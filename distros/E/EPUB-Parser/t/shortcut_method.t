use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });

is($ep->title,      $ep->opf->metadata->title);
is($ep->creator,    $ep->opf->metadata->creator); 
is($ep->language,   $ep->opf->metadata->language);
is($ep->identifier, $ep->opf->metadata->identifier);

is_deeply(
    scalar $ep->items_by_media,
    scalar $ep->opf->manifest->items_by_media,
);

is_deeply(
    scalar $ep->items_by_media_type({ regexp => qr{ text/css }ix }),
    scalar $ep->opf->manifest->items_by_media_type({ regexp => qr{ text/css }ix }),
);

is_deeply(
    scalar $ep->toc_list,
    scalar $ep->navi->toc->list
);

done_testing;
