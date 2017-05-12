use inc::Module::Install;

name           'Mail-SNCF';
license        'perl';
all_from       'lib/Mail/SNCF.pm';

requires	   'Data::ICal'         => 0;
requires       'Data::ICal::Entry::Event' => 0;
requires       'Date::ICal'         => 0;
requires       'DateTime'           => 0;
requires       'Email::Folder'      => 0;
requires       'Data::Dump'         => 0;

test_requires  'Test::More'         => '0.42';
test_requires  'Test::Dependencies' =>  0;

install_script 'sncf-parse';

WriteAll;

