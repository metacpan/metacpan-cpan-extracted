use inc::Module::Install;

name('Kwiki-Technorati');
abstract('Access Technorati Cosmos with WAFL');
author('Chris Dent <chris.dent@socialtext.com>');
version_from('lib/Kwiki/Technorati.pm');
license('perl');

requires('Kwiki::FetchRSS');

check_nmake();

&WriteAll();
