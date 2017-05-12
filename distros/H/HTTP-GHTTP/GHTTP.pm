# $Id: GHTTP.pm,v 1.11 2002/03/25 09:25:53 matt Exp $

package HTTP::GHTTP;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.07';

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

bootstrap HTTP::GHTTP $VERSION;

@EXPORT_OK = qw( 
    get
    METHOD_GET
    METHOD_POST
    METHOD_OPTIONS
    METHOD_HEAD
    METHOD_PUT
    METHOD_DELETE
    METHOD_TRACE
    METHOD_CONNECT
    METHOD_PROPFIND
    METHOD_PROPPATCH
    METHOD_MKCOL
    METHOD_COPY
    METHOD_MOVE
    METHOD_LOCK
    METHOD_UNLOCK
    );

%EXPORT_TAGS = (
    methods => [qw(
                    METHOD_GET
                    METHOD_POST
                    METHOD_OPTIONS
                    METHOD_HEAD
                    METHOD_PUT
                    METHOD_DELETE
                    METHOD_TRACE
                    METHOD_CONNECT
                    METHOD_PROPFIND
                    METHOD_PROPPATCH
                    METHOD_MKCOL
                    METHOD_COPY
                    METHOD_MOVE
                    METHOD_LOCK
                    METHOD_UNLOCK
                )],
    );

sub new {
    my $class = shift;
    my $r = $class->_new();
    bless $r, $class;
    if (@_) {
        my $uri = shift;
        die "Blank uri not supported" unless length($uri);
        $r->set_uri($uri);
        while(@_) {
            my ($header, $value) = splice(@_, 0, 2);
            $r->set_header($header, $value);
        }
    }
    return $r;
}

sub get {
    die "get() requires a URI as a parameter" unless @_;
    my $r = __PACKAGE__->new(@_);
    $r->process_request;
    return $r->get_body();
}

sub get_socket {
    my $self = shift;
    require IO::Handle;
    my $sockno = $self->_get_socket();
    my $sock = IO::Handle->new_from_fd($sockno, "r") 
            || die "Cannot open socket: $!";
    return $sock;
}

1;
__END__

=head1 NAME

HTTP::GHTTP - Perl interface to the gnome ghttp library

=head1 SYNOPSIS

  use HTTP::GHTTP;
  
  my $r = HTTP::GHTTP->new();
  $r->set_uri("http://axkit.org/");
  $r->process_request;
  print $r->get_body;

=head1 DESCRIPTION

This is a fairly low level interface to the Gnome project's libghttp,
which allows you to process HTTP requests to HTTP servers. There also
exists a slightly higher level interface - a simple get() function
which takes a URI as a parameter. This is not exported by default, you
have to ask for it explicitly.

=head1 API

=head2 HTTP::GHTTP->new([$uri, [%headers]])

Constructor function - creates a new GHTTP object. If supplied a URI
it will automatically call set_uri for you. If you also supply a list
of key/value pairs it will set those as headers:

    my $r = HTTP::GHTTP->new(
        "http://axkit.com/",
        Connection => "close");

=head2 $r->set_uri($uri)

This sets the URI for the request

=head2 $r->set_header($header, $value)

This sets an outgoing HTTP request header

=head2 $r->set_type($type)

This sets the request type. The request types themselves are constants
that are not exported by default. To export them, specify the :methods
option in the import list:

    use HTTP::GHTTP qw/:methods/;
    my $r = HTTP::GHTTP->new();
    $r->set_uri('http://axkit.com/');
    $r->set_type(METHOD_HEAD);
    ...

The available methods are:

    METHOD_GET
    METHOD_POST
    METHOD_OPTIONS
    METHOD_HEAD
    METHOD_PUT
    METHOD_DELETE
    METHOD_TRACE
    METHOD_CONNECT
    METHOD_PROPFIND
    METHOD_PROPPATCH
    METHOD_MKCOL
    METHOD_COPY
    METHOD_MOVE
    METHOD_LOCK
    METHOD_UNLOCK

Some of these are for DAV.

=head2 $r->set_body($body)

This sets the body of a request, useful in POST and some of the DAV
request types.

=head2 $r->process_request()

This sends the actual request to the server

=head2 $r->get_status()

