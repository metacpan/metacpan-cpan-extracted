package Mail::MIMEDefang::OpenSMTPD;

# MIT License
#
# Copyright (c) 2022-2026 The McGrail Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;
use v5.16;

use Exporter 'import';
use IO::Select;
use IO::Socket::UNIX;
use Socket qw( SOCK_STREAM SHUT_WR );

use Mail::MIMEDefang;

our $VERSION = '1.1';

our @EXPORT_OK = qw(
    split_addr relay_hostname encode_command mx_request
    parse_mx_reply reply_to_decision
    parse_headers header_value parse_results apply_header_ops
    stuff_line unstuff_line build_commands
    tls_macros
);

=head1 NAME

Mail::MIMEDefang::OpenSMTPD - helpers for the MIMEDefang OpenSMTPD filter

=head1 DESCRIPTION

This module holds the parts of filter-mimedefang that do not need a
running smtpd(8): talking to mimedefang-multiplexor(8), parsing its answers
and the C<RESULTS> file, and rewriting message headers.  It is split out so
that it can be unit tested.

=head1 FUNCTIONS

=head2 split_addr($str)

Splits an smtpd(8) C<ip:port>, C<[ipv6]:port> or C<local> string into
C<($ip, $port)>.  The IP never has brackets.

=cut

sub split_addr {
    my ($str) = @_;
    return ( 'unknown', 0 ) unless defined $str and length $str;

    return ( $1, $2 ) if $str =~ /^\[([^\]]*)\]:(\d+)$/;     # [::1]:25
    return ( $1, 0 )  if $str =~ /^\[([^\]]*)\]$/;           # [::1]
    return ( $1, $2 ) if $str =~ /^([^:]+):(\d+)$/;          # 192.0.2.1:25
    return ( $str, 0 );    # local, unix:/path, bare IPv4/IPv6
}

=head2 relay_hostname($rdns, $ip)

Returns the host name the way MIMEDefang expects it: the reverse DNS name,
or the IP address in square brackets when there is none.

=cut

sub relay_hostname {
    my ( $rdns, $ip ) = @_;
    return "[$ip]"
        if not defined $rdns
        or $rdns eq ''
        or $rdns =~ /^<.*>$/
        or lc($rdns) eq 'unknown';
    return $rdns;
}

=head2 encode_command(@args)

Percent-encodes each argument and joins them with spaces, like
mimedefang(8) does.  Undefined and empty arguments become C<?>.

=cut

sub encode_command {
    return join ' ',
        map { ( defined $_ and length $_ ) ? percent_encode($_) : '?' } @_;
}

=head2 mx_request($socket_path, $timeout, $command)

Sends one newline-terminated command to the multiplexor and returns
everything it answers, or undef on failure.  A failed attempt is retried
once.

=cut

sub mx_request {
    my ( $path, $timeout, $cmd ) = @_;
    $timeout ||= 30;

    for my $try ( 1 .. 2 ) {
        my $c = IO::Socket::UNIX->new(
            Type    => SOCK_STREAM,
            Peer    => $path,
            Timeout => $timeout,
        ) or next;

        my $ok = eval {
            $c->autoflush(1);
            print {$c} "$cmd\n" or die "write: $!";
            $c->shutdown(SHUT_WR);
            1;
        };
        if ( not $ok ) { close $c; next; }

        my $buf = '';
        my $sel = IO::Select->new($c);
        while ( $sel->can_read($timeout) ) {
            my $n = $c->sysread( my $chunk, 4096 );
            last if not $n;
            $buf .= $chunk;
        }
        close $c;
        return $buf if length $buf;
    }
    return;
}

=head2 parse_mx_reply($text)

Parses an C<ok N message code dsn delay> answer to C<relayok>, C<helook>,
C<senderok> or C<recipok>.  Returns a hashref with C<status> (1 continue,
0 reject, -1 tempfail, 2 accept without further filtering, 3 discard),
C<message>, C<code>, C<dsn> and C<delay>, or undef if the text is not an
answer.

=cut

sub parse_mx_reply {
    my ($text) = @_;
    return undef unless defined $text;    ## no critic (ProhibitExplicitReturnUndef)
    $text =~ s/\s+$//;
    return undef    ## no critic (ProhibitExplicitReturnUndef)
        unless $text
        =~ /^ok\s+(-?\d+)(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\S+))?(?:\s+(\d+))?/;
    my %r = (
        status  => $1,
        message => defined $2 ? percent_decode($2) : '',
        code    => defined $3 ? percent_decode($3) : '',
        dsn     => defined $4 ? percent_decode($4) : '',
        delay   => $5 // 0,
    );
    $r{message} = '' if $r{message} eq '?';
    return \%r;
}

=head2 reply_to_decision($reply, $default_text)

Turns a parsed multiplexor answer into C<($action, $text)>.  C<$action> is
one of C<proceed>, C<reject>, C<accept> (stop filtering this session) or
C<discard>; C<$text> is a complete SMTP reply such as C<550 5.7.1 go away>
for C<reject>.

=cut

