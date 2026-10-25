package Milter::Client 0.002;

# ABSTRACT: Send commands to milters and get responses


use 5.014;
use strict;
use warnings FATAL => 'all';
use re '/aa';

use IO::Socket::IP;
use IO::Socket::UNIX;
use Socket      qw{SOCK_STREAM};
use Time::HiRes ();

use parent 'Exporter';
our %EXPORT_TAGS = (
    constants => [
        qw{
          SMFIC_ABORT
          SMFIC_BODY
          SMFIC_CONNECT
          SMFIC_MACRO
          SMFIC_BODYEOB
          SMFIC_HELO
          SMFIC_HEADER
          SMFIC_MAIL
          SMFIC_EOH
          SMFIC_OPTNEG
          SMFIC_RCPT
          SMFIC_QUIT
          SMFIC_DATA
          SMFIC_UNKNOWN
          SMFIR_ADDRCPT
          SMFIR_DELRCPT
          SMFIR_ADDRCPT_PAR
          SMFIR_ACCEPT
          SMFIR_REPLBODY
          SMFIR_CONTINUE
          SMFIR_DISCARD
          SMFIR_ADDHEADER
          SMFIR_INSHEADER
          SMFIR_SETSYMLIST
          SMFIR_CHGHEADER
          SMFIR_PROGRESS
          SMFIR_QUARANTINE
          SMFIR_REJECT
          SMFIR_CHGFROM
          SMFIR_TEMPFAIL
          SMFIR_REPLYCODE
          SMFIR_SKIP
          SMFIA_UNKNOWN
          SMFIA_UNIX
          SMFIA_INET
          SMFIA_INET6
          CLIENT_TIMEOUT
          CLIENT_EOF
          MILTER_CHUNK_SIZE
        }
    ],
    protocol => [
        qw{
          SMFIP_NOCONNECT
          SMFIP_NOHELO
          SMFIP_NOMAIL
          SMFIP_NORCPT
          SMFIP_NOBODY
          SMFIP_NOHDRS
          SMFIP_NOEOH
          SMFIP_NR_HDR
          SMFIP_NOUNKNOWN
          SMFIP_NODATA
          SMFIP_SKIP
          SMFIP_NR_CONN
          SMFIP_NR_HELO
          SMFIP_NR_MAIL
          SMFIP_NR_RCPT
          SMFIP_NR_DATA
          SMFIP_NR_UNKN
          SMFIP_NR_EOH
          SMFIP_NR_BODY
        }
    ],
);
our @EXPORT_OK = ( map( { @$_ } values(%EXPORT_TAGS) ), qw{split_message} );

# The protocol's names are the interface: callers write SMFIC_HELO as sendmail's headers do, which Readonly cannot export.
## no critic (PreferredModules)

# Commands:
use constant SMFIC_ABORT   => 'A';
use constant SMFIC_BODY    => 'B';
use constant SMFIC_CONNECT => 'C';
use constant SMFIC_MACRO   => 'D';
use constant SMFIC_BODYEOB => 'E';
use constant SMFIC_HELO    => 'H';
use constant SMFIC_HEADER  => 'L';
use constant SMFIC_MAIL    => 'M';
use constant SMFIC_EOH     => 'N';
use constant SMFIC_OPTNEG  => 'O';
use constant SMFIC_RCPT    => 'R';
use constant SMFIC_QUIT    => 'Q';
use constant SMFIC_DATA    => 'T';    # v4
use constant SMFIC_UNKNOWN => 'U';    # v3

