# -*-perl-*-
# Creation date: 2003-09-05 20:58:07
# Authors: Don
# Change log:
# $Id: Table.pm,v 1.7 2003/09/14 07:41:39 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;

use HTML::Widgets::Table::Core;
use HTML::Widgets::Table::Row;

=pod

=head1 NAME

 HTML::Widgets::Table - An HTML table generation class.

=head1 SYNOPSIS

 use HTML::Widgets::Table;
 my $table = HTML::Widgets::Table->new(\%params);
 my $html = $table->render;

=head1 DESCRIPTION

 HTML::Widgets::Table creates an HTML table from native data structures.

=head1 METHODS

=cut

{   package HTML::Widgets::Table;

    use vars qw($VERSION);

    BEGIN {
        $VERSION = '0.01'; # change in POD below
    };

    use base 'HTML::Widgets::Table::Core';

=pod

=head2 new(\%params)

 Create a new table object.  Parameters that can be passed
 include any legal attributes for an HTML table tag.  In
 addition, the following parameters may be passed.

=over 4

 pretty_border => 1
 pretty_border_color => '#669999'

    If pretty_border is a true value, the table will be rendered
    with a browser-independent border by putting the table inside
    another table, allowing the background color of the outside
    table come through as the border.  The value of pretty_border
    will be with width of the border, and pretty_border_color
    will be the color of the border.

 alternating_row_colors => [ '#ffffff',
                             '#f2f2f2'
                           ]

    You can use this to alternate the background color of the
    rows in the table.  This is useful for making tables without
    borders and rules easier to read.

=back

=cut
    sub new {
        my ($proto, $params) = @_;
        $params = {} unless ref($params) eq 'HASH';
        my $self = { _rows => [], _indent_level => 0, _indent_width => 0,
                     _params => $params };
        bless $self,  ref($proto) || $proto;
        return $self;
    }

=pod

=head2 addHeaderRow(\@data, \%cell_params, \%params)

 Adds a header row to the table (as in the <th> tags for the
 columns).  Header rows are also enclosed in <thead> tags.  @data
 is an array of column values.  Any elements of the array that
 are hash references are taken to be key/value pairs with the
 cell contents as the value associated with the key 'data', and
 all the other key/value pairs are attributes to be applied to
 that cell.  These override the values in %cell_params.
 %cell_params are default attributes for every column in the row.
 %params are the row attributes to go in the <tr> tag.

=cut
    sub addHeaderRow {
        my ($self, $data, $cell_params, $params) = @_;
        $params = {} unless ref($params) eq 'HASH';
        $params = { %$params, header => 1};
        return $self->_addRow($data, $cell_params, $params);
    }

=pod

=head2 addRow(\@data, \%cell_params, \%params)

 Adds a new row to the table.  @data is an array of column
 values.  Any elements of the array that are hash references are
 taken to be key/value pairs with the cell contents as the value
 associated with the key 'data', and all the other key/value
 pairs are attributes to be applied to that cell.  These override
 the values in %cell_params.  %cell_params are default attributes
 for every column in the row.  %params are the row attributes to
 go in the <tr> tag.


=cut
    sub addRow {
        my ($self, $data, $cell_params, $params) = @_;
        return $self->_addRow($data, $cell_params, $params);
    }

=pod

=head2 setRepeatingHeaderRow(\@data, \%cell_params, \%params, $repeat_interval)

 Adds a header row to be repeated every $repeat_interval rows.
 This is useful to keep the user oriented when viewing long tables.

=cut
    sub setRepeatingHeaderRow {
        my ($self, $data, $cell_params, $params, $repeat_interval) = @_;
        $params = {} unless ref($params) eq 'HASH';
        $params = { %$params, header => 1};

        my $row = $self->_createRow($data, $cell_params, $params);
        $$self{_repeating_header_row} = $row;
        $$self{_repeating_header_row_interval} = $repeat_interval;
        return 1;
    }

=pod

=head2 setRepeatingRow(\@data, \%cell_params, \%params, $repeat_interval)

 Adds a row to be repeated every $repeat_interval rows.
 This is useful to keep the user oriented when viewing long tables.

=cut
    sub setRepeatingRow {
        my ($self, $data, $cell_params, $params, $repeat_interval) = @_;
        my $row = $self->_createRow($data, $cell_params, $params);
        $$self{_repeating_header_row} = $row;
        $$self{_repeating_header_row_interval} = $repeat_interval;
        return 1;
    }

    sub _addRow {
        my ($self, $data, $cell_params, $params) = @_;
        my $row = $self->_createRow($data, $cell_params, $params);
        push @{$$self{_rows}}, $row;
        return 1;

    }
    
    sub _createRow {
        my ($self, $data, $cell_params, $params) = @_;
        
        if (UNIVERSAL::isa($data, 'HTML::Widgets::Table::Row')) {
            push @{$$self{_rows}}, $data;
            return 1;
        }
        
        $params = {} unless ref($params) eq 'HASH';
        $params = { %$params };
        my $row = $self->getNewRowObj($params);
        $cell_params = {} unless ref($cell_params) eq 'HASH';
        $cell_params = { %$cell_params }; # make copy
        my $table_params = $self->_getParams;
        if ($$table_params{pretty_border}) {
            my $bg_color = $$table_params{pretty_border_background};
            $bg_color = '#ffffff' if $bg_color eq '';
            $cell_params = { pretty_border_background => $bg_color, %$cell_params };
        }
        foreach my $cell (@$data) {
            $row->addCell($cell, $cell_params);
        }

        return $row;
    }

    sub _addRowObj {
        my ($self, $row) = @_;
        push @{$$self{_rows}}, $row;
    }
    
    sub getNewRowObj {
        my ($self, $params) = @_;
        return HTML::Widgets::Table::Row->new($params);
    }

    sub _getDefaultParams {
        my ($self) = @_;
        my $defaults = { summary => '', border => 0 };

        return $defaults;
    }

    sub _getNonAttrParams {
        return { pretty_border => 1,
                 pretty_border_color => 1,
                 pretty_border_background => 1,
                 alternating_row_colors => 1,
               };
    }

=pod

=head2 render()

 Returns a string containing the HTML version of the table.

=cut
    sub render {
        my ($self) = @_;
        my $str;
        my $params = $self->_getParams;
        my $attr = $self->_getRenderAttr;

        my $repeat_row = $$self{_repeating_header_row};
        my $repeat_interval = $$self{_repeating_header_row_interval};
        $repeat_row = undef unless $repeat_interval > 1;

        my $alternating_row_colors = $$params{alternating_row_colors};
        $alternating_row_colors = undef unless ref($alternating_row_colors) eq 'ARRAY'
            and @$alternating_row_colors;

        if (my $width = $$params{pretty_border}) {
            $$attr{cellspacing} = $width;
            $$attr{width} = '100%';
        }

        my $attr_str = $self->_getAttributeStringFromHash($attr);
        $attr_str = ' ' . $attr_str unless $attr_str eq '';
        $str .= qq{<table$attr_str>\n};

        my $head = 0;
        my $body = 0;
        my $body_row_count = -1;
        my $row_num = -1;
        foreach my $row (@{$$self{_rows}}) {
            $row_num++;
            my $this_row_params = {};

            if ($repeat_row and $row_num % $repeat_interval == 0) {
                $str .= $repeat_row->render;
            }
            
            if ($row->isHeaderRow) {
                if (defined($head)) {
                    if ($head == 0) {
                        $str .= qq{<thead>\n};
                    }
                    $head++;
                }
            } else {
                if (defined($head) and $head != 0) {
                    $str .= qq{</thead>\n};
                }
                undef $head;
                $str .= qq{<tbody>\n} if $body == 0;
                $body++;
            }
            if ($body) {
                $body_row_count++;

                if ($alternating_row_colors) {
                    my $num_colors = scalar(@$alternating_row_colors);
                    my $color = $$alternating_row_colors[$body_row_count % $num_colors];
                    $$this_row_params{bgcolor} = $color;
                }
            }
            $str .= $row->render($this_row_params);
        }

        $str .= qq{</thead>\n} if defined($head);
        $str .= qq{</tbody>\n} unless $body == 0;
        
        $str .= qq{</table>\n};

        if (my $width = $$params{pretty_border}) {
            my $border_color = $$params{pretty_border_color};
            $border_color = '#000000' if $border_color eq '';
            my $outer_table = $self->new({ bgcolor => $border_color, cellpadding => 0,
                                           cellspacing => 0 });
            my $cell_data = { data => "\n" . $str, attr => { bgcolor => $border_color }  };
            $outer_table->addRow([ $cell_data ], {}, { bgcolor => $border_color });
            return $outer_table->render;
        }
        
        return $str;
    }

}

1;

__END__

=pod


=head1 AUTHOR

 Don Owens <don@owensnet.com>

=head1 COPYRIGHT

 Copyright (c) 2003 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 0.01

=cut
