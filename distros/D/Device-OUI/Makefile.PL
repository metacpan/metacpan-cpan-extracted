use inc::Module::Install;

name 'Device-OUI';
all_from 'lib/Device/OUI.pm';

recommends 'LWP::Simple';

requires( $_ ) for qw(
    IO::File
    AnyDBM_File
    Class::Accessor::Grouped
    Carp
    Sub::Exporter
);

test_requires( $_ ) for qw(
    Test::More
    Test::Exception
    FindBin
    File::Copy
    LWP::Simple
);

WriteAll();
