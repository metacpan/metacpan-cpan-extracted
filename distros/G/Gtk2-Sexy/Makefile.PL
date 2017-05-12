#!/usr/bin/env perl

use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;

name 'Gtk2-Sexy';
license 'lgpl';
perl_version '5.008';
all_from 'lib/Gtk2/Sexy.pm';

sexy or exit;

requires 'Gtk2';

configure_requires 'Cwd';
configure_requires 'File::Spec';
configure_requires 'Gtk2::CodeGen';
configure_requires 'Glib::MakeHelper';
configure_requires 'ExtUtils::Depends';
configure_requires 'ExtUtils::PkgConfig';

test_requires 'Gtk2::TestHelper';

no_index directory => qw/inc ext/;

extra_tests;
auto_provides;

WriteAll;
