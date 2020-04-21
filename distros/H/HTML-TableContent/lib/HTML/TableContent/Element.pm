package HTML::TableContent::Element;

use Moo;
use HTML::TableContent::Table;

our $VERSION = '1.00';

my @ATTRIBUTE =
  qw/class id style colspan rowspan onclick onchange type onkeyup placeholder scope selected value
  autocomplete for onFocus onBlur href role width height data_toggle data_placement title/;

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    my $build = ();

    if ( my $links = delete $args->{links} ) {
        if ( ref $links eq 'ARRAY' ) {
            $build->{links} = $links;
        }
    }

    if ( my $concat = delete $args->{truncate} ) {
        $build->{truncate} = $concat;
    }

    $build->{attributes}     = $args;
    $build->{attribute_list} = \@ATTRIBUTE;

    for my $field ( @ATTRIBUTE, 'html_tag', 'tag') {
        if ( defined $args->{$field} ) {
            $build->{$field} = $args->{$field};
        }
    }

    return $class->$orig($build);
};

for my $field (@ATTRIBUTE) {
    has $field => (
        is      => 'rw',
        lazy    => 1,
        trigger => 1,
        default => q{}
    );
}

has [qw/template_attr row_index index data tag/] => (
    is      => 'rw',
    clearer => 1,
    builder => 1,
);

has attributes => (
    is      => 'rw',
    default => sub { {} }
);

has [qw/inner_html wrap_html attribute_list truncate/] => ( is => 'rw' );

has [qw/children nested links before_element after_element/] => (
    is      => 'rw',
    default => sub { [] },
);

has html_tag => (
    is      => 'rw',
    default => 'table',
);

sub _build_row_index {
    return
      defined $_[0]->attributes->{row_index}
      ? delete $_[0]->attributes->{row_index}
      : undef;
}

sub _build_index {
    return
      defined $_[0]->attributes->{index}
      ? delete $_[0]->attributes->{index}
      : undef;
}

sub _build_template_attr {
    return
      defined $_[0]->attributes->{template_attr}
      ? delete $_[0]->attributes->{template_attr}
      : undef;
}

sub _build_tag {
    my $caller = caller();
    my ($tag) = $caller =~ /.*\:\:(.*)/;
    return lc $tag;
}

sub has_data { return scalar @{ $_[0]->data } ? 1 : 0; }

sub has_children { return scalar @{ $_[0]->children } ? 1 : 0; }

sub count_children { return scalar @{ $_[0]->children }; }

sub has_nested { return scalar @{ $_[0]->nested } ? 1 : 0; }

sub count_nested { return scalar @{ $_[0]->nested }; }

sub get_first_nested { return $_[0]->nested->[0]; }

sub get_nested { return $_[0]->nested->[ $_[1] ]; }

sub all_nested { return @{ $_[0]->nested }; }

sub has_links { return scalar @{ $_[0]->links } ? 1 : 0; }

sub count_links { return scalar @{ $_[0]->links }; }

sub get_first_link { return $_[0]->links->[0]; }

sub get_link { return $_[0]->links->[ $_[1] ]; }

sub all_links { return @{ $_[0]->links }; }

sub add_child {
    my $element = $_[0]->new( $_[1] );
    push @{ $_[0]->children }, $element;
    return $element;
}

sub add_nested {
    my $table = HTML::TableContent::Table->new( $_[1] );
    push @{ $_[0]->nested }, $table;
    return $table;
}

sub add_to_nested {
    return push @{ $_[0]->nested }, $_[1];
}

sub text { return join q{ }, @{ $_[0]->data }; }

sub truncate_text { return substr($_[0]->text, 0, $_[0]->truncate) . '...'; }

sub add_text { return push @{ $_[0]->data }, $_[1]; }

sub set_text { $_[0]->data( [ $_[1] ] ); }

sub lc_text { return lc $_[0]->text; }

sub ucf_text { return ucfirst $_[0]->text; }

sub add_class {
    my $class = $_[0]->class;
    return $_[0]->class( sprintf( '%s %s', $class, $_[1] ) );
}

