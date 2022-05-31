#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 2;
use Mojo::Util qw(dumper);

use lib "/works/firewall/lib";
use Firewall::Utils::Date;

my $date;

ok(
  do {
    eval { $date = Firewall::Utils::Date->new };
    warn $@ if $@;
    $date->isa('Firewall::Utils::Date');
  },
  ' 生成 Firewall::Utils::Date 对象'
);

ok(
  do {
    eval { $date = Firewall::Utils::Date->new };
    warn $@ if $@;
    my $time = 1387431015;
    say dumper $date->getFormatedDate($time);
    say dumper $date->getFormatedDate();
  },
  ' getFormatedDate'
);
