# Mail::SMI Perl Module
# 
# If you are need some help, read documentation first.
# $ perldoc Mail::SMI
# 
# $Id$
#
package Mail::SMI;

use Socket qw(:DEFAULT :crlf);
use POSIX qw(strftime);
use strict;
use vars qw($sock $VERSION $DEBUG);

eval("use MIME::QuotedPrint");

$DEBUG   = 0;
$VERSION = '0.01';

sub _gethostname
{
  my $this= @_;
  my ($port, $iaddr, $sockaddr, $hostname, $hostaddr);

  $sockaddr = getpeername($sock);
  ($port, $iaddr) = unpack_sockaddr_in($sockaddr);
  $hostname = gethostbyaddr($iaddr, AF_INET);
  return $hostname;
}

sub _getrcpt
{
  my $this = shift;
  return @{$this->{SMTP_RCPT}};
}

sub connect
{
  my($this,$host,$port,$hostname)=@_;
  my ($iaddr, $paddr, $proto);

  $this->{HOST} = $host;
  $this->{PORT} = $port || 25;

  $iaddr = inet_aton($this->{HOST});
  $paddr = sockaddr_in($port, $iaddr);
  $proto = getprotobyname('tcp');

  unless(socket SOCKFH, AF_INET, SOCK_STREAM, $proto)
  {
    $this->{ERR} = "connect method failed: $!\n";
    return 0;
  }
  unless(connect SOCKFH, $paddr)
  {
    $this->{ERR} = "connect method failed: $!\n";
    return 0;
  }

  $sock = \*SOCKFH;

  select($sock); $|=1; select(STDOUT);

  my $resp = <$sock>;
  if($resp !~ /^220/) 
  { 
    $this->{ERR} = "connect method failed: ($resp)"; 
    return 0; 
  }

  $hostname = (gethostbyname('localhost'))[0] unless $hostname;

  print $sock "HELO $hostname\015\012";
  $resp = <$sock>;
  print $resp if $DEBUG;
  if($resp !~ /^250/) 
  { 
    $this->{ERR} = "connect method failed: ($resp)\n"; 
    return 0; 
  }

  return 1;
}

sub disconnect
{
  my $resp;

  print $sock "QUIT\015\012";
  $resp = <$sock>;
  close($sock);

  return 1;
}

sub new 
{
  my $this = 
  {
    ERR => undef,
    HOST => undef,
    PORT => 0,
    SMTP_FROM => undef, 
    SMTP_RCPT => [],
    SMTP_DATA => undef,
  };

  bless $this;
  return $this;
}

sub reset
{
  my $this = shift;

  undef $this->{ERR};
  undef $this->{SMTP_FROM};
  undef $this->{SMTP_RCPT};
  undef $this->{SMTP_DATA};
}

sub rfc822_date
{
  return strftime "%a, %d %b %Y %H:%M:%S %z", localtime(time());
}

sub sendmail
{
  my ($this, $host, $port) = shift;
  my ($resp, $c);

  if($host && $port) {
    return 0 unless $this->connect($host, $port);
  }

  if(!$this->{SMTP_FROM})
  {
    $this->{ERR} = "sendmail method failed: missing SMTP_FROM\n";
    return 0;
  }

  print $sock "MAIL FROM: <$this->{SMTP_FROM}>\015\012";
  $resp = <$sock>;
  if($resp !~ /^250/) { $this->{ERR} = "sendmail method failed (MAIL FROM)"; return 0; }

  foreach my $rcpt ($this->_getrcpt())
  {
    print $sock "RCPT TO: <$rcpt>\015\012";
    $resp = <$sock>;
    unless($resp =~ /^250/) { $this->{ERR} = "sendmail method failed: ($resp)"; }
    $c++;
  }

  if(!$c)
  {
    $this->{ERR} = "sendmail method failed: missing SMTP_RCPT\n";
    return 0;
  }

  print $sock "DATA\015\012";
  $resp = <$sock>;
  print "smtp: $resp" if $DEBUG;
  unless($resp =~ /^354/) 
  { 
    chomp $resp;
    $this->{ERR} = "sendmail method failed: ($resp)"; 
    return 0; 
  }

  print $sock $this->{SMTP_DATA};
  $resp = <$sock>;
  print "smtp: $resp" if $DEBUG;
  unless($resp =~ /^250/) 
  {
    chomp $resp;
    $this->{ERR} = "sendmail method failed: ($resp)"; 
    return 0; 
  }

  if($host && $port)
  {
    $this->disconnect();
  }

  if($this->{ERR}) { return -1; }
  else { return 1; }
}

