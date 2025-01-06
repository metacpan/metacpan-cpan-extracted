#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'DateTimeX::Start',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/DateTimeX/Start.pm',
   ABSTRACT_FROM  => 'lib/DateTimeX/Start.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
   clean          => { FILES => 'DateTimeX-Start-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker' => 6.74,
            },
         },
         runtime => {
            requires => {
               'Carp'                => 0,
               'DateTime'            => 0,
               'DateTime::TimeZone'  => 0,
               'Exporter'            => 0,
               'Scalar::Util'        => 0,
               'strict'              => 0,
               'version'             => 0,
               'warnings'            => 0,
            },
            # recommends => { },
            # suggests => { },
         },
         test => {
            requires => {
               'Test::More'          => 0,
            },
            recommends => {
               'DateTime::TimeZone'  => 1.53,  # Tests are skipped with earlier versions.
               'Test::Pod'           => 1.22,
            },
         },
         develop => {
            requires => {
               'DateTime::TimeZone'  => 1.53,  # Key tests are skipped with earlier versions.
               'Pod::Coverage'       => 0.18,
               'Test::Pod::Coverage' => 1.08,
            },
         },
      },

      resources => {
         homepage => 'https://metacpan.org/dist/DateTimeX-Start/',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web => 'https://github.com/ikegami/perl-DateTimeX-Start/issues'
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-DateTimeX-Start.git',
            web  => 'https://github.com/ikegami/perl-DateTimeX-Start',
         },
      },
   },
);
