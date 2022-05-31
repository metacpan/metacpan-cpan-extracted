#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::DBI::Oracle;
use Firewall::Policy::Designer::Netscreen;
use Firewall::Policy::Searcher::Report::FwInfo;
use Firewall::Config::Element::Rule::Netscreen;

my $designer;

ok(
  do {
    my $searcherReportFwInfo;
    my $param = {
      'dstMap'   => { '10.31.12.3/32' => undef },
      'hit'      => 'dst',
      'fromZone' => 'V1-Untrust',
      'srvMap'   => { 'tcp/8080' => undef },
      'fwType'   => 'Netscreen',
      'srcMap'   => { '10.44.100.66/32' => undef },
      'action'   => {
        'new' => {
          'src' => { '10.44.100.66/32' => undef },
          'srv' => { 'tcp/8080'        => ['TCP_8080'] },
          'dst' => { '10.31.12.3/32'   => undef }
        }
      },
      'fwId'           => '1',
      'validModifyAct' => { 'add' => undef },
      'type'           => 'new',
      'policyId'       => undef,
      'toZone'         => 'V1-Trust',
      'ruleObj'        => Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'V1-Untrust',
        toZone   => 'V1-Trust',
        action   => 'permit',
        content  => '...',
        priority => 234
      ),
      'fwName' => 'FW_ZJ_SF_NS1'
    };
    eval {
      $searcherReportFwInfo = Firewall::Policy::Searcher::Report::FwInfo->new($param);

      #my $dbi = Firewall::DBI::Oracle->new( dsn => 'dbi:Oracle:host=10.31.10.25;sid=t0paitsm;port=1558', user => 'jemondata', password => 'rsms1234' );
      my $dbi = Firewall::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=10.25.10.72;sid=mt;port=1521',
        user     => 'rsms',
        password => 'test1234'
      );
      $designer = Firewall::Policy::Designer::Netscreen->new(
        searcherReportFwInfo => $searcherReportFwInfo,
        dbi                  => $dbi
      );
    };
    warn $@ if $@;
    $designer->isa('Firewall::Policy::Designer::Netscreen');
  },
  ' 生成 Firewall::Policy::Designer::Netscreen 对象'
);

