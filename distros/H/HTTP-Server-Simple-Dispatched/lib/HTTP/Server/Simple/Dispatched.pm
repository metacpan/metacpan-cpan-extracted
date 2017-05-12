package HTTP::Server::Simple::Dispatched;

=head1 NAME

HTTP::Server::Simple::Dispatched - Django-like regex dispatching with request and response objects - no CGI.pm cruft!

=head1 VERSION

Version 0.06

=cut

use Moose;
use Moose::Util::TypeConstraints;
our $VERSION = '0.06';

extends qw(
	HTTP::Server::Simple
	Exporter
);

use URI;
use URI::Escape qw(uri_unescape);
use MIME::Types;
use File::Spec::Functions qw(rel2abs);

use HTTP::Server::Simple::Dispatched::Request;
use HTTP::Response;

use Data::Dumper;
use Devel::StackTrace;
use Carp;

=head1 SYNOPSIS

Quick and dirty regex-based dispatching inspired by Django, with standard response and request objects to ease some of the pain of HTTP::Server::Simple. Lower level than CGI.pm, which allows you to lose some of the cruft of that hoary old monster.

    use HTTP::Server::Simple::Dispatched qw(static);

    my $server = HTTP::Server::Simple::Dispatched->new(
      hostname => 'myawesomeserver.org',
      port     => 8081,
      debug    => 1,
      dispatch => [
        qr{^/hello/} => sub {
          my ($response) = @_;
          $response->content_type('text/plain');
          $response->content("Hello, world!");
          return 1;
        },
        qr{^/say/(\w+)/} => sub {
          my ($response) = @_;
          $response->content_type('text/plain');
          $response->content("You asked me to say $1.");
          return 1;
        },
        qr{^/counter/} => sub {
          my ($response, $request, $context) = @_;
          my $num = ++$context->{counter};
          $response->content_type('text/plain');
          $response->content("Called $num times.");
          return 1;
        },
        qr{^/static/(.*\.(?:png|gif|jpg))} => static("t/"),
        qr{^/error/} => sub {
          die "This will cause a 500!";
        },
      ],
    );

    $server->run();

=cut

sub _valid_dispatch_map {
	my $aref = $_[0];
	return 0 if (@$aref % 2);

	for(my $i = 0; $i < @$aref; ) {
		my $pattern = $aref->[$i++];
		my $handler = $aref->[$i++];
		if (ref $pattern ne 'Regexp' || ref $handler ne 'CODE') {
			return 0;
		}
	}

	return 1;
}
subtype DispatchMap => as ArrayRef => where {_valid_dispatch_map($_)};

=head1 EXPORTED VARIABLES

=head2 $mime

The registry of mime types, this is a MIME::Types and is referenced
during the serving of static files.  Not exported by default.

=cut

our $mime = MIME::Types->new();

=head1 EXPORTED FUNCTIONS

=head2 static

Use this in dispatch specifiers to install a static-file handler.  It takes one argument, a "root" directory.  Your regex must capture the path from that root as $1 - e.g. "qr{^/some_path/(.*\.(?:png))} => static("foo/") to serve only .png files from foo/ as "/some_path/some.png".  See the the 'static' example in the synopsis.  Not exported by default.  

=cut

sub static {
	my $root = rel2abs($_[0]);
	my $child_match = qr{^$root/.*};
	my $default_type = $mime->type('application/octet-stream');

	return sub {
		my ($response, $request) = @_;
		eval {
			my $path = rel2abs(uri_unescape($1), $root);
			$path =~ $child_match or die {code => 404};

			my $fh = IO::File->new($path, '<') or 
				die {code => (-e $path ? 403 : 404)};

			my $type = $mime->mimeTypeOf($path) || $default_type;
			$fh->binmode() if $type->isBinary;

			my $content;
			{local $/; $content = <$fh>};
			$fh->close();

			$content ||= q();
			$response->content($content);
			$response->content_type($content ? $type : 'text/plain');
		};
		return 1 unless $@; 

		if (ref $@ eq 'HASH' and exists $@->{code}) {
			$response->code($@->{code});
			return 1;
		}

		# Other errors mean 500 with debug info
		die $@;
	};
}

our @EXPORT_OK = qw(static $mime);

=head1 ATTRIBUTES

These are Moose attributes: see its documentation for details, or treat them like regular perl read/write object accessors with convenient keyword arguments in the constructor.  

=head2 dispatch

An arrayref of regex object => coderef pairs.  This bit is why you're using this module - you can map urls to handlers and capture pieces of the url.  Any captures in the regex are bound to $1..$n just like in a normal regex.  See the 'say' example in the synopsis.  Note: these are matched in the order you specify them, so beware permissive regexes!  

=over 2

=item

Handlers receive three arguments:  An HTTP::Response, an HTTP::Server::Simple::Dispatched::Request, and the context object.  The response object defaults to a 200 OK response with text/html as the content type.  

=item

