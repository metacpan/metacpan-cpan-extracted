#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Keywords 'none';

# Basic true/false testing
ok( !(none { $_ > 10 } 1 .. 20), 'list contains a value above ten' );
ok(  (none { $_ > 10 } 1 .. 9), 'list does not contain a value above ten' );

# none empty list is true
{
   my $invoked;
   my $ret = none { $invoked++ } ();
   ok( $ret, 'none on empty list is true' );
   ok( !$invoked, 'none on empty list did not invoke block' );
}

# none failure yields scalar in list context
{
   my @ret;
   @ret = none { $_ > 10 } 1 .. 9;
   ok( !!@ret, 'none nothing yielded false in list context' );

   @ret = none { $_ > 10 } ();
   ok( !!@ret, 'none nothing yielded false in list context on empty input' );
}

done_testing;
