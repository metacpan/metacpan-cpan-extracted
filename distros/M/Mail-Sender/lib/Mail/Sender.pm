package Mail::Sender;

use strict;
use warnings;
use base 'Exporter';

no warnings 'uninitialized';
use Carp              ();
use Encode            ();
use File::Basename    ();
use IO::Socket::INET  ();
use MIME::Base64      ();
use MIME::QuotedPrint ();
use Socket            ();
use Time::Local       ();

our @EXPORT    = qw();
our @EXPORT_OK = qw(GuessCType);

our $VERSION = '0.903'; # VERSION
$VERSION = eval $VERSION;

warnings::warnif('deprecated', 'Mail::Sender is deprecated and you should look to Email::Sender instead');

our $GMTdiff;
our $Error;
our %default; # loaded in from our config files
our $MD5_loaded = 0;
our $debug      = 0;
our %CTypes     = (
    GIF   => 'image/gif',
    JPE   => 'image/jpeg',
    JPEG  => 'image/jpeg',
    SHTML => 'text/html',
    SHTM  => 'text/html',
    HTML  => 'text/html',
    HTM   => 'text/html',
    TXT   => 'text/plain',
    INI   => 'text/plain',
    DOC   => 'application/x-msword',
    EML   => 'message/rfc822',
);
our @Errors = (
    'OK',
    'Unknown encoding',
    'TLS unsupported by server',
    'TLS unsupported by script',
    'IO::SOCKET::SSL failed',
    'STARTTLS failed',
    'debug file cannot be opened',
    'file cannot be read',
    'all recipients have been rejected',
    'authentication protocol is not implemented',
    'login not accepted',
    'authentication protocol not accepted by the server',
    'no From: address specified',
    'no SMTP server specified',
    'connection not established. Did you mean MailFile instead of SendFile?',
    'site specific error',
    'not available in singlepart mode',
    'file not found',
    'no file name specified in call to MailFile or SendFile',
    'no message specified in call to MailMsg or MailFile',
    'argument $to empty',
    'transmission of message failed',
    'local user $to unknown on host $smtp',
    'unspecified communication error',
    'service not available',
    'connect() failed',
    'socket() failed',
    '$smtphost unknown'
);

# if you do not use MailFile or SendFile and only send 7BIT or 8BIT "encoded"
# messages you may comment out these lines.
#MIME::Base64 and MIME::QuotedPrint may be found at CPAN.

my $TLS_notsupported;

BEGIN {
    eval <<'END'
        use IO::Socket::SSL;# qw(debug4);
        use Net::SSLeay;
        1;
END
        or $TLS_notsupported = $@;
}

# include config file and libraries when packaging the script
if (0) {
    require 'Mail/Sender.config';    # local configuration
    require 'Symbol.pm';             # for debuging and GetHandle() method
    require 'Tie/Handle.pm';         # for debuging and GetHandle() method
    require 'IO/Handle.pm';          # for debuging and GetHandle() method
    require 'Digest/HMAC_MD5.pm';    # for CRAM-MD5 authentication only
    require 'Authen/NTLM.pm';        # for NTLM authentication only
} # this block above is there to let PAR, PerlApp, PerlCtrl, PerlSvc and Perl2Exe know I may need those files.

BEGIN {
    my $config = $INC{'Mail/Sender.pm'};
    die
        "Wrong case in use statement or Mail::Sender module renamed. Perl is case sensitive!!!\n"
        unless $config;
    my $compiled = !(-e $config)
        ; # if the module was not read from disk => the script has been "compiled"
    $config =~ s/\.pm$/.config/;
    if ($compiled or -e $config) {

  # in a Perl2Exe or PerlApp created executable or PerlCtrl generated COM object
  # or the config is known to exist
        eval { require $config };
        if ($@ and $@ !~ /Can't locate /) {
            print STDERR "Error in Mail::Sender.config : $@";
        }
    }
}

#local IP address and name
my $local_name
    = $ENV{HOSTNAME} || $ENV{HTTP_HOST} || (gethostbyname 'localhost')[0];
$local_name
    =~ s/:.*$//; # the HTTP_HOST may be set to something like "foo.bar.com:1000"
my $local_IP = join('.', unpack('CCCC', (gethostbyname $local_name)[4]));

#time diference to GMT - Windows will not set $ENV{'TZ'}, if you know a better way ...

sub ResetGMTdiff {
    my $local = time;
    my $gm    = Time::Local::timelocal(gmtime $local);
    my $sign  = qw( + + - ) [$local <=> $gm];
    $GMTdiff = sprintf "%s%02d%02d", $sign, (gmtime abs($local - $gm))[2, 1];
    return $GMTdiff;
}
ResetGMTdiff();

#
my @priority
    = ('', '1 (Highest)', '2 (High)', '3 (Normal)', '4 (Low)', '5 (Lowest)');

#data encoding
my $chunksize        = 1024 * 4;
my $chunksize64      = 71 * 57;    # must be divisible by 57 !
my $enc_base64_chunk = 57;

sub enc_base64 {
    if ($_[0]) {
        my $charset = $_[0];
        return sub {
            my $s
                = MIME::Base64::encode_base64(Encode::encode($charset, $_[0]));
            $s =~ s/\x0A/\x0D\x0A/sg;
            return $s;
            }
    }
    else {
        return sub {
            my $s = MIME::Base64::encode_base64($_[0]);
            $s =~ s/\x0A/\x0D\x0A/sg;
            return $s;
            }
    }
}

sub enc_qp {
    if ($_[0]) {
        my $charset = $_[0];
        return sub {
            my $s = Encode::encode($charset, $_[0]);
            $s =~ s/\x0D\x0A/\n/g;
            $s = MIME::QuotedPrint::encode_qp($s);
            $s =~ s/^\./../gm;
            $s =~ s/\x0A/\x0D\x0A/sg;
            return $s;
            }
    }
    else {
        return sub {
            my $s = $_[0];
            $s =~ s/\x0D\x0A/\n/g;
            $s = MIME::QuotedPrint::encode_qp($s);
            $s =~ s/^\./../gm;
            $s =~ s/\x0A/\x0D\x0A/sg;
            return $s;
            }
    }
}

sub enc_plain {
    if ($_[0]) {
        my $charset = $_[0];
        return sub {
            my $s = Encode::encode($charset, $_[0]);
            $s =~ s/^\./../gm;
            $s =~ s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg;
            return $s;
            }
    }
    else {
        return sub {
            my $s = $_[0];
            $s =~ s/^\./../gm;
            $s =~ s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg;
            return $s;
            }
    }
}

sub enc_xtext {
    my $input = shift;
    $input =~ s/([^!-*,-<>-~])/'+'.uc(unpack('H*', $1))/eg;
    return $input;
}

{
    my $username;

    sub getusername () {
        return $username if defined($username);
        return $username = eval { getlogin || getpwuid($<) } || $ENV{USERNAME};
    }
}

#IO

#reads the whole SMTP response
# converts
#    nnn-very
#    nnn-long
#    nnn message
# to
#    nnn very
#    long
#    message
sub get_response ($) {
    my $s   = shift;
    my $res = <$s>;
    if ($res =~ s/^(\d\d\d)-/$1 /) {
        my $nextline = <$s>;
        while ($nextline =~ s/^\d\d\d-//) {
            $res .= $nextline;
            $nextline = <$s>;
        }
        $nextline =~ s/^\d\d\d //;
        $res .= $nextline;
    }
    $Mail::Sender::LastResponse = $res;
    return $res;
}

sub send_cmd ($$) {
    my ($s, $cmd) = @_;
    chomp $cmd;
    if ($s->opened()) {
        print $s "$cmd\x0D\x0A";
        get_response($s);
    }
    else {
        return '400 connection lost';
    }
}

sub _print_hdr {
    my ($s, $hdr, $str, $charset) = @_;
    return if !defined $str or $str eq '';
    $str =~ s/[\x0D\x0A\s]+$//;

    if ($charset && $str =~ /[^[:ascii:]]/) {
        $str = Encode::encode($charset, $str);
        my @parts = split /(\s*[,;<> ]\s*)/, $str;
        $str = '';
        for (my $i = 0; $i < @parts; $i++) {
            my $part = $parts[$i];
            $part .= $parts[++$i]
                if ($i < $#parts && $parts[$i + 1] =~ /^\s+$/);
            if ($part =~ /[^[:ascii:]]/ || $part =~ /[\r\n\t]/) {
                $part = MIME::QuotedPrint::encode_qp($part, '');
                $part =~ s/([\s\?])/'=' . sprintf '%02x',ord($1)/ge;
                $str .= "=?$charset?Q?$part?=";
            }
            else {
                $str .= $part;
            }
        }
    }

    $str =~ s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg;    # \n or \r => \r\n
    $str =~ s/\x0D\x0A([^\t])/\x0D\x0A\t$1/sg;
    if (length($str) + length($hdr) > 997) {   # header too long, max 1000 chars
        $str =~ s/(.{1,980}[;,])\s+(\S)/$1\x0D\x0A\t$2/g;
    }
    print $s "$hdr: $str\x0D\x0A";
}


sub _say_helo {
    my ($self, $s) = @_;
    my $res = send_cmd $s, "EHLO $self->{'client'}";
    if ($res !~ /^[123]/) {
        $res = send_cmd $s, "HELO $self->{'client'}";
        if ($res !~ /^[123]/) { return $self->Error(_COMMERROR($_)); }
        return;
    }

    $res =~ s/^.*\n//;
    $self->{'supports'} = {map { split /(?:\s+|=)/, $_, 2 } split /\n/, $res};

    if (exists $self->{'supports'}{AUTH}) {
        my @auth = split /\s+/, uc($self->{'supports'}{AUTH});
        $self->{'auth_protocols'} = {map { $_, 1 } @auth};

        # create a hash with accepted authentication protocols
    }

    $self->{esmtp}{_MAIL_FROM} = '';
    $self->{esmtp}{_RCPT_TO}   = '';
    if (exists $self->{'supports'}{DSN} and exists $self->{esmtp}) {
        for (qw(RET ENVID)) {
            $self->{esmtp}{_MAIL_FROM} .= " $_=$self->{esmtp}{$_}"
                if $self->{esmtp}{$_} ne '';
        }
        for (qw(NOTIFY ORCPT)) {
            $self->{esmtp}{_RCPT_TO} .= " $_=$self->{esmtp}{$_}"
                if $self->{esmtp}{$_} ne '';
        }
    }
    return;
}

sub login {
    my $self = shift();
    my $auth = uc($self->{'auth'}) || 'LOGIN';
    if (!$self->{'auth_protocols'}->{$auth}) {
        return $self->Error(_INVALIDAUTH($auth));
    }

    $self->{'authid'} = $self->{'username'}
        if (exists $self->{'username'} and !exists $self->{'authid'});

    $self->{'authpwd'} = $self->{'password'}
        if (exists $self->{'password'} and !exists $self->{'authpwd'});

  # change all characters except letters, numbers and underscores to underscores
    $auth =~ tr/a-zA-Z0-9_/_/c;
    no strict qw'subs refs';
    my $method = "Mail::Sender::Auth::$auth";
    $method->($self);
}

# authentication code stolen from http://support.zeitform.de/techinfo/e-mail_prot.html
sub Mail::Sender::Auth::LOGIN {
    my $self = shift();
    my $s    = $self->{'socket'};

    $_ = send_cmd $s, 'AUTH LOGIN';
    if (!/^[123]/) { return $self->Error(_INVALIDAUTH('LOGIN', $_)); }

    if ($self->{auth_encoded}) {

        # I assume the username and password had been base64 encoded already!
        $_ = send_cmd $s, $self->{'authid'};
        if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }

        $_ = send_cmd $s, $self->{'authpwd'};
        if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }
    }
    else {
        $_ = send_cmd $s, MIME::Base64::encode_base64($self->{'authid'}, '');
        if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }

        $_ = send_cmd $s, MIME::Base64::encode_base64($self->{'authpwd'}, '');
        if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }
    }
    return;
}

sub Mail::Sender::Auth::CRAM_MD5 {
    my $self = shift();
    my $s    = $self->{'socket'};

    $_ = send_cmd $s, "AUTH CRAM-MD5";
    if (!/^[123]/) { return $self->Error(_INVALIDAUTH('CRAM-MD5', $_)); }
    my $stamp = $1 if /^\d{3}\s+(.*)$/;

    unless ($MD5_loaded) {
        eval 'use Digest::HMAC_MD5 qw(hmac_md5_hex)';
        die "$@\n" if $@;
        $MD5_loaded = 1;
    }

    my $user   = $self->{'authid'};
    my $secret = $self->{'authpwd'};

    my $decoded_stamp = MIME::Base64::decode_base64($stamp);
    my $hmac          = hmac_md5_hex($decoded_stamp, $secret);
    my $answer        = MIME::Base64::encode_base64($user . ' ' . $hmac, '');
    $_ = send_cmd $s, $answer;
    if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }
    return;
}

sub Mail::Sender::Auth::PLAIN {
    my $self = shift();
    my $s    = $self->{'socket'};

    $_ = send_cmd $s, "AUTH PLAIN";
    if (!/^[123]/) { return $self->Error(_INVALIDAUTH('PLAIN', $_)); }

    $_ = send_cmd $s,
        MIME::Base64::encode_base64(
        "\000" . $self->{'authid'} . "\000" . $self->{'authpwd'}, '');
    if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }
    return;
}

