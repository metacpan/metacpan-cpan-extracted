# -*- perl -*-

use strict;
use inc::Module::Install;

perl_version    5.004;

name		('Gtk2-Net-LDAP-Widgets');
module_name	('Gtk2::Net::LDAP::Widgets');
author		('Aleksander Adamowski <cpan@olo.org.pl>');
version_from	('Widgets.pm');
license		('perl');
abstract_from	('Widgets.pm');

sign(1);

check_nmake();      # check and download nmake.exe for Win32

requires        ( 'Gtk2' => 1.0, 'Net::LDAP' => 0.20);

include_deps	('Test::More');
include 	('ExtUtils::AutoInstall');

auto_install_now();

WriteAll;
