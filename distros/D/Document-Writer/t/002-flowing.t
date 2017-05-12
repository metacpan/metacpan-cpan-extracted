use strict;
use Test::More tests => 3;
use lib qw(lib t/lib);

use Document::Writer;
use Document::Writer::Page;
use Document::Writer::TextArea;

use Graphics::Color::RGB;

use MockDriver;

my $doc = Document::Writer->new;
my $driver = MockDriver->new;

isa_ok($doc, 'Document::Writer');

my $page = Document::Writer::Page->new(
    color => Graphics::Color::RGB->new(red => 0, green => 0, blue => 0),
    width => 80, height => 3
);

$doc->add_page_break($driver, $page);
cmp_ok($doc->component_count, '==', 1, '1 page');

my $ta = Document::Writer::TextArea->new(
    text => "Lorem ipsum dolor sit amet,\nconsectetur adipisicing elit,\nLorem ipsum dolor sit amet,\nconsectetur adipisicing elit,Lorem ipsum dolor sit amet,\nconsectetur adipisicing elit,"
);

$doc->add_component($ta);

my $pages = $doc->draw($driver);

cmp_ok(scalar(@{ $pages }), '==', 1, '2 pages');
