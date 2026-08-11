#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT   = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $ORIGIN = getcwd();

# _workflow_files()
# Lists the continuous-integration workflow definitions that the repository owns.
# Input: none; the workflow directory is resolved from the repository root.
# Output: sorted list of absolute workflow file paths.
sub _workflow_files {
    my $dir = File::Spec->catdir( $ROOT, '.github', 'workflows' );
    opendir( my $dh, $dir ) or die "Unable to read $dir: $!";
    my @names = sort grep { m{[.]ya?ml\z} } readdir($dh);
    closedir($dh);
    return map { File::Spec->catfile( $dir, $_ ) } @names;
}

# _harness_sources()
# Lists every repository file that can start a Devel::Cover harness run. The
# workflows used to hold that invocation directly; it now lives in the one
# canonical entrypoint they all call, so the scan has to follow it there. A
# scan whose subject has moved out from under it reports a clean pass over an
# empty set, which is why the count assertion below is not decoration.
# Input: none.
# Output: list of absolute paths to scan.
sub _harness_sources {
    return ( _workflow_files(), File::Spec->catfile( $ROOT, 'script', 'coverage-gate' ) );
}

# _coverage_invocations($file)
# Collects the lines of one workflow file that start a Devel::Cover harness run.
# Input: absolute path to a workflow file.
# Output: list of hash references carrying the line number and the line text.
sub _coverage_invocations {
    my ($file) = @_;
    open( my $fh, '<', $file ) or die "Unable to open $file: $!";
    my @hits;
    while ( my $line = <$fh> ) {
        chomp $line;
        # `-MDevel::Cover::DB::IO` LOADS a submodule to ask where it lives; it
        # does not start a coverage run, so blib isolation means nothing to it.
        # Matching -MDevel::Cover as a bare substring caught it and demanded a
        # flag that would be meaningless there - a cheap check returning a
        # plausible answer, which is the shape of failure this repo keeps paying
        # for. A harness invocation is -MDevel::Cover followed by its options.
        next if $line =~ m{-MDevel::Cover::};
        push @hits, { line => $., text => $line } if $line =~ m{-MDevel::Cover\b};
    }
    close($fh);
    return @hits;
}

# The gate that stops the regression. Devel::Cover prepends the build tree to
# @INC on its own, so an invocation without an explicit opt-out grades whatever
# blib/ happens to be lying around instead of the source under lib/.
my @invocations;
for my $file ( _harness_sources() ) {
    my ($name) = ( File::Spec->splitpath($file) )[2];
    for my $hit ( _coverage_invocations($file) ) {

        # cpanm installing the distribution is not a harness invocation.
        next if $hit->{text} =~ m{cpanm};
        push @invocations, $hit;
        like(
            $hit->{text},
            qr{-MDevel::Cover=(?:[^\s'"]*,)?-blib,0},
            "$name line $hit->{line} runs the coverage harness with blib isolation",
        );
    }
}
ok( scalar(@invocations) > 0, 'the workflow scan found coverage harness invocations to check' );

# The behavioural half. Without this the scan above only pins a string, and a
# future Devel::Cover that changed the meaning of the flag would go unnoticed.
SKIP: {
    eval { require Devel::Cover; 1 }
      or skip 'Devel::Cover is required for the blib isolation behaviour check', 2;

    my $tmp = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $tmp, 'lib' ) );

    # blib only takes effect when the build tree is complete: blib, blib/lib
    # and blib/arch must all exist before blib.pm touches @INC.
    make_path( File::Spec->catdir( $tmp, 'blib', 'lib' ) );
    make_path( File::Spec->catdir( $tmp, 'blib', 'arch' ) );

    for my $case ( [ 'lib', 'SOURCE' ], [ File::Spec->catdir( 'blib', 'lib' ), 'STALE' ] ) {
        my ( $where, $origin ) = @{$case};
        my $probe = File::Spec->catfile( $tmp, $where, 'DDBlibProbe.pm' );
        open( my $fh, '>', $probe ) or die "Unable to write $probe: $!";
        print {$fh} "package DDBlibProbe;\nsub origin { return '$origin' }\n1;\n";
        close($fh) or die "Unable to close $probe: $!";
    }

    chdir $tmp or die "Unable to chdir to $tmp: $!";

    # _probe_origin(@cover_options)
    # Reports which copy of the probe module a child perl loads.
    # Input: Devel::Cover import options for the child interpreter.
    # Output: the origin string printed by the loaded probe module.
    my $probe_origin = sub {
        my (@options) = @_;
        my ( $stdout, $stderr, $exit ) = capture {
            system( $^X, '-M' . join( ',', 'Devel::Cover=-silent', 1, @options ),
                '-Ilib', '-MDDBlibProbe', '-e', 'print DDBlibProbe::origin()' );
        };
        is( $exit, 0, 'the probe interpreter ran cleanly' ) or diag($stderr);
        return $stdout;
    };

    is(
        $probe_origin->( '-db', File::Spec->catdir( $tmp, 'cover_db_default' ) ),
        'STALE',
        'the bare coverage harness silently loads the build tree, which is the hazard being guarded',
    );
    is(
        $probe_origin->( '-blib', 0, '-db', File::Spec->catdir( $tmp, 'cover_db_isolated' ) ),
        'SOURCE',
        'blib isolation makes the coverage harness load the source tree it is meant to grade',
    );

    chdir $ORIGIN or die "Unable to chdir back to $ORIGIN: $!";
}

done_testing();

__END__

=head1 NAME

t/133-coverage-gate-blib-isolation.t - pin the coverage harness to the source tree

=head1 PURPOSE

A regression gate for DD-431. It pins that every Devel::Cover harness run this
repository owns grades the working copy under C<lib/> and never a build tree
under C<blib/>.

Devel::Cover performs an implicit C<use blib> whenever a complete build tree is
reachable from the current directory or any of its first five parents. C<blib>
places C<blib/arch> and C<blib/lib> at the front of C<@INC>, ahead of the
C<-Ilib> that C<prove -l> supplies, so the instrumented suite loads the built
snapshot rather than the source. Devel::Cover then rewrites those paths back to
C<lib/> when it reports, which is what makes the substitution invisible.

=head1 WHY IT EXISTS

The coverage gate is the primary correctness instrument of this distribution:
it decides whether a change reached 100.0 on statement, subroutine, branch and
condition coverage. A run that grades a stale snapshot reports both false reds
and false greens. It produced both at once - a security contract test that
passed standalone failed inside the instrumented suite against the pre-fix
snapshot, while a branch and condition shortfall was attributed to code that no
longer existed in the source.

=head1 WHEN TO USE

Run it whenever the coverage command changes, whenever a release workflow gains
or edits a harness invocation, and after any upgrade of Devel::Cover.

=head1 HOW TO USE

  prove -lv t/133-coverage-gate-blib-isolation.t

=head1 WHAT USES IT

The repository test suite, through C<prove -lr t>, and the release workflows
whose own coverage invocations it inspects.

=head1 EXAMPLES

Run the gate on its own:

  prove -lv t/133-coverage-gate-blib-isolation.t

Run it beside the coverage gate script contract it protects:

  prove -lv t/107-all-metric-coverage-gate.t t/133-coverage-gate-blib-isolation.t

Run it under the coverage harness, in the isolated form it exists to enforce:

  HARNESS_PERL_SWITCHES=-MDevel::Cover=-blib,0 prove -l t/133-coverage-gate-blib-isolation.t

=cut
