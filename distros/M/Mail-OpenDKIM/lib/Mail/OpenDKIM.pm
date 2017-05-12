package Mail::OpenDKIM;

use 5.010000;
use strict;
use warnings;

use Error;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration  use Mail::OpenDKIM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

## Sourced from dkim.h

use constant DKIM_STAT_OK => 0;             # function completed successfully
use constant DKIM_STAT_BADSIG => 1;         # signature available but failed
use constant DKIM_STAT_NOSIG => 2;          # no signature available
use constant DKIM_STAT_NOKEY => 3;          # public key not found
use constant DKIM_STAT_CANTVRFY => 4;       # can't get domain key to verify
use constant DKIM_STAT_SYNTAX => 5;         # message is not valid syntax
use constant DKIM_STAT_NORESOURCE => 6;     # resource unavailable
use constant DKIM_STAT_INTERNAL => 7;       # internal error
use constant DKIM_STAT_REVOKED => 8;        # key found, but revoked
use constant DKIM_STAT_INVALID => 9;        # invalid function parameter
use constant DKIM_STAT_NOTIMPLEMENT => 10;  # function not implemented
use constant DKIM_STAT_KEYFAIL => 11;       # key retrieval failed
use constant DKIM_STAT_CBREJECT => 12;      # callback requested reject
use constant DKIM_STAT_CBINVALID => 13;     # callback gave invalid result
use constant DKIM_STAT_CBTRYAGAIN => 14;    # callback says try again later
use constant DKIM_STAT_CBERROR => 15;       # callback error
use constant DKIM_STAT_MULTIDNSREPLY => 16; # multiple DNS replies
use constant DKIM_STAT_SIGGEN => 17;        # signature generation failed

use constant DKIM_CBSTAT_CONTINUE => 0;     # continue
use constant DKIM_CBSTAT_REJECT => 1;       # reject
use constant DKIM_CBSTAT_TRYAGAIN => 2;     # try again later
use constant DKIM_CBSTAT_NOTFOUND => 3;     # requested record not found
use constant DKIM_CBSTAT_ERROR => 4;        # error requesting record
use constant DKIM_CBSTAT_DEFAULT => 5;      # bypass; use default handling

use constant DKIM_SIGERROR_UNKNOWN => -1;         # unknown error
use constant DKIM_SIGERROR_OK => 0;               # no error
use constant DKIM_SIGERROR_VERSION => 1;          # unsupported version
use constant DKIM_SIGERROR_DOMAIN => 2;           # invalid domain (d=/i=)
use constant DKIM_SIGERROR_EXPIRED => 3;          # signature expired
use constant DKIM_SIGERROR_FUTURE => 4;           # signature in the future
use constant DKIM_SIGERROR_TIMESTAMPS => 5;       # x= < t=
use constant DKIM_SIGERROR_UNUSED => 6;           # OBSOLETE
use constant DKIM_SIGERROR_INVALID_HC => 7;       # c= invalid (header)
use constant DKIM_SIGERROR_INVALID_BC => 8;       # c= invalid (body)
use constant DKIM_SIGERROR_MISSING_A => 9;        # a= missing
use constant DKIM_SIGERROR_INVALID_A => 10;       # a= invalid
use constant DKIM_SIGERROR_MISSING_H => 11;       # h= missing
use constant DKIM_SIGERROR_INVALID_L => 12;       # l= invalid
use constant DKIM_SIGERROR_INVALID_Q => 13;       # q= invalid
use constant DKIM_SIGERROR_INVALID_QO => 14;      # q= option invalid
use constant DKIM_SIGERROR_MISSING_D => 15;       # d= missing
use constant DKIM_SIGERROR_EMPTY_D => 16;         # d= empty
use constant DKIM_SIGERROR_MISSING_S => 17;       # s= missing
use constant DKIM_SIGERROR_EMPTY_S => 18;         # s= empty
use constant DKIM_SIGERROR_MISSING_B => 19;       # b= missing
use constant DKIM_SIGERROR_EMPTY_B => 20;         # b= empty
use constant DKIM_SIGERROR_CORRUPT_B => 21;       # b= corrupt
use constant DKIM_SIGERROR_NOKEY => 22;           # no key found in DNS
use constant DKIM_SIGERROR_DNSSYNTAX => 23;       # DNS reply corrupt
use constant DKIM_SIGERROR_KEYFAIL => 24;         # DNS query failed
use constant DKIM_SIGERROR_MISSING_BH => 25;      # bh= missing
use constant DKIM_SIGERROR_EMPTY_BH => 26;        # bh= empty
use constant DKIM_SIGERROR_CORRUPT_BH => 27;      # bh= corrupt
use constant DKIM_SIGERROR_BADSIG => 28;          # signature mismatch
use constant DKIM_SIGERROR_SUBDOMAIN => 29;       # unauthorized subdomain
use constant DKIM_SIGERROR_MULTIREPLY => 30;      # multiple records returned
use constant DKIM_SIGERROR_EMPTY_H => 31;         # h= empty
use constant DKIM_SIGERROR_INVALID_H => 32;       # h= missing req'd entries
use constant DKIM_SIGERROR_TOOLARGE_L => 33;      # l= value exceeds body size
use constant DKIM_SIGERROR_MBSFAILED => 34;       # "must be signed" failure
use constant DKIM_SIGERROR_KEYVERSION => 35;      # unknown key version
use constant DKIM_SIGERROR_KEYUNKNOWNHASH => 36;  # unknown key hash
use constant DKIM_SIGERROR_KEYHASHMISMATCH => 37; # sig-key hash mismatch
use constant DKIM_SIGERROR_NOTEMAILKEY => 38;     # not an e-mail key
use constant DKIM_SIGERROR_UNUSED2 => 39;         # OBSOLETE
use constant DKIM_SIGERROR_KEYTYPEMISSING => 40;  # key type missing
use constant DKIM_SIGERROR_KEYTYPEUNKNOWN => 41;  # key type unknown
use constant DKIM_SIGERROR_KEYREVOKED => 42;      # key revoked
use constant DKIM_SIGERROR_KEYDECODE => 43;       # key couldn't be decoded
use constant DKIM_SIGERROR_MISSING_V => 44;       # v= tag missing
use constant DKIM_SIGERROR_EMPTY_V => 45;         # v= tag empty
use constant DKIM_SIGERROR_KEYTOOSMALL => 46;     # too few key bits

use constant DKIM_DNS_ERROR => -1;        # error in transit
use constant DKIM_DNS_SUCCESS => 0;       # reply available
use constant DKIM_DNS_NOREPLY => 1;       # reply not available (yet)
use constant DKIM_DNS_EXPIRED => 2;       # no reply, query expired
use constant DKIM_DNS_INVALID => 3;       # invalid request

use constant DKIM_CANON_UNKNOWN => -1;    # unknown method
use constant DKIM_CANON_SIMPLE => 0;      # as specified in DKIM spec
use constant DKIM_CANON_RELAXED => 1;     # as specified in DKIM spec
use constant DKIM_CANON_DEFAULT => DKIM_CANON_SIMPLE;

use constant DKIM_SIGN_UNKNOWN => -2;     # unknown method
use constant DKIM_SIGN_DEFAULT => -1;     # use internal default
use constant DKIM_SIGN_RSASHA1 => 0;      # an RSA-signed SHA1 digest
use constant DKIM_SIGN_RSASHA256 => 1;    # an RSA-signed SHA256 digest

use constant DKIM_QUERY_UNKNOWN => -1;    # unknown method
use constant DKIM_QUERY_DNS => 0;         # DNS query method (per the draft)
use constant DKIM_QUERY_FILE => 1;        # text file method (for testing)
use constant DKIM_QUERY_DEFAULT => DKIM_QUERY_DNS;

