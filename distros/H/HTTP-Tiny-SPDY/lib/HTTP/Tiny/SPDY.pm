package HTTP::Tiny::SPDY;

use strict;
use warnings;

# ABSTRACT: A subclass of HTTP::Tiny with SPDY support

our $VERSION = '0.020'; # VERSION

use HTTP::Tiny;
use Net::SPDY::Session;

use parent 'HTTP::Tiny';

my @attributes;
BEGIN {
    @attributes = qw(enable_SPDY);
    ## no critic (NoStrict)
    no strict 'refs';
    for my $accessor (@attributes) {
        *{$accessor} = sub {
            @_ > 1 ? $_[0]->{$accessor} = $_[1] : $_[0]->{$accessor};
        };
    }
    ## use critic
}


sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{enable_SPDY} = exists $args{enable_SPDY} ? $args{enable_SPDY} : 1;

    return $self;
}

my %DefaultPort = (
    http => 80,
    https => 443,
);
 
sub _request {
    my ($self, $method, $url, $args) = @_;
 
    my ($scheme, $host, $port, $path_query, $auth) = $self->_split_url($url);
 
    my $request = {
        method    => $method,
        scheme    => $scheme,
        host      => $host,
        host_port => ($port == $DefaultPort{$scheme} ? $host : "$host:$port"),
        uri       => $path_query,
        headers   => {},
    };
 
    # We remove the cached handle so it is not reused in the case of redirect.
    # If all is well, it will be recached at the end of _request.  We only
    # reuse for the same scheme, host and port
    my $handle = delete $self->{handle};
    if ( $handle ) {
        unless ( $handle->can_reuse( $scheme, $host, $port ) ) {
            $handle->close;
            undef $handle;
        }
    }
    $handle ||= $self->_open_handle( $request, $scheme, $host, $port );

    $self->_prepare_headers_and_cb($request, $args, $url, $auth);

    $handle->write_request($request);

    my $response;

    if (defined $handle->{spdy}) {
        # SPDY connection
        my $framer = $handle->{spdy}->{session}->{framer};

        while (my %frame = $framer->read_frame) {
            if (exists $frame{type} &&
                $frame{type} == Net::SPDY::Framer::SYN_REPLY)
            {
                my %frame_headers = @{$frame{headers}};
                my @http_headers = @{$frame{headers}};

                ($response->{status}, $response->{reason}) =
                    split /[\x09\x20]+/, delete($frame_headers{':status'}), 2;

                $response->{headers} = {};

                for (my $i = 0; $i < $#http_headers; $i += 2) {
                    if ($http_headers[$i] !~ /^:/) {
                        my $field_name = lc $http_headers[$i];

                        if (exists $response->{headers}->{$field_name}) {
                            if (ref $response->{headers}->{$field_name} ne 'ARRAY') {
                                $response->{headers}->{$field_name} = [
                                    $response->{headers}->{$field_name}
                                ];

                                push @{$response->{headers}->{$field_name}}, $http_headers[$i+1];
                            }
                        }
                        else {
                            $response->{headers}->{$field_name} = $http_headers[$i+1];
                        }
                    }
                }
            }

            if (!$frame{control}) {
                # TODO: Add support for max_size
                $response->{content} .= $frame{data};
            }

            last if ($frame{flags} & Net::SPDY::Framer::FLAG_FIN);

            # FIXME: Probably need to do better than just saying "throw another
            # 64K on us" after each and every frame
            $framer->write_frame(
                control => 1,
                type => Net::SPDY::Framer::WINDOW_UPDATE,
                stream_id => $frame{stream_id},
                delta_window_size => 0x00010000,
            );
        }

        $handle->close;
    }
    else {
        # Traditional HTTP(S) connection
        do { $response = $handle->read_response_header }
            until (substr($response->{status},0,1) ne '1');
     
        $self->_update_cookie_jar( $url, $response ) if $self->{cookie_jar};
     
        if ( my @redir_args = $self->_maybe_redirect($request, $response, $args) ) {
            $handle->close;
            return $self->_request(@redir_args, $args);
        }
     
        my $known_message_length;
        if ($method eq 'HEAD' || $response->{status} =~ /^[23]04/) {
            # response has no message body
            $known_message_length = 1;
        }
        else {
            my $data_cb = $self->_prepare_data_cb($response, $args);
            $known_message_length = $handle->read_body($data_cb, $response);
        }

        if ( $self->{keep_alive}
            && $known_message_length
            && $response->{protocol} eq 'HTTP/1.1'
            && ($response->{headers}{connection} || '') ne 'close'
        ) {
            $self->{handle} = $handle;
        }
        else {
            $handle->close;
        }        
    }
 
    $response->{success} = substr($response->{status},0,1) eq '2';
    $response->{url} = $url;
    return $response;
}

