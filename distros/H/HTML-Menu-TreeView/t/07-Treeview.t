use HTML::Menu::TreeView qw(:all);
my @tree = (
    {
        text    => 'News',
        columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
    },
    {
        text    => 'Folder',
        columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
        subtree => [
            {
                text    => 'News',
                columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
            },
            {
                text    => 'Folder',
                subtree => [
                    {
                        text    => 'Test',
                        columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
                    },
                ],
                columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
            },
            {
                text    => 'Test',
                columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
            },
        ],
    },
    {
        text    => 'Test',
        columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
        subtree => [
            {
                text    => 'Test',
                columns => [ ' a&#160;', ' b  jjjjj kkkkk llll iiiiiiiii', ' c ', ' d ', ' e ' ],
            },
        ],
    },
);
my $TreeView = new HTML::Menu::TreeView();
$TreeView->columns( "Column1", "Column2", "Column3", "Column4", "Column5" );
use Test::More tests => 1;
ok( $TreeView->columns == 5 );
1;
