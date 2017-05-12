use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/File/SAUCE.pm > README' );
}

perl_version '5.006';

name 'File-SAUCE';
all_from 'lib/File/SAUCE.pm';

requires 'FileHandle';
requires 'IO::String' => '1.06';
requires 'Time::Piece';
requires 'Class::Accessor';

test_requires 'Test::More';

repository "http://github.com/bricas/file-sauce/tree/master";

WriteAll;
