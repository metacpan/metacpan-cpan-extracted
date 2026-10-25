#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

use FindBin::libs;
use IO::Socket::IP;
use Socket;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Milter::Client qw{:constants :protocol split_message};
use FakeMilter     qw{fake_milter packet};

# A fake milter on the other end of a socketpair: reads one packet per command, and answers each with the next scripted reply.
# A reply of undef means say nothing; running out of replies hangs up.
sub converse {
    my ( $opts, $replies, @cmds ) = @_;
    socketpair( my $client, my $milter, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair: $!";
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
        close $client or die "close: $!";
        foreach my $reply (@$replies) {
            read( $milter, my $buf, 4 ) == 4 or last;
            read( $milter, $buf,    unpack( 'N', $buf ) );
            next unless defined $reply;
            syswrite( $milter, pack( 'N a*', length($_), $_ ) ) for ( ref $reply ? @$reply : $reply );
        }
        close $milter or die "close: $!";
        exit 0;
    }
    close $milter or die "close: $!";
    my @res = Milter::Client::sendmail( $client, ( $opts ? $opts : () ), @cmds );
    close $client or die "close: $!";
    waitpid( $pid, 0 );
    return @res;
}

my @ends = ( [SMFIC_EOH], [SMFIC_BODYEOB] );

is( [ converse( undef, [ SMFIR_CONTINUE, SMFIR_ACCEPT ], @ends ) ], [ SMFIR_ACCEPT, '', [] ], 'final reply returned' );

is(
    [ converse( undef, [ SMFIR_CONTINUE, [ SMFIR_ADDHEADER . "X-Spam\0yes\0", SMFIR_PROGRESS, SMFIR_ACCEPT ] ], @ends ) ],
    [ SMFIR_ACCEPT, '', [ [ SMFIR_ADDHEADER, "X-Spam\0yes" ] ] ],
    'modifications collected ahead of the final reply, progress dropped'
);

is( [ converse( { timeout => 0.2 }, [ SMFIR_CONTINUE, undef, 'unused' ], @ends ) ], [ CLIENT_TIMEOUT, undef, [] ], 'silence is a timeout when asked' );
is( [ converse( { timeout => 0.2 }, [SMFIR_CONTINUE],                    @ends ) ], [ CLIENT_EOF,     undef, [] ], 'hanging up is EOF when asked' );
is( [ converse( undef, [SMFIR_CONTINUE], @ends ) ], [ SMFIR_CONTINUE, undef, [] ], 'without options, both are presumed CONTINUE' );

is( [ converse( { timeout => 0.2 }, [ SMFIR_CONTINUE, undef, SMFIR_ACCEPT ], [SMFIC_EOH], [SMFIC_QUIT], [SMFIC_BODYEOB] ) ], [ SMFIR_ACCEPT, '', [] ], 'no reply is waited for after QUIT' );

