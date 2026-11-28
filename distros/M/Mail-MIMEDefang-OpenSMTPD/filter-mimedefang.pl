#!/usr/bin/perl

# MIT License
#
# Copyright (c) 2022-2023 The McGrail Foundation
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

=head1 NAME

filter-mimedefang.pl - an OpenSMTPD filter for MIMEDefang

=head1 DESCRIPTION

MIMEDefang-smtpd-filter is an OpenSMTPD filter to integrate MIMEDefang and OpenSMTPD.

To enable the filter just add the following lines into your smtpd.conf:

    filter "mimedefang" proc-exec "filter-mimedefang.pl" user _mdefang group _mdefang
    listen on all filter "mimedefang"

The filter is installed in /usr/local/libexec/smtpd, where smtpd(8) looks
up a relative proc-exec path.  If it was installed somewhere else, give the
full path.

=head2 USAGE

The program has some parameters to modify its behavior.

-d	enable debug mode, when debug mode is enabled, logs will
	be more verbose and temporary files under /var/spool/MIMEDefang will not be removed.

-r	performs a relay check by calling filter_relay sub in mimedefang-filter(5)

-H	performs a HELO check by calling filter_helo sub in mimedefang-filter(5)

-s	calls filter_sender sub in mimedefang-filter(5) for every MAIL FROM

-t	calls filter_recipient sub in mimedefang-filter(5) for every RCPT TO,
	each recipient is accepted or rejected on its own

-X	Do not add an X-Scanned-By: header.

-m socket	path of the mimedefang-multiplexor(8) socket,
	default /var/spool/MIMEDefang/mimedefang-multiplexor.sock

-z dir	MIMEDefang spool directory, default /var/spool/MIMEDefang

-T secs	timeout for the multiplexor, default 30 seconds.  If it cannot be
	reached or does not answer, mail is tempfailed with a 451.

=head2 WHAT THE FILTER PASSES TO MIMEDEFANG

Besides the sender, the accepted recipients (in angle brackets, like
Sendmail) and the client address, the filter sets the C<tls_version>,
C<cipher> and C<cipher_bits> macros for TLS sessions and C<auth_authen> for
authenticated ones, so they can be read from C<%SendmailMacros>.
The queue ID is the smtpd(8) envelope id, or its message id before the
envelope exists (during filter_sender and filter_recipient).

=head2 BUGS AND LIMITATIONS

Some features that are available in MIMEDefang are not implemented because
smtpd-filters(7) cannot express them once the message has been accepted:
add_recipient(), delete_recipient() and change_sender() are not available, nor
is quarantining a message in the MTA queue (action_sm_quarantine()), and the
tarpit delay returned by filter_relay() and friends is ignored.
Requests for them are logged at "warning" level and mail is delivered.
action_discard() is ignored.

=head1 SEE ALSO

mimedefang(8), mimedefang-filter(5), mimedefang-protocol(7), smtpd.conf(5),
smtpd-filters(7), L<Mail::MIMEDefang::OpenSMTPD>

=cut

use v5.16;	# needed by OpenSMTPd::Filter

use Carp;
use File::Path;
use Getopt::Std;
use IO::Socket::UNIX;
use Mail::MIMEDefang;
use Mail::MIMEDefang::Utils;
use OpenSMTPd::Filter;
use Mail::MIMEDefang::OpenSMTPD qw(
    split_addr relay_hostname encode_command mx_request
    parse_mx_reply reply_to_decision
    parse_headers header_value parse_results apply_header_ops
    stuff_line unstuff_line build_commands tls_macros
);

# This lets us see if there are other modules we may need to preload
unshift @INC, sub { carp "Attempted to load $_[1]"; return };

my $MDSPOOL_PATH = '/var/spool/MIMEDefang/';
my $SOCK_PATH    = '/var/spool/MIMEDefang/mimedefang-multiplexor.sock';
my $MX_TIMEOUT   = 30;

