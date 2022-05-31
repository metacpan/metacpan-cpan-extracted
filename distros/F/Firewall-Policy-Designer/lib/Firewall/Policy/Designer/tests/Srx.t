#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::DBI::Oracle;
use Firewall::Policy::Designer::Srx;
use Firewall::Policy::Searcher::Report::FwInfo;
use Firewall::Utils::Ip;
use Firewall::Config::Element::Rule::Srx;

my $designer;

ok(
  do {
    my $searcherReportFwInfo;
    my $param = {
      'dstMap'   => { '10.33.2.3/32' => undef },
      'hit'      => 'dst',
      'fromZone' => 'l2-untrust',
      'srvMap'   => { 'tcp/8080' => undef },
      'fwType'   => 'Srx',
      'srcMap'   => { '10.39.100.66/32' => undef },
      'action'   => {
        'new' => {
          'src' => { '10.39.100.66/32' => undef },
          'srv' => { 'tcp/8080'        => [ 'TCP_8080', 'tcp_8080' ] },
          'dst' => { '10.33.2.3/32'    => undef }
        }
      },
      'fwId'           => '6',
      'validModifyAct' => { 'add' => undef },
      'type'           => 'new',
      'policyId'       => undef,
      'toZone'         => 'l2-trust',
      'ruleObj'        => Firewall::Config::Element::Rule::Srx->new(
        fwId     => 6,
        ruleName => 'gogo',
        fromZone => 'l2-untrust',
        toZone   => 'l2-trust',
        content  => '...'
      ),
      'fwName' => 'FW_GL_SF_SRX3600_1'
    };
    eval {
      $searcherReportFwInfo = Firewall::Policy::Searcher::Report::FwInfo->new($param);
      my $dbi = Firewall::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=10.31.10.25;sid=t0paitsm;port=1558',
        user     => 'jemondata',
        password => 'rsms1234'
      );

      #my $dbi = Firewall::DBI::Oracle->new( dsn => 'dbi:Oracle:host=10.25.10.72;sid=mt;port=1521', user => 'rsms', password => 'test1234' );
      $designer = Firewall::Policy::Designer::Srx->new(
        searcherReportFwInfo => $searcherReportFwInfo,
        dbi                  => $dbi
      );
      say dumper $designer->design;
    };
    warn $@ if $@;
    $designer->isa('Firewall::Policy::Designer::Srx');
  },
  ' 生成 Firewall::Policy::Designer::Srx 对象'
);

