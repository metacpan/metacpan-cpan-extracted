use inc::Module::Install;

name('Kwiki-Soap-Google');
abstract('Access Google SOAP services from kwiki wafl phrase');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/SOAP/Google.pm');
license('perl');

requires('Kwiki::SOAP');
requires('Test::More');

check_nmake();

&WriteAll();
