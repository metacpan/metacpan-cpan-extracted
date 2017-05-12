package HTML::HTML5::Microdata::Strategy::Microdata0;

use 5.010;
use strict;
use utf8;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use URI::Escape qw[uri_escape];

use base qw[HTML::HTML5::Microdata::Strategy::Basic];

sub make_uri
{
	my ($self=>%params) = @_;
	
	if ($self->is_uri($params{name}))
	{
		return $params{name};
	}
	elsif (not length ($params{type}//''))
	{
		return undef unless $params{prefix_empty};
		return $params{prefix_empty}.uri_escape($params{name});
	}
	
	# Let predicate have the same value as [item type].
	my $predicate = $params{type};
	
	# If predicate does not contain a U+0023 NUMBER SIGN character (#),
	# then append a U+0023 NUMBER SIGN character (#) to predicate.
	$predicate .= '#' unless $predicate =~ /#/;
	
	# Append a U+003A COLON character (:) to predicate.
	$predicate .= ':';
	
	# Append the value of name to predicate, with any characters in name
	# that are not valid in the <ifragment> production of the IRI syntax
	# being %-escaped.
	# Generate the following triple:
	# predicate : the concatenation of the string
	# "http://www.w3.org/1999/xhtml/microdata#" and predicate, with any
	# characters in predicate that are not valid in the <ifragment>
	# production of the IRI syntax being %-escaped [RFC3987] 
	# TOBY-QUERY: should $name really get escaped twice??
	$predicate = 'http://www.w3.org/1999/xhtml/microdata#'
		. uri_escape($predicate . uri_escape($params{name}));

	return $predicate;
}

1;