#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 28;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/carp.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

is($ebug->line, 6);
my($stdout, $stderr) = $ebug->output;
is($stdout, "");
is($stderr, "");

$ebug->step;
is($ebug->line, 7);
($stdout, $stderr) = $ebug->output;
is($stdout, "");
is($stderr, "");

$ebug->step;
is($ebug->line, 8);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
is($stderr, "");

$ebug->step;
is($ebug->line, 9);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
is($stderr, "\$x is -4 at t/carp.pl line 8, <GEN1> line 10.\n");

$ebug->step;
is($ebug->line, 13);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
is($stderr, "\$x is -4 at t/carp.pl line 8, <GEN1> line 10.\n");

$ebug->step;
is($ebug->line, 14);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
is($stderr, "\$x is -4 at t/carp.pl line 8, <GEN1> line 10.\n");

$ebug->next;
is($ebug->line, 15);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
like($stderr, qr{
  \Qx is -4 at t/carp.pl line 8\E .*
  \Qdebug: In square_root, -4 is -4 at t/carp.pl line 14\E .*
  \Qmain::square_root(-4) called at t/carp.pl line 9\E
}msx);

$ebug->next;
is($ebug->line, 16);
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
like($stderr, qr{
  \Qx is -4 at t/carp.pl line 8\E .*
  \Qdebug: In square_root, -4 is -4 at t/carp.pl line 14\E .*
  \Qmain::square_root(-4) called at t/carp.pl line 9\E
}msx);

$ebug->next;
ok($ebug->finished);
is($ebug->package, "DB::fake"); # bit of a side effect
($stdout, $stderr) = $ebug->output;
is($stdout, "Hi!\nAbout to get square_root(-4)\n");
like($stderr, qr{
  \Qx is -4 at t/carp.pl line 8\E .*
  \Qdebug: In square_root, -4 is -4 at t/carp.pl line 14\E .*
  \Qmain::square_root(-4) called at t/carp.pl line 9\E .*
  \Qsquare_root of negative number: -4 at t/carp.pl line 16\E .*
  \Qmain::square_root(-4) called at t/carp.pl line 9\E
}msx);

