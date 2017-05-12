package Mail::OpenDKIM::DKIM;

use 5.010000;
use strict;
use warnings;

use Error;

use Mail::OpenDKIM;

=head1 NAME

Mail::OpenDKIM::DKIM - Provides an interface to libOpenDKIM

=head1 DESCRIPTION

Mail::OpenDKIM::DKIM, coupled with Mail::OpenDKIM, provides a means of calling libOpenDKIM
from Perl.
Mail::OpenDKIM implements those routine taking a DKIM_LIB argument; those taking a DKIM
argument have been implemented in Mail::OpenDKIM::DKIM.

When an error is encountered, an Error::Simple object is thrown.

=head1 SUBROUTINES/METHODS

=head2 new

Create a new signing/verifying object.

You probably don't want to call this method directly.
Instead, call either Mail::DKIM->dkim_sign() or Mail::DKIM->dkim_verify() to instantiate an
object.

=cut

sub new {
  my ($class, $args) = @_;

  foreach(qw(dkimlib_handle)) {
    exists($$args{$_}) or throw Error::Simple("$class->new missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("$class->new undefined argument '$_'");
  }

  my $self = {
    _dkimlib_handle => $$args{dkimlib_handle},  # DKIM_LIB
    _dkim_handle => undef,  # DKIM
  };

  bless $self, $class;

  return $self;
}

=head2 dkim_sign

You probably don't want to call this method directly.
Instead, call Mail::DKIM->dkim_sign().

=cut

sub dkim_sign
{
  my ($self, $args) = @_;

  if($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sign called twice');
  }

  foreach(qw(id secretkey selector domain hdrcanon_alg bodycanon_alg sign_alg length)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sign missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sign undefined argument '$_'");
  }

  my $statp;

  $self->{_dkim_handle} = Mail::OpenDKIM::_dkim_sign($self->{_dkimlib_handle},
    $$args{id}, $$args{secretkey}, $$args{selector}, $$args{domain},
    $$args{hdrcanon_alg}, $$args{bodycanon_alg}, $$args{sign_alg},
    $$args{length}, $statp);

  return $statp;
}

=head2 dkim_verify

You probably don't want to call this method directly.
Instead, call Mail::DKIM->dkim_verify().

=cut

sub dkim_verify
{
  my ($self, $args) = @_;

  if($self->{_dkim_handle}) {
    throw Error::Simple('dkim_verify called twice');
  }

  foreach(qw(id)) {
    exists($$args{$_}) or throw Error::Simple("dkim_verify missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_verify undefined argument '$_'");
  }

  my $statp;

  $self->{_dkim_handle} = Mail::OpenDKIM::_dkim_verify($self->{_dkimlib_handle},
    $$args{id}, $statp);

  return $statp;
}

=head2 dkim_header

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_header
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_header called before dkim_sign/dkim_verify');
  }
  foreach(qw(header len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_header missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_header undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_header($self->{_dkim_handle}, $$args{header}, $$args{len});
}

=head2 dkim_body

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_body
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_body called before dkim_sign/dkim_verify');
  }
  foreach(qw(bodyp len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_body missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_body undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_body($self->{_dkim_handle}, $$args{bodyp}, $$args{len});
}

=head2 dkim_eoh

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_eoh
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_eoh called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_eoh($self->{_dkim_handle});
}

=head2 dkim_chunk

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_chunk
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_chunk called before dkim_sign/dkim_verify');
  }
  foreach(qw(chunkp len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_chunk missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_chunk undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_chunk($self->{_dkim_handle}, $$args{chunkp}, $$args{len});
}

=head2 dkim_eom

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_eom
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_eom called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_eom($self->{_dkim_handle});
}

=head2 dkim_getid

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getid
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getid called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getid($self->{_dkim_handle});
}

