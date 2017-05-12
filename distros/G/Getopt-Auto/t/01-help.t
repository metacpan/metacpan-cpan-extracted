#! /usr/bin/perl
#  Copyright (C) 2010, Geoffrey Leach
#===============================================================================
#
#         FILE:  01.help.t
#
#  DESCRIPTION:  Test auto-help
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  Fri Oct  8 16:16:29 PDT 2010
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;
use Test::Output qw{ stderr_from };
use Getopt::Auto( { 'test' => 1 } );

use 5.006;
our $VERSION = '1.9.8';
my $me = '01-help.t';

## no critic (ProhibitImplicitNewlines)
## no critic (ProtectPrivateSubs)
## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateVars)
## no critic (ProhibitPackageVars)

our %options;    # Will be set by Getopt::Auto; 'our' is required for that

# Now, if all is proceeding according to plan, we are set up to expect option
# --foo. $is_foo_called will be set to j if the subroutine foo() implied by the
# --foo option is not called, because the failure to recognize -x calls help(), which
# ends processing. We also have here a "short" option, -x, which has
# not been specified in advance, so we expect that $main::options->{x} will not be set

my $is_foo_called = 0;
sub foo { ++$is_foo_called; return; }

@ARGV = qw( -x --foo );
my $help =
    "Getopt::Auto: -x is not a registered option\n" .
    "This is $me version $VERSION\n\n" .
    "$me --foo - do a foo\n\n" .
    "Test\n\n" .
    "This is the built-in help, exiting\n";

my $stderr = stderr_from( \&Getopt::Auto::_parse_args );
$stderr =~ s{\S+$me}{$me}gxism; 
is( $stderr, $help, 'Check -x not registered' );
ok( $is_foo_called == 0, 'Sub foo() was not called' );
isnt( $options{'x'}, 1, 'option "x" was not set' );

exit 0;

__END__

=pod

=head2 --foo - do a foo

Test

=cut

