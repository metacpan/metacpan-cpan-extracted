# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-12-21 22:40:31 +0000 (Sat, 21 Dec 2013) $
# Id:            $Id: Build.PL 311 2013-12-21 22:40:31Z rmp $
# $HeadURL$
#
use strict;
use warnings;
use Module::Build;
use Carp;
use English qw(-no_match_vars);

my $class = Module::Build->subclass(
                                    class => 'Module::Build::HamDXCC',
                                    code  => <<'SUBCLASS' );
sub run_tap_harness {
  my ($self, $tests) = @_;

  require TAP::Harness::JUnit;

  # TODO allow the test @INC to be set via our API?

  my $aggregate = TAP::Harness::JUnit->new({
    lib => [@INC],
    verbosity => $self->{properties}{verbose},
    switches  => [ $self->harness_switches ],
    %{ $self->tap_harness_args },
  })->runtests(@$tests);

  return $aggregate;
}

SUBCLASS

my $builder = $class->new(
                          module_name         => 'Ham::DXCC',
                          dist_author         => 'Roger Pettett <rmp@psyphi.net>',
                          version_from        => 'lib/Ham/DXCC.pm',
                          dist_abstract       => q[DXCC cty.xml fetching & parsing],
                          license             => 'gpl',
                          requires            => {
                                                  'strict'                  => '1.03',
                                                  'warnings'                => '1.05',
                                                  'base'                    => '2.07',
                                                  'Carp'                    => '1.04',
                                                  'English'                 => '1.02',
                                                  'LWP::Simple'             => '6.00',
                                                  'XML::XPath'              => '1.13',
                                                 },
                          recommends          => {
                                                 },
                          build_requires      => {
                                                  'Test::More'              => '0.62',
                                                  'TAP::Harness::JUnit'     => '0.41',
                                                 },
                          build_recommends    => {
                                                  'Test::Distribution'      => '2.00',
                                                  'Test::Perl::Critic'      => '1.01',
                                                 },
                          script_files        => [qw(bin/dxcc-update)],
                          use_tap_harness     => 1,
                          tap_harness_args    => {
                                                  jobs      => 10,
                                                  verbosity => 1,
                                                  merge     => 1,
                                                  xmlfile   => 'tap-harness-junit.xml',
                                                 },
#                          sign                => 1,
                         );

$builder->create_build_script();
