#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Commandable::Invocation;

use Devel::MAT::Dumper;
use Devel::MAT;

use Future;

use constant USING_FUTURE_XS => defined &Future::XS::new;

use Scalar::Util qw( refaddr );

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# Boot the tool
$pmat->available_tools;

# TODO: Consider extracting this into some sort of reusable library, maybe even
# into Devel::MAT itself
my $output;
package Devel::MAT::Cmd {
   sub printf {
      shift;
      my ( $fmt, @args ) = @_;
      $output .= sprintf $fmt, @args;
   }
}

sub output_matches_ok(&$$)
{
   my ( $code, $want, $name ) = @_;

   $output = "";
   $code->();

   $want = quotemeta $want;
   $want =~ s/_ADDR_/0x[0-9a-f]+/g;
   $want =~ s/_NUM_/\\d+/g;

   like( $output, qr/^$want$/, $name );
}

BEGIN {
   our %FUTURES = (
      pending   => Future->new,
      done      => Future->new->done( 1, 2, 3 ),
      failed    => Future->new->fail( "oops" ),
      cancelled => Future->new,
   );

   $FUTURES{cancelled}->cancel;
}

my $MATCH_Future = USING_FUTURE_XS ? "SCALAR(UV)=Future" : "HASH(_NUM_)=Future";
my $DETAIL       = USING_FUTURE_XS ? "UV=_NUM_"          : "_NUM_ values (use 'values' command to show)";

# show command with added output
#   Note: these tests are quite fragile as they depend on the exact output format of 'show'
{
   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "show " . (refaddr $::FUTURES{pending}) ) );
   } <<"EOF", 'output from "show" command on pending';
$MATCH_Future at _ADDR_ with refcount 1
  size _NUM_ bytes
  blessed as Future
  Future state pending
  $DETAIL
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "show " . (refaddr $::FUTURES{done}) ) );
   } <<"EOF", 'output from "show" command on done';
$MATCH_Future at _ADDR_ with refcount 1
  size _NUM_ bytes
  blessed as Future
  Future state done
  Future result: SCALAR(UV) at _ADDR_ = 1, ...
  $DETAIL
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "show " . (refaddr $::FUTURES{failed}) ) );
   } <<"EOF", 'output from "show" command on failed';
$MATCH_Future at _ADDR_ with refcount 1
  size _NUM_ bytes
  blessed as Future
  Future state failed
  Future failure: "oops"
  $DETAIL
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "show " . (refaddr $::FUTURES{cancelled}) ) );
   } <<"EOF", 'output from "show" command on cancelled';
$MATCH_Future at _ADDR_ with refcount 1
  size _NUM_ bytes
  blessed as Future
  Future state cancelled
  $DETAIL
EOF
}

# find future filter
{
   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "find future -p" ) );
   } <<"EOF", 'output from "find future -p" command';
$MATCH_Future at _ADDR_: Future(pending)
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "find future -d" ) );
   } <<"EOF", 'output from "find future -d" command';
$MATCH_Future at _ADDR_: Future(done) - SCALAR(UV) at _ADDR_ = 1, ...
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "find future -f" ) );
   } <<"EOF", 'output from "find future -f" command';
$MATCH_Future at _ADDR_: Future(failed) - "oops"
EOF

   output_matches_ok {
      $pmat->run_command( Commandable::Invocation->new( "find future -c" ) );
   } <<"EOF", 'output from "find future -c" command';
$MATCH_Future at _ADDR_: Future(cancelled)
EOF
}

done_testing;
