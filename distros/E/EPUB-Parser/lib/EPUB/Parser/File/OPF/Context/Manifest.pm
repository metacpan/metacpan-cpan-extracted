package EPUB::Parser::File::OPF::Context::Manifest;
use strict;
use warnings;
use Carp;
use Smart::Args;
use parent 'EPUB::Parser::File::OPF::Context';
use EPUB::Parser::Util::AttributePacker;

sub nav_path {
    my $self = shift;
    my $nav_path = $self->parser->single('pkg:item[@properties="nav"]/@href')->string_value;

    croak '<item properties="nav" /> is required for epub3' unless $nav_path;

    return $nav_path;
}

sub cover_image_path {
    args(
        my $self,
        my $abs => { optional => 1 },
    );
    my $cover_img_path =  $self->parser->single('pkg:item[@properties="cover-image"]/@href');

    return unless $cover_img_path;

    if ($abs) {
        return $self->{opf}->dir . '/' . $cover_img_path->string_value;
    }else{
        return $cover_img_path->string_value;
    }
}

sub attr_by_media_type {
    my $self = shift;
    my $nodes = $self->parser->find('pkg:item');
    EPUB::Parser::Util::AttributePacker->grouped_list($nodes, { group => 'media-type'});
}

sub attr_by_id {
    my $self = shift;
    my $nodes = $self->parser->find('pkg:item');
    EPUB::Parser::Util::AttributePacker->by_uniq_key($nodes, { key => 'id'});
}


sub _items_path {
    args(
        my $self,
        my $href => 'ArrayRef',
        my $abs  => { optional => 1 },
    );

    my $base_dir = '';
    if ($abs) {
        $base_dir = $self->{opf}->dir . '/';
    }

    [map { $base_dir . $_ } @$href];
}

sub items_path {
    my $self = shift;
    my $args = shift || {};

    my @href = map { $_->{href} } values %{ $self->attr_by_id || {} };

    $self->_items_path({ %$args, href => \@href });
}

sub items_path_by_media_type {
    args(
        my $self,
        my $abs => { optional => 1 },
        my $regexp,
    );

    my $attr =  $self->attr_by_media_type || {};
    my @href;
    for my $media_type ( keys %$attr ) {
        next unless $media_type =~ $regexp;
        push @href, map { $_->{href} } @{$attr->{$media_type}};
    }

    $self->_items_path({ abs => $abs, href => \@href });
}


sub _items {
    my $self  = shift;
    my $paths = shift;
    my $it = $self->{opf}->{zip}->get_members({
        files_path => $paths,
    });
    return wantarray ? $it->all : $it;
}

sub items {
    my $self = shift;
    $self->_items( $self->items_path({ abs => 1 }) );
}


sub items_by_media {
    my $self = shift;
    $self->_items( $self->items_path_by_media_type({ abs => 1, regexp => qr{image/ | video/ | audio/}ix }) );
}

sub items_by_media_type {
    args(
        my $self,
        my $regexp,
    );
    $self->_items( $self->items_path_by_media_type({ abs => 1, regexp => $regexp }) );
}


1;

__END__

=encoding utf-8

=head1 NAME

 EPUB::Parser::File::OPF::Context::Manifest - parses manifest node in opf file

=head1 METHODS

=head2 nav_path

Get navigation file path from item element with the property 'nav'.

=head2 cover_image_path(\%opt)

Get cover image path from item element with the property 'cover-image'.
Valid options are:

=over 4

=item abs

 $manifest->cover_image_path({ abs => 1 });
 Get absolute path.

=back

=head2 attr_by_media_tyep({ regexp => qr{ ... }ix })

Retrun in the following format.

 {

    'image/png' =>  [{
        href => "cover.png", id => "_cover.png", properties => "cover-image"
    },{
        href => "fig01.png", id => "_fig01.png"
    }],
    'text/css' => [{
        .....
    }],
 }

=head2 attr_by_id

Retrun in the following format.

 {
    "_cover.png"   => { "media-type" => "image/png", href => "cover.png", properties => "cover-image" },
    "_style.css"   => { "media-type" => "text/css",  href => "style.css" },
    "_toc.ncx"     => { "media-type" => "application/x-dtbncx+xml", href => "toc.ncx" },
    "_cover.xhtml" => { "media-type" => "application/xhtml+xml",  href => "cover.xhtml" },
    "_nav.xhtml"   => { "media-type" => "application/xhtml+xml",  href => "nav.xhtml", properties => "nav" },
    ....
 }


=head2 items_path

Returns all item path.

=head2 items_path_by_media_type

Returns items path with media-type specified by Regular expression.

=head2 items

Returns all item.
The item is instance of L<EPUB::Parser::Util::Archive::Iterator>.

=head2 items_by_media

Returns items with specified media-type. image/*, video/* ,audio/* .
The item is instance of L<EPUB::Parser::Util::Archive::Iterator>.

=head2 items_by_media_type({ regexp => qr{ ... }ix })

Returns items with media-type specified by Regular expression.
The item is instance of L<EPUB::Parser::Util::Archive::Iterator>.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut

