package HTML::TableContentParser;

use strict;
use warnings;

use parent qw{ HTML::Parser };

our $VERSION = '0.303';

our $CLASSIC = 0;
our $DEBUG = 0;

my @stacked = qw{ current_table current_row current_element };

sub new
{
	my ( $class, %arg ) = @_;
	my $classic = delete $arg{classic};
	my $self = $class->SUPER::new( %arg );
	$self->{ATTR}{classic} =  defined $classic ? $classic : $CLASSIC;
	return $self;
}

sub classic
{
	my ( $self ) = @_;
	return $self->{ATTR}{classic};
}

sub start
{
#	my ($self, $tag, $attr, $attrseq, $origtext) = @_;
	my ($self, $tag, $attr, undef, $origtext) = @_;

	$tag = lc($tag);

# Store the incoming details in the current 'object'.
	if ($tag eq 'table') {
		my $table = $attr;
		push @{ $self->{STORE}{stack} }, {
			map { $_ => $self->{STORE}{$_} } @stacked };
		push @{$self->{STORE}->{tables}}, $table;
		$self->{STORE}->{current_table} = $table;
		$self->{STORE}->{current_row} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'th') {
		my $th = $attr;
		push @{$self->{STORE}->{current_table}->{headers}}, $th;
		unless ( $self->{ATTR}{classic} ) {
			push @{$self->{STORE}->{current_row}->{cells}}, undef;
			push @{$self->{STORE}->{current_row}->{headers}}, $th;
		}
		$self->{STORE}->{current_element} = $th;

	} elsif ($tag eq 'tr') {
		my $tr = $attr;
		push @{$self->{STORE}->{current_table}->{rows}}, $tr;
		$self->{STORE}->{current_row} = $tr;
		$self->{STORE}->{current_element} = $tr;

	} elsif ($tag eq 'td') {
		my $td = $attr;
		push @{$self->{STORE}->{current_row}->{cells}}, $td;
		unless ( $self->{ATTR}{classic} ) {
			push @{$self->{STORE}->{current_row}->{headers}}, undef;
		}
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
			$self->_debug('TEXT(tag) = ', $origtext) if $DEBUG;
			$elem->{data} .= $origtext;
		}

	}

	$self->_debug($origtext) if $DEBUG;

	return;
}



sub text
{
	my ($self, $text) = @_;
	my $elem = $self->{STORE}->{current_element};
	if (!$elem) {
		return;
	}

	$self->_debug('TEXT = ', $text) if $DEBUG;
	$elem->{data} .= $text;

	return;
}



sub end
{
	my ($self, $tag, $origtext) = @_;
	$tag = lc($tag);

# Turn off the current object
	if ($tag eq 'table') {
		my $prev = pop @{ $self->{STORE}{stack} } || [];
		$self->{STORE}{$_} = $prev->{$_} for @stacked;

	} elsif ($tag eq 'th') {
		$self->{STORE}->{current_element} = undef;
	} elsif ($tag eq 'tr') {
		for my $key ( 'cells', $self->{ATTR}{classic} ? () : 'headers' ) {
			my $data = $self->{STORE}{current_row}{$key} || [];
			pop @{ $data } while @{ $data } && !  $data->[-1];
			delete $self->{STORE}{current_row}{$key}
				unless @{ $data };
		}
		$self->{STORE}->{current_row} = undef;
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'td') {
		$self->{STORE}->{current_element} = undef;

	} elsif ($tag eq 'caption') {
		$self->{STORE}->{current_element} = undef;

	} else {
## Found a non-table related close tag. Push it into the currently-defined
## td or th (if one exists).
		my $elem = $self->{STORE}->{current_element};
		if ($elem) {
			$self->_debug('TEXT(tag) = ', $origtext) if $DEBUG;
			$elem->{data} .= $origtext;
		}

	}

	$self->_debug($origtext) if $DEBUG;

	return;
}


sub parse
{
	my ($self, $data) = @_;

	unless ( defined $data ) {	# RT 7262
	    require Carp;
	    Carp::croak( 'Argument must be defined' );
	}

	$self->{STORE} = {
	    stack	=> [],
	};

	$self->SUPER::parse($data);

	my $tables = $self->{STORE}{tables};
	delete $self->{STORE};

	return $tables;
}




sub _debug
{
	my ( $self, @args ) = @_;
	my $class = ref($self);
	warn "$class: ", join( '', @args ), "\n";
	return;
}


1;


__END__

=head1 NAME

HTML::TableContentParser - Do interesting things with the contents of tables.

=head1 SYNOPSIS

  use HTML::TableContentParser;
  my $p = HTML::TableContentParser->new();
  my $html = read_html_from_somewhere();
  my $tables = $p->parse( $html );
  for my $t (@$tables) {
    for my $r (@{$t->{rows}}) {
      print 'Row:';
      for my $c (@{$r->{cells}}) {
        print " [$c->{data}]";
      }
      print "\n";
    }
  }

=head1 DESCRIPTION

