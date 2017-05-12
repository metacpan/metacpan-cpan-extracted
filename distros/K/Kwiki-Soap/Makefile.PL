use inc::Module::Install;

name('Kwiki-Soap');
abstract('Access SOAP services from kwiki wafl phrase');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/SOAP.pm');
license('perl');

requires('Kwiki');
requires('Test::More');
requires('SOAP::Lite');

check_nmake();

&WriteAll();
