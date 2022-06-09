#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::DBI::Oracle;

=lala
has dsn => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has user => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has dbi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_buildDbi',
);

has option => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub { {} },
);
=cut

my $db = {
  mt => {
    host     => '10.25.10.72',
    port     => 1521,
    sid      => 'mt',
    user     => 'mojo',
    password => 'test1234'
  },
  mojo => {
    host     => '10.31.10.25',
    port     => 1558,
    sid      => 'mojo',
    user     => 'mojo',
    password => 'mojo1234'
  },
};

my $dbi;

ok(
  do {
    my ( $dbi2, $dbi3 );
    eval {
      $dbi = Firewall::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=10.31.10.25;sid=mojo;port=1558',
        user     => 'mojo',
        password => 'mojo1234'
      );

      #$dbi = Firewall::DBI::Oracle->new( dsn => 'dbi:Oracle:host=10.25.10.72;sid=mt;port=1521', user => 'mojo', password => 'test1234' );
      my $param = $db->{mojo};
      $dbi2 = Firewall::DBI::Oracle->new($param);
      $dbi3 = Firewall::DBI::Oracle->new(%$param);
    };
    warn $@ if $@;
    $dbi->isa('Firewall::DBI::Oracle')
      and $dbi2->isa('Firewall::DBI::Oracle')
      and $dbi3->isa('Firewall::DBI::Oracle');
  },
  ' 生成 Firewall::DBI::Oracle 对象'
);

=lala
say dumper $dbi->execute("select sysdate from dual")->all;
my $lala = $dbi->clone;
say dumper $lala->execute("select sysdate from dual")->all;
sleep;
=cut