use constant DKIM_PARAM_UNKNOWN => -1;    # unknown
use constant DKIM_PARAM_SIGNATURE => 0;   # b
use constant DKIM_PARAM_SIGNALG => 1;     # a
use constant DKIM_PARAM_DOMAIN => 2;      # d
use constant DKIM_PARAM_CANONALG => 3;    # c
use constant DKIM_PARAM_QUERYMETHOD => 4; # q
use constant DKIM_PARAM_SELECTOR => 5;    # s
use constant DKIM_PARAM_HDRLIST => 6;     # h
use constant DKIM_PARAM_VERSION => 7;     # v
use constant DKIM_PARAM_IDENTITY => 8;    # i
use constant DKIM_PARAM_TIMESTAMP => 9;   # t
use constant DKIM_PARAM_EXPIRATION => 10; # x
use constant DKIM_PARAM_COPIEDHDRS => 11; # z
use constant DKIM_PARAM_BODYHASH => 12;   # bh
use constant DKIM_PARAM_BODYLENGTH => 13; # l

use constant DKIM_MODE_UNKNOWN => -1;
use constant DKIM_MODE_SIGN => 0;
use constant DKIM_MODE_VERIFY => 1;

use constant DKIM_OP_GETOPT => 0;
use constant DKIM_OP_SETOPT => 1;

use constant DKIM_OPTS_FLAGS => 0;
use constant DKIM_OPTS_TMPDIR => 1;
use constant DKIM_OPTS_TIMEOUT => 2;
use constant DKIM_OPTS_SENDERHDRS => 3; # obsolete
use constant DKIM_OPTS_SIGNHDRS => 4;
use constant DKIM_OPTS_OVERSIGNHDRS => 5;
use constant DKIM_OPTS_QUERYMETHOD => 6;
use constant DKIM_OPTS_QUERYINFO => 7;
use constant DKIM_OPTS_FIXEDTIME => 8;
use constant DKIM_OPTS_SKIPHDRS => 9;
use constant DKIM_OPTS_ALWAYSHDRS => 10; # obsolete
use constant DKIM_OPTS_SIGNATURETTL => 11;
use constant DKIM_OPTS_CLOCKDRIFT => 12;
use constant DKIM_OPTS_MUSTBESIGNED => 13;
use constant DKIM_OPTS_MINKEYBITS => 14;
use constant DKIM_OPTS_REQUIREDHDRS => 15;

use constant DKIM_LIBFLAGS_NONE => 0x00000000;
use constant DKIM_LIBFLAGS_TMPFILES => 0x00000001;
use constant DKIM_LIBFLAGS_KEEPFILES => 0x00000002;
use constant DKIM_LIBFLAGS_SIGNLEN => 0x00000004;
use constant DKIM_LIBFLAGS_CACHE => 0x00000008;
use constant DKIM_LIBFLAGS_ZTAGS => 0x00000010;
use constant DKIM_LIBFLAGS_DELAYSIGPROC => 0x00000020;
use constant DKIM_LIBFLAGS_EOHCHECK => 0x00000040;
use constant DKIM_LIBFLAGS_ACCEPTV05 => 0x00000080;
use constant DKIM_LIBFLAGS_FIXCRLF => 0x00000100;
use constant DKIM_LIBFLAGS_ACCEPTDK => 0x00000200;
use constant DKIM_LIBFLAGS_BADSIGHANDLES => 0x00000400;
use constant DKIM_LIBFLAGS_VERIFYONE => 0x00000800;
use constant DKIM_LIBFLAGS_STRICTHDRS => 0x00001000;
use constant DKIM_LIBFLAGS_REPORTBADADSP => 0x00002000;
use constant DKIM_LIBFLAGS_DROPSIGNER => 0x00004000;
use constant DKIM_LIBFLAGS_STRICTRESIGN => 0x00008000;
use constant DKIM_LIBFLAGS_REQUESTREPORTS => 0x00010000;
use constant DKIM_LIBFLAGS_DEFAULT => DKIM_LIBFLAGS_NONE;

use constant DKIM_DNSSEC_UNKNOWN => -1;
use constant DKIM_DNSSEC_BOGUS => 0;
use constant DKIM_DNSSEC_INSECURE => 1;
use constant DKIM_DNSSEC_SECURE => 2;