=head2 dkim_get_msgdate

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_get_msgdate
{
  my $self = shift;

  if (Mail::OpenDKIM::dkim_libversion() >= 0x02070000) {
    throw Error::Simple('dkim_get_msgdate not implemented in >= 2.7.0');
  }

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_get_msgdate called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_get_msgdate($self->{_dkim_handle});
}

=head2 dkim_get_sigsubstring

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_get_sigsubstring
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_get_sigsubstring called before dkim_sign/dkim_verify');
  }
  foreach(qw(sig buf buflen)) {
    exists($$args{$_}) or throw Error::Simple("dkim_get_sigsubstring missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_key_getsigsubstring undefined argument '$_'");
  }

  my $buflen = $$args{buflen};

  my $rc =  Mail::OpenDKIM::_dkim_get_sigsubstring($self->{_dkim_handle}, $$args{sig}, $$args{buf}, $buflen);

  if($rc == DKIM_STAT_OK) {
    $$args{buflen} = $buflen;
  }
  return $rc;
}

=head2 dkim_key_syntax

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_key_syntax
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_key_syntax called before dkim_sign/dkim_verify');
  }

  foreach(qw(str len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_key_syntax missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_key_syntax undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_key_syntax($self->{_dkim_handle}, $$args{str}, $$args{len});
}

=head2 dkim_getsighdr

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getsighdr
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getsighdr called before dkim_sign');
  }
  foreach(qw(initial buf len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_getsighdr missing argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_getsighdr($self->{_dkim_handle}, $$args{buf}, $$args{len}, $$args{initial});
}

=head2 dkim_getsighdr_d

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getsighdr_d
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getsighdr_d called before dkim_sign');
  }
  foreach(qw(initial buf len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_getsighdr_d missing argument '$_'");
  }

  my $len;

  my $rc = Mail::OpenDKIM::_dkim_getsighdr_d($self->{_dkim_handle}, $$args{initial}, $$args{buf}, $len);

  if($rc == DKIM_STAT_OK) {
    $$args{len} = $len;
  }

  return $rc;
}

=head2 dkim_getsignature

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getsignature
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getsignature called before dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getsignature($self->{_dkim_handle});
}

=head2 dkim_getsiglist

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getsiglist
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getsiglist called before dkim_sign/dkim_verify');
  }
  foreach(qw(sigs nsigs)) {
    exists($$args{$_}) or throw Error::Simple("dkim_getsiglist missing argument '$_'");
  }

  my($rc, $nsigs, @sigs) = Mail::OpenDKIM::_dkim_getsiglist($self->{_dkim_handle});

  if($rc == DKIM_STAT_OK) {
    $$args{nsigs} = $nsigs;
    $$args{sigs} = \@sigs;
  }
  else {
    $$args{nsigs} = undef;
  }

  return $rc;
}

=head2 dkim_ohdrs

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_ohdrs
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_ohdrs called before dkim_verify');
  }
  foreach(qw(sig ptrs cnt)) {
    exists($$args{$_}) or throw Error::Simple("dkim_ohdrs missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_ohdrs missing argument '$_'");
  }

  my $cnt = $$args{cnt};

  my $rc = Mail::OpenDKIM::_dkim_ohdrs($self->{_dkim_handle}, $$args{sig}, $$args{ptrs}, $cnt);
  if($rc == DKIM_STAT_OK) {
    $$args{cnt} = $cnt;
  }
  else {
    $$args{cnt} = undef;
  }

  return $rc;
}

=head2 dkim_get_signer

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_get_signer
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_get_signer called before dkim_sign');
  }

  return Mail::OpenDKIM::_dkim_get_signer($self->{_dkim_handle});
}

=head2 dkim_set_signer

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_signer
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_set_signer called before dkim_sign');
  }
  foreach(qw(signer)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_signer missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_signer undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_set_signer($self->{_dkim_handle}, $$args{signer});
}

=head2 dkim_set_margin

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_margin
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_set_margin called before dkim_sign');
  }
  foreach(qw(margin)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_margin missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_margin undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_set_margin($self->{_dkim_handle}, $$args{margin});
}

