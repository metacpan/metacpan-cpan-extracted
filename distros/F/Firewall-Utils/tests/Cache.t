#!/usr/bin/env perl

use strict;
use warnings;
use 5.018;
use Test::Simple tests => 5;
use Mojo::Util qw(dumper);

use lib "/works/firewall/lib";
use Firewall::Utils::Cache;

my $cache;

ok(
  do {
    eval { $cache = new Firewall::Utils::Cache };
    warn $@ if $@;
    $cache->isa('Firewall::Utils::Cache');
  },
  ' 生成 Firewall::Utils::Cache 对象'
);

ok(
  do {
    eval { $cache = Firewall::Utils::Cache->new( cache => { lala => { lele => { lili => { lolo => 'lulu' } } } } ) };
    warn $@ if $@;
    $cache->locate(qw/ lala lele lili /)->{lolo} eq 'lulu';
  },
  ' locate'
);

ok(
  do {
    eval { $cache = Firewall::Utils::Cache->new( cache => { lala => { lele => { lili => { lolo => 'lulu' } } } } ) };
    warn $@ if $@;
    $cache->get(qw/ lala lele lili /)->{lolo} eq 'lulu';
  },
  ' get'
);

ok(
  do {
    eval { $cache = Firewall::Utils::Cache->new( cache => { lala => { lele => { lili => { lolo => 'lulu' } } } } ) };
    warn $@ if $@;
    $cache->clear(qw/ lala lele lili lolo /);
    my $ref = $cache->get(qw/ lala lele lili /);
    defined $ref and not exists $ref->{lolo};
  },
  ' locate'
);

ok(
  do {
    eval { $cache = Firewall::Utils::Cache->new( cache => { lala => { lele => { lili => { lolo => 'lulu' } } } } ) };
    warn $@ if $@;
    $cache->set(qw/ lala lele lili 2 /);
    $cache->get(qw/ lala lele lili /) eq '2';
  },
  ' set'
);