# Responses:
use constant SMFIR_ADDRCPT     => '+';
use constant SMFIR_DELRCPT     => '-';
use constant SMFIR_ADDRCPT_PAR => '2';
use constant SMFIR_ACCEPT      => 'a';
use constant SMFIR_REPLBODY    => 'b';
use constant SMFIR_CONTINUE    => 'c';
use constant SMFIR_DISCARD     => 'd';
use constant SMFIR_ADDHEADER   => 'h';
use constant SMFIR_INSHEADER   => 'i';    # v3, or v2 and Sendmail 8.13+
use constant SMFIR_SETSYMLIST  => 'l';
use constant SMFIR_CHGHEADER   => 'm';
use constant SMFIR_PROGRESS    => 'p';
use constant SMFIR_QUARANTINE  => 'q';
use constant SMFIR_REJECT      => 'r';
use constant SMFIR_CHGFROM     => 'e';    # Sendmail 8.14+
use constant SMFIR_TEMPFAIL    => 't';
use constant SMFIR_REPLYCODE   => 'y';
use constant SMFIR_SKIP        => 's';    # v6, to a body chunk: send no more of the body

# Socktypes
use constant SMFIA_UNKNOWN => 'U';
use constant SMFIA_UNIX    => 'L';
use constant SMFIA_INET    => '4';
use constant SMFIA_INET6   => '6';

# Protocol steps a milter can ask the MTA to leave out, or not to wait for a reply to
use constant SMFIP_NOCONNECT => 0x00000001;
use constant SMFIP_NOHELO    => 0x00000002;
use constant SMFIP_NOMAIL    => 0x00000004;
use constant SMFIP_NORCPT    => 0x00000008;
use constant SMFIP_NOBODY    => 0x00000010;
use constant SMFIP_NOHDRS    => 0x00000020;
use constant SMFIP_NOEOH     => 0x00000040;
use constant SMFIP_NR_HDR    => 0x00000080;
use constant SMFIP_NOUNKNOWN => 0x00000100;
use constant SMFIP_NODATA    => 0x00000200;
use constant SMFIP_SKIP      => 0x00000400;    # offered by an MTA which takes SMFIR_SKIP
use constant SMFIP_NR_CONN   => 0x00001000;
use constant SMFIP_NR_HELO   => 0x00002000;
use constant SMFIP_NR_MAIL   => 0x00004000;
use constant SMFIP_NR_RCPT   => 0x00008000;
use constant SMFIP_NR_DATA   => 0x00010000;
use constant SMFIP_NR_UNKN   => 0x00020000;
use constant SMFIP_NR_EOH    => 0x00040000;
use constant SMFIP_NR_BODY   => 0x00080000;

# Not part of the milter protocol.  Returned by sendmail() when asked to report on a hung or dead milter.
use constant CLIENT_TIMEOUT => 'timeout';
use constant CLIENT_EOF     => 'eof';

# Largest body chunk a milter will accept unless it negotiates otherwise (MILTER_CHUNK_SIZE in libmilter)
use constant MILTER_CHUNK_SIZE => 65535;

## use critic

# Pack templates for sending over messages
my %templates = (
    SMFIC_OPTNEG()  => "A N N N",
    SMFIC_CONNECT() => "A Z* A n Z*",
    SMFIC_HELO()    => "A Z*",
    SMFIC_MAIL()    => "A Z*",
    SMFIC_RCPT()    => "A Z*",
    SMFIC_DATA()    => "A",
    SMFIC_HEADER()  => "A Z* Z*",
    SMFIC_EOH()     => "A",
    SMFIC_BODY()    => "A a*",
    SMFIC_BODYEOB() => "A",
    SMFIC_QUIT()    => "A",
);

# For each command, the protocol flag which leaves it out and the one which says the milter sends no reply to it
my %STEP = (
    SMFIC_CONNECT() => [ SMFIP_NOCONNECT, SMFIP_NR_CONN ],
    SMFIC_HELO()    => [ SMFIP_NOHELO,    SMFIP_NR_HELO ],
    SMFIC_MAIL()    => [ SMFIP_NOMAIL,    SMFIP_NR_MAIL ],
    SMFIC_RCPT()    => [ SMFIP_NORCPT,    SMFIP_NR_RCPT ],
    SMFIC_DATA()    => [ SMFIP_NODATA,    SMFIP_NR_DATA ],
    SMFIC_HEADER()  => [ SMFIP_NOHDRS,    SMFIP_NR_HDR ],
    SMFIC_EOH()     => [ SMFIP_NOEOH,     SMFIP_NR_EOH ],
    SMFIC_BODY()    => [ SMFIP_NOBODY,    SMFIP_NR_BODY ],
    SMFIC_UNKNOWN() => [ SMFIP_NOUNKNOWN, SMFIP_NR_UNKN ],
);

