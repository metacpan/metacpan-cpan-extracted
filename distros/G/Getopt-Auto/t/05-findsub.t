#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-findsub.t
#
#  DESCRIPTION:  Test configuration option "findsub"
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      COMPANY:
#      VERSION:  1.9.8
#      CREATED:  Mon Oct 19 15:02:10 PDT 2009
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 10;
use Test::Output;

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars))
## no critic (ProtectPrivateVars)
## no critic (ProtectPrivateSubs)

our %options;

BEGIN {
    @ARGV = qw(foo -b --c);
    use Getopt::Auto( { 'findsub' => 1, 'nohelp' => 1 } );
}

my $is_foo_called;
sub foo { $is_foo_called = 1; return; }

my $is_b_called;
sub b { $is_b_called = 1; return; }

my $is_c_called;
sub c { $is_c_called = 1; return; }

ok( $is_foo_called, 'foo() called' );
ok( $is_b_called,   'b() called' );
ok( $is_c_called,   'c() called' );

# The distinction here is that because the options -d and --e are
# not registered they are not stored as options internally in
# Getopt::Auto. Hence, it does not see them as options.
# When they are processed in @ARGV, _our_ %options should be set.

@ARGV = qw(-d --e);
stderr_is(
    \&Getopt::Auto::_parse_args,
    "Getopt::Auto: -d is not a registered option\n"
        . "Getopt::Auto: --e is not a registered option\n",
    '-d and -e are not registered options'
);
ok( Getopt::Auto::test_option('d') == 0,   '-d is not an option' );
ok( Getopt::Auto::test_option('--e') == 0, '--e is not an option' );
ok( !exists $options{'-d'},                 '-d is not in %options' );
ok( !exists $options{'--e'},                '--e is not in %options' );
ok( $ARGV[0] eq '-d',  '-d returned to ARGV' );
ok( $ARGV[1] eq '--e', '--e returned to ARGV' );

exit 0;

__END__
