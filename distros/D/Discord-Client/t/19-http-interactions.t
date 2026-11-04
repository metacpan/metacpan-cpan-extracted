use v5.26;
use warnings;
use Test2::V1;
use IO::Handle;
use JSON::PP;
use Future;
use Crypt::PK::Ed25519;
use IO::Async::Loop;
use lib 't/lib';
use TestDiscordREST ();
use Discord::Client::Interaction::Verifier;
use Discord::Client::HTTPInteractions;

sub fixture {
    my (%options) = @_;

    # Use a fresh signing key and controlled clocks for each independent HTTP scenario.
    my $signer = Crypt::PK::Ed25519->new->generate_key;
    my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
    my @errors;
    my $service = Discord::Client::HTTPInteractions->new(
        public_key => unpack( 'H*', $signer->export_key_raw('public') ),
        loop => IO::Async::Loop->new,
        clock => sub { $clock->{now} },
        wall_clock => sub { 1700000000 + $clock->{now} },
        delay => sub { $clock->delay( $_[0] ) },
        on_error => sub { push @errors, $_[0] },
        %options,
    );
    return { service => $service, clock => $clock, signer => $signer, errors => \@errors };
}

sub signed {
    my ( $fixture, $payload, $timestamp ) = @_;
    my $clock = $fixture->{clock};
    my $signer = $fixture->{signer};
    $timestamp //= 1700000000 + int( $clock->{now} );

    # Sign the exact UTF-8 bytes that the endpoint receives, including the timestamp prefix.
    my $body = ref($payload) ? JSON::PP->new->utf8->encode($payload) : $payload;
    return (
        {
            'X-Signature-Ed25519' => unpack( 'H*', $signer->sign_message( $timestamp . $body ) ),
            'X-Signature-Timestamp' => "$timestamp"
        },
        $body
    );
}

sub payload {
    my ( $id, $name ) = @_;
    return {
        id => "$id",
        application_id => '456',
        token => 'FAKE_HTTP_TOKEN',
        type => 2,
        data => { name => $name, type => 1 }
    };
}
sub json { JSON::PP->new->utf8->decode( $_[0][2][0] ) }

sub env {
    my ( $headers, $body, $streaming ) = @_;

    # The returned PSGI environment owns this stream until the application reads its body.
    open my $input, '<', \$body or die 'scalar input';
    binmode $input;
    return {
        REQUEST_METHOD => 'POST',
        CONTENT_LENGTH => length($body),
        CONTENT_TYPE => 'application/json',
        'psgi.input' => $input,
        'psgi.streaming' => $streaming,
        HTTP_X_SIGNATURE_ED25519 => $headers->{'X-Signature-Ed25519'},
        HTTP_X_SIGNATURE_TIMESTAMP => $headers->{'X-Signature-Timestamp'}
    };
}

T2->subtest(
    'exact signature and freshness before JSON/handler processing',
    sub {
        my $fixture = fixture();
        my ( $http, $clock, $errors ) = @{$fixture}{qw(service clock errors)};
        my ( $headers, $body ) = signed( $fixture, { type => 1 } );
        T2->is( json( $http->handle( $headers, $body )->get ), { type => 1 }, 'signed PING produces PONG' );
        T2->is( $http->handle( $headers, $body . ' ' )->get->[0], 401, 'body tampering rejected' );
        T2->is( $http->handle( { %$headers, 'X-Signature-Timestamp' => '1700000001' }, $body )->get->[0],
            401, 'timestamp is signed' );
        T2->is( $http->handle( {}, $body )->get->[0], 401, 'missing signature rejected' );
        T2->is( $http->handle( { %$headers, 'X-Signature-Ed25519' => '00' }, $body )->get->[0],
            401, 'malformed signature rejected' );
        ( $headers, $body ) = signed( $fixture, { type => 1 }, 1699999600 );
        T2->is( $http->handle( $headers, $body )->get->[0], 401, 'old signed request rejected by age policy' );

        # Only authenticated bytes reach JSON parsing, and parser errors must not echo them.
        ( $headers, $body ) = signed( $fixture, '{bad FAKE_HTTP_TOKEN' );
        my $bad = $http->handle( $headers, $body )->get;
        T2->is( $bad->[0], 400, 'valid signature with malformed JSON returns 400' );
        T2->unlike( $bad->[2][0], qr/FAKE_HTTP_TOKEN/, 'parser error never echoes body' );
        $http->close->get;
        T2->is( $clock->timer_count, 0, 'the scenario leaves no handler timers' );
    }
);

