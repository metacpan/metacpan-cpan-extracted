use HTML::Menu::TreeView qw(:backward size clasic %anker);
my @tree = (
    {
        text    => 'News',
        href    => 'TreeView.pl',
        subtree => [
            {
                text  => 'TreeView',
                href  => 'attribute',
                image => 'news.gif',
            },
        ],
    },
);
use Test::More tests => 7;
setSize(32);
ok( size() == 32 );
use Cwd;
my $path = getcwd;
setDocumentRoot("$path/httpdocs");
ok( getDocumentRoot() eq "$path/httpdocs" );
setClasic();
ok( clasic() == 1 );
setModern();
ok( clasic() == 0 );
ok( $anker{href} eq 'URI for linked resource' );
setStyle('simple');
ok( style() eq 'simple' );
style('Crystal');
ok( style() eq 'Crystal' );
1;
