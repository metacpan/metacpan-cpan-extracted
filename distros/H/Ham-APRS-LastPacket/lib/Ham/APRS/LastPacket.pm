package Ham::APRS::LastPacket;

# --------------------------------------------------------------------------
# Ham::APRS::LastPacket - A simple interface to retrieve the most recent
# packet data for a station from APRS-IS.
#
# Copyright (c) 2008-2010 Brad McConahay N8QQ.
# Cincinnat, Ohio USA
#
# This module is free software; you can redistribute it and/or
# modify it under the terms of the Artistic License 2.0. For
# details, see the full text of the license in the file LICENSE.
# 
# This program is distributed in the hope that it will be
# useful, but it is provided "as is" and without any express
# or implied warranties. For details, see the full text of
# the license in the file LICENSE.
# --------------------------------------------------------------------------

use strict;
use warnings;
use XML::Simple;
use LWP::UserAgent;
use vars qw($VERSION);

our $VERSION = '0.03';

my $aprs_url = "http://aprsearch.net/xml/1.3/report.cgi?call=";
my $site_name = 'aprsearch.net/xml';
my $default_timeout = 10;

sub new
{
	my $class = shift;
	my %args = @_;
	my $self = {};
	$self->{timeout} = $args{timeout} || $default_timeout;
	if ($args{suppress_empty}) {
		$self->{suppress_empty} = $args{suppress_empty};
	} elsif (defined $args{suppress_empty} and !$args{suppress_empty}) {
		$self->{suppress_empty} = '';
	} elsif (exists $args{suppress_empty} and ! defined $args{suppress_empty}) {
		$self->{suppress_empty} = undef;
	} else {
		$self->{suppress_empty} = '';
	}
	bless $self, $class;
	return $self;
}

sub set_callsign
{
	my $self = shift;
	my $callsign = shift;
	if (!$callsign) {
		$self->{is_error} = 1;
		$self->{error_message} = "No callsign was provided";
		return undef;
	}
	$callsign =~ tr/a-z/A-Z/;
	$self->{callsign} = $callsign;
}

sub get_callsign
{
	my $self = shift;
	return $self->{callsign};	
}

sub get_data
{
	my $self = shift;
	if (!$self->{callsign}) {
		$self->{is_error} = 1;
		$self->{error_message} = "Can not get data without a callsign";
		return undef;
	}	
	return _get_xml($self);
}

sub is_error { my $self = shift; $self->{is_error} }
sub error_message { my $self = shift; $self->{error_message} }

# -----------------------
#	PRIVATE
# -----------------------

sub _get_xml
{
	my $self = shift;
	my $ua = LWP::UserAgent->new( timeout=>$self->{timeout} );
	$ua->agent("Perl Ham-APRS-LastPacket.pm $VERSION");
	my $request = HTTP::Request->new('GET', $aprs_url.$self->{callsign});
	my $response = $ua->request($request);
	if (!$response->is_success) {
		$self->{is_error} = 1;
		$self->{error_message} = "Could not contact site: $site_name - ".HTTP::Status::status_message($response->code);
		return undef;
	}
	my $content = $response->content;
	chomp $content;
	$content =~ s/(\r|\n)//g;

	my $xs = XML::Simple->new(
		SuppressEmpty => $self->{suppress_empty}
	);
	my $data = $xs->XMLin($content);

	if (!$data->{position}) {
		$self->{is_error} = 1;
		$self->{error_message} = "$self->{callsign} was not found at $site_name\n";
		return undef;
	}
	return $data;
}

1;
__END__

=head1 NAME

Ham::APRS::LastPacket - A simple interface to retrieve the most recent packet data for a station from APRS-IS.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 use Ham::APRS::LastPacket;

 my $aprs = Ham::APRS::LastPacket->new; 
 $aprs->set_callsign('n8qq');
 my $packet = $aprs->get_data;

 die $aprs->error_message if $aprs->is_error;

 # show the entire structure of data
 use Data::Dumper;
 print Dumper($packet);

 # get a single item
 print $aprs->get_callsign;
 print " is at $packet->{position}->{longitude}->{degrees} degrees longitude.\n";


=head1 DESCRIPTION

The C<Ham::APRS::LastPacket> module retrieves the latest packet from APRS-IS for a given station's
callsign by referencing the aprsworld-to-XML interface. You provide the callsign for a station that
exists in APRSWorld, and you will get back a hashref of hashrefs containing all data available for
that station's latest packet.  Use C<Data::Dumper> to inspect the data to see all items that are
available (as shown in the synopsis).  The data set returned can differ based on what type of station
is being referenced.  For instance, a weather station will contain weather data that another type of
station won't.

=head1 CONSTRUCTOR

=head2 new()

 Usage    : my $aprs = Ham::APRS::LastPacket->new;
 Function : creates a new Ham::APRS::LastPacket object
 Returns  : a Ham::APRS::LastPacket object
 Args     : a hash:
            key             required?   value
            -------         ---------   -----
            timeout         no          an integer of seconds to wait for
                                        the timeout of the web site
                                        default = 10
            suppress_empty  no          set the handling for empty elements
                                        suppress_empty => 1 will exclude empty elements
                                        suppress_empty => '' will set them to an empty hash
                                        suppress_empty => undef will set the hashes to undef
                                        default is empty string

=head1 METHODS

=head2 set_callsign()

 Usage    : $aprs->set_callsign( $callsign );
 Function : set the callsign of the station whose data will be retrieved with get_data()
 Returns  : n/a
 Args     : a case-insensitive string containing the callsign of the station in APRS-IS.
            you can use CWOP callsigns and callsigns with SSIDs.

=head2 get_callsign()

 Usage    : $callsign = $aprs->get_callsign;
 Function : get the callsign that was set with the most recent call to set_callsign().
 Returns  : a string.  (the callsign will have been converted to upper case)
 Args     : n/a

=head2 get_data()

 Usage    : $data = $aprs->get_data;
 Function : get a hashref of hashrefs of the data contained in APRS-IS for the station set in set_callsign()
 Returns  : a hashref of hashrefs
 Args     : n/a

=head2 is_error()

 Usage    : if ( $aprs->is_error )
 Function : test for an error if one was returned from the call to the aprsworld-to-XML site
 Returns  : a true value if there has been an error
 Args     : n/a

=head2 error_message()

 Usage    : my $err_msg = $aprs->error_message;
 Function : if there was an error message when trying to call the site, this is it
 Returns  : a string (the error message)
 Args     : n/a

=head1 DEPENDENCIES

=over 4

=item * L<XML::Simple>

=item * L<LWP::UserAgent>

=item * An Internet connection

=back

=head1 TODO

=over 4

=item * Maybe provide a list of data items and the hashref hierarchy.

=item * Improve the module description.

=item * Improve error checking.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item

This module gets its data from the aprsworld-to-XML interface, by Brad McConahay N8QQ (me).  See http://aprsearch.net/xml

=item

The aprsworld-to-XML interface gets its data from APRSWorld, by Jim Jarvis KB0THN.  See http://aprsworld.net

=item

APRS-IS is the Internet-based network which inter-connects various APRS radio networks throughout the world (and space).  See http://aprs-is.net

=item

APRS was created by, and is a trademark of, Bob Bruninga WB4APR.  See http://aprs.org

=back

=head1 AUTHOR

Brad McConahay N8QQ, C<< <brad at n8qq.com> >>

=head1 COPYRIGHT AND LICENSE

C<Ham::APRS::LastPacket> is Copyright (C) 2008-2010 Brad McConahay N8QQ.

This module is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0. For
details, see the full text of the license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