{
    my $NTLM_loaded = 0;

    sub Mail::Sender::Auth::NTLM {
        unless ($NTLM_loaded) {
            eval "use Authen::NTLM qw();";
            die "$@\n" if $@;
            $NTLM_loaded = 1;
        }
        my $self = shift();
        my $s    = $self->{'socket'};

        $_ = send_cmd $s, "AUTH NTLM";
        if (!/^[123]/) { return $self->Error(_INVALIDAUTH('NTLM', $_)); }

        Authen::NTLM::ntlm_reset();
        Authen::NTLM::ntlm_user($self->{'authid'});
        Authen::NTLM::ntlm_password($self->{'authpwd'});
        Authen::NTLM::ntlm_domain($self->{'authdomain'})
            if defined $self->{'authdomain'};

        $_ = send_cmd $s, Authen::NTLM::ntlm();
        if (!/^3\d\d (.*)$/s) { return $self->Error(_LOGINERROR($_)); }
        my $response = $1;
        $_ = send_cmd $s, Authen::NTLM::ntlm($response);
        if (!/^[123]/) { return $self->Error(_LOGINERROR($_)); }
        return;
    }
}

sub Mail::Sender::Auth::AUTOLOAD {
    (my $auth = $Mail::Sender::Auth::AUTOLOAD) =~ s/.*:://;
    my $self = shift();
    my $s    = $self->{'socket'};
    send_cmd $s, "QUIT";
    close $s;
    delete $self->{'socket'};
    return $self->Error(_UNKNOWNAUTH($auth));
}

my $debug_code;

sub __Debug {
    my ($socket, $file) = @_;
    if (defined $file) {
        unless (@Mail::Sender::DBIO::ISA) {
            eval "use Symbol;";
            eval $debug_code;
            die $@ if $@;
        }
        my $handle = gensym();
        *$handle = \$socket;
        if (!ref $file) {
            open my $DEBUG, '>', $file
                or die "Cannot open the debug file '$file': $^E\n";
            binmode $DEBUG;
            $DEBUG->autoflush();
            tie *$handle, 'Mail::Sender::DBIO', $socket, $DEBUG, 1;
        }
        else {
            my $DEBUG = $file;
            tie *$handle, 'Mail::Sender::DBIO', $socket, $DEBUG, 0;
        }
        bless $handle, 'Mail::Sender::DBIO';
        return $handle;
    }
    else {
        return $socket;
    }
}

#internale

sub _HOSTNOTFOUND {
    my $msg = shift || '';
    $!     = 2;
    $Error = "The SMTP server $msg was not found";
    return -1, $Error;
}

sub _CONNFAILED {
    $!     = 5;
    $Error = "connect() failed: $^E";
    return -3, $Error;
}

sub _SERVNOTAVAIL {
    my $msg = shift || '';
    $!     = 40;
    $Error = "Service not available. "
        . ($msg ? "Reply: $msg" : "Server closed the connection unexpectedly");
    return -4, $Error;
}

sub _COMMERROR {
    my $msg = shift || '';
    $! = 5;
    if ($msg eq '') {
        $Error = "No response from server";
    }
    else {
        $Error = "Server error: $msg";
    }
    return -5, $Error;
}

sub _USERUNKNOWN {
    my $user = shift || '';
    my $host = shift || '';
    my $err  = shift || '';
    $! = 2;
    if ($err and $err !~ /Local user/i) {
        $err =~ s/^\d+\s*//;
        $err =~ s/\s*$//s;
        $err ||= "Error";
        $Error = "$err for \"$user\" on host \"$host\"";
    }
    else {
        $Error = "Local user \"$user\" unknown on host \"$host\"";
    }
    return -6, $Error;
}

sub _TRANSFAILED {
    my $msg = shift || '';
    $!     = 5;
    $Error = "Transmission of message failed ($msg)";
    return -7, $Error;
}

sub _TOEMPTY {
    $!     = 14;
    $Error = "Argument \$to empty";
    return -8, $Error;
}

sub _NOMSG {
    $!     = 22;
    $Error = "No message specified";
    return -9, $Error;
}

sub _NOFILE {
    $!     = 22;
    $Error = "No file name specified";
    return -10, $Error;
}

sub _FILENOTFOUND {
    my $msg = shift || '';
    $!     = 2;
    $Error = "File \"$msg\" not found";
    return -11, $Error;
}

sub _NOTMULTIPART {
    my $msg = shift || '';
    $!     = 40;
    $Error = "$msg not available in singlepart mode";
    return -12, $Error;
}

sub _SITEERROR {
    $!     = 15;
    $Error = "Site specific error";
    return -13, $Error;
}

sub _NOTCONNECTED {
    $!     = 1;
    $Error = "Connection not established";
    return -14, $Error;
}

sub _NOSERVER {
    $!     = 22;
    $Error = "No SMTP server specified";
    return -15, $Error;
}

sub _NOFROMSPECIFIED {
    $!     = 22;
    $Error = "No From: address specified";
    return -16, $Error;
}

sub _INVALIDAUTH {
    my $proto = shift || '';
    my $res   = shift || '';
    $!     = 22;
    $Error = "Authentication protocol $proto is not accepted by the server";
    $Error .= ",\nresponse: $res" if $res;
    return -17, $Error;
}

sub _LOGINERROR {
    $!     = 22;
    $Error = "Login not accepted";
    return -18, $Error;
}

sub _UNKNOWNAUTH {
    my $msg = shift || '';
    $!     = 22;
    $Error = "Authentication protocol $msg is not implemented by Mail::Sender";
    return -19, $Error;
}

sub _ALLRECIPIENTSBAD {
    $!     = 2;
    $Error = "All recipients are bad";
    return -20, $Error;
}

sub _FILECANTREAD {
    my $msg = shift || '';
    $Error = "File \"$msg\" cannot be read: $^E";
    return -21, $Error;
}

sub _DEBUGFILE {
    $Error = shift;
    return -22, $Error;
}

sub _STARTTLS {
    my $msg = shift || '';
    my $two = shift || '';
    $!     = 5;
    $Error = "STARTTLS failed: $msg $two";
    return -23, $Error;
}

sub _IO_SOCKET_SSL {
    my $msg = shift || '';
    $!     = 5;
    $Error = "IO::Socket::SSL->start_SSL failed: $msg";
    return -24, $Error;
}

sub _TLS_UNSUPPORTED_BY_ME {
    my $msg = shift || '';
    $!     = 5;
    $Error = "TLS unsupported by the script: $msg";
    return -25, $Error;
}

sub _TLS_UNSUPPORTED_BY_SERVER {
    $!     = 5;
    $Error = "TLS unsupported by server";
    return -26, $Error;
}

sub _UNKNOWNENCODING {
    my $msg = shift || '';
    $!     = 5;
    $Error = "Unknown encoding '$msg'";
    return -27, $Error;
}

sub new {
    my $this = shift;
    my $self = {};
    my $class;
    if (ref($this)) {
        $class = ref($this);
        %$self = %$this;
    }
    else {
        $class = $this;
    }
    bless $self, $class;
    return $self->_initialize(@_);
}

sub _initialize {
    undef $Error;
    my $self = shift;

    delete $self->{'_buffer'};
    $self->{'debug'} = 0;
    $self->{'proto'} = (getprotobyname('tcp'))[2];

    $self->{'port'}  = getservbyname('smtp', 'tcp') || 25
        unless $self->{'port'};

    $self->{'boundary'} = 'Message-Boundary-by-Mail-Sender-' . time();
    $self->{'multipart'}   = 'mixed';    # default is multipart/mixed
    $self->{'tls_allowed'} = 1;

    $self->{'client'} = $local_name;

    # Copy defaults from %default
    foreach my $key (keys %default) {
        $self->{lc $key} = $default{$key};
    }

    if (@_ != 0) {
        if (ref $_[0] eq 'HASH') {
            my $hash = $_[0];
            foreach my $key (keys %$hash) {
                $self->{lc $key} = $hash->{$key};
            }
            $self->{'reply'} = $self->{'replyto'}
                if ($self->{'replyto'} and !$self->{'reply'});
        }
        else {
            (
                $self->{'from'}, $self->{'reply'},   $self->{'to'},
                $self->{'smtp'}, $self->{'subject'}, $self->{'headers'},
                $self->{'boundary'}
            ) = @_;
        }
    }

    $self->{'fromaddr'}  = $self->{'from'};
    $self->{'replyaddr'} = $self->{'reply'};

    $self->_prepare_addresses('to')  if $self->{'to'};
    $self->_prepare_addresses('cc')  if $self->{'cc'};
    $self->_prepare_addresses('bcc') if $self->{'bcc'};

    $self->_prepare_ESMTP() if defined $self->{'esmtp'};

    # get from email address
    $self->{'fromaddr'} =~ s/.*<([^\s]*?)>/$1/ if ($self->{'fromaddr'});

    if ($self->{'replyaddr'}) {
        $self->{'replyaddr'} =~ s/.*<([^\s]*?)>/$1/;   # get reply email address
        $self->{'replyaddr'} =~ s/^([^\s]+).*/$1/;     # use first address
    }

    if ($self->{'smtp'}) {
        $self->{'smtp'} =~ s/^\s+//g;    # remove spaces around $smtp
        $self->{'smtp'} =~ s/\s+$//g;

        unless ($self->{'smtpaddr'} = Socket::inet_aton($self->{'smtp'})) {
            return $self->Error(_HOSTNOTFOUND($self->{'smtp'}));
        }
        $self->{'smtpaddr'} = $1 if ($self->{'smtpaddr'} =~ /(.*)/s);  # Untaint
    }

    $self->{'boundary'} =~ tr/=/-/ if defined $self->{'boundary'};

    $self->_prepare_headers() if defined $self->{'headers'};

    return $self;
}

sub GuessCType {
    my $file = shift;
    if (defined $file && $file =~ /\.(.*)$/) {
        return $CTypes{uc($1)} || 'application/octet-stream';
    }
    return 'application/octet-stream';
}

sub Connect {
    my $self = shift();

    my $s = IO::Socket::INET->new(
        PeerHost => $self->{'smtp'},
        PeerPort => $self->{'port'},
        Proto    => "tcp",
        Timeout  => ($self->{'timeout'} || 120),
    ) or return $self->Error(_CONNFAILED);

    $s->autoflush(1);
    binmode($s);

    if ($self->{'debug'}) {
        eval { $s = __Debug($s, $self->{'debug'}); }
            or return $self->Error(_DEBUGFILE($@));
        $self->{'debug_level'} = 4 unless defined $self->{'debug_level'};
    }

    $_ = get_response($s);
    if (not $_ or !/^[123]/) { return $self->Error(_SERVNOTAVAIL($_)); }
    $self->{'server'} = substr $_, 4;
    $self->{'!greeting'} = $_;

    {
        my $res = $self->_say_helo($s);
        return $res if $res;
    }

    if (
            ($self->{tls_required} or $self->{tls_allowed})
        and !$TLS_notsupported
        and (  defined($self->{'supports'}{STARTTLS})
            or defined($self->{'supports'}{TLS}))
        )
    {
        Net::SSLeay::load_error_strings();
        Net::SSLeay::SSLeay_add_ssl_algorithms();
        $Net::SSLeay::random_device = $0 if (!-s $Net::SSLeay::random_device);
        Net::SSLeay::randomize();

        my $res = send_cmd $s, "STARTTLS";
        my ($code, $text) = split(/\s/, $res, 2);

        return $self->Error(_STARTTLS($code, $text)) if ($code != 220);

        my %ssl_options = (
            SSL_version     => 'TLSv1',
            SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE(),
        );
        if (exists $self->{ssl_version}) {
            $ssl_options{SSL_version} = $self->{ssl_version};
        }
        if (exists $self->{ssl_verify_mode}) {
            $ssl_options{SSL_verify_mode} = $self->{ssl_verify_mode};
        }
        if (exists $self->{ssl_ca_path}) {
            $ssl_options{SSL_ca_path} = $self->{ssl_ca_path};
        }
        if (exists $self->{ssl_ca_file}) {
            $ssl_options{SSL_ca_file} = $self->{ssl_ca_file};
        }
        if (exists $self->{ssl_verifycb_name}) {
            $ssl_options{SSL_verifycb_name} = $self->{ssl_verifycb_name};
        }
        if (exists $self->{ssl_verifycn_schema}) {
            $ssl_options{ssl_verifycn_schema} = $self->{ssl_verifycn_schema};
        }
        if (exists $self->{ssl_hostname}) {
            $ssl_options{SSL_hostname} = $self->{ssl_hostname};
        }

        if ($self->{'debug'}) {
            $res = IO::Socket::SSL->start_SSL(tied(*$s)->[0], %ssl_options);
        }
        else {
            $res = IO::Socket::SSL->start_SSL($s, %ssl_options);
        }
        if (!$res) {
            return $self->Error(_IO_SOCKET_SSL(IO::Socket::SSL::errstr()));
        }

        {
            my $res = $self->_say_helo($s);
            return $res if $res;
        }
    }
    elsif ($self->{tls_required}) {
        if ($TLS_notsupported) {
            return $self->Error(_TLS_UNSUPPORTED_BY_ME($TLS_notsupported));
        }
        else {
            return $self->Error(_TLS_UNSUPPORTED_BY_SERVER());
        }
    }

    if ($self->{'auth'} or $self->{'username'}) {
        $self->{'socket'} = $s;
        my $res = $self->login();
        return $res if $res;
        delete $self->{'socket'};    # it's supposed to be added later
    }

    return $s;
}

