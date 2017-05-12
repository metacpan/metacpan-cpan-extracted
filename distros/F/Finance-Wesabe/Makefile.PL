use inc::Module::Install 0.99;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Finance/Wesabe.pm > README' );
}

perl_version '5.008';

name 'Finance-Wesabe';
all_from 'lib/Finance/Wesabe.pm';

requires 'Moose' => '0.51';
requires 'URI';
requires 'LWP::UserAgent';
requires 'XML::Simple';
requires 'DateTime::Format::ISO8601';

test_requires 'Test::More';

extra_tests;

repository "http://github.com/bricas/finance-wesabe/";

WriteAll;
