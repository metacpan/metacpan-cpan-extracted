use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Server::Connection;

{
    package T::RawHTTPConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
        
    sub _http_native_request ($self, $request) {
        $self->data->{raw_request_hits}++;
        return $self->SUPER::_http_native_request($request);
    }

    sub _http_native_fallback_input ($self, $bytes) {
        $self->data->{fallback_hits}++;
        return $self->SUPER::_http_native_fallback_input($bytes);
    }

    sub _http_native_content_length_body ($self, $bytes, $done) {
        $self->data->{native_body_hits}++;
        return $self->SUPER::_http_native_content_length_body($bytes, $done);
    }

    sub _http_native_chunked_body ($self, $bytes, $done) {
        $self->data->{native_chunked_body_hits}++;
        return $self->SUPER::_http_native_chunked_body($bytes, $done);
    }

    sub on_request ($self, $request, $response) {
        my $state = $self->data;
        push @{$state->{paths}}, $request->target;
        $response->header('Content-Type', 'text/plain');
        $response->body(
            $request->target eq '/upload' ? 'POST'
            : $request->target eq '/after' ? 'AFTER'
            : 'RAW'
        );
        return;
    }

    sub on_body ($self, $request, $response, $bytes) {
        $self->data->{body} .= $bytes;
        return;
    }
}

subtest 'raw native head parsing shares the current request lifecycle' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        body => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_body_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawHTTPConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw HTTP integration test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /upload HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Content-Length: 4\r\n\r\n" .
                "DATA" .
                "GET /after HTTP/1.1\r\n" .
                "Host: example.test\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            my $responses = () = $state->{wire} =~ /HTTP\/1\.1 200 OK/g;
            if ($responses >= 2 && !$state->{sent_third}) {
                $state->{sent_third} = 1;
                $stream->write(
                    "GET /raw-again HTTP/1.1\r\n" .
                    "Host: example.test\r\n\r\n"
                );
            }
            if ($responses >= 3) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_error => sub ($stream, $error) {
            die "raw HTTP client failed: $error\n";
        },
    );

    $loop->run;

    is($state->{body}, 'DATA',
        'Content-Length body bytes reach the existing on_body lifecycle');
    is_deeply(
        $state->{paths},
        [ '/upload', '/after', '/raw-again' ],
        'request ordering survives direct body delivery and remains native',
    );
    is($state->{raw_request_hits}, 3,
        'all request heads, including the same-read pipelined head, parse natively');
    cmp_ok($state->{native_body_hits}, '>=', 1,
        'Content-Length body used direct raw-provider body delivery');
    is($state->{fallback_hits}, 0,
        'Content-Length body does not enter the generic Perl input fallback');
    is(
        scalar(() = $state->{wire} =~ /HTTP\/1\.1 200 OK/g),
        3,
        'all three responses completed on one persistent connection',
    );
};

{
    package T::RawDrainConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
        
    sub _http_native_request ($self, $request) {
        $self->data->{raw_request_hits}++;
        return $self->SUPER::_http_native_request($request);
    }

    sub _http_native_fallback_input ($self, $bytes) {
        $self->data->{fallback_hits}++;
        return $self->SUPER::_http_native_fallback_input($bytes);
    }

    sub _http_native_content_length_complete ($self) {
        $self->data->{native_complete_hits}++;
        return $self->SUPER::_http_native_content_length_complete;
    }

    sub _http_native_chunked_complete ($self) {
        $self->data->{native_chunked_complete_hits}++;
        return $self->SUPER::_http_native_chunked_complete;
    }

    sub on_request ($self, $request, $response) {
        push @{$self->data->{paths}}, $request->target;
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body($request->target eq '/drain' ? 'DRAIN' : 'NEXT');
        return;
    }
}