=head2 dkim_get_user_context

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_get_user_context
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_get_user_context called before dkim_sign');
  }

  return Mail::OpenDKIM::_dkim_get_user_context($self->{_dkim_handle});
}

=head2 dkim_set_user_context

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_user_context
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_set_user_context called before dkim_sign');
  }
  foreach(qw(context)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_final missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_final undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_set_user_context($self->{_dkim_handle}, $$args{context});
}

=head2 dkim_atps_check

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_atps_check
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_atps_check called before dkim_verify');
  }
  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_final missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_final undefined argument '$_'");
  }
  foreach(qw(res timeout)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_final missing argument '$_'");
  }

  my $res;

  my $rc = Mail::OpenDKIM::_dkim_atps_check($self->{_dkim_handle}, $$args{sig}, $$args{timeout} ? $$args{timeout} : 0, $res);

  if($rc == DKIM_STAT_OK) {
    $$args{res} = $res;
  }
  else {
    $$args{res} = undef;
  }

  return $rc;
}

=head2 dkim_diffheaders

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_diffheaders
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_diffheaders called before dkim_verify');
  }
  foreach(qw(canon maxcost ohdrs nohdrs)) {
    exists($$args{$_}) or throw Error::Simple("dkim_diffheaders missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_diffheaders undefined argument '$_'");
  }

  my $nout;
  my $out;

  my $rc = Mail::OpenDKIM::_dkim_diffheaders($self->{_dkim_handle}, $$args{canon}, $$args{maxcost}, $$args{ohdrs}, $$args{hdrs}, $out, $nout);

  if($rc == DKIM_STAT_OK) {
    $$args{out} = $out;
    $$args{nout} = $nout;
  }
  else {
    $$args{out} = undef;
    $$args{nout} = undef;
  }

  return $rc;
}

=head2 dkim_set_final

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_final
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_final called before dkim_sign');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_final missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_final undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_set_final($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_set_prescreen

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_set_prescreen
{
  my ($self, $args) = @_;

  unless($self->{_dkimlib_handle}) {
    throw Error::Simple('dkim_set_prescreen called before dkim_sign');
  }
  foreach(qw(func)) {
    exists($$args{$_}) or throw Error::Simple("dkim_set_prescreen missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_set_prescreen undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_set_prescreen($self->{_dkimlib_handle}, $$args{func});
}

=head2 dkim_getpartial

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getpartial
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getpartial called before dkim_sign');
  }

  return Mail::OpenDKIM::_dkim_getpartial($self->{_dkim_handle});
}

=head2 dkim_setpartial

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_setpartial
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_setpartial called before dkim_sign');
  }
  foreach(qw(value)) {
    exists($$args{$_}) or throw Error::Simple("dkim_setpartial missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_setpartial undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_setpartial($self->{_dkim_handle}, $$args{value});
}

=head2 dkim_getdomain

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getdomain
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getdomain called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getdomain($self->{_dkim_handle});
}

=head2 dkim_getuser

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getuser
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getuser called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getuser($self->{_dkim_handle});
}

=head2 dkim_minbody

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_minbody
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_minbody called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_minbody($self->{_dkim_handle});
}

=head2 dkim_getmode

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getmode
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getmode called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getmode($self->{_dkim_handle});
}

=head2 dkim_sig_syntax

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_syntax
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_syntax called before dkim_verify');
  }
  foreach(qw(str len)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_syntax missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_syntax undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_syntax($self->{_dkim_handle}, $$args{str}, $$args{len});
}

=head2 dkim_getpresult

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_getpresult
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_getpresult called before dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_getpresult($self->{_dkim_handle});
}

=head2 dkim_sig_getbh

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getbh
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getbh called before dkim_verify');
  }
  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getbh missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getbh undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getbh($$args{sig});
}

