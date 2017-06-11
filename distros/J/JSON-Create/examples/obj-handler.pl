#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use JSON::Create;
package Monkey::Shines;
sub new { return bless {}; }
1;
package Monkey::Shines::Bool;
sub true { my $monkey = 1; return bless \$monkey; }
sub false { my $monkey = 0; return bless \$monkey; }
1;
package main;
my $monkeys = {
    CuriousGeorge => Monkey::Shines->new (),
    KingKong => Monkey::Shines::Bool->true (),
    FunkyKong => Monkey::Shines::Bool->false (),
    PeterTork => "Monkees",
};
my $obj_handler = sub {
    my ($obj) = @_;
    if (ref ($obj) =~ /bool/i) {
	return $$obj ? 'true' : 'false';
    }
    else {
	return 'null';
    }
};
my $jc = JSON::Create->new ();
print $jc->run ($monkeys), "\n";
$jc->obj_handler ($obj_handler);
print $jc->run ($monkeys), "\n";
$jc->obj_handler ();
print $jc->run ($monkeys), "\n";
