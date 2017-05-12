#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-multiple.t
#
#  DESCRIPTION:  Test multiple configuration options
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

use Test::More tests => 9;    # last test to print

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateSubs)

BEGIN {

    # These need to be in place _before_  INIT block
    @ARGV = qw(foo --bar -b );
    use Getopt::Auto(
        { 'nobare' => 1, 'noshort' => 1, 'init' => \&my_init } );
}

my $is_init_called;
sub my_init { $is_init_called = 1; return; }

my $is_foo_called;
sub foo { $is_foo_called = 1; return; }

my $is_b_called;
sub b { $is_b_called = 1; return; }

my $is_bar_called;
sub bar { $is_bar_called = 1; return; }

ok( $is_init_called,          'my_init() called' );
ok( !defined($is_foo_called), 'foo() not called' );
ok( $is_bar_called,           'bar() called' );
ok( !defined($is_b_called),   'b() not called' );

ok( Getopt::Auto::test_option('foo') == 0,   'foo is not an option' );
ok( Getopt::Auto::test_option('--bar') == 1, '--bar is an option' );
ok( Getopt::Auto::test_option('b') == 0,     'b is not an option' );

ok( $ARGV[0] eq 'foo', 'Unused command line argument "foo" remains' );
ok( $ARGV[1] eq '-b',  'Unused command line argument "-b`" remains' );

exit 0;

__END__

=pod

=head2 foo - do a bare foo

=head2 --bar - do a bar

=cut