use constant HAS_UNVEIL => eval { require OpenBSD::Unveil; };
use constant HAS_PLEDGE => eval { require OpenBSD::Pledge; };

my %opts;
getopts( 'dHrstXm:z:T:', \%opts )
  or die "usage: $0 [-dHrstX] [-m socket] [-z spooldir] [-T timeout]\n";

my $debug      = 0;
my $relaycheck = 0;
my $helocheck  = 0;
my $sendercheck    = 0;
my $recipientcheck = 0;
my $xscannedby = 1;

our $SyslogFacility = "mail";

$debug      = 1 if defined $opts{d};
$helocheck  = 1 if defined $opts{H};
$relaycheck = 1 if defined $opts{r};
$sendercheck    = 1 if defined $opts{s};
$recipientcheck = 1 if defined $opts{t};
$xscannedby = 0 if defined $opts{X};
$SOCK_PATH  = $opts{m} if defined $opts{m};
$MDSPOOL_PATH = $opts{z} if defined $opts{z};
$MX_TIMEOUT = $opts{T} if defined $opts{T} and $opts{T} =~ /^[1-9]\d*$/;
$MDSPOOL_PATH .= '/' if $MDSPOOL_PATH !~ m{/$};

# Routine messages are only logged at "info" in debug mode, otherwise at
# "debug", so that a busy server does not fill the mail log.
sub _log {
    my ( $level, $msg ) = @_;
    $level = ( $debug ? 'info' : 'debug' ) if $level eq 'routine';
    eval { md_syslog( $level, $msg ); 1 } or warn "$level: $msg\n";
}

if (HAS_UNVEIL) {
    OpenBSD::Unveil->import;
    # Needed for rmtree to work
    unveil( '/', "r" ) || croak "Unable to unveil: $!";
    unveil( $MDSPOOL_PATH, "rwcx" ) || croak "Unable to unveil: $!";
    # connect(2) to the multiplexor socket needs "w", and -m may point outside the spool
    unveil( $SOCK_PATH, "rw" )      || croak "Unable to unveil $SOCK_PATH: $!";
    unveil()                        || croak "Unable to lock unveil: $!";
}

if (HAS_PLEDGE) {
    OpenBSD::Pledge->import;
    pledge(qw( rpath wpath cpath prot_exec unix )) || croak "Unable to pledge: $!";
}

my %smtp_in = (
    'connect'    => \&relay_check,
    'helo'       => \&helo_check,
    'ehlo'       => \&helo_check,
    'data-lines' => \&data_save,
    'commit'     => \&data_check,
);
$smtp_in{'mail-from'} = \&sender_check    if $sendercheck;
$smtp_in{'rcpt-to'}   = \&recipient_check if $recipientcheck;

my $filter = OpenSMTPd::Filter->new(
    debug => $debug,
    on    => {
        report => { 'smtp-in' => {
            'link-disconnect' => \&cleanup,
            'tx-reset'        => \&cleanup,
            'tx-rollback'     => \&cleanup,
        } },
        filter => { 'smtp-in' => \%smtp_in },
    }
);

$filter->ready;



sub _get_realip {
    my ($ip) = split_addr(shift);
    return $ip;
}


# Queue ID of the current transaction as MIMEDefang knows it.
sub _qid {
    my ($s) = @_;
    my $m = $s->{state}->{message};
    return 'NOQUEUE' if not $m;
    return $m->{'envelope-id'} // $m->{'message-id'} // 'NOQUEUE';
}

