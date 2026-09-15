use v5.36;
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;
use JSON::PP qw(decode_json);
use CPAN::Meta::YAML ();

my $root = File::Spec->catdir($Bin, '..');

sub _slurp ($path) {
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    my $src = <$fh>;
    close $fh;
    return $src;
}

for my $required (
    'README.md',
    'LICENSE',
    'docs/CORE.md',
    'docs/ARCHITECTURE.md',
    'docs/DEVELOPMENT-HISTORY.md',
    'docs/IO-KERNEL-ARCHITECTURE.md',
    'docs/ORDERED-BYTE-IO-DESIGN.md',
    'docs/ORDERED-BYTE-CONSUMER-ABI.md',
    'docs/ORDERED-BYTE-DEADLINES.md',
    'docs/TRANSPORT-BOUNDARY.md',
    'docs/OBJECT-LIFECYCLE.md',
    'docs/SOCKET-CONNECTIONS.md',
    'docs/LISTENER-DESIGN.md',
    'docs/TIMER-DESIGN.md',
    'docs/SIGNAL-DESIGN.md',
    'docs/EVENT-DESIGN.md',
    'docs/FIRST-CLASS-STREAM-CALLBACKS.md',
    'docs/SOCKET-CONFIGURATION.md',
    'docs/DGRAM-DESIGN.md',
    'docs/PROCESS-DESIGN.md',
    'docs/CHOOSING-A-FRAMER.md',
    'docs/FRAMING.md',
    'docs/INTROSPECTION.md',
    'bench/README.md',
    'bench/LINE-RUNTIME-COMPARISON.md',
    'bench/run-async-consumer-lifetime-bench.pl',
    'bench/run-connect-microbench.pl',
    'bench/run-listen-microbench.pl',
    'bench/run-reactor-comparison.pl',
    'bench/run-resolver-microbench.pl',
    'bench/run-signal-microbench.pl',
    'bench/run-wakeup-microbench.pl',
    'bench/run-datagram-microbench.pl',
    'bench/run-process-microbench.pl',
    'bench/run-process-pipe-drain-bench.pl',
    'bench/run-callback-batching-fairness.pl',
    'bench/run-callback-batching-microbench.pl',
    'bench/run-callback-ceiling.pl',
    'bench/run-stream-lifecycle-bench.pl',
    'bench/run-stream-microbench.pl',
    'bench/run-stream-payload-sweep.pl',
    'bench/run-tls-accept-setup-bench.pl',
    'bench/run-tls-microbench.pl',
    'bench/run-stream-transition-bench.pl',
    'bench/run-stream-watcher-state-bench.pl',
    'bench/run-framing-microbench.pl',
    'bench/run-first-class-callback-construction-bench.pl',
    'bench/run-first-class-framed-callback-bench.pl',
    'bench/run-first-class-raw-callback-bench.pl',
    'bench/run-line-runtime-comparison.pl',
    'bench/runtime-line/line-asyncio.py',
    'bench/runtime-line/line-linuxevent.pl',
    'bench/runtime-line/line-node.js',
    'bench/runtime-line/line-ruby.rb',
    'bench/run-native-framers-microbench.pl',
    'bench/run-performance-regression.pl',
    'bench/run-timer-microbench.pl',
    'bench/archive/README.md',
    'lib/Linux/Event.pm',
    'lib/Linux/Event/Address.pm',
    'lib/Linux/Event/Error.pm',
    'lib/Linux/Event/Framer.pm',
    'lib/Linux/Event/Framer/DecimalLength.pm',
    'lib/Linux/Event/Framer/Delimiter.pm',
    'lib/Linux/Event/Framer/Fixed.pm',
    'lib/Linux/Event/Framer/LengthPrefix.pm',
    'lib/Linux/Event/Framer/Netstring.pm',
    'lib/Linux/Event/Framer/U32BE.pm',
    'lib/Linux/Event/Framer/Varint.pm',
    'lib/Linux/Event/TLS.pm',
    'lib/Linux/Event/Loop.pm',
    'lib/Linux/Event/Loop/Introspection.pm',
    'lib/Linux/Event/IO.pm',
    'lib/Linux/Event/IO/Pipe.pm',
    'lib/Linux/Event/IO/TTY.pm',
    'lib/Linux/Event/IO/Sock.pm',
    'lib/Linux/Event/IO/Sock/Stream.pm',
    'lib/Linux/Event/IO/Sock/Listener.pm',
    'lib/Linux/Event/IO/Sock/Dgram.pm',
    'lib/Linux/Event/Kernel.pm',
    'lib/Linux/Event/Kernel/Timer.pm',
    'lib/Linux/Event/Kernel/Signal.pm',
    'lib/Linux/Event/Kernel/Event.pm',
    'lib/Linux/Event/Kernel/Process.pm',
    'lib/Linux/Event/_IO.pm',
    'lib/Linux/Event/_ByteStream.pm',
    'lib/Linux/Event/_ByteStream/Descriptor.pm',
    'lib/Linux/Event/_Socket.pm',
    'lib/Linux/Event/_Socket/Descriptor.pm',
    'lib/Linux/Event/_Socket/Connection.pm',
    'lib/Linux/Event/_Socket/Stream.pm',
    'lib/Linux/Event/_Socket/Listener.pm',
    'lib/Linux/Event/_Socket/Dgram.pm',
    'lib/Linux/Event/_Resolver.pm',
    'lib/Linux/Event/_SocketConfig.pm',
    'xstls/Makefile.PL',
    'xstls/TLS.xs',
    'xstls/check_openssl.c',
    'xsbytestream/Makefile.PL',
    'xsbytestream/ByteStream.xs',
    'xsconnection/Makefile.PL',
    'xsconnection/Connection.xs',
    'xsresolver/Makefile.PL',
    'xsresolver/Resolver.xs',
    'xssignal/Makefile.PL',
    'xssignal/Signal.xs',
    'xsevent/Makefile.PL',
    'xsevent/Event.xs',
    'xsdatagram/Makefile.PL',
    'xsdatagram/Datagram.xs',
    'xsprocess/Makefile.PL',
    'xsprocess/Process.xs',
    'xsprocess/check_spawn_chdir.c',
    'xslistener/Makefile.PL',
    'xslistener/Listener.xs',
    'examples/line-echo-server.pl',
    'examples/line-echo-client.pl',
    'examples/udp-echo-server.pl',
    'examples/udp-echo-client.pl',
    'examples/wakeup-thread.pl',
    'examples/process-capture.pl',
    'examples/first-class-line-echo-server.pl',
    't/architecture-20-native-consumer.t',
) {
    ok(-s File::Spec->catfile($root, split m{/}, $required), "$required is present");
}

