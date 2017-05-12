#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  05-nobare.t
#
#  DESCRIPTION:  Test advanced option "nobare"
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
    @ARGV = qw(foo --bar);
    use Getopt::Auto( { 'nobare' => 1 } );
}

my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( !defined($is_foo_called), 'foo() not called' );

ok( Getopt::Auto::test_option('foo') == 0,   'foo is not an option' );
ok( Getopt::Auto::test_option('--bar') == 1, '--bar is an option' );

exit 0;

__END__

=pod

=head2 foo - do a bare foo

=head2 --bar - do a bar

=cut
