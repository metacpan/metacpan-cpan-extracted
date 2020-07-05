package Markdent::Dialect::Theory::BlockParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use List::AllUtils qw( insert_after_string sum );
use Markdent::Event::StartTable;
use Markdent::Event::EndTable;
use Markdent::Event::StartTableHeader;
use Markdent::Event::EndTableHeader;
use Markdent::Event::StartTableBody;
use Markdent::Event::EndTableBody;
use Markdent::Event::StartTableRow;
use Markdent::Event::EndTableRow;
use Markdent::Event::StartTableCell;
use Markdent::Event::EndTableCell;
use Markdent::Regexes qw( $HorizontalWS $EmptyLine $BlockStart $BlockEnd );
use Markdent::Types;

use Moose::Role;

with 'Markdent::Role::Dialect::BlockParser';

has _in_table => (
    traits   => ['Bool'],
    is       => 'ro',
    isa      => t('Bool'),
    default  => 0,
    init_arg => undef,
    handles  => {
        _enter_table => 'set',
        _leave_table => 'unset',
    },
);

around _possible_block_matches => sub {
    my $orig = shift;
    my $self = shift;

    my @look_for = $self->$orig();

    return @look_for if $self->_list_level();

    if ( $self->_in_table() ) {
        insert_after_string 'list', 'table_cell', @look_for;
    }
    else {
        insert_after_string 'list', 'table', @look_for;
    }

    return @look_for;
};

my $TableCaption = qr{ ^
                       $HorizontalWS*
                       \[
                       (.*)
                       \]
                       $HorizontalWS*
                       \n
                     }xm;

# The use of (?> ... ) in the various regexes below forces the regex engine
# not to backtrack once it matches the relevant subsection. Using this where
# possible _hugely_ speeds up matching, and seems to be safe. At least, the
# tests pass.

my $PipeRow = qr{ ^
                  [|]?               # optional starting pipe
                  (?:
                    (?:
                      (?>[^\|\\\n]*) # safe chars (not pipe or escape or newline)
                    |
                      \\[|]          # an escaped newline
                    )+
                    [|]              # must have at least one pipe
                  )+
                  .*                 # can have a final cell after the last pipe
                }xm;

my $ColonRow = qr{ ^
                   :?
                   (?:
                     (?:
                       (?>[^:\\\n]*)
                       |
                       \\:
                     )+
                     :
                   )+
                   .*
                 }xm;

my $TableRow = qr{ (?>$PipeRow)        # must have at least one starting row
                   \n
                   (?>
                     (?:
                       $ColonRow
                       \n
                     )*                # ... can have 0+ continuation lines
                   )
                 }xm;

my $HeaderMarkerLine = qr/^[\-\+=]+\n/xm;

my $TableHeader = qr{ $TableRow
                      $HeaderMarkerLine
                    }xm;

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _match_table {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                $BlockStart
                                (
                                  $TableCaption?
                                  $HeaderMarkerLine?
                                  ($TableHeader+)?
                                  (
                                    $TableRow
                                    (?:
                                      $TableRow
                                      |
                                      $EmptyLine
                                    )*
                                  )
                                  $HeaderMarkerLine?
                                  $TableCaption?
                                )
                                $BlockEnd
                              /xmgc;

    $self->_debug_parse_result(
        $1,
        'table',
    ) if $self->debug();

    my $caption = defined $2 ? $2 : $5;

    $self->_debug_parse_result(
        $caption,
        'table caption',
    ) if defined $caption && $self->debug();

    my $header = $3;
    my $body   = $4;

    $self->_debug_parse_result(
        $header,
        'table header',
    ) if $self->debug();

    $self->_debug_parse_result(
        $body,
        'table body',
    ) if $self->debug();

    my @header;

    if ( defined $header ) {
        @header = $self->_parse_rows( qr/$HeaderMarkerLine/m, $header );
        $_->{is_header_cell} = 1 for map { @{$_} } @header;
    }

    my @body = $self->_parse_rows( qr/\n/, $body );

    $self->_normalize_cell_count_and_alignments( @header, @body );

    if (@header) {
        my $first_header_cell_content = $header[0][0]{content};
        unless ( defined $first_header_cell_content
            && $first_header_cell_content =~ /\S/ ) {
            $_->[0]{is_header_cell} = 1 for @body;
        }
    }

    $self->_enter_table();

    my %caption = defined $caption ? ( caption => $caption ) : ();
    $self->_send_event( 'StartTable', %caption );

    $self->_events_for_rows( \@header, 'Header' )
        if @header;
    $self->_events_for_rows( \@body, 'Body' );

    $self->_send_event('EndTable');

    $self->_leave_table();

    return 1;
}
## use critic

