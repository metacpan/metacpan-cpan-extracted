package EPUB::Parser::File::OPF::Context::Spine;
use strict;
use warnings;
use Carp;
use parent 'EPUB::Parser::File::OPF::Context';
use EPUB::Parser::Util::AttributePacker;

sub ordered_list {
    my $self = shift;
    my $node_list = $self->parser->find('pkg:itemref');
    EPUB::Parser::Util::AttributePacker->ordered_list($node_list) || [];
}

sub attrs {
    my $self = shift;

    my $items;
    my $attr_by_id = $self->opf->manifest->attr_by_id;

    for my $idref ( @{$self->ordered_list} ) {
        push @$items, $attr_by_id->{$idref->{idref}};
    }

    return $items || [];
}

sub items_path {
    my $self = shift;
    my $args = shift || {};
    my @href = map { $_->{href} } @{$self->attrs};

    $self->opf->manifest->_items_path({ %$args, href => \@href });
}

sub items {
    my $self = shift;
    $self->opf->manifest->_items( $self->items_path({ abs => 1 }) );
}



1;

__END__

=encoding utf-8

=head1 NAME

EPUB::Parser::File::OPF::Context::Spine - parses spine node in opf file

=head1 METHODS

=head2 ordered_list

Attribute of each child nodes of spine is added to hash.
For exsample,

 [
    { idref => "_cover.xhtml",  linear => "no"},
    { idref => '_nav.xhtml' },
    { idref => "_document_0_0.xhtml" },
    ....
 ]

=head2 attrs

Get Manifest infomation corresponding to Spine.
For example,

 [{
     'href' => 'cover.xhtml',
     'media-type' => 'application/xhtml+xml'
 },{
     'href' => 'nav.xhtml',
     'media-type' => 'application/xhtml+xml',
     'properties' => 'nav'
 },{
     ...
 }]


=head2 items_path

Return path of item which spine has is obtained.

=head2 items

Return item which spine has is obtained.
The item is instance of L<EPUB::Parser::Util::Archive::Iterator>.

=head1 LICENSE

Copyright (C) tokubass.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokubass E<lt>tokubass {at} cpan.orgE<gt>

=cut

