use inc::Module::Install;
name 'Geo-Coordinates-Converter-iArea';
all_from 'lib/Geo/Coordinates/Converter/iArea.pm';

requires 'Geo::Coordinates::Converter' => 0.09;
requires 'File::ShareDir' => 1.02;
requires 'CDB_File' => '0.96';

author_tests('xt');
install_share 'share';
test_requires 'Test::More' => 0.96;
WriteAll;
