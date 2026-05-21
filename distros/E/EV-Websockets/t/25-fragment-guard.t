use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;

# RFC 6455 §5.4 forbids interleaving a new data frame into an open
# fragmented message. send() and send_binary() must croak in that
# case rather than silently corrupt the wire stream. Kept in its
# own file to avoid prove harness state interactions seen when
# combined with other blocks in t/24.

my $ctx = EV::Websockets::Context->new;
my (@errors, %keep);

my $port = $ctx->listen(
    port => 0,
    on_connect => sub { $keep{srv} = $_[0] },
    on_message => sub { },
    on_close => sub { delete $keep{srv} },
);

$keep{cli} = $ctx->connect(
    url => "ws://127.0.0.1:$port",
    on_connect => sub {
        my ($c) = @_;
        $c->send_fragment("part1", 0, 0);          # text, NO_FIN
        { local $@; eval { $c->send("oops") };        push @errors, $@ // "" }
        { local $@; eval { $c->send_binary("oops") }; push @errors, $@ // "" }
        $c->send_fragment("part2", 0, 1);          # finish the fragment
        $c->close(1000);
    },
    on_close => sub { delete $keep{cli}; EV::break },
    on_error => sub { delete $keep{cli}; EV::break },
);

my $to = EV::timer(5, 0, sub { diag "timeout"; EV::break });
EV::run;

like($errors[0] // '', qr/fragmented message is in progress/,
    "send() croaks during open fragment");
like($errors[1] // '', qr/fragmented message is in progress/,
    "send_binary() croaks during open fragment");

done_testing;
