package Deplide::RFID::EPCISSubmitter;

use strict;
use warnings;
use v5.10;
use LWP::UserAgent;
use HTTP::Request::Common;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Deplide::RFID::EPCISSubmitter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';
our $DEFAULT_ENDPOINT_URL = 'https://arkady.deplide.org/rfidReading';

sub new {
	my $class = shift;
	my $user = shift;
	my $password = shift;
	my $endpointURL = shift || $Deplide::RFID::EPCISSubmitter::DEFAULT_ENDPOINT_URL;
	my $ua = LWP::UserAgent->new();
	$ua->agent("Deplide::RFID::EPCISSubmitter/$Deplide::RFID::EPCISSubmitter::VERSION");
	my $self = {
		_user => $user,
		_password => $password,
		_url => $endpointURL,
		_ua => $ua
	};

	bless $self, ref($class) || $class;
	return $self;
}

sub submit {
	my $self = shift;
	my $message = shift;

	my $request = HTTP::Request::Common::POST($self->{_url});
	$request->content($message);
	$request->header('content-type' => 'application/xml');
	$request->header('content-length' => length($message));
	$request->authorization_basic($self->{_user}, $self->{_password});
	 
	my $response = $self->{_ua}->request($request);
	return $response;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Deplide::RFID::EPCISSubmitter - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Deplide::RFID::EPCISSubmitter;
  blah blah blah

=head1 DESCRIPTION

Deplide::RFID::EPCISSubmitter lets you submit data to the EPCIS Train RFID streams 
in Deplide 


=head1 AUTHOR

Eddie Olsson, E<lt>eddie.olsson@ri.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Eddie Olsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