=head2 dkim_sig_getcanonlen

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getcanonlen
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getcanonlen called before dkim_verify');
  }
  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getcanonlen missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getcanonlen undefined argument '$_'");
  }

  my $msglen = $$args{msglen};
  my $canonlen = $$args{canonlen};
  my $signlen = $$args{signlen};

  my $rc = Mail::OpenDKIM::_dkim_sig_getcanonlen($self->{_dkim_handle}, $$args{sig}, $msglen, $canonlen, $signlen);

  if($rc == DKIM_STAT_OK) {
    if(exists($$args{msglen})) {
      $$args{msglen} = $msglen;
    }
    if(exists($$args{canonlen})) {
      $$args{canonlen} = $canonlen;
    }
    if(exists($$args{signlen})) {
      $$args{signlen} = $signlen;
    }
  }

  return $rc;
}

=head2 dkim_sig_getcanons

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getcanons
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getcanons called before dkim_verify');
  }

  my $hdr = $$args{hdr};
  my $body = $$args{body};

  my $rc = Mail::OpenDKIM::_dkim_sig_getcanons($$args{sig}, $hdr, $body);

  if($rc == DKIM_STAT_OK) {
    if(exists($$args{hdr})) {
      $$args{hdr} = $hdr;
    }
    if(exists($$args{body})) {
      $$args{body} = $body;
    }
  }

  return $rc;
}

=head2 dkim_sig_getcontext

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getcontext
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getcontext missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getcontext undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getcontext($$args{sig});
}

=head2 dkim_sig_getreportinfo

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getreportinfo
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getreportinfo called before dkim_verify');
  }

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getreportinfo missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_reportinfo undefined argument '$_'");
  }
  my $interval = -1;

  my $rc = Mail::OpenDKIM::_dkim_sig_getreportinfo($self->{_dkim_handle}, $$args{sig},
    $$args{hfd} ? $$args{hfd} : 0,
    $$args{bfd} ? $$args{bfd} : 0,
    $$args{addrbuf} ? $$args{addrbuf} : 0, $$args{addrlen},
    $$args{optsbuf} ? $$args{optsbuf} : 0, $$args{optslen},
    $$args{smtpbuf} ? $$args{smtpbuf} : 0, $$args{smtplen},
    $interval);

  if($rc == DKIM_STAT_OK) {
    $$args{interval} = $interval;
  }

  return $rc;
}

=head2 dkim_sig_getselector

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getselector
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getselector missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_selector undefined argument '$_'");
  }
  
  return Mail::OpenDKIM::_dkim_sig_getselector($$args{sig});
}

=head2 dkim_sig_getsignalg

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getsignalg
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getsignalg missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getsignalg undefined argument '$_'");
  }
  
  my $alg = -1;

  my $rc =  Mail::OpenDKIM::_dkim_sig_getsignalg($$args{sig}, $alg);

  if($rc == DKIM_STAT_OK) {
    $$args{alg} = $alg;
  }

  return $rc;
}

=head2 dkim_sig_getsignedhdrs

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getsignedhdrs
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getsignedhdrs called before dkim_verify');
  }

  foreach(qw(sig hdrs hdrlen nhdrs)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getsignedhdrs missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getsignedhdrs undefined argument '$_'");
  }
  
  my $nhdrs = $$args{nhdrs};

  my $rc =  Mail::OpenDKIM::_dkim_sig_getsignedhdrs($self->{_dkim_handle}, $$args{sig}, $$args{hdrs}, $$args{hdrlen}, $nhdrs);

  if($rc == DKIM_STAT_OK) {
    $$args{nhdrs} = $nhdrs;
  }
  else {
    $$args{nhdrs} = undef;
  }

  return $rc;
}

=head2 dkim_sig_getsigntime

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getsigntime
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getsigntime missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getsigntime undefined argument '$_'");
  }

  my $when = -1;

  my $rc = Mail::OpenDKIM::_dkim_sig_getsigntime($$args{sig}, $when);

  if($rc == DKIM_STAT_OK) {
    $$args{when} = $when;
  }

  return $rc;
}