sub _open_handle {
    my ($self, $request, $scheme, $host, $port) = @_;

    if ($self->{enable_SPDY}) {
        my $handle  = HTTP::Tiny::Handle::SPDY->new(
            timeout         => $self->{timeout},
            SSL_options     => $self->{SSL_options},
            verify_SSL      => $self->{verify_SSL},
            local_address   => $self->{local_address},
            keep_alive      => $self->{keep_alive},
        );

        if ($self->{_has_proxy}{$scheme} && ! grep { $host =~ /\Q$_\E$/ } @{$self->{no_proxy}}) {
            return $self->_proxy_connect( $request, $handle );
        }
        else {
            return $handle->connect($scheme, $host, $port);
        }
    }
    else {
        return $self->SUPER::_open_handle($request, $scheme, $host, $port);
    }
}

package
    HTTP::Tiny::Handle::SPDY;

use strict;
use warnings;

use IO::Socket qw(SOCK_STREAM);

use parent -norequire, 'HTTP::Tiny::Handle';

sub connect {
    @_ == 4 || die(q/Usage: $handle->connect(scheme, host, port)/ . "\n");
    my ($self, $scheme, $host, $port) = @_;
 
    if ( $scheme eq 'https' ) {
        # Need IO::Socket::SSL 1.42 for SSL_create_ctx_callback
        die(qq/IO::Socket::SSL 1.42 must be installed for https support\n/)
            unless eval {require IO::Socket::SSL; IO::Socket::SSL->VERSION(1.42)};
        # Need Net::SSLeay 1.49 for MODE_AUTO_RETRY
        die(qq/Net::SSLeay 1.49 must be installed for https support\n/)
            unless eval {require Net::SSLeay; Net::SSLeay->VERSION(1.49)};
    }
    elsif ( $scheme ne 'http' ) {
      die(qq/Unsupported URL scheme '$scheme'\n/);
    }
    $self->{fh} = 'IO::Socket::INET'->new(
        PeerHost  => $host,
        PeerPort  => $port,
        $self->{local_address} ?
            ( LocalAddr => $self->{local_address} ) : (),
        Proto     => 'tcp',
        Type      => SOCK_STREAM,
        Timeout   => $self->{timeout}
    ) or die(qq/Could not connect to '$host:$port': $@\n/);
 
    binmode($self->{fh})
      or die(qq/Could not binmode() socket: '$!'\n/);

    if ($scheme eq 'https') {
        $self->start_ssl($host);

        if ($self->{fh}->next_proto_negotiated &&
            $self->{fh}->next_proto_negotiated eq 'spdy/3')
        {
            # SPDY negotiation succeeded
            $self->{spdy} = {
                session => Net::SPDY::Session->new($self->{fh}),
                stream_id => 1,
            };
        }
    }

    $self->{scheme} = $scheme;
    $self->{host} = $host;
    $self->{port} = $port;
 
    return $self;
}

my $Printable = sub {
    local $_ = shift;
    s/\r/\\r/g;
    s/\n/\\n/g;
    s/\t/\\t/g;
    s/([^\x20-\x7E])/sprintf('\\x%.2X', ord($1))/ge;
    $_;
};

# HTTP headers which must not be present in a SPDY request
my %invalid_headers;
undef @invalid_headers{qw( connection host )};
 
