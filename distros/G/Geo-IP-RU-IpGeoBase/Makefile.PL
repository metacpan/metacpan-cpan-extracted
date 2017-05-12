use inc::Module::Install;

all_from     'lib/Geo/IP/RU/IpGeoBase.pm';
readme_from  'lib/Geo/IP/RU/IpGeoBase.pm';

requires     'Archive::Extract';
requires     'DBI';
requires     'Encode';
requires     'File::Spec';
requires     'File::Temp';
requires     'Getopt::Long';
requires     'LWP::Simple';

install_script 'bin/ip-geo-base-ru';

WriteAll;
