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
    my ($section) = $text =~ /^=head1 \Q$heading\E\n(.*?)(?=^=head1 |^=cut)/ms;
    ok defined($section), "$path documents $heading";
    return $section // '';
}

sub documents_option ($text, $option, $name) {
    like(
        $text,
        qr/(?:^=head2 \Q$option\E\s*$|=item \* C<\Q$option\E>)/m,
        "$name documents option $option",
    );
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
    my $text = source($path);
    like $text, qr/^  sub stream_tuning \(\$class\) \{/m,
        "$path demonstrates the stream_tuning class method";
    documents_option($text, $_, $path) for @stream_tuning;
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Stream.pm';
    my $text = source($path);
    like $text, qr/^  sub socket_options \(\$class\) \{/m,
        "$path demonstrates the socket_options class method";
    for my $option (qw(
        tcp_nodelay keepalive keepalive_idle keepalive_interval keepalive_count
        tcp_user_timeout send_buffer receive_buffer
    )) {
        documents_option($text, $option, $path);
    }
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Dgram.pm';
    my $text = source($path);
    like $text, qr/^  sub datagram_options \(\$class\) \{/m,
        "$path demonstrates the datagram_options class method";
    for my $option (qw(
        max_datagram_size max_datagrams_per_tick edge_triggered high_watermark
        low_watermark max_pending_bytes max_pending_datagrams reuseaddr
        reuseport broadcast v6only send_buffer receive_buffer
    )) {
        documents_option($text, $option, $path);
    }
}

{
    my $path = 'lib/Linux/Event/Kernel/Process.pm';
    my $section = pod_section($path, 'PROCESS I/O TUNING');
    like $section, qr/^  sub process_options \(\$class\) \{/m,
        "$path demonstrates the process_options class method";
    for my $option (qw(
        read_size max_reads_per_tick stdin_high_watermark stdin_low_watermark
        max_pending_stdin
    )) {
        documents_option($section, $option, $path);
    }
}

{
    my $path = 'lib/Linux/Event/IO/Sock/Listener.pm';
    my $text = source($path);
    like $text, qr/^=head1 LISTENER ACCEPTANCE TUNING\s*$/m,
        "$path has a Listener acceptance tuning section";
    like $text, qr/Linux::Event::IO::Sock::Listener->new\(/,
        "$path demonstrates constructor tuning";
    for my $option (qw(
        backlog max_accept_per_tick edge_triggered reuseaddr reuseport v6only
        bind_device
    )) {
        documents_option($text, $option, $path);
    }
    for my $option (qw(unlink unlink_on_close permissions)) {
        documents_option($text, $option, $path);
    }
    like $text, qr/C<owns_socket>/,
        "$path distinguishes constructor option owns_socket";
}

{
    my $text = source('lib/Linux/Event/Loop.pm');
    for my $method (qw(
        event_capacity set_event_capacity callback_scope_limit
        set_callback_scope_limit enable_watcher_reclaim
    )) {
        like $text, qr/^=head2 \Q$method\E(?:\([^\n]*\))?\s*$/m,
            "Loop POD documents tuning method $method";
    }
    like $text,
        qr/^=head2 event_capacity\s*\n.*?The default is 8,192 events\./ms,
        'Loop POD records event capacity default';
    like $text,
        qr/^=head2 callback_scope_limit\s*\n.*?The default is 128\./ms,
        'Loop POD records callback scope default';
    like $text, qr/\$loop->set_event_capacity\(16_384\)/,
        'Loop POD demonstrates instance-method tuning';
}

done_testing;
