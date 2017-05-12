package HTML::ListScraper::Interactive;

use warnings;
use strict;

use HTML::Entities;

require Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(format_tags canonicalize_tags);

use Class::Generate qw(class);

class 'HTML::ListScraper::FormTag' => {
    name => { type => '$', required => 1 },
    index => { type => '$', required => 1, readonly => 1 },
    link => { type => '$', required => 1, readonly => 1 },
    text => { type => '$', required => 1, readonly => 1 },
    '&close_name' => q{ $name .= '/'; }
};

sub is_opening {
    my $tag = shift;

    return $tag !~ m~\/~;
}

sub is_closing {
    my $tag = shift;

    return $tag =~ m~^\/~;
}

sub format_tags {
    my ($scraper, $tags, $incl) = @_;

    my $incl_attr;
    my $incl_text;
    my $incl_index;
    if (ref($incl)) {
        $incl_attr = $incl->{attr};
        $incl_text = $incl->{text};
        $incl_index = $incl->{index};
    }

    my @buffer;
    my @stack;
    foreach my $td (@$tags) {
        my $name = $td->name;
	my $tag = $name;
	$tag =~ s~^\/~~;

	my $text = $td->text || '';
	$text =~ s/[\s[:cntrl:]]+/ /g;

	my $link = $td->link || '';
	$link =~ s/[\s[:cntrl:]]+//g;

	if ($name eq $tag) {
	    push @stack, [ $tag, scalar(@buffer) ];
	    push @buffer, HTML::ListScraper::FormTag->new(name => $name,
                index => $td->index, link => $link, text => $text);
	} else {
	    while (scalar(@stack) &&
		    ($stack[scalar(@stack) - 1]->[0] ne $tag)) {
		if ($scraper->is_unclosed_tag(
                        $stack[scalar(@stack) - 1]->[0])) {
		    my $pair = pop @stack;

		    $buffer[$pair->[1]]->close_name();
		} else {
		    last;
		}
	    }

	    if (scalar(@stack)) {
	        pop @stack;
	    }

	    push @buffer, HTML::ListScraper::FormTag->new(name => $name,
                index => $td->index, link => $link, text => $text);
	}
    }

    while (scalar(@stack)) {
        my $pair = pop @stack;
	$buffer[$pair->[1]]->close_name();
    }

    my @out;
    my $prev;
    my $prev_index;
    my $depth = 0;
    foreach my $ft (@buffer) {
        my $name = $ft->name;
        if (defined($prev)) {
	    my $op = is_opening($prev);
	    my $cl = is_closing($name);
  	    if ($op && !$cl) {
	        ++$depth;
	    } elsif (!$op && $cl) {
	        if ($depth > 0) {
		    --$depth;
		}
	    }
        }

	my $indent = ' ' x (2 * $depth);

	my $attr = '';
	if ($incl_attr && $ft->link) {
	    $attr = ' href="' . encode_entities($ft->link, '"') . '"';
	}

	my $lncol = '';
	if ($incl_index) {
	    $lncol = $ft->index . "\t";
	}

	if (defined($prev_index) && (($ft->index - $prev_index) != 1)) {
	    push @out, "\n";
	}

	push @out, "$lncol$indent<$name$attr>\n";
	
	if ($incl_text && ($ft->text !~ /^[\s\r\n]*$/)) {
	    $lncol = $incl_index ? "\t" : "";
	    push @out, $lncol . $indent . encode_entities($ft->text, "<>&") . "\n";
	}

	$prev = $name;
	$prev_index = $ft->index;
    }

    return wantarray ? @out : \@out;
}

sub canonicalize_tags {
    my @out;
    foreach (@_) {
        my $ln = lc $_;
	$ln =~ s/^\s*<//;
	$ln =~ s/\/?>[\s\r\n]*$//;

	if ($ln) {
	    push @out, $ln;
	}
    }

    return wantarray ? @out : \@out;
}

1;

__END__

=head1 NAME

HTML::ListScraper::Interactive - formatting data from L<HTML::ListScraper>

=head1 FUNCTIONS

=head2 format_tags

Formats a tag sequence to emphasize its tree-like structure. Takes 2
or 3 parameters: a L<HTML::ListScraper> object, array reference
containing L<HTML::ListScraper::Tag> objects and an optional hash with
formatting options. C<format_tags> returns an array (array reference
if called in a scalar context) with formatted tag names and text.

The formatting options are

=over

=item attr

Include the C<href> attribute in the output.

=item text

Include the plain text in the output.

=item index

Include tag positions in the output.

=back

The returned values are basically XHTML lines: opening tags, text with
quoted entities and closing tags. Tags are enclosed in angle
brackets. The returned values don't necessarily form a valid XML
fragment, though, i.e. because the input tags need not form a
tree.

When C<index> is set, tag values start with the tag's index, followed
by a tab. Next, spaces show indentation. An opening tag not identified
as missing a closing tag increases indentation by 2 spaces, a closing
tag decreases it back. An opening tag with missing closing tag is
output with '/' appended to its name. For the rules of associating
opening and closing tags, see C<HTML::ListScraper::shapeless>.

When C<attr> is set, links are formatted without whitespace and
enclosed in double quotes. Double quotes in links are escaped, but no
other characters are (which can also make the result invalid
HTML). When C<text> is set, the output text has normalized whitespace;
nodes containing only whitespace are dropped. Gaps between adjacent
tag positions are displayed as an empty line. All values end with a
newline.

=head2 canonicalize_tags

Undoes the formatting done by C<format_tags>. Takes a list of lines
such as those output by C<format_tags> when called without any
formatting options and converts them to a list of tag names. Note that
C<canonicalize_tags> doesn't handle attributes, text lines nor index
numbers.

