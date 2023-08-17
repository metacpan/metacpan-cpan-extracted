#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestCPANfile;
use Clone qw(clone);

use Dist::Zilla::Plugin::SyncCPANfile;

my $log = '';

{
    no warnings 'redefine';

    sub Dist::Zilla::Plugin::SyncCPANfile::log {
        my ($self, $msg) = @_;

        $log .= $msg . "\n";
    }
}

sub test_cpanfile {
    my $desc    = shift;
    my $prereqs = shift;
    my $config  = shift;
    my $tests   = shift;
    my $test    = build_dist( clone( $prereqs ), $config);

    my $content = $test->{cpanfile}->slurp_raw;
    ok check_cpanfile( $content, $prereqs ), $desc;

    like $content, qr/"ExtUtils::MakeMaker"\s+=>\s+"?(?!0)/;

    my ($version) =  $content =~ m/"ExtUtils::MakeMaker"\s+=>\s+"?([0-9]+)/;
    cmp_ok $version, '>', 0;

    for my $regex_test ( @{ $tests || [] } ) {
        for my $regex ( @{ $regex_test->{content} || [] } ) {
            like $content, $regex, "$regex matches content";
        }

        for my $regex ( @{ $regex_test->{log} || [] } ) {
            like $log, $regex, "$regex matches log";
        }
    }
}

test_cpanfile
  'cpan_audit - simple prereq',
  [
      Prereqs => [
          'Mojo::File' => 8,
          'ExtUtils::MakeMaker' => 0,
      ]
  ],
  { cpan_audit => 1 },
  [
      { log => [ qr/Mojo::File 8 is vulnerable/ ] },
  ]
;

test_cpanfile
  'cpan_audit - version range excludes fixed version',
  [
      Prereqs => [
          'Mojo::File' => ">8.1,<9.1",
          'ExtUtils::MakeMaker' => 0,
      ]
  ],
  { cpan_audit => 1 },
  [
      { content => [ qr/"Mojo::File" => "> 8.1, < 9.1"/ ] },
      { log     => [ qr/Range '> 8.1, < 9.1' for Mojo::File does not include latest fixed version/ ] },
  ]
;

done_testing;
