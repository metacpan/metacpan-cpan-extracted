#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Devel::MAT; } or
      plan skip_all => "No Devel::MAT";

   require Devel::MAT::Dumper;
}

use Future;

use Future::AsyncAwait;

my $f1 = Future->new;
my $fret = (async sub { local $@; await $f1 })->();

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

$f1->done;
$fret->get;

pass( "did not crash" );

done_testing;
