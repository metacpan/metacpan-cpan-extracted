#!/usr/bin/env perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

use FindBin qw{$Bin};
use FindBin::libs;
use Capture::Tiny qw{capture};
use Cpanel::JSON::XS;
use File::Temp;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Milter::Client qw{:constants};
use FakeMilter     qw{fake_milter packet};

# A modulino is a file with no module name to require it by
my $loaded = lives { require "$Bin/../bin/milterprobe" };    ## no critic (RequireBarewordIncludes)
ok( $loaded, 'milterprobe loads as a modulino without running' ) or diag($@);

sub probe {
    my @args = @_;
    my ( $out, $err, $exit ) = capture { MilterProbe::main(@args) };
    return ( $exit, $out, $err );
}

subtest 'arguments' => sub {
    my ( $exit, undef, $err ) = probe();
    is( $exit, 2, 'no --socket exits 2' );
    like( $err, qr/--socket\ is\ required/xs, '... and says why' );

    ( $exit, undef, $err ) = probe(qw{--socket /bogus/milter.sock --macro connect-j});
    is( $exit, 2, 'a macro that is not STAGE:NAME=VALUE exits 2' );
    like( $err, qr/--macro\ connect-j\ is\ not\ STAGE:NAME=VALUE/xs, '... and names it' );

    ( $exit, undef, $err ) = probe(qw{--socket /bogus/milter.sock --macro bogus:j=x});
    is( $exit, 2, 'a macro for no stage exits 2' );
    like( $err, qr/No\ such\ stage\ as\ bogus/xs, '... and names it' );

    ( $exit, undef, $err ) = probe( qw{--socket /bogus/milter.sock --header}, 'no colon' );
    is( $exit, 2, 'a header that is not Name: value exits 2' );
    like( $err, qr/--header\ no\ colon\ is\ not\ Name:\ value/xs, '... and names it' );

    ( $exit, undef, $err ) = probe( '--socket', '/bogus/milter.sock' );
    is( $exit, 2, 'a milter that cannot be reached exits 2' );
    like( $err, qr{Cannot\ connect\ to\ /bogus/milter\.sock}xs, '... and says where it looked' );

    ( $exit, undef, $err ) = probe(qw{--socket /bogus/milter.sock --body x --message /bogus/message});
    is( $exit, 2, '--body and --message together exit 2' );

    ( $exit, undef, $err ) = probe(qw{--socket /bogus/milter.sock --message /bogus/message});
    is( $exit, 2, 'a message that cannot be read exits 2' );
    like( $err, qr{Cannot\ read\ /bogus/message}xs, '... and names it' );

    ( $exit, undef, $err ) = probe(qw{--socket /bogus/milter.sock stray});
    is( $exit, 2, 'an argument that is no option exits 2' );

    ( $exit, my $out ) = probe('--help');
    is( $exit, 0, '--help exits 0' );
    like( $out, qr/milterprobe\ --socket\ SPEC/xs, '... and prints the usage' );
};

subtest 'describe' => sub {
    my %cases = (
        'insert_header 1 X-A: v'            => { action => 'insert_header', index  => 1, name => 'X-A', value => 'v' },
        'change_header 2 X-A: v w'          => { action => 'change_header', index  => 2, name => 'X-A', value => "v\r\n w" },
        'add_rcpt a@test.test NOTIFY=NEVER' => { action => 'add_rcpt',      rcpt   => 'a@test.test', args => 'NOTIFY=NEVER' },
        'delete_rcpt a@test.test'           => { action => 'delete_rcpt',   rcpt   => 'a@test.test' },
        'change_from b@test.test'           => { action => 'change_from',   from   => 'b@test.test' },
        'replace_body 4'                    => { action => 'replace_body',  body   => "new\0" },
        'quarantine held'                   => { action => 'quarantine',    reason => 'held' },
        'discard'                           => { action => 'discard' },
    );
    is( MilterProbe::describe( $cases{$_} ), $_, $_ ) for sort keys %cases;
};

