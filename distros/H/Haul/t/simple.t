#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Test::More tests => 10;
use_ok('Haul');

my $h = Haul->new;
isa_ok($h, 'Haul');

mkdir "work";
chdir "work";

my $filename = $h->fetch("Acme::Colour");
like($filename, qr/Acme-Colour-1.00/);
ok(-f $filename);

my $dir = $h->extract("Acme::Colour");
like($dir, qr/Acme-Colour-1.00/);
ok(-d $dir);

$dir = $h->extract("Acme::Colour");
like($dir, qr/Acme-Colour-1.00/);
ok(-d $dir);

ok(!$h->installed("This::Module::Does::Not::Exist"));
ok($h->installed("Test::More"));

