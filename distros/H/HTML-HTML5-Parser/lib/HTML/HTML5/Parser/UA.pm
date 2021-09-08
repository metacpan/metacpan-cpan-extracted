package HTML::HTML5::Parser::UA;

use 5.008001;
use strict;
use warnings;

BEGIN {
	$HTML::HTML5::Parser::UA::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Parser::UA::VERSION   = '0.992';
}

use Encode qw(decode);
use HTTP::Tiny;
use URI::file;

our $NO_LWP = '0';

sub get
{
	my ($class, $uri, $ua) = @_;

	if (ref $ua and $ua->isa('HTTP::Tiny') and $uri =~ /^https?:/i)
		{ goto \&_get_tiny }
	if (ref $ua and $ua->isa('LWP::UserAgent'))
		{ goto \&_get_lwp }
	if (UNIVERSAL::can('LWP::UserAgent', 'can') and not $NO_LWP)
		{ goto \&_get_lwp }
	if ($uri =~ /^file:/i)
		{ goto \&_get_fs }

	goto \&_get_tiny;
}

sub _get_lwp
{
	eval "require LWP::UserAgent; 1"
	or do {
		require Carp;
		Carp::croak("could not load LWP::UserAgent");
	};
	
	my ($class, $uri, $ua) = @_;

	$ua ||= LWP::UserAgent->new(
		agent => sprintf(
			"%s/%s ",
			'HTML::HTML5::Parser',
			HTML::HTML5::Parser->VERSION,
		),
		default_headers => HTTP::Headers->new(
			'Accept' => join q(, ) => qw(
				text/html
				application/xhtml+xml;q=0.9
				application/xml;q=0.1
				text/xml;q=0.1
			)
		),
		parse_head => 0,
	);
	
	my $response = $ua->get($uri);
	
	my $h = $response->headers;
	my %header_hash =
		map { lc($_) => $h->header($_); }
		$h->header_field_names;
	
	return +{
		success  => $response->is_success,
		status   => $response->code,
		reason   => $response->message,
		headers  => \%header_hash,
		content  => $response->content,
		decoded_content => $response->decoded_content,
	};
}

sub _get_tiny
{
	my ($class, $uri, $ua) = @_;
	
	$ua ||= HTTP::Tiny->new(
		agent => sprintf("%s/%s", 'HTML::HTML5::Parser', HTML::HTML5::Parser->VERSION),
		default_headers => +{
			'Accept' => join(q(, ) => qw(
				text/html
				application/xhtml+xml;q=0.9
				application/xml;q=0.1
				text/xml;q=0.1
			)),
		},
	);
	
	my $response = $ua->get($uri);
	
	if ($response->{headers}{'content-type'} =~ /charset=(\S+)/)
	{
		(my $encoding = $1) =~ s/["']//g;
		$response->{decoded_content} = eval {
			decode($encoding, $response->{content})
		};
	}
	
	$response->{decoded_content} = $response->{content}
		unless defined $response->{decoded_content};
	return $response;
}

sub _get_fs
{
	my $class = shift;
	my ($uri) = map { ref() ? $_ : URI->new($_) } @_;
	my $file  = $uri->file;

	my ($status, $reason, $content, $content_type) = do {
		if (not -e $file)
			{ (404 => 'Not Found', 'File not found.', 'text/plain') }
		elsif (not -r $file)
			{ (403 => 'Forbidden', 'File not readable by effective guid.', 'text/plain') }
		else
			{ (200 => 'OK') }
	};
	
	$content ||= do {
		if (open my $fh, '<', $file)
			{ local $/ = <$fh> }
		else
			{ $status = 418; $reason = "I'm a teapot"; $content_type = 'text/plain'; $! }
	};
	
	$content_type ||= 'text/xml' if $file =~ /\.xml$/i;
	$content_type ||= 'application/xhtml+xml' if $file =~ /\.xht(ml)?$/i;
	$content_type ||= 'text/html' if $file =~ /\.html?$/i;
	$content_type ||= 'application/octet-stream';
	
	return +{
		success  => ($status == 200),
		status   => $status,
		reason   => $reason,
		headers  => +{
			'content-type'   => $content_type,
			'content-length' => length($content),
		},
		content  => $content,
		decoded_content => $content,
	};
}

1;

=head1 NAME

HTML::HTML5::Parser::UA - simple web user agent class

=head1 SYNOPSIS

 use aliased 'HTML::HTML5::Parser::UA';
 
 my $response = UA->get($url);
 die unless $response->{success};
 
 print $response->{decoded_content};

=head1 DESCRIPTION

This is a simple wrapper around HTTP::Tiny and LWP::UserAgent to smooth out
the API differences between them. It only supports bog standard
C<< get($url) >> requests.

If LWP::UserAgent is already in memory, this module will use that.

If LWP::UserAgent is not in memory, then this module will use HTTP::Tiny (or
direct filesystem access for "file://" URLs).

If LWP::UserAgent is not in memory, and you attempt to request a URL that
HTTP::Tiny cannot handle (e.g. an "ftp://" URL), then this module will load
LWP::UserAgent and die if it cannot be loaded (e.g. is not installed).

HTML::HTML5::Parser::UA is used by the C<parse_file> method of
HTML::HTML5::Parser.

=head2 Class Method

=over

=item C<< get($url, $ua) >>

Gets the URL and returns a hashref similar to HTTP::Tiny's hashrefs, but
with an additional C<decoded_content> key, which contains the response
body, decoded into a Perl character string (not a byte string).

If $ua is given (it's optional), then this user agent will be used to
perform the actual request. Must be undef or an LWP::UserAgent object
(or a subclass) or an HTTP::Tiny object (or a subclass).

=back

=head2 Package Variable

=over

=item C<< $HTML::HTML5::Parser::NO_LWP >>

If true, avoids using LWP::UserAgent.

=back

=head1 MOTIVATION

L<LWP::UserAgent> is a good piece of software but it has a dependency on
L<HTML::Parser>. L<HTML::Parser> is only used to provide one fairly
esoteric feature, which this package doesn't make use of. (It's the
C<parse_head> option.)

Because of that, I don't especially want HTML::HTML5::Parser to have a
dependency on LWP::UserAgent. Hence this module.

=head1 SEE ALSO

L<HTML::HTML5::Parser>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

