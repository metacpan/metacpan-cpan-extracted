package HTML::Parser::Simple::Attributes;

use strict;
use warnings;

use Moo;

has a_hashref =>
(
	default => sub{return {} },
	is      => 'rw',
);

has a_string =>
(
	default => sub{return ''},
	is      => 'rw',
);

has parsed =>
(
	default => sub{return 0},
	is      => 'rw',
);

our $VERSION = '2.02';

# -----------------------------------------------

sub get
{
	my($self, $key) = @_;

	$self -> parse if ($self -> parsed == 0);

	my($attrs) = $self -> a_hashref;

	return $key ? $$attrs{$key} : $$attrs;

} # End of get.

# -----------------------------------------------

sub hashref2string
{
	my($self, $h) = @_;
	$h ||= {};

	return '{' . join(', ', map{"$_ => $$h{$_}"} sort keys %$h) . '}';

} # End of hashref2string.

# -----------------------------------------------

our(@quote) =
(
 qr{^([a-zA-Z0-9_-]+)\s*=\s*["]([^"]+)["]\s*(.*)$}so, # Double quotes.
 qr{^([a-zA-Z0-9_-]+)\s*=\s*[']([^']+)[']\s*(.*)$}so, # Single quotes.
 qr{^([a-zA-Z0-9_-]+)\s*=\s*([^\s'"]+)\s*(.*)$}so,    # Unquoted.
);

sub parse
{
	my($self, $string) = @_;
	$string    ||= $self -> a_string;
	$string    =~ s/^\s+|\s+$//g;
	my($attrs) = {};

	$self -> a_string($string);

	while (length $string)
	{
		my($i)        = - 1;
		my($original) = $string;

		while ($i < $#quote)
		{
			$i++;

			if ($string =~ $quote[$i])
			{
				$$attrs{$1} = $2;
				$string     = $3;
				$i          = - 1;
			}
		}

		die "Can't parse $string - not a properly formed attribute string\n" if ($string eq $original);
	}

	$self -> a_hashref($attrs);
	$self -> parsed(1);

	return $attrs;

} # End of parse.

# -----------------------------------------------

sub string2hashref
{
	my($self, $s) = @_;
	$s            ||= '';
	my($result)   = {};

	if ($s)
	{
		if ($s =~ m/^\{\s*([^}]*)\}$/)
		{
			my(@attr) = map{s/([\"\'])(.*)\1/$2/; $_} map{split(/\s*=>\s*/)} split(/\s*,\s*/, $1);
			$result   = {@attr} if (@attr);
		}
		else
		{
			die "Invalid syntax for hashref: $s";
		}
	}

	return $result;

} # End of string2hashref.

# -----------------------------------------------

1;

=head1 NAME

C<HTML::Parser::Simple::Attributes> - A simple HTML attribute parser

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use HTML::Parser::Simple::Attributes;

	# -------------------------

	# Method 1:

	my($parser) = HTML::Parser::Simple::Attributes -> new(' height="20" width=20 ');

	# Get all the attributes as a hashref.
	# This triggers a call to parse(), if necessary.

	my($attr_href) = $parser -> get;

	# Get the value of a specific attribute.
	# This triggers a call to parse(), if necessary.

	my($height) = $parser -> get('height');

	# Method 2:

	my($parser) = HTML::Parser::Simple::Attributes -> new;

	$parser -> parse(' height="20" width=20 ');

	# Get all attributes, or 1, as above.

	my($attr_href) = $parser -> get;
	my($height)    = $parser -> get('height');

	# Get the attribute string passed to new() or to parse().

	my($a_string) = $parser -> a_string;

	# Get the parsed attributes as a hashref, if parse() has been called.
	# If parse() has not been called, this returns {}.

	my($a_hashref) = $parser -> a_hashref;


=head1 Description

C<HTML::Parser::Simple::Attributes> is a pure Perl module.

It parses HTML V 4 attribute strings, and turns them into a hashrefs.

Also, convenience methods L</hashref2string($hashref)> and L</string2hash($string)> are provided,
which deal with Perl hashrefs formatted as strings.

See also L<HTML::Parser::Simple> and L<HTML::Parser::Simple::Reporter>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<HTML::Parser::Simple::Attributes>.

This is the class contructor.

Usage: C<< HTML::Parser::Simple::Attributes -> new >>.

This method takes a hash of options.

Call C<< new() >> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (each one of which is also a method):

=over 4

=item o a_string => $a_HTML_attribute_string

This takes a string as formatted for HTML attribites.

E.g.: ' height="20" width=20 '.

Default: '' (the empty string).

=back

=head1 Methods

=head2 a_hashref()

Returns a hashref of parsed attributes, if C<< parse() >> has been called.

Returns {} if C<< parse() >> has not been called.

=head2 a_string()

Returns the attribute string passed to C<< new() >>, or to L<parse($attr_string)>.

Returns '' (the empty string) if C<< parse() >> has not been called.

'a_string' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 get([$name])

Here, the [] indicate an optional parameter.

	my($hashref) = $parser -> get;
	my($value)   = $parser -> get('attr_name');

If you do not pass in an attribute name, this returns a hashref with the attribute names as keys
and the attribute values as the values.

If you pass in an attribute name, it will return the value for just that attribute.

Returns undef if you supply the name of a non-existant attribute.

=head2 hashref2string($hashref)

Returns a string suitable for printing.

Warning: The hashref is formatted as we would normally do in Perl, i.e. with commas and fat commas.

	{height => 20, width => 20} is returned as 'height => 20, width => 20'

This is not how HTML attributes are written.

The output string can be parsed by L</string2hashref($string)>.

This is a convenience method.

=head2 new()

This is the constructor. See L</Constructor and initialization> for details.

=head2 parse($attr_string)

	$attr_href = $parser -> parse($attr_string);

Or

	$parser    = HTML::Parser::Simple::Attributes -> new(a_string => $attr_string);
	$attr_href = $parser -> parse;

Parses a string of HTML attributes and returns the result as a hashref, or
dies if the string is not a valid attribute string.

Attribute values may be quoted with double quotes or single quotes.
Quotes may be omitted if there are no spaces in the value.

Returns an empty hashref if $attr_string was not supplied to C<< new() >>, nor to C<< parse() >>.

=head2 string2hashref($string)

Returns a hashref by (simplistically) parsing the string.

	'height => 20, width => 20' is returned as {height => 20, width => 20}

Warning: This string must have been output by L</hashref2string($hashref)>, because it deals with a
string of hashrefs as we normally think of them in Perl, i.e. with commas and fat commas.

This is not how HTML deals with a string of attributes.

This is a convenience method.

=head1 Author

C<HTML::Parser::Simple::Attributes> was written by Mark Stosberg I<E<lt>mark@summersault.comE<gt>> in 2009.

The code has be re-worked by Ron Savage.

Home page: L<http://mark.stosberg.com/>.

=head1 Copyright

Copyright (c) 2009 Mark Stosberg.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