use constant DKIM_ATPS_UNKNOWN => (-1);
use constant DKIM_ATPS_NOTFOUND => 0;
use constant DKIM_ATPS_FOUND => 1;

use constant DKIM_SIGFLAG_IGNORE => 0x01;
use constant DKIM_SIGFLAG_PROCESSED => 0x02;
use constant DKIM_SIGFLAG_PASSED => 0x04;
use constant DKIM_SIGFLAG_TESTKEY => 0x08;
use constant DKIM_SIGFLAG_NOSUBDOMAIN => 0x10;
use constant DKIM_SIGFLAG_KEYLOADED => 0x20;

use constant DKIM_SIGBH_UNTESTED => -1;
use constant DKIM_SIGBH_MATCH => 0;
use constant DKIM_SIGBH_MISMATCH => 1;

use constant DKIM_FEATURE_DIFFHEADERS => 0;
use constant DKIM_FEATURE_UNUSED => 1;
use constant DKIM_FEATURE_PARSE_TIME => 2;
use constant DKIM_FEATURE_QUERY_CACHE => 3;
use constant DKIM_FEATURE_SHA256 => 4;
use constant DKIM_FEATURE_OVERSIGN => 5;
use constant DKIM_FEATURE_DNSSEC => 6;
use constant DKIM_FEATURE_RESIGN => 7;
use constant DKIM_FEATURE_ATPS => 8;
use constant DKIM_FEATURE_XTAGS => 9;
use constant DKIM_FEATURE_MAX => 9;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

    DKIM_STAT_OK
    DKIM_STAT_BADSIG
    DKIM_STAT_NOSIG
    DKIM_STAT_NOKEY
    DKIM_STAT_CANTVRFY
    DKIM_STAT_SYNTAX
    DKIM_STAT_NORESOURCE
    DKIM_STAT_INTERNAL
    DKIM_STAT_REVOKED
    DKIM_STAT_INVALID
    DKIM_STAT_NOTIMPLEMENT
    DKIM_STAT_KEYFAIL
    DKIM_STAT_CBREJECT
    DKIM_STAT_CBINVALID
    DKIM_STAT_CBTRYAGAIN
    DKIM_STAT_CBERROR
    DKIM_STAT_MULTIDNSREPLY
    DKIM_STAT_SIGGEN

    DKIM_CBSTAT_CONTINUE
    DKIM_CBSTAT_REJECT
    DKIM_CBSTAT_TRYAGAIN
    DKIM_CBSTAT_NOTFOUND
    DKIM_CBSTAT_ERROR
    DKIM_CBSTAT_DEFAULT

    DKIM_SIGERROR_UNKNOWN
    DKIM_SIGERROR_OK
    DKIM_SIGERROR_VERSION
    DKIM_SIGERROR_DOMAIN
    DKIM_SIGERROR_EXPIRED
    DKIM_SIGERROR_FUTURE
    DKIM_SIGERROR_TIMESTAMPS
    DKIM_SIGERROR_UNUSED
    DKIM_SIGERROR_INVALID_HC
    DKIM_SIGERROR_INVALID_BC
    DKIM_SIGERROR_MISSING_A
    DKIM_SIGERROR_INVALID_A
    DKIM_SIGERROR_MISSING_H
    DKIM_SIGERROR_INVALID_L
    DKIM_SIGERROR_INVALID_Q
    DKIM_SIGERROR_INVALID_QO
    DKIM_SIGERROR_MISSING_D
    DKIM_SIGERROR_EMPTY_D
    DKIM_SIGERROR_MISSING_S
    DKIM_SIGERROR_EMPTY_S
    DKIM_SIGERROR_MISSING_B
    DKIM_SIGERROR_EMPTY_B
    DKIM_SIGERROR_CORRUPT_B
    DKIM_SIGERROR_NOKEY
    DKIM_SIGERROR_DNSSYNTAX
    DKIM_SIGERROR_KEYFAIL
    DKIM_SIGERROR_MISSING_BH
    DKIM_SIGERROR_EMPTY_BH
    DKIM_SIGERROR_CORRUPT_BH
    DKIM_SIGERROR_BADSIG
    DKIM_SIGERROR_SUBDOMAIN
    DKIM_SIGERROR_MULTIREPLY
    DKIM_SIGERROR_EMPTY_H
    DKIM_SIGERROR_INVALID_H
    DKIM_SIGERROR_TOOLARGE_L
    DKIM_SIGERROR_MBSFAILED
    DKIM_SIGERROR_KEYVERSION
    DKIM_SIGERROR_KEYUNKNOWNHASH
    DKIM_SIGERROR_KEYHASHMISMATCH
    DKIM_SIGERROR_NOTEMAILKEY
    DKIM_SIGERROR_UNUSED2
    DKIM_SIGERROR_KEYTYPEMISSING
    DKIM_SIGERROR_KEYTYPEUNKNOWN
    DKIM_SIGERROR_KEYREVOKED
    DKIM_SIGERROR_KEYDECODE
    DKIM_SIGERROR_MISSING_V
    DKIM_SIGERROR_EMPTY_V
    DKIM_SIGERROR_KEYTOOSMALL

    DKIM_DNS_ERROR
    DKIM_DNS_SUCCESS
    DKIM_DNS_NOREPLY
    DKIM_DNS_EXPIRED
    DKIM_DNS_INVALID

    DKIM_CANON_UNKNOWN
    DKIM_CANON_SIMPLE
    DKIM_CANON_RELAXED
    DKIM_CANON_DEFAULT

    DKIM_SIGN_UNKNOWN
    DKIM_SIGN_DEFAULT
    DKIM_SIGN_RSASHA1
    DKIM_SIGN_RSASHA256

    DKIM_QUERY_UNKNOWN
    DKIM_QUERY_DNS
    DKIM_QUERY_FILE
    DKIM_QUERY_DEFAULT

    DKIM_PARAM_UNKNOWN
    DKIM_PARAM_SIGNATURE
    DKIM_PARAM_SIGNALG
    DKIM_PARAM_DOMAIN
    DKIM_PARAM_CANONALG
    DKIM_PARAM_QUERYMETHOD
    DKIM_PARAM_SELECTOR
    DKIM_PARAM_HDRLIST
    DKIM_PARAM_VERSION
    DKIM_PARAM_IDENTITY
    DKIM_PARAM_TIMESTAMP
    DKIM_PARAM_EXPIRATION
    DKIM_PARAM_COPIEDHDRS
    DKIM_PARAM_BODYHASH
    DKIM_PARAM_BODYLENGTH

    DKIM_MODE_UNKNOWN
    DKIM_MODE_SIGN
    DKIM_MODE_VERIFY

    DKIM_OP_GETOPT
    DKIM_OP_SETOPT

    DKIM_OPTS_FLAGS
    DKIM_OPTS_TMPDIR
    DKIM_OPTS_TIMEOUT
    DKIM_OPTS_SENDERHDRS
    DKIM_OPTS_SIGNHDRS
    DKIM_OPTS_OVERSIGNHDRS
    DKIM_OPTS_QUERYMETHOD
    DKIM_OPTS_QUERYINFO
    DKIM_OPTS_FIXEDTIME
    DKIM_OPTS_SKIPHDRS
    DKIM_OPTS_ALWAYSHDRS
    DKIM_OPTS_SIGNATURETTL
    DKIM_OPTS_CLOCKDRIFT
    DKIM_OPTS_MUSTBESIGNED
    DKIM_OPTS_MINKEYBITS
    DKIM_OPTS_REQUIREDHDRS

    DKIM_LIBFLAGS_NONE
    DKIM_LIBFLAGS_TMPFILES
    DKIM_LIBFLAGS_KEEPFILES
    DKIM_LIBFLAGS_SIGNLEN
    DKIM_LIBFLAGS_CACHE
    DKIM_LIBFLAGS_ZTAGS
    DKIM_LIBFLAGS_DELAYSIGPROC
    DKIM_LIBFLAGS_EOHCHECK
    DKIM_LIBFLAGS_ACCEPTV05
    DKIM_LIBFLAGS_FIXCRLF
    DKIM_LIBFLAGS_ACCEPTDK
    DKIM_LIBFLAGS_BADSIGHANDLES
    DKIM_LIBFLAGS_VERIFYONE
    DKIM_LIBFLAGS_STRICTHDRS
    DKIM_LIBFLAGS_REPORTBADADSP
    DKIM_LIBFLAGS_DROPSIGNER
    DKIM_LIBFLAGS_STRICTRESIGN
    DKIM_LIBFLAGS_REQUESTREPORTS
    DKIM_LIBFLAGS_DEFAULT

    DKIM_DNSSEC_UNKNOWN
    DKIM_DNSSEC_BOGUS
    DKIM_DNSSEC_INSECURE
    DKIM_DNSSEC_SECURE

    DKIM_ATPS_UNKNOWN
    DKIM_ATPS_NOTFOUND
    DKIM_ATPS_FOUND

    DKIM_SIGFLAG_IGNORE
    DKIM_SIGFLAG_PROCESSED
    DKIM_SIGFLAG_PASSED
    DKIM_SIGFLAG_TESTKEY
    DKIM_SIGFLAG_NOSUBDOMAIN
    DKIM_SIGFLAG_KEYLOADED

    DKIM_SIGBH_UNTESTED
    DKIM_SIGBH_MATCH
    DKIM_SIGBH_MISMATCH

    DKIM_FEATURE_DIFFHEADERS
    DKIM_FEATURE_UNUSED
    DKIM_FEATURE_PARSE_TIME
    DKIM_FEATURE_QUERY_CACHE
    DKIM_FEATURE_SHA256
    DKIM_FEATURE_OVERSIGN
    DKIM_FEATURE_DNSSEC
    DKIM_FEATURE_RESIGN
    DKIM_FEATURE_ATPS
    DKIM_FEATURE_XTAGS
    DKIM_FEATURE_MAX

);

