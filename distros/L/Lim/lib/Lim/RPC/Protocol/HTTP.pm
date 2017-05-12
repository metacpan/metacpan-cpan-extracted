package Lim::RPC::Protocol::HTTP;

use common::sense;

use Scalar::Util qw(blessed weaken);

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use LWP::MediaTypes ();
use Fcntl ();
use JSON::XS ();

use Lim ();
use Lim::Util ();
use Lim::RPC::Callback ();

use base qw(Lim::RPC::Protocol);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $JSON = JSON::XS->new->utf8->convert_blessed;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 name

=cut

sub name {
    'http';
}

=head2 serve

=cut

sub serve {
}

=head2 handle

=cut

sub handle {
    my ($self, $cb, $request) = @_;
    
    unless (blessed($request) and $request->isa('HTTP::Request')) {
        return;
    }
    
    unless (defined Lim::Config->{protocol}->{http}->{webroot}
        and -d Lim::Config->{protocol}->{http}->{webroot})
    {
        return;
    }

    my (@path, $path, $file);
    foreach $path (split(/\//o, $request->uri->path)) {
        if ($path eq '..') {
            unless (scalar @path) {
                return;
            }
            pop(@path);
            next;
        }
        if ($path) {
            push(@path, $path);
        }
    }

    $file = pop(@path);
    $path = join('/', Lim::Config->{protocol}->{http}->{webroot}, @path);

    if (-d $path) {
        my $response = HTTP::Response->new;
        $response->request($request);
        $response->protocol($request->protocol);
        
        unless (defined $file) {
            $file = 'index.html';
        }
        $path .= '/'.$file;
        
        if (-d $path) {
            $path .= '/index.html';
        }
        
        unless (-r $path) {
            return;
        }

        my $query;
        if ($request->header('Content-Type') =~ /(?:^|\s)application\/x-www-form-urlencoded(?:$|\s|;)/o) {
            my $query_str = $request->content;
            $query_str =~ s/[\015\012]+$//o;

            $query = Lim::Util::QueryDecode($query_str);
        }
        else {
            $query = Lim::Util::QueryDecode($request->uri->query);
        }
        
        Lim::DEBUG and $self->{logger}->debug('Serving file ', $path);

        unless (sysopen(FILE, $path, Fcntl::O_RDONLY)) {
            $response->code(HTTP_FORBIDDEN);
            $cb->cb->($response);
            return 1;
        }

        binmode(FILE);
        
        my ($size, $mtime) = (stat(FILE))[7,9];
        unless (defined $size and defined $mtime) {
            $response->code(HTTP_INTERNAL_SERVER_ERROR);
            $cb->cb->($response);
            return 1;
        }
        
        if (defined $query->{jsonpCallback}) {
            my ($content, $buf);
            while (sysread(FILE, $buf, 64*1024)) {
                $content .= $buf;
            }
            close(FILE);
            
            eval {
                $content = $JSON->encode({ content => $content });
            };
            if ($@) {
                $response->code(HTTP_INTERNAL_SERVER_ERROR);
                $cb->cb->($response);
                return 1;
            }

            $response->header('Content-Type' => 'application/javascript; charset=utf-8');
            $response->content($query->{jsonpCallback}.'('.$content.');');
            $response->code(HTTP_OK);

            $cb->cb->($response);
            return 1;
        }
        
        unless (LWP::MediaTypes::guess_media_type($path, $response)) {
            $response->code(HTTP_INTERNAL_SERVER_ERROR);
            $cb->cb->($response);
            return 1;
        }

        if ($request->header('If-Modified-Since')
            and $request->header('If-Modified-Since') >= $mtime)
        {
            close(FILE);
            $response->code(HTTP_NOT_MODIFIED);
            $cb->cb->($response);
            return 1;
        }

        $response->header(
            'Content-Length' => $size,
            'Last-Modified' => $mtime
            );

        my $buf;
        while (sysread(FILE, $buf, 64*1024)) {
            $response->add_content($buf);
        }
        close(FILE);
        
        $response->code(HTTP_OK);

        $cb->cb->($response);
        return 1;
    }
    return;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Protocol::HTTP
