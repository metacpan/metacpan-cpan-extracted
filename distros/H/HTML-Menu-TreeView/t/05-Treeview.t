use HTML::Menu::TreeView qw(:all style);
my @tree = (
            {
             text    => "Help",
             onclick => 'attribute',
             image   => "help.gif"
            },
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
            }
           );
use Test::More tests => 10;
my $t1 = Tree(\@tree);
folderFirst(1);
ok(folderFirst() == 1);
folderFirst(0);
ok(folderFirst() == 0);
ok(Style() eq 'Crystal');
documentRoot("blib/rhtml");
Style('simple');
ok(Style() eq 'simple');
ok(size() == 16);
size(32);
ok(size() == 32);
size(1200);
ok(size() == 32);
size(48);
ok(size() == 48);
size(64);
ok(size() == 64);
size(128);
ok(size() == 128);
1;
