use HTML::Menu::TreeView qw(Tree);
my @tree = (
            {
             text    => 'News',
             href    => "TreeView.pl",
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
my $TreeView = new HTML::Menu::TreeView();
my @tree2 = (
             {
              text    => 'News',
              href    => "TreeView.pl",
              subtree => [
                          {
                           text  => 'TreeView',
                           href  => 'attribute',
                           image => "news.gif"
                          },
                         ],
             },
            );
use Test::More tests => 1;
my $tree2 = Tree(\@tree);
my $tree3 = Tree(\@tree2);
ok(length($tree3) < length($tree2));
1;
