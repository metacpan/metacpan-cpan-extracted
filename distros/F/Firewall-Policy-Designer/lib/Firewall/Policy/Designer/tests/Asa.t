#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::DBI::Oracle;
use Firewall::Policy::Designer::Asa;
use Firewall::Policy::Searcher::Report::FwInfo;
use Firewall::Utils::Ip;
use Firewall::Config::Element::Rule::Asa;

my $designer;

ok(
  do {
    my $searcherReportFwInfo;
    my $param = {

      'dstMap'   => { '10.11.108.69/32' => undef },
      'hit'      => 'dst',
      'exist'    => undef,
      'fromZone' => 'outbond',
      'srvMap'   => { 'tcp/8896' => undef },
      'fwType'   => 'Asa',
      'srcMap'   => { '10.25.6.69/32' => undef },
      'action'   => {
        'new' => {
          'src' => { '10.25.6.69/32'   => undef },
          'srv' => { 'tcp/8896'        => undef },
          'dst' => { '10.11.108.69/32' => undef }
        }
      },
      'fwId'           => '14',
      'validModifyAct' => { 'add' => undef },
      'type'           => 'new',
      'policyId'       => undef,
      'toZone'         => 'inbond',
      'ruleObj'        => Firewall::Config::Element::Rule::Asa->new(
        fwId          => 14,
        zone          => 'inbond',
        aclName       => 'inbond',
        aclLineNumber => 5,
        action        => 'permit',
        content       => '...'
      ),
      'fwName' => 'FW-GL-NM-ASA'

    };
    eval {

      $searcherReportFwInfo = Firewall::Policy::Searcher::Report::FwInfo->new($param);

      my $dbi = Firewall::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=10.31.10.25;sid=t0paitsm;port=1558',
        user     => 'jemondata',
        password => 'rsms1234'
      );

      #my $dbi = Firewall::DBI::Oracle->new( dsn => 'dbi:Oracle:host=10.25.10.72;sid=mt;port=1521', user => 'rsms', password => 'test1234' );
      $designer = Firewall::Policy::Designer::Asa->new(
        searcherReportFwInfo => $searcherReportFwInfo,
        dbi                  => $dbi
      );

      #say dumper $designer->design;
    };
    warn $@ if $@;
    $designer->isa('Firewall::Policy::Designer::Asa');
  },
  ' 生成 Firewall::Policy::Designer::Asa 对象'
);

