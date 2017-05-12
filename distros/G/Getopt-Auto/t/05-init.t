#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-init.t
#
#  DESCRIPTION:  Test advanced option "init"
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

use Test::More tests => 3;    # last test to print

use 5.006;
our $VERSION = '1.9.8';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProtectPrivateSubs)

BEGIN {
    @ARGV = qw(--bar);
    use Getopt::Auto( { 'init' => \&my_init } );
}

my $is_init_called;
sub my_init { $is_init_called = 1; return; }

my $is_bar_called;
sub bar { $is_bar_called = 1; return; }

ok( $is_init_called,                          'my_init() called' );
ok( $is_bar_called,                           'bar() called' );
ok( Getopt::Auto::test_option('--bar') == 1, '--bar is an option' );

exit 0;

__END__

=pod

=head2 --bar - do a bar

=cut
