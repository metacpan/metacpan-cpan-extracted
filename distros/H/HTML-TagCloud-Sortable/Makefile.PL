use inc::Module::Install 0.91;

if( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/HTML/TagCloud/Sortable.pm > README' );
}

perl_version '5.006';
name 'HTML-TagCloud-Sortable';
all_from 'lib/HTML/TagCloud/Sortable.pm';

requires 'HTML::TagCloud';
test_requires 'Test::More';

repository "http://github.com/bricas/html-tagcloud-sortable/tree/master";

WriteAll;
