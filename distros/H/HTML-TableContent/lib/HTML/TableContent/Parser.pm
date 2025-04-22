package HTML::TableContent::Parser;

use Moo;

our $VERSION = '1.01';

extends 'HTML::Parser';

use HTML::TableContent::Table;

has [qw(current_tables nested caption_selectors)] => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    default => sub { [] },
);

has [qw(current_table current_element selected)] => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
);

has options => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

sub has_caption_selector { return scalar @{ $_[0]->caption_selectors } ? 1 : 0 }

sub count_nested { return scalar @{ $_[0]->nested }; }

sub has_nested { return $_[0]->count_nested ? 1 : 0; }

sub get_last_nested { return $_[0]->nested->[ $_[0]->count_nested - 1 ]; }

sub clear_last_nested {
    return delete $_[0]->nested->[ $_[0]->count_nested - 1 ];
}

sub all_current_tables { return @{ $_[0]->current_tables }; }

sub count_current_tables { return scalar @{ $_[0]->current_tables }; }

sub current_or_nested {
    return $_[0]->has_nested ? $_[0]->get_last_nested : $_[0]->current_table;
}

sub parse {
    my ( $self, $data ) = @_;

    $self->SUPER::parse($data);

    return $self->current_tables;
}

sub parse_file {
    my ( $self, $file ) = @_;

    $self->SUPER::parse_file($file);

    return $self->current_tables;
}

sub start {
    my ( $self, $tag, $attr, $attrseq, $origtext ) = @_;

    if ($self->current_element && $attr->{href}) {
        push @{ $self->current_element->links }, $attr->{href};
    }

    $tag = lc $tag;
    if ( my $option = $self->options->{$tag} ) {
        my $table = $self->current_or_nested;
        my $action = $option->{add};
        my $element = $self->$action($attr, $table);
        return $self->current_element($element);
    }

    if ( $self->has_caption_selector ) {
        foreach my $selector ( @{ $self->caption_selectors }) {
            if ( $selector eq $tag ) {
                return $self->selected($attr);
            }
            
            for my $field (qw/id class/) {
                my $val = $attr->{$field};
                next unless $val;
               
                if ( $val =~ m/$selector/ixms) {
                    return $self->selected($attr);
                }
            }
        }
    }

    return;
}

sub text {
    my ( $self, $text ) = @_;

    if ( my $elem = $self->current_element ) {
        if ( $text =~ m{\S+}xms ) {
            $text =~ s{^\s+|\s+$}{}g;
            push @{ $elem->data }, $text;
        }
    }
    if ( my $selected = $self->selected) {
        if ( $text =~ m{\S+}xms ) {
            $selected->{text} = $text;
            $self->selected($selected);
        }
    }

    return;
}

sub end {
    my ( $self, $tag, $origtext ) = @_;

    $tag = lc $tag;

    if ( my $option = $self->options->{$tag} ) {
        my $table = $self->current_or_nested;
        if ( my $action = $option->{close} ) {
            my $element = $self->$action($table);
        }
    }

    return;
}

sub _build_options {
    return {
        table => {
            add => '_add_table',
            close => '_close_table',
        },
        th => {
            add => '_add_header',
        },
        tr => {
            add => '_add_row',
            close => '_close_row',
        },
        td => {
            add => '_add_cell',
        },
        caption => {
            add => '_add_caption'
        }
    };
}

sub _add_header {
    my ($self, $attr, $table) = @_;

    my $header = $table->add_header($attr);
    $table->get_last_row->header($header);
    return $header;
}

sub _add_row {
    my ($self, $attr, $table) = @_;

    my $row = $table->add_row($attr);
    return $row;
}

sub _add_cell {
    my ($self, $attr, $table) = @_;

    my $cell = $table->get_last_row->add_cell($attr);
    $table->parse_to_column($cell);
    return $cell;
}

sub _add_caption {
    my ($self, $attr, $table) = @_;

    my $caption = $table->add_caption($attr);
    return $caption;
}

sub _add_table {
    my ($self, $attr, $table) = @_;

    my $element = HTML::TableContent::Table->new($attr);

    if ( defined $table && $table->isa('HTML::TableContent::Table') ) {
        if ( $self->has_nested ) {
            push @{ $self->current_table->nested }, $element; 
        }
        push @{ $self->nested }, $element;
        push @{ $table->nested }, $element;
        push @{ $table->get_last_row->get_last_cell->nested }, $element;
    }
    else {
        if ( my $caption = $self->selected ){
            $element->add_caption($caption);
            $self->clear_selected;
        }
        $self->current_table($element);
    }
}

sub _close_table {
    my ($self, $table) = @_;

    if ( $self->has_nested ) {
        return $self->clear_last_nested;
    }
    else {
        push @{ $self->current_tables }, $self->current_table;
        $self->clear_current_element;
        return $self->clear_current_table;
    }
}

sub _close_row {
    my ($self, $table) = @_;

    my $row = $table->get_last_row;

    if ( $row->header ) {
        $table->clear_last_row;

        my $index = 0;
        foreach my $cell ( $row->all_cells ) {
            my $row = $table->rows->[$index];
            if ( defined $row ) {
                push @{ $row->cells }, $cell;
            }
            else {
                my $new_row = $table->add_row({});
                push @{ $new_row->cells }, $cell;
            }
            $index++;
        }
    }
    elsif ( $row->cell_count == 0 ) {
        $table->clear_last_row;
    }

    return;
}

1;

__END__

=head1 NAME

HTML::TableContent::Parser - HTML::Parser subclass.

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

    my $t = HTML::TableContent->new();

    $t->parser->parse($html);

    # most recently parsed tables
    my $last_parsed = $t->parser->current_tables;

    for my $table ( @{ $last_parsed } ) {
        ...
    }

=head1 DESCRIPTION

HTML::Parser subclass.

=head1 SUBROUTINES/METHODS

=head2 parse

Parse $string as a chunk of html.

    $parser->parse($string);

=head2 parse_file

Parse a file that contains html.

    $parser->parse_file($string);

=head2 current_tables

ArrayRef consisiting of the last parsed tables.

    $parser->current_tables;

=head2 all_current_tables

Array consisiting of the last parsed tables.

    $parser->all_current_tables;

=head2 count_current_tables

Count of the current tables.

    $parser->count_current_tables;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 DEPENDENCIES

L<Moo>,
L<HTML::Parser>, 
L<HTML::TableContent::Parser>,
L<HTML::TableContent::Table>,
L<HTML::TableContent::Table::Caption>, 
L<HTML::TableContent::Table::Header>,
L<HTML::TableContent::Table::Row>,
L<HTML::TableContent::Table::Row::Cell>

=head1 CONFIGURATION AND ENVIRONMENT 

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 SUPPORT

=head1 DIAGNOSTICS

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016->2025 LNATION.

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

