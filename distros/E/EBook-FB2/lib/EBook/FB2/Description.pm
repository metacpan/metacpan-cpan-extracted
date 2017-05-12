# Copyright (c) 2009, 2010 Oleksandr Tymoshenko <gonzo@bluezbox.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package EBook::FB2::Description;

use Moose;

use EBook::FB2::Description::CustomInfo;
use EBook::FB2::Description::DocumentInfo;
use EBook::FB2::Description::PublishInfo;
use EBook::FB2::Description::TitleInfo;

has 'title_info' =>  (
    isa     => 'Object', 
    is      => 'rw', 
    handles => {
        book_title  => 'book_title',
        authors     => 'authors',
        translators => 'translators',
        sequences   => 'sequences',
        genres      => 'genres',
        lang        => 'lang',
        src_lang    => 'src_lang',
        date        => 'date',
        keywords    => 'keywords',
        coverpages  => 'coverpages',
    },
);

has 'src_title_info' =>  (
    isa     => 'Object', 
    is      => 'rw', 
    handles => {
        src_book_title  => 'book_title',
        src_authors     => 'authors',
        src_translators => 'translators',
        src_sequences   => 'sequences',
        src_genres      => 'genres',
        src_date        => 'date',
        src_keywords    => 'keywords',
        src_coverpages  => 'coverpages',
    },
);

has 'publish_info' =>  (
    isa     => 'Object', 
    is      => 'rw', 
    handles => {
        publication_title   => 'book_name',
        publisher           => 'publisher',
        publication_city    => 'city',
        publication_year    => 'year',
        isbn                => 'isbn',
    },
);


has 'document_info' =>  (
    isa     => 'Object', 
    is      => 'rw', 
    handles => {
        document_publishers     => 'publishers',
        document_src_urls       => 'src_urls',
        document_authors        => 'authors',
        document_program_used   => 'program_used',
        document_date           => 'date',
        document_src_ocr        => 'src_ocr',
        document_id             => 'id',
        document_version        => 'version',
        document_history        => 'history',
    },
);

has '_custom_infos' =>  (
    isa     => 'ArrayRef[Object]',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        custom_infos        => 'elements',
        add_custom_info     => 'push',
    },
);

sub load
{
    my ($self, $node) = @_;
    my @title_info_nodes = $node->findnodes('title-info');

    if (@title_info_nodes != 1) {
        warn ("Wrong number of <title-info> element");
        return;
    }

    my $title_info = EBook::FB2::Description::TitleInfo->new();
    $title_info->load( $title_info_nodes[0]);
    $self->title_info($title_info);

    my @src_title_info_nodes = $node->findnodes('src-title-info');

    if (@src_title_info_nodes > 1) {
        warn ("Wrong number of <src-title-info> element");
        return;
    }

    if (@src_title_info_nodes) {
        my $src_title_info = EBook::FB2::Description::TitleInfo->new();
        $src_title_info->load( $src_title_info_nodes[0]);
        $self->src_title_info($src_title_info);
    }

    my @publish_info_nodes = $node->findnodes('publish-info');

    if (@publish_info_nodes > 1) {
        warn ("Wrong number of <publish-info> element");
        return;
    }

    if (@publish_info_nodes) {
        my $publish_info = EBook::FB2::Description::PublishInfo->new();
        $publish_info->load( $publish_info_nodes[0]);
        $self->publish_info($publish_info);
    }

    my @document_info_nodes = $node->findnodes('document-info');

    if (@document_info_nodes != 1) {
        warn ("Wrong number of <document-info> element");
        return;
    }

    my $document_info = EBook::FB2::Description::DocumentInfo->new();
    $document_info->load( $document_info_nodes[0]);
    $self->document_info($document_info);

    my @custom_info_nodes = $node->findnodes('custom-info');

    foreach my $n (@custom_info_nodes) {
        my $custom_info = EBook::FB2::Description::CustomInfo->new();
        $custom_info->load( $n );
        $self->add_custom_info($custom_info);
    }

}

1;

__END__
=head1 NAME

EBook::FB2::Description

=head1 SYNOPSIS

EBook::FB2::Description - FB2 document metadata

=head1 SUBROUTINES/METHODS

=over 4

=item title_info()

Returns reference to L<EBook::FB2::Description::TitleInfo> object that 
contains book metadata.

=item src_title_info()

Returns reference to L<EBook::FB2::Description::TitleInfo> object that 
contains original book metadata. Valid if book is translation.

=item publish_info()

Returns reference to L<EBook::FB2::Description::PublicationInfo>


=item document_info()

Returns reference to L<EBook::FB2::Description::DocumentInfo> object that 
contains document metadata: program used, OCR info, etc.

=item custom_infos()

Returns list of references to L<EBook::FB2::Description::CustomInfo> objects

=back 

=head1 FORWARDED METHODS

These methods provided to make access to document metada easier and generally 
they are just forwarders to B<title_info>, B<src_title_info>, B<document_info>,
B<publish_info> members

    # these are the same
    my $src_title = $fb2->desciption->src_book_title;
    my $src_title = $fb2->desciption->src_title_info->book_title;

    # these are the same
    my $isbn = $fb2->desciption->isbn;
    my $isbn = $fb2->desciption->publication_info->isbn;

    
You've got the idea...

=over 4

=item annotation()

Returns reference to XML::DOM::Node, parsed annotation

=item authors()

Returns list of book authors (references to L<EBook::FB2::Description::Author>)

=item book_title()

Returns book title

=item coverpages()

Returns list of ids that references to images with original cover artwork

=item date()

Returns book creation date

=item document_authors()

Returns document(fb2) creators

=item document_date()

Returns document(fb2) moification/creation date

=item document_history()

Returns document(fb2) history

=item document_id()

Returns document(fb2) id

=item document_program_used()

Returns program that has been used for generating this document

=item document_publishers()

Returns publisher of FB2 document (not book)

=item document_src_ocr()

Returns OCR author

=item document_src_urls()

Returns source URL of original document

=item document_version()

Return document version

=item genres()

Returns list of genres book falls in (references to 
L<EBook::FB2::Description::Genre>)

=item isbn()

Returns book ISBN

=item keywords()

Returns book keyword

=item lang()

Return book languagage: "ru", "en", etc...

=item publication_city()

Returns city where book has been published

=item publication_title()

Returns original publication title

=item publication_year()

Returns publication year

=item publisher()

Returns book publisher

=item sequences()

Returns list of sequences book belongs to (references to L<EBook::FB2::Description::Sequence>)

=item src_authors()

See L<authors>. Valid if book is translation.

=item src_book_title()

See L<book_title>. Valid if book is translation.

=item src_coverpages()

See L<coverpages>. Valid if book is translation.

=item src_date()

See L<date>. Valid if book is translation.

=item src_genres()

See L<genres>. Valid if book is translation.

=item src_keywords()

See L<keywords>. Valid if book is translation.

=item src_lang()

Original book language. Valid if book is translation.

=item src_sequences()

See L<sequences>. Valid if book is translation.

=item translators()

Returns list of translators represented by references to 
L<EBook::FB2::Description::Author> objects;

=back

=head1 AUTHOR

Oleksandr Tymoshenko, E<lt>gonzo@bluezbox.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to  E<lt>gonzo@bluezbox.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2009, 2010 Oleksandr Tymoshenko.

L<http://bluezbox.com>

This module is free software; you can redistribute it and/or
modify it under the terms of the BSD license. See the F<LICENSE> file
included with this distribution.
