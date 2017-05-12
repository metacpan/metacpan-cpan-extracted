package Lorem::Document;
{
  $Lorem::Document::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

use Lorem::Meta::Attribute::Trait::Inherit;

use Lorem::Element::Div;
use Lorem::Element::Page;
use Lorem::Element::Header;
use Lorem::Element::HRule;
use Lorem::Element::Spacer;
use Lorem::Stamp;
use Lorem::Element::Table;
use Lorem::Element::Text;
use Lorem::Types qw( MaybeLoremDoesStamp );
use Lorem::Util;


extends 'Lorem::Element::Box';
with 'Lorem::Role::HasHeaderFooter';
with 'Lorem::Role::HasWatermark';

with 'Lorem::Role::ConstructsElement' => { 
    name => 'header',
    function => sub {
        my $self = shift;
        my $header = Lorem::Element::Header->new( parent => $self, @_ );
        $self->set_header( $header );
        return $header;
    }
};

with 'Lorem::Role::ConstructsElement' => {
    name => 'page',
    function => sub {
        my $self = shift;
        my $new  = Lorem::Element::Page->new( parent => $self, width => $self->width, style => $self->style->clone );
        $new->set_margin_top( $self->margin_top );
        $new->set_margin_left( $self->margin_left );
        $new->set_margin_right( $self->margin_right );
        $new->set_margin_bottom( $self->margin_bottom );
        $new->set_header_margin( $self->header_margin );
        $new->set_footer_margin( $self->footer_margin );
        $new->set_header( $self->header->clone ) if $self->header;
        $new->set_watermark( $self->watermark->clone ) if $self->watermark;
        $self->append_element( $new );
        return $new;
    }
};

has '+parent' => (
    required => 0,
);

has 'builder_func' => (
    is => 'rw',
    isa => 'CodeRef',
    writer => 'build',
    reader => 'builder_func',
);

sub current_page {
    $_[0]->children->[-1];
}

sub doc { $_[0] }

sub inner_width {
    $_[0]->width - $_[0]->margin_left - $_[0]->margin_right;
}

sub inner_height {
    $_[0]->height - $_[0]->margin_top - $_[0]->margin_bottom;
}

sub margin_left_pos {
    $_[0]->margin_left;
}

sub margin_right_pos {
    $_[0]->width - $_[0]->margin_right;
}

sub margin_top_pos {
    $_[0]->margin_top;
}

sub margin_bottom_pos {
    $_[0]->height - $_[0]->margin_bottom;
}

sub margin_center_pos {
    $_[0]->margin_left_pos + ( $_[0]->inner_width / 2 );
}

sub imprint_header {
    my ( $self, @args ) = @_;
    $_[0]->header->imprint( $_[0], @args ) if $_[0]->header;
}

sub imprint_footer {
    $_[0]->footer->imprint( $_[0] ) if $_[0]->footer;
}

sub draw_page{
    my ( $self, $cr, $i ) = @_;
    $_[0]->children->[$i]->imprint( $cr );
}

1;


__END__

=pod

=head1 NAME

Lorem::Document - Document root class

=head1 SYNOPSIS

  use Lorem;

  $doc = Lorem->new_document;

  $page = $doc->new_page;

  $page->new_text( content => 'Lorem Ipsum' );


=head1 DESCRIPTION

L<Lorem::Document> is the root element of a document.

=head1 METHODS

=over 4

=item new_page

Returns a new L<Lorem::Element::Page> object.

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