subtest 'raw Content-Length drain stays native through a pipelined next head' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_complete_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawDrainConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw Content-Length drain test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /drain HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Content-Length: 4\r\n\r\n" .
                "DATA" .
                "GET /next HTTP/1.1\r\n" .
                "Host: example.test\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            my $responses = () = $state->{wire} =~ /HTTP\/1\.1 200 OK/g;
            if ($responses >= 2) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_error => sub ($stream, $error) {
            die "raw Content-Length drain client failed: $error\n";
        },
    );

    $loop->run;

    is_deeply($state->{paths}, [ '/drain', '/next' ],
        'drained body boundary preserves the pipelined next request');
    is($state->{raw_request_hits}, 2,
        'both request heads are parsed through the raw provider');
    is($state->{native_complete_hits}, 1,
        'drained Content-Length body notifies Perl only at completion');
    is($state->{fallback_hits}, 0,
        'drained Content-Length body never enters generic fallback');
};

subtest 'raw chunked body delivery stays native through a pipelined next head' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        body => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_body_hits => 0,
        native_chunked_body_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawHTTPConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw chunked body test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /upload HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Transfer-Encoding: chunked\r\n\r\n" .
                "4\r\nDATA\r\n0\r\n\r\n" .
                "GET /after HTTP/1.1\r\n" .
                "Host: example.test\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            my $responses = () = $state->{wire} =~ /HTTP\/1\.1 200 OK/g;
            if ($responses >= 2) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_error => sub ($stream, $error) {
            die "raw chunked body client failed: $error\n";
        },
    );

    $loop->run;

    is($state->{body}, 'DATA', 'chunked body reaches on_body directly');
    is_deeply($state->{paths}, [ '/upload', '/after' ],
        'chunked body boundary preserves the pipelined next request');
    is($state->{raw_request_hits}, 2,
        'both request heads parse through the raw provider');
    cmp_ok($state->{native_chunked_body_hits}, '>=', 1,
        'chunked body used direct native-provider body delivery');
    is($state->{fallback_hits}, 0,
        'chunked body does not enter the generic Perl input fallback');
};

subtest 'raw chunked decoder preserves state across separate reads' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        body => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_body_hits => 0,
        native_chunked_body_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawHTTPConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw fragmented chunked test timed out\n";
        },
    );
    my $second_write;

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /upload HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Transfer-Encoding: chunked\r\n\r\n" .
                "4\r\nDA"
            );
            $second_write = Linux::Event::Kernel::Timer->new(
                loop => $loop,
                after => 0.02,
                on_timer => sub ($timer) {
                    $stream->write(
                        "TA\r\n0\r\n\r\n" .
                        "GET /after HTTP/1.1\r\n" .
                        "Host: example.test\r\n\r\n"
                    );
                },
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            my $responses = () = $state->{wire} =~ /HTTP\/1\.1 200 OK/g;
            if ($responses >= 2) {
                $guard->cancel;
                $second_write->cancel if $second_write;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_error => sub ($stream, $error) {
            die "raw fragmented chunked client failed: $error\n";
        },
    );

    $loop->run;

    is($state->{body}, 'DATA',
        'chunked payload split across reads is decoded exactly once');
    is_deeply($state->{paths}, [ '/upload', '/after' ],
        'fragmented chunked completion preserves following request');
    is($state->{raw_request_hits}, 2,
        'next request returns to native request-head parsing');
    cmp_ok($state->{native_chunked_body_hits}, '>=', 2,
        'persistent native chunked decoder delivered across multiple reads');
    is($state->{fallback_hits}, 0,
        'fragmented chunked body never enters generic fallback');
};

subtest 'raw chunked drain consumes trailers and preserves next request' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_complete_hits => 0,
        native_chunked_complete_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawDrainConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw chunked drain test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /drain HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Transfer-Encoding: chunked\r\n\r\n" .
                "4\r\nDATA\r\n0\r\nX-Trailer: yes\r\n\r\n" .
                "GET /next HTTP/1.1\r\n" .
                "Host: example.test\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            my $responses = () = $state->{wire} =~ /HTTP\/1\.1 200 OK/g;
            if ($responses >= 2) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_error => sub ($stream, $error) {
            die "raw chunked drain client failed: $error\n";
        },
    );

    $loop->run;

    is_deeply($state->{paths}, [ '/drain', '/next' ],
        'chunked trailers end before the pipelined next request');
    is($state->{raw_request_hits}, 2,
        'both request heads remain on the raw native parser');
    is($state->{native_chunked_complete_hits}, 1,
        'drained chunked body notifies Perl only at completion');
    is($state->{fallback_hits}, 0,
        'drained chunked body never enters generic fallback');
};