# Read exactly that many bytes, or die with CLIENT_EOF
my $read_exactly = sub {
    my ( $sock, $want ) = @_;
    my $buf = '';
    while ( length($buf) < $want ) {
        my $got = sysread( $sock, $buf, $want - length($buf), length($buf) );
        die CLIENT_EOF . "\n" unless $got;
    }
    return $buf;
};

# Read one reply packet: 4 byte length, then that many bytes of code & payload.
my $read_reply = sub {
    my ( $sock, $timeout ) = @_;
    $timeout ||= 1;

    my $packet;
    local $@;
    my $ok = eval {
        local $SIG{ALRM} = sub { die CLIENT_TIMEOUT . "\n" };
        Time::HiRes::alarm($timeout);
        my $len = unpack( 'N', $read_exactly->( $sock, 4 ) );
        $packet = $read_exactly->( $sock, $len );
        Time::HiRes::alarm(0);
        1;
    };
    Time::HiRes::alarm(0);
    if ( !$ok ) {
        my $err = $@;
        chomp $err;
        return CLIENT_TIMEOUT if $err eq CLIENT_TIMEOUT;
        return CLIENT_EOF;
    }

    # The terminator of a string payload goes, but the negotiation and a new body are binary, and may end in a NUL that is data
    my ( $code, $payload ) = unpack( 'a a*', $packet );
    $payload =~ s/\0\z//xs if defined $payload && $code ne SMFIC_OPTNEG && $code ne SMFIR_REPLBODY;
    return ( $code, $payload );
};


my %MODIFICATIONS = map { $_ => 1 } ( SMFIR_ADDRCPT, SMFIR_DELRCPT, SMFIR_ADDRCPT_PAR, SMFIR_REPLBODY, SMFIR_ADDHEADER, SMFIR_INSHEADER, SMFIR_CHGHEADER, SMFIR_CHGFROM, SMFIR_QUARANTINE, SMFIR_PROGRESS );