sub Error {
    my $self = shift();
    if (@_) {
        if (defined $self->{'socket'}) {
            my $s = $self->{'socket'};
            print $s "quit\x0D\x0A";
            close $s;
            delete $self->{'socket'};
        }
        delete $self->{'_data'};
        ($self->{'error'}, $self->{'error_msg'}) = @_;
    }
    if ($self->{'die_on_errors'} or ($self->{on_errors} && $self->{'on_errors'} eq 'die')) {
        die $self->{'error_msg'} . "\n";
    }
    elsif (exists $self->{'on_errors'}
        and (!defined($self->{'on_errors'}) or $self->{'on_errors'} eq 'undef'))
    {
        return;
    }
    return $self->{'error'};
}

sub ClearErrors {
    my $self = shift();
    delete $self->{'error'};
    delete $self->{'error_msg'};
    undef $Error;
}

sub _prepare_addresses {
    my ($self, $type) = @_;
    if (ref $self->{$type}) {
        $self->{$type . '_list'}
            = [map { s/\s+$//; s/^\s+//; $_ } @{$self->{$type}}];
        $self->{$type} = join ', ', @{$self->{$type . '_list'}};
    }
    else {
        $self->{$type} =~ s/\s+/ /g;
        $self->{$type} =~ s/, ?,/,/g;
        $self->{$type . '_list'} = [map { s/\s+$//; $_ }
                $self->{$type} =~ /((?:[^",]+|"[^"]*")+)(?:,\s*|\s*$)/g ];
    }
}

sub _prepare_ESMTP {
    my $self = shift;
    $self->{esmtp}
        = {%{$self->{esmtp}}};    # make a copy of the hash. Just in case

    $self->{esmtp}{ORCPT} = 'rfc822;' . $self->{esmtp}{ORCPT}
        if $self->{esmtp}{ORCPT} ne '' and $self->{esmtp}{ORCPT} !~ /;/;
    for (qw(ENVID ORCPT)) {
        $self->{esmtp}{$_} = enc_xtext($self->{esmtp}{$_});
    }
}

sub _prepare_headers {
    my $self = shift;
    return unless exists $self->{'headers'};
    if ($self->{'headers'} eq '') {
        delete $self->{'headers'};
        delete $self->{'_headers'};
        return;
    }
    if (ref($self->{'headers'}) eq 'HASH') {
        my $headers = '';
        while (my ($hdr, $value) = each %{$self->{'headers'}}) {
            for ($hdr, $value) {
                s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg
                    ;    # convert all end-of-lines to CRLF
                s/^(?:\x0D\x0A)+//;    # strip leading
                s/(?:\x0D\x0A)+$//;    # and trailing end-of-lines
                s/\x0D\x0A(\S)/\x0D\x0A\t$1/sg;
                if (length($_) > 997) {    # header too long, max 1000 chars
                    s/(.{1,980}[;,])\s+(\S)/$1\x0D\x0A\t$2/g;
                }
            }
            $headers .= "$hdr: $value\x0D\x0A";
        }
        $headers =~ s/(?:\x0D\x0A)+$//;    # and trailing end-of-lines
        $self->{'_headers'} = $headers;
    }
    elsif (ref($self->{'headers'})) {
    }
    else {
        $self->{'_headers'} = $self->{'headers'};
        for ($self->{'_headers'}) {
            s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg; # convert all end-of-lines to CRLF
            s/^(?:\x0D\x0A)+//;               # strip leading
            s/(?:\x0D\x0A)+$//;               # and trailing end-of-lines
        }
    }
}

sub Open {
    undef $Error;
    my $self = shift;
    local $_;
    if (!$self->{'keepconnection'} and $self->{'_data'})
    {    # the user did not Close() or Cancel() the previous mail
        if ($self->{'error'}) {
            $self->Cancel;
        }
        else {
            $self->Close;
        }
    }

    delete $self->{'error'};
    delete $self->{'encoding'};
    delete $self->{'messageid'};
    my %changed;
    $self->{'multipart'}    = 0;
    $self->{'_had_newline'} = 1;

    if (ref $_[0] eq 'HASH') {
        my $key;
        my $hash = $_[0];
        $hash->{'reply'} = $hash->{'replyto'}
            if (defined $hash->{'replyto'} and !defined $hash->{'reply'});
        foreach $key (keys %$hash) {
            if (ref($hash->{$key}) eq 'HASH' and exists $self->{lc $key}) {
                if (ref($self->{lc $key}) eq 'HASH') {
                    $self->{lc $key} = {%{$self->{lc $key}}, %{$hash->{$key}}};
                }
                else {
                    $self->{lc $key} = {%{$hash->{$key}}}; # make a shallow copy
                }
            }
            else {
                $self->{lc $key} = $hash->{$key};
            }
            $changed{lc $key} = 1;
        }
    }
    else {
        my ($from, $reply, $to, $smtp, $subject, $headers) = @_;

        if ($from)  { $self->{'from'}  = $from;  $changed{'from'}  = 1; }
        if ($reply) { $self->{'reply'} = $reply; $changed{'reply'} = 1; }
        if ($to)    { $self->{'to'}    = $to;    $changed{'to'}    = 1; }
        if ($smtp)  { $self->{'smtp'}  = $smtp;  $changed{'smtp'}  = 1; }
        if ($subject) {
            $self->{'subject'} = $subject;
            $changed{'subject'} = 1;
        }
        if ($headers) {
            $self->{'headers'} = $headers;
            $changed{'headers'} = 1;
        }
    }

    $self->_prepare_addresses('to')  if $changed{'to'};
    $self->_prepare_addresses('cc')  if $changed{'cc'};
    $self->_prepare_addresses('bcc') if $changed{'bcc'};

    $self->_prepare_ESMTP() if defined $changed{'esmtp'};

    $self->{'boundary'} =~ tr/=/-/ if defined $changed{'boundary'};

    return $self->Error(_NOFROMSPECIFIED) unless defined $self->{'from'};

    if ($changed{'from'}) {
        $self->{'fromaddr'} = $self->{'from'};
        $self->{'fromaddr'} =~ s/.*<([^\s]*?)>/$1/;    # get from email address
    }

    if ($changed{'reply'}) {
        $self->{'replyaddr'} = $self->{'reply'};
        $self->{'replyaddr'} =~ s/.*<([^\s]*?)>/$1/;   # get reply email address
        $self->{'replyaddr'} =~ s/^([^\s]+).*/$1/;     # use first address
    }

    if ($changed{'smtp'}) {
        $self->{'smtp'} =~ s/^\s+//g;    # remove spaces around $smtp
        $self->{'smtp'} =~ s/\s+$//g;
        $self->{'smtpaddr'} = Socket::inet_aton($self->{'smtp'});
        if (!defined($self->{'smtpaddr'})) {
            return $self->Error(_HOSTNOTFOUND($self->{'smtp'}));
        }
        $self->{'smtpaddr'} = $1 if ($self->{'smtpaddr'} =~ /(.*)/s);  # Untaint
        if (exists $self->{'socket'}) {
            my $s = $self->{'socket'};
            close $s;
            delete $self->{'socket'};
        }
    }

    $self->_prepare_headers() if ($changed{'headers'});

    if (!$self->{'to'}) { return $self->Error(_TOEMPTY); }

    return $self->Error(_NOSERVER) unless defined $self->{'smtp'};

    if ($Mail::Sender::{'SiteHook'} and !$self->SiteHook()) {
        return defined $self->{'error'} ? $self->{'error'} : $self->{'error'}
            = _SITEERROR();
    }

    my $s = $self->{'socket'} || $self->Connect();
    return $s
        unless ref $s;    # return the error number if we did not get a socket
    $self->{'socket'} = $s;

    $_ = send_cmd $s,
        "MAIL FROM:<".($self->{'fromaddr'}||'').">".($self->{esmtp}{_MAIL_FROM}||'');
    if (!/^[123]/) { return $self->Error(_COMMERROR($_)); }

    {
        local $^W;
        if ($self->{'skip_bad_recipients'}) {
            my $good_count = 0;
            my %failed;
            foreach my $addr (
                @{$self->{'to_list'}},
                @{$self->{'cc_list'}},
                @{$self->{'bcc_list'}}
                )
            {
                if ($addr =~ /<(.*)>/) {
                    $_ = send_cmd $s, "RCPT TO:<$1>$self->{esmtp}{_RCPT_TO}";
                }
                else {
                    $_ = send_cmd $s, "RCPT TO:<$addr>$self->{esmtp}{_RCPT_TO}";
                }
                if (!/^[123]/) {
                    chomp;
                    s/^\d{3} //;
                    $failed{$addr} = $_;
                }
                else {
                    $good_count++;
                }
            }
            $self->{'skipped_recipients'} = \%failed if %failed;
            if ($good_count == 0) {
                return $self->Error(_ALLRECIPIENTSBAD);
            }
        }
        else {
            foreach my $addr (
                @{$self->{'to_list'}},
                @{$self->{'cc_list'}},
                @{$self->{'bcc_list'}}
                )
            {
                if ($addr =~ /<(.*)>/) {
                    $_ = send_cmd $s, "RCPT TO:<$1>$self->{esmtp}{_RCPT_TO}";
                }
                else {
                    $_ = send_cmd $s, "RCPT TO:<".($addr||'').">".($self->{esmtp}{_RCPT_TO}||'');
                }
                if (!/^[123]/) {
                    return $self->Error(
                        _USERUNKNOWN($addr, $self->{'smtp'}, $_));
                }
            }
        }
    }

    $_ = send_cmd $s, "DATA";
    if (!/^[123]/) { return $self->Error(_COMMERROR($_)); }

    $self->{'socket'}
        ->stop_logging("\x0D\x0A... message headers and data skipped ...")
        if ($self->{'debug'} and $self->{'debug_level'} <= 1);
    $self->{'_data'} = 1;

    $self->{'ctype'} = 'text/plain'
        if (defined $self->{'charset'} and !defined $self->{'ctype'});

    my $headers;
    if (defined $self->{'encoding'} or defined $self->{'ctype'}) {
        $headers = 'MIME-Version: 1.0';
        $headers .= "\r\nContent-Type: $self->{'ctype'}"
            if defined $self->{'ctype'};
        $headers .= "; charset=$self->{'charset'}"
            if defined $self->{'charset'};

        undef $self->{'chunk_size'};
        if (defined $self->{'encoding'}) {
            $headers .= "\r\nContent-Transfer-Encoding: $self->{'encoding'}";
            if ($self->{'encoding'} =~ /Base64/i) {
                $self->{'code'}       = enc_base64($self->{'charset'});
                $self->{'chunk_size'} = $enc_base64_chunk;
            }
            elsif ($self->{'encoding'} =~ /Quoted[_\-]print/i) {
                $self->{'code'} = enc_qp($self->{'charset'});
            }
            elsif ($self->{'encoding'} =~ /^[78]bit$/i) {
                $self->{'code'} = enc_plain($self->{charset});
            }
            else {
                return $self->Error(_UNKNOWNENCODING($self->{'encoding'}));
            }
        }
    }

    $self->{'code'} = enc_plain($self->{charset}) unless $self->{'code'};

    _print_hdr $s,
        "To" =>
        (defined $self->{'fake_to'} ? $self->{'fake_to'} : $self->{'to'}),
        $self->{'charset'};
    _print_hdr $s,
        "From" =>
        (defined $self->{'fake_from'} ? $self->{'fake_from'} : $self->{'from'}),
        $self->{'charset'};
    if (defined $self->{'fake_cc'} and $self->{'fake_cc'}) {
        _print_hdr $s, "Cc" => $self->{'fake_cc'}, $self->{'charset'};
    }
    elsif (defined $self->{'cc'} and $self->{'cc'}) {
        _print_hdr $s, "Cc" => $self->{'cc'}, $self->{'charset'};
    }
    _print_hdr $s, "Reply-To", $self->{'reply'}, $self->{'charset'}
        if defined $self->{'reply'};

    $self->{'subject'} = "<No subject>" unless defined $self->{'subject'};
    _print_hdr $s, "Subject" => $self->{'subject'}, $self->{'charset'};

    unless (defined $Mail::Sender::NO_DATE and $Mail::Sender::NO_DATE
        or defined $self->{'_headers'} and $self->{'_headers'} =~ /^Date:/m
        or defined $Mail::Sender::SITE_HEADERS
        && $Mail::Sender::SITE_HEADERS =~ /^Date:/m)
    {
        my $date = localtime();
        $date
            =~ s/^(\w+)\s+(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+(\d+)$/$1, $3 $2 $5 $4/;
        _print_hdr $s, "Date" => "$date $GMTdiff";
    }

    if ($self->{'priority'}) {
        $self->{'priority'} = $priority[$self->{'priority'}]
            if ($self->{'priority'} + 0 eq $self->{'priority'});
        _print_hdr $s, "X-Priority" => $self->{'priority'};
    }

    if ($self->{'confirm'}) {
        for my $confirm (split /\s*,\s*/, $self->{'confirm'}) {
            if ($confirm =~ /^\s*reading\s*(?:\:\s*(.*))?/i) {
                _print_hdr $s,
                    "X-Confirm-Reading-To" => ($1 || $self->{'from'}),
                    $self->{'charset'};
            }
            elsif ($confirm =~ /^\s*delivery\s*(?:\:\s*(.*))?/i) {
                _print_hdr $s,
                    "Return-Receipt-To" => ($1 || $self->{'fromaddr'}),
                    $self->{'charset'};
                _print_hdr $s,
                    "Disposition-Notification-To" =>
                    ($1 || $self->{'fromaddr'}),
                    $self->{'charset'};
            }
        }
    }

    unless (defined $Mail::Sender::NO_X_MAILER) {
        my $script = File::Basename::basename($0);
        _print_hdr $s,
            "X-Mailer" =>
            qq{Perl script "$script"\r\n\tusing Mail::Sender $VERSION by Jenda Krynicky, Czechlands\r\n\trunning on $local_name ($local_IP)\r\n\tunder account "}
            . getusername()
            . qq{"\r\n};
    }

    unless (defined $Mail::Sender::NO_MESSAGE_ID
        and $Mail::Sender::NO_MESSAGE_ID)
    {
        if (!defined $self->{'messageid'} or $self->{'messageid'} eq '') {
            if (defined $self->{'createmessageid'}
                and ref $self->{'createmessageid'} eq 'CODE')
            {
                $self->{'messageid'}
                    = $self->{'createmessageid'}->($self->{'fromaddr'});
            }
            else {
                $self->{'messageid'} = MessageID($self->{'fromaddr'});
            }
        }
        _print_hdr $s, "Message-ID" => $self->{'messageid'};
    }

    print $s $Mail::Sender::SITE_HEADERS,
        "\x0D\x0A"    #<???> should handle \r\n at the end of the headers
        if (defined $Mail::Sender::SITE_HEADERS);

    print $s $self->{'_headers'}, "\x0D\x0A"
        if defined $self->{'_headers'} and $self->{'_headers'};
    print $s $headers, "\r\n" if defined $headers;

    print $s "\r\n";

    $self->{'socket'}->stop_logging("... message data skipped ...")
        if ($self->{'debug'} and $self->{'debug_level'} <= 2);

    return $self;
}

sub OpenMultipart {
    undef $Error;
    my $self = shift;

    local $_;
    if (!$self->{'keepconnection'} and $self->{'_data'})
    {    # the user did not Close() or Cancel() the previous mail
        if ($self->{'error'}) {
            $self->Cancel;
        }
        else {
            $self->Close;
        }
    }

    delete $self->{'error'};
    delete $self->{'encoding'};
    delete $self->{'messageid'};
    $self->{'_part'} = 0;

    my %changed;
    if (defined $self->{'type'} and $self->{'type'}) {
        $self->{'multipart'} = $1 if $self->{'type'} =~ m{^multipart/(.*)}i;
    }
    $self->{'multipart'} = 'Mixed' unless $self->{'multipart'};
    $self->{'idcounter'} = 0;

    if (ref $_[0] eq 'HASH') {
        my $key;
        my $hash = $_[0];
        $hash->{'multipart'} = $hash->{'subtype'} if defined $hash->{'subtype'};
        $hash->{'reply'} = $hash->{'replyto'}
            if (defined $hash->{'replyto'} and !defined $hash->{'reply'});
        foreach $key (keys %$hash) {
            if ((ref($hash->{$key}) eq 'HASH') and exists($self->{lc $key})) {
                if (ref($self->{lc $key}) eq 'HASH') {
                    $self->{lc $key} = {%{$self->{lc $key}}, %{$hash->{$key}}};
                }
                else {
                    $self->{lc $key} = {%{$hash->{$key}}}; # make a shallow copy
                }
            }
            else {
                $self->{lc $key} = $hash->{$key};
            }
            $changed{lc $key} = 1;
        }
    }
    else {
        my ($from, $reply, $to, $smtp, $subject, $headers, $boundary) = @_;

        if ($from)  { $self->{'from'}  = $from;  $changed{'from'}  = 1; }
        if ($reply) { $self->{'reply'} = $reply; $changed{'reply'} = 1; }
        if ($to)    { $self->{'to'}    = $to;    $changed{'to'}    = 1; }
        if ($smtp)  { $self->{'smtp'}  = $smtp;  $changed{'smtp'}  = 1; }
        if ($subject) {
            $self->{'subject'} = $subject;
            $changed{'subject'} = 1;
        }
        if ($headers) {
            $self->{'headers'} = $headers;
            $changed{'headers'} = 1;
        }
        if ($boundary) { $self->{'boundary'} = $boundary; }
    }

    $self->_prepare_addresses('to')  if $changed{'to'};
    $self->_prepare_addresses('cc')  if $changed{'cc'};
    $self->_prepare_addresses('bcc') if $changed{'bcc'};

    $self->_prepare_ESMTP() if defined $changed{'esmtp'};

    $self->{'boundary'} =~ tr/=/-/ if $changed{'boundary'};

    $self->_prepare_headers() if ($changed{'headers'});

    return $self->Error(_NOFROMSPECIFIED) unless defined $self->{'from'};
    if ($changed{'from'}) {
        $self->{'fromaddr'} = $self->{'from'};
        $self->{'fromaddr'} =~ s/.*<([^\s]*?)>/$1/;    # get from email address
    }

    if ($changed{'reply'}) {
        $self->{'replyaddr'} = $self->{'reply'};
        $self->{'replyaddr'} =~ s/.*<([^\s]*?)>/$1/;   # get reply email address
        $self->{'replyaddr'} =~ s/^([^\s]+).*/$1/;     # use first address
    }

    if ($changed{'smtp'}) {
        $self->{'smtp'} =~ s/^\s+//g;    # remove spaces around $smtp
        $self->{'smtp'} =~ s/\s+$//g;
        $self->{'smtpaddr'} = Socket::inet_aton($self->{'smtp'});
        if (!defined($self->{'smtpaddr'})) {
            return $self->Error(_HOSTNOTFOUND($self->{'smtp'}));
        }
        $self->{'smtpaddr'} = $1 if ($self->{'smtpaddr'} =~ /(.*)/s);  # Untaint
        if (exists $self->{'socket'}) {
            my $s = $self->{'socket'};
            close $s;
            delete $self->{'socket'};
        }
    }

    if (!$self->{'to'}) { return $self->Error(_TOEMPTY); }

    return $self->Error(_NOSERVER) unless defined $self->{'smtp'};

#    if (!defined($self->{'smtpaddr'})) { return $self->Error(_HOSTNOTFOUND($self->{'smtp'})); }

    if ($Mail::Sender::{'SiteHook'} and !$self->SiteHook()) {
        return defined $self->{'error'} ? $self->{'error'} : $self->{'error'}
            = _SITEERROR();
    }

    my $s = $self->{'socket'} || $self->Connect();
    return $s
        unless ref $s;    # return the error number if we did not get a socket
    $self->{'socket'} = $s;

    $_ = send_cmd $s,
        "MAIL FROM:<$self->{'fromaddr'}>$self->{esmtp}{_MAIL_FROM}";
    if (!/^[123]/) { return $self->Error(_COMMERROR($_)); }

    {
        local $^W;
        if ($self->{'skip_bad_recipients'}) {
            my $good_count = 0;
            my %failed;
            foreach my $addr (
                @{$self->{'to_list'}},
                @{$self->{'cc_list'}},
                @{$self->{'bcc_list'}}
                )
            {
                if ($addr =~ /<(.*)>/) {
                    $_ = send_cmd $s, "RCPT TO:<$1>$self->{esmtp}{_RCPT_TO}";
                }
                else {
                    $_ = send_cmd $s, "RCPT TO:<$addr>$self->{esmtp}{_RCPT_TO}";
                }
                if (!/^[123]/) {
                    s/^\d{3} //;
                    $failed{$addr} = $_;
                }
                else {
                    $good_count++;
                }
            }
            $self->{'skipped_recipients'} = \%failed if %failed;
            if ($good_count == 0) {
                return $self->Error(_ALLRECIPIENTSBAD);
            }
        }
        else {
            foreach my $addr (
                @{$self->{'to_list'}},
                @{$self->{'cc_list'}},
                @{$self->{'bcc_list'}}
                )
            {
                if ($addr =~ /<(.*)>/) {
                    $_ = send_cmd $s, "RCPT TO:<$1>$self->{esmtp}{_RCPT_TO}";
                }
                else {
                    $_ = send_cmd $s, "RCPT TO:<$addr>$self->{esmtp}{_RCPT_TO}";
                }
                if (!/^[123]/) {
                    return $self->Error(
                        _USERUNKNOWN($addr, $self->{'smtp'}, $_));
                }
            }
        }
    }

    $_ = send_cmd $s, "DATA";
    if (!/^[123]/) { return $self->Error(_COMMERROR($_)); }

    $self->{'socket'}
        ->stop_logging("\x0D\x0A... message headers and data skipped ...")
        if ($self->{'debug'} and $self->{'debug_level'} <= 1);
    $self->{'_data'} = 1;

    _print_hdr $s,
        "To" =>
        (defined $self->{'fake_to'} ? $self->{'fake_to'} : $self->{'to'}),
        $self->{'charset'};
    _print_hdr $s,
        "From" =>
        (defined $self->{'fake_from'} ? $self->{'fake_from'} : $self->{'from'}),
        $self->{'charset'};
    if (defined $self->{'fake_cc'} and $self->{'fake_cc'}) {
        _print_hdr $s, "Cc" => $self->{'fake_cc'}, $self->{'charset'};
    }
    elsif (defined $self->{'cc'} and $self->{'cc'}) {
        _print_hdr $s, "Cc" => $self->{'cc'}, $self->{'charset'};
    }
    _print_hdr $s,
        "Reply-To" => $self->{'reply'},
        $self->{'charset'}
        if defined $self->{'reply'};

    $self->{'subject'} = "<No subject>" unless defined $self->{'subject'};
    _print_hdr $s, "Subject" => $self->{'subject'}, $self->{'charset'};

    unless (defined $Mail::Sender::NO_DATE and $Mail::Sender::NO_DATE
        or defined $self->{'_headers'} and $self->{'_headers'} =~ /^Date:/m
        or defined $Mail::Sender::SITE_HEADERS
        && $Mail::Sender::SITE_HEADERS =~ /^Date:/m)
    {
        my $date = localtime();
        $date
            =~ s/^(\w+)\s+(\w+)\s+(\d+)\s+(\d+:\d+:\d+)\s+(\d+)$/$1, $3 $2 $5 $4/;
        _print_hdr $s, "Date" => "$date $GMTdiff";
    }

    if ($self->{'priority'}) {
        $self->{'priority'} = $priority[$self->{'priority'}]
            if ($self->{'priority'} + 0 eq $self->{'priority'});
        _print_hdr $s, "X-Priority" => $self->{'priority'};
    }

    if ($self->{'confirm'}) {
        for my $confirm (split /\s*,\s*/, $self->{'confirm'}) {
            if ($confirm =~ /^\s*reading\s*(?:\:\s*(.*))?/i) {
                _print_hdr $s,
                    "X-Confirm-Reading-To" => ($1 || $self->{'from'}),
                    $self->{'charset'};
            }
            elsif ($confirm =~ /^\s*delivery\s*(?:\:\s*(.*))?/i) {
                _print_hdr $s,
                    "Return-Receipt-To" => ($1 || $self->{'fromaddr'}),
                    $self->{'charset'};
                _print_hdr $s,
                    "Disposition-Notification-To" =>
                    ($1 || $self->{'fromaddr'}),
                    $self->{'charset'};
            }
        }
    }

    unless (defined $Mail::Sender::NO_X_MAILER and $Mail::Sender::NO_X_MAILER) {
        my $script = File::Basename::basename($0);
        _print_hdr $s,
            "X-Mailer" =>
            qq{Perl script "$script"\r\n\tusing Mail::Sender $VERSION by Jenda Krynicky, Czechlands\r\n\trunning on $local_name ($local_IP)\r\n\tunder account "}
            . getusername()
            . qq{"\r\n};
    }

    print $s $Mail::Sender::SITE_HEADERS, "\r\n"
        if (defined $Mail::Sender::SITE_HEADERS);

    unless (defined $Mail::Sender::NO_MESSAGE_ID
        and $Mail::Sender::NO_MESSAGE_ID)
    {
        if (!defined $self->{'messageid'} or $self->{'messageid'} eq '') {
            if (defined $self->{'createmessageid'}
                and ref $self->{'createmessageid'} eq 'CODE')
            {
                $self->{'messageid'}
                    = $self->{'createmessageid'}->($self->{'fromaddr'});
            }
            else {
                $self->{'messageid'} = MessageID($self->{'fromaddr'});
            }
        }
        _print_hdr $s, "Message-ID" => $self->{'messageid'};
    }

    print $s $self->{'_headers'}, "\r\n"
        if defined $self->{'_headers'} and $self->{'_headers'};
    print $s "MIME-Version: 1.0\r\n";
    _print_hdr $s, "Content-Type",
        qq{multipart/$self->{'multipart'};\r\n\tboundary="$self->{'boundary'}"};

    print $s "\r\n";
    $self->{'socket'}->stop_logging("... message data skipped ...")
        if ($self->{'debug'} and $self->{'debug_level'} <= 2);

    print $s
        "This message is in MIME format. Since your mail reader does not understand\r\n"
        . "this format, some or all of this message may not be legible.\r\n"
        . "\r\n--$self->{'boundary'}\r\n";

    return $self;
}

sub Connected {
    my $self = shift();
    return unless exists $self->{'socket'} and $self->{'socket'};
    my $s = $self->{'socket'};
    return $s->opened();
}

sub MailMsg {
    my $self = shift;
    my $msg;
    local $_;
    if (ref $_[0] eq 'HASH') {
        my $hash = $_[0];
        $msg = $hash->{'msg'};
    }
    else {
        $msg = pop;
    }
    return $self->Error(_NOMSG) unless $msg;

    if (ref $self->Open(@_) and ref $self->SendEnc($msg) and ref $self->Close())
    {
        return $self;
    }
    else {
        return $self->{'error'};
    }
}

sub MailFile {
    my $self = shift;
    my $msg;
    local $_;
    my ($file, $desc, $haddesc, $ctype, $charset, $encoding);
    my @files;
    my $hash;
    if (ref $_[0] eq 'HASH') {
        $hash = {%{$_[0]}};    # make a copy

        $msg = delete $hash->{'msg'};

        $file = delete $hash->{'file'};

        $desc = delete $hash->{'description'};
        $haddesc = 1 if defined $desc;

        $ctype = delete $hash->{'ctype'};

        $charset = delete $hash->{'charset'};

        $encoding = delete $hash->{'encoding'};
    }
    else {
        $desc    = pop if ($#_ >= 2);
        $haddesc = 1   if defined $desc;
        $file    = pop;
        $msg     = pop;
    }
    return $self->Error(_NOMSG)  unless $msg;
    return $self->Error(_NOFILE) unless $file;

    if (ref $file eq 'ARRAY') {
        @files = @$file;
    }
    elsif ($file =~ /,/) {
        @files = split / *, */, $file;
    }
    else {
        @files = ($file);
    }
    foreach $file (@files) {
        return $self->Error(_FILENOTFOUND($file))
            unless ($file =~ /^&/ or -e $file);
    }

    ref $self->OpenMultipart($hash ? $hash : @_)
        and ref $self->Body($self->{'b_charset'} || $self->{'charset'},
        $self->{'b_encoding'}, $self->{'b_ctype'})
        and $self->SendEnc($msg)
        or return $self->{'error'};

    $Error = '';
    foreach $file (@files) {
        my $cnt;
        my $filename = File::Basename::basename $file;
        my $ctype    = $ctype || GuessCType $filename, $file;
        my $encoding = $encoding
            || ($ctype =~ m#^text/#i ? 'Quoted-printable' : 'Base64');

        $desc = $filename unless (defined $haddesc);

        $self->Part(
            {
                encoding    => $encoding,
                disposition => (
                    defined $self->{'disposition'} ? $self->{'disposition'}
                    : "attachment; filename=\"$filename\""
                ),
                ctype => (
                    $ctype =~ /;\s*name(?:\*(?:0\*?)?)?=/ ? $ctype
                    : "$ctype; name=\"$filename\""
                    )
                    . (defined $charset ? "; charset=$charset" : ''),
                description => $desc
            }
        );

        my $code = $self->{'code'};

        open my $FH, "<", $file or return $self->Error(_FILECANTREAD($file));
        binmode $FH
            unless $ctype =~ m#^text/#i
            and $encoding =~ /Quoted[_\-]print|Base64/i;
        my $s;
        $s = $self->{'socket'};
        my $mychunksize = $chunksize;
        $mychunksize = $chunksize64 if defined $self->{'chunk_size'};
        while (read $FH, $cnt, $mychunksize) {
            $cnt = $code->($cnt);
            $cnt =~ s/^\.\././ unless $self->{'_had_newline'};
            print $s $cnt;
            $self->{'_had_newline'} = ($cnt =~ /[\n\r]$/);
        }
        close $FH;
    }

    if ($Error eq '') {
        undef $Error;
    }
    else {
        chomp $Error;
    }
    return $self->Close;
}

sub Send {
    my $self = shift;
    my $s;
    $s = $self->{'socket'};
    print $s @_;
    return $self;
}

sub SendLine {
    my $self = shift;
    my $s    = $self->{'socket'};
    print $s (@_, "\x0D\x0A");
    return $self;
}

sub print { return shift->SendEnc(@_) }
sub SendLineEnc { push @_, "\r\n"; return shift->SendEnc(@_) }

sub SendEnc {
    my $self = shift;
    local $_;
    my $code = $self->{'code'};
    $self->{'code'} = $code = enc_plain($self->{'charset'})
        unless defined $code;
    my $s;
    $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);
    if (defined $self->{'chunk_size'}) {
        my $str;
        my $chunk = $self->{'chunk_size'};
        if (defined $self->{'_buffer'}) {
            $str = (join '', ($self->{'_buffer'}, @_));
        }
        else {
            $str = join '', @_;
        }
        my ($len, $blen);
        $len = length $str;
        if (($blen = ($len % $chunk)) > 0) {
            $self->{'_buffer'} = substr($str, ($len - $blen));
            print $s ($code->(substr($str, 0, $len - $blen)));
        }
        else {
            delete $self->{'_buffer'};
            print $s ($code->($str));
        }
    }
    else {
        my $encoded = $code->(join('', @_));
        $encoded =~ s/^\.\././ unless $self->{'_had_newline'};
        print $s $encoded;
        $self->{'_had_newline'} = ($_[-1] =~ /[\n\r]$/);
    }
    return $self;
}

sub SendLineEx { push @_, "\r\n"; shift->SendEx(@_) }

sub SendEx {
    my $self = shift;
    my $s;
    $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);
    my $str;
    my @data = @_;
    foreach $str (@data) {
        $str =~ s/(?:\x0D\x0A?|\x0A)/\x0D\x0A/sg;
        $str =~ s/^\./../mg;
    }
    print $s @data;
    return $self;
}

sub Part {
    my $self = shift;
    local $_;
    if (!$self->{'multipart'}) {
        return $self->Error(_NOTMULTIPART("\$sender->Part()"));
    }
    $self->EndPart();

    my ($description, $ctype, $encoding, $disposition, $content_id, $msg,
        $charset);
    if (ref $_[0] eq 'HASH') {
        my $hash = $_[0];
        $description = $hash->{'description'};
        $ctype       = $hash->{'ctype'};
        $encoding    = $hash->{'encoding'};
        $disposition = $hash->{'disposition'};
        $content_id  = $hash->{'content_id'};
        $msg         = $hash->{'msg'};
        $charset     = $hash->{'charset'};
    }
    else {
        ($description, $ctype, $encoding, $disposition, $content_id, $msg) = @_;
    }

    $ctype       = "application/octet-stream" unless defined $ctype;
    $disposition = "attachment"               unless defined $disposition;
    $encoding    = "7BIT"                     unless defined $encoding;
    $self->{'encoding'} = $encoding;
    if (defined $charset and $charset and $ctype !~ /charset=/i) {
        $ctype .= qq{; charset="$charset"};
    }
    elsif (!defined $charset and $ctype =~ /charset="([^"]+)"/) {
        $charset = $1;
    }

    my $s;
    $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);

    undef $self->{'chunk_size'};
    if ($encoding =~ /Base64/i) {
        $self->{'code'}       = enc_base64($charset);
        $self->{'chunk_size'} = $enc_base64_chunk;
    }
    elsif ($encoding =~ /Quoted[_\-]print/i) {
        $self->{'code'} = enc_qp($charset);
    }
    else {
        $self->{'code'} = enc_plain($charset);
    }

    $self->{'socket'}->start_logging()
        if ($self->{'debug'} and $self->{'debug_level'} == 3);

    if ($ctype =~ m{^multipart/}i) {
        $self->{'_part'} += 2;
        print $s
            "Content-Type: $ctype; boundary=\"Part-$self->{'boundary'}_$self->{'_part'}\"\r\n\r\n";
    }
    else {
        $self->{'_part'}++;
        print $s "Content-Type: $ctype\r\n";
        if ($description) { print $s "Content-Description: $description\r\n"; }
        print $s "Content-Transfer-Encoding: $encoding\r\n";
        print $s "Content-Disposition: $disposition\r\n"
            unless $disposition eq ''
            or uc($disposition) eq 'NONE';
        print $s "Content-ID: <$content_id>\r\n" if (defined $content_id);
        print $s "\r\n";

        $self->{'socket'}->stop_logging("... data skipped ...")
            if ($self->{'debug'} and $self->{'debug_level'} == 3);
        $self->SendEnc($msg) if defined $msg;
    }

    #$self->{'_had_newline'} = 1;
    return $self;
}

sub Body {
    my $self = shift;
    if (!$self->{'multipart'}) {

        # ->Body() has no meanin in singlepart messages
        if (@_) {

         # they called it with some parameters? Too late for them, let's scream.
            return $self->Error(_NOTMULTIPART("\$sender->Body()"));
        }
        else {
            # $sender->Body() ... OK, let's ignore it.
            return $self;
        }
    }
    my $hash;
    $hash = shift() if (ref $_[0] eq 'HASH');
    my $charset = shift || $hash->{'charset'} || 'US-ASCII';
    my $encoding
        = shift || $hash->{'encoding'} || $self->{'encoding'} || '7BIT';
    my $ctype = shift || $hash->{'ctype'} || $self->{'ctype'} || 'text/plain';

    $ctype .= qq{; charset="$charset"} unless $ctype =~ /charset=/i;

    $self->{'encoding'} = $encoding;
    $self->{'ctype'}    = $ctype;

    $self->Part("Mail message body",
        $ctype, $encoding, 'inline', undef, $hash->{'msg'});
    return $self;
}

sub Attach { shift->SendFile(@_) }

sub SendFile {
    my $self = shift;
    local $_;
    if (!$self->{'multipart'}) {
        return $self->Error(_NOTMULTIPART("\$sender->SendFile()"));
    }
    if (!$self->{'socket'}) { return $self->Error(_NOTCONNECTED); }

    my ($description, $ctype, $encoding, $disposition, $file, $content_id,
        @files);
    if (ref $_[0] eq 'HASH') {
        my $hash = $_[0];
        $description = $hash->{'description'};
        $ctype       = $hash->{'ctype'};
        $encoding    = $hash->{'encoding'};
        $disposition = $hash->{'disposition'};
        $file        = $hash->{'file'};
        $content_id  = $hash->{'content_id'};
    }
    else {
        ($description, $ctype, $encoding, $disposition, $file, $content_id)
            = @_;
    }
    return ($self->{'error'} = _NOFILE) unless $file;

    if (ref $file eq 'ARRAY') {
        @files = @$file;
    }
    elsif ($file =~ /,/) {
        @files = split / *, */, $file;
    }
    else {
        @files = ($file);
    }
    foreach $file (@files) {
        return $self->Error(_FILENOTFOUND($file))
            unless ($file =~ /^&/ or -e $file);
    }

    $disposition = "attachment; filename=*" unless defined $disposition;
    $encoding = 'Base64' unless $encoding;

    my $s = $self->{'socket'};

    if ($self->{'_buffer'}) {
        my $code = $self->{'code'};
        print $s ($code->($self->{'_buffer'}));
        delete $self->{'_buffer'};
    }

    my $code;
    if ($encoding =~ /Base64/i) {
        $code = enc_base64();
    }
    elsif ($encoding =~ /Quoted[_\-]print/i) {
        $code = enc_qp();
    }
    else {
        $code = enc_plain();
    }
    $self->{'code'} = $code;

    foreach $file (@files) {
        $self->EndPart();
        $self->{'_part'}++;
        $self->{'encoding'} = $encoding;
        my $cnt    = '';
        my $name   = File::Basename::basename $file;
        my $fctype = $ctype ? $ctype : GuessCType $name, $file;
        $self->{'ctype'} = $fctype;

        $self->{'socket'}->start_logging()
            if ($self->{'debug'} and $self->{'debug_level'} == 3);

        if ($fctype =~ /;\s*name(?:\*(?:0\*?)?)?=/)
        {    # looking for name=, name*=, name*0= or name*0*=
            print $s ("Content-Type: $fctype\r\n");
        }
        else {
            print $s ("Content-Type: $fctype; name=\"$name\"\r\n");
        }

        if ($description) {
            print $s ("Content-Description: $description\r\n");
        }
        print $s ("Content-Transfer-Encoding: $encoding\r\n");

        if ($disposition =~ /^(.*)filename=\*(.*)$/i) {
            print $s ("Content-Disposition: ${1}filename=\"$name\"$2\r\n");
        }
        elsif ($disposition and uc($disposition) ne 'NONE') {
            print $s ("Content-Disposition: $disposition\r\n");
        }

        if ($content_id) {
            if ($content_id eq '*') {
                print $s ("Content-ID: <$name>\r\n");
            }
            elsif ($content_id eq '#') {
                print $s ("Content-ID: <id" . $self->{'idcounter'}++ . ">\r\n");
            }
            else {
                print $s ("Content-ID: <$content_id>\r\n");
            }
        }
        print $s "\r\n";

        $self->{'socket'}->stop_logging("... data skipped ...")
            if ($self->{'debug'} and $self->{'debug_level'} == 3);

        open my $FH, "<", $file or return $self->Error(_FILECANTREAD($file));
        binmode $FH
            unless $fctype =~ m#^text/#i
            and $encoding =~ /Quoted[_\-]print|Base64/i;

        my $mychunksize = $chunksize;
        $mychunksize = $chunksize64 if lc($encoding) eq "base64";
        my $s;
        $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);
        while (read $FH, $cnt, $mychunksize) {
            print $s ($code->($cnt));
        }
        close $FH;
    }

    return $self;
}

sub EndPart {
    my $self = shift;
    return unless $self->{'_part'};
    my $end = shift();
    my $s;
    my $LN = "\x0D\x0A";
    $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);

    # flush the buffer (if it contains anything)
    if ($self->{'_buffer'}) {    # used only for base64
        my $code = $self->{'code'};
        if (defined $code) {
            print $s ($code->($self->{'_buffer'}));
        }
        else {
            print $s ($self->{'_buffer'});
        }
        delete $self->{'_buffer'};
    }
    if ($self->{'_had_newline'}) {
        $LN = '';
    }
    else {
        print $s "="
            if !$self->{'bypass_outlook_bug'}
            and $self->{'encoding'}
            =~ /Quoted[_\-]print/i;    # make sure we do not add a newline
    }

    $self->{'socket'}->start_logging()
        if ($self->{'debug'} and $self->{'debug_level'} == 3);

    if ($self->{'_part'} > 1) {        # end of a subpart
        print $s "$LN--Part-$self->{'boundary'}_$self->{'_part'}",
            ($end ? "--" : ()), "\r\n";
    }
    else {
        print $s "$LN--$self->{'boundary'}", ($end ? "--" : ()), "\r\n";
    }

    $self->{'_part'}--;
    $self->{'code'}     = enc_plain($self->{'charset'});
    $self->{'encoding'} = '';
    return $self;
}

sub Close {
    my $self = shift;
    local $_;
    my $s = $self->{'socket'};
    return 0 unless $s;

    if ($self->{'_data'}) {

        # flush the buffer (if it contains anything)
        if ($self->{'_buffer'}) {
            my $code = $self->{'code'};
            if (defined $code) {
                print $s ($code->($self->{'_buffer'}));
            }
            else {
                print $s ($self->{'_buffer'});
            }
            delete $self->{'_buffer'};
        }

        if ($self->{'_part'}) {
            while ($self->{'_part'}) {
                $self->EndPart(1);
            }
        }

        $self->{'socket'}->start_logging() if ($self->{'debug'});
        print $s "\r\n.\r\n";
        $self->{'_data'} = 0;
        $_ = get_response($s);
        if (/^[45]\d* (.*)$/) { return $self->Error(_TRANSFAILED($1)); }
        $self->{message_response} = $_;
    }

    delete $self->{'encoding'};
    delete $self->{'ctype'};

    if ($_[0] or !$self->{'keepconnection'}) {
        $_ = send_cmd $s, "QUIT";
        if (!/^[123]/) { return $self->Error(_COMMERROR($_)); }
        close $s;
        delete $self->{'socket'};
        delete $self->{'debug'};
    }
    return $self;
}

sub Cancel {
    my $self = shift;
    my $s;
    $s = $self->{'socket'} or return $self->Error(_NOTCONNECTED);
    close $s;
    delete $self->{'socket'};
    delete $self->{'error'};
    return $self;
}

sub DESTROY {
    return if ref($_[0]) ne 'Mail::Sender';
    my $self = shift;
    if (defined $self->{'socket'}) {
        delete $self->{'keepconnection'};
        $self->Close;
    }
}

sub MessageID {
    my $from = shift;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
    $mon++;
    $year += 1900;

    return sprintf "<%04d%02d%02d_%02d%02d%02d_%06d.%s>", $year, $mon, $mday,
        $hour, $min, $sec, rand(100000), $from;
}

sub QueryAuthProtocols {
    my $self = shift;
    Carp::croak(
        "Mail::Sender::QueryAuthProtocols() called without any parameter!")
        unless defined $self;
    local $_;
    if (ref $self) {

 # $sender->QueryAuthProtocols() or $sender->QueryAuthProtocols('the.server.com)
        if ($self->{'socket'}) {

            # the user did not Close() or Cancel() the previous mail
            die
                "You forgot to close the mail before calling QueryAuthProtocols!\n";
        }
        if (@_) {
            $self->{'smtp'} = shift();
            $self->{'smtp'} =~ s/^\s+//g;    # remove spaces around $smtp
            $self->{'smtp'} =~ s/\s+$//g;
            $self->{'smtpaddr'} = Socket::inet_aton($self->{'smtp'});
            if (!defined($self->{'smtpaddr'})) {
                return $self->Error(_HOSTNOTFOUND($self->{'smtp'}));
            }
            $self->{'smtpaddr'} = $1
                if ($self->{'smtpaddr'} =~ /(.*)/s);    # Untaint
        }
    }
    elsif ($self =~ /::/) { # Mail::Sender->QueryAuthProtocols('the.server.com')
        Carp::croak
            "Mail::Sender->QueryAuthProtocols() called without any parameter!"
            if !@_;
        $self = Mail::Sender->new({smtp => $_[0]});
        return unless ref $self;
    }
    else {                  # Mail::Sender::QueryAuthProtocols('the.server.com')
        $self = Mail::Sender->new({smtp => $self});
        return unless ref $self;
    }

    return $self->Error(_NOSERVER) unless defined $self->{'smtp'};

    my $s = IO::Socket::INET->new(
        PeerHost => $self->{'smtp'},
        PeerPort => $self->{'port'},
        Proto    => "tcp",
        Timeout  => $self->{'timeout'} || 120,
    ) or return $self->Error(_CONNFAILED);

    $s->autoflush(1);

    $_ = get_response($s);
    if (not $_ or !/^[123]/) { return $self->Error(_SERVNOTAVAIL($_)); }
    $self->{'server'} = substr $_, 4;

    {
        my $res = $self->_say_helo($s);
        return $res if $res;
    }

    $_ = send_cmd $s, "QUIT";
    close $s;
    delete $self->{'socket'};

    if (wantarray) {
        return keys %{$self->{'auth_protocols'}};
    }
    else {
        my $key = each %{$self->{'auth_protocols'}};
        return $key;
    }
}

sub printAuthProtocols {
    print "$_[1] supports: ",
        join(", ", Mail::Sender->QueryAuthProtocols($_[1] || 'localhost')),
        "\n";
}

sub TestServer {
    my $self = shift;
    local $_;
    if (!defined $self) {
        Carp::croak "Mail::Sender::TestServer() called without any parameter!";
    }
    elsif (ref $self)
    {    # $sender->TestServer() or $sender->TestServer('the.server.com)
        if ($self->{'socket'})
        {    # the user did not Close() or Cancel() the previous mail
            die "You forgot to close the mail before calling TestServer!\n";
        }
        if (@_) {
            $self->{'smtp'} = shift();
            $self->{'smtp'} =~ s/^\s+//g;    # remove spaces around $smtp
            $self->{'smtp'} =~ s/\s+$//g;
            $self->{'smtpaddr'} = Socket::inet_aton($self->{'smtp'});
            if (!defined($self->{'smtpaddr'})) {
                return $self->Error(_HOSTNOTFOUND($self->{'smtp'}));
            }
            $self->{'smtpaddr'} = $1
                if ($self->{'smtpaddr'} =~ /(.*)/s);    # Untaint
        }
        $self->{'on_errors'} = 'die';
    }
    elsif ($self =~ /::/) {    # Mail::Sender->TestServer('the.server.com')
        Carp::croak("Mail::Sender->TestServer() called without any parameter!")
            if !@_;
        $self = Mail::Sender->new({smtp => $_[0], on_errors => 'die'});
        return unless ref $self;
    }
    else {    # Mail::Sender::QueryAuthProtocols('the.server.com')
        $self = Mail::Sender->new({smtp => $self, on_errors => 'die'});
        return unless ref $self;
    }

    return $self->Error(_NOSERVER) unless defined $self->{'smtp'};

# if (!defined($self->{'smtpaddr'})) { return $self->Error(_HOSTNOTFOUND($self->{'smtp'})); }

    if (exists $self->{'on_errors'}
        and (!defined($self->{'on_errors'}) or $self->{'on_errors'} eq 'undef'))
    {
        return ($self->Connect() and $self->Close() and 1);
    }
    elsif (exists $self->{'on_errors'} and $self->{'on_errors'} eq 'die') {
        $self->Connect();
        $self->Close();
        return 1;
    }
    else {
        my $res = $self->Connect();
        return $res unless ref $res;
        $res = $self->Close();
        return $res unless ref $res;
        return $self;
    }
}

#====== Debuging bazmecks

$debug_code = <<'END';
package Mail::Sender::DBIO;
use IO::Handle;
use Tie::Handle;
@Mail::Sender::DBIO::ISA = qw(Tie::Handle);

sub SOCKET () {0}
sub LOG () {1}
sub ENDLINE () {2}
sub CLOSELOG () {3}
sub OFF () {4}

sub TIEHANDLE {
    my ($pkg,$socket,$debughandle, $mayCloseLog) = @_;
    return bless [$socket,$debughandle,1, $mayCloseLog,0], $pkg;
}

sub PRINT {
    my $self = shift;
    my $text = join(($\ || ''), @_);
    $self->[SOCKET]->print($text);
    return if $self->[OFF];
    $text =~ s/\x0D\x0A(?=.)/\x0D\x0A<< /g;
    $text = "<< ".$text if $self->[ENDLINE];
    $self->[ENDLINE] = ($text =~ /\x0D\x0A$/);
    $self->[LOG]->print($text);
}

sub READLINE {
    my $self = shift();
    my $socket = $self->[SOCKET];
    my $line = <$socket>;
    $self->[LOG]->print(">> $line") if defined $line and !$self->[OFF];
    return $line;
}

sub CLOSE {
    my $self = shift();
    $self->[SOCKET]->close();
    $self->[LOG]->close() if $self->[CLOSELOG];
    return $self->[SOCKET];
}

sub opened {
    our $SOCKET;
    local *SOCKET = $_[SOCKET] or return;
    $SOCKET->opened();
}

use Data::Dumper;
sub stop_logging {
    my $self = tied(${$_[0]});

#print "stop_logging( ".$self." )\n";

    return if $self->[OFF];
    $self->[OFF] = 1;

    my $text = join(($\ || ''), $_[1])
        or return;
    $text .= "\x0D\x0A";
    $text =~ s/\x0D\x0A(?=.)/\x0D\x0A<< /g;
    $text = "<< ".$text if $self->[ENDLINE];
    $self->[ENDLINE] = ($text =~ /\x0D\x0A$/);
    $self->[LOG]->print($text);
}

sub start_logging {
    my $self = tied(${$_[0]});
    $self->[OFF] = 0;
}
END

my $pseudo_handle_code = <<'END';
package Mail::Sender::IO;
use IO::Handle;
use Tie::Handle;
@Mail::Sender::IO::ISA = qw(Tie::Handle);

sub TIEHANDLE {
    my ($pkg,$sender) = @_;
    return bless [$sender, $sender->{'_part'}], $pkg;
}

sub PRINT {
    my $self = shift;
    $self->[0]->SendEnc(@_);
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    $self->[0]->SendEnc( sprintf $format, @_);
}

sub CLOSE {
    my $self = shift();
    if ($self->[1]) {
        $self->[1]->EndPart();
    } else {
        $self->[0]->Close();
    }
}
END

package Mail::Sender;

sub GetHandle {
    my $self = shift();
    unless (@Mail::Sender::IO::ISA) {
        eval "use Symbol;";
        eval $pseudo_handle_code;
    }
    my $handle = gensym();
    tie *$handle, 'Mail::Sender::IO', $self;
    return $handle;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::Sender - (DEPRECATED) module for sending mails with attachments through an SMTP server

=head1 DEPRECATED

L<Mail::Sender> is deprecated. L<Email::Sender> is the go-to choice when you
need to send Email from Perl.  Go there, be happy!

=head1 SYNOPSIS

  use Mail::Sender;

  my $sender = Mail::Sender->new({
    smtp => 'mail.yourdomain.com',
    from => 'your@address.com'
  });
  $sender->MailFile({
    to => 'some@address.com',
    subject => 'Here is the file',
    msg => "I'm sending you the list you wanted.",
    file => 'filename.txt'
  });

=head1 DESCRIPTION

L<Mail::Sender> is deprecated. L<Email::Sender> is the go-to choice when you
need to send Email from Perl.  Go there, be happy!

L<Mail::Sender> provides an object-oriented interface to sending mails. It directly connects to the mail server using L<IO::Socket>.

=head1 ATTRIBUTES

L<Mail::Sender> implements the following attributes.

* Please note that altering an attribute after object creation is best
handled with creating a copy using C<< $sender = $sender->new({attribute => 'value'}) >>.
To obtain the current value of an attribute, break all the rules and reach in
there! C<< my $val = $sender->{attribute}; >>

=head2 auth

    # mutating single attributes could get costly!
    $sender = $sender->new({auth => 'PLAIN'});
    my $auth = $sender->{auth}; # reach in to grab

The SMTP authentication protocol to use to login to the server currently the
only ones supported are C<LOGIN>, C<PLAIN>, C<CRAM-MD5> and C<NTLM>.
Some protocols have module dependencies. C<CRAM-MD5> depends on L<Digest::HMAC_MD5>
and C<NTLM> on L<Authen::NTLM>.

You may add support for other authentication protocols yourself.

=head2 auth_encoded

    # mutating single attributes could get costly!
    $sender = $sender->new({auth_encoded => 1});
    my $auth_enc = $sender->{auth_encoded}; # reach in to grab

If set to a true value, L<Mail::Sender> attempts to use TLS (encrypted connection)
whenever the server supports it and you have L<IO::Socket::SSL> and L<Net::SSLeay>.

The default value of this option is true! This means that if L<Mail::Sender>
can send the data encrypted, it will.

=head2 authdomain

    # mutating single attributes could get costly!
    $sender = $sender->new({authdomain => 'bar.com'});
    my $domain = $sender->{authdomain}; # reach in to grab

The domain name; used optionally by the C<NTLM> authentication. Other authentication
protocols may use other options as well. They should all start with C<auth> though.

=head2 authid

    # mutating single attributes could get costly!
    $sender = $sender->new({authid => 'username'});
    my $username = $sender->{authid}; # reach in to grab

The username used to login to the server.

=head2 authpwd

    # mutating single attributes could get costly!
    $sender = $sender->new({authpwd => 'password'});
    my $password = $sender->{authpwd}; # reach in to grab

The password used to login to the server.

=head2 bcc

    # mutating single attributes could get costly!
    $sender = $sender->new({bcc => 'foo@bar.com'});
    $sender = $sender->new({bcc => 'foo@bar.com, bar@baz.com'});
    $sender = $sender->new({bcc => ['foo@bar.com', 'bar@baz.com']});
    my $bcc = $sender->{bcc}; # reach in to grab

Send a blind carbon copy to these addresses.

=head2 boundary

    # mutating single attributes could get costly!
    $sender = $sender->new({boundary => '--'});
    my $boundary = $sender->{boundary}; # reach in to grab

The message boundary. You usually do not have to change this, it might only come in handy if you need
to attach a multi-part mail created by L<Mail::Sender> to your message as a
single part. Even in that case any problems are unlikely.

=head2 cc

    # mutating single attributes could get costly!
    $sender = $sender->new({cc => 'foo@bar.com'});
    $sender = $sender->new({cc => 'foo@bar.com, bar@baz.com'});
    $sender = $sender->new({cc => ['foo@bar.com', 'bar@baz.com']});
    my $cc = $sender->{cc}; # reach in to grab

Send a carbon copy to these addresses.

=head2 charset

    # mutating single attributes could get costly!
    $sender = $sender->new({charset => 'UTF-8'});
    my $charset = $sender->{charset}; # reach in to grab

The charset of the single part message or the body of the multi-part one.

=head2 client

    # mutating single attributes could get costly!
    $sender = $sender->new({client => 'localhost.localdomain'});
    my $client = $sender->{client}; # reach in to grab

The name of the client computer.

During the connection you send the mail server your computer's name. By default
L<Mail::Sender> sends C<(gethostbyname 'localhost')[0]>. If that is not the
address your needs, you can specify a different one.

=head2 confirm

    # only delivery, to the 'from' address
    $sender = $sender->new({confirm => 'delivery'});
    # only reading, to the 'from' address
    $sender = $sender->new({confirm => 'reading'});
    # both: to the 'from' address
    $sender = $sender->new({confirm => 'delivery, reading'});
    # delivery: to specified address
    $sender = $sender->new({confirm => 'delivery: my.other@address.com'});
    my $confirm = $sender->{confirm}; # reach in to grab

Whether you want to request reading or delivery confirmations and to what addresses.

Keep in mind that confirmations are not guaranteed to work. Some servers/mail
clients do not support this feature and some users/admins may have disabled it.
So it's possible that your mail was delivered and read, but you won't get any
confirmation!

=head2 createmessageid

    # mutating single attributes could get costly!
    $sender = $sender->new({createmessageid => sub {
        my $from = shift;
        my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
        $mon++;
        $year += 1900;

        return sprintf "<%04d%02d%02d_%02d%02d%02d_%06d.%s>", $year, $mon, $mday,
            $hour, $min, $sec, rand(100000), $from;
    }});
    my $cm_id = $sender->{createmessageid}; # reach in to grab

This option allows you to overwrite the function that generates the message
IDs for the emails. The option gets the "pure" sender's address as it's only
parameter and is supposed to return a string. See the L<Mail::Sender/"MessageID">
method.

If you want to specify a message id you can also use the C<messageid> parameter
for the L<Mail::Sender/"Open">, L<Mail::Sender/"OpenMultipart">,
L<Mail::Sender/"MailMsg"> or L<Mail::Sender/"MailFile"> methods.

=head2 ctype

    # mutating single attributes could get costly!
    $sender = $sender->new({ctype => 'text/plain'});
    my $type = $sender->{ctype}; # reach in to grab

The content type of a single part message or the body of the multi-part one.

Please do not confuse these two. The L<Mail::Sender/"multipart"> parameter is
used to specify the overall content type of a multi-part message (for example any
HTML document with inlined images) while C<ctype> is an ordinary content type
for a single part message or the body of a multi-part message.

=head2 debug

    # mutating single attributes could get costly!
    $sender = $sender->new({debug => '/path/to/debug/file.txt'});
    $sender = $sender->new({debug => $file_handle});
    my $debug = $sender->{debug}; # reach in to grab

All the conversation with the server will be logged to that file or handle.
All lines in the file should end with C<CRLF> (the Windows and Internet format).

If you pass the path to the log file, L<Mail::Sender> will overwrite it.
If you want to append to the file, you have to open it yourself and pass the
filehandle:

    open my $fh, '>>', '/path/to/file.txt' or die "Can't open: $!";
    my $sender = Mail::Sender->new({
        debug => $fh,
    });

=head2 debug_level

    # mutating single attributes could get costly!
    $sender = $sender->new({debug_level => 1});
    # 1: only log server communication, skip all msg data
    # 2: log server comm. and message headers
    # 3: log server comm., message and part headers
    # 4: log everything (default behavior)
    my $level = $sender->{debug_level}; # reach in to grab

Only taken into account if the C<debug> attribute is specified.

=head2 encoding

    # mutating single attributes could get costly!
    $sender = $sender->new({encoding => 'Quoted-printable'});
    my $encoding = $sender->{encoding}; # reach in to grab

Encoding of a single part message or the body of a multi-part message.

If the text of the message contains some extended characters or very long lines,
you should use C<< encoding => 'Quoted-printable' >> in the call to L<Mail::Sender/"Open">,
L<Mail::Sender/"OpenMultipart">, L<Mail::Sender/"MailMsg"> or L<Mail::Sender/"MailFile">.

If you use some encoding you should either use L<Mail::Sender/"SendEnc"> or
encode the data yourself!

=head2 ESMPT

    # mutating single attributes could get costly!
    $sender = $sender->new({
        ESMTP => {
            NOTIFY => 'SUCCESS,FAILURE,DELAY',
            RET => 'HDRS',
            ORCPT => 'rfc822;my.other@address.com',
            ENVID => 'iuhsdfobwoe8t237',
        },
    });
    my $esmtp = $sender->{ESMTP}; # reach in to grab

This option contains data for SMTP extensions. For example, it allows you to
request delivery status notifications according to L<RFC1891|https://tools.ietf.org/html/rfc1891>.
If the SMTP server you connect to doesn't support this extension, the options
will be ignored.  You do not need to worry about encoding the C<ORCPT> or C<ENVID>
parameters.

=over

=item *

C<ENVID> - Used to propagate an identifier for this message transmission
envelope, which is also known to the sender and will, if present, be returned
in any Delivery Status Notifications issued for this transmission.

=item *

C<NOTIFY> - To specify the conditions under which a delivery status
notification should be generated. Should be either C<NEVER> or a comma-separated
list of C<SUCCESS>, C<FAILURE> and C<DELAY>.

=item *

C<ORCPT> - Used to convey the original (sender-specified) recipient address.

=item *

C<RET> - To request that Delivery Status Notifications containing an indication
of delivery failure either return the entire contents of a message or only the
message headers. Must be either C<FULL> or C<HDRS>.

=back

=head2 fake_cc

    # mutating single attributes could get costly!
    $sender = $sender->new({fake_cc => 'foo@bar.com'});
    my $fake_cc = $sender->{fake_cc}; # reach in to grab

The address that will be shown in headers. If not specified, the L<Mail::Sender/"cc"> attribute will be used.

=head2 fake_from

    # mutating single attributes could get costly!
    $sender = $sender->new({fake_from => 'foo@bar.com'});
    my $fake_from = $sender->{fake_from}; # reach in to grab

The address that will be shown in headers. If not specified, the L<Mail::Sender/"from"> attribute will be used.

=head2 fake_to

    # mutating single attributes could get costly!
    $sender = $sender->new({fake_to => 'foo@bar.com'});
    my $fake_to = $sender->{fake_to}; # reach in to grab

The recipient's address that will be shown in headers. If not specified, the L<Mail::Sender/"to"> attribute will be used.

If the list of addresses you want to send your message to is long or if you do
not want the recipients to see each other's address set the L<Mail::Sender/"fake_to"> parameter to
some informative, yet bogus, address or to the address of your mailing/distribution list.

=head2 from

    # mutating single attributes could get costly!
    $sender = $sender->new({from => 'foo@bar.com'});
    my $from = $sender->{from}; # reach in to grab

The sender's email address.

=head2 headers

    # mutating single attributes could get costly!
    $sender = $sender->new({headers => 'Content-Type: text/plain'});
    $sender = $sender->new({headers => {'Content-Type' => 'text/plain'}});
    my $headers = $sender->{headers}; # reach in to grab

You may use this parameter to add custom headers into the message.
The parameter may be either a string containing the headers in the right format
or a hash containing the headers and their values.

=head2 keepconnection

    # mutating single attributes could get costly!
    $sender = $sender->new({keepconnection => 1);
    $sender = $sender->new({keepconnection => 0});
    my $keepcon = $sender->{keepconnection}; # reach in to grab

If set to a true value, it causes the L<Mail::Sender> to keep the connection
open for several messages. The connection will be closed if you call the
L<Mail::Sender/"Close"> method with a true value or if you call
L<Mail::Sender/"Open">, L<Mail::Sender/"OpenMultipart">, L<Mail::Sender/"MailMsg">
or L<Mail::Sender/"MailFile"> with the C<smtp> attribute. This means that if you
want the object to keep the connection, you should pass the C<smtp> either to
L<Mail::Sender/"new"> or only to the first L<Mail::Sender/"Open">,
L<Mail::Sender/"OpenMultipart">, L<Mail::Sender/"MailMsg">
or L<Mail::Sender/"MailFile">!

=head2 multipart

    # mutating single attributes could get costly!
    $sender = $sender->new({multipart => 'Mixed'});
    my $multi = $sender->{multipart}; # reach in to grab

The C<MIME> subtype for the whole message (C<Mixed/Related/Alternative>). You may
need to change this setting if you want to send an HTML body with some inline
images, or if you want to post the message in plain text as well as HTML
(alternative).

=head2 on_errors

    # mutating single attributes could get costly!
    $sender = $sender->new({on_errors => 'undef'}); # return undef on error
    $sender = $sender->new({on_errors => 'die'}); # raise an exception
    $sender = $sender->new({on_errors => 'code'}); # return the negative error code (default)
    # -1 = $smtphost unknown
    # -2 = socket() failed
    # -3 = connect() failed
    # -4 = service not available
    # -5 = unspecified communication error
    # -6 = local user $to unknown on host $smtp
    # -7 = transmission of message failed
    # -8 = argument $to empty
    # -9 = no message specified in call to MailMsg or MailFile
    # -10 = no file name specified in call to SendFile or MailFile
    # -11 = file not found
    # -12 = not available in singlepart mode
    # -13 = site specific error
    # -14 = connection not established. Did you mean MailFile instead of SendFile?
    # -15 = no SMTP server specified
    # -16 = no From: address specified
    # -17 = authentication protocol not accepted by the server
    # -18 = login not accepted
    # -19 = authentication protocol is not implemented
    # -20 = all recipients were rejected by the server
    # -21 = file specified as an attachment cannot be read
    # -22 = failed to open the specified debug file for writing
    # -23 = STARTTLS failed (for SSL or TLS encrypted connections)
    # -24 = IO::Socket::SSL->start_SSL failed
    # -25 = TLS required by the specified options, but the required modules are not available. Need IO::Socket::SSL and Net::SSLeay
    # -26 = TLS required by the specified options, but the server doesn't support it
    # -27 = unknown encoding specified for the mail body, part or attachment. Only base64, quoted-printable, 7bit and 8bit supported.
    my $on_errors = $sender->{on_errors}; # reach in to grab
    say $Mail::Sender::Error; # contains a textual description of last error.

This option allows you to affect the way L<Mail::Sender> reports errors.
All methods return the C<$sender> object if they succeed.

C<< $Mail::Sender::Error >> C<< $sender->{'error'} >> and C<< $sender->{'error_msg'} >>
are set in all cases.

=head2 port

    # mutating single attributes could get costly!
    $sender = $sender->new({port => 25});
    my $port = $sender->{port}; # reach in to grab

The TCP/IP port used form the connection. By default C<getservbyname('smtp', 'tcp')||25>.
You should only need to use this option if your mail server waits on a nonstandard port.

=head2 priority

    # mutating single attributes could get costly!
    $sender = $sender->new({priority => 1});
    # 1. highest
    # 2. high
    # 3. normal
    # 4. low
    # 5. lowest
    my $priority = $sender->{priority}; # reach in to grab

The message priority number.

=head2 replyto

    # mutating single attributes could get costly!
    $sender = $sender->new({replyto => 'foo@bar.com'});
    my $replyto = $sender->{replyto}; # reach in to grab

The reply to address.

=head2 skip_bad_recipients

    # mutating single attributes could get costly!
    $sender = $sender->new({skip_bad_recipients => 1);
    $sender = $sender->new({skip_bad_recipients => 0});
    my $skip = $sender->{skip_bad_recipients}; # reach in to grab

If this option is set to false, or not specified, then L<Mail::Sender> stops
trying to send a message as soon as the first recipient's address fails. If it
is set to a true value, L<Mail::Sender> skips the bad addresses and tries to
send the message at least to the good ones. If all addresses are rejected by the
server, it reports a C<All recipients were rejected> message.

If any addresses were skipped, the C<< $sender->{'skipped_recipients'} >> will
be a reference to a hash containing the failed address and the server's response.


=head2 smtp

    # mutating single attributes could get costly!
    $sender = $sender->new({smtp => 'smtp.bar.com'});
    my $smtp = $sender->{smtp}; # reach in to grab

The IP address or domain of your SMTP server.

=head2 ssl_...

The C<ssl_version>, C<ssl_verify_mode>, C<ssl_ca_path>, C<ssl_ca_file>,
C<ssl_verifycb_name>, C<ssl_verifycn_schema> and C<ssl_hostname> options (if
specified) are passed to L<IO::Socket::SSL/"start_SSL">. The default version is
C<TLSv1> and verify mode is C<IO::Socket::SSL::SSL_VERIFY_NONE>.

If you change the C<ssl_verify_mode> to C<SSL_VERIFY_PEER>, you may need to
specify the C<ssl_ca_file>. If you have L<Mozilla::CA> installed, then setting
it to C<< Mozilla::CA::SSL_ca_file() >> may help.

=head2 subject

    # mutating single attributes could get costly!
    $sender = $sender->new({subject => 'An email is coming!'});
    my $subject = $sender->{subject}; # reach in to grab

The subject of the message.

=head2 tls_allowed

    # mutating single attributes could get costly!
    $sender = $sender->new({tls_allowed => 1}); # true, default
    $sender = $sender->new({tls_allowed => 0}); # false
    my $tls = $sender->{tls_allowed}; # reach in to grab

If set to a true value, L<Mail::Sender> will attempt to use TLS (encrypted
connection) whenever the server supports it.  This requires that you have
L<IO::Socket::SSL> and L<Net::SSLeay>.

=head2 tls_required

    # mutating single attributes could get costly!
    $sender = $sender->new({tls_required => 1}); # true, require TLS encryption
    $sender = $sender->new({tls_required => 0}); # false, plain. default
    my $required = $sender->{tls_required};

If you set this option to a true value, the module will fail if it's unable to use TLS.

=head2 to

    # mutating single attributes could get costly!
    $sender = $sender->new({to => 'foo@bar.com'});
    $sender = $sender->new({to => 'foo@bar.com, bar@baz.com'});
    $sender = $sender->new({to => ['foo@bar.com', 'bar@baz.com']});
    my $to = $sender->{to}; # reach in to grab

The recipient's addresses. This parameter may be either a comma separated list
of email addresses or a reference to a list of addresses.

=head1 METHODS

L<Mail::Sender> implements the following methods.

=head2 Attach

    # set parameters in an ordered list
    # -- description, ctype, encoding, disposition, file(s)
    $sender = $sender->Attach(
        'title', 'application/octet-stream', 'Base64', 'attachment; filename=*', '/file.txt'
    );
    $sender = $sender->Attach(
        'title', 'application/octet-stream', 'Base64', 'attachment; filename=*',
        ['/file.txt', '/file2.txt']
    );
    # OR use a hashref
    $sender = $sender->Attach({
        description => 'some title',
        charset => 'US-ASCII', # default
        encoding => 'Base64', # default
        ctype => 'application/octet-stream', # default
        disposition => 'attachment; filename=*', # default
        file => ['/file1.txt'], # file names
        content_id => '#', # for auto-increment number, or * for filename
    });

Sends a file as a separate part of the mail message. Only in multi-part mode.

=head2 Body

    # set parameters in an ordered list
    # -- charset, encoding, content-type
    $sender = $sender->Body('US-ASCII', '7BIT', 'text/plain');
    # OR use a hashref
    $sender = $sender->Body({
        charset => 'US-ASCII', # default
        encoding => '7BIT', # default
        ctype => 'text/plain', # default
        msg => '',
    });

Sends the head of the multi-part message body. You can specify the charset and the encoding.

=head2 Cancel

    $sender = $sender->Cancel;

Cancel an opened message.

L<Mail::Sender/"SendFile"> and other methods may set C<< $sender->{'error'} >>.
In that case "undef $sender" calls C<< $sender->Cancel >> not C<< $sender->Close >>!!!

=head2 ClearErrors

    $sender->ClearErrors();

Make the various error variables C<undef>.

=head2 Close

    $sender->Close();
    $sender->Close(1); # force override keepconnection

Close and send the email message. If you pass a true value to the method the
connection will be closed even if the C<keepconnection> was specified. You
should only keep the connection open if you plan to send another message
immediately. And you should not keep it open for hundreds of emails even if you
do send them all in a row.

This method should be called automatically when destructing the object, but you
should not rely on it. If you want to be sure your message WAS processed by the
server, you SHOULD call L<Mail::Sender/"Close"> explicitly.

=head2 Connect

This method gets called automatically. Do not call it yourself.

=head2 Connected

    my $bool = $sender->Connected();

Returns an C<undef> or true value to let you know if you're connected to the
mail server.

=head2 EndPart

    $sender = $sender->EndPart($ctype);

Closes a multi-part part.

If the C<$ctype> is not present or evaluates to false, only the current
SIMPLE part is closed! Don't do that unless you are really sure you know what
you are doing.

It's best to always pass to the C<< ->EndPart() >> the content type of the
corresponding C<< ->Part() >>.

=head2 GetHandle

    $sender->Open({...});
    my $handle = $sender->GetHandle();
    $handle->print("Hello world.\n");
    my ($mday,$mon,$year) = (localtime())[3,4,5];
    $handle->print(sprintf("Today is %04d/%02d/%02d.", $year+1900, $mon+1, $mday));
    close $handle;

Returns a file handle to which you can print the message or file to attach. The
data you print to this handle will be encoded as necessary. Closing this handle
closes either the message (for single part messages) or the part.

=head2 MailFile

    # set parameters in an ordered list
    # -- from, reply-to, to, smtp, subject, headers, message, files(s)
    $sender = $sender->MailFile('from@foo.com','reply-to@bar.com','to@baz.com')
    # OR use a hashref -- see the attributes section for a
    # list of appropriate parameters.
    $sender = $sender->MailFile({file => ['/file1','/file2'], msg => "Message"});

Sends one or more files by mail. If a message in C<$sender> is opened, it gets closed and a
new message is created and sent. C<$sender> is then closed.

The C<file> parameter may be a string file name, a comma-separated list of
filenames, or an array reference of filenames.

Keep in mind that parameters like C<ctype>, C<charset> and C<encoding> will be
used for the attached file, not the body of the message. If you want to specify
those parameters for the body, you have to use C<b_ctype>, C<b_charset> and
C<b_encoding>.

=head2 MailMsg

    # set parameters in an ordered list
    # -- from, reply-to, to, smtp, subject, headers, message
    $sender = $sender->MailMsg('from@foo.com','reply-to@bar.com','to@baz.com')
    # OR use a hashref -- see the attributes section for a
    # list of appropriate parameters.
    $sender = $sender->MailMsg({from => "foo@bar.com", msg => "Message"});

Sends a message. If a message in C<$sender> is opened, it gets closed and a
new message is created and sent. C<$sender> is then closed.

=head2 new

    # Create a new sender instance with only the 'from' address
    my $sender = Mail::Sender->new('from_address@bar.com');
    # Create a new sender with any attribute above set in a hashref
    my $sender = Mail::Sender->new({attribute => 'value', });
    # Create a new sender as a copy of an existing one
    my $copy = $sender->new({another_attr => 'bar',});

Prepares a sender. Any attribute can be set during instance creation.  This doesn't
start any connection to the server. You have to use C<< $sender->Open >> or
C<< $sender->OpenMultipart >> to start talking to the server.

The attributes are used in subsequent calls to C<< $sender->Open >> and
C<< $sender->OpenMultipart >>. Each such call changes the saved variables. You
can set C<smtp>, C<from> and other options here and then use the info in all messages.

=head2 Open

    # set parameters in an ordered list
    # -- from, reply-to, to, smtp, subject, headers
    $sender = $sender->Open('from@foo.com','reply-to@bar.com','to@baz.com');
    # OR use a hashref -- see the attributes section for a
    # list of appropriate parameters.
    $sender = $sender->Open({to=>'to@baz.com', subject=>'Incoming!!!'});

Opens a new message. The only additional parameter that may not be specified
directly in L<Mail::Sender/"new"> is C<messageid>. If you set this option, the
message will be sent with that C<Message-ID>, otherwise a new Message ID will
be generated out of the sender's address, current date+time and a random number
(or by the function you specified in the C<createmessageid> attribute).

After the message is sent C<< $sender->{messageid} >> will contain the Message-ID
with which the message was sent.

=head2 OpenMultipart

    # set parameters in an ordered list
    # -- from, reply-to, to, smtp, subject, headers, boundary
    $sender = $sender->OpenMultipart('from@foo.com','reply-to@bar.com');
    # OR use a hashref -- see the attributes section for a
    # list of appropriate parameters.
    $sender = $sender->OpenMultipart({to=>'to@baz.com', subject=>'Incoming!!!'});

Opens a multipart message.

=head2 Part

    # set parameters in an ordered list
    # -- description, ctype, encoding, disposition, content_id, Message
    $sender = $sender->Part(
        'something', 'text/plain', '7BIT', 'attachment; filename="send.pl"'
    );
    # OR use a hashref -- see the attributes section for a
    # list of appropriate parameters.
    $sender = $sender->Part({
        description => "desc",
        ctype => "application/octet-stream", # default
        encoding => '7BIT', # default
        disposition => 'attachment', # default
        content_id => '#', # for auto-increment number, or * for filename
        msg => '', # You don't have to specify here, you may use SendEnc()
                    # to add content to the part.
    });

Prints a part header for the multipart message and (if specified) the contents.

=head2 print

An alias for L<Mail::Sender/"SendEnc">.

=head2 QueryAuthProtocols

    my @protocols = $sender->QueryAuthProtocols();
    my @protocols = $sender->QueryAuthProtocols( $smtpserver);

Queries the server specified in the attributes or in the parameter to this
method for the authentication protocols it supports.

=head2 Send

    $sender = $sender->Send(@strings);

Prints the strings to the socket. It doesn't add any line terminations or encoding.
You should use C<\r\n> as the end-of-line!

UNLESS YOU ARE ABSOLUTELY SURE YOU KNOW WHAT YOU ARE DOING YOU SHOULD USE
L<Mail::Sender/"SendEnc"> INSTEAD!

=head2 SendEnc

    $sender = $sender->SendEnc(@strings);

Prints the bytes to the socket. It doesn't add any line terminations. Encodes
the text using the selected encoding: C<none | Base64 | Quoted-printable>.
You should use C<\r\n> as the end-of-line!

=head2 SendEx

    $sender = $sender->SendEx(@strings);

Prints the strings to the socket. Doesn't add any end-of-line characters.
Changes all end-of-lines to C<\r\n>. Doesn't encode the data!

UNLESS YOU ARE ABSOLUTELY SURE YOU KNOW WHAT YOU ARE DOING YOU SHOULD USE
L<Mail::Sender/"SendEnc"> INSTEAD!

=head2 SendFile

Alias for L<Mail::Sender/"Attach">

=head2 SendLine

    $sender = $sender->SendLine(@strings);

Prints the strings to the socket. Each byte string is terminated by C<\r\n>. No
encoding is done. You should use C<\r\n> as the end-of-line!

UNLESS YOU ARE ABSOLUTELY SURE YOU KNOW WHAT YOU ARE DOING YOU SHOULD USE
L<Mail::Sender/"SendLineEnc"> INSTEAD!

=head2 SendLineEnc

    $sender = $sender->SendLineEnc(@strings);

Prints the strings to the socket and adds the end-of-line character at the end.
Encodes the text using the selected encoding: C<none | Base64 | Quoted-printable>.

Do NOT mix up L<Mail::Sender/"Send">, L<Mail::Sender/"SendEx">, L<Mail::Sender/"SendLine">,
or L<Mail::Sender/"SendLineEx"> with L<Mail::Sender/"SendEnc"> or L<Mail::Sender/"SendLineEnc">!
L<Mail::Sender/"SendEnc"> does some buffering necessary for correct Base64
encoding, and L<Mail::Sender/"Send"> and L<Mail::Sender/"SendEx"> are not aware of that.

Usage of L<Mail::Sender/"Send">, L<Mail::Sender/"SendEx">, L<Mail::Sender/"SendLine">,
and L<Mail::Sender/"SendLineEx"> in non C<xBIT> parts is not recommended. Using
C<< Send(encode_base64($string)) >> may work, but more likely it will not! In
particular, if you use several such to create one part, the data is very likely
to get crippled.

=head2 SendLineEx

    $sender = $sender->SendLineEnc(@strings);

Prints the strings to the socket. Adds an end-of-line character at the end.
Changes all end-of-lines to C<\r\n>. Doesn't encode the data!

UNLESS YOU ARE ABSOLUTELY SURE YOU KNOW WHAT YOU ARE DOING YOU SHOULD USE
L<Mail::Sender/"SendLineEnc"> INSTEAD!

=head1 FUNCTIONS

L<Mail::Sender> implements the following functions.

=head2 GuessCType

    my $ctype = Mail::Sender::GuessCType($filename, $filepath);

Guesses the content type based on the filename or the file contents. This
function is used when you attach a file and do not specify the content type.
It is not exported by default!

=head2 MessageID

    my $id = Mail::Sender::MessageID('from@foo.com');

Generates a "unique" message ID for a given from address.

=head2 ResetGMTdiff

    Mail::Sender::ResetGMTdiff();

The module computes the local vs. GMT time difference to include in the
timestamps added into the message headers. As the time difference may change
due to summer savings time changes you may want to reset the time difference
occasionally in long running programs.

=head1 BUGS

I'm sure there are many. Please let me know if you find any.

The problem with multi-line responses from some SMTP servers (namely
L<qmail|http://www.qmail.org/top.html>) is solved at last.

=head1 SEE ALSO

L<Email::Sender>

There are lots of mail related modules on CPAN. Be wise, use L<Email::Sender>!

=head1 AUTHOR

Jan Krynický <F<Jenda@Krynicky.cz>> L<http://Jenda.Krynicky.cz>

=head1 CONTRIBUTORS

=over

=item *

Brian Blakley <F<bblakley@mp5.net>>,

=item *

Chase Whitener <F<capoeirab@cpan.org>>,

=item *

Ed McGuigan <F<itstech1@gate.net>>,

=item *

John Sanche <F<john@quadrant.net>>

=item *

Rodrigo Siqueira <F<rodrigo@insite.com.br>>,

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 1997-2014 Jan Krynický <F<Jenda@Krynicky.cz>>. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