sub reply_to_decision {
    my ( $r, $default ) = @_;
    return ( 'reject', '451 4.3.0 Temporary failure, please try again later.' )
        if not defined $r;

    my $st = $r->{status};
    return ( 'proceed', undef ) if $st == 1;
    return ( 'accept',  undef ) if $st == 2;
    return ( 'discard', undef ) if $st == 3;

    my ( $want, $defcode, $defdsn )
        = $st < 0 ? ( '4', '451', '4.7.1' ) : ( '5', '550', '5.7.1' );
    my $code = $r->{code} =~ /^${want}\d\d$/ ? $r->{code} : $defcode;
    my $dsn
        = $r->{dsn} =~ /^${want}\.\d{1,3}\.\d{1,3}$/ ? $r->{dsn} : $defdsn;
    my $msg = length $r->{message} ? $r->{message} : $default;
    $msg =~ s/[\r\n]+/ /g;
    return ( 'reject', "$code $dsn $msg" );
}

=head2 build_commands(%args)

Returns the text of the C<COMMANDS> file for mimedefang.pl.  Arguments:
C<sender>, C<recipients> (array ref), C<msgid>, C<qid>, C<helo>,
C<subject> (already percent-encoded), C<relay_ip>, C<mx_id> and C<macros>
(hash ref of Sendmail macro name to value, written as C<=name value>).
Addresses are written inside angle brackets, as Sendmail does.

=cut

