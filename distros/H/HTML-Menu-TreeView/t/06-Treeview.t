use strict;
use HTML::Menu::TreeView;
use vars qw(@TreeView @tree);
@tree = (
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
my $Tree = new HTML::Menu::TreeView();
my $t    = $Tree->Tree(\@tree);
$Tree->saveTree("./tree.pl");
$Tree->loadTree("./tree.pl");
*TreeView = \@{$HTML::Menu::TreeView::TreeView[0]};
my $tree2 = $Tree->Tree();
use Test::More tests => 2;
ok($tree[0]->{text} eq $TreeView[0]->{text});
splice @TreeView, 0, 2, ($TreeView[1], $TreeView[0]);
ok($tree[0]->{text} eq $TreeView[1]->{text});
unlink("./tree.pl");
1;
