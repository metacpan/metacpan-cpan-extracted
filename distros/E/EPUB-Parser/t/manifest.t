use Test::More;
use strict;
use warnings;
use utf8;

use File::Slurp qw/read_file/;
use EPUB::Parser;

my $ep = EPUB::Parser->new;
$ep->load_file({ file_path  => 't/var/denden_converter.epub' });
my $opf = $ep->opf;

subtest 'EPUB::Parser::File::OPF::in_manifest' => sub {
    my $answer = <<'MANIFEST';
<manifest>
<item media-type="image/png" href="cover.png" id="_cover.png" properties="cover-image" />
<item media-type="application/xhtml+xml" href="cover.xhtml" id="_cover.xhtml" />
<item media-type="text/css" href="style.css" id="_style.css" />
<item media-type="application/xhtml+xml" href="bodymatter_0_0.xhtml" id="_bodymatter_0_0.xhtml" />
<item media-type="application/xhtml+xml" href="bodymatter_0_1.xhtml" id="_bodymatter_0_1.xhtml" />
<item media-type="application/xhtml+xml" href="bodymatter_0_2.xhtml" id="_bodymatter_0_2.xhtml" />
<item media-type="image/png" href="fig01.png" id="_fig01.png" />
<item media-type="application/xhtml+xml" href="bodymatter_0_3.xhtml" id="_bodymatter_0_3.xhtml" />
<item media-type="application/xhtml+xml" href="bodymatter_0_4.xhtml" id="_bodymatter_0_4.xhtml" />
<item media-type="application/xhtml+xml" href="bodymatter_0_5.xhtml" id="_bodymatter_0_5.xhtml" />
<item media-type="application/xhtml+xml" href="bodymatter_0_6.xhtml" id="_bodymatter_0_6.xhtml" />
<item media-type="application/xhtml+xml" href="nav.xhtml" id="_nav.xhtml" properties="nav" />
<item media-type="application/x-dtbncx+xml" href="toc.ncx" id="_toc.ncx" />
</manifest>
MANIFEST

    $answer =~ s/\s//g;
    (my $manifest = $opf->parser->in_manifest->context_node) =~ s/\s//g;

    is($manifest, $answer);
};


subtest 'EPUB::Parser::File::OPF::Context::Manifest::attr_by_media_type' => sub {
    my $list = $opf->manifest->attr_by_media_type;
    is_deeply( $list->{'image/png'}, [{ href => "cover.png", id => "_cover.png", properties => "cover-image" }, { href => "fig01.png", id => "_fig01.png"}] );
    is_deeply( $list->{'text/css'},  [{ href => "style.css", id => "_style.css" }] );
    is_deeply( $list->{'application/x-dtbncx+xml'},  [{ href => "toc.ncx", id => "_toc.ncx" }] );
    is_deeply( $list->{'application/xhtml+xml'},  [{
        href => "cover.xhtml",          id => "_cover.xhtml",
    },{ href => "bodymatter_0_0.xhtml", id => "_bodymatter_0_0.xhtml",
    },{ href => "bodymatter_0_1.xhtml", id => "_bodymatter_0_1.xhtml",
    },{ href => "bodymatter_0_2.xhtml", id => "_bodymatter_0_2.xhtml",
    },{ href => "bodymatter_0_3.xhtml", id => "_bodymatter_0_3.xhtml",
    },{ href => "bodymatter_0_4.xhtml", id => "_bodymatter_0_4.xhtml",
    },{ href => "bodymatter_0_5.xhtml", id => "_bodymatter_0_5.xhtml",
    },{ href => "bodymatter_0_6.xhtml", id => "_bodymatter_0_6.xhtml",
    },{ href => "nav.xhtml",            id => "_nav.xhtml", properties => "nav",
    }], 'manifest->attr_by_media_type');
};

subtest 'EPUB::Parser::File::OPF::Context::Manifest::attr_by_id' => sub {
    my $list = $opf->manifest->attr_by_id;
    my $answer = {
        "_cover.png" => { "media-type" => "image/png", href => "cover.png", properties => "cover-image" },
        "_fig01.png" => { "media-type" => "image/png", href => "fig01.png" },
        "_style.css" => { "media-type" => "text/css",  href => "style.css" },
        "_toc.ncx"   => { "media-type" => "application/x-dtbncx+xml", href => "toc.ncx" },
        "_cover.xhtml" => { "media-type" => "application/xhtml+xml",  href => "cover.xhtml" },
        "_bodymatter_0_0.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_0.xhtml" },
        "_bodymatter_0_1.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_1.xhtml" },
        "_bodymatter_0_2.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_2.xhtml" },
        "_bodymatter_0_3.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_3.xhtml" },
        "_bodymatter_0_4.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_4.xhtml" },
        "_bodymatter_0_5.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_5.xhtml" },
        "_bodymatter_0_6.xhtml" => { "media-type" => "application/xhtml+xml",  href => "bodymatter_0_6.xhtml" },
        "_nav.xhtml"            => { "media-type" => "application/xhtml+xml",  href => "nav.xhtml", properties => "nav" },
    };

    is_deeply($list, $answer,'attr_by_id');
};

subtest 'EPUB::Parser::File::OPF::Context::Manifest::items' => sub {
    my $it = $ep->opf->manifest->items;

    is($it->size, 13, 'manifest_items size');

    while ( my $member = $it->next ) {
        ok(length $member->data, 'manifest_items data');
    }
};


subtest 'EPUB::Parser::File::OPF::Context::Manifest::items_by_media' => sub {
    my $it = $ep->opf->manifest->items_by_media;
    is($it->size, 2, 'items_by_media size');
    
    while ( my $member = $it->next ) {
        ok(length $member->data, 'items_by_media data');
    }
};

subtest 'EPUB::Parser::File::OPF::Context::Manifest::items_by_media_type' => sub {
    my $manifest = $ep->opf->manifest;

    subtest 'single media_type' => sub {
        my $it = $manifest->items_by_media_type({ regexp => qr{ text/css }ix });
        is($it->size, 1, 'items_by_media_type size');
    
        while ( my $member = $it->next ) {
            is($member->path, 'OEBPS/style.css');
        }
    };

    subtest 'multi media_type' => sub {
        my $it = $manifest->items_by_media_type({ regexp => qr{ text/css | image/png }ix });
        is($it->size, 3, 'items_by_media_type size');
    
        my $got;
        while ( my $member = $it->next ) {
            $got->{$member->path} = 1;
        }

        is_deeply($got, {
            'OEBPS/style.css' => 1,
            'OEBPS/cover.png' => 1,
            'OEBPS/fig01.png' => 1,
        });
    };

};


done_testing;
