use inc::Module::Install;

name        'Locale-Country-Geo';
all_from    'lib/Locale/Country/Geo.pm';

requires    'YAML::Syck' => '0';

sign; WriteAll(meta => 1);