use vars qw($VERSION);
$VERSION = 4203;

require XSLoader;
XSLoader::load('Mail::OpenDKIM', $VERSION);

=pod

=head1 NAME

Mail::OpenDKIM - Provides an interface to libOpenDKIM

=head1 SYNOPSIS

 # sign outgoing message

 use Mail::DKIM::Signer;

 # create a signer object
 my $dkim = Mail::OpenDKIM::Signer->new(
  Algorithm => 'rsa-sha1',
  Method => 'relaxed',
  Domain => 'example.org',
  Selector => 'selector1',
  KeyFile => 'private.key',
 );

 # read an email and pass it into the signer, one line at a time
 while(<STDIN>) {
  # remove local line terminators
  chomp;
  s/\015$//;

  # use SMTP line terminators
  $dkim->PRINT("$_\015\012");
 }
 $dkim->CLOSE();

 # what is the signature result?
 my $signature = $dkim->signature;
 print $signature->as_string;

 # check validity of incoming message
 my $o = Mail::OpenDKIM->new();
 $o->dkim_init();

 my $d = $o->dkim_verify({
  id => 'MLM',
 });

 $msg =~ s/\n/\r\n/g;

 $d->dkim_chunk({ chunkp => $msg, len => length($msg) });

 $d->dkim_chunk({ chunkp => '', len => 0 });

 $d->dkim_eom();

 my $sig = $d->dkim_getsignature();

 $d->dkim_sig_process({ sig => $sig });

 printf "0x\n", $d->dkim_sig_getflags({ sig => $sig });

 $d->dkim_free();

 $o->dkim_close();

