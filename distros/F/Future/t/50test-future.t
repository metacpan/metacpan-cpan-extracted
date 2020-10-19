#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Refcount;
use Test::Builder::Tester;

use Future;
use Test::Future;

# pass
{
   test_out( "ok 1 - immediate Future" );

   my $ran_code;
   no_pending_futures {
      $ran_code++;
      Future->done(1,2,3);
   } 'immediate Future';

   test_test( "immediate Future passes" );
   ok( $ran_code, 'actually ran the code' );
}

# fail
{
   test_out( "not ok 1 - pending Future" );
   test_fail( +8 );
   test_err( "# The following Futures are still pending:" );
   test_err( qr/^# 0x[0-9a-f]+\n/ );
   test_err( qr/^# Writing heap dump to \S+\n/ ) if Test::Future::HAVE_DEVEL_MAT_DUMPER;

   my $f;
   no_pending_futures {
      $f = Future->new;
   } 'pending Future';

   test_test( "pending Future fails" );

   $f->cancel;
}

# does not retain Futures
{
   test_out( "ok 1 - refcount 2 before drop" );
   test_out( "ok 2 - refcount 1 after drop" );
   test_out( "ok 3 - retain" );

   no_pending_futures {
      my $arr = [1,2,3];
      my $f = Future->new;
      $f->done( $arr );
      is_refcount( $arr, 2, 'refcount 2 before drop' );
      undef $f;
      is_refcount( $arr, 1, 'refcount 1 after drop' );
   } 'retain';

   test_test( "no_pending_futures does not retain completed Futures" );
}

# does not retain immedate Futures
{
   test_out( "ok 1 - refcount 2 before drop" );
   test_out( "ok 2 - refcount 1 after drop" );
   test_out( "ok 3 - retain" );

   no_pending_futures {
      my $arr = [1,2,3];
      my $f = Future->done( $arr );
      is_refcount( $arr, 2, 'refcount 2 before drop' );
      undef $f;
      is_refcount( $arr, 1, 'refcount 1 after drop' );
   } 'retain';

   test_test( "no_pending_futures does not retain immediate Futures" );
}

END {
   # Clean up Devel::MAT dumpfile
   my $pmat = $0;
   $pmat =~ s/\.t$/-1.pmat/;
   unlink $pmat if -f $pmat;
}

done_testing;