=head2 dkim_sig_process

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_process
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_process called before dkim_verify');
  }

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_process missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_process undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_process($self->{_dkim_handle}, $$args{sig});
}

=head2 dkim_sig_gettagvalue

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_gettagvalue
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_gettagvalue called before dkim_verify');
  }

  foreach(qw(sig keytag tag)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_gettagvalue missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_gettagvalue undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_gettagvalue($$args{sig}, $$args{keytag}, $$args{tag});
}

=head2 dkim_sig_hdrsigned

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_hdrsigned
{
  my ($self, $args) = @_;

  foreach(qw(sig hdr)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_hdrsigned missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_hdrsigned undefined argument '$_'");
  }

  my $rc = Mail::OpenDKIM::_dkim_sig_hdrsigned($$args{sig}, $$args{hdr});
}

=head2 dkim_sig_getdnssec

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getdnssec
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getdnssec missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getdnssec undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getdnssec($$args{sig});
}

=head2 dkim_sig_getdomain

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getdomain
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getdomain missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getdomain undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getdomain($$args{sig});
}

=head2 dkim_sig_ignore

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_ignore
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_ignore missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_ignore undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_ignore($$args{sig});
}

=head2 dkim_sig_getidentity

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getidentity
{
  my ($self, $args) = @_;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_sig_getidentity called before dkim_verify');
  }

  foreach(qw(sig val vallen)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getidentity missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getidentity undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getidentity($self->{_dkim_handle}, $$args{sig}, $$args{val}, $$args{vallen});
}

=head2 dkim_sig_getflags

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getflags
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getflags missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getflags undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_getflags($$args{sig});
}

=head2 dkim_sig_getkeysize

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_getkeysize
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_getkeysize missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_getkeysize undefined argument '$_'");
  }

  my $bits;

  my $rc =  Mail::OpenDKIM::_dkim_sig_getkeysize($$args{sig}, $bits);

  if($rc == DKIM_STAT_OK) {
    $$args{bits} = $bits;
  }

  return $rc;
}

=head2 dkim_sig_geterror

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_sig_geterror
{
  my ($self, $args) = @_;

  foreach(qw(sig)) {
    exists($$args{$_}) or throw Error::Simple("dkim_sig_geterror missing argument '$_'");
    defined($$args{$_}) or throw Error::Simple("dkim_sig_geterror undefined argument '$_'");
  }

  return Mail::OpenDKIM::_dkim_sig_geterror($$args{sig});
}

=head2 dkim_geterror

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_geterror
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_geterror called before dkim_sign/dkim_verify');
  }

  return Mail::OpenDKIM::_dkim_geterror($self->{_dkim_handle});
}

=head2 dkim_free

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_free
{
  my $self = shift;

  unless($self->{_dkim_handle}) {
    throw Error::Simple('dkim_free called before dkim_sign');
  }

  my $rc = Mail::OpenDKIM::_dkim_free($self->{_dkim_handle});

  if($rc == DKIM_STAT_OK) {
    $self->{_dkim_handle} = undef;
  }

  return $rc;
}

sub DESTROY
{
  my $self = shift;

  if($self->{_dkim_handle}) {
    $self->dkim_free();
  }
}

=head2 EXPORT

This module exports nothing.

=head1 SEE ALSO

Mail::DKIM

http://www.opendkim.org/libopendkim/

RFC 4870, RFC 4871

=head1 NOTES

The sig routines would be better if they were in a separate class.

The signature creation rountines have been tested more thoroughly than the signature
verification routines.

Feedback will be greatfully received.

=head1 AUTHOR

Nigel Horne, C<< <nigel at mailermailer.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::OpenDKIM

You can also look for information at:

=over 4

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

This module is Copyright 2013 Khera Communications, Inc.
It is licensed under the same terms as Perl itself.

=cut

1;
