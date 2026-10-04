#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::open override must exist before the module under test is
# compiled. It fails only for exact paths registered in %FAIL, so the open
# failure runs deterministically even when the suite runs as root, where a
# chmod 0000 file is still readable.
our %FAIL;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
}

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::ProcessSupervision;

my $dir    = tempdir( CLEANUP => 1 );
my $helper = File::Spec->catfile( $dir, 'helper.pl' );
open my $fh, '>', $helper or die "Unable to write $helper: $!";
print {$fh} "web-foreground\n";
close $fh or die "Unable to close $helper: $!";

my $self = bless {}, 'Developer::Dashboard::ProcessSupervision';

is( $self->_helper_file_supports_internal_command( $helper, 'web-foreground' ), 1, 'a readable helper that mentions the command is supported' );

local $FAIL{$helper} = 1;
is( $self->_helper_file_supports_internal_command( $helper, 'web-foreground' ), 0, 'a helper that passes -f but cannot be opened is not supported' );

done_testing;

__END__

=pod

=head1 NAME

t/451-processsupervision-coverage.t - covers the unreadable-helper branch of Developer::Dashboard::ProcessSupervision

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the open failure in C<_helper_file_supports_internal_command> for a file that exists, so the branch is exercised even when the suite runs as root.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs this branch exercised, and the chmod-based test in t/100-runtimemanager-coverage.t skips itself when the process can read a mode-0000 file, which is always true for root.

=head1 WHEN TO USE

Use this file when you change the helper-support check in ProcessSupervision, or when a coverage run reports its open failure as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/451-processsupervision-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/451-processsupervision-coverage.t

Run this coverage-gap test by itself while editing ProcessSupervision.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/451-processsupervision-coverage.t

Confirm the open-failure branch is reported as covered.

=cut