for my $live (
    'README.md',
    'docs/CORE.md',
    'docs/ARCHITECTURE.md',
    'docs/IO-KERNEL-ARCHITECTURE.md',
    'docs/ORDERED-BYTE-IO-DESIGN.md',
    'docs/ORDERED-BYTE-CONSUMER-ABI.md',
    'docs/ORDERED-BYTE-DEADLINES.md',
    'docs/TRANSPORT-BOUNDARY.md',
    'docs/OBJECT-LIFECYCLE.md',
    'docs/SOCKET-CONNECTIONS.md',
    'docs/LISTENER-DESIGN.md',
    'docs/TIMER-DESIGN.md',
    'docs/SIGNAL-DESIGN.md',
    'docs/EVENT-DESIGN.md',
    'docs/FIRST-CLASS-STREAM-CALLBACKS.md',
    'docs/SOCKET-CONFIGURATION.md',
    'docs/DGRAM-DESIGN.md',
    'docs/PROCESS-DESIGN.md',
    'docs/CHOOSING-A-FRAMER.md',
    'docs/FRAMING.md',
    'docs/INTROSPECTION.md',
    'bench/README.md',
    'bench/LINE-RUNTIME-COMPARISON.md',
    'bench/run-async-consumer-lifetime-bench.pl',
    'bench/run-connect-microbench.pl',
    'bench/run-listen-microbench.pl',
    'bench/run-reactor-comparison.pl',
    'bench/run-resolver-microbench.pl',
    'bench/run-signal-microbench.pl',
    'bench/run-wakeup-microbench.pl',
    'bench/run-datagram-microbench.pl',
    'bench/run-process-microbench.pl',
    'bench/run-callback-ceiling.pl',
    'bench/run-stream-lifecycle-bench.pl',
    'bench/run-stream-microbench.pl',
    'bench/run-tls-microbench.pl',
    'bench/run-stream-transition-bench.pl',
    'bench/run-stream-watcher-state-bench.pl',
    'bench/run-framing-microbench.pl',
    'bench/run-first-class-callback-construction-bench.pl',
    'bench/run-first-class-framed-callback-bench.pl',
    'bench/run-first-class-raw-callback-bench.pl',
    'bench/run-line-runtime-comparison.pl',
    'bench/run-native-framers-microbench.pl',
    'bench/run-performance-regression.pl',
    'bench/run-timer-microbench.pl',
) {
    my $path = File::Spec->catfile($root, split m{/}, $live);
    my $src = _slurp($path);
    unlike($src, qr/\b(?:Phase|phase)\d+[A-Za-z]?\b/, "$live has no development-phase vocabulary");
}