T2->subtest(
    'HTTP-only slash reply and duplicate request replay',
    sub {
        my $fixture = fixture();
        my ( $http, $clock, $errors ) = @{$fixture}{qw(service clock errors)};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->reply("Pong \x{2603}!");
            }
        );
        my ( $headers, $body ) = signed( $fixture, payload( 100, 'ping' ) );
        my $response = $http->handle( $headers, $body )->get;
        T2->is( $response->[0], 200, 'HTTP inline response' );
        T2->is( json($response)->{data}{content}, "Pong \x{2603}!", 'UTF-8 response' );
        T2->is( $calls, 1, 'handler invoked once' );

        # A duplicate receives an independent response snapshot without repeating side effects.
        $response->[2][0] = 'changed';
        my $again = $http->handle( $headers, $body )->get;
        T2->is( json($again)->{type}, 4, 'cached response copied for retry' );
        T2->is( $calls, 1, 'signed duplicate never invokes twice' );
        T2->is( $http->rest->stats->{http_started} // 0, 0, 'initial HTTP response needs no REST/Gateway I/O' );
        $http->close->get;
        T2->is( $clock->timer_count, 0, 'the scenario leaves no handler timers' );
    }
);

T2->subtest(
    'PSGI synchronous and delayed response contracts',
    sub {
        my $fixture = fixture();
        my ( $http, $clock, $errors ) = @{$fixture}{qw(service clock errors)};
        my $app = $http->psgi_app;
        my ( $headers, $body ) = signed( $fixture, { type => 1 } );
        my $response = $app->( env( $headers, $body, 0 ) );
        T2->ref_ok( $response, 'ARRAY', 'immediate response works on ordinary PSGI' );
        T2->is( json($response)->{type}, 1, 'PSGI PONG' );

        # A delayed reply advances only when the host drives the event loop.
        $http->command(
            slow => description => 'Slow',
            handler => sub {
                my ($interaction) = @_;
                return $clock->delay(1)->then( sub { $interaction->reply('later') } );
            }
        );
        ( $headers, $body ) = signed( $fixture, payload( 101, 'slow' ) );
        my $delayed = $app->( env( $headers, $body, 1 ) );
        T2->ref_ok( $delayed, 'CODE', 'pending response uses PSGI delayed callback' );
        my $result;
        $delayed->( sub { $result = $_[0] } );
        T2->ok( !defined($result), 'application never starts the loop implicitly' );
        $clock->advance(1);
        T2->is( json($result)->{data}{content}, 'later', 'host-driven loop completes delayed response' );

        # Hosts without delayed-response support must reject and cancel asynchronous work.
        ( $headers, $body ) = signed( $fixture, payload( 102, 'slow' ) );
        T2->is( $app->( env( $headers, $body, 0 ) )->[0], 503, 'async work requires streaming PSGI support' );
        T2->is( $clock->timer_count, 0, 'unsupported async request cancels its timers' );

        # Reject unsupported methods and truncated bodies before dispatch.
        my $get = env( $headers, $body, 0 );
        $get->{REQUEST_METHOD} = 'GET';
        T2->is( $app->($get)->[0], 405, 'only POST accepted' );
        my $short = env( $headers, $body, 0 );
        $short->{CONTENT_LENGTH}++;
        T2->is( $app->($short)->[0], 400, 'truncated input rejected' );
        $http->close->get;
        T2->is( $clock->timer_count, 0, 'the scenario leaves no handler timers' );
    }
);

T2->subtest(
    'initial response deadline and shutdown',
    sub {
        my $fixture = fixture();
        my ( $http, $clock, $errors ) = @{$fixture}{qw(service clock errors)};
        $http->command( unanswered => description => 'Unanswered', handler => sub { } );
        my ( $headers, $body ) = signed( $fixture, payload( 103, 'unanswered' ) );
        my $response_future = $http->handle( $headers, $body );

        # Unanswered requests must settle at the initial-response deadline.
        $clock->advance(3);
        T2->is( $response_future->get->[0], 504, 'unanswered interaction has bounded deadline' );
        T2->unlike( join( ' ', @$errors ), qr/FAKE_HTTP_TOKEN/, 'handler/deadline diagnostics sanitized' );

        # Shutdown also settles pending responses and releases their deadline timers.
        ( $headers, $body ) = signed( $fixture, payload( 104, 'unanswered' ) );
        my $pending = $http->handle( $headers, $body );
        $http->close->get;
        T2->is( $pending->get->[0], 503, 'shutdown finishes pending HTTP responses' );
        T2->is( $clock->timer_count, 0, 'shutdown cleans all timers' );
        T2->is( $http->handle( $headers, $body )->get->[0], 503, 'closed endpoint rejects work' );
    }
);