=head1 DESCRIPTION

Mail::OpenDKIM, coupled with Mail::OpenDKIM::DKIM, provides a means of
calling libOpenDKIM from Perl.  Mail::OpenDKIM implements those
routine taking a DKIM_LIB argument; those taking a DKIM argument have
been implemented in Mail::OpenDKIM::DKIM.

Mail::OpenDKIM::Signer provides a drop in replacement for the
signature process provided by Mail::DKIM::Signer.

When an error is encountered, an Error::Simple object is thrown.

=head1 SUBROUTINES/METHODS

=head2 new

Create a new signing/verifying object.
After doing this you will need to call the dkim_init method before you can do much else.

=cut

sub new {
  my $class = shift;

  my $self = {
    _dkimlib_handle => undef,  # DKIM_LIB
  };

  bless $self, $class;

  return $self;
}

=head2 dkim_init

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_init
{
  my $self = shift;

  if($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_init called more than once');
  }
  $self->{_dkimlib_handle} = _dkim_init();
  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_init failed to create a handle');
  }

  return $self;
}

=head2 dkim_close

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_close
{
  my $self = shift;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_close called before dkim_init');
  }
  _dkim_close($self->{_dkimlib_handle});
  $self->{_dkimlib_handle} = undef;
}

=head2 dkim_flush_cache

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_flush_cache
{
  my $self = shift;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_flush_cache called before dkim_init');
  }
  return _dkim_flush_cache($self->{_dkimlib_handle});
}

