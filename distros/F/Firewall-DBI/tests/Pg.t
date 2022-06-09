#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::DBI::Pg;

#dbi:Pg:dbname=$param{dbname};host=$param{host};port=$param{port}
my $db = {
  firewall => {
    host     => '192.168.31.194',
    port     => 5432,
    dbname   => 'firewall',
    user     => 'postgres',
    password => 'postgres'
  },
};

my $dbi;

ok(
  do {
    my ( $dbi2, $dbi3 );
    eval {
      $dbi = Firewall::DBI::Pg->new(
        dsn      => 'dbi:Pg:dbname=firewall;host=192.168.31.194;port=5432',
        user     => 'postgres',
        password => 'postgres'
      );
      my $param = $db->{firewall};
      $dbi2 = Firewall::DBI::Pg->new($param);
      $dbi3 = Firewall::DBI::Pg->new( %{$param} );
    };
    warn $@ if $@;
    $dbi->isa('Firewall::DBI::Pg')
      and $dbi2->isa('Firewall::DBI::Pg')
      and $dbi3->isa('Firewall::DBI::Pg');
  },
  ' 生成 Firewall::DBI::Pg 对象'
);

say dumper $dbi->execute("select * from fw_basekey")->all;
my $lala = $dbi->clone;
say dumper $lala->execute("select * from fw_basekey")->all;
sleep;
