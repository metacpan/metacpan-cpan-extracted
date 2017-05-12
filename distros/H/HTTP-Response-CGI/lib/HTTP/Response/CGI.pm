package HTTP::Response::CGI;
use base 'HTTP::Response';

$VERSION = "1.0";

use warnings;
use strict;



sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self;
}


sub parse
{
    my($class, $str) = @_;
	# borrowed from HTML::Response
	my $status_line;
	if ($str =~ m/^(.*)\n/) {
		$status_line = $1;
	}
	else {
		$status_line = $str;
	}

    my $self = $class->SUPER::parse($str);

	if (!$self->protocol || $self->protocol =~ /^HTTP\/[\d\.]+/) {
		# Everything was already set correctly by SUPER::parse().
		# This may not be CGI output.
	} else {
		# Parsed the $status_line "incorrectly".
		
		# If there was a header on the first line, it will get snarfed into
		# protocol()/code().
		# Re-parse that header out here.
		my ($header, $value) = $status_line =~ /^([^:]+):\s*(.+)$/;
		if ($header && $value) {
			# remove carriage return, if it exists.
			$value =~ s/\r$// if $value;
			$self->header($header => $value);
		}

		# if headers contain a Status: line, modify that into an HTTP header.
		if ($self->header('Status')) {
			# case: the CGI has set an explict Status:
			my ($code, $message) = split(' ', $self->header('Status'), 2);
			$self->protocol(undef);
			$self->code($code) if defined($code);
			$self->message($message) if defined($message);
		} else {
			# case: the CGI has not set an explict Status:
			# Assume "200 OK".
			$self->protocol(undef);
			$self->code('200');
			$self->message('OK');
		}
	}

    $self;
}


1;


__END__

=head1 NAME

HTTP::Response::CGI - HTTP style response message, from CGI output

=head1 SYNOPSIS

Use this sub-class of HTTP::Response to parse CGI output.

	# ...
	my $output = $cgiapp->run();
	$response = HTTP::Response::CGI->parse($output)
	# Use $response as a normal HTTP::Response object.
	# ...
	if ($response->is_success) {
		print $response->decoded_content;
	} else {
		print STDERR $response->status_line, "\n";
	}

=head1 DESCRIPTION

The C<HTTP::Response::CGI> class sub-classes C<HTTP::Response> from libwwwperl. 

The main distinction is that this module's parse() accepts CGI output. CGI programs do not print the first line ("status line") of the HTTP protocol (eg. "HTTP/1.1 200 OK"). Instead, they communicate a special "Status:" header to the web server, and the web server translates this into the HTTP status line.

This module's parse() function provides that translation.

=head1 SEE ALSO

L<HTTP::Response>

C<RFC 3875>(L<http://www.ietf.org/rfc/rfc3875.txt>)

=head1 AUTHOR

Ken Dreyer, E<lt>ktdreyer[at]ktdreyer.comE<gt>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

