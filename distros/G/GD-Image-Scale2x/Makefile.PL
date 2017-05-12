use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/GD/Image/Scale2x.pm > README' );
}

perl_version '5.006';

name 'GD-Image-Scale2x';
all_from 'lib/GD/Image/Scale2x.pm';

requires 'GD';
requires 'Algorithm::Scale2x'; 

test_requires 'Test::More';

install_script 'bin/scale2x';

repository "http://github.com/bricas/gd-image-scale2x/tree/master";

WriteAll;