# Ask the multiplexor a relayok/helook/senderok/recipok question and turn the
# answer into an smtpd(8) filter decision.
sub _ask {
    my ( $s, $what, $default_text, @cmd ) = @_;

    my $reply = mx_request( $SOCK_PATH, $MX_TIMEOUT, encode_command(@cmd) );
    _log( 'warning', "no answer from the multiplexor for $what" )
        if not defined $reply;

    my $parsed = parse_mx_reply($reply);
    my ( $action, $text ) = reply_to_decision( $parsed, $default_text );
    if ( $action eq 'accept' ) {
        $s->{state}->{md_accepted} = 1;    # no more filtering for this session
        return 'proceed';
    }
    if ( $action eq 'discard' ) {
        _log( 'warning', "$what: discard is not supported by smtpd-filters(7), continuing" );
        return 'proceed';
    }
    return 'proceed' if $action eq 'proceed';
    return reject => $text;
}

sub relay_check {
    my ( $phase, $s ) = @_;

    return 'proceed' if not $relaycheck or $s->{state}->{md_accepted};

    my $state = $s->{state};
    my $event = $s->{events}->[-1] // {};
    my ( $src_ip, $src_port ) = split_addr( $state->{src} // $event->{src} );
    my ( $dst_ip, $dst_port ) = split_addr( $state->{dest} );
    my $host = relay_hostname( $state->{rdns} // $event->{rdns}, $src_ip );

    _log( 'routine', "checking relay from ip $src_ip" );
    return _ask( $s, "relay $src_ip", 'relay not allowed.',
        'relayok', $src_ip, $host, $src_port, $dst_ip, $dst_port, _qid($s) );
}

sub helo_check {
    my ( $phase, $s ) = @_;

    return 'proceed' if not $helocheck or $s->{state}->{md_accepted};

    my $state    = $s->{state};
    my $event    = $s->{events}->[-1] // {};
    my $identity = $event->{identity} // $state->{identity} // 'UNKNOWN';
    my ( $src_ip, $src_port ) = split_addr( $state->{src} );
    my ( $dst_ip, $dst_port ) = split_addr( $state->{dest} );
    my $host = relay_hostname( $state->{rdns}, $src_ip );

    _log( 'routine', "checking helo $identity" );
    return _ask( $s, "helo $identity", 'EHLO failure, go away.',
        'helook', $src_ip, $host, $identity, $src_port, $dst_ip, $dst_port, _qid($s) );
}

# Recipients accepted by smtpd(8) for this transaction, in order.
sub _recipients {
    my ( $s, $message ) = @_;
    my $mid = $message->{'message-id'} // '';
    my @r = map { $_->{address} }
        grep {
            ( $_->{event} // '' ) eq 'tx-rcpt'
                and ( $_->{'message-id'} // '' ) eq $mid
                and ( $_->{result} // '' ) eq 'ok'
                and defined $_->{address}
        } @{ $s->{events} // [] };
    return @r ? @r : @{ $message->{'rcpt-to'} // [] };
}

# Sendmail macros that filters expect, derived from what smtpd(8) reports.
sub _macros {
    my ($state) = @_;
    my %m = tls_macros( $state->{'tls-string'} );
    $m{auth_authen} = $state->{username}
        if defined $state->{username}
        and ( $state->{result} // 'pass' ) eq 'pass';
    return \%m;
}

# Create (or reuse) the MIMEDefang spool directory of a message.
sub _spool_dir {
    my ($message) = @_;

    return $message->{md_spool_dir}
        if defined $message->{md_spool_dir} and -d $message->{md_spool_dir};

    if ( Mail::MIMEDefang::Utils->can('gen_mx_id') ) {
        $message->{md_mx_id} //= Mail::MIMEDefang::Utils::gen_mx_id();
    }
    my $id = $message->{'envelope-id'} // $message->{md_mx_id};
    return if not defined $id;

    my $dir = $MDSPOOL_PATH . 'mdefang-' . $id;
    return if not -d $dir and not mkdir $dir;
    return $message->{md_spool_dir} = $dir;
}

sub _read_file {
    my ($path) = @_;
    open( my $fh, '<', $path ) or return;
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# The message being built.  smtpd(8) normally reports tx-begin before it asks
# for the sender, but do not depend on it.
sub _current_message {
    my ($state) = @_;
    return $state->{message} // ( $state->{md_tmp} //= {} );
}

sub sender_check {
    my ( $phase, $s ) = @_;

    my $state = $s->{state};
    return 'proceed' if not $sendercheck or $state->{md_accepted};

    my $message = _current_message($state);
    my $sender  = $s->{events}->[-1]->{address} // '';
    my ($ip)    = split_addr( $state->{src} );
    my $host    = relay_hostname( $state->{rdns}, $ip );
    my $dir     = _spool_dir($message);
    return ( reject => '451 4.3.0 Temporary failure, please try again later.' )
        if not defined $dir;

    $sender = "<$sender>" if $sender !~ /^<.*>$/;
    _log( 'routine', "checking sender $sender" );
    return _ask( $s, "sender $sender", 'Sender address rejected.',
        'senderok', $sender, $ip, $host, $state->{identity} // 'UNKNOWN',
        $dir, _qid($s) );
}

sub recipient_check {
    my ( $phase, $s ) = @_;

    my $state = $s->{state};
    return 'proceed' if not $recipientcheck or $state->{md_accepted};

    my $message   = _current_message($state);
    my $recipient = $s->{events}->[-1]->{address} // '';
    my $sender    = $message->{'mail-from'} // '';
    my ($ip)      = split_addr( $state->{src} );
    my $host      = relay_hostname( $state->{rdns}, $ip );
    my $dir       = _spool_dir($message);
    return ( reject => '451 4.3.0 Temporary failure, please try again later.' )
        if not defined $dir;

    my ($first) = _recipients( $s, $message );
    $first //= $recipient;
    for ( $recipient, $sender, $first ) { $_ = "<$_>" if $_ !~ /^<.*>$/ }

    _log( 'routine', "checking recipient $recipient" );
    return _ask( $s, "recipient $recipient", 'Recipient address rejected.',
        'recipok', $recipient, $sender, $ip, $host, $first,
        $state->{identity} // 'UNKNOWN', $dir, _qid($s), undef, undef, undef );
}

sub data_save {
    my ( $phase, $s, $lines ) = @_;
    my @lines = @{$lines};

    my $state   = $s->{state};
    my $message = $state->{message};
    return if not $message;

    # A directory made by sender_check() before tx-begin was reported.
    if ( my $tmp = delete $state->{md_tmp} ) {
        $message->{$_} //= $tmp->{$_} for qw( md_spool_dir md_mx_id );
    }

    # Drop the end of data marker; smtpd(8) gets it back from the module.
    pop @lines if @lines and $lines[-1] eq '.';

    if ( $state->{md_accepted} ) {    # an earlier check said "no more filtering"
        $message->{md_status} = 'ok';
        return @lines;
    }

    # Anything that goes wrong from here on is a tempfail at commit time.
    $message->{md_status} = 'temp_error';

    my ( $headers, $bodystart ) = parse_headers( \@lines );
    return if not @{$headers};

    my $dir = _spool_dir($message);
    return if not defined $dir;

    my $subject;
    my ($subject_header) = grep { $_->{lc} eq 'subject' } @{$headers};
    $subject = percent_encode( header_value($subject_header) ) if $subject_header;

    open( my $fh, '>', "$dir/HEADERS" ) or return;
    print {$fh} "$_\n" for map { @{ $_->{lines} } } @{$headers};
    close $fh;

    open( my $fi, '>', "$dir/INPUTMSG" ) or return;
    print {$fi} unstuff_line($_), "\n" for @lines;
    close $fi;

    open( my $fc, '>', "$dir/COMMANDS" ) or return;
    print {$fc} build_commands(
        sender     => $message->{'mail-from'},
        recipients => [ _recipients( $s, $message ) ],
        msgid      => $message->{'message-id'},
        qid        => $message->{'envelope-id'},
        helo       => $state->{identity},
        subject    => $subject,
        relay_ip   => _get_realip( $state->{src} ),
        mx_id      => $message->{md_mx_id},
        macros     => _macros($state),
    );
    close $fc;

    _log( 'routine', "checking message $message->{'envelope-id'}" );
    my $buffer = mx_request( $SOCK_PATH, $MX_TIMEOUT,
        encode_command( 'scan', $message->{'envelope-id'}, $dir ) );
    return if not defined $buffer;
    $message->{md_status} = $buffer;
    return if $buffer !~ /^ok\b/;    # "error: ..." is reported by data_check

    my $results = _read_file("$dir/RESULTS");
    if ( not defined $results ) {
        _log( 'warning', "no RESULTS file for $message->{'envelope-id'}" );
        $message->{md_status} = 'temp_error';
        return;
    }
    my $res = $message->{md_result} = parse_results($results);

    # A rejected message is not delivered, so there is nothing to rewrite.
    return @lines if $res->{action};

    for my $u ( @{ $res->{unsupported} } ) {
        my %what = (
            Q => 'Quarantine command unsupported',
            R => 'Adding a new recipient is not supported',
            S => 'Deleting a recipient is not supported',
            f => 'Changing the envelope sender is not supported',
        );
        _log( 'warning', "$what{ $u->{type} }, email processing will continue" );
    }

    my @new = apply_header_ops( $headers, $res->{ops} );
    push @new, 'X-Scanned-By: MIMEDefang ' . $Mail::MIMEDefang::VERSION
        . ' on ' . _get_realip( $state->{'dest'} )
        if $xscannedby;

    my @body;
    if ( $res->{newbody} ) {
        my $nb = _read_file("$dir/NEWBODY");
        if ( not defined $nb ) {
            _log( 'warning', "no NEWBODY file for $message->{'envelope-id'}" );
            $message->{md_status} = 'temp_error';
            return;
        }
        # The file is plain text; smtpd(8) wants dot-stuffed lines.
        @body = ( '', map { s/\r$//r } map { stuff_line($_) } split /\n/, $nb, -1 );
        pop @body if @body > 1 and $body[-1] eq '';    # trailing newline
    }
    elsif ( $bodystart < @lines ) {
        @body = @lines[ $bodystart .. $#lines ];
    }
    return ( @new, @body );
}

sub data_check {
    my ( $phase, $s ) = @_;

    my $message = $s->{state}->{message};
    my $status  = $message ? $message->{md_status} : undef;
    my $res     = $message ? $message->{md_result} : undef;
    my $tempfail = '451 4.3.0 Temporary failure, please try again later.';

    my @ret;
    if ( not defined $status or $status eq 'temp_error' ) {
        @ret = ( reject => $tempfail );
    }
    elsif ( $status !~ /^ok\b/ ) {
        # "error: ..." from the multiplexor; mimedefang(8) tempfails too.
        ( my $why = $status ) =~ s/\s+$//;
        _log( 'warning', "multiplexor: $why" );
        @ret = ( reject => $tempfail );
    }
    elsif ( $res and ( $res->{action} // '' ) =~ /^(?:reject|tempfail)$/ ) {
        @ret = ( reject => $res->{reply} );
    }
    elsif ( $res and ( $res->{action} // '' ) eq 'discard' ) {
        _log( 'warning', 'Discard command unsupported, email processing will continue' );
        @ret = ('proceed');
    }
    else {
        @ret = ('proceed');
    }

    message_cleanup($message) if $message;
    return @ret;
}

# Remove the spool directories of every transaction of the session.
# Remove the spool directories of every transaction of the session.
sub cleanup {
    my ( $phase, $s ) = @_;
    message_cleanup($_) for @{ $s->{messages} // [] }, $s->{state}->{md_tmp} // ();
}

sub message_cleanup {
    my $message = shift;

    return if $debug;
    rmtree( delete $message->{md_spool_dir} ) if defined $message->{md_spool_dir};
}