sub _parse_rows {
    my $self     = shift;
    my $split_re = shift;
    my $rows     = shift;

    my @rows;

    for my $chunk ( split $split_re, $rows ) {

        # Splitting on an empty string returns nothing, so we need to
        # special-case that, as we want to preserve empty lines.
        for my $line ( length $chunk ? ( split /\n/, $chunk ) : $chunk ) {
            if ( $line =~ /^$HorizontalWS*$/ ) {
                push @rows, undef;
            }
            elsif ( $self->_is_continuation_line($line) ) {

                # If the $TableRow regex is correct, this shouldn't be
                # possible.
                die q{Continuation of a row before we've seen a row start?!}
                    unless @rows;

                my $cells = $self->_cells_from_line( $line, ':' );

                for my $i ( 0 .. $#{$cells} ) {
                    if ( defined $cells->[$i]{content}
                        && $cells->[$i]{content} =~ /\S/ ) {
                        $rows[-1][$i]{content}
                            .= "\n" . $cells->[$i]{content};
                        $rows[-1][$i]{colspan} ||= 1;
                    }
                }
            }
            else {
                push @rows, $self->_cells_from_line( $line, '|' );
            }
        }
    }

    return @rows;
}

sub _is_continuation_line {
    my $self = shift;
    my $line = shift;

    return 0
        if $line =~ /(?<!\\)[|]/x;

    return 1
        if $line =~ /(^|\p{SpaceSeparator}+)(?<!\\):(\p{SpaceSeparator}|$)/x;

    # a blank line, presumably
    return 0;
}

sub _cells_from_line {
    my $self = shift;
    my $line = shift;
    my $div  = shift;

    my @row;

    for my $cell ( $self->_split_cells( $line, $div ) ) {
        if ( length $cell ) {
            push @row, $self->_cell_params($cell);
        }

        # If the first cell is empty, that means the line started with a
        # divider, and we can ignore the "cell". If we already have cells in
        # the row, that means we just saw a repeated divider, which means the
        # most recent cell has a colspan+1.
        elsif (@row) {
            $row[-1]{colspan}++;
        }
    }

    return \@row;
}

sub _split_cells {
    my $self = shift;
    my $line = shift;
    my $div  = shift;

    $line =~ s/^\Q$div//;
    $line =~ s/\Q$div\E$HorizontalWS*$/$div/;

    # We don't want to split on a backslash-escaped divider, thus the
    # lookbehind. The -1 ensures that Perl gives us the trailing empty fields.
    my @cells = split /(?<!\\)\Q$div/, $line, -1;

    # If the line has just one divider as the line-ending, it should not be
    # treated as marking an empty cell.
    if ( $cells[-1] eq q{} && $line =~ /\Q$div\E$HorizontalWS*$/ ) {
        pop @cells;
    }

    return @cells;
}

sub _cell_params {
    my $self = shift;
    my $cell = shift;

    my $alignment;
    my $content;

    if ( defined $cell && $cell =~ /\S/ ) {
        $alignment = $self->_alignment_for_cell($cell);

        ( $content = $cell ) =~ s/^$HorizontalWS+|$HorizontalWS+$//g;
    }

    my %p = (
        colspan => 1,
        content => $content,
    );

    $p{alignment} = $alignment
        if defined $alignment;

    return \%p;
}

sub _alignment_for_cell {
    my $self = shift;
    my $cell = shift;

    return 'center'
        if $cell =~ /^\p{SpaceSeparator}{2,}.+?\p{SpaceSeparator}{2,}$/;

    return 'left'
        if $cell =~ /\p{SpaceSeparator}{2,}$/;

    return 'right'
        if $cell =~ /^\p{SpaceSeparator}{2,}/;

    return;
}

sub _normalize_cell_count_and_alignments {
    my $self = shift;
    my @rows = @_;

    # We use the first header row as an indicator for how many cells we expect
    # on each line.
    my $default_cells = sum( map { $_->{colspan} } @{ $rows[0] } );

    # Alignments are inherited from the cell above, or they default to
    # "left". We loop through all the rules and set alignments accordingly.
    my %alignments;

    for my $row ( grep {defined} @rows ) {

        # If we have one extra column and the final cell has a colspan > 1 it
        # means we misinterpreted a trailing divider as indicating that the
        # prior cell had a colspan > 1. We adjust for that by comparing it to
        # the number of columns in the first row.
        if ( sum( map { $_->{colspan} } @{$row} ) == $default_cells + 1
            && $row->[-1]{colspan} > 1 ) {
            $row->[-1]{colspan}--;
        }

        my $i = 0;
        for my $cell ( @{$row} ) {
            if ( $cell->{alignment} ) {
                $alignments{$i} = $cell->{alignment};
            }
            else {
                $cell->{alignment} = $alignments{$i} || 'left';
            }

            $i += $cell->{colspan};
        }
    }
}

sub _events_for_rows {
    my $self = shift;
    my $rows = shift;
    my $type = shift;

    my $start = 'StartTable' . $type;
    my $end   = 'EndTable' . $type;

    $self->_send_event($start);

    for my $row ( @{$rows} ) {
        if ( !defined $row ) {
            $self->_send_event($end);
            $self->_send_event($start);
            next;
        }

        $self->_send_event('StartTableRow');

        for my $cell ( @{$row} ) {
            my $content = delete $cell->{content};

            $self->_send_event(
                'StartTableCell',
                %{$cell}
            );

            if ( defined $content ) {

                # If the content has newlines, it should be matched as a
                # block-level construct (blockquote, list, etc), but to make
                # that work, it has to have a trailing newline.
                $content .= "\n"
                    if $content =~ /\n/;

                $self->_parse_text( \$content );
            }

            $self->_send_event(
                'EndTableCell',
                is_header_cell => $cell->{is_header_cell},
            );
        }

        $self->_send_event('EndTableRow');
    }

    $self->_send_event($end);
}

# A table cell's contents can be a single line _not_ terminated by a
# newline. If that's the case, it won't match as a paragraph.
#
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _match_table_cell {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                (
                                  ^
                                  \p{SpaceSeparator}*
                                  \S
                                  .*
                                )
                                \z
                              /xmgc;

    $self->_debug_parse_result(
        $1,
        'table cell',
    ) if $self->debug();

    $self->_span_parser()->parse_block($1);
}
## use critic

1;

# ABSTRACT: Block parser for Theory's proposed Markdown extensions

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Dialect::Theory::BlockParser - Block parser for Theory's proposed Markdown extensions

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role adds parsing for Markdown extensions proposed by David Wheeler (aka
Theory). See
L<http://justatheory.com/computers/markup/markdown-table-rfc.html> and
L<http://justatheory.com/computers/markup/modest-markdown-proposal.html> for
details.

For now, this role handles tables only.

This role should be applied to L<Markdent::Parser::BlockParser> class or a
subclass of that class.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::BlockParser> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
