# EREQINEOF and EREQINBUFLIMIT.
use warnings;
use strict;
use t::share;

@CheckPoint = (
    [ 'reader', 0, EREQINEOF        ], 'reader: EREQINEOF',
    [ 'reader', 0, EREQINBUFLIMIT   ], 'reader: EREQINBUFLIMIT',
    [ 'reader', IN, '123'           ], 'reader: IN "123"',
);
plan tests => @CheckPoint/2;

socketpair my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
nonblocking($server);
nonblocking($client);
my $r = IO::Stream->new({
    fh          => $server,
    cb          => \&reader,
    wait_for    => 0,
});
my $w = IO::Stream->new({
    fh          => $client,
    cb          => \&writer,
    wait_for    => 0,
});

$w->write('1');
EV::loop;

$r->{wait_for} = EOF;
$w->write('2');
EV::loop;

$r->{wait_for} = IN;
$w->write('3');
EV::loop;


sub reader {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err || $io->{in_buf});
    EV::unloop;
}

sub writer {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
}