subtest 'what the milter did' => sub {
    my ( $path, $done ) = fake_milter(
        replies => {
            E => [
                packet( SMFIR_ADDHEADER, "Authentication-Results\0mx.test.test;\n\tdmarc=pass\0" ),
                packet( SMFIR_CHGHEADER, pack( 'N', 1 ) . "Authentication-Results\0\0" ),
                packet(SMFIR_ACCEPT),
            ]
        }
    );
    my ( $exit, $out ) = probe(
        '--socket', $path, qw{--client-ip 192.0.2.1 --helo client.test.test --from a@test.test --rcpt b@test.test --macro connect:j=mta.test.test},
        '--header', 'Authentication-Results: elsewhere.test.test; spf=pass', '--header', 'From: a@test.test', '--body', "A probe.\n",
    );
    my @got = $done->();
    is( $exit, 0,                                                                                                                'a verdict exits 0' );
    is( $out,  "add_header Authentication-Results: mx.test.test;\tdmarc=pass\ndelete_header 1 Authentication-Results\naccept\n", 'each change, unfolded, then the verdict' );

    my %sent = map { $_->[0] => $_->[1] } reverse @got;
    is( [ unpack( 'Z* a n Z*', $sent{ SMFIC_CONNECT() } ) ],                                  [ '[192.0.2.1]', SMFIA_INET, 25, '192.0.2.1' ],                                               'the milter is told the client address' );
    is( [ grep { $_->[0] eq SMFIC_MACRO && substr( $_->[1], 0, 1 ) eq SMFIC_CONNECT } @got ], [ [ SMFIC_MACRO, SMFIC_CONNECT . "j\0mta.test.test\0" ] ],                                    'a --macro replaces the default' );
    is( [ map { [ unpack( 'Z* Z*', $_->[1] ) ] } grep { $_->[0] eq SMFIC_HEADER } @got ],     [ [ 'Authentication-Results', 'elsewhere.test.test; spf=pass' ], [ 'From', 'a@test.test' ] ], 'each --header, in order' );
    is( $sent{ SMFIC_BODY() },                                                                "A probe.\r\n",                                                                               'the body, with CRLF' );
};

subtest '--message and --json' => sub {
    my $dir = File::Temp->newdir();
    open( my $fh, '>', "$dir/message" ) or die "write: $!";
    print {$fh} "From: a\@test.test\n\nHello\n";
    close $fh or die "write: $!";

    my ( $path, $done ) = fake_milter( replies => { E => [ packet( SMFIR_REPLYCODE, "550 5.7.1 Go away\0" ) ] } );
    my ( $exit, $out )  = probe( '--socket', "unix:$path", '--message', "$dir/message", '--header', 'X-First: 1', '--json' );
    my @got = $done->();
    is( $exit,                                                                         0,                                                                                 'a refusal is still a verdict, so it exits 0' );
    is( Cpanel::JSON::XS->new->decode($out),                                           { verdict => { action => 'reply', reply => '550 5.7.1 Go away' }, changes => [] }, 'JSON holds the verdict and the changes' );
    is( [ map { ( unpack( 'Z*', $_->[1] ) ) } grep { $_->[0] eq SMFIC_HEADER } @got ], [ 'X-First', 'From' ],                                                             'a --header goes ahead of the header of the message' );
};

subtest 'a milter that says nothing' => sub {
    my ( $path, $done ) = fake_milter( no_reply => [SMFIC_BODYEOB] );
    my ( $exit, $out )  = probe( '--socket', $path, qw{--timeout 0.3} );
    $done->();
    is( $exit, 1,           'exits 1' );
    is( $out,  "timeout\n", '... and says it timed out' );
};

done_testing();

__END__

=head1 DESCRIPTION

L<milterprobe> against a fake milter: what it sends, what it prints, and how it exits.

=cut
