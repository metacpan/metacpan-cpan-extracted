use strict;
use warnings;
use Test::More;
use File::Copy qw( copy );
use lib 't/lib';
use SmtpdHarness qw( run_filter session report filter );
use Mail::MIMEDefang qw( percent_decode );

# A fake multiplexor: remembers what the filter wrote and answers a scan with
# whatever RESULTS/NEWBODY the test wants.
sub scanner {
    my (%o) = @_;
    return sub {
        my ( $cmd, $spool ) = @_;
        my ( $what, $qid, $dir ) = map { percent_decode($_) } split ' ', $cmd;
        return "ok 1 ok 250 2.1.0 0\n" if $what ne 'scan';
        for my $f (qw( COMMANDS HEADERS INPUTMSG )) {
            copy( "$dir/$f", "$spool/../cap.$f" );
        }
        if ( defined $o{results} ) {
            open my $fh, '>', "$dir/RESULTS" or die;
            print {$fh} $o{results};
            close $fh;
        }
        if ( defined $o{newbody} ) {
            open my $fh, '>', "$dir/NEWBODY" or die;
            print {$fh} $o{newbody};
            close $fh;
        }
        return $o{answer} // "ok\n";
    };
}

sub transaction {
    my (%o) = @_;
    my $msg = $o{message}
        // [ 'Received: from x', 'Subject: hi there', 'From: a@example.org', '', 'line one', '..dotted', 'last' ];
    my $t = 0;
    return (
        session( 'S1', %{ $o{session} // {} } ),
        report( 'tx-begin',    'S1', 'abcd1234' ),
        report( 'tx-mail',     'S1', 'abcd1234', 'ok', 'sender@example.org' ),
        ( map { report( 'tx-rcpt', 'S1', 'abcd1234', 'ok', $_ ) } @{ $o{rcpt} // ['r1@example.net'] } ),
        report( 'tx-envelope', 'S1', 'abcd1234', 'abcd123400000001' ),
        ( map { filter( 'data-line', 'S1', 'D' . ++$t, $_ ) } @{$msg}, '.' ),
        filter( 'commit', 'S1', 'C1' ),
    );
}

sub body_of {
    my ($r) = @_;
    return [ map { /^filter-dataline\|S1\|[^|]+\|(.*)$/ ? $1 : () } @{ $r->{out} } ];
}

sub slurp { open my $fh, '<', $_[0] or return; local $/; return <$fh> }

# --- untouched message -----------------------------------------------------
my $r = run_filter( args => ['-X'], mx => scanner( results => '' ), lines => [ transaction() ] );
is_deeply body_of($r),
    [ 'Received: from x', 'Subject: hi there', 'From: a@example.org', '', 'line one', '..dotted', 'last', '.' ],
    'message passes through unchanged, dot-stuffing preserved';
is $r->{out}[-1], 'filter-result|S1|C1|proceed', 'accepted at commit';
is_deeply $r->{spool}, [], 'spool directory removed';

my $in = slurp("$r->{dir}/cap.INPUTMSG");
like $in, qr/^\.dotted$/m, 'INPUTMSG is not dot-stuffed';
like slurp("$r->{dir}/cap.COMMANDS"), qr/^Uhi%20there$/m, 'subject is unfolded and has no leading space';

# --- X-Scanned-By ----------------------------------------------------------
$r = run_filter( mx => scanner( results => '' ), lines => [ transaction() ] );
like body_of($r)->[3], qr/^X-Scanned-By: MIMEDefang \S+ on 192\.0\.2\.2$/, 'X-Scanned-By added after the headers';

# --- header changes --------------------------------------------------------
$r = run_filter(
    args => ['-X'],
    mx   => scanner(
        results => "HX-Spam-Score 5.2\nN X-Top 0 first\nISubject 1 changed%20subject\nJReceived 1\n"
    ),
    lines => [ transaction() ],
);
is_deeply body_of($r),
    [ 'X-Top: first', 'Subject: changed subject', 'From: a@example.org', 'X-Spam-Score: 5.2', '',
      'line one', '..dotted', 'last', '.' ],
    'H, N, I and J all work';

# --- new body and content type --------------------------------------------
$r = run_filter(
    args => ['-X'],
    mx   => scanner( results => "C\nMmultipart/mixed;%20boundary=\"b\"\n", newbody => "--b\n.leading dot\n--b--\n" ),
    lines => [ transaction() ],
);
is_deeply body_of($r),
    [ 'Received: from x', 'Subject: hi there', 'From: a@example.org', 'MIME-Version: 1.0',
      'Content-Type: multipart/mixed; boundary="b"', '', '--b', '..leading dot', '--b--', '.' ],
    'NEWBODY is dot-stuffed and Content-Type replaced';

# --- rejections ------------------------------------------------------------
$r = run_filter(
    mx    => scanner( results => "B554 5.7.1 Virus%20found\nHX-Ignored 1\n" ),
    lines => [ transaction() ],
);
is $r->{out}[-1], 'filter-result|S1|C1|reject|554 5.7.1 Virus found', 'B rejects with the filter text';
is_deeply $r->{spool}, [], 'spool removed after a rejection';

$r = run_filter( mx => scanner( results => "T451 4.7.1 Come%20back%20later\n" ), lines => [ transaction() ] );
is $r->{out}[-1], 'filter-result|S1|C1|reject|451 4.7.1 Come back later', 'T tempfails';

# --- failures --------------------------------------------------------------
$r = run_filter( mx => scanner( answer => "error: worker died\n" ), lines => [ transaction() ] );
is $r->{out}[-1], 'filter-result|S1|C1|reject|451 4.3.0 Temporary failure, please try again later.',
    'multiplexor error is a tempfail, not a permanent 550';

$r = run_filter( mx => sub { undef }, lines => [ transaction() ] );
is $r->{out}[-1], 'filter-result|S1|C1|reject|451 4.3.0 Temporary failure, please try again later.',
    'no answer from the multiplexor';

$r = run_filter( mx => scanner( answer => "ok\n" ), lines => [ transaction() ] );
is $r->{out}[-1], 'filter-result|S1|C1|reject|451 4.3.0 Temporary failure, please try again later.',
    'a missing RESULTS file must not deliver an empty message';

# --- unsupported requests are only logged ---------------------------------
$r = run_filter( args => ['-X'], mx => scanner( results => "Rextra\@example.org\nSgone\@example.org\nfnew\@example.org\nQwhy\n" ),
    lines => [ transaction() ] );
is $r->{out}[-1], 'filter-result|S1|C1|proceed', 'unsupported actions do not stop delivery';

# --- COMMANDS: every recipient, TLS and authentication macros --------------
$r = run_filter(
    args  => ['-X'],
    mx    => scanner( results => '' ),
    lines => [
        transaction(
            rcpt    => [ 'a@example.net', 'b@example.net' ],
            session => { tls => 'TLSv1.3:AEAD-AES256-GCM-SHA384:256', user => 'alice' },
        )
    ],
);
my $cmds = slurp("$r->{dir}/cap.COMMANDS");
like $cmds, qr/^S<sender\@example\.org>$/m, 'sender';
like $cmds, qr/^R<a\@example\.net> \? \? \?\nR<b\@example\.net> \? \? \?$/m, 'all recipients';
like $cmds, qr/^=tls_version TLSv1\.3$/m,   'tls version macro';
like $cmds, qr/^=cipher AEAD-AES256-GCM-SHA384$/m, 'cipher macro';
like $cmds, qr/^=cipher_bits 256$/m,         'cipher bits macro';
like $cmds, qr/^=auth_authen alice$/m,       'auth macro';
like $cmds, qr/^I192\.0\.2\.1$/m,             'relay address';
like $cmds, qr/\nF\n\z/,                      'terminated';

# --- spool cleanup when the transaction never commits ----------------------
{
    my @t = transaction();
    pop @t;    # no commit
    push @t, report( 'tx-rollback', 'S1', 'abcd1234' );
    $r = run_filter( mx => scanner( results => '' ), lines => \@t );
    is_deeply $r->{spool}, [], 'rollback removes the spool directory';

    @t = transaction();
    pop @t;
    push @t, report( 'link-disconnect', 'S1' );
    $r = run_filter( mx => scanner( results => '' ), lines => \@t );
    is_deeply $r->{spool}, [], 'disconnect removes the spool directory';
}

done_testing;