sub build_commands {
    my (%a) = @_;
    my $addr = sub {
        my $x = shift // '';
        $x = "<$x>" unless $x =~ /^<.*>$/;
        return $x;
    };
    my @l;
    my $sender = $addr->( $a{sender} );
    push @l, "S$sender", "=mail_addr $sender";
    push @l, "X$a{msgid}" if defined $a{msgid};
    push @l, "Q$a{qid}"   if defined $a{qid};
    if ( defined $a{helo} ) {
        push @l, "H$a{helo}", "E$a{helo}", "=mail_host $a{helo}.";
    }
    my %m = %{ $a{macros} // {} };
    push @l, map {"=$_ $m{$_}"} grep { defined $m{$_} and length $m{$_} } sort keys %m;
    push @l, "U$a{subject}" if defined $a{subject};
    push @l, "I$a{relay_ip}" if defined $a{relay_ip};
    push @l, "i$a{mx_id}"    if defined $a{mx_id};
    push @l, map { 'R' . $addr->($_) . ' ? ? ?' } @{ $a{recipients} // [] };
    push @l, 'F';
    return join( "\n", @l ) . "\n";
}

=head2 stuff_line($line) / unstuff_line($line)

Add or remove SMTP dot-stuffing on one line.

=cut

sub stuff_line   { my $l = shift; $l =~ s/^\./../; return $l }
sub unstuff_line { my $l = shift; $l =~ s/^\.(.+)$/$1/; return $l }

=head2 tls_macros($tls_string)

Converts the C<version:cipher:bits> string reported by smtpd(8) into the
Sendmail macros that MIMEDefang filters expect.

=cut

sub tls_macros {
    my ($s) = @_;
    return () unless defined $s and length $s;
    my ( $version, $cipher, $bits ) = split /:/, $s;
    my %m;
    $m{tls_version}  = $version if defined $version and length $version;
    $m{cipher}       = $cipher  if defined $cipher  and length $cipher;
    $m{cipher_bits}  = $bits    if defined $bits    and $bits =~ /^\d+$/;
    return %m;
}

=head2 parse_headers(\@lines)

Splits message lines (without the final C<.>) into headers and body.
Returns C<(\@headers, $body_index)>.  Each header is a hashref with C<name>,
C<lc> (lower-cased name) and C<lines>, the raw physical lines including any
folded continuation lines.  C<$body_index> is the index of the blank line
that ends the headers, or the number of lines if there is none.

=cut

sub parse_headers {
    my ($lines) = @_;
    my @h;
    my $i = 0;
    for ( ; $i < @{$lines}; $i++ ) {
        my $ln = $lines->[$i];
        last if $ln eq '';
        if ( $ln =~ /^[ \t]/ and @h ) {
            push @{ $h[-1]{lines} }, $ln;
        }
        elsif ( $ln =~ /^([^\s:]+)[ \t]*:/ ) {
            push @h, { name => $1, lc => lc $1, lines => [$ln] };
        }
        else {
            push @h, { name => undef, lc => '', lines => [$ln] };
        }
    }
    return ( \@h, $i );
}

=head2 header_value($header)

The unfolded value of a header returned by C<parse_headers>, without the
leading white space.

=cut

sub header_value {
    my ($h) = @_;
    my $v = join ' ', map { my $l = $_; $l =~ s/^[ \t]+//; $l } @{ $h->{lines} };
    $v =~ s/^[^:]*:[ \t]*//;
    return $v;
}

=head2 parse_results($text)

Parses the C<RESULTS> file written by mimedefang.pl.  Returns a hashref:

 ops         list of { type => H|N|I|J|M, name, idx, value } header changes
 action      first of 'reject', 'tempfail' or 'discard' found, if any
 reply       complete SMTP reply for reject and tempfail
 newbody     true if the body was replaced (NEWBODY)
 unsupported list of { type => Q|R|S|f, value } requests that cannot be
             done through smtpd-filters(7)

As in mimedefang(8), header changes are not to be applied when C<action>
is set.

=cut

sub parse_results {
    my ($text) = @_;
    my %r = ( ops => [], action => undef, reply => undef, newbody => 0, unsupported => [] );

    for my $line ( split /\n/, ( $text // '' ) ) {
        next unless length $line;
        my $cmd = substr( $line, 0, 1 );
        my $arg = substr( $line, 1 );

        if ( $cmd eq 'H' ) {                       # add header
            my ( $n, $v ) = split ' ', $arg, 2;
            next unless defined $n;
            push @{ $r{ops} }, { type => 'H', name => percent_decode($n),
                                 value => percent_decode( $v // '' ) };
        }
        elsif ( $cmd eq 'N' or $cmd eq 'I' ) {     # insert / change header
            my ( $n, $i, $v ) = split ' ', $arg, 3;
            next unless defined $n and defined $i and $i =~ /^\d+$/;
            push @{ $r{ops} }, { type => $cmd, name => percent_decode($n),
                                 idx => $i, value => percent_decode( $v // '' ) };
        }
        elsif ( $cmd eq 'J' ) {                    # delete header
            my ( $n, $i ) = split ' ', $arg, 2;
            next unless defined $n;
            $i = 1 if not defined $i or $i !~ /^\d+$/ or $i < 1;
            push @{ $r{ops} }, { type => 'J', name => percent_decode($n), idx => $i };
        }
        elsif ( $cmd eq 'B' or $cmd eq 'T' ) {     # bounce / tempfail
            next if $r{action};
            my ( $code, $dsn, $msg ) = split ' ', $arg, 3;
            my $st = $cmd eq 'B' ? 0 : -1;
            ( undef, $r{reply} ) = reply_to_decision(
                {   status  => $st,
                    code    => percent_decode( $code // '' ),
                    dsn     => percent_decode( $dsn  // '' ),
                    message => percent_decode( $msg  // '' ),
                },
                $cmd eq 'B' ? 'Message rejected' : 'Temporary failure, please try again later.'
            );
            $r{action} = $cmd eq 'B' ? 'reject' : 'tempfail';
        }
        elsif ( $cmd eq 'D' ) {
            $r{action} //= 'discard';
        }
        elsif ( $cmd eq 'C' ) {
            $r{newbody} = 1;
        }
        elsif ( $cmd eq 'M' ) {                    # new Content-Type
            push @{ $r{ops} }, { type => 'M', value => percent_decode($arg) };
        }
        elsif ( $cmd =~ /^[QRSf]$/ ) {
            push @{ $r{unsupported} }, { type => $cmd, value => percent_decode($arg) };
        }
    }
    return \%r;
}

=head2 apply_header_ops(\@headers, \@ops)

Applies the header changes from C<parse_results> to the headers from
C<parse_headers>, in order, the way libmilter would, and returns the
resulting list of physical header lines.  The input is not modified.

 H  add a header at the end
 N  insert a header so that it is header number idx (0 is the top)
 I  change the idx'th (1-based) header called name; add it if there is none
 J  delete the idx'th header called name
 M  replace Content-Type (and add MIME-Version if missing)

=cut

sub apply_header_ops {
    my ( $headers, $ops ) = @_;
    my @h = map { { %{$_}, lines => [ @{ $_->{lines} } ] } } @{$headers};

    my $new = sub {
        my ( $name, $value ) = @_;
        return { name => $name, lc => lc $name, lines => [ split /\n/, "$name: $value", -1 ] };
    };

    for my $op ( @{$ops} ) {
        my $t = $op->{type};
        if ( $t eq 'H' ) {
            push @h, $new->( $op->{name}, $op->{value} );
        }
        elsif ( $t eq 'N' ) {
            my $pos = $op->{idx} > @h ? scalar @h : $op->{idx};
            splice @h, $pos, 0, $new->( $op->{name}, $op->{value} );
        }
        elsif ( $t eq 'I' or $t eq 'J' ) {
            my ( $n, $found ) = ( lc $op->{name}, 0 );
            my $at;
            for my $k ( 0 .. $#h ) {
                next unless $h[$k]{lc} eq $n;
                if ( ++$found == $op->{idx} ) { $at = $k; last }
            }
            if ( not defined $at ) {
                push @h, $new->( $op->{name}, $op->{value} ) if $t eq 'I';
            }
            elsif ( $t eq 'I' ) {
                $h[$at] = $new->( $h[$at]{name}, $op->{value} );
            }
            else {
                splice @h, $at, 1;
            }
        }
        elsif ( $t eq 'M' ) {
            @h = grep { $_->{lc} ne 'content-type' } @h;
            push @h, $new->( 'MIME-Version', '1.0' )
                unless grep { $_->{lc} eq 'mime-version' } @h;
            push @h, $new->( 'Content-Type', $op->{value} );
        }
    }
    return map { @{ $_->{lines} } } @h;
}

1;
