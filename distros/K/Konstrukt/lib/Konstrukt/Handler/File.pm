=head1 NAME

Konstrukt::Handler::File - Handler for the processing of a given filename

=head1 SYNOPSIS

	my $filehandler = Konstrukt::Handler::File->new($root, $filename);
	$filehandler->handler();

=head1 DESCRIPTION

Parses a given file against special (e.g. <&...&>) tags and prints out the result.

=cut

package Konstrukt::Handler::File;

use strict;
use warnings;

use Time::HiRes 'time';

use Konstrukt::Request;
use Konstrukt::Response;
use Konstrukt::Debug;
use base 'Konstrukt::Handler';

=head1 METHODS

=head2 new

Constructor of this class. Will so some necessary initialization and call the
constructor of the super class.

B<Parameters>:

=over

=item * $root - The B<absolute> path of the document root

=item * $filename - The file to process (B<relative> to the document root)

=back

=cut
sub new {
	my ($class, $root, $filename) = @_;
	
	#read "fake" cookies
	my $cookie_filename = $root . ($root =~ /[\\\/]$/ ? '' : '/') . "cookies.txt";
	$ENV{HTTP_COOKIE} = $Konstrukt::File->raw_read($cookie_filename)
		if -e $cookie_filename;
	
	#set fake ip address
	$ENV{REMOTE_ADDR} = '1.2.3.4';
	
	#create object
	return $class->SUPER::new($root, $filename);
}
#/new

=head2 handler

Handles the file and prints out the result

=cut
sub handler {
	my ($self) = @_;
	
	#dummy request/response
	$Konstrukt::Request  = Konstrukt::Request->new(uri => $self->{filename}, method => 'GET', headers => {});
	$Konstrukt::Response = Konstrukt::Response->new(status => 200, headers => { 'Content-Type' => 'text/html' });
	
	#print result
	my $result = $self->process();
	print "\n=== result: =======>\n" if Konstrukt::Debug::DEBUG;
	print "$result";
	
	#force session to write its data
	$Konstrukt::Session->release()
		if $Konstrukt::Settings->get('session/use');

	#write "fake" cookies
	my $cookies = join "; ", map { "$_=" . $Konstrukt::Handler->{cookies}->{$_}->value() } keys %{$Konstrukt::Handler->{cookies}};
	$Konstrukt::File->write('/cookies.txt', $cookies) if $cookies;
	
	#print out debug- and error messages
	print $Konstrukt::Debug->format_error_messages() if $Konstrukt::Settings->get('handler/show_error_messages');
	print $Konstrukt::Debug->format_debug_messages() if $Konstrukt::Settings->get('handler/show_debug_messages');
}
#= /handler

=head2 emergency_exit

Will be called on a critical error. Put out the error messages.

=cut
sub emergency_exit {
	my ($self) = @_;
	
	if ($Konstrukt::Settings->get('handler/show_error_messages') or $Konstrukt::Settings->get('handler/show_debug_messages')) {
		#print out debug- and error messages
		print "A critical error occurred while processing this request.\nThe request has been aborted.\n\n";
		print $Konstrukt::Debug->format_error_messages();
		print $Konstrukt::Debug->format_debug_messages();
	}
	
	exit;
}
#= /emergency_exit

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Handler>, L<Konstrukt>

=cut