sub add_style {
    my $style = $_[0]->style;
    return $_[0]->style( sprintf( '%s %s', $style, $_[1] ) );
}

sub raw {
    my $args = $_[0]->attributes;

    if ( $_[0]->has_nested ) {
        $args->{nested} = ();
        for ( $_[0]->all_nested ) {
            push @{ $args->{nested} }, $_->raw;
        }
    }

    if ( scalar @{ $_[0]->data } ) {
        $args->{text} = $_[0]->text;
        $args->{data} = $_[0]->data;
    }

    return $args;
}

sub render {
    my $args = $_[0]->attributes;

    my $attr = '';
    foreach my $attribute ( @{ $_[0]->attribute_list } ) {
        if ( my $val = $args->{$attribute} ) {
            $attribute =~ s/\_/\-/g;
            if ( ref $val eq 'ARRAY' ) {
                $val = sprintf(
                    $val->[0],
                    map { $_[0]->$_ } @{$val}[ 1 .. scalar @{$val} - 1 ]
                );
            } elsif ( ref $val eq 'CODE' ) {
                $val = $val->($_[0]);
            }
            $attr .= sprintf '%s="%s" ', $attribute, $val;

        }
    }

    my $render = $_[0]->_render_element;

    if ( my $inner_html = $_[0]->inner_html ) {
        my $inner_count = scalar @{$inner_html};
        if ( $inner_count == 1 ) {
            $render = sprintf( $inner_html->[0], $render );
        }
        else {
            $render = sprintf(
                $inner_html->[0],
                map { $_[0]->$_ } @{$inner_html}[ 1 .. $inner_count - 1 ]
            );
        }
    }

    if ($_[0]->has_children) {
        my @elements = map { $_->render } @{ $_[0]->children };
        my $ele_html = sprintf '%s' x @elements, @elements;

        $render = sprintf '%s%s', $render, $ele_html; 
    }

    my $tag = $_[0]->html_tag;
    my $html = sprintf( "<%s %s>%s</%s>", $tag, $attr, $render, $tag );

    if ( my $before_element = $_[0]->before_element ) {
        for ( @{$before_element} ) {
            my $ren = ref \$_ eq 'SCALAR' ? $_ : $_->render;
            $html = sprintf "%s%s", $ren, $html;
        }
    }

    if ( my $after_element = $_[0]->after_element ) {
        for ( @{$after_element} ) {
            my $ren = ref \$_ eq 'SCALAR' ? $_ : $_->render;
            $html = sprintf "%s%s", $html, $ren;
        }
    }

    if ( my $wrap_html = $_[0]->wrap_html ) {
        my $wrap_count = scalar @{$wrap_html};
        if ( $wrap_count == 1 ) {
            $html = sprintf( $wrap_html->[0], $html );
        }
        else {
            $html = sprintf(
                $wrap_html->[0],
                map { $_[0]->$_ } @{$wrap_html}[ 1 .. $wrap_html - 1 ]
            );
        }
    }

    return $_[0]->tidy_html($html);
}

sub _render_element {
    return $_[0]->_render_element_text($_[0]->text);
}

sub _render_element_text {
    return defined $_[0]->truncate ? $_[0]->truncate_text($_[0]->text) : $_[0]->text;
}

sub _trigger_class { return $_[0]->attributes->{class} = $_[1]; }

sub _trigger_id { return $_[0]->attributes->{id} = $_[1]; }

sub _trigger_style { return $_[0]->attributes->{style} = $_[1]; }

sub _trigger_colspan { return $_[0]->attributes->{colspan} = $_[1]; }

sub _trigger_rowspan { return $_[0]->attributes->{rowspan} = $_[1]; }

sub _trigger_onclick { return $_[0]->attributes->{onclick} = $_[1]; }

sub _trigger_onchange { return $_[0]->attributes->{onchange} = $_[1]; }

sub _trigger_type { return $_[0]->attributes->{type} = $_[1]; }

sub _trigger_value { return $_[0]->attributes->{value} = $_[1]; }

sub _trigger_scope { return $_[0]->attributes->{scope} = $_[1]; }

sub _trigger_onkeyup { return $_[0]->attributes->{onkeyup} = $_[1]; }