T2->subtest(
    'signature freshness includes the exact boundary in both directions',
    sub {
        for my $case (
            { name => 'old boundary', offset => -300, status => 200 },
            { name => 'future boundary', offset => 300, status => 200 },
            { name => 'too old', offset => -301, status => 401 },
            { name => 'too far in future', offset => 301, status => 401 },
            )
        {
            T2->subtest(
                $case->{name},
                sub {
                    my $fixture = fixture();
                    my ( $headers, $body ) = signed( $fixture, { type => 1 }, 1700000000 + $case->{offset} );
                    T2->is( $fixture->{service}->handle( $headers, $body )->get->[0],
                        $case->{status}, 'the signed timestamp is checked against the configured clock' );
                    $fixture->{service}->close->get;
                }
            );
        }
    }
);

T2->subtest(
    'invalid signatures never invoke a command handler',
    sub {
        my $fixture = fixture();
        my $http = $fixture->{service};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );
        my ( $headers, $body ) = signed( $fixture, payload( 200, 'ping' ) );

        # Signature rejection must precede handler side effects and token-only REST.
        T2->is( $http->handle( $headers, $body . ' ' )->get->[0], 401, 'tampered command is rejected' );
        T2->is( $calls, 0, 'rejection performs no application work' );
        T2->is( $http->rest->stats->{http_started} // 0, 0, 'rejection performs no REST request' );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'the valid command still works' );
        T2->is( $calls, 1, 'only the valid command invokes its handler' );
        $http->close->get;
    }
);

T2->subtest(
    'deduplication capacity recovers after entries expire',
    sub {
        my $fixture = fixture( max_seen => 1 );
        my $http = $fixture->{service};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );
        my ( $headers, $body ) = signed( $fixture, payload( 300, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'first command reserves replay capacity' );
        ( $headers, $body ) = signed( $fixture, payload( 301, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 503, 'a new command is refused while full' );
        T2->is( $calls, 1, 'capacity rejection does not run the handler' );

        # Expiry releases process-local capacity without weakening signature freshness.
        $fixture->{clock}->advance(900);
        ( $headers, $body ) = signed( $fixture, payload( 301, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'freshly signed command succeeds after expiry' );
        T2->is( $calls, 2, 'capacity recovery invokes the new handler exactly once' );
        $http->close->get;
    }
);

T2->subtest(
    'body size rejects oversized signed input before invoking its handler',
    sub {
        my $body = JSON::PP->new->utf8->encode( payload( 400, 'ping' ) );
        my $fixture = fixture( max_body => length($body) );
        my $http = $fixture->{service};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );

        # Both inputs are correctly signed JSON; only their byte lengths differ.
        my ( $headers, $oversized ) = signed( $fixture, $body . ' ' );
        T2->is( $http->handle( $headers, $oversized )->get->[0], 413, 'one byte above the limit is rejected' );
        T2->is( $calls, 0, 'body rejection has no handler side effects' );
        ( $headers, $body ) = signed( $fixture, $body );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'the exact byte limit is accepted' );
        T2->is( $calls, 1, 'only the permitted request invokes the handler' );
        $http->close->get;
    }
);

T2->subtest(
    'pending capacity includes deferred handlers and recovers when work finishes',
    sub {
        my $fixture = fixture( max_pending => 1 );
        my $http = $fixture->{service};
        my @work;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                $_[0]->defer;
                my $work = Future->new;
                push @work, $work;
                return $work;
            }
        );
        my ( $headers, $body ) = signed( $fixture, payload( 500, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'deferral is sent immediately' );
        T2->is( $http->dispatcher->stats->{pending}, 1, 'background work still occupies capacity' );
        ( $headers, $body ) = signed( $fixture, payload( 501, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 503, 'another handler cannot start while full' );
        T2->is( scalar(@work), 1, 'rejection does not start extra background work' );

        $work[0]->done;
        T2->is( $http->dispatcher->stats->{pending}, 0, 'completion releases capacity' );
        T2->is( $http->handle( $headers, $body )->get->[0],
            200, 'the same rejected request succeeds after recovery' );
        T2->is( scalar(@work), 2, 'one additional handler starts after recovery' );
        $http->close->get;
        T2->ok( $work[1]->is_cancelled, 'shutdown cancels deferred background work' );
        T2->is( $fixture->{clock}->timer_count, 0, 'shutdown leaves no handler timers' );
    }
);

