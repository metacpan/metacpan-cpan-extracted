package HTTP::Server::Brick;

use version;
our $VERSION = qv(0.1.7);

# $Id$

=head1 NAME

HTTP::Server::Brick - Simple pure perl http server for prototyping "in the style of" Ruby's WEBrick


=head1 VERSION

This document describes HTTP::Server::Brick version 0.1.7


=head1 SYNOPSIS

    use HTTP::Server::Brick;
    use HTTP::Status;
    
    my $server = HTTP::Server::Brick->new( port => 8888 );
    
    $server->mount( '/foo/bar' => {
        path => '/some/directory/htdocs',
    });
    
    $server->mount( '/test/proc' => {
        handler => sub {
            my ($req, $res) = @_;
            $res->add_content("<html><body>
                                 <p>Path info: $req->{path_info}</p>
                               </body></html>");
            1;
        },
        wildcard => 1,
    });
    
    $server->mount( '/test/proc/texty' => {
        handler => sub {
            my ($req, $res) = @_;
            $res->add_content("flubber");
            $res->header('Content-type', 'text/plain');
            1;
        },
        wildcard => 1,
    });
    
    # these next two are equivalent
    $server->mount( '/favicon.ico' => {
        handler => sub { RC_NOT_FOUND },
    });
    $server->mount( '/favicon.ico' => {
        handler => sub {
            my ($req, $res) = @_;
            $res->code(RC_NOT_FOUND);
            1;
        },
    });
    
    # start accepting requests (won't return unless/until process
    # receives a HUP signal)
    $server->start;

For an SSL (https) server, replace the C<new()> line above with:

    use HTTP::Daemon::SSL;
    
    my $server = HTTP::Server::Brick->new(
                                           port => 8889,
                                           daemon_class => 'HTTP::Daemon::SSL',
                                           daemon_args  => [
                                              SSL_key_file  => 'my_ssl_key.pem',
                                              SSL_cert_file => 'my_ssl_cert.pem',
                                           ],
                                         );

See the docs of L<HTTP::Daemon::SSL> for other options.

=head1 DESCRIPTION

HTTP::Server::Brick allows you to quickly wrap a prototype web server around some
Perl code. The underlying server daemon is HTTP::Daemon and the performance should
be fine for demo's, light internal systems, etc.
  
=head1 METHODS  

=cut

use warnings;
use strict;

use HTTP::Daemon;
use HTTP::Status;
use LWP::MediaTypes;
use URI;

use constant DEBUG => $ENV{DEBUG} || 0;


my $__singleton;
my $__server_should_run = 0;

$SIG{__WARN__} = sub { $__singleton ? $__singleton->_log( error => '[warn] ' . shift ) : CORE::warn(@_) };
$SIG{__DIE__} = sub {
  CORE::die (@_) if $^S; # don't interfere with eval
  $__singleton->_log( error => '[die] ' . $_[0] ) if $__singleton;
  CORE::die (@_)
};
$SIG{HUP} = sub { $__server_should_run = 0; };


=head2 new

C<new> takes nine named arguments (all of which are optional):

=over

=item error_log, access_log

Should be self-explanatory - can be anything that responds to C<print> eg.
file handle, IO::Handle, etc. Default to stderr and stdout respectively.

=item port

The port to listen on. Defaults to a random high port (you'll see it in the error log).

=item host

The server hostname. Defaults to something sensible.

=item timeout

Used for various timout values - see L<HTTP::Daemon> for more information.

=item directory_index_file

The filename for directory indexing. Note that this only applies to static path mounts.
Defaults to C<index.html>.

=item directory_indexing

If no index file is available (for a static path mount), do you want a clickable list
of files in the directory be rendered? Defaults to true.

=item leave_sig_pipe_handler_alone

HTTP::Daemon, the http server module this package is built on, chokes in certain multiple-request
situations unless you ignore PIPE signals. By default PIPE signals are ignored as soon as you start
the server (and restored if the server exits via HUP). If you want to handle PIPE signals your own
way, pass in a true value for this.

If this makes no sense to you, just ignore it - the "right thing" will happen by default.

=item daemon_class

The class which actually handles webserving.  The default is C<HTTP::Daemon>.
If you want SSL, use C<HTTP::Daemon::SSL>.  Whatever class you use must inherit
from HTTP::Daemon.

=item daemon_args

Sometimes you need to pass extra arguments to your C<daemon_class>, e.g. SSL
configuration.  This arrayref will be dereferenced and passed to C<new>.

=item fork

Set to true if you want a forking server.

=back

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;

    if ($args{daemon_class} and not
        eval { $args{daemon_class}->isa('HTTP::Daemon') }) {
        die "daemon_class argument '$args{daemon_class}'" .
          " must inherit from HTTP::Daemon";
    }

    my $self = bless {
        _site_map => [],
        error_log => \*STDERR,
        access_log => \*STDOUT,
        directory_index_file => 'index.html',
        directory_indexing => 1,
        daemon_class => 'HTTP::Daemon',
        daemon_args  => [],
        %args,
       }, $class;

    $__singleton = $self;

    return $self;
}

=head2 mount

C<mount> takes two positional arguments. The first a full uri (as
a string beginning with '/' - any trailing '/' will be stripped). The
second is a hashref which serves as a spec for the mount. The allowable
hash keys in this spec are:

=over

=item path

A full path to a local filesystem directory or file for static serving.
Mutually exclusive with C<handler>.

=item handler

A coderef. See L</Handlers> below. Mutually exclusive with C<path>.

=item wildcard

If false, only exact matches will be served. If true, any requests based
on the uri will be served. eg. if C<wildcard> is false, C<'/foo/bar'> will
only match C<http://mysite.com/foo/bar> and not, say, C<http://mysite.com/foo/bar/sheep>.
If C<wildcard> is true, on the other hand, it will match. A handler can
access the path extension as described below in L</Handlers>.

Static handlers that are directories default to wildcard true.

=back

The site map is always searched depth-first, in other words a more specific
uri will trump a less-specific one.

=head3 return value

C<mount> returns C<$self> so that it can be chained into a one-liner if desired.

=head3 shortcut invocation

As a shortcut also to aid one-liners, instead of a hashref the second argument can be
either a path string or a coderef, mapped like so:

=over

=item string

equivalent to C<{ path => the_string, wildcard => 1 }>

=item coderef

equivalent to C<{ handler => coderef, wildcard => 0 }>

=back

Eg. to quickly server your current directory:

  perl -MHTTP::Server::Brick -e 'HTTP::Server::Brick->new(fork=>1)->mount(qw(/ .))->start'

=cut

sub mount {
    my ($self, $uri, $args) = @_;

    if (ref($args) eq 'CODE') {
        $args = { handler => $args, wildcard => 0 };
    } elsif (!ref($args)) {
        $args = { path => $args, wildcard => 1 };
    } elsif (ref($args) ne 'HASH') {
        die 'third arg to mount must be a hashref, coderef or path string';
    }

    my $depth;
    if ($uri eq '/') {
        $depth = 0;
    } else {
        $uri =~ s!/$!!;
        my @parts = split( m!/!, $uri );
        $depth = scalar(@parts) - 1; # leading / adds one
    }

    $self->{_site_map}[$depth] ||= {};
    $self->{_site_map}[$depth]{$uri} = $args;

    # we should default a static path to a wildcard mount if it's a directory
    if (!exists $args->{wildcard} && exists $args->{path} && -d $args->{path}) {
        $args->{wildcard} = 1;
    }

    my $mount_type = exists $args->{handler} ? 'handler' :
      exists $args->{path} ? 'directory' : '(unknown)';
    $self->_log( error => 'Mounted' . ($args->{wildcard} ? ' wildcard' : '') . " $mount_type at $uri" );

    return $self;
}

=head2 start

Actually starts the server - this will loop indefinately, or until
the process recieves a C<HUP> signal in which case it will return after servicing
any current request, or waiting for the next timeout (which defaults to 5s - see L</new>).

=cut

sub start {
    my $self = shift;

    $__server_should_run = 1;

    # HTTP::Daemon chokes on multiple simultaneous requests
    unless ($self->{leave_sig_pipe_handler_alone}) {
        $self->{_old_sig_pipe_handler} = $SIG{'PIPE'};
        $SIG{'PIPE'} = 'IGNORE';
    }

    $SIG{CHLD} = 'IGNORE' if $self->{fork};

    $self->{daemon} = $self->{daemon_class}->new(
        ReuseAddr => 1,
        LocalPort => $self->{port},
        LocalHost => $self->{host},
        Timeout => exists $self->{timeout} ? $self->{timeout} : 5,
        @{ $self->{daemon_args} },
       ) or die "Can't start daemon: $!";

    # HTTP::Server::Daemon seems inconsistent in returning a string vs URI object
    my $url_string = UNIVERSAL::can($self->{daemon}->url, 'as_string') ?
      $self->{daemon}->url->as_string :
        $self->{daemon}->url;

    $self->_log(error => "Server started on $url_string");

    while ($__server_should_run) {
        my $conn = $self->{daemon}->accept or next;

        # if we're a forking server, fork. The parent will wait for the next request.
        # TODO: limit number of children
        next if $self->{fork} and fork;
        while (my $req = $conn->get_request) {

          # Provide an X-Brick-Remote-IP header
          my ($r_port, $r_iaddr) = Socket::unpack_sockaddr_in($conn->peername);
          my $ip = Socket::inet_ntoa($r_iaddr);
          $req->headers->remove_header('X-Brick-Remote-IP');
          $req->header('X-Brick-Remote-IP' => $ip) if defined $ip;

          my ($submap, $match) = $self->_map_request($req);

          if ($submap) {
              if (exists $submap->{path}) {
                  $self->_handle_static_request( $conn, $req, $submap, $match);
                  
              } elsif (exists $submap->{handler}) {
                  $self->_handle_dynamic_request( $conn, $req, $submap, $match);

              } else {
                  $self->_send_error($conn, $req, RC_INTERNAL_SERVER_ERROR, 'Corrupt Site Map');
              }

          } else {
              $self->_send_error($conn, $req, RC_NOT_FOUND, ' Not Found in Site Map');
          }
        }
        # should use a guard object here to protect against early exit leaving zombies
        exit if $self->{fork};
    }

    
    unless ($self->{leave_sig_pipe_handler_alone}) {
        $SIG{'PIPE'} = $self->{_old_sig_pipe_handler};
    }

    1;
}

sub _handle_static_request {
    my ($self, $conn, $req, $submap, $match) = @_;

    my $path = $submap->{path} . '/' . $match->{path_info};

    if (-d $path && $match->{full_path} !~ m!/$! ) {
        $conn->send_redirect( $match->{full_path} . '/', RC_SEE_OTHER );
        DEBUG && $self->_log(error => 'redirecting to path with / appended: ' . $match->{full_path});
        return;
    }

    my $serve_path = -d $path ? "$path/$self->{directory_index_file}" : $path;

    if (-r $serve_path) {
        my $code = $conn->send_file_response($serve_path);
        $self->_log_status($req, $code);
        
    } elsif (-d $path && $self->{directory_indexing}) {

        my $res = $self->_render_directory($path, $match->{full_path});
        $conn->send_response( $res );
        $self->_log( access => '[' . RC_OK . "] $match->{full_path}" );

        
    } elsif (-d $path) {
        $self->_send_error($conn, $req, RC_FORBIDDEN, 'Directory Indexing Not Allowed' );

    } else {
        $self->_send_error($conn, $req, RC_NOT_FOUND, 'File Not Found' );
    }
}

sub _handle_dynamic_request {
    my ($self, $conn, $req, $submap, $match) = @_;

    my $res = HTTP::Response->new;
    $res->base($match->{full_path});

    # stuff the match info into the request
    $req->{mount_path} = $match->{mount_path};
    $req->{path_info} = $match->{path_info} ? '/' . $match->{path_info} : undef;

    # and some other useful bits TODO: document (and, actually, subclass HTTP::Request...)

    # It seems that in some cases (specifically when the url contains no explicit port),
    # HTTP::Daemon returns a uri string instead of an object. RT #29042
    my $url = $self->{daemon}->url;
    $url = URI->new($url) if ! ref $url;

    if ($req->header('Host') =~ /^(.*):(.*)$/) {
        $req->{hostname} = $1;
        $req->{port} = $2;
    } elsif ($req->header('Host')) {
        $req->{hostname} = $req->header('Host');
        $req->{port} = $url->port;
    } else {
        $req->{hostname} = $url->host;
        $req->{port} = $url->port;
    }

    # actually call the handler
    if ( my $return_code = eval { $submap->{handler}->($req, $res) } ) {

        # choose the status in this order:
        #  1. if the handler died or returned false => RC_INTERNAL_SERVER_ERROR
        #  2. if the handler set a code on the response object, use that
        #  3. if the handler returned something that looks like a return code
        #  4. RC_OK
                    
        my $code = !$return_code ? RC_INTERNAL_SERVER_ERROR :
          $res->code ? $res->code :
            $return_code >= 100 ? $return_code : RC_OK;
                    
        $res->code($code);

        # default mime type to text/html
        $res->header( 'Content-Type' ) || $res->header( 'Content-Type', 'text/html' );
                    
        if ($res->is_success) {
            $conn->send_response( $res );
            $self->_log( access => "[$code] $match->{full_path}" );

        } elsif ($res->is_error) {
            # TODO: should allow a way to specify custom error content
            $self->_send_error( $conn, $req, $res->code, $res->message );

        } elsif ($res->is_redirect) {
            if (UNIVERSAL::can($res->{target_uri}, 'path')) {
                my $target = $res->{target_uri}->path;

                if ($target !~ m!^/!) {
                    # prepend dirname of original request
                    $match->{full_path} =~ m!^(.*/)! and
                      $target = $1 . $target;
                }
                $conn->send_redirect($target, $code);
                $self->_log( access => "[$code] Redirecting to " . $target );
            } else {
                $self->_send_error($conn, $req, RC_INTERNAL_SERVER_ERROR,
                              'Handler Tried to Redirect Without Setting Target URI');
            }

        } else {
            $self->_send_error($conn, $req, 
                          RC_NOT_IMPLEMENTED,
                          'Handler Returned an Unimplemented Response Code: ' . $code);
        }
    } else {
        $self->_send_error($conn, $req, RC_INTERNAL_SERVER_ERROR, 'Handler Failed');
        $self->_log( error => "Handler Failed for mount: " . $match->{mount_path});
        $self->_log( error => $@ ) if $@;
    }

    1;
}

sub _render_directory {
    my ($self, $path, $uri ) = @_;

    my $res = HTTP::Response->new( RC_OK );
        $res->header( 'Content-type', 'text/html' );
        
        $res->add_content(<<END_HEADER);
<html>
<head>
<title>Directory for $uri</title>
</head>
<body>
<h1>Directory for $uri</h1>
<blockquote><pre>
<a href="..">.. (Parent directory)</a>
END_HEADER

        for (sort glob "$path/*") {
            my $is_directory = -d $_;
            s!.*/!!;
            $_ .= '/' if $is_directory;
            $res->add_content("<a href=\"$_\">$_</a>\n");
        }

        $res->add_content(<<END_FOOTER);
</pre></blockquote>
</body>
</html>
END_FOOTER

    return $res;
}

sub _send_error {
    my ($self, $conn, $req, $code, $text) = @_;

    $conn->send_error($code, $text);

    $self->_log_status($req, $code, $text);
}

sub _log_status {
    my ($self, $req, $code, $text) = @_;

    if ($code == RC_OK || $code == RC_UNAUTHORIZED || $code == RC_NOT_FOUND) {
        $self->_log( access => "[$code] " . $req->uri->path );
    }

    $self->_log( error => "[$code] [" . $req->uri->path . '] ' . ($text || status_message($code)) )
      unless $code == RC_OK;
}

# this is not the best data structure for a complex site map, but it's
# easy to insert and query (although very hard to move things around).
# basically for every path depth (ie. number of /) there is a hash of
# full paths and their associated handler and meta-data.

# this would be an obvious performance point if you wanted to use this
# for actual serving.

sub _map_request {
    my ($self, $request) = @_;

    my $map = $self->{_site_map};

    my $uri = $request->uri->path;

    my @parts = split( m!/!, $uri );

    my $depth = scalar(@parts) - 1;
    # the test is reall for $uri eq '/', but an integer comparison is faster
    $depth = 0 if $depth == -1;
    my $match_depth = $depth;

    while ($match_depth >= 0) {

        my $mount_path = '/' . join('/', @parts[1..$match_depth]);

        if ($map->[$match_depth] && exists $map->[$match_depth]{$mount_path}) {

            # if we find a depth-first match, but it's not flagged as a wildcard
            # mount, then don't match
            if ($match_depth != $depth && !$map->[$match_depth]{$mount_path}{wildcard}) {
                return;
            }

            return(
                $map->[$match_depth]{$mount_path},
                {
                    full_path => $uri,
                    mount_path => $mount_path,
                    path_info => join('/', @parts[$match_depth+1..$depth]),
                },
               );
        }

        $match_depth--;
    }
}

=head2 add_type

The mime-type of static files is automatically determined by L<LWP::MediaTypes>. You
can add any types it doesn't know about via this method.

The first argument is the mime type, all subsequent arguments form a list of
possible file extensions for that mime type. See L<LWP::MediaTypes> for more info.

=cut

# Improve LWP::MediaTypes' mime-type knowledge.
LWP::MediaTypes::add_type('image/png'       => qw(png));
LWP::MediaTypes::add_type('text/css'        => qw(css));
LWP::MediaTypes::add_type('text/javascript' => qw(js));

sub add_type {
    my ($self, @args) = @_;

    LWP::MediaTypes::add_type(@args);
}

sub _log {
    my ($self, $log_key, $text) = @_;

    $self->{"${log_key}_log"}->print( '[' . localtime() . "] [$$] ", $text, "\n" );
}


1; # Magic true value required at end of module
__END__

=head1 Handlers

When a mounted handler codred matches a requested url, the sub is called with two
arguments in C<@_>, first a request object then a response object.

=head2 Request

The request object is an instance of L<HTTP::Request> with two extra properties:

=over

=item C<$req-E<gt>{mount_path}>

The mounted path that was matched. This will always be identical to C<< $req->uri->path >>
for non-wildcard mounts.

=item C<$req-E<gt>{path_info}>

Using nomenclature from L<CGI.pm>, any extra path (or rather, uri) info after the matched C<mount_path>.
This will always be empty for non-wildcard mounts.

=back

The documentation for L<HTTP::Request> will be of use for extracting all the other
useful information.

Added to the regular request headers created by L<HTTP::Request> is an X-Remote-IP header,
which allows you to obtain the remote IP of the client. (Contributed by Hans Dieter Pearcey).

=head2 Response

The response object is an instance of L<HTTP::Response>. The useful operations (which
you can learn how to do from the L<HTTP::Response> docs) are setting headers,
adding content and setting the http status code.

=head2 Response Headers

The C<Content-type> header defaults to C<text/html> unless your handler sets it to
something else. The C<Content-length> header is set for you.

=head2 Redirection

If you set the response code to a redirect code, you need to set a C<{target_uri}> property on the
request object to an instance of a C<URI::http> object reflecting the uri you want to redirect to
(either fully qualified or relative to the directory of the requested url). There are examples
in the test file C<t/serving.t> in this module's distribution.

This is weak because we're breaking encapsulation by assuming it's ok to stuff an extra variable
into the response object (just as we are to propogate the C<path_info> property). It does in fact
work fine and is unlikely to ever break, but a future version (prior to 1.0.0) of this module will
replace this behavior with a subclassed L<HTTP::Response> and appropriate setter/getter methods.

=head2 Handler Return

The handler sub must return true for a normal response. The actual http response
is determined as follows:

    1. if the handler died or returned false => RC_INTERNAL_SERVER_ERROR (ie. 500)
    2. if the handler set a code on the response object, use that
    3. if the handler returned something that looks like a return code
    4. RC_OK (ie. 200)

=head1 DEBUGGING

If an envronment variable DEBUG is set (to something Perl considers true) there will
be extra logging to C<error_log>.

=head1 DEPENDENCIES

L<LWP>
L<Test::More>
L<version>

=head1 HISTORY

Over the past few years I've spent quite a bit of time noodling about with Ruby
based web code - whether Rails or super cool continuation stuff - and it's always
easy to get a prototype up and serving thanks to WEBrick (the pure-Ruby server
that's part of the standard Ruby distribution). I've never found it quite as easy
to throw together such a prototype in Perl, hence YASHDM (yet another simple http
daemon module).

HTTP::Server::Brick is not a clone of WEBrick - it's "in the style of" WEBrick like
those movies in the discount VHS bin are "in the style of Lassie": The good guys
get saved, the bad guys get rounded up, but the dog's never quite as well trained...

To be more fair, I have just taken the ideas I have used (and liked) when building
prototypes with WEBrick and implemented them in (what I hope is) a Perlish way.


=head1 BUGS AND LIMITATIONS

=over

=item It's version 0.1.7 - there's bound to be some bugs!

=item The tests fail on windows due to forking limitations. I don't see any reason why the server itself won't work but I haven't tried it personally, and I have to figure out a way to test it from a test script that will work on Windows.

=item In forking mode there is no attempt to limit the number of forked children - beware of forking yourself ;)

=item No attention has been given to propagating any exception text into the http error (although the exception/die message will appear in the error_log).

=item Versions 1.02 and earlier of HTTP::Daemon::SSL has a feature/documentation conflict where it will never timeout. This means your server won't respond to a HUP signal until the next request is served. Version 1.03_01 (developer release) and later do not have this issue.

=back

If you want to check out the latest development version of HTTP::Server::Brick
you can do so from my GitHub account L<http://github.com/aufflick/p5-http-server-brick>.

Please report any bugs or feature requests to
C<bug-http-server-brick@rt.cpan.org>, through the web interface at
L<http://rt.cpan.org> or via email to the author.

=head1 SEE ALSO

CPAN has various other modules that may suit you better. Search for HTTP::Server or HTTP::Daemon.
L<HTTP::Daemon>, L<HTTP::Daemon::App> and L<HTTP::Server::Simple> spring to mind.


=head1 AUTHOR

=over

=item Original version by: Mark Aufflick  C<< <mark@aufflick.com> >> L<http://mark.aufflick.com/>

=item SSL and original forking support by: Hans Dieter Pearcey  C<< <hdp@pobox.com> >>

=item Maintained by: Mark Aufflick

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 2008, Mark Aufflick C<< <mark@aufflick.com> >>.
Portions Copyright (c) 2007 2008, Hans Dieter Pearcey C<< <hdp@pobox.com> >>

All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
