use inc::Module::Install 0.99;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Games/NES/ROM.pm > README' );
}

perl_version '5.008';

name 'Games-NES-ROM';
all_from 'lib/Games/NES/ROM.pm';

requires 'Moose';
requires 'Module::Runtime';
requires 'Try::Tiny';
requires 'FileHandle';
requires 'XML::Simple';
requires 'XML::XPath';

test_requires 'Test::More';

repository 'http://github.com/bricas/games-nes-rom';

WriteAll;
