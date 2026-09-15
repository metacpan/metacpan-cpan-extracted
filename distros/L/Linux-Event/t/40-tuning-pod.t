use v5.36;
use strict;
use warnings;

use Test::More;

sub source ($path) {
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

sub pod_section ($path, $heading) {
    my $text = source($path);
    my ($section) = $text =~ /^=head2 \Q$heading\E\n(.*?)(?=^=head[12] |^=cut)/ms;
    ok defined($section), "$path documents $heading";
    return $section // '';
}

my @stream_tuning = qw(
    read_size read_budget_bytes read_batch_bytes message_batch_size max_buffer
    high_watermark low_watermark max_pending_bytes idle_timeout read_timeout
    write_timeout
);

for my $path (qw(
    lib/Linux/Event/IO/Sock/Stream.pm
    lib/Linux/Event/IO/Pipe.pm
    lib/Linux/Event/IO/TTY.pm
)) {
    my $section = pod_section($path, 'stream_tuning');
    like $section, qr/^  sub stream_tuning \(\$class\) \{/m,
        "$path demonstrates the stream_tuning class method";
    for my $option (@stream_tuning) {
        like $section, qr/=item \* C<\Q$option\E>/,
            "$path lists stream option $option";
    }
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Stream.pm';
    my $section = pod_section($path, 'socket_options');
    like $section, qr/^  sub socket_options \(\$class\) \{/m,
        "$path demonstrates the socket_options class method";
    for my $option (qw(
        tcp_nodelay keepalive keepalive_idle keepalive_interval keepalive_count
        tcp_user_timeout send_buffer receive_buffer
    )) {
        like $section, qr/=item \* C<\Q$option\E>/,
            "$path lists socket option $option";
    }
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Dgram.pm';
    my $section = pod_section($path, 'datagram_options');
    like $section, qr/^  sub datagram_options \(\$class\) \{/m,
        "$path demonstrates the datagram_options class method";
    for my $option (qw(
        max_datagram_size max_datagrams_per_tick edge_triggered high_watermark
        low_watermark max_pending_bytes max_pending_datagrams reuseaddr
        reuseport broadcast v6only send_buffer receive_buffer
    )) {
        like $section, qr/=item \* C<\Q$option\E>/,
            "$path lists datagram option $option";
    }
}

{
    my $path = 'lib/Linux/Event/Kernel/Process.pm';
    my $section = pod_section($path, 'process_options');
    like $section, qr/^  sub process_options \(\$class\) \{/m,
        "$path demonstrates the process_options class method";
    for my $option (qw(
        read_size max_reads_per_tick stdin_high_watermark stdin_low_watermark
        max_pending_stdin
    )) {
        like $section, qr/=item \* C<\Q$option\E>/,
            "$path lists process option $option";
    }
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Listener.pm';
    my $section = pod_section($path, 'Listener acceptance tuning');
    like $section, qr/Linux::Event::IO::Sock::Listener->new\(/,
        "$path demonstrates constructor tuning";
    for my $option (qw(
        backlog max_accept_per_tick edge_triggered reuseaddr reuseport v6only
        bind_device
    )) {
        like $section, qr/=item \* C<\Q$option\E>/,
            "$path lists listener option $option";
    }
    for my $option (qw(unlink unlink_on_close permissions owns_socket)) {
        like $section, qr/C<\Q$option\E>/,
            "$path distinguishes constructor option $option";
    }
}

{
    my $text = source('lib/Linux/Event/Loop.pm');
    for my $method (qw(
        event_capacity set_event_capacity callback_scope_limit
        set_callback_scope_limit enable_watcher_reclaim
    )) {
        like $text, qr/C<\Q$method\E(?:\([^>]*\))?>/,
            "Loop POD documents tuning method $method";
    }
    like $text, qr/event-array capacity, default\n8,192/,
        'Loop POD records event capacity default';
    like $text, qr/temporary scope, default 128/,
        'Loop POD records callback scope default';
    like $text, qr/\$loop->set_event_capacity\(16_384\)/,
        'Loop POD demonstrates instance-method tuning';
}

done_testing;