subtest 'macros' => sub {
    socketpair( my $client, my $milter, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair: $!";
    my $pid = fork() // die "fork: $!";
    if ( !$pid ) {
        close $client or die "close: $!";

        # Read the macro packet, say nothing, then answer the next command with what the macro held
        read( $milter, my $len,    4 );
        read( $milter, my $packet, unpack( 'N', $len ) );
        my ( $cmd, $for, @pairs ) = unpack( 'A A (Z*)*', $packet );
        read( $milter, $len, 4 );
        read( $milter, $len, unpack( 'N', $len ) );
        my $reply = SMFIR_REPLYCODE . "550 5.7.1 $cmd $for @pairs\0";
        syswrite( $milter, pack( 'N a*', length($reply), $reply ) );
        exit 0;
    }
    close $milter or die "close: $!";
    my @res = Milter::Client::sendmail( $client, { timeout => 0.5 }, [ SMFIC_MACRO, SMFIC_MAIL, i => 'Q1', j => 'host' ], [SMFIC_EOH] );
    waitpid( $pid, 0 );
    is( [ @res[ 0, 1 ] ], [ SMFIR_REPLYCODE, '550 5.7.1 D M i Q1 j host' ], 'a macro packs its command and name/value pairs, and no reply is waited for' );
};

subtest 'negotiation' => sub {
    my $eom  = { E => [ packet(SMFIR_ACCEPT) ] };
    my @cmds = Milter::Client::conversation( "Subject: s\n\nx\n", { macros => { connect => { j => 'mta.test.test' } } } );

    my ( $path, $done ) = fake_milter( protocol => SMFIP_NOHELO | SMFIP_NOHDRS, replies => $eom );
    my ($code) = Milter::Client::sendmail( Milter::Client::milter_socket($path), { timeout => 1 }, @cmds );
    my @letters = map { $_->[0] } $done->();
    is( $code,                                                        SMFIR_ACCEPT, 'the conversation reaches the verdict' );
    is( [ grep { $_ eq SMFIC_HELO || $_ eq SMFIC_HEADER } @letters ], [],           'a step the milter left out is not sent' );
    ok( ( grep { $_ eq SMFIC_MAIL } @letters ), '... and the rest are' );

    # NR_CONN and NR_MAIL are 0x5000, whose last byte is a NUL: the negotiation must keep it to be read at all
    ( $path, $done ) = fake_milter( protocol => SMFIP_NR_CONN | SMFIP_NR_MAIL, no_reply => [ SMFIC_CONNECT, SMFIC_MAIL ], replies => $eom );
    ($code) = Milter::Client::sendmail( Milter::Client::milter_socket($path), { timeout => 1 }, @cmds );
    $done->();
    is( $code, SMFIR_ACCEPT, 'no reply is waited for where the milter said it sends none' );

    ( $path, $done ) = fake_milter( protocol => SMFIP_NOCONNECT, replies => $eom );
    Milter::Client::sendmail( Milter::Client::milter_socket($path), { timeout => 1 }, @cmds );
    is( [ grep { $_->[0] eq SMFIC_MACRO } $done->() ], [], 'nor is a macro for a step that is left out' );

    # Two chunks of body, of which the milter wants only the first
    my @long = Milter::Client::conversation( "Subject: s\n\n" . ( 'x' x MILTER_CHUNK_SIZE ) . "y\n" );
    ( $path, $done ) = fake_milter( replies => { B => [ packet(SMFIR_SKIP) ], %$eom } );
    ($code) = Milter::Client::sendmail( Milter::Client::milter_socket($path), { timeout => 1 }, @long );
    @letters = map { $_->[0] } $done->();
    is( $code,                                                         SMFIR_ACCEPT,                  'a milter which skips the body still reaches the verdict' );
    is( [ grep { $_ eq SMFIC_BODY || $_ eq SMFIC_BODYEOB } @letters ], [ SMFIC_BODY, SMFIC_BODYEOB ], '... and is sent no more of the body, then the end of the message' );
};

subtest 'milter_socket' => sub {
    my ( $path, $done ) = fake_milter( replies => { H => [ packet( SMFIR_REPLYCODE, "550 5.7.1 no\0" ) ] } );
    my @res = Milter::Client::sendmail( Milter::Client::milter_socket("unix:$path"), { timeout => 1 }, [ SMFIC_HELO, 'h.test.test' ] );
    $done->();
    is( [ @res[ 0, 1 ] ], [ SMFIR_REPLYCODE, '550 5.7.1 no' ], 'unix:/path reaches the milter' );

    my $listen = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1 ) or die "listen: $@";
    my $port   = $listen->sockport();
    ok( Milter::Client::milter_socket( "inet:$port\@127.0.0.1", 1 ), 'inet:port@host connects' );

    like( dies { Milter::Client::milter_socket('/bogus/milter.sock') },   qr{\A Cannot\ connect\ to\ /bogus/milter\.sock:\ }xs, 'a socket nobody listens on dies' );
    like( dies { Milter::Client::milter_socket('tcp://127.0.0.1:8891') }, qr{not\ unix:/path,\ inet:port\@host\ or\ inet6}xs,   'a spec of no known form dies, and says what it takes' );
};

