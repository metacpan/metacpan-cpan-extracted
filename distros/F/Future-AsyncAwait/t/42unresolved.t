#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount 0.09 import => [qw( is_refcount refcount )];

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;
my $file = quotemeta __FILE__;

my $errgv_ref = \*@;

async sub identity
{
   return await $_[0];
}

async sub func
{
   my ( $f, @vals ) = @_;

   my $pad = "foo" . ref($f);
   my $x = 123;
   $x + 1 + [ "a", await identity $f ];
}

# abandoned chain
{
   my $f1 = Future->new;
   my $fret = func( $f1, 1, 2 );

   undef $fret;
   pass( 'abandoned chain does not crash' );
}

# abandoned subsequent (RT129303)
{
   my $f1 = Future->new;
   my $fret = func( $f1, 3, 4 );

   undef $fret;

   my $warnings = "";
   {
      local $SIG{__WARN__} = sub { $warnings .= join "", @_ };
      $f1->done;
   }
   pass( 'abandoned subsequent does not crash' );
   like( $warnings, qr/^Suspended async sub main::func lost its returning future at $file line \d+/,
      'warning from attempted resume' );
}

# abandoned subsequent on anon sub
{
   my $f1 = Future->new;
   my $fret = (async sub { await $f1 })->();

   undef $fret;

   my $warnings = "";
   {
      local $SIG{__WARN__} = sub { $warnings .= join "", @_ };
      $f1->done;
   }
   pass( 'abandoned subsequent does not crash' );
   like( $warnings, qr/^Suspended async sub CODE\(0x[0-9a-f]+\) in package main lost its returning future at $file line \d+/,
      'warning from attempted resume' );
}

# abandoned foreach loop (RT129320)
{
   my $f1 = Future->new;
   my $fret = (async sub { foreach my $f ($f1) { await $f } })->();

   undef $fret;
   pass( "abandoned foreach loop does not crash" );
}

# abandoned local $@
{
   my $errsv_refcount = refcount(\$@);
   my $errgv_refcount = refcount($errgv_ref);

   my $f1 = Future->new;
   my $fret = (async sub { local $@; await $f1 })->();

   undef $fret;
   undef $f1;
   pass( "abandoned local \$@ does not crash" );

   is_refcount( \$@, $errsv_refcount, '$@ refcount preserved' );
   is_refcount( $errgv_ref, $errgv_refcount, '*@ refcount preserved' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;