T2->subtest(
    'response eviction admits new IDs without repeating evicted handlers',
    sub {
        my $fixture = fixture( max_replay => 1, max_seen => 3, replay_ttl => 10 );
        my $http = $fixture->{service};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply("Pong $calls");
            }
        );

        # Response storage and ID protection have independent bounds.
        for my $id ( 600, 601 ) {
            my ( $headers, $body ) = signed( $fixture, payload( $id, 'ping' ) );
            T2->is( $http->handle( $headers, $body )->get->[0], 200, 'new ID runs despite full response storage' );
        }
        T2->is( $http->stats->{replay_entries}, 1, 'only one completed response is stored' );
        T2->is( $http->stats->{seen_entries}, 2, 'both IDs remain protected' );
        my ( $headers, $body ) = signed( $fixture, payload( 600, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 409, 'evicted response cannot repeat its handler' );
        ( $headers, $body ) = signed( $fixture, payload( 601, 'ping' ) );
        T2->is( json( $http->handle( $headers, $body )->get )->{data}{content},
            'Pong 2', 'latest response is replayed' );
        T2->is( $calls, 2, 'neither duplicate executes again' );

        # Expiry releases both bytes and ID protection on the next signed request.
        $fixture->{clock}->advance(10);
        ( $headers, $body ) = signed( $fixture, payload( 602, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'new request succeeds at configured expiry' );
        T2->is( $http->stats->{seen_entries}, 1, 'expired IDs are removed' );
        $http->close->get;
    }
);

T2->subtest(
    'default response capacity accepts more than 1024 completed interactions',
    sub {
        my $fixture = fixture();
        my $http = $fixture->{service};
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );

        # Run a burst without advancing the clock or weakening replay protection.
        my @statuses;
        for my $id ( 1000 .. 2024 ) {
            my ( $headers, $body ) = signed( $fixture, payload( $id, 'ping' ) );
            push @statuses, $http->handle( $headers, $body )->get->[0];
        }
        T2->is( [ grep { $_ != 200 } @statuses ], [], 'every new interaction is admitted' );
        T2->is( $calls, 1025, 'every handler executes once' );
        T2->is( $http->stats->{replay_entries}, 1024, 'response storage stays bounded' );
        my ( $headers, $body ) = signed( $fixture, payload( 1000, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 409, 'the oldest ID remains protected after eviction' );
        T2->is( $calls, 1025, 'eviction does not cause repeated side effects' );
        $http->close->get;
    }
);

T2->subtest(
    'running deferred handlers remain protected beyond replay expiry',
    sub {
        my $fixture = fixture( max_replay => 1, max_seen => 1, replay_ttl => 1 );
        my $http = $fixture->{service};
        my $work = Future->new;
        my $calls = 0;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->defer;
                return $work;
            }
        );

        # A completed initial reply does not release a still-running handler's ID.
        my ( $headers, $body ) = signed( $fixture, payload( 700, 'ping' ) );
        T2->is( json( $http->handle( $headers, $body )->get )->{type}, 5, 'initial response is deferred' );
        $fixture->{clock}->advance(2);
        ( $headers, $body ) = signed( $fixture, payload( 700, 'ping' ) );
        T2->is( json( $http->handle( $headers, $body )->get )->{type},
            5, 'duplicate still receives the pending reply' );
        T2->is( $calls, 1, 'expiry never repeats a running handler' );
        ( $headers, $body ) = signed( $fixture, payload( 701, 'ping' ) );
        T2->is( $http->handle( $headers, $body )->get->[0], 503,
            'active ID still occupies deduplication capacity' );
        $work->done;
        T2->is( $http->handle( $headers, $body )->get->[0], 200, 'completed expired work releases capacity' );
        T2->is( $calls, 2, 'new request runs once after completion' );
        $http->close->get;
    }
);

T2->subtest(
    'concurrent duplicates share work and handler failures remain protected',
    sub {
        my $fixture = fixture();
        my $http = $fixture->{service};
        my $calls = 0;
        my $work = Future->new;
        $http->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $work;
            }
        );

        # A caller's cancellation cannot cancel the shared operation for other callers.
        my ( $headers, $body ) = signed( $fixture, payload( 800, 'ping' ) );
        my $first = $http->handle( $headers, $body );
        my $second = $http->handle( $headers, $body );
        $first->cancel;
        T2->ok( !$work->is_ready && !$second->is_ready, 'only the caller waiter is cancelled' );
        T2->is( $calls, 1, 'concurrent delivery invokes once' );

        # Even a handler failure named queue_full is not an admission rejection.
        $work->fail( 'application side effect may have happened', 'queue_full' );
        $fixture->{clock}->advance(3);
        T2->ok( $second->is_ready, 'failed unanswered work settles at the deadline' );
        T2->is( $second->get->[0], 500, 'handler failure produces a server error' );
        T2->is( $http->handle( $headers, $body )->get->[0], 500, 'retry replays the handler failure' );
        T2->is( $calls, 1, 'ambiguous side effects cannot run twice' );
        $http->close->get;
    }
);

T2->done_testing;
