# NAME

    EPUB::Parser - EPUB Parser class

# SYNOPSIS

    use EPUB::Parser;
    my $ep = EPUB::Parser->new;

    # load epub
    $ep->load_file({ file_path  => 'sample.epub' });
    # or
    $ep->load_binary({ data  => $binary_data })

    # get opf version
    my $version = $ep->opf->guess_version;

    # get css. Return value is 'EPUB::Parser::Util::Archive::Iterator' object.
    my $itr = $ep->items_by_media_type({ regexp => qr{text/css}ix });
    while ( my $zip_member = $itr->next ) {
        $zip_member->data;
        $zip_member->path;
    }

    # shortcut method. iterator object contain image,audio,video item path.
    my $itr = $ep->items_by_media;

    # get list under <nav id="toc" epub:type="toc"> 
    # todo: parse nested list
    for my $chapter ( $ep->toc_list ) {
        $chapter->{title};
        $chapter->{href};
    }

    # get cover image blob
    my $cover_img_path = $ep->opf->cover_image_path;
    $ep->data_from_path($cover_img_path);

    # get page list from each chapter.
    my $collect_pages = $ep->pages_manager->get_page_from_each_chapter;
    #   no_chapter_member => [
    #        'OEBPS/cover.xhtml',
    #        'OEBPS/nav.xhtml'
    #    ],
    #    chapter_group => [
    #        [
    #            'OEBPS/0_1.xhtml'
    #            'OEBPS/0_2.xhtml'
    #            'OEBPS/0_3.xhtml'
    #        ],
    #        [
    #            'OEBPS/1_1.xhtml'
    #            'OEBPS/1_2.xhtml'
    #            'OEBPS/1_3.xhtml'
    #        ],
    #        ....
    #    ]

# DESCRIPTION

EPUB::Parser parse EPUB3 and return Perl Data Structure.
This module can only parse EPUB3.

# METHODS

## new(\\%opts)

Constructor.
Creates a new EPUB::Parser instance. Valid options are:

- epub\_version

    EPUB::Parser->new({ epub\_version => '3.0' });
    epub\_version is default 3.0 and current supoprt only 3.0.

## opf

Returns instance of [EPUB::Parser::File::OPF](https://metacpan.org/pod/EPUB::Parser::File::OPF).

## navi

Returns instance of [EPUB::Parser::File::Navi](https://metacpan.org/pod/EPUB::Parser::File::Navi).

## data\_from\_path($path)

get blob from loaded EPUB with path indicated in $path.

## pages\_manager

Returns instance of [EPUB::Parser::Manager::Pages](https://metacpan.org/pod/EPUB::Parser::Manager::Pages).

## load\_file({ file\_path  => 'sample.epub' })

load from EPUB file.

## load\_binary({ data  => $binary\_data })

load from EPUB blob.

# LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokubass &lt;tokubass {at} cpan.org>
