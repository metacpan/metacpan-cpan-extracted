#  TableContentParser
#  A package to parse the contents of HTML tables.
#  (C) 2002  Simon Drabble  <sdrabble@cpan.org>
#
#  $Id: TableContentParser.pm,v 1.7 2002/07/14 15:00:43 simon Exp $


package HTML::TableContentParser;

use HTML::Parser;

@ISA = qw(HTML::Parser);

use strict;

our $VERSION = 0.13;

our $DEBUG = 0;


# The tags we're interested in.
my @tag_names = qw(table tr td th caption);


sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;

	$tag = lc($tag);

# Store the incoming details in the current 'object'.
	if ($tag eq 'table') {
		my $table = $attr;
		push @{$self->{STORE}->{tables}}, $table;
		$self->{STORE}->{current_table} = $table;

	} elsif ($tag eq 'th') {
		my $th = $attr;
		push @{$self->{STORE}->{current_table}->{headers}}, $th;
		$self->{STORE}->{current_header} = $th;
		$self->{STORE}->{current_element} = $th;

	} elsif ($tag eq 'tr') {
		my $tr = $attr;
		push @{$self->{STORE}->{current_table}->{rows}}, $tr;
		$self->{STORE}->{current_row} = $tr;
		$self->{STORE}->{current_element} = $tr;

	} elsif ($tag eq 'td') {
		my $td = $attr;
		push @{$self->{STORE}->{current_row}->{cells}}, $td;
		$self->{STORE}->{current_data_cell} = $td;
		$self->{STORE}->{current_element} = $td;

	} elsif ($tag eq 'caption') {
		my $cap = $attr;
		$self->{STORE}->{current_table}->{caption} = $cap;
		$self->{STORE}->{current_element} = $cap;

	} else {
## Found a non-table related tag. Push it into the currently-defined td
## or th (if one exists).
		my $elem = $self->{STORE}->{current_element};
		if ($elem) {
			$self->debug('TEXT(tag) = ', $origtext) if $DEBUG;
			$elem->{data} .= $origtext;
		}
		
	}
	
	$self->debug($origtext) if $DEBUG;
}



sub text
{
	my ($self, $text) = @_;
	my $elem = $self->{STORE}->{current_element};
	if (!$elem) {
		return undef;
	}

	$self->debug('TEXT = ', $text) if $DEBUG;
	$elem->{data} .= $text;
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	$tag = lc($tag);

# Turn off the current object
	if ($tag eq 'table') {
		$self->{STORE}->{current_table} = undef;
		$self->{STORE}->{current_row} = undef;
		$self->{STORE}->{current_data_cell} = undef;
		$self->{STORE}->{current_header} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'th') {
		$self->{STORE}->{current_row} = undef;
		$self->{STORE}->{current_data_cell} = undef;
		$self->{STORE}->{current_header} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'tr') {
		$self->{STORE}->{current_row} = undef;
		$self->{STORE}->{current_data_cell} = undef;
		$self->{STORE}->{current_header} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'td') {
		$self->{STORE}->{current_data_cell} = undef;
		$self->{STORE}->{current_header} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'caption') {
		$self->{STORE}->{current_element} = undef;

	} else {
## Found a non-table related close tag. Push it into the currently-defined
## td or th (if one exists).
		my $elem = $self->{STORE}->{current_element};
		if ($elem) {
			$self->debug('TEXT(tag) = ', $origtext) if $DEBUG;
			$elem->{data} .= $origtext;
		}
		
	}

	$self->debug($origtext) if $DEBUG;
}


sub parse
{
	my ($self, $data) = @_;

	$self->{STORE} = undef;

# Ensure the following keys exist
	$self->{STORE}->{current_data_cell} = undef;
	$self->{STORE}->{current_row} = undef;
	$self->{STORE}->{current_table} = undef;

	$self->SUPER::parse($data);

	return $self->{STORE}->{tables};
}




sub debug
{
	my ($self) = shift;
	my $class = ref($self);
	warn "$class: ", join('', @_), "\n";
}


1;


__END__

=head1 NAME

HTML::TableContentParser - Do interesting things with the contents of tables.

=head1 SYNOPSIS

  use HTML::TableContentParser;
  $p = HTML::TableContentParser->new();
  $tables = $p->parse($html);

=head1 DESCRIPTION

This package pulls out the contents of a table from a string containing HTML.
Each time a table is encountered, data will be stored in an array consisting
of a hash of whatever was discovered about the table -- id, name, border,
cellspacing etc, and of course data contained within the table. 

The format of each hash will look something like

  attributes            keys from the attributes of the <table> tag
  @{$table_headers}     array of table headers, in order found
  @{$table_rows}        rows discovered, in order

If the table has a caption, this will be provided as 

  caption               keys from the caption tag's attributes
    data                the text of the <caption>..</caption> element

then for each table row,
    @{$table_data}      td's found, in order
    other attributes    the ... in <tr ...>

then for each data cell,
      data              what comes between <td> and </td>
      other attributes  the ... in <td ...>
		  

=head2 EXAMPLE

  use HTML::TableContentParser;
  $p = HTML::TableContentParser->new();
	$html = read_html_from_somewhere();
  $tables = $p->parse($html);
  for $t (@$tables) {
    for $r (@{$t->{rows}}) {
			print "Row: ";
      for $c (@{$r->{cells}}) {
        print "[$c->{data}] ";				
      }				
      print "\n";			
    }
  }

	
=head1 METHODS

=over 4

=item start($parser, $tag, $attr, $attrseq, $origtext);

Called whenever a particular start tag has been recognised. This is called
automatically by the parser and should not be called from the application.


=item text($parser, $content); 

Called whenever a piece of content is encountered. This is called
automatically by the parser and should not be called from the application.

=item end($parser, $tag, $origtext);  

Called whenever a particular end tag is encountered. This is called
automatically by the parser and should not be called from the application.

=item $tables_ref = $p->parse($html);

Called with the HTML to parse. This is all the application needs to do. 
The return value will be an arrayref containing each table encountered, in the
format detailed above.

=item DEBUG

Not a method, but a class variable. Set to 1 to cause debugging output
(basically the structure and content of the table) to be sent to stdout via
warn().

=back

=head2 EXPORTS

Nothing.


=head2 CAVEATS, BUGS, and TODO


=head1 AUTHOR

  Simon Drabble  E<lt>sdrabble@cpan.orgE<gt>

  (C) 2002  Simon Drabble  

This software is released under the same terms as perl.


=cut

