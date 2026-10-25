package FakeMilter;

use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

use File::Temp;
use IO::Socket::UNIX;
use Socket qw{SOCK_STREAM};

use Milter::Client qw{:constants};

use parent 'Exporter';
our @EXPORT_OK = qw{fake_milter packet};

# One reply packet, as a milter writes it
sub packet {
    my ( $code, $payload ) = @_;
    my $body = $code . ( $payload // '' );
    return pack( 'N a*', length($body), $body );
}

# A milter on a unix socket, in a child, which takes one connection.
# It answers OPTNEG with $opts{protocol}, each command in $opts{replies} with the packets there,
# and any other command but a macro, QUIT, or one the protocol says has no reply, with CONTINUE.
# Returns the socket path, and a sub which waits for the child and returns each command it got as [ $letter, $payload ].
sub fake_milter {
    my (%opts) = @_;
    my $dir    = File::Temp->newdir();
    my $path   = "$dir/milter.sock";
    my $listen = IO::Socket::UNIX->new( Type => SOCK_STREAM(), Local => $path, Listen => 1 ) or die "listen $path: $!";
    pipe( my $from_child, my $to_parent ) or die "pipe: $!";

    my %no_reply = map { $_ => 1 } ( SMFIC_MACRO, SMFIC_QUIT, @{ $opts{no_reply} // [] } );
    my $pid      = fork() // die "fork: $!";
    if ( !$pid ) {
        close $from_child            or die "close: $!";
        my $conn = $listen->accept() or exit 1;
        my @got;
        while ( read( $conn, my $len, 4 ) == 4 ) {
            read( $conn, my $cmd, unpack( 'N', $len ) );
            my ( $letter, $payload ) = unpack( 'a a*', $cmd );
            push @got, "$letter" . unpack( 'H*', $payload );
            my @replies =
                $letter eq SMFIC_OPTNEG ? ( packet( SMFIC_OPTNEG, pack( 'N N N', 6, 0x1FF, $opts{protocol} // 0 ) ) )
              : $opts{replies}{$letter} ? @{ $opts{replies}{$letter} }
              : $no_reply{$letter}      ? ()
              :                           ( packet(SMFIR_CONTINUE) );
            syswrite( $conn, $_ ) for @replies;
        }
        print {$to_parent} map { "$_\n" } @got;
        close $to_parent or die "close: $!";
        exit 0;
    }
    close $to_parent or die "close: $!";
    close $listen    or die "close: $!";

    return (
        $path,
        sub {
            chomp( my @lines = <$from_child> );
            waitpid( $pid, 0 );
            undef $dir;
            return map { [ substr( $_, 0, 1 ), pack( 'H*', substr( $_, 1 ) ) ] } @lines;
        }
    );
}

1;
