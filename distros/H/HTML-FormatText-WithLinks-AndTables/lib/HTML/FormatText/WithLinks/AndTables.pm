package HTML::FormatText::WithLinks::AndTables;

use strict;
use warnings;

our $VERSION = '0.07'; # VERSION

use base 'HTML::FormatText::WithLinks';
use HTML::TreeBuilder;

################################################################################
# configuration defaults
################################################################################
my $cellpadding     = 1; # number of horizontal spaces to pad interior of <td> cells
my $no_rowspacing   = 0; # boolean, suppress space between table rows and rows with empty <td>s
################################################################################

=head1 NAME

HTML::FormatText::WithLinks::AndTables - Converts HTML to Text with tables intact

=head1 VERSION

version 0.07

=cut

=head1 SYNOPSIS

    use HTML::FormatText::WithLinks::AndTables;

    my $text = HTML::FormatText::WithLinks::AndTables->convert($html);

Or optionally...

    my $conf = { # same as HTML::FormatText excepting below
        cellpadding   => 2,  # defaults to 1
        no_rowspacing => 1,  # bool, suppress vertical space between table rows
    };

    my $text = HTML::FormatText::WithLinks::AndTables->convert($html, $conf);

=head1 DESCRIPTION

This module was inspired by HTML::FormatText::WithLinks which has proven to be a
useful `lynx -dump` work-alike. However one frustration was that no other HTML
converters I came across had the ability to deal affectively with HTML <TABLE>s.
This module can in a rudimentary sense do so. The aim was to provide facility to take
a simple HTML based email template, and to also convert it to text with the <TABLE>
structure intact for inclusion as "multipart/alternative" content. Further, it will
preserve both the formatting specified by the <TD> tag's "align" attribute, and will
also preserve multiline text inside of a <TD> element provided it is broken using <BR/>
tags.

=head2 EXPORT

None by default.


=head1 METHODS

=head2 convert

=cut

my $parser_indent = 3; # HTML::FormatText::WithLinks adds this indent to <table> data
my $conf_defaults = {};

# the one and only public interface
sub convert {
    shift if $_[0] eq __PACKAGE__; # to make it function friendly
    my ($html, $conf) = @_;

    # over-ride our defaults
    if ($conf and ref $conf eq 'HASH') {
        $no_rowspacing = $$conf{no_rowspacing} if $$conf{no_rowspacing};
        delete $$conf{no_rowspacing};
        $cellpadding = $$conf{cellpadding} if $$conf{cellpadding};
        delete $$conf{cellpadding};
        %$conf_defaults = (%$conf_defaults, %$conf);
    }

    return __PACKAGE__->new->parse($html);
}

# sub-class configure
sub configure {
# SUPER::configure actually modifies the hash, so we need to pass a copy
    my %configure = %$conf_defaults;

    shift()->SUPER::configure(\%configure);
}

# sub-class parse
sub parse {

    my $self = shift;
    my $html = shift;

    return unless defined $html;
    return '' if $html eq '';

    my $tree = HTML::TreeBuilder->new->parse( $html );
    return $self->_format_tables( $tree ); # we work our magic...

}

