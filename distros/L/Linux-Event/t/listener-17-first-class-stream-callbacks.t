use v5.36;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);
use Test::More;

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;

{
    package T::ListenerCallbacks::Raw;
    use parent 'Linux::Event::IO::Sock::Stream';
}

{
    package T::ListenerCallbacks::Line;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
}

sub client_for ($listener, $payload) {
    socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
    connect($client,
        pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
        or die "connect: $!";
    syswrite($client, $payload) == length($payload)
        or die "syswrite: $!";
    return $client;
}

subtest 'Listener reuses one raw callback for accepted Streams' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { bytes => [], ready => 0, close => 0 };
    my $scope = 'shared';
    my $callback = sub ($stream, $bytes) {
        push @{ $stream->data->{bytes} }, "$scope:$bytes";
        $stream->close;
        $loop->stop if @{ $stream->data->{bytes} } == 2;
    };
    my $weak = $callback;
    weaken($weak);
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            class => 'T::ListenerCallbacks::Raw',
            data => $state,
            on_data => $callback,
            on_ready => sub ($stream) { $stream->data->{ready}++ },
            on_close => sub ($stream) { $stream->data->{close}++ },
        },
    );
    undef $callback;
    ok(defined($weak), 'Listener retains one shared callback CV');

    my $first = client_for($listener, 'one');
    my $second = client_for($listener, 'two');
    $loop->run;
    is_deeply($state->{bytes}, ['shared:one', 'shared:two'],
        'same lexical callback handles both accepted Streams');
    is($state->{ready}, 2,
        'propagated readiness callback runs once per accepted Stream');
    is($state->{close}, 2,
        'accepted Streams use propagated lifecycle callback');

    $listener->close;
    ok(!defined($weak),
        'closing Listener releases template after accepted Streams close');
    close $first;
    close $second;
};

subtest 'Listener propagates framed constructor callback' => sub {
    my $loop = Linux::Event::Loop->new;
    my @message;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            class => 'T::ListenerCallbacks::Line',
            on_message => sub ($stream, $value) {
                push @message, $value;
                $stream->close;
                $loop->stop;
            },
        },
    );
    my $client = client_for($listener, "line\n");
    $loop->run;
    is_deeply(\@message, ['line'],
        'methodless accepted framed Stream uses Listener callback');
    $listener->close;
    close $client;
};

subtest 'Listener validates callback templates before accepting' => sub {
    my $made = eval {
        Linux::Event::IO::Sock::Listener->new(
            host => '127.0.0.1', port => 0,
            stream => {
                class => 'T::ListenerCallbacks::Raw',
                on_message => sub { },
            },
        );
        1;
    };
    ok(!$made, 'raw accepted class rejects framed callback template');
    like($@, qr/on_message requires a framed ordered-byte class/,
        'Listener template mismatch is reported during construction');
};

done_testing;