my @bench_root = sort map { s{^.*/}{}r }
    grep { -f $_ }
    glob(File::Spec->catfile($root, 'bench', '*'));
my %allowed = map { $_ => 1 } qw(
    BENCHMARK-DECISIONS.md
    LINE-RUNTIME-COMPARISON.md
    README.md
    STREAM-COMPETITOR-PLAN.md
    run-async-consumer-lifetime-bench.pl
    run-connect-microbench.pl
    run-listen-microbench.pl
    run-line-runtime-comparison.pl
    run-reactor-comparison.pl
    run-stream-competitor-comparison.pl
    run-resolver-microbench.pl
    run-signal-microbench.pl
    run-wakeup-microbench.pl
    run-datagram-microbench.pl
    run-process-microbench.pl
    run-process-pipe-drain-bench.pl
    run-callback-batching-fairness.pl
    run-callback-batching-microbench.pl
    run-callback-ceiling.pl
    run-stream-lifecycle-bench.pl
    run-stream-microbench.pl
    run-stream-payload-sweep.pl
    run-tls-accept-setup-bench.pl
    run-tls-microbench.pl
    run-stream-transition-bench.pl
    run-stream-watcher-state-bench.pl
    run-framing-microbench.pl
    run-first-class-callback-construction-bench.pl
    run-first-class-framed-callback-bench.pl
    run-first-class-raw-callback-bench.pl
    run-framer-send-bench.pl
    run-native-framers-microbench.pl
    run-performance-regression.pl
    run-public-api-overhead.pl
    run-timer-microbench.pl
);
is_deeply([grep { !$allowed{$_} } @bench_root], [], 'bench root contains only current public files');
ok(!-d File::Spec->catdir($root, 'tls'),
    'TLS does not have a nested distribution tree');

for my $removed (
    'docs/STREAM-DESIGN.md',
    'docs/STREAM-DEADLINES.md',
    'docs/STREAM-CONSUMER-ABI.md',
    'docs/WAKEUP-DESIGN.md',
    'docs/DATAGRAM-DESIGN.md',
    'lib/Linux/Event/Watcher.pm',
    'lib/Linux/Event/XSLoop.pm',
    'lib/Linux/Event/XSWatcher.pm',
    'lib/Linux/Event/Connect.pm',
    'lib/Linux/Event/Connector.pm',
    'lib/Linux/Event/Listen.pm',
    'lib/Linux/Event/Listener/_Engine.pm',
    'lib/Linux/Event/Stream/Error.pm',
    'lib/Linux/Event/Stream/Framer.pm',
    'lib/Linux/Event/Stream/_Deadline.pm',
    'lib/Linux/Event/Stream/_Resolver.pm',
    'lib/Linux/Event/Stream.pm',
    'lib/Linux/Event/Stream',
    'lib/Linux/Event/Socket.pm',
    'lib/Linux/Event/Socket',
    'lib/Linux/Event/Listener.pm',
    'lib/Linux/Event/Datagram.pm',
    'lib/Linux/Event/Timer.pm',
    'lib/Linux/Event/Signal.pm',
    'lib/Linux/Event/Wakeup.pm',
    'lib/Linux/Event/Process.pm',
    'xsstream',
    'xswakeup',
) {
    ok(!-e File::Spec->catfile($root, split m{/}, $removed),
        "$removed is not part of the public surface");
}

