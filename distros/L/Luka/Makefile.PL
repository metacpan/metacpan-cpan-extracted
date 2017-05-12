use inc::Module::Install;

name('Luka');
author('Toni Prug <toni@irational.org>');
abstract('Exception handling and reporting framework');
license('gpl');
version_from('lib/Luka.pm');

build_requires(qw(
	   Net::FTP 0
));

requires(qw(
	Error 0
	version 0
        Sub::Uplevel 0 
	Class::Std 0
	Test::Exception 0
	Exception::Class 1.21
	Config::IniFiles 0
	Sys::Syslog 0
	Sys::Hostname 0
	Sys::Hostname::Long 0
	Mail::SendEasy 0
        Test::More 0
        What::MTA 0
));

auto_install;
WriteAll;