=head2 dkim_libfeature

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_libfeature
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_libfeature called before dkim_init');
  }
  foreach(qw(feature)) {
    exists($$args{$_}) or throw Error::Simple("dkim_libfeature missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_libfeature undefined argument '$_'");
  }

  return _dkim_libfeature($self->{_dkimlib_handle}, $$args{feature});
}

=head2 dkim_sign

For further information, refer to http://www.opendkim.org/libopendkim/

Returns a Mail::OpenDKIM::DKIM object.

=cut

sub dkim_sign
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_sign called before dkim_init');
  }
  foreach(qw(id secretkey selector domain hdrcanon_alg bodycanon_alg sign_alg length)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sign missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sign undefined argument '$_'");
  }
  require Mail::OpenDKIM::DKIM;

  my $dkim = Mail::OpenDKIM::DKIM->new({ dkimlib_handle => $self->{_dkimlib_handle} });

  my $statp = $dkim->dkim_sign($args);

  unless($statp == DKIM_STAT_OK) {
    throw Error::Simple("dkim_sign failed with status $statp");
  }

  return $dkim;
}

=head2 dkim_verify

For further information, refer to http://www.opendkim.org/libopendkim/

Returns a Mail::OpenDKIM::DKIM object.
The memclosure argument is ignored.

=cut

sub dkim_verify
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_verify called before dkim_init');
  }
  foreach(qw(id)) {
    exists($$args{$_}) or throw Error::Simple("dkim_verify missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_verify undefined argument '$_'");
  }
  require Mail::OpenDKIM::DKIM;

  my $dkim = Mail::OpenDKIM::DKIM->new({ dkimlib_handle => $self->{_dkimlib_handle} });

  my $statp = $dkim->dkim_verify($args);

  unless($statp == DKIM_STAT_OK) {
    throw Error::Simple("dkim_verify failed with status $statp");
  }

  return $dkim;
}

=head2 dkim_getcachestats

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getcachestats
{
  my ($self, $args) = @_;

  if (dkim_libversion() >= 0x02080000) {
    unless($self->{_dkimlib_handle}) {
      throw Error::Simple('dkim_set_dns_callback called before dkim_init');
    }
    return _dkim_getcachestats($self->{_dkimlib_handle}, $$args{queries}, $$args{hits}, $$args{expired}, $$args{keys});
  } else {
    return _dkim_getcachestats($$args{queries}, $$args{hits}, $$args{expired});
  }
}

=head2 dkim_set_dns_callback

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_dns_callback
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_dns_callback called before dkim_init');
  }
  foreach(qw(func interval)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_dns_callback missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_dns_callback undefined argument '$_'");
  }

  return _dkim_set_dns_callback($self->{_dkimlib_handle}, $$args{func}, $$args{interval});
}

