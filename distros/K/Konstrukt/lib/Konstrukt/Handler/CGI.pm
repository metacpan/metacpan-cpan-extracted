#TODO: test this!
#TODO: config doc

=head1 NAME

Konstrukt::Handler::CGI - Handler for the processing of a given filename

=head1 SYNOPSIS
	
	my $root = $ENV{'DOCUMENT_ROOT'};
	my $cgihandler = Konstrukt::Handler::CGI->new($root, $filename);
	$cgihandler->handler();

=head1 DESCRIPTION

Parses a given file against special (e.g. <&...&>) tags and prints out the result.

=head1 CONFIGURATION

#TODO: config doc

=cut

package Konstrukt::Handler::CGI;

use strict;
use warnings;

use Konstrukt::Request;
use Konstrukt::Response;

use Konstrukt::Debug;

use base 'Konstrukt::Handler';

=head1 METHODS

=head2 handler

Handles the file and prints out the result

=cut
sub handler {
	my ($self) = @_;
	
	#check for file existance
	if (!-e $Konstrukt::Handler->{abs_filename}) {
		print $Konstrukt::CGI->header('text/html', -expires =>'now', -Cache_control => 'no-cache', -Pragma => 'no-cache', -cookie => $Konstrukt::Handler->{cookies}, -status => '404 Not found');
		print "404 - File \"$Konstrukt::Handler->{abs_filename}\" not found";
		return;
	}
	
	#create and initialize request and response objects
	$Konstrukt::Request = Konstrukt::Request->new(
		uri => $Konstrukt::Handler->{ENV}->{REQUEST_URI},
		method => $Konstrukt::Handler->{ENV}->{REQUEST_METHOD},
		headers => {
			(map {
				if ($_ =~ /^HTTP_(.*)$/) {
					($1 => $Konstrukt::Handler->{ENV}->{$_})
				} else { () }
			} keys %{$Konstrukt::Handler->{ENV}})
		}
	);
	#default response
	$Konstrukt::Response = Konstrukt::Response->new(status => '200', headers => { 'Content-Type' => 'text/html' });
	
	#generate result
	my $result = $self->process();
	#add debug- and error messages, if any
	if ($Konstrukt::Response->header('Content-Type') eq 'text/html') {
		$result .= "<!--\n" . $Konstrukt::Debug->format_error_messages() . "\n-->\n" if $Konstrukt::Settings->get('handler/show_error_messages');
		$result .= "<!--\n" . $Konstrukt::Debug->format_debug_messages() . "\n-->\n" if $Konstrukt::Settings->get('handler/show_debug_messages');
	}
	#determine content length
	$Konstrukt::Response->header('Content-Length' => length($result));
	
	#print result
	#HTTP header: text/html, cookies, no caching of this page!
	my $headers = $Konstrukt::Response->headers();
	print $Konstrukt::CGI->header(
		-Expires       =>'now',
		-Cache_control => 'no-cache',
		-Pragma        => 'no-cache',
		-Cookie        => $Konstrukt::Handler->{cookies},
		(map { ("-$_" => $headers->{$_}) } keys %{$headers})
		);
	print $result;
	
	#clean up
	#force session to write its data
	$Konstrukt::Session->release()
		if $Konstrukt::Settings->get('session/use');
	#$self->{plugins}->destroy();
	#$self->{dbi}->disconnect();
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
	
	warn "A critical error occurred while processing this request. The request has been aborted";
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
