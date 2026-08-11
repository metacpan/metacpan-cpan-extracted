use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT  = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $GATE  = File::Spec->catfile( $ROOT, 'script', 'cpan-audit-declared-chain' );
my $SOURCE = _slurp($GATE);

# Source contracts. These hold whether or not the advisory database is
# installed on this host, so they are checked before anything is executed.
ok( -f $GATE, 'the declared-chain audit gate is tracked in script/' );
ok( -x $GATE, 'the declared-chain audit gate is executable' );
like( $SOURCE, qr{\A#!/usr/bin/env perl\n}, 'the gate uses the portable env shebang' );
like( $SOURCE, qr/^use strict;$/m,   'the gate runs under strict' );
like( $SOURCE, qr/^use warnings;$/m, 'the gate runs under warnings' );
like( $SOURCE, qr/EXIT_UNUSABLE/, 'the gate has a distinct exit code for "could not audit"' );
like( $SOURCE, qr/prereqs.*runtime.*requires/s, 'the gate walks runtime requirements rather than recommendations or suggestions' );
like( $SOURCE, qr/_read_exclusions/, 'the gate consumes the reviewed advisory disposition file' );
unlike( $SOURCE, qr/JSON::PP|LWP::Simple|HTTP::Tiny|capture_merged/, 'the gate uses no forbidden library' );

# Everything below executes the gate, which needs the CPAN::Audit advisory
# database. It is present on the development host and in the dedicated CI audit
# job; when it is absent the gate itself refuses to report a clean chain, and
# there is nothing further this test can assert.
my $have_audit_db = eval {
    require CPAN::Audit::DB;
    require CPAN::Audit::Version;
    1;
};

# The advisory used as the executable regression proof. HTML-Parser is the
# distribution DD-443 was opened for: it is never named in the cpanfile and is
# never called by the product, and it reached the resolved chain only because
# libwww-perl requires HTML::HeadParser at runtime.
my $ADVISORY   = 'CPANSA-HTML-Parser-2026-8829';
my $VULNERABLE = '3.83';
my $FIXED      = '3.84';

# The only floor anywhere in the real chain came from libwww-perl requiring
# HTML::HeadParser 3.71, and 3.71 is itself a released HTML-Parser version, so
# the lowest release the chain permits is 3.71 - well inside the advisory range.
my $PERMITTED = '3.71';

SKIP: {
    skip 'CPAN::Audit is not installed in this runtime, so the gate cannot be executed', 20
        if !$have_audit_db;

    # Fail-closed contract: usage errors and unusable inputs never exit 0.
    {
        my ( $rc, $out ) = _run_gate();
        is( $rc, 2, 'the gate exits 2 when no library root is given' );
        like( $out, qr/Usage:/, 'the gate prints a usage diagnostic when no library root is given' );
    }

    {
        my ( $rc, $out ) = _run_gate('/tmp/dd443-nonexistent-library-root');
        is( $rc, 2, 'the gate exits 2 when the library root does not exist' );
        like( $out, qr/not a directory/, 'the gate names the missing library root' );
    }

    {
        my $empty = tempdir( CLEANUP => 1 );
        my ( $rc, $out ) = _run_gate($empty);
        is( $rc, 2, 'the gate exits 2 for a library root with no distribution metadata' );
        like( $out, qr/no distribution metadata/, 'the gate refuses to call an unwalkable chain clean' );
    }

    # Executable regression proof for DD-443: a chain whose cpanfile names only
    # a distribution that requires HTML::HeadParser transitively still permits
    # the vulnerable HTML-Parser release, and the gate has to say so.
    my $fixture = _build_fixture_root();

    {
        my $cpanfile = _write_cpanfile( $fixture, "requires 'Fixture::Agent', '1.00';\n" );
        my ( $rc, $out ) = _run_gate( '--cpanfile', $cpanfile, $fixture );
        is( $rc, 1, 'a transitively permitted vulnerable HTML-Parser fails the gate' );
        like( $out, qr/HTML-Parser permits \Q$PERMITTED\E/, 'the gate reports the lowest release the declared chain still permits, not the installed one' );
        like( $out, qr/\Q$ADVISORY\E/, 'the gate reports the exact advisory identifier' );
        like( $out, qr/runtime\/requires of Fixture-Agent/, 'the gate attributes the floor to the transitive requirement that produced it' );
    }

    # The floor is the whole mitigation: naming HTML::Parser at the fixed
    # version clears the same chain with no other change.
    {
        my $cpanfile = _write_cpanfile( $fixture,
            "requires 'Fixture::Agent', '1.00';\nrequires 'HTML::Parser', '$FIXED';\n" );
        my ( $rc, $out ) = _run_gate( '--cpanfile', $cpanfile, $fixture );
        is( $rc, 0, 'declaring the advisory floor clears the same chain' );
        like( $out, qr/No distribution in the declared runtime closure/, 'the cleared chain reports explicitly that nothing is permitted' );
    }

    # A reviewed disposition suppresses only the advisory it names.
    {
        my $cpanfile = _write_cpanfile( $fixture, "requires 'Fixture::Agent', '1.00';\n" );
        my $exclude  = File::Spec->catfile( $fixture, 'reviewed-advisories.txt' );
        _write_file( $exclude, "# reviewed for this fixture only\n$ADVISORY\n" );
        my ( $rc, undef ) = _run_gate( '--cpanfile', $cpanfile, '--exclude-file', $exclude, $fixture );
        is( $rc, 0, 'a reviewed advisory disposition suppresses its own finding' );
    }

    # A metadata file the gate cannot parse shrinks the closure, and a shrunken
    # closure can hide a finding, so it is the fail-closed case - not a skip.
    # Dropping Fixture-Agent's metadata is exactly what would hide the
    # HTML-Parser finding this whole gate exists to catch, and reporting the
    # drop on STDERR while still exiting 0 would leave every caller that checks
    # the exit code - the continuous-integration step included - reading it as a
    # clean chain.
    {
        my $damaged = _build_fixture_root();
        _write_file(
            File::Spec->catfile( $damaged, 'fixture-arch', '.meta', 'Fixture-Agent-1.00', 'install.json' ),
            '{ this is not json',
        );
        my $cpanfile = _write_cpanfile( $damaged, "requires 'Fixture::Agent', '1.00';\n" );
        my ( $rc, $out ) = _run_gate( '--cpanfile', $cpanfile, $damaged );
        is( $rc, 2, 'distribution metadata the gate cannot parse makes the audit unusable rather than clean' );
        like( $out, qr/closure would be incomplete/, 'the gate says the closure would be incomplete instead of reporting a clean chain' );
        like( $out, qr/Fixture-Agent-1\.00.+unparseable/, 'the gate names the metadata file it could not parse and why' );
    }

    # Well-formed JSON that is not an object is the same defect with a different
    # reason, and must reach the same fail-closed outcome.
    {
        my $damaged = _build_fixture_root();
        _write_file(
            File::Spec->catfile( $damaged, 'fixture-arch', '.meta', 'Fixture-Agent-1.00', 'install.json' ),
            '[]',
        );
        my $cpanfile = _write_cpanfile( $damaged, "requires 'Fixture::Agent', '1.00';\n" );
        my ( $rc, $out ) = _run_gate( '--cpanfile', $cpanfile, $damaged );
        is( $rc, 2, 'distribution metadata that is valid JSON but not an object is unusable too' );
        like( $out, qr/not a JSON object/, 'the gate names the reason the metadata was unusable' );
    }

    # A cpanfile with no runtime requirements is unusable, not clean.
    {
        my $cpanfile = _write_cpanfile( $fixture, "on 'develop' => sub {\n    recommends 'DBI';\n};\n" );
        my ( $rc, $out ) = _run_gate( '--cpanfile', $cpanfile, $fixture );
        is( $rc, 2, 'a cpanfile with no runtime requirements is reported as unusable' );
        like( $out, qr/no runtime requirements declared/, 'the gate names why it could not audit' );
    }
}

# The real gate over the real declared chain. This is a live check: the advisory
# database moves, so a new advisory against any distribution in the closure is a
# genuine finding that needs a floor or a reviewed disposition.
SKIP: {
    skip 'CPAN::Audit is not installed in this runtime, so the real chain cannot be audited', 1
        if !$have_audit_db;

    my $library_root = _installed_library_root();
    skip 'no Perl library root with distribution metadata was found for the real chain', 1
        if !defined $library_root;

    my ( $rc, $out ) = _run_gate($library_root);
    is( $rc, 0, "the declared dependency chain permits no vulnerable resolution under $library_root" )
        or diag($out);
}

done_testing;

# Purpose: read a repository file in full.
# Input: an absolute file path.
# Output: the file contents as a string, or the empty string when absent.
sub _slurp {
    my ($path) = @_;
    return '' if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return defined $content ? $content : '';
}

# Purpose: write a file, creating nothing else.
# Input: an absolute file path and the content to write.
# Output: nothing; dies when the write fails.
sub _write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return;
}

# Purpose: run the declared-chain gate in a child process and capture both its
#          exit status and its combined output.
# Input: the argument list to pass to the gate.
# Output: a two element list of exit code and captured output.
sub _run_gate {
    my (@args) = @_;
    my $command = join ' ', $^X, $GATE, @args;
    my $out = `$command 2>&1`;
    my $rc  = ${^CHILD_ERROR_NATIVE} >> 8;
    return ( $rc, defined $out ? $out : '' );
}

# Purpose: build a synthetic library root whose metadata reproduces the DD-443
#          shape - one distribution that requires HTML::HeadParser at runtime,
#          and a vulnerable HTML-Parser release that provides it.
# Input: none.
# Output: the path to the temporary library root (cleaned up with the test).
sub _build_fixture_root {
    my $root = tempdir( CLEANUP => 1 );
    my $meta = File::Spec->catdir( $root, 'fixture-arch', '.meta' );

    _write_dist_metadata(
        $meta,
        'Fixture-Agent-1.00',
        '{"dist":"Fixture-Agent-1.00","version":"1.00","provides":{"Fixture::Agent":{"version":"1.00"}}}',
        '{"prereqs":{"runtime":{"requires":{"HTML::HeadParser":"3.71"}}}}',
    );
    _write_dist_metadata(
        $meta,
        "HTML-Parser-$VULNERABLE",
        qq({"dist":"HTML-Parser-$VULNERABLE","version":"$VULNERABLE","provides":{"HTML::Parser":{"version":"$VULNERABLE"},"HTML::Entities":{"version":"$VULNERABLE"},"HTML::HeadParser":{"version":"$VULNERABLE"}}}),
        '{"prereqs":{"runtime":{"requires":{}}}}',
    );

    return $root;
}

# Purpose: write one distribution's cpanm metadata pair into a .meta tree.
# Input: the .meta directory, the versioned distribution directory name, the
#        install.json body, and the MYMETA.json body.
# Output: nothing; dies when the write fails.
sub _write_dist_metadata {
    my ( $meta, $dist_dir, $install_json, $mymeta_json ) = @_;
    my $dir = File::Spec->catdir( $meta, $dist_dir );
    make_path($dir);
    _write_file( File::Spec->catfile( $dir, 'install.json' ), $install_json );
    _write_file( File::Spec->catfile( $dir, 'MYMETA.json' ),  $mymeta_json );
    return;
}

# Purpose: place a candidate cpanfile inside the fixture root.
# Input: the fixture root and the cpanfile body.
# Output: the path to the written cpanfile.
sub _write_cpanfile {
    my ( $root, $body ) = @_;
    my $path = File::Spec->catfile( $root, 'cpanfile' );
    _write_file( $path, $body );
    return $path;
}

# Purpose: find a real Perl library root that carries cpanm distribution
#          metadata, so the project's own declared chain can be audited.
# Input: none.
# Output: the first matching library root path, or undef when none exists.
sub _installed_library_root {
    my @candidates = (
        File::Spec->catdir( $ROOT, 'local', 'lib', 'perl5' ),
        File::Spec->catdir( $ENV{HOME} // '', 'perl5', 'lib', 'perl5' ),
    );

    for my $candidate (@candidates) {
        next if !-d $candidate;
        return $candidate if _has_metadata($candidate);
    }
    return undef;    ## no critic
}

# Purpose: decide whether a library root carries any cpanm .meta metadata.
# Input: a library root path.
# Output: 1 when at least one .meta directory exists below it, 0 otherwise.
sub _has_metadata {
    my ($root) = @_;

    return 1 if -d File::Spec->catdir( $root, '.meta' );
    opendir my $dh, $root or return 0;
    my @entries = grep { !/^\./ } readdir $dh;
    closedir $dh or die "Unable to close $root: $!";
    for my $entry (@entries) {
        return 1 if -d File::Spec->catdir( $root, $entry, '.meta' );
    }
    return 0;
}

__END__

=head1 NAME

t/109-declared-chain-advisory-closure.t - verify the declared-chain advisory gate

=head1 PURPOSE

Verify that C<script/cpan-audit-declared-chain> walks the transitive runtime
closure of the declared dependency chain, reports any distribution whose lowest
still-permitted release falls inside a published advisory range, honours the
reviewed advisory disposition list, and fails closed rather than reporting a
clean chain it could not audit.

=head1 WHY IT EXISTS

The project's advisory floor list used to be derived from the modules the
C<cpanfile> names, while the exposure comes from the transitive closure. Two
distributions reached the resolved chain that way and were caught only by manual
audit: C<HTTP::Date> and C<HTML::Parser>, both pulled in by C<libwww-perl>'s own
runtime requirements, neither named in the C<cpanfile>, and neither called by
the product. An installed-distribution scan cannot catch this class of defect,
because a resolver always installs the newest release, so the installed versions
look clean while the declared floors still permit a vulnerable one.

This test pins the gate that closes that hole. Its central case is a synthetic
chain built in the exact shape of the original defect: a distribution that
requires C<HTML::HeadParser> at runtime, and a vulnerable C<HTML-Parser> release
that provides it. The gate has to report the advisory without C<HTML::Parser>
ever being named in that chain's C<cpanfile>, and declaring the floor has to
clear it.

=head1 WHEN TO USE

Run it whenever the gate, the declared prerequisites, or the reviewed advisory
disposition list changes, and as part of the normal suite.

=head1 HOW TO USE

Run C<prove -lv t/109-declared-chain-advisory-closure.t>. The source contracts
always run. The executable cases need C<CPAN::Audit> on the runtime include
path and are skipped with an explicit reason when it is absent; the dedicated
continuous-integration audit job provides it there.

The final case audits the project's own declared chain against a real library
root and is deliberately live. A failure means a newly published advisory now
covers a version the declared chain still permits, and the fix is to raise that
distribution's floor in C<cpanfile>, C<Makefile.PL> and C<dist.ini> together, or
to record a reviewed disposition for the advisory.

=head1 WHAT USES IT

The normal C<prove -lr t> suite, the CVE gate of the delivery pipeline, and
release verification.

=head1 EXAMPLES

Example 1 - run the test on its own:

  prove -lv t/109-declared-chain-advisory-closure.t

Example 2 - reproduce the live case by hand:

  script/cpan-audit-declared-chain "$HOME/perl5/lib/perl5"

Example 3 - audit an isolated dependency root a build resolved:

  script/cpan-audit-declared-chain local/lib/perl5

=head1 AUTHOR

Developer Dashboard Contributors
