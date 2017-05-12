=head1 NAME

Konstrukt::Handler::Apache - Handler for an Apache request

=head1 SYNOPSIS

Handle an apache request

	Konstrukt::Handler::Apache::handler($request);

Plugins and other module may access the apache request like this:

	#the apache request object. shouldn't be used for compatibility reasons.
	$Konstrukt::Handler::APACHE_REQUEST
	
=head1 DESCRIPTION

Parses the requested file against special (e.g. <&...&>) tags.

=head1 CONFIGURATION

You need to tell Apache to apply the PerlHandler on the requested files.

Take a look at L<Konstrukt::Doc::Installation/Apache configuration> for more information about
the Apache configuration.

=cut

package Konstrukt::Handler::Apache;

use strict;
use warnings;

use Time::HiRes 'time';

#which mod_perl are we using? will be 0, 1 or 2
use constant MODPERL => $ENV{MOD_PERL} ? ( ( exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 ) ? 2 : 1 ) : 0;

#load appropriate modules for mod_perl 1 or mod_perl 2
BEGIN {
	#handler specific modules
	if (MODPERL == 1) {
		require Apache::Constants;
		Apache::Constants->import(qw(:common));
#		use Apache::Table ();
	} elsif (MODPERL == 2) {
		require Apache2::RequestRec; # for $r->content_type, $r->uri, $r->method, $r->headers_in
		require Apache2::RequestIO;  # for $r->print
		require Apache2::RequestUtil;# for $r->document_root, $r->no_cache
		require Apache2::Const;
		Apache2::Const->import(qw(:common));
	} else {
		die "Konstrukt::Handler::Apache can only be used with mod_perl!";
	}
}

use Konstrukt::Request;
use Konstrukt::Response;
use Konstrukt::Debug;

#inheritance
use base 'Konstrukt::Handler';

=head1 FUNCTIONS

=head2 handler

Handles the request.

Filter a file before returning it to the web client.

B<Parameters>:

=over

=item * $request - The Apache request

=back

=cut
sub handler {
	my ($request) = @_;

	#request overhead benchmarking
	my ($starttime, $duration_request) = (time(), 0);
	
	#set global request object (needed for CGI.pm)
	Apache2::RequestUtil->request($request) if MODPERL == 2;
	
	#apache specific initialization
	$Konstrukt::Handler::APACHE_REQUEST = $request;
	$Konstrukt::Handler->{ENV} = $request->subprocess_env(); #environment
	
	#load environment
	#TODO: needed?
	$request->subprocess_env if MODPERL == 2;
	
	#create myself
	my $self = Konstrukt::Handler::Apache->new(
		$request->document_root(),
		#the apache request returns an absolute filename, but we need the path
		#relatively to the doc root. so we cut off the leading doc root without the trailing slash.
		substr(
			$request->filename(),
			length($request->document_root()) - (substr($request->document_root(), -1, 1) eq '/' ?  1 : 0))
	);
	#the apache request returns the absolute path to the requested file,
	$Konstrukt::Handler->{abs_filename} = $request->filename();
	$Konstrukt::Handler->{filename}     = $Konstrukt::File->relative_path($Konstrukt::Handler->{abs_filename});
	
	#create and initialize request and response objects
	#$request->headers_in():
	#-mod_perl1: List (key => value)
	#-mod_perl2: Tied hash
	$Konstrukt::Request  = Konstrukt::Request->new(uri => $request->uri(), method => $request->method(), headers => MODPERL == 1 ? { ($request->headers_in()) } : { %{$request->headers_in()} });
	#default response
	$Konstrukt::Response = Konstrukt::Response->new(status => '200', headers => { 'Content-Type' => 'text/html' });
	
	#check for file existance
	unless (-e $Konstrukt::Handler->{abs_filename}) {
		$Konstrukt::Debug->debug_message("File '$Konstrukt::Handler->{abs_filename}' not found!");
		return NOT_FOUND;
	}
	
	#stop request overhead time
	$duration_request = time() - $starttime;
	$Konstrukt::Debug->debug_message(sprintf("$Konstrukt::Handler->{filename} request overhead: %.6f seconds.", $duration_request)) if Konstrukt::Debug::INFO;
	
	#generate result
	my $result = $self->process();
	#add debug- and error messages, if any
	if ($Konstrukt::Response->header('Content-Type') eq 'text/html') {
		$result .= "<!--\n" . $Konstrukt::Debug->format_error_messages() . "\n-->\n" if $Konstrukt::Settings->get('handler/show_error_messages');
		$result .= "<!--\n" . $Konstrukt::Debug->format_debug_messages() . "\n-->\n" if $Konstrukt::Settings->get('handler/show_debug_messages');
	}
	#determine content length
	$Konstrukt::Response->header('Content-Length' => length($result));
	
	#set cookies
	foreach my $cookie (keys %{$Konstrukt::Handler->{cookies}}) {
		$request->headers_out->add('Set-Cookie', $Konstrukt::Handler->{cookies}->{$cookie}->as_string());
	}
	
	#set custom headers
	my $headers = $Konstrukt::Response->headers();
	foreach my $field (keys %{$headers}) {
		if (MODPERL == 1) { #weird...
			$request->header_out($field => $headers->{$field});
		} else {
			$request->headers_out->add($field => $headers->{$field});
		}
		#special case for content-type and content-encoding, which have to be defined explicitly
		if ($field eq 'Content-Type') {
			$request->content_type($headers->{$field});
		} elsif ($field eq 'Content-Encoding') {
			$request->content_encoding($headers->{$field});
		}
	}
	
	#set status code
	$request->status($Konstrukt::Response->status());
	#don't cache my dynamic documents!
	$request->no_cache(1);
	#send header. mod_perl 2 does this automatically
	$request->send_http_header() if MODPERL == 1;
	
	#send content
	$request->print($result);
	
	#force session to write its data
	$Konstrukt::Session->release()
		if $Konstrukt::Settings->get('session/use');
	
	#clean up
	#$self->{dbi}->disconnect();
	
	#get status
	my $status = $request->status();
	#must return 0 for status code 200. don't ask me why...
	return $status == 200 ? OK : $status;
}

sub emergency_exit {
	my $self = (@_);
	
	my $request = $Konstrukt::Handler::APACHE_REQUEST;
	
	$request->content_type('text/plain');
	$request->no_cache(1);
	if ($Konstrukt::Settings->get('handler/show_error_messages') or $Konstrukt::Settings->get('handler/show_debug_messages')) {
		#print out debug- and error messages
		$request->status(200);
		$request->send_http_header() if MODPERL == 1;
		
		$request->print("A critical error occurred while processing this request.\nThe request has been aborted.\n\n");
		$request->print($Konstrukt::Debug->format_error_messages()) if $Konstrukt::Settings->get('handler/show_error_messages');
		$request->print($Konstrukt::Debug->format_debug_messages()) if $Konstrukt::Settings->get('handler/show_debug_messages');
	} else {
		$request->status(500);
	}
	
	warn "A critical error occurred while processing this request. The request has been aborted";
	exit;
}

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Handler>, L<Konstrukt>

=cut
