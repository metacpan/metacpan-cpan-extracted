use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;
use EPUB::Parser::File::Document;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });

my %ret;
my $it = $ep->opf->spine->items;
while ( my $member = $it->next ) {
    my $doc = EPUB::Parser::File::Document->new({ archive_doc => $member });
    $ret{$doc->path} = $doc->item_abs_paths;
}

is_deeply(\%ret, {
  'OEBPS/bodymatter_0_0.xhtml' => {
    'http://conv.denshochan.com/' => 'http://conv.denshochan.com/',
    'http://www.aozora.gr.jp/' => 'http://www.aozora.gr.jp/',
    'http://www.aozora.gr.jp/cards/001263/files/50361_39049.html' => 'http://www.aozora.gr.jp/cards/001263/files/50361_39049.html',
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_1.xhtml' => {
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_2.xhtml' => {
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_3.xhtml' => {
    'fig01.png' => 'OEBPS/fig01.png',
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_4.xhtml' => {
    '#fn_1' => 'OEBPS/#fn_1',
    '#fnref_1' => 'OEBPS/#fnref_1',
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_5.xhtml' => {
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/bodymatter_0_6.xhtml' => {
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/cover.xhtml' => {
    'cover.png' => 'OEBPS/cover.png',
    'style.css' => 'OEBPS/style.css'
  },
  'OEBPS/nav.xhtml' => {
    'bodymatter_0_0.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_0.xhtml#toc_index_1',
    'bodymatter_0_1.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_1.xhtml#toc_index_1',
    'bodymatter_0_2.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_2.xhtml#toc_index_1',
    'bodymatter_0_3.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_3.xhtml#toc_index_1',
    'bodymatter_0_4.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_4.xhtml#toc_index_1',
    'bodymatter_0_5.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_5.xhtml#toc_index_1',
    'bodymatter_0_6.xhtml#toc_index_1' => 'OEBPS/bodymatter_0_6.xhtml#toc_index_1',
    'cover.xhtml' => 'OEBPS/cover.xhtml',
    'nav.xhtml' => 'OEBPS/nav.xhtml',
    'style.css' => 'OEBPS/style.css'
  }
}, 'item_abs_paths in all_document');

done_testing;
