use inc::Module::Install;

name           'Kwiki-Textile';
all_from       'lib/Kwiki/Textile.pm';
build_requires 'Test::Base';
requires       'Kwiki' => 0.38;

&WriteAll;

