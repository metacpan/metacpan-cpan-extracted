use inc::Module::Install;
name 'Geo-iArea';
perl_version '5.008';
license 'perl';
all_from 'lib/Geo/iArea.pm';

recommends $_ for (qw/
    LWP::Simple
    Getopt::Long
    Archive::Lha::Stream
    Archive::Lha::Header
    Archive::Lha::Decode
    File::Spec
    Spreadsheet::ParseExcel
    Spreadsheet::ParseExcel::FmtJapan2
    File::Path
/);

requires $_ for (qw/
    Encode
    File::ShareDir
    Geo::JapanMesh
    CDB_File
    Class::Accessor::Fast
/);

install_share 'share';
build_requires 'Test::Base';
build_requires 'ExtUtils::MakeMaker' => 6.42;
use_test_base;
auto_include;
WriteAll;
