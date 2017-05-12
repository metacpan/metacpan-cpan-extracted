use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;

name 'Gtk2-Notify';
license 'lgpl';
all_from 'lib/Gtk2/Notify.pm';

notify or exit;

requires 'Gtk2';

configure_requires 'Gtk2::CodeGen';
configure_requires 'Glib::MakeHelper';
configure_requires 'ExtUtils::Depends';
configure_requires 'ExtUtils::PkgConfig';

no_index directory => qw/inc ext/;

WriteAll;
