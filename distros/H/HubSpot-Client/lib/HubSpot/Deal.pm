package HubSpot::Deal;
our $VERSION = "0.1";
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use strict;

# Classes we need
use Data::Dumper;

# Make us a class
use Class::Tiny qw(json),
{
		# Default variables in here
};
use parent 'HubSpot::JSONBackedObject';

sub name
{
	my $self = shift;
	
	return $self->json->{'properties'}->{'dealname'}->{'value'};
}

sub id
{
	my $self = shift;
	
	return $self->json->{'dealId'};
}

sub logMeeting()
{
	my $self = shift;
	my $content = shift;
	my $time = shift;
}
	
1;
