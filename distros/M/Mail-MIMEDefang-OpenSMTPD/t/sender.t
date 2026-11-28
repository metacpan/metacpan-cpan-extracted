use strict;
use warnings;
use Test::More;
use lib 't/lib';
use SmtpdHarness qw( run_filter session report filter );
use Mail::MIMEDefang qw( percent_decode );

my @pre = (
    session('S1'),
    report( 'tx-begin', 'S1', 'abcd1234' ),
);

# --- off by default --------------------------------------------------------
my $r = run_filter(
    mx    => sub { die "not expected" },
    lines => [ @pre, filter( 'mail-from', 'S1', 'T1', 'a@example.org' ) ],
);
is scalar @{ $r->{mx} }, 0, 'no -s, multiplexor not asked';

# --- sender check ----------------------------------------------------------
$r = run_filter(
    args => ['-s'],
    mx   => sub {
        my ( $cmd, $spool ) = @_;
        my @a = map { percent_decode($_) } split ' ', $cmd;
        if ( open my $fh, '>>', "$spool/../dir-existed" ) { print {$fh} ( -d $a[5] ? 1 : 0 ), "\n"; close $fh }
        return $a[1] eq '<bad@example.org>' ? "ok 0 Sender%20banned 553 5.7.1 0\n" : "ok 1 ok 250 2.1.0 0\n";
    },
    lines => [
        @pre,
        filter( 'mail-from', 'S1', 'T1', 'bad@example.org' ),
        filter( 'mail-from', 'S1', 'T2', 'good@example.org' ),
        report( 'link-disconnect', 'S1' ),
    ],
);
is_deeply $r->{out},
    [ 'filter-result|S1|T1|reject|553 5.7.1 Sender banned', 'filter-result|S1|T2|proceed' ],
    'sender accepted or rejected with the filter text';
like $r->{mx}[0],
    qr{^senderok <bad\@example\.org> 192\.0\.2\.1 mx\.example\.org client\.example\.org \S+/mdefang-\S+ abcd1234$},
    'senderok has sender, ip, name, helo, dir and qid';
open my $de, '<', "$r->{dir}/dir-existed" or die; my @de = <$de>;
is_deeply [ map { s/\s+//r } @de ], [ 1, 1 ], 'the worker can chdir to the directory';
is_deeply $r->{spool}, [], 'directory removed when the session ends';

# --- recipient check -------------------------------------------------------
$r = run_filter(
    args => ['-t'],
    mx   => sub {
        my ($cmd) = @_;
        return $cmd =~ /nobody/ ? "ok 0 No%20such%20user 550 5.1.1 0\n" : "ok 1 ok 250 2.1.0 0\n";
    },
    lines => [
        @pre,
        report( 'tx-mail', 'S1', 'abcd1234', 'ok', 'sender@example.org' ),
        filter( 'rcpt-to', 'S1', 'T1', 'first@example.net' ),
        report( 'tx-rcpt', 'S1', 'abcd1234', 'ok', 'first@example.net' ),
        filter( 'rcpt-to', 'S1', 'T2', 'nobody@example.net' ),
        report( 'tx-rcpt', 'S1', 'abcd1234', 'permfail', 'nobody@example.net' ),
        filter( 'rcpt-to', 'S1', 'T3', 'second@example.net' ),
    ],
);
is_deeply $r->{out},
    [   'filter-result|S1|T1|proceed',
        'filter-result|S1|T2|reject|550 5.1.1 No such user',
        'filter-result|S1|T3|proceed',
    ],
    'each recipient is decided separately';
my @c = map { [ map { percent_decode($_) } split ' ', $_ ] } @{ $r->{mx} };
is_deeply [ @{ $c[0] }[ 0 .. 4 ] ], [ 'recipok', '<first@example.net>', '<sender@example.org>', '192.0.2.1', 'mx.example.org' ],
    'recipok: recipient, sender, ip, name';
is $c[0][5], '<first@example.net>', 'first recipient is itself';
is $c[2][5], '<first@example.net>', 'first recipient stays the first one';
is $c[0][6], 'client.example.org', 'helo';
is_deeply [ @{ $c[0] }[ 9 .. 11 ] ], [ '?', '?', '?' ], 'mailer, host and addr are unknown';

# --- ok 2 skips the rest ---------------------------------------------------
$r = run_filter(
    args => [ '-s', '-t' ],
    mx   => sub { "ok 2 ? 250 2.1.0 0\n" },
    lines => [
        @pre,
        filter( 'mail-from', 'S1', 'T1', 'a@example.org' ),
        filter( 'rcpt-to',   'S1', 'T2', 'b@example.net' ),
    ],
);
is scalar @{ $r->{mx} }, 1, 'recipient check skipped after ok 2';

done_testing;
