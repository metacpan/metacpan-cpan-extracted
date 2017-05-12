#  $Id: TableExtractor.pm,v 1.2 2002/06/11 15:52:25 simon Exp $


package HTML::TableExtractor;

use HTML::Parser;

@ISA = qw(HTML::Parser);

use strict;


our $VERSION = 0.11;

# The tags we're interested in.
my @tag_names = qw(table tr td th);



sub start
{
	my ($self, $tag, $attr, $attrseq, $origtext) = @_;

	return unless grep { $_ eq lc($tag) } @tag_names;

	if (ref($self->{"${tag}_start_callback"}) eq 'CODE') {
		&{$self->{"${tag}_start_callback"}}($attr, $origtext);
	}
	if (ref($self->{"${tag}_callback"}) eq 'CODE') {
		&{$self->{"${tag}_callback"}}($attr, $origtext);
	}

}




sub end
{
	my ($self, $tag, $origtext) = @_;

	return unless grep { $_ eq lc($tag) } @tag_names;

	if (ref($self->{"${tag}_callback"}) eq 'CODE') {
		&{$self->{"${tag}_callback"}}($origtext);
	}
	if (ref($self->{"${tag}_end_callback"}) eq 'CODE') {
		&{$self->{"${tag}_end_callback"}}($origtext);
	}
}



sub parse
{
	my ($self, $data, @types) = @_;
	my %cbs = @types;

	for (@tag_names) {
		$self->{$_ . "_callback"} = $cbs{$_} if exists $cbs{$_};
		$self->{$_ . "_start_callback"} = $cbs{"start_$_"}
			if exists $cbs{"start_$_"};
		$self->{$_ . "_end_callback"} = $cbs{"end_$_"}
			if exists $cbs{"end_$_"};
	}
	$self->SUPER::parse($data);
}




1;

__END__

=head1 NAME

HTML::TableExtractor - Do stuff with the layout of HTML tables.

=head1 SYNOPSIS

  use HTML::TableExtractor;
  $p = HTML::TableExtractor->new();
  $p->parse($html, 	table => sub { ... }, tr => sub { ... });

=head1 DESCRIPTION

Parses HTML looking for table-related elements (table, tr, td and th as of 
version 0.1).

Three callbacks can be registered for each element. These callbacks,
described below, are executed whenever an element of a particular type is
encountered.
  
  o  start_${tagname}  Called whenever $tagname is opened.
  o  ${tagname}        Called immediately after start_${tagname}, and
		                   immediately before end_${tagname}.
  o  end_${tagname}    Called whenever a closing $tagname is encountered.


=head2 EXAMPLE

  use HTML::TableExtractor;
  $p = HTML::TableExtractor->new();
  $p->parse($html,
      start_table => sub {
        my ($attr, $origtext) = @_;
        print "Table border is $table->{border}\n";
      },
      tr => sub { print "Row opened or closed.\n" },
      );

	
=head1 METHODS

=over 4

=item start($parser, $tag, $attr, $attrseq, $origtext);

Called whenever a particular start tag has been recognised. This module
recognises these tags: <table>, <tr>, <td> & <th>.

This method will be called by the parser and is not intended to be called from
an application. 

=item end($parser, $tag, $origtext); 

Called whenever a particular end tag is encountered.

This method will be called by the parser and is not intended to be called from
an application. 

=item $p->parse($html, tag_type => \&coderef, ...);

This method is all you really need to do. Call it with callbacks for each tag
type. These will be executed as described above.


=back

=head2 EXPORTS


=head2 CAVEATS, BUGS, and TODO

o  parse() should handle other data sources, such as streaming, file handle
etc.


=head2 SEE ALSO

HTML::Parser, HTML::TableContentParser

=head1 AUTHOR

Simon Drabble  E<lt>simon@thebigmachine.org<gt>

(C) 2002  Simon Drabble  

This software is released under the same terms as perl.

=cut