=head2 dkim_set_key_lookup

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_key_lookup
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_key_lookup called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_key_lookup missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_key_lookup undefined argument '$_'");
  }

  return _dkim_set_key_lookup($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_set_signature_handle

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_signature_handle
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_signature_handle called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_signature_handle missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_signature_handle undefined argument '$_'");
  }

  return _dkim_set_signature_handle($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_set_signature_handle_free

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_signature_handle_free
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_signature_handle_free called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_signature_handle_free missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_signature_handle_free undefined argument '$_'");
  }

  return _dkim_set_signature_handle_free($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_set_signature_tagvalues

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_signature_tagvalues
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_signature_tagvalues called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_signature_tagvalues missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_signature_tagvalues undefined argument '$_'");
  }

  return _dkim_set_signature_tagvalues($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_dns_set_query_cancel

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_dns_set_query_cancel
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_dns_set_query_cancel called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_dns_set_query_cancel missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_dns_set_query_cancel undefined argument '$_'");
  }

  return _dkim_dns_set_query_cancel($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_dns_set_query_service

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_dns_set_query_service
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_dns_set_query_service called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_dns_set_query_service missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_dns_set_query_service undefined argument '$_'");
  }

  return _dkim_dns_set_query_service($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_dns_set_query_start

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_dns_set_query_start
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_dns_set_query_start called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_dns_set_query_start missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_dns_set_query_start undefined argument '$_'");
  }

  return _dkim_dns_set_query_start($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_dns_set_query_waitreply

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_dns_set_query_waitreply
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_dns_set_query_waitreply called before dkim_sign/dkim_verify');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_dns_set_query_waitreply missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_dns_set_query_waitreply undefined argument '$_'");
  }

  return _dkim_dns_set_query_waitreply($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_options

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_options
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_options called before dkim_sign/dkim_verify');
  }
  foreach(qw(op opt data len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_options missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_options undefined argument '$_'");
  }

  return _dkim_options($self->{_dkimlib_handle}, $$args{op}, $$args{opt}, $$args{data}, $$args{len});
}

sub DESTROY
{
  my $self = shift;

  if ($self->{_dkimlib_handle}) {
    $self->dkim_close();
  }
}

=head2 dkim_libversion

Static method.

=head2 dkim_ssl_version

Static method.

=head2 dkim_getcachestats

Static method.

=head2 dkim_getresultstr

Calls C routine of same name.

=head2 dkim_sig_geterrorstr

Calls C routine of same name.

=head2 dkim_mail_parse

Calls C routine of same name.

=head1 EXPORT

Many DKIM_* constants, e.g. DKIM_STAT_OK are exported.

=head1 SEE ALSO

Mail::DKIM

http://www.opendkim.org/libopendkim/

RFC 4870, RFC 4871

=head1 REPOSITORY

L<https://github.com/infracaninophile/Mail-OpenDKIM.git>

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  Test::More
  libOpenDKIM 2.10 (http://www.opendkim.org/libopendkim/)
  C compiler

=head1 NOTES

Tested against libOpenDKIM 2.10.3.

Only portions of Mail::DKIM::Signer interface, and the support for it,
have been implemented.

Please report any bugs or feature requests to C<bug-mail-opendkim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-OpenDKIM>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

The signature creation rountines have been tested more thoroughly than
the signature verification routines.

Feedback will be greatfully received.

=head1 AUTHOR

Nigel Horne

Vick Khera, C<< <vivek at khera.org> >>

Matthew Seaman, C<< <m.seaman@infracaninophile.co.uk> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::OpenDKIM

You can also look for information at:

=over 4

=item * MailerMailer Project page

L<http://www.mailermailer.com/labs/projects/Mail-OpenDKIM.rwp>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-OpenDKIM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-OpenDKIM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-OpenDKIM>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-OpenDKIM/>

=back


=head1 SPONSOR

This code has been developed under sponsorship of MailerMailer LLC,
http://www.mailermailer.com/

=head1 COPYRIGHT AND LICENCE

This module is Copyright 2014 Khera Communications, Inc.
Copyright 2015 Matthew Seaman
It is licensed under the same terms as Perl itself.

=cut

1;
