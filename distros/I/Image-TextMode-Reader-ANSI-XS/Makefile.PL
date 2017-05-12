use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Image/TextMode/Reader/ANSI/XS.pm > README' );
}

perl_version '5.008';

name 'Image-TextMode-Reader-ANSI-XS';
all_from 'lib/Image/TextMode/Reader/ANSI/XS.pm';

requires 'Image::TextMode' => '0.22';

test_requires 'Test::More';

repository 'http://github.com/bricas/image-textmode-reader-ansi-xs';

WriteAll;