my @engineering_history = qw(
    docs/STREAM-REVIEW-FOLLOWUPS.md
    docs/XS-ROADMAP.md
    docs/xs-reduction-roadmap.md
    bench/BENCHMARK-DECISIONS.md
    bench/run-public-api-overhead.pl
);

my $manifest_path = File::Spec->catfile($root, 'MANIFEST');
open my $manifest_fh, '<', $manifest_path
    or die "open $manifest_path: $!";
my %manifest_entry;
while (my $line = <$manifest_fh>) {
    next if $line =~ /^\s*(?:#|$)/;
    my ($path) = split /\s+/, $line, 2;
    $manifest_entry{$path} = 1;
}
close $manifest_fh;

my @root_tests = sort map { File::Spec->abs2rel($_, $root) }
    grep { -f $_ }
    glob(File::Spec->catfile($root, 't', '*.t'));
for my $path (@root_tests) {
    ok($manifest_entry{$path}, "$path is included in MANIFEST");
}

for my $path (qw(
    bench/LINE-RUNTIME-COMPARISON.md
    bench/run-line-runtime-comparison.pl
    bench/runtime-line/line-asyncio.py
    bench/runtime-line/line-linuxevent.pl
    bench/runtime-line/line-node.js
    bench/runtime-line/line-ruby.rb
)) {
    ok($manifest_entry{$path}, "$path is included in MANIFEST");
}

my $manifest_skip_path = File::Spec->catfile($root, 'MANIFEST.SKIP');
open my $manifest_skip_fh, '<', $manifest_skip_path
    or die "open $manifest_skip_path: $!";
my @manifest_skip = map { qr/$_/ }
    grep { length && !/^#/ }
    map { chomp; s/^\s+|\s+$//gr }
    <$manifest_skip_fh>;
close $manifest_skip_fh;

for my $path (@engineering_history) {
    ok(!$manifest_entry{$path}, "$path is excluded from MANIFEST");
    ok(scalar(grep { $path =~ $_ } @manifest_skip),
        "$path is excluded by MANIFEST.SKIP");
}

my $makefile_pl = _slurp(File::Spec->catfile($root, 'Makefile.PL'));
my ($public_module_block) = $makefile_pl =~
    /my \@public_modules = qw\(\s*(.*?)\s*\);/s;
ok(defined $public_module_block,
    'Makefile.PL declares the public module source of truth');
my @expected_provides = sort grep { length }
    split /\s+/, ($public_module_block // '');

my $meta_json = decode_json(
    _slurp(File::Spec->catfile($root, 'META.json'))
);
is($meta_json->{abstract},
    'Linux-native reactor, I/O, kernel events, and processes',
    'META.json has the current distribution abstract');
is_deeply([sort keys %{ $meta_json->{provides} }], \@expected_provides,
    'META.json provides exactly the Makefile.PL public taxonomy');

my $meta_yml_path = File::Spec->catfile($root, 'META.yml');
my $meta_yml_docs = CPAN::Meta::YAML->read($meta_yml_path);
ok($meta_yml_docs && @$meta_yml_docs, 'META.yml parses');
if ($meta_yml_docs && @$meta_yml_docs) {
    my $meta_yml = $meta_yml_docs->[0];
    is($meta_yml->{abstract},
        'Linux-native reactor, I/O, kernel events, and processes',
        'META.yml has the current distribution abstract');
    is_deeply([sort keys %{ $meta_yml->{provides} }], \@expected_provides,
        'META.yml provides exactly the Makefile.PL public taxonomy');
}

my $readme = _slurp(File::Spec->catfile($root, 'README.md'));
my ($stream_server_prefix) = $readme =~
    /## Stream socket server\b(.*?)package EchoConnection;/s;
ok(defined $stream_server_prefix,
    'README contains the flagship stream socket example');
if (defined $stream_server_prefix) {
    unlike($stream_server_prefix, qr/use Linux::Event::Framer\b/,
        'flagship framer declaration lives inside the stream subclass');
}

done_testing;