sub write_request {
    @_ == 2 || die(q/Usage: $handle->write_request(request)/ . "\n");
    my ($self, $request) = @_;

    if (defined $self->{spdy}) {
        my $framer = $self->{spdy}->{session}->{framer};

        my %frame = (
            type => Net::SPDY::Framer::SYN_STREAM,
            stream_id => $self->{spdy}->{stream_id},
            associated_stream_id => 0,
            priority => 2,
            flags => $request->{cb} ? 0 : Net::SPDY::Framer::FLAG_FIN,
            slot => 0,
            headers => [
                ':method' => $request->{method},
                ':scheme' => $request->{scheme},
                ':path' => $request->{uri},
                ':version' => 'HTTP/1.1',
                ':host' => $request->{host_port},
            ]
        );

        while (my ($k, $v) = each %{$request->{headers}}) {
            my $field_name = lc $k;

            # Omit invalid headers
            next if exists $invalid_headers{$field_name};

            for (ref $v eq 'ARRAY' ? @$v : $v) {
                /[^\x0D\x0A]/
                    or die(qq/Invalid HTTP header field value ($field_name): / . $Printable->($_). "\n");
                push @{$frame{headers}}, $field_name, $_;
            }
        }

        $framer->write_frame(%frame);

        if ($request->{cb}) {
            if ($request->{headers}{'content-length'}) {
                # write_content_body
                my ($len, $content_length) = (0, $request->{headers}{'content-length'});

                my $data = $request->{cb}->();
                my $last_frame = 0;

                do {
                    my %frame = (
                        control => 0,
                        stream_id => $self->{spdy}->{stream_id},
                        data => $data || '',
                        flags => 0,
                    );

                    $last_frame = !defined $data || !length $data;
                    
                    if (!$last_frame) {
                        $data = $request->{cb}->();
                        $last_frame = !defined $data || !length $data;
                    }

                    if ($last_frame) {
                        $frame{flags} |= Net::SPDY::Framer::FLAG_FIN;
                    }
                    
                    %frame = $framer->write_frame(%frame);
                    
                    $len += $frame{length};
                }
                while (!$last_frame);

                $len == $content_length
                    or die(qq/Content-Length mismatch (got: $len, expected: $content_length)\n/);
            }
            else {
                # write_chunked_body
            }
        }

        $self->{spdy}->{stream_id} += 2;

        return;
    }
    else {
        return $self->SUPER::write_request($request);
    }
}

sub _ssl_args {
    my ($self, $host) = @_;

    my %ssl_args = %{$self->SUPER::_ssl_args($host)};

    $ssl_args{SSL_npn_protocols} = ['spdy/3'];

    return \%ssl_args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::SPDY - A subclass of HTTP::Tiny with SPDY support

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use HTTP::Tiny::SPDY;

    my $response = HTTP::Tiny::SPDY->new->get('https://example.com/');

    die "Failed!\n" unless $response->{success};

    print "$response->{status} $response->{reason}\n";

    while (my ($k, $v) = each %{$response->{headers}}) {
        for (ref $v eq 'ARRAY' ? @$v : $v) {
            print "$k: $_\n";
        }
    }

    print $response->{content} if length $response->{content};

=head1 DESCRIPTION

This is a subclass of L<HTTP::Tiny> with added support for the SPDY protocol. It
is intended to be fully compatible with HTTP::Tiny so that it can be used as a
drop-in replacement for it.

=head1 METHODS

=head2 new

    $http = HTTP::Tiny::SPDY->new( %attributes );

Constructor that returns a new HTTP::Tiny::SPDY object. It accepts the same
attributes as the constructor of HTTP::Tiny, and one additional attribute:

=over 4

=item *

C<enable_SPDY>

A boolean that indicates if a SPDY connection should be negotiated for HTTPS
requests (default is true)

=back

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Tiny>

=item *

L<Net::SPDY>

=item *

L<SPDY Project Homepage|http://dev.chromium.org/spdy/>

=back

=head1 ACKNOWLEDGEMENTS

SPDY protocol support is provided by L<Net::SPDY>, written by Lubomir Rintel.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-HTTP-Tiny-SPDY/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-HTTP-Tiny-SPDY>

  git clone https://github.com/odyniec/p5-HTTP-Tiny-SPDY.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
