use Test::More tests => 7;
use lib qw(t t/lib);

use Graphics::Color::RGB;

use Document::Writer;
use Document::Writer::Page;
use MockDriver;

my $doc = Document::Writer->new;

my $driver = MockDriver->new;

isa_ok($doc, 'Document::Writer');

my ($w, $h) = Document::Writer->get_paper_dimensions('letter');

eval {
    $doc->add_page_break;
};
ok($@ =~ /Must add a first page/, 'add page break with no pages');

my ($width, $height) = $doc->get_paper_dimensions('letter');
my $page = Document::Writer::Page->new(
    width => $width,
    height => $height,
    color => Graphics::Color::RGB->new(
        red => 0, green => 0, blue => 0, alpha => 1
    )
);

$doc->add_page_break($driver, $page);
cmp_ok($doc->component_count, '==', 1, '1 component');

my $page2 = Document::Writer::Page->new(
    width => $w,
    height => $h,
    color => Graphics::Color::RGB->new(
        red => 0, green => 0, blue => 0, alpha => 1
    )
);
isa_ok($page2, 'Document::Writer::Page');

$doc->add_page_break($driver, $page2);
cmp_ok($doc->component_count, '==', 2, '2 pages');

my $newpage = $doc->add_page_break($driver);
cmp_ok($newpage->width, '==', $page2->width, 'new page width');
cmp_ok($newpage->height, '==', $page2->height, 'new page height');
