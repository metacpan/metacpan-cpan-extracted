######################################################################
# Test suite for LWP::UserAgent::POE
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Log::Log4perl qw(:easy);
use LWP::UserAgent::POE;
use POE;

plan tests => 2;
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }

my $ticks = 0;
my $STOP   = 0;
my $UA;

#Log::Log4perl->easy_init($INFO);

POE::Session->create(
  inline_states => {
    _start => sub { 
                $_[KERNEL]->yield("next");
                urlfetch();
              },
    next   => sub {
                $_[KERNEL]->delay(next => .01) unless $STOP;
                $ticks++;
    },
    theend => sub {
                $STOP = 1;
                undef $UA;
              },
  },
);

POE::Kernel->run();

###########################################
sub urlfetch {
###########################################
   $UA = LWP::UserAgent::POE->new();
   my $resp = $UA->get( "http://www.yahoo.com" );

   my $code = $resp->code();
   like($code, qr/^(200|500)$/, "Return code");
   ok($ticks != 0, "number of ticks != 0 ($ticks)");
   $poe_kernel->yield("theend");
}
