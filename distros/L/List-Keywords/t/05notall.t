#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Keywords 'notall';

# Basic true/false testing
ok(  (notall { $_ < 10 } 1 .. 20), 'notall list values below ten' );
ok( !(notall { $_ < 10 } 1 .. 9), 'not notall list values below ten' );

# notall empty list is true
{
   my $invoked;
   my $ret = notall { $invoked++ } ();
   ok( defined $ret, 'notall on empty list is defined' );
   ok( !$ret, 'notall on empty list is false' );
   ok( !$invoked, 'notall on empty list did not invoke block' );
}

# notall failure yields scalar in list context
{
   my @ret;
   @ret = notall { $_ > 10 } 1 .. 9;
   ok( !!@ret, 'notall nothing yielded false in list context' );

   @ret = notall { $_ > 10 } ();
   ok( !!@ret, 'notall nothing yielded false in list context on empty input' );
}

done_testing;
