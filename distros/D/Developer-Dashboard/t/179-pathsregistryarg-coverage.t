#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

# --- require_paths_arg: returns the paths registry when present (line 15 true) --
{
    my $paths = bless {}, 'Fake::Paths';
    is( require_paths_arg( paths => $paths ), $paths,
        'require_paths_arg returns the given paths registry' );
}

# --- require_paths_arg: dies when paths is absent (line 15 false) --------------
{
    eval { require_paths_arg() };
    like( $@, qr/Missing paths registry/, 'require_paths_arg dies with the shared message when paths is absent' );
}

# --- require_paths_arg: dies when paths is present but false -------------------
{
    eval { require_paths_arg( paths => 0 ) };
    like( $@, qr/Missing paths registry/, 'require_paths_arg dies when paths is present but false' );
}

# --- the die message lives in exactly ONE place among the 7 named callers ------
# (DD-785's own verification instruction, corrected in scope: "exactly one
# place among the 7 constructor modules this ticket names", not "exactly one
# place in lib/" - the same literal string also appears 24 times across four
# unrelated CLI-handler files this ticket does not touch.) Strip POD first,
# since PathsRegistryArg's own SYNOPSIS/EXAMPLES sections quote the message.
{
    my @callers = qw(
        Collector Doctor IndicatorStore PageStore Housekeeper FileRegistry Prompt
    );
    my $total_in_callers = 0;
    for my $name (@callers) {
        my $path = "lib/Developer/Dashboard/$name.pm";
        open my $fh, '<', $path or die "Unable to read $path: $!";
        local $/;
        my $src = <$fh>;
        close $fh;
        $src =~ s/\n=\w+.*?\n=cut\n/\n/gs;
        my $count = () = $src =~ /Missing paths registry/g;
        $total_in_callers += $count;
    }
    is( $total_in_callers, 0,
        'none of the 7 named callers carry their own copy of the die message any more' );

    open my $fh, '<', 'lib/Developer/Dashboard/PathsRegistryArg.pm'
        or die "Unable to read PathsRegistryArg.pm: $!";
    local $/;
    my $src = <$fh>;
    close $fh;
    $src =~ s/\n=\w+.*?\n=cut\n/\n/gs;
    $src =~ s/#.*//g;
    my $shared_count = () = $src =~ /Missing paths registry/g;
    is( $shared_count, 1,
        'the die message lives in exactly one CODE occurrence - the shared module - outside comments and POD' );
}

done_testing();

__END__

=head1 NAME

179-pathsregistryarg-coverage.t - coverage for Developer::Dashboard::PathsRegistryArg

=head1 PURPOSE

Exercises C<require_paths_arg>'s one branch in both directions - a real
paths registry returned, and every falsy value (absent, zero) treated the
same as absent.

=head1 WHY IT EXISTS

DD-785 extracted this guard out of seven constructors' own C<new()>. This
file is the coverage gate for the extraction itself, so the shared function
carries its own 100% rather than relying on the seven callers' coverage to
exercise it indirectly.

=head1 WHEN TO USE

Run whenever C<PathsRegistryArg.pm> changes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/179-pathsregistryarg-coverage.t

=head1 WHAT USES IT

Nothing else calls this file; it is invoked by C<prove> directly or as
part of the full suite.

=head1 EXAMPLES

Example 1:

  require_paths_arg( paths => $registry );

Returns C<$registry>.

=cut