subtest 'conversation' => sub {
    my $body = ( "x" x 99 . "\n" ) x 1000;
    my @cmds = Milter::Client::conversation( "From: a\@test.test\nSubject: s\n\n$body", { client_ip => '192.0.2.1', helo => 'h', mail_from => '', rcpt_to => 'r@test.test' } );
    is( $cmds[0],                                   [ SMFIC_OPTNEG, 6, 0x1FF, 0x1FFFFF ],                                          'negotiation offers every version 6 action and step' );
    is( $cmds[1],                                   [ SMFIC_CONNECT, '[192.0.2.1]', SMFIA_INET, 25, '192.0.2.1' ],                 'connect with the client address' );
    is( $cmds[3],                                   [ SMFIC_MAIL, '<>' ],                                                          'null sender kept' );
    is( [ grep { $_->[0] eq SMFIC_HEADER } @cmds ], [ [ SMFIC_HEADER, 'From', 'a@test.test' ], [ SMFIC_HEADER, 'Subject', 's' ] ], 'one command per header' );
    my @chunks = grep { $_->[0] eq SMFIC_BODY } @cmds;
    is( scalar(@chunks), 2, 'a 101k body is sent in two chunks' );
    ok( !( grep { length( $_->[1] ) > MILTER_CHUNK_SIZE } @chunks ), '... none over the chunk size' );
    is( join( '', map { $_->[1] } @chunks ), ( "x" x 99 . "\r\n" ) x 1000, '... with CRLF line endings' );
    is( [ map { $_->[0] } @cmds[ -2, -1 ] ], [ SMFIC_BODYEOB, SMFIC_QUIT ], 'ends with end of message, then quit' );

    @cmds = Milter::Client::conversation( "Subject: s\n\nx", {} );
    is( $cmds[1],                                 [ SMFIC_CONNECT, 'localhost', SMFIA_UNKNOWN, 25, '' ], 'no client address, unknown family' );
    is( [ grep { $_->[0] eq SMFIC_RCPT } @cmds ], [ [ SMFIC_RCPT, '<>' ] ],                              'no recipient, one null one' );

    @cmds = Milter::Client::conversation( "Subject: s\n\nx", { client_ip => '2001:db8::1', client_host => 'v6.test.test' } );
    is( $cmds[1], [ SMFIC_CONNECT, 'v6.test.test', SMFIA_INET6, 25, '2001:db8::1' ], 'IPv6 client' );

    @cmds = Milter::Client::conversation( "Subject: s\n\nx", { rcpt_to => [ 'a@test.test', 'b@test.test' ], queue_id => 'Q1', macros => { rcpt => { rcpt_addr => 'x' }, mail => { auth_authen => 'u' } } } );
    is(
        [ grep { $_->[0] eq SMFIC_MACRO || $_->[0] eq SMFIC_MAIL || $_->[0] eq SMFIC_RCPT } @cmds ],
        [ [ SMFIC_MACRO, SMFIC_MAIL, auth_authen => 'u', i => 'Q1' ], [ SMFIC_MAIL, '<>' ], [ SMFIC_MACRO, SMFIC_RCPT, rcpt_addr => 'x' ], [ SMFIC_RCPT, '<a@test.test>' ], [ SMFIC_RCPT, '<b@test.test>' ] ],
        'one RCPT per recipient, the queue id joins the MAIL macros, and a macro goes before the first command of its stage'
    );

    is( dies { Milter::Client::conversation( "Subject: s\n\nx", { macros => { bogus => {} } } ) }, "No such stage as bogus: one of connect, data, eoh, eom, helo, mail, rcpt\n", 'an unknown stage dies, and names the stages' );
};