# Bogus sendmail.
sub sendmail {
    my ( $sock, @cmds ) = @_;
    my %opts = ref $cmds[0] eq 'HASH' ? %{ shift @cmds } : ();
    my @mods;
    my $protocol = 0;
    my $skip_body;

    # A milter which hangs up is reported (or presumed to continue), not fatal
    local $SIG{PIPE} = 'IGNORE';

    foreach my $args (@cmds) {
        my $action = $args->[0];
        my ( $left_out, $no_reply ) = @{ $STEP{ $action eq SMFIC_MACRO ? $args->[1] : $action } // [ 0, 0 ] };
        next if $protocol & $left_out;
        next if $skip_body && $action eq SMFIC_BODY;

        # The single string form of SMFIC_HEADER needs the value terminator added
        my @args = ( $action eq SMFIC_HEADER && @$args == 2 ) ? ( @$args, '' ) : @$args;

        # A macro command carries the command it is for, then any number of name/value pairs
        my $template = $action eq SMFIC_MACRO ? 'A A' . ( ' Z*' x ( @args - 2 ) ) : $templates{$action};
        my $packed   = pack( $template, @args );

        # What we will actually send over the wire
        my $packed_with_length = pack( 'N a*', length($packed), $packed );
        my $sent = syswrite $sock, $packed_with_length;
        next if $action eq SMFIC_QUIT || $action eq SMFIC_MACRO || $protocol & $no_reply;

        my ( $res, $payload ) = $sent ? $read_reply->( $sock, $opts{timeout} ) : (CLIENT_EOF);

        # A milter may send any number of modifications (and progress reports) before its final reply, each a packet of its own
        while ( $MODIFICATIONS{$res} ) {
            push @mods, [ $res, $payload ] unless $res eq SMFIR_PROGRESS;
            ( $res, $payload ) = $read_reply->( $sock, $opts{timeout} );
        }

        if ( $res eq CLIENT_TIMEOUT || $res eq CLIENT_EOF ) {
            return ( $res, undef, \@mods ) if defined $opts{timeout};
            next;
        }

        # The milter's version, actions and protocol steps, then any macros it wants, which we send regardless
        if ( $res eq SMFIC_OPTNEG ) {
            ( undef, undef, $protocol ) = unpack( 'N N N', $payload );
            next;
        }
        if ( $res eq SMFIR_SKIP && $action eq SMFIC_BODY ) {
            $skip_body = 1;
            next;
        }
        return ( $res, $payload, \@mods ) if $res ne SMFIR_CONTINUE;
    }
    return ( SMFIR_CONTINUE, undef, \@mods );
}


sub milter_socket {
    my ( $spec, $timeout ) = @_;
    my $sock;
    if ( my ($path) = $spec =~ m{\A (?:(?:unix|local):)? (/.*) \z}xs ) {
        $sock = IO::Socket::UNIX->new( Type => SOCK_STREAM(), Peer => $path ) or die "Cannot connect to $spec: $!\n";
    }
    elsif ( my ( $port, $host ) = $spec =~ m{\A inet6?: (\d+) (?:\@(.+))? \z}xs ) {
        $sock = IO::Socket::IP->new( PeerHost => $host // 'localhost', PeerPort => $port, Type => SOCK_STREAM(), ( $timeout ? ( Timeout => $timeout ) : () ) ) or die "Cannot connect to $spec: $@\n";
    }
    else {
        die "Cannot connect to $spec: not unix:/path, inet:port\@host or inet6:port\@host\n";
    }
    return $sock;
}


my %STAGE = ( connect => SMFIC_CONNECT, helo => SMFIC_HELO, mail => SMFIC_MAIL, rcpt => SMFIC_RCPT, data => SMFIC_DATA, eoh => SMFIC_EOH, eom => SMFIC_BODYEOB );

sub conversation {
    my ( $raw, $env ) = @_;
    $env //= {};
    my ( $fields, $body ) = split_message($raw);
    $body =~ s/(?<!\r)\n/\r\n/xsg;

    my %macros = %{ $env->{macros} // {} };
    $macros{mail} = { i => $env->{queue_id}, %{ $macros{mail} // {} } } if defined $env->{queue_id};
    my %before;
    foreach my $stage ( sort keys %macros ) {
        my $command = $STAGE{$stage} // die "No such stage as $stage: one of " . join( ', ', sort keys %STAGE ) . "\n";
        my $set     = $macros{$stage};
        $before{$command} = [ [ SMFIC_MACRO, $command, map { $_ => $set->{$_} } sort keys %$set ] ];
    }

    my $ip     = $env->{client_ip};
    my $family = !$ip ? SMFIA_UNKNOWN : index( $ip, ':' ) >= 0 ? SMFIA_INET6 : SMFIA_INET;
    my $host   = $env->{client_host} // ( $ip ? "[$ip]" : 'localhost' );
    my @rcpts  = ref $env->{rcpt_to} ? @{ $env->{rcpt_to} } : ( $env->{rcpt_to} // '' );

    my @steps = (
        [ SMFIC_CONNECT, $host, $family, 25, $ip // '' ],
        [ SMFIC_HELO,    $env->{helo} // 'unknown' ],
        [ SMFIC_MAIL,    '<' . ( $env->{mail_from} // '' ) . '>' ],
        ( map { [ SMFIC_RCPT, "<$_>" ] } @rcpts ),
        [SMFIC_DATA],
        ( map { [ SMFIC_HEADER, @$_ ] } @$fields ),
        [SMFIC_EOH],
        body_chunks($body),
        [SMFIC_BODYEOB],
    );

    # A macro goes before the first command of its stage only, as before the first of several RCPTs
    my ( %sent, @cmds );
    foreach my $step (@steps) {
        push @cmds, @{ $before{ $step->[0] } // [] } unless $sent{ $step->[0] }++;
        push @cmds, $step;
    }
    return ( [ SMFIC_OPTNEG, 6, 0x1FF, 0x1FFFFF ], @cmds, [SMFIC_QUIT] );
}


sub split_message {
    my ($raw) = @_;
    my ( $head, $body ) = split( /\r?\n\r?\n/xs, $raw, 2 );
    $body //= '';

    my @fields;
    foreach my $line ( split( /\r?\n(?![ \t])/xs, $head ) ) {
        my ( $name, $value ) = $line =~ m/\A ([^:\s]+) : [ \t]? (.*) \z/xs or next;
        $value =~ s/\r\n/\n/xsg;
        push @fields, [ $name, $value ];
    }
    return ( \@fields, $body );
}


sub body_chunks {
    my ($body) = @_;
    my @chunks;
    for ( my $pos = 0; $pos < length($body); $pos += MILTER_CHUNK_SIZE ) {
        push @chunks, [ SMFIC_BODY, substr( $body, $pos, MILTER_CHUNK_SIZE ) ];
    }
    return @chunks;
}


my %FINAL = ( SMFIR_ACCEPT() => 'accept', SMFIR_CONTINUE() => 'continue', SMFIR_DISCARD() => 'discard', SMFIR_REJECT() => 'reject', SMFIR_TEMPFAIL() => 'tempfail', CLIENT_TIMEOUT() => 'timeout', CLIENT_EOF() => 'eof' );

sub decode {
    my ( $code, $payload ) = @_;
    $payload //= '';
    return { action => $FINAL{$code} } if $FINAL{$code};
    if ( $code eq SMFIR_ADDHEADER ) {
        my ( $name, $value ) = unpack( 'Z* a*', $payload );
        return { action => 'add_header', name => $name, value => $value };
    }
    if ( $code eq SMFIR_INSHEADER || $code eq SMFIR_CHGHEADER ) {
        my ( $index, $name, $value ) = unpack( 'N Z* a*', $payload );
        return { action => 'insert_header', index => $index, name => $name, value => $value } if $code eq SMFIR_INSHEADER;
        return { action => 'delete_header', index => $index, name => $name } if $value eq '';
        return { action => 'change_header', index => $index, name => $name, value => $value };
    }
    if ( $code eq SMFIR_ADDRCPT || $code eq SMFIR_ADDRCPT_PAR || $code eq SMFIR_CHGFROM ) {
        my ( $addr, $args ) = unpack( 'Z* a*', $payload );
        my $field = $code eq SMFIR_CHGFROM ? 'from' : 'rcpt';
        return { action => $code eq SMFIR_CHGFROM ? 'change_from' : 'add_rcpt', $field => $addr, ( $args ne '' ? ( args => $args ) : () ) };
    }
    return { action => 'delete_rcpt',  rcpt   => $payload } if $code eq SMFIR_DELRCPT;
    return { action => 'replace_body', body   => $payload } if $code eq SMFIR_REPLBODY;
    return { action => 'quarantine',   reason => $payload } if $code eq SMFIR_QUARANTINE;
    return { action => 'reply',        reply  => $payload } if $code eq SMFIR_REPLYCODE;
    die "No such milter reply as '$code'\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Milter::Client - Send commands to milters and get responses

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Milter::Client qw{:constants};

    # A message as an MTA would hand it to the milter, from the connection to the end of the message
    my $sock = Milter::Client::milter_socket('unix:/run/opendmarc/opendmarc.sock');
    my @cmds = Milter::Client::conversation(
        "From: test\@test.test\nSubject: Test\n\nTesting 123\n",
        { client_ip => '192.0.2.1', helo => 'test.test', mail_from => 'test@test.test', rcpt_to => ['test@test.test'] },
    );
    my ( $code, $payload, $mods ) = Milter::Client::sendmail( $sock, { timeout => 5 }, @cmds );
    print Milter::Client::decode( @$_ )->{action}, "\n" for @$mods;

    # Or build the conversation by hand.  This is a pretty maximal exchange, mirroring a standard SMTP dialog.
    my $sockfile = '/var/run/feet.sock';
    our @gibbering = (
        # Version, actions, protocol steps.  Below is every action and step of version 6.  You can omit this entirely.
        [SMFIC_OPTNEG,  6, 0x1FF, 0x1FFFFF],
        # You'll want to use the proper sock type based on how the client connected to the MTA
        # If it isn't a unix socket, the last argument needs to be an IP address
        [SMFIC_CONNECT, 'test.test', SMFIA_UNIX, 0, $sockfile],
        # Everything from here is pretty self-explanatory based on its SMTP equivalents.
        [SMFIC_HELO,    'test.test'],
        [SMFIC_MAIL,    '<test@test.test>'], # Envelope Sender
        [SMFIC_RCPT,    '<test@test.test>'], # Envelope Recipient
        [SMFIC_DATA,    ],
        # One command per header: name, then value.
        [SMFIC_HEADER,  'From',    'test@test.test'],
        [SMFIC_HEADER,  'To',      'test@test.test'],
        [SMFIC_HEADER,  'Subject', 'Test'],
        [SMFIC_EOH,     ],
        # Bodies over 64k need to be sent in chunks, see body_chunks()
        [SMFIC_BODY,    "Testing 123"],
        [SMFIC_BODYEOB, ],
        [SMFIC_QUIT,    ],
    );

    # Returns whenever you either run out of commands or get a code other than SMFIS_CONTINUE or SMFIS_OPTNEG
    # You'll get some kind of SMFIR_* constant returned, usually SMFIR_REPLYCODE when it's a REJ/DEFER w/ SMTP & ESMTP response codes.
    ( $code, $payload ) = Milter::Client::sendmail( Milter::Client::milter_socket($sockfile), @gibbering );

    # Pass options as a hashref before the commands to find out when the milter hangs or dies,
    # rather than presuming it wanted you to continue.
    ( $code, $payload ) = Milter::Client::sendmail( Milter::Client::milter_socket($sockfile), { timeout => 5 }, @gibbering );
    warn "Milter hung"  if $code eq CLIENT_TIMEOUT;
    warn "Milter died"  if $code eq CLIENT_EOF;

=head1 DESCRIPTION

The milter protocol is what an MTA such as postfix or sendmail speaks to a mail filter.
This module speaks the MTA's half of it, so a milter can be tested without an MTA.

C<milterprobe> is a program on top of it, which gives one message to a milter and prints what the milter did with it.

=head1 WHY

It occurred to me the lack of public development for innovative milters may have something to do with the difficulty of testing them.

There are no milter client modules which are not themselves an MTA I am aware of.
As you might imagine, that complicates the sort of automated testing you might want to do to distribute modular milters.

=head1 FUNCTIONS

=head2 ($code, $payload, $modifications) = sendmail($socket, [\%options], @commands)

Send commands to a milter & read the responses.

Terminates whenever you run out of commands or get something other than SMFIR_CONTINUE.

Requests to modify the message (add a header, change the body, quarantine it and so forth) are not a final reply.
They are returned in C<$modifications>, an arrayref of C<[ $code, $payload ]>, which C<decode()> reads.

Headers are sent one per command, as C<[SMFIC_HEADER, $name, $value]>.
The older form of C<[SMFIC_HEADER, $all_the_headers]> still works, but the milter will see it as one header with an empty value.

Macros go as C<[SMFIC_MACRO, $command, $name => $value, ...]>, sent before the command they belong to,
for example C<[SMFIC_MACRO, SMFIC_MAIL, i => 'QUEUEID']> before SMFIC_MAIL for the queue id.

No reply is waited for after SMFIC_MACRO or SMFIC_QUIT, as milters do not send one.

The milter's answer to SMFIC_OPTNEG is obeyed as an MTA obeys it.
A command for a step the milter asked to leave out is not sent, and neither is a macro for it.
No reply is waited for to a step the milter said it sends no reply to.
A milter which answers a body chunk with SMFIR_SKIP is sent no more of the body, and the end of the message follows.
Without SMFIC_OPTNEG, every command is sent and every reply waited for.

Without options, a milter which says nothing within a second is presumed to want you to continue.
Pass a hashref of options before the commands to change that:

=over 4

=item C<timeout>

Seconds (fractions allowed) to wait for each reply.
When given, a milter which does not reply in time returns C<CLIENT_TIMEOUT>, and one which hangs up returns C<CLIENT_EOF>.

=back

See Synopsis for more details.

=head2 $socket = milter_socket($spec, [$timeout])

Connect to a milter, and return the socket for C<sendmail()>.

C<$spec> is written as postfix and sendmail write it:
C<unix:/path> (or C<local:/path>, or just C</path>) for a unix socket,
and C<inet:port@host> or C<inet6:port@host> for TCP.
The host defaults to localhost.

C<$timeout>, in seconds, applies to the connect.

Dies when it cannot connect, or when C<$spec> is none of those.

=head2 @commands = conversation($raw, [\%envelope])

The commands an MTA would send a milter for one message on a connection of its own, for C<sendmail()>:
OPTNEG offering every version 6 action and step, CONNECT, HELO, MAIL, RCPT, DATA,
one HEADER per header, EOH, the body in chunks with bare LF turned into CRLF as on the wire, end of message, and QUIT.

C<$raw> is the message, header and body, as C<split_message()> takes it.
C<%envelope> says what the MTA knew about the client and the envelope:

=over 4

=item C<client_ip>

The address of the client.  Without it, CONNECT says the family is unknown.

=item C<client_host>

The name of the client.  Defaults to the address in brackets, or C<localhost>.

=item C<helo>

What the client said in HELO.  Defaults to C<unknown>.

=item C<mail_from>

The envelope sender, without angle brackets.  Defaults to the null sender.

=item C<rcpt_to>

The envelope recipient, or an arrayref of them, one RCPT each.  Defaults to one null recipient.

=item C<queue_id>

Sent as the C<{i}> macro before MAIL, as postfix does.

=item C<macros>

A hashref of the stage (C<connect>, C<helo>, C<mail>, C<rcpt>, C<data>, C<eoh> or C<eom>) to a hashref of macro names and values, sent before that stage.

=back

Dies on a stage it does not know.

=head2 ($fields, $body) = split_message($raw)

Split a raw message the way an MTA would before handing it to a milter.

C<$fields> is an arrayref of C<[ $name, $value ]> in the order they appear.
The value has the single space after the colon removed, and keeps any folding (with CR removed) as a milter would see it.
Lines in the header which are not a header field are dropped.

C<$body> is everything after the blank line which ends the header.

=head2 @commands = body_chunks($body)

Split a message body into SMFIC_BODY commands no bigger than MILTER_CHUNK_SIZE, as an MTA would.

An empty body yields no commands.

=head2 \%what = decode($code, $payload)

What a reply from C<sendmail()> means, as a hashref with an C<action> and the fields that action has.
It takes a modification, as C<@$_> of each in C<$modifications>, or the final code and payload.

=over 4

=item C<add_header>: C<name>, C<value>

=item C<insert_header>, C<change_header>: C<index>, C<name>, C<value>

=item C<delete_header>: C<index>, C<name>

A change to an empty value, which is how a milter removes a header.

=item C<add_rcpt>: C<rcpt>, and C<args> when the milter gave ESMTP arguments

=item C<delete_rcpt>: C<rcpt>

=item C<change_from>: C<from>, and C<args> when the milter gave ESMTP arguments

=item C<replace_body>: C<body>, one chunk of the new body

=item C<quarantine>: C<reason>

=item C<reply>: C<reply>, the SMTP reply such as C<550 5.7.1 Go away>

=item C<accept>, C<continue>, C<discard>, C<reject>, C<tempfail>, C<timeout>, C<eof>

=back

C<index> counts from 1 among the headers of that name for a change, and among all headers for an insert.
Header names and values are as the milter sent them, folding and all.

Dies on a code it does not know.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Milter-Client/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTORS

=for stopwords Andy Baugh troglodyne-bot

=over 4

=item *

Andy Baugh <andy@troglodyne.net>

=item *

troglodyne-bot <morpheus@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