This returns 2 values, a status code (numeric) and a status reason
phrase. A simple example of the return values would be (200, "OK").

=head2 $r->get_header($header)

This gets the value of an incoming HTTP response header

=head2 $r->get_headers()

Returns a list of all the response header names in the order they 
came back. This method is only available in libghttp 1.08 and later -
perl Makefile.PL should have reported whether it found it or not.

  my @headers = $r->get_headers;
  print join("\n", 
        map { "$_: " . $r->get_header($_) } @headers), "\n\n";

=head2 $r->get_body()

This gets the body of the response

=head2 $r->get_error()

If the response failed for some reason, this returns a textual error

=head2 $r->set_authinfo($user, $password)

This sets an outgoing username and password for simple HTTP 
authentication

=head2 $r->set_proxy($proxy)

This sets your proxy server, use the form "http://proxy:port"

=head2 $r->set_proxy_authinfo($user, $password)

If you have set a proxy and your proxy requires a username and password
you can set it with this.

=head2 $r->prepare()

This is a low level interface useful only when doing async downloads.
See L<ASYNC OPERATION>.

=head2 $r->process()

This is a low level interface useful only when doing async downloads.
See L<ASYNC OPERATION>.

process returns undef for error, 1 for "in progress", and zero for
"complete".

=head2 $r->get_socket()

Returns an IO::Handle object that is the currently in progress socket.
Useful only when doing async downloads. There appears to be some corruption
when using the socket to retrieve file contents on more recent libghttp's.

=head2 $r->current_status()

This is only useful in async mode. It returns 3 values: The current
processing stage (0 = none, 1 = request, 2 = response headers,
3 = response), the number of bytes read, and the number of bytes total.

=head2 $r->set_async()

This turns async mode on. There is no corresponding unset function.

=head2 $r->set_chunksize($bytes)

Sets the download (and upload) chunk size in bytes for use in async
mode. This may be a useful value to set for slow modems, or perhaps
for a download progress bar, or just to allow periodic writes.

=head2 get($uri, [%headers])

This does everything automatically for you, retrieving the body at
the remote URI. Optionally pass in headers.

=head1 ASYNC OPERATION

Its possible to use an asynchronous mode of operation with ghttp. Here's
a brief example of how:

    my $r = HTTP::GHTTP->new("http://axkit.org/");
    $r->set_async; 
    $r->set_chunksize(1);
    $r->prepare;

    my $status;
    while ($status = $r->process) {
        # do something
        # you can do $r->get_body in here if you want to
        # but it always returns the entire body.
    }
    
    die "An error occured" unless defined $status;
    
    print $r->get_body;

Doing timeouts is an exercise for the reader (hint: lookup select() in
perlfunc).

Note also that $sock above is an IO::Handle, not an IO::Socket, although
you can probably get away with re-blessing it. Also note that by calling
$r->get_socket() you load IO::Handle, which probably brings a lot of
code with it, thereby obliterating a lot of the use for libghttp. So
use at your own risk :-)

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software, you may use it and distribute it under the 
same terms as Perl itself. Please be aware though that libghttp is
licensed under the terms of the LGPL, a copy of which can be found
in the libghttp distribution.

=head1 BUGS

Probably many - this is my first adventure into XS.

libghttp doesn't support SSL. When libghttp does support SSL, so will
HTTP::GHTTP. The author of libghttp, Chris Blizzard <blizzard@redhat.com>
is looking for patches to support SSL, so get coding!

=head1 BENCHMARKS

Benchmarking this sort of thing is often difficult, and I don't want
to offend anyone. But as well as being lightweight (HTTP::GHTTP is
about 4 times less code than either LWP::UserAgent, or HTTP::Lite), it
is also in my tests significantly faster. Here are my benchmark
results requesting http://localhost/ (the Apache "Successful Install"
page):

    Benchmark: timing 1000 iterations of ghttp, lite, lwp...
         ghttp:  8 wallclock secs ( 0.96 usr +  1.16 sys =  2.12 CPU)
          lite: 21 wallclock secs ( 3.00 usr +  3.44 sys =  6.44 CPU)
           lwp: 18 wallclock secs ( 9.76 usr +  1.59 sys = 11.35 CPU)

=cut