{
    package T::RawChunkedErrorConnection;
    use parent -norequire, 'T::RawHTTPConnection';

    sub on_request ($self, $request, $response) {
        push @{$self->data->{paths}}, $request->target;
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body('SHOULD-NOT-COMPLETE');
        return;
    }

    sub _http_native_chunked_error ($self) {
        $self->data->{chunked_error_hits}++;
        return $self->SUPER::_http_native_chunked_error;
    }
}

subtest 'malformed raw chunked body fails the active request with 400' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        wire => '',
        body => '',
        paths => [],
        raw_request_hits => 0,
        fallback_hits => 0,
        native_body_hits => 0,
        native_chunked_body_hits => 0,
        chunked_error_hits => 0,
    };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawChunkedErrorConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw malformed chunked test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /upload HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Transfer-Encoding: chunked\r\n\r\n" .
                "Z\r\nBAD\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            $state->{wire} .= $bytes;
            if ($state->{wire} =~ /HTTP\/1\.1 400 /) {
                $guard->cancel;
                $stream->close;
                $server->close;
                $loop->stop;
            }
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "raw malformed chunked client failed: $error\n";
        },
    );

    $loop->run;

    is($state->{chunked_error_hits}, 1,
        'native chunked decoder reports malformed input through HTTP lifecycle');
    like($state->{wire}, qr/\AHTTP\/1\.1 400 /,
        'malformed native chunked body produces a 400 response');
    is($state->{fallback_hits}, 0,
        'malformed chunked body does not enter generic fallback');
};


{
    package T::RawBodyCloseConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
        
    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_body ($self, $request, $response, $bytes) {
        $self->data->{body_hits}++;
        $self->close;
        return;
    }
}

subtest 'reentrant close is safe inside direct raw Content-Length on_body' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { body_hits => 0 };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawBodyCloseConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw body reentrant-close test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /close-body HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Content-Length: 4\r\n\r\nDATA"
            );
        },
        on_data => sub ($stream, $bytes) {
            return;
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "raw body close client failed: $error\n";
        },
    );

    $loop->run;
    is($state->{body_hits}, 1,
        'direct raw Content-Length body callback closed the Stream once');
};

{
    package T::RawCloseConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
        
    sub _http_native_request ($self, $request) {
        $self->data->{raw_request_hits}++;
        return $self->SUPER::_http_native_request($request);
    }

    sub on_request ($self, $request, $response) {
        $self->data->{callback_hits}++;
        $self->close;
        return;
    }
}

subtest 'reentrant close is safe inside direct raw chunked on_body' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { body_hits => 0 };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawBodyCloseConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw chunked reentrant-close test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "POST /close-chunked HTTP/1.1\r\n" .
                "Host: example.test\r\n" .
                "Transfer-Encoding: chunked\r\n\r\n" .
                "4\r\nDATA\r\n0\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            return;
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "raw chunked close client failed: $error\n";
        },
    );

    $loop->run;
    is($state->{body_hits}, 1,
        'direct raw chunked body callback closed the Stream once');
};

subtest 'reentrant close is safe inside raw-provider application callback' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { raw_request_hits => 0, callback_hits => 0 };
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        data => $state,
        connection_class => 'T::RawCloseConnection',
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 2,
        on_timer => sub ($timer) {
            die "raw reentrant-close test timed out\n";
        },
    );

    Linux::Event::IO::Sock::Stream->connect(
        loop => $loop,
        host => '127.0.0.1',
        port => $server->port,
        on_ready => sub ($stream) {
            $stream->write(
                "GET /close HTTP/1.1\r\nHost: example.test\r\n\r\n"
            );
        },
        on_data => sub ($stream, $bytes) {
            return;
        },
        on_eof => sub ($stream) {
            $guard->cancel;
            $stream->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($stream, $error) {
            die "raw close client failed: $error\n";
        },
    );

    $loop->run;

    is($state->{raw_request_hits}, 1,
        'request entered through the raw native provider');
    is($state->{callback_hits}, 1,
        'application callback closed the Stream reentrantly');
};

done_testing;