subtest 'split_message' => sub {
    my ( $fields, $body ) = split_message("A: one\r\nB:  two\r\n\tfolded\r\nnot a header\r\nC:\r\n\r\nbody\r\n\r\nmore");
    is( $fields, [ [ 'A', 'one' ], [ 'B', " two\n\tfolded" ], [ 'C', '' ] ], 'fields split, folding kept, junk dropped' );
    is( $body,   "body\r\n\r\nmore",                                         'body is everything after the first blank line' );

    ( $fields, $body ) = split_message("A: headers only\n");
    is( [ $fields, $body ], [ [ [ 'A', 'headers only' ] ], '' ], 'a message with no body has an empty one' );
};

subtest 'decode' => sub {
    my %cases = (
        'add_header'         => [ SMFIR_ADDHEADER,   "X-Spam\0yes",                { action => 'add_header', name => 'X-Spam', value => 'yes' } ],
        'insert_header'      => [ SMFIR_INSHEADER,   pack( 'N', 1 ) . "A-R\0v",    { action => 'insert_header', index => 1, name => 'A-R', value => 'v' } ],
        'change_header'      => [ SMFIR_CHGHEADER,   pack( 'N', 2 ) . "A-R\0v",    { action => 'change_header', index => 2, name => 'A-R', value => 'v' } ],
        'an empty change'    => [ SMFIR_CHGHEADER,   pack( 'N', 1 ) . "A-R\0",     { action => 'delete_header', index => 1, name => 'A-R' } ],
        'add_rcpt'           => [ SMFIR_ADDRCPT,     'a@test.test',                { action => 'add_rcpt', rcpt => 'a@test.test' } ],
        'add_rcpt with args' => [ SMFIR_ADDRCPT_PAR, "a\@test.test\0NOTIFY=NEVER", { action => 'add_rcpt', rcpt => 'a@test.test', args => 'NOTIFY=NEVER' } ],
        'delete_rcpt'        => [ SMFIR_DELRCPT,     'a@test.test',                { action => 'delete_rcpt', rcpt => 'a@test.test' } ],
        'change_from'        => [ SMFIR_CHGFROM,     "b\@test.test\0SIZE=1",       { action => 'change_from', from => 'b@test.test', args => 'SIZE=1' } ],
        'replace_body'       => [ SMFIR_REPLBODY,    "new\0",                      { action => 'replace_body', body   => "new\0" } ],
        'quarantine'         => [ SMFIR_QUARANTINE,  'held',                       { action => 'quarantine',   reason => 'held' } ],
        'reply'              => [ SMFIR_REPLYCODE,   '550 5.7.1 no',               { action => 'reply',        reply  => '550 5.7.1 no' } ],
        'accept'             => [ SMFIR_ACCEPT,      undef,                        { action => 'accept' } ],
        'a timeout'          => [ CLIENT_TIMEOUT,    undef,                        { action => 'timeout' } ],
    );
    is( Milter::Client::decode( @{ $cases{$_} }[ 0, 1 ] ), $cases{$_}[2],                   $_ ) for sort keys %cases;
    is( dies { Milter::Client::decode( 'Z', '' ) },        "No such milter reply as 'Z'\n", 'an unknown code dies' );
};

is( [ Milter::Client::body_chunks('') ],                                                          [],                       'empty body, no chunks' );
is( [ map { length( $_->[1] ) } Milter::Client::body_chunks( 'x' x ( MILTER_CHUNK_SIZE + 1 ) ) ], [ MILTER_CHUNK_SIZE, 1 ], 'body split at the chunk size' );

done_testing();

__END__

=head1 DESCRIPTION

L<Milter::Client> against a scripted fake milter: final replies, modifications, timeouts, hangups, negotiation and body chunking,
and the conversation it builds for a message.

=cut
