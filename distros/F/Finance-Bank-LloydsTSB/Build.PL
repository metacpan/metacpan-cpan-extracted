#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
  module_name   => 'Finance::Bank::LloydsTSB',
  license       => 'perl',
  author        => 'Adam Spiers <aspiers@cpan.org>',
  requires      => {
    'WWW::Mechanize'     => 0.39,
    'HTML::TableExtract' => 0,
    'HTML::TreeBuilder'  => 0,
    'HTML::ElementTable' => 0,
  },
#  script_files  => [ 'fetch-statement.pl' ],
)->create_build_script;