sub _trigger_placeholder { return $_[0]->attributes->{placeholder} = $_[1]; }

sub _trigger_onFocus { return $_[0]->attributes->{onFocus} = $_[1]; }

sub _trigger_onBlur { return $_[0]->attributes->{onBlur} = $_[1]; }

sub _trigger_role { return $_[0]->attributes->{role} = $_[1]; }

sub _trigger_href { return $_[0]->attributes->{href} = $_[1]; }

sub _trigger_width { return $_[0]->attributes->{width} = $_[1]; }

sub _trigger_height { return $_[0]->attributes->{height} = $_[1]; }

sub _trigger_data_toggle { return $_[0]->attributes->{data_toggle} = $_[1]; }

sub _trigger_data_placement { return $_[0]->attributes->{data_placement} = $_[1]; }

sub _trigger_title { return $_[0]->attributes->{title} = $_[1]; }

sub _trigger_template_attr {
    return $_[0]->attributes->{template_attr} = $_[1];
}

sub _trigger_selected { return $_[0]->attributes->{selected} = $_[1]; }

sub _trigger_autocomplete { return $_[0]->attributes->{autocomplete} = $_[1]; }

sub _trigger_for { return $_[0]->attributes->{for} = $_[1]; }

sub _build_data {
    my $data = delete $_[0]->attributes->{data};
    my $text = delete $_[0]->attributes->{text};

    if ( defined $text ) {
        push @{$data}, $text;
    }

    return $data if defined $data && scalar @{$data};
    return [];
}

sub has_id { return length $_[0]->id ? 1 : 0; }

sub tidy_html {
    $_[1] =~ s/\s+>/>/g;
    return $_[1];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TableContent::Element - attributes, text, data, class, id

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

    $element->attributes;
    $element->data;

    $element->text;
    $element->class;
    $element->id;

=head1 Description

Base for L<HTML::TableContent::Table>, L<HTML::TableContent::Table::Header>,
L<HTML::TableContent::Table::Row>, L<HTML::TableContent::Table::Row::Cell> 
and L<HTML::TableContent::Table::Caption> 

=cut

=head1 SUBROUTINES/METHODS

=head2 attributes

hash consisting of the html attributes belonging to the current element.

    $element->attributes;

=head2 data

Array of text strings belonging to the current element.

    $element->data;

=head2 text

Join ' ' the elements data

    $element->text;

=head2 class

Element tag's class if found.

    $element->class;

=head2 id

Element tag's id if found.

    $element->id;

=head2 nested

ArrayRef of nested Tables.

    $element->nested

=head2 all_nested

Array of nested Tables.

    $element->all_nested

=head2 add_nested

Add a nested L<HTML::TableContent::Table> to the element.

    $element->add_nested({});

=head2 has_nested

Boolean check, returns true if the element has nested tables.

    $element->has_nested

=head2 count_nested

Count number of nested tables.

    $element->count_nested

=head2 get_first_nested

Get the first nested table.

    $element->get_first_nested

=head2 get_nested

Get Nested table by index.

    $element->get_nested(1);

=head2 links

ArrayRef of href links.

    $element->links;

=head2 all_links

Array of links.

    $element->links

=head2 has_links

Boolean check, returns true if the element has links.

    $element->has_links

=head2 count_links

Count number of links.

    $element->count_links

=head2 get_first_link

Get the first nested table.

    $element->get_first_link

=head2 get_last_link

Get the first nested table.

    $element->get_last_link

=head2 get_link

Get Nested table by index.

    $element->get_link(1);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 DEPENDENCIES

L<Moo>,
L<HTML::Parser>,

L<HTML::TableContent::Parser>,
L<HTML::TableContent::Table>,
L<HTML::TableContent::Table::Caption>,
L<HTML::TableContent::Table::Header>,
L<HTML::TableContent::Table::Row>,
L<HTML::TableContent::Table::Row::Cell>

=head1 BUGS AND LIMITATIONS

=head1 SUPPORT

=head1 DIAGNOSTICS

=head1 ACKNOWLEDGEMENTS
    
=head1 LICENSE AND COPYRIGHT

Copyright 2016->2020 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