This package parses tables out of HTML. The return from the parse is a
reference to an array containing the tables found.

Tables appear in the output in the order in which they are encountered.
If a table is nested inside a cell of another table, it will appear
after the containing table in the output, and any connection between the
two will be lost. As of version 0.200_01, the appearance of a nested
table should not cause any truncation of the containing table.

The following tags are processed by this module: C<< <table> >>,
C<< <caption> >>, C<< <tr> >>, C<< <th> >>, and C<< <td> >>. In the
return from the parse method, each tag is represented by a hash
reference, having the tag's attributes as keys, and the attribute values
as values. In addition, the following keys will be provided:

=over

=item C<< <table> >>

=over

=item caption

the C<< <caption> >> tag, if any

=item headers

a reference to an array containing all the C<< <th> >> tags, in the
order encountered

=item rows

a reference to an array containing all the C<< <tr> >> tags, in the
order encountered

=back

=item C<< <caption> >>

=over

=item data

the content of the C<< <caption> >> tag

=back

=item C<< <tr> >>

=over

=item cells

a reference to an array containing all the C<< <td> >> tags, in the
order encountered, with C<undef> representing any C<< <th> >> tags
encountered. Trailing C<undef> values will be dropped, and the entire
key will be absent unless actual C<< <td> >> tags are found in the row.

Note that prior to version 0.299_01, C<< <th> >> tags were not
represented at all.

=item headers

new with version 0.299_01, this is a reference to an array containing all the
C<< <th> >> tags in the row, in the order encountered, with C<undef>
representing any C<< <td> >> tags. Trailing C<undef> values will be
dropped, and the entire key will be absent unless actual C<< <th> >>
tags are found in the row.

It is the understanding of the current author (TRW) that in valid HTML
C<< <th> >> tags must occur inside a C<< <tr> >> element, so they need
to be recognized there, rather than (or in addition to) in isolation.

=back

=item C<< <th> >>

=over

=item data

the content of the C<< <th> >> tag

=back

=item C<< <td> >>

=over

=item data

the content of the C<< <td> >> tag

=back

=back

=head1 METHODS

This module is a subclass of L<HTML::Parser|HTML::Parser>. It provides
only one new method, L<classic()|/classic>, which is an accessor for the
attribute of the same name.  The following inherited (or overridden)
methods may profitably be called by the user.

=head2 new

 my $p = HTML::TableContentParser->new();

This static method instantiates the parser object. The only supported
argument is

=over

=item classic

If this argument is set to C<1>, C<< <th> >> tags are handled in the
pre-0.299_01 way. That is, the C<< <tr> >> hash will not
contain a C<{headers}> key, and its C<{cells}> key will not contain any
C<undef> values corresponding to C<< <th> >> elements.

If this argument is set to C<0>, you get the behavior documented for
0.299_01 and after.

If this argument is C<undef> or omitted, the value of
L<$HTML::TableContentParser::CLASSIC|/$HTML::TableContentParser::CLASSIC>
is used.

No other values are supported -- that is, the author reserves them, and
the behavior when you use them may change without warning.

=back

=head2 classic

This method returns the value of the C<classic> attribute, whether
specified or defaulted.

=head2 parse

 my $tables = $p->parse( $html );

This method parses the given HTML. The return is a reference to an array
containing all the tables found.

=head1 GLOBALS

The following global variables, B<properly localized,> can be used to
modify the behavior of this module.

=head2 $HTML::TableContentParser::CLASSIC

This variable provides the default value of the C<classic> argument to
L<new()|/new>, and is subject to the same restrictions.

=head2 $HTML::TableContentParser::DEBUG

If set to C<1>, causes debug output to F<STDERR> (via C<warn()>).
Setting this to any true value (including C<1>) is unsupported in the
sense that the behavior of this module in response to any true value is
explicitly undocumented, and can change without notice.

=head1 EXPORTS

Nothing.

=head1 CAVEATS, BUGS, and TODO

The C<rowspan> and C<colspan> attributes are reported but ignored. That
is,

 <tr><td colspan="2">Moe</td><td>Howard</td></tr>

occupies three columns in the HTML table, but only two entries are made
in the C<{cells}> value of the hash that represents this row.

Please file bug reports at
L<https://github.com/trwyant/perl-HTML-TableContentParser/issues>, or in
electronic mail to F<wyant at cpan dot org>.

=head1 SEE ALSO

This module is a very specific tool to address a very specific problem.
One of the following modules may better address your needs.

L<HTML::Parser|HTML::Parser>. This is a general HTML parser, which forms
the basis for this module.

L<HTML::TreeBuilder|HTML::TreeBuilder>. This is a general HTML parser,
with methods to search and traverse the parse tree once generated.

L<Mojo::DOM|Mojo::DOM> in the F<Mojolicious> distribution. This is a
general HTML/XML DOM parser, with methods to search the parse tree using
CSS selectors.

=head1 AUTHOR

Simon Drabble  E<lt>sdrabble@cpan.orgE<gt>

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002 Simon Drabble

Copyright (C) 2017-2021 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
