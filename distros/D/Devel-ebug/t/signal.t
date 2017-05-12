#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use Test::More;

plan skip_all => "Devel::ebug does not handle signals under Windows atm" if $^O =~ /mswin32/i;
plan tests => 8;

my $ebug = Devel::ebug->new;
$ebug->program("t/signal.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

$ebug->run;
is($ebug->finished, 0);
is($ebug->line, 8);
my $pad = $ebug->pad;
is($pad->{'$i'}, 11);
is($pad->{'$square'}, 121);

$ebug->run;
is($ebug->finished, 0);
is($ebug->line, 8);
$pad = $ebug->pad;
is($pad->{'$i'}, 12);
is($pad->{'$square'}, 144);

