use Test::More;
use ok 'Forest::Tree::Viewer::Gtk2';
use Gtk2-init;
use Forest::Tree;
use Forest::Tree::Reader::SimpleTextFile;

my $reader = Forest::Tree::Reader::SimpleTextFile->new;
my $viewer = Forest::Tree::Viewer::Gtk2->new(tree=>$reader->tree);
isa_ok $viewer->tree_store,'Gtk2::TreeStore';
isa_ok $viewer->view,'Gtk2::TreeView';
$reader->read(\*DATA);
done_testing;
__DATA__
root
    1.0
        1.1
        1.2
            1.2.1
    2.0
        2.1
    3.0
    4.0
        4.1
            4.1.1
other root