# a private method
sub _format_tables {
    my $self = shift;
    my $tree = shift;

    my $formatted_tables = []; # a nested stack for our formatted table text

    # the result of an all night programming session...
    #
    # essentially we take two passes over each table
    # and modify the structure of text and html by replacing <td> content with tokens
    # then replacing the tokens after _parse() has converted it to text
    #
    # for each <tr> in each <table>...
    #   we grab all it's <td> inner text (and/or parsed html), rearrange it into a
    #   single string of formatted text, and put a token into it's first <td>
    # once we have processed the html with _parse(), we replace the tokens with the
    # corresponding formatted text

    my @tables = $tree->look_down(_tag=>'table');
    my $table_count = 0;
    for my $table (@tables) {
        $formatted_tables->[$table_count] = [];
        my @trs = $table->look_down(_tag=>'tr');
        my @max_col_width; # max column widths by index
        my @max_col_heights; # max column heights (for multi-line text) by index
        my @col_lines; # a stack for our redesigned rows of column (<td>) text
        FIRST_PASS: {
            my $row_count = 0; # obviously a counter...
            for my $tr (@trs) { # *** 1st pass over rows
                $max_col_heights[$row_count] = 0;
                $col_lines[$row_count] = [];
                my @cols = $tr->look_down(_tag=>qr/^(td|th)$/); # no support for <th>. sorry.
                for (my $i = 0; $i < scalar @cols; $i++) {
                    my $td = $cols[$i]->clone;
                    my $new_tree = HTML::TreeBuilder->new;
                    $new_tree->{_content} = [ $td ];
                    # parse the contents of the td into text
                    # this doesn't work well with nested tables...
                    my $text = __PACKAGE__->new->_parse($new_tree);
                    # we don't want leading or tailing whitespace
                    $text =~ s/\xA0+/ /s; # &nbsp -> space
                    $text =~ s/^\s+//s;
                    $text =~ s/\s+\z//s;
                    # now we figure out the maximum widths and heights needed for each column
                    my $max_line_width = 0;
                    my @lines = split "\n", $text; # take the parsed text and break it into virtual rows
                    $max_col_heights[$row_count] = scalar @lines if scalar @lines > $max_col_heights[$row_count];
                    for my $line (@lines) {
                        my $line_width = length $line;
                        $max_line_width = $line_width if $line_width > $max_line_width;
                    }
                    $cols[$i]->{_content} = [ $text ];
                    $max_col_width[$i] ||= 0;
                    $max_col_width[$i] = $max_line_width if $max_line_width > $max_col_width[$i];
                    # now put the accumulated lines onto our stack
                    $col_lines[$row_count]->[$i] = \@lines;
                }
                $tr->{_content} = \@cols;
                $row_count++;
            }
        }

        SECOND_PASS: {
            my $row_count = 0; # obviously, another counter...
            for my $tr (@trs) { # *** 2nd pass over rows
                my @cols = $tr->look_down(_tag=>qr/^(td|th)$/); # no support for <th>. sorry.

                my $row_text; # the final string representing each row of reformatted text

                my @col_rows; # a stack for each virtual $new_line spliced together from a group of <td>'s

                # iterate over each column of the maximum rows of parsed multiline text per <td>
                # for each virtual row of each virtual column, concat the text with alignment spacings
                # the final concatinated string value will be placed in column 0
                for (my $j = 0; $j < $max_col_heights[$row_count]; $j++) {
                    my $new_line;
                    for (my $i = 0; $i < scalar @cols; $i++) { # here are the actual <td> elements we're iterating over...
                        my $width = $max_col_width[$i] + $cellpadding; # how wide is this column of text
                        my $line = $col_lines[$row_count]->[$i]->[$j]; # get the text to fit into it
                        $line = defined $line ? $line : '';

                        # strip the whitespace from beginning and end of each line
                        $line =~ s/^\s+//gs;
                        $line =~ s/\s+\z//gs;
                        my $n_space = $width - length $line; # the difference between the column and text widths

                        # we are creating virtual rows of text within a single <td>
                        # so we need to add an indent to all but the first row to
                        # match the indent added by _parse() for presenting table contents
                        $line = ((' ')x$parser_indent). $line if $j != 0 and $i == 0;

                        # here we adjust the text alignment by wrapping the text in occulted whitespace
                        my $justify = $cols[$i]->tag eq 'td' ? ( $cols[$i]->attr('align') || 'left' ) : 'center';
                        if ($justify eq 'center') {
                            my $pre = int( ($n_space + $cellpadding) / 2 ); # divide remaining space in half
                            my $post = $n_space - $pre; # assign any uneven remainder to the end
                            $new_line .= ((' ')x$pre). $line .((' ')x$post); # wrap the text in spaces
                        } elsif ($justify eq 'left') {
                            $new_line .= ((' ')x$cellpadding). $line .((' ')x$n_space);
                        } else {
                            $new_line .= ((' ')x$n_space). $line .((' ')x$cellpadding);
                        }
                    }
                    $new_line .= "\n" if $j != $max_col_heights[$row_count] - 1; # add a newline to all but the last text row
                    $col_rows[$j] = $new_line; # put the line into the stack for this row
                }
                $row_text .= $_ for @col_rows;
                for (my $i = 1; $i < scalar @cols; $i++) {
                    $cols[$i]->delete; # get rid of unneeded <td>'s
                }
                # put the fully formatted text into our accumulator
                $formatted_tables->[$table_count]->[$row_count] = $row_text;
                if (scalar @cols) {
                   $cols[0]->content->[0] = "__TOKEN__${table_count}__${row_count}__"; # place a token into the row at col 0
                }
                $row_count++;
            }
        }
        $table_count++;
    }

    # now replace our tokens
    my $text = $self->_parse( $tree );
    for (my $i = 0; $i < scalar @$formatted_tables; $i++) {
        for (my $j = 0; $j < scalar @{ $$formatted_tables[$i] }; $j++) {
            my $token = "__TOKEN__${i}__${j}__";
            $token .= "\n?" if $no_rowspacing;
            my $new_text = $$formatted_tables[$i][$j];
            if (defined $new_text) {
               $text =~ s/$token/$new_text/;
            }
            else {
               $text =~ s/$token//;
            }
        }
    }

    return $text;
}

1;
__END__

=head1 EXAMPLE

Given the HTML below ...

    <HTML><BODY>
    <TABLE>
        <TR>
            <TD ALIGN="right">Name:</TD>
            <TD>Mr. Foo Bar</TD>
        </TR>
        <TR>
            <TD ALIGN="right">Address:</TD>
            <TD>
                #1-276 Quux Lane,     <BR/>
                Schenectady, NY, USA, <BR/>
                12345
            </TD>
        </TR>
        <TR>
            <TD ALIGN="right">Email:</TD>
            <TD><a href="mailto:foo@bar.baz">foo@bar.baz</a></TD>
        </TR>
    </TABLE>
    </BODY></HTML>

... the (default) return value of convert() will be as follows.

       Name:  Mr. Foo Bar

    Address:  #1-276 Quux Lane,
              Schenectady, NY, USA,
              12345

      Email:  [1]foo@bar.baz



              1. mailto:foo@bar.baz

=head1 SEE ALSO

    HTML::FormatText::WithLinks
    HTML::TreeBuilder

=head1 CAVEATS

    * <TH> elements are treated identically to <TD> elements

    * It assumes a fixed width font for display of resulting text.

    * It doesn't work well on nested <TABLE>s or other nested blocks within <TABLE>s.

=head1 AUTHOR

Shaun Fryer, C<< <pause.cpan.org at sourcery.ca> >> (author emeritus)

Dale Evans, C<< <daleevans at cpan.org> >> (current maintainer)

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-formattext-withlinks-andtables at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-FormatText-WithLinks-AndTables>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::FormatText::WithLinks::AndTables


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormatText-WithLinks-AndTables>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-FormatText-WithLinks-AndTables>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-FormatText-WithLinks-AndTables>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-FormatText-WithLinks-AndTables>

=back


=head1 ACKNOWLEDGEMENTS

Everybody. :)
L<http://en.wikipedia.org/wiki/Standing_on_the_shoulders_of_giants>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shaun Fryer, all rights reserved.

Copyright 2015 Dale Evans, all rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=for Pod::Coverage configure

=cut
