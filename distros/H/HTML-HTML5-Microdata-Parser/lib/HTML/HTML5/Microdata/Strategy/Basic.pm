package HTML::HTML5::Microdata::Strategy::Basic;

use 5.010;
use strict;
use utf8;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use URI::Escape qw[uri_escape];

sub new
{
	my ($class=>%params) = @_;
	bless \%params, $class;
}

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
	
	return;
}

sub is_uri
{
	my ($self=>$uri) = @_;
	return ($uri =~ /:/);
}

sub postprocess_uri
{
	my ($self=>$uri, $params) = @_;
	return $uri;
}

sub generate_uri
{
	my ($self=>%params) = @_;
	my $uri = $self->make_uri(%params);
	return undef unless defined $uri;
	return $self->postprocess_uri($uri, \%params);
}

1;