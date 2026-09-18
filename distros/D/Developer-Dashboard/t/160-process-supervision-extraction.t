#!/usr/bin/env perl

# Written RED, before Developer::Dashboard::ProcessSupervision exists.
#
# This file pins the extraction itself rather than the behaviour of the helpers,
# which is already covered by the per-module coverage tests. Three things have to
# be true and none of them is checked anywhere else:
#
#   1. every extracted helper is DEFINED in exactly one place
#   2. both consumers can still CALL them, which is what proves the export
#      reaches the package's method-resolution path rather than just existing
#   3. the nine helpers that legitimately DIFFER between the two modules are
#      still defined by each module itself
#
# Point 3 is the guard, not the goal. Two of the extracted helpers call divergent
# ones - _pid_is_running calls _read_process_state, _replace_state_file calls
# _replace_path_via_powershell - so the extraction must keep $self-> dispatch and
# must not drag either divergent helper into the shared module. Doing so would
# silently impose one class's behaviour on the other, and every existing test
# would still pass, because each version currently satisfies its own module's
# tests.

use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

my @EXTRACTED = qw(
    _current_perl_command
    _descriptor_is_inherited_pipe
    _fork_process
    _open_file_descriptors
    _overwrite_state_file_in_place
    _pid_is_running
    _pid_namespace_id
    _powershell_command
    _powershell_single_quote
    _process_exists
    _read_process_env_marker
    _reap_child_process
    _rename_path
    _replace_state_file
    _unlink_path
    _helper_file_supports_internal_command
    _same_pid_namespace
    _close_inherited_fds
);

# Deliberately NOT extracted: these differ between the two modules (DD-669), and
# each class must keep its own.
# Each name here is a helper that EXISTS IN BOTH CONSUMERS WITH DIFFERENT BODIES and is
# deliberately left that way. The reason is recorded beside the name because a bare list
# only asserts that they differ - it cannot tell a later reader whether the justification
# still holds, which is the question that actually matters when one of these is touched.
# Four resolutions exist for a divergent shared name, and only the first removes it:
# reconcile, rename, declare-as-interface, or declare-as-defect (DD-669).
my %MUST_STAY_PER_CLASS = (
    _read_process_state =>
        'INTERFACE: shared _pid_is_running dispatches through this name, so each consumer '
      . 'supplies its own body. Also carries the per-module procfs-trust policy.',
    _read_process_title =>
        'PER-MODULE POLICY: RuntimeManager gates every procfs read on _procfs_available and '
      . 'trusts it; CollectorRunner never gates and always confirms with ps. The module is '
      . 'the qualifier, so a rename would repeat one fact across every helper in the class.',
    _replace_path_via_powershell =>
        'INTERFACE: shared _replace_state_file dispatches through this name.',
    _spawn_windows_background_command =>
        'DEFECT, NOT DESIGN: RuntimeManager hardcodes the powershell string where '
      . 'CollectorRunner resolves it via _powershell_command and dies when unavailable. '
      . 'Tracked as DD-753; reconciles once that lands. Renaming would make the defect '
      . 'read as a deliberate variant.',
);
my @MUST_STAY_PER_CLASS = sort keys %MUST_STAY_PER_CLASS;

my @CONSUMERS = qw(
    Developer::Dashboard::RuntimeManager
    Developer::Dashboard::CollectorRunner
);

require_ok('Developer::Dashboard::ProcessSupervision')
    or BAIL_OUT('the shared module does not exist yet - this file is the RED test for it');

require_ok($_) for @CONSUMERS;

# 1. Defined in exactly one place.
#
# CORRECTED: an earlier version of this comment claimed `defined &Pkg::name`
# asks "whether the symbol table entry has a body of its own", and so tells an
# import apart from a local definition. IT DOES NOT. Exporter installs the sub
# directly into the importing package's symbol table - which is exactly what
# makes `$self->_helper(...)` resolve through the consumer - so `defined &` is
# true for an import too. Measured:
#
#   defined &Developer::Dashboard::CollectorRunner::_pid_is_running  -> TRUE
#
# even though CollectorRunner imports it. What DOES discriminate is CODEREF
# IDENTITY: a shared sub and its importer are the same coderef, a surviving
# local copy is a different one. Both checks are made below.
for my $sub (@EXTRACTED) {
    no strict 'refs';
    ok( defined &{"Developer::Dashboard::ProcessSupervision::$sub"},
        "$sub is defined in the shared module" );
}

# 2. Both consumers can still call them.
#
# This is the part that proves the export lands where a method call will find it.
# A module that merely defines the subs, without them reaching each consumer's
# package, would satisfy point 1 and break every call site.
for my $pkg (@CONSUMERS) {
    for my $sub (@EXTRACTED) {
        ok( $pkg->can($sub), "$pkg can still reach $sub" );

        # The check that actually proves the consumer uses the SHARED body
        # rather than having kept a copy of its own. Without this, a stale
        # duplicate left behind in the consumer would satisfy every other
        # assertion in this file - which is precisely the outcome the
        # extraction exists to prevent.
        no strict 'refs';
        is( \&{"${pkg}::${sub}"}, \&{"Developer::Dashboard::ProcessSupervision::${sub}"},
            "$pkg\'s $sub IS the shared body, not a surviving local copy" );
    }
}

# 3. The divergent nine stay where they are.
for my $pkg (@CONSUMERS) {
    for my $sub (@MUST_STAY_PER_CLASS) {
        no strict 'refs';
        ok( defined &{"${pkg}::$sub"},
            "$pkg still defines its own $sub (it differs between modules - DD-669)" );
    }
}

