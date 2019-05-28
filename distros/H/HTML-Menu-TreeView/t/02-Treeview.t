use HTML::Menu::TreeView qw(:all );
my @tree = (
    {
        text    => 'News',
        href    => 'TreeView.pl',
        subtree => [
            {
                text  => 'TreeView',
                href  => 'attribute',
                image => "news.gif"
            },
        ],
    },
    {
        text    => "Help",
        onclick => 'attribute',
        image   => "help.gif"
    },
);
my @tree2 = (
    {
        text    => 'News',
        href    => 'TreeView.pl',
        subtree => [
            {
                text  => 'TreeView',
                href  => 'attribute',
                image => "news.gif",
            },
        ],
    },
);
use Cwd;
my $path = getcwd;
use Test::More tests => 7;
my $TreeView = new HTML::Menu::TreeView();
$TreeView->documentRoot("$path/httpdocs");
my $js  = $TreeView->jscript();
my $js2 = jscript();
ok( length($js2) eq length($js) );
Style("Crystal");
ok( $TreeView->Style() eq "Crystal" );
ok( documentRoot() eq "$path/httpdocs" );
ok( length( $TreeView->css() ) > 0 );
TrOver(1);
ok( TrOver() == 1 );
my $TreeView2 = new HTML::Menu::TreeView( \@tree );
my $tree      = $TreeView2->Tree();
my $tree2     = Tree();
ok( length($tree) le length($tree2) );
my $tree3 = Tree( \@tree2 );
ok( length($tree3) le length($tree2) );
1;
