package HTML::HTML5::Microdata::Strategy::Heuristic;

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
	
	my ($pfx, $char, $sfx) = $self->_split_on_last($params{type}, '#/');
	
	if ($char eq '#')
	{
		return $pfx . $char . $params{name};
	}

	if ($char eq '/' and $sfx =~ m/^\P{IsUpper}/)
	{
		return $params{type} . '#' . $params{name};
	}
	
	while ('we have nothing better to do')
	{
		if ($self->_is_minimal($pfx))
		{
			last;
		}
		if ($sfx =~ m/^(\P{IsUpper})/)
		{
			$pfx .= $char . $sfx;
			last;
		}
		if ($char ne '/')
		{
			last;
		}
		
		($pfx, $char, $sfx) = $self->_split_on_last($pfx, '/');
	}
	
	return $pfx . '/' . $params{name};
}

sub _is_minimal
{
	my ($self=>$uri) = @_;
	
	if ($uri =~ m/^https?:/i)
	{
		return ($uri =~ m#https?://[^/?]+$#i);
	}

	if ($uri =~ m/^s?ftps?:/i)
	{
		return ($uri =~ m#s?ftps?://[^/]+$#i);
	}

	return 'unknown URI scheme'; # true
}

sub _split_on_last
{
	my ($self=>$string,$chars) = @_;
	
	if ($string =~ m/^ (.*) ([$chars]) ([^$chars]*) $/x)
	{
		return ($1, $2, $3);
	}
	else
	{
		return ($string, undef, undef);
	}
}

1;