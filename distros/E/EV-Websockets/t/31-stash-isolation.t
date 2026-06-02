use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Each connection's stash is independent. The server tags every connection with
# its own id and per-connection hit counter; if stashes leaked between conns the
# ids would collide or the counts would not both be 1.

my $ctx = EV::Websockets::Context->new();
my %keep;
my $next_id = 0;

my $port = $ctx->listen(
    port       => 0,
    on_connect => sub {
        my ($c) = @_;
        $c->stash->{id}   = ++$next_id;
        $c->stash->{hits} = 0;
    },
    on_message => sub {
        my ($c) = @_;
        $c->stash->{hits}++;
        $c->send($c->stash->{id} . ":" . $c->stash->{hits});
    },
    on_close => sub { },
);

my %reply;
my $done = 0;
for my $tag (qw(A B)) {
    $keep{$tag} = $ctx->connect(
        url        => "ws://127.0.0.1:$port",
        on_connect => sub { $_[0]->send("hi") },
        on_message => sub {
            my ($c, $d) = @_;
            $reply{$tag} = $d;
            $c->close(1000);
            EV::break if ++$done == 2;
        },
        on_error   => sub { diag "error: $_[1]"; EV::break },
    );
}

my $to = EV::timer(15, 0, sub { diag "Timeout"; EV::break });
EV::run;

is(scalar(keys %reply), 2, "both connections got a reply");
like($reply{A} // '', qr/^\d+:1$/, "conn A: own hit counter at 1 (got: " . ($reply{A} // 'undef') . ")");
like($reply{B} // '', qr/^\d+:1$/, "conn B: own hit counter at 1 (got: " . ($reply{B} // 'undef') . ")");
my ($ida) = ($reply{A} // '') =~ /^(\d+):/;
my ($idb) = ($reply{B} // '') =~ /^(\d+):/;
isnt($ida // 'x', $idb // 'y', "connections have distinct stash ids ($ida vs $idb)");

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
