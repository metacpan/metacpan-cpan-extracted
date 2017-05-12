use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/HTML/FormFu/Filter/Demoroniser.pm > README' );
}

perl_version '5.008';

name 'HTML-FormFu-Filter-Demoroniser';
all_from 'lib/HTML/FormFu/Filter/Demoroniser.pm';

requires 'HTML::FormFu' => '0.09000';
requires 'Text::Demoroniser';

test_requires 'Test::More';

extra_tests;

resources repository => 'http://github.com/bricas/html-formfu-filter-demoroniser';

WriteAll;