Your handler should return a true value if it handles the request - return 0 otherwise (that entry didn't exist in the database, etc.) and a standard 404 will be generated unless another handler picks it up.

=item

Content-Length will be set for you if you do not set it yourself.  This is I<probably> what you want.  If you do not, manually set Content-Length to whatever you think it should be.

=item

Any errors in your handler will be caught and raise a 500, so you I<probably> do not need to raise this condition yourself.  Anything that is not handled by one of your handlers will raise a 404.  The rest is up to you!  

=back

=cut

has dispatch => (
	is       => 'rw',
	isa      => 'DispatchMap',
	required => 1,
);

=head2 hostname

Not to be confused with the parent class's "host" accessor, the hostname has
nothing to do with which interface to bind the server to.  It is used to fill
out Request objects with a full URI (in some cases, the locally known hostname
for an interface is NOT what the outside world uses to reach it!

=cut

has hostname => (is => 'rw');

=head2 context

Every handler will get passed this object, which is global to the server.  It can be anything, but defaults to a hashref.  Use this as a quick and dirty stash, and then fix it with something real later.

=cut

has context => (
	is      => 'rw',
	default => sub { {} },
);

=head2 debug

If this is set to true, 500 errors will display some debugging information to the browser.  Defaults to false.

=cut

has debug => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

=head2 append_slashes

If this is set true (which it is by default), requests for /some/method will be redirected to the /some/method/ handler (if such a handler exists).  This is highly recommended, as many user agents start to append slashes if the last component of a path does not have an extension, and it makes things look a little nicer.

=cut

has append_slashes => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
);

has request => (
	is  => 'rw',
	isa => 'HTTP::Server::Simple::Dispatched::Request',
);

=head1 METHODS

=head2 new

This is a proper subclass of HTTP::Server::Simple, but the constructor takes all L<ATTRIBUTES> and standard PERLy accessors from the parent class as keyword arguments for convenience.

=cut

sub new {
	my $class = shift;
	my %args;

	if (@_ == 1) {	
		(ref $_[0] eq 'HASH' and %args = %{$_[0]}) 
			or confess 'Single paramaters to new() must be a HASH ref.';
	} else {
		%args = @_;
	}

	my $server = $class->SUPER::new($args{port});

	my $meta = $class->meta;
	my $self = $meta->new_object(__INSTANCE__ => $server, %args);

	# Moosie constructor params for normal accessors
	foreach my $key (keys %args) {
		if(!$meta->has_attribute($key) and my $setter = $self->can($key)) {
			$setter->($self, $args{$key});	
		}
	}	

	return $self;
}

sub headers {
	my ($self, $args) = @_;
	for(my $i = 0; $i < @$args; ) {
		my $header = $args->[$i++];
		my $value  = $args->[$i++];
		$self->request->header($header => $value);
	}
}

before setup => sub {
	my ($self, %args) = @_;

	my $uri = URI->new($args{request_uri});
	$uri->scheme('http');
	$uri->authority($self->hostname);
	$uri->port($self->port);

	$self->request(HTTP::Server::Simple::Dispatched::Request->new(
		method   => $args{method},
		uri      => $uri->canonical,
		protocol => $args{protocol},
		handle   => $self->stdin_handle,
	));
};

sub handler {
	my $self = shift;
	my $request = $self->request;

	my $response = HTTP::Response->new(200);
	$response->content_type('text/html');
	$response->protocol($request->protocol);

	my $dispatch = $self->dispatch;
	my $path = uri_unescape($request->uri->path);
	my $slashes = $self->append_slashes;

	my $handled = 0;

	for (my $i = 0; $i < @$dispatch; ) {
		my $pattern = $dispatch->[$i++];
		my $handler = $dispatch->[$i++];
		if ($path =~ $pattern) {
			eval {
				$handled = $handler->($response, $request, $self->context);
			};
			if (my $err = $@) {
				$response->headers->clear();
				$response->code(500);
				$response->headers->content_type('text/plain');
				if ($self->debug) {
					my $reqdump = $self->request->as_string;
					my $resdump = $response->as_string;
					my $condump = Dumper($self->context);
					$response->content(
						"Handler died: $err\n\n".
						Devel::StackTrace->new."\n\n".
						"Request:  $reqdump\n".
						"Response: $resdump\n".
						"Context:\n$condump"
					);
				}
				else {
					$response->content("500 - Internal Server Error");
				}
				$handled = 1;
			}
		}
		elsif ($slashes && "$path/" =~ $pattern) {
			$response->code(301);
			$response->header(Location => "$path/");
			$handled = 1;
		}
		last if $handled;
	}
	$response->code(404) unless ($handled);
	if ($response->code != 200 && $response->code != 500) {
		$response->headers->content_type('text/plain');
		$response->content($response->status_line);
	}

	unless (defined $response->content_length) {
		use bytes;
		$response->content_length(length $response->content);
	}
	print $response->as_string;
}

no Moose;
1;

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-server-simple-dispatched at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Server-Simple-Dispatched>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 CONTRIBUTING

The development branch lives at L<http://helios.tapodi.net/~pdriver/Bazaar/HTTP-Server-Simple-Dispatched>. Creating your own branch and sending me the URL is the preferred way to send patches.

=head1 ACKNOWLEDGEMENTS

The static serve code was adapted from HTTP::Server::Simple::Static - I would have reused, but it didn't do what I wanted at all.

As mentioned elsewhere, Django's url dispatching is the inspiration for this module.

=head1 SEE ALSO

L<HTTP::Response>, L<HTTP::Server::Simple::Dispatched::Request>,
L<MIME::Types>, L<Moose>, L<HTTP::Server::Simple::Dispatched>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