sub setdata
{
  my ($this, $MSG) = @_;
  my ($c, $body, $hdrs, $type);

  foreach my $key(keys %{$MSG})
  {
    if($key =~ /mime\-version/i) { $hdrs .="m|"; }
    elsif($key =~ /content\-type/i) { $hdrs .= "ct|"; $type = $MSG->{$key}; }
    elsif($key =~ /content\-transfer\-encoding/i) { $hdrs .= "ce|"; }
    if($key =~ /body/i) { $body = $MSG->{$key}; }
    else { $this->{SMTP_DATA} .= "$key: $MSG->{$key}\015\012"; }
  }
  if($hdrs !~ /m\|/) 
  {
    $this->{SMTP_DATA} .= "Mime-version: 1.0\015\012";
  }
  if($hdrs !~ /ct\|/) { 
    $this->{SMTP_DATA} .= "Content-type: text/plain; charset=\"iso-8859-1\"\015\012";
  }
  if($hdrs !~ /ce\|/) {
    $this->{SMTP_DATA} .= "Content-transfer-encoding: 8bit\015\012";
  }

  if($type =~ /quoted\-printable/i) { encode_qp $body; }
  else { $body =~ s/\012/\015\012/g; }
  $this->{SMTP_DATA} .= "\015\012";
  $this->{SMTP_DATA} .= $body;
  $this->{SMTP_DATA} .= "\015\012.\015\012";

  unless($c) 
  { 
    $this->{ERR} = "setdata method failed: DATA key missing\n";
    return 0; 
  }
  return 1;
}

sub setfrom
{
  my ($this, $from) = @_;
  $this->{SMTP_FROM} = $from;
  return $this->{SMTP_FROM};
}

sub setrcpt
{
  my ($this, $rcpt) = @_;
  return push(@{$this->{SMTP_RCPT}}, $rcpt);
}

sub strerror
{
  my $this = shift;
  return $this->{ERR};
}

1;
__END__

=head1 NAME

Mail::SMI - SMTP and Mail Interface Module

=cut

=head1 SYNOPSIS

  use Mail::SMI;

  $mobj = new Mail::SMI;
  $mobj->connect(HOST, 25) || die $mobj->strerror();
  $mobj->setfrom(MAILFROM) || die $mobj->strerror();
  $mobj->setrcpt(RCPTTO) || die $mobj->strerror();
  $mobj->setrcpt(RCPTTO) || die $mobj->strerror();
  $MSG = {
    'Date' => $mobj->rfc822_date(),
    'To' => 'TO',
    'From' => 'FROM',
    'Subject' => 'SENDMAIL Module',
    'X-AnotherHeader' => 'OK',
    .
    .
    .
    'Body' => BODY
  };
  $mobj->setdata($MSG);
  $mobj->sendmail() || die $mobj->strerror();
  $mobj->disconnect();

=head1 DESCRIPTION

This module was created to substitute the old modules that establish a
new local connection every time that you want send a new mail. 
With this you can make one connection and send all mail throught this connection
without disconnecting in this transaction

=head1 METHODS

=item $mobj = new Mail::SMI;

=item $mobj->connect(HOST, PORT, HOSTNAME);

=item $mobj->disconnect();

=item $mobj->reset();

=item $mobj->rfc822_date();

=item $mobj->sendmail([HOST, PORT]);

=item $mobj->setdata(HASHREF);

=item $mobj->setfrom(FROM);

=item $mobj->setrcpt(RCPT);

=item $mobj->strerror();

=head1 AUTHOR

Daniel Froz Costa 

Please feel free to modify this module,
send diff to dfroz@users.sourceforge.net.
Any suggestions and comments are welcome ;^)

=head1 LICENSE

Copyright (C) 2001 Daniel Froz Costa

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA

=head1 SEE ALSO

perl(1).

=cut
