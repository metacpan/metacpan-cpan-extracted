#!/usr/bin/perl -w

use strict;
use warnings;
use lib 'inc';

use My::Build;

my $build = My::Build->new
  ( module_name => 'ExtUtils::XSpp',
    license     => 'perl',
    requires    =>
      { 'perl'                => '5.6.1',
        'ExtUtils::ParseXS'   => '3.07',
        'ExtUtils::Typemaps'  => '1',
        'Digest::MD5'         => '2.0',
        },
    build_requires =>
      { 'Test::Base'          => '0',
        'Test::Differences'   => '0',
        },
    add_to_cleanup => [ qw(t/files/foo.h) ],
    script_files => 'scripts',
    );
$build->create_build_script;
