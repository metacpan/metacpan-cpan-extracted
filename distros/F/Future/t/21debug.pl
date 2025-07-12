use v5.10;
use strict;
use warnings;

use Test2::V0;

plan skip_all => "Message format changed" if defined $Future::XS::VERSION and $Future::XS::VERSION lt '0.14';

use Time::HiRes qw( gettimeofday tv_interval );

BEGIN {
   $ENV{PERL_FUTURE_DEBUG} = 1;
   Future::XS::reread_environment() if defined &Future::XS::reread_environment;
}

use Future;

my $FILE = __FILE__;
$FILE = qr/\Q$FILE\E/;

my $LINE;
my $LOSTLINE;

sub warnings_from(&)
{
   my $code = shift;
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= shift };
   $code->();
   $LOSTLINE = __LINE__; return $warnings;
}

is( warnings_from {
      my $f = Future->new;
      $f->done;
   }, "", 'Completed Future does not give warning' );

is( warnings_from {
      my $f = Future->new;
      $f->cancel;
   }, "", 'Cancelled Future does not give warning' );

like( warnings_from {
      $LINE = __LINE__; my $f = Future->new->set_label( "the-label" );
      undef $f;
   },
   qr/^Future=\S+ \("the-label"\) \(constructed at $FILE line $LINE\) was lost near $FILE line (?:$LOSTLINE|${\($LINE+1)}) before it was ready\.?$/,
   'Lost Future raises a warning' );

my $THENLINE;
my $SEQLINE;
like( warnings_from {
      $LINE = __LINE__; my $f1 = Future->new->set_label( "label-1" );
      $THENLINE = __LINE__; my $fseq = $f1->then( sub { } )->set_label( "label-2" ); undef $fseq;
      $SEQLINE = __LINE__; $f1->done;
   },
   qr/^Future=\S+ \("label-2"\) \(constructed at $FILE line $THENLINE\) was lost near $FILE line (?:$SEQLINE|$THENLINE) before it was ready\.?
Future=\S+ \("label-1"\) \(constructed at $FILE line $LINE\) lost a sequence Future at $FILE line $SEQLINE\.?$/,
   'Lost sequence Future raises warning' );

like( warnings_from {
      $LINE = __LINE__; my $f = Future->fail("Failed!");
      undef $f;
   },
   qr/^Future=\S+ \(constructed at $FILE line $LINE\) was lost near $FILE line (?:$LOSTLINE|${\($LINE+1)}) with an unreported failure of: Failed!\.?/,
   'Destroyed failed future raises warning' );

{
   $Future::TIMES or
      BAIL_OUT( "Need to set \$Future::TIMES = 1" );

   my $before = [ gettimeofday ];

   my $future = Future->new;

   ok( defined $future->btime, '$future has btime with $TIMES=1' );
   ok( tv_interval( $before, $future->btime ) >= 0, '$future btime is not earlier than $before' );

   $future->done;

   ok( defined $future->rtime, '$future has rtime with $TIMES=1' );
   ok( tv_interval( $future->btime, $future->rtime ) >= 0, '$future rtime is not earlier than btime' );
   ok( tv_interval( $future->rtime ) >= 0, '$future rtime is not later than now' );

   ok( defined $future->elapsed, '$future has ->elapsed time' );
   ok( $future->elapsed >= 0, '$future elapsed time >= 0' );

   my $imm = Future->done;

   ok( defined $imm->rtime, 'Immediate future has rtime' );
   ok( defined $imm->elapsed, 'Immediate future has ->elapsed time' );
   ok( $imm->elapsed >= 0, 'Immediate future elapsed time >= 0' );
}

done_testing;