# 4. And the shared module must NOT have absorbed any of them.
for my $sub (@MUST_STAY_PER_CLASS) {
    no strict 'refs';
    ok( !defined &{"Developer::Dashboard::ProcessSupervision::$sub"},
        "$sub was NOT pulled into the shared module - it differs per class" );
}

# ---------------------------------------------------------------------------
# 5. THE NEXT divergence, not just these nine (DD-669 AC-3).
#
# @MUST_STAY_PER_CLASS above is a hardcoded list. It pins the nine we know about
# and says nothing about a tenth - so a helper that starts diverging tomorrow, or
# one that is quietly reconciled and left in the list, both pass. That is the
# same shape as a grep naming its own subjects: it restates the author's model
# and passes precisely when that model is incomplete.
#
# This derives the set FROM THE SOURCE and compares it against the declaration,
# so either direction of drift fails.
#
# COMMENT-STRIPPED, and that is not cosmetic: one module comments its helpers and
# the other does not, so comparing bodies WITH comments reports almost the
# inverse split - 9 identical and 14 different, when the truth is the reverse.
{
    my $extract = sub {
        my ($path) = @_;
        open my $fh, '<', $path or die "$path: $!";
        my ( %subs, $name, @body, $depth, $in );
        while ( my $line = <$fh> ) {
            if ( !$in && $line =~ /^\s*sub\s+(\w+)\s*\{/ ) {
                $name = $1; $in = 1; $depth = 0; @body = ();
            }
            next if !$in;
            my $stripped = $line;
            $stripped =~ s/\#.*$//;
            $stripped =~ s/^\s+|\s+$//g;
            push @body, $stripped if length $stripped;
            $depth += ( $line =~ tr/{// );
            $depth -= ( $line =~ tr/}// );
            if ( $depth <= 0 ) { $subs{$name} = join "\n", @body; $in = 0; }
        }
        close $fh;
        return \%subs;
    };

    my $rm = $extract->("$FindBin::Bin/../lib/Developer/Dashboard/RuntimeManager.pm");
    my $cr = $extract->("$FindBin::Bin/../lib/Developer/Dashboard/CollectorRunner.pm");

    # 'new' is a constructor: it differs because they are two classes, not
    # because anything drifted.
    #
    # _now_iso8601 was RECONCILED, not merely re-pinned (DD-894): it no longer
    # appears as `sub _now_iso8601 { ... }` in either consumer at all, so it
    # naturally drops out of the divergent-body comparison below without
    # needing its own dedicated per-class check here (the check this block
    # used to run - confirming RuntimeManager's body used gmtime and
    # CollectorRunner's used localtime - is superseded by
    # t/191-timeutils-coverage.t, which pins the same UTC/local split as an
    # explicit tz parameter on the shared Developer::Dashboard::TimeUtils
    # function both consumers now import). DD-642's decision that the split
    # itself is deliberate (not a bug to merge away) still holds and is what
    # TimeUtils.pm's own POD documents; only the MECHANISM of keeping the
    # split changed, from two divergent bodies to one parameterized one.

my @divergent = sort grep {
        $_ ne 'new' && exists $cr->{$_} && $rm->{$_} ne $cr->{$_}
    } keys %$rm;

    my @declared = sort @MUST_STAY_PER_CLASS;
    is_deeply( \@divergent, \@declared,
        'the divergent shared helpers found in the source are exactly the ones declared - a NEW divergence, or a resolved one left in the list, fails here' );
}


# DD-753: RuntimeManager hardcoded the bare string 'powershell' at four call sites
# while CollectorRunner resolved it and reported a named failure. Both now use the
# shared resolver, so no bare command argument may remain. Comments are stripped
# before matching, because a guard that greps raw source cannot tell code from the
# commentary explaining why the code is that way - and this file's own header
# discusses the string it forbids.
{
    my $rm = "$FindBin::Bin/../lib/Developer/Dashboard/RuntimeManager.pm";
    open my $fh, '<', $rm or die "cannot read $rm: $!";
    my @code = grep { $_ !~ /^\s*#/ } <$fh>;
    close $fh;
    my $source = join '', @code;
    my @hits = ( $source =~ /(['"]powershell['"])\s*,/g );
    is( scalar @hits, 0,
        'RuntimeManager passes no bare powershell string as a command argument' )
      or diag( 'still hardcoded at ' . scalar(@hits) . ' site(s)' );
}

done_testing();

__END__

=head1 NAME

t/160-process-supervision-extraction.t - pin the shared process-supervision extraction

=head1 PURPOSE

Assert that the helpers whose bodies were identical in RuntimeManager and
CollectorRunner are defined once, are reachable from both, and that the helpers
which genuinely differ between those modules were left alone.

=head1 WHY IT EXISTS

The per-module coverage tests exercise what these helpers DO. Nothing exercised
where they LIVE, so an extraction could quietly move a helper that differs
between the two classes and every existing test would still pass - each version
satisfies its own module's tests today. This file is the discriminating check
that a behaviour-preserving refactor needs and the behaviour tests cannot give.

=head1 WHEN TO USE

It runs in the ordinary suite. Consult it when changing which helpers are shared,
or when a call site stops resolving a helper it used to reach.

=head1 HOW TO USE

    prove -l t/160-process-supervision-extraction.t

=head1 WHAT USES IT

Nothing programmatic; it is a standing guard in the suite, run by C<prove -lr t>
and by the coverage gate.

=head1 EXAMPLES

Adding a helper to the shared module means adding its name to C<@EXTRACTED>.
Moving one of C<@MUST_STAY_PER_CLASS> into the shared module makes this file fail
by design, because those helpers differ between the two classes and sharing one
would impose a single behaviour on both.

=cut
