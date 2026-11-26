use strict;
use warnings;
use Test::More;
use EV;

# The blocking resolver fails before any I/O, as a refused loopback connect
# does on the BSDs: on_error must still come from the loop, after new().
BEGIN { unshift @INC, sub { die "no EV::cares here\n" if $_[1] eq 'EV/cares.pm'; return } }
use EV::ClickHouse;

for my $case ([ 'unresolvable host', 'nonexistent.invalid', 9000 ],
              [ 'refused port',      '127.0.0.1',           1    ]) {
    my ($what, $host, $port) = @$case;
    my ($ch, $err, $had_ch);
    $ch = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'native', connect_timeout => 5,
        on_error => sub { $err = $_[0]; $had_ch = defined $ch; EV::break },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok(defined $err, "$what: on_error fired") or next;
    ok($had_ch, "$what: on_error ran after new() returned");
    $ch->finish if $ch;
}

done_testing;
