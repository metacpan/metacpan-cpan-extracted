
package Email::Verify::SMTP;

use strict;
use warnings 'all';
use base 'Exporter';
use Net::Nslookup;
use IO::Socket::Telnet;
use Carp 'confess';

our @EXPORT  = ('verify_email');
our $VERSION = '0.003';
our $FROM    = 'root@localhost';
our $DEBUG   = 0;

sub verify_email
{
  my $email = shift or return;
  $email = lc($email);

  my $error;

  my (undef, $domain) = split /@/, $email;
  unless( $domain )
  {
    return _result(
      undef, "Invalid email address"
    );
  }# end unless()


  my $err = undef;
  my $host = $domain;
  local $SIG{ALRM} = sub {
    $err = "Timeout on host '$host'";
    die "Timeout on host '$host'";
  };

  alarm(4);
  my ($mx) = eval {
    my ($mx) = nslookup(domain => $domain, type => "MX")
      or do { $err = "No mx records found for '$domain'"; die };
    $mx;
  } or return _result(undef, "No mx records found for '$domain'");
  $host = $mx;
  alarm(0);
  return _result( undef, $err || $@ ) if $err || $@;

  my $t = IO::Socket::Telnet->new(
    PeerAddr => $mx,
    PeerPort => 25,
  ) or return _result(undef, "Cannot open socket to '$mx'");

  alarm(8);
  my $res = eval {
    $t->send("helo $domain\n");
    $t->recv(my $res, 4096) or do{ $err = "Socket error on HELO"; die };
    warn $res if $DEBUG;

    $t->send(qq(mail from: <$FROM>\n));
    $t->recv($res, 4096) or do{ $err = "Socket error on MAIL FROM"; die };
    warn $res if $DEBUG;

    $t->send(qq(rcpt to: <$email>\n));
    $t->recv($res, 4096) or do{ $err = "Socket error on RCPT TO"; die };
    warn $res if $DEBUG;

    $res;
  };
  alarm(0);
  
  $t->close;
  return _result( undef, $err || $@ ) if $@;
  
  my $is_valid = $res =~ m/^250\b/;
  return _result( $is_valid, $is_valid ? "" : $res );
}# end verify()


sub _result
{
  my ($valid, $msg) = @_;
  
  if( wantarray )
  {
    chomp($msg);
    return (
      $valid, $msg
    );
  }
  else
  {
    return unless defined $valid;
    return $valid;
  }# end if()
}# end _result()

1;# return true:

=pod

=head1 NAME

Email::Verify::SMTP - Verify an email address by using SMTP.

=head1 SYNOPSIS

  use Email::Verify::SMTP;
  
  # This is important:
  $Email::Verify::SMTP::FROM = 'verifier@my-server.com';
  
  # Just a true/false:
  if( verify_email('foo@example.com') ) {
    # Email is valid
  }
  
  # Find out if, and why not (if not):
  my ($is_valid, $msg) = verify_email('foo@example.com');
  if( $is_valid ) {
    # Email is valid:
  }
  else {
    # Email is *not* valid:
    warn "Email is bad: $msg";
  }

=head1 DESCRIPTION

C<Email::Verify::Simple> is what I came with when I needed to verify several email 
addresses without actually sending them email.

To put that another way:

=over 4

B<This module verifies email addresses without actually sending email to them.>

=back

=head1 EXPORTED FUNCTIONS

=head2 verify_email( $email )

Verifies the supplied email address.

If called in scalar context, eg:

  my $is_valid = verify_email( $email )

then you get a true or false value.

If called in list context, eg:

  my ($is_valid, $why_not) = verify_email( $email )

then you get both a true/false value and any error message that came up.

=head1 PUBLIC STATIC VARIABLES

=head2 $Email::Verify::SMTP::FROM

Default value: <root@localhost>

This is used as the "from" field on the email that is not actually sent.  It
should be a valid email address on a real domain - just like if you were sending
a normal email.

=head2 $Email::Verify::SMTP::DEBUG

Default value: C<0>

If set to a true value, extra diagnostics will be output to STDERR via C<warn>.

=head1 DEPENDENCIES

This module depends on the following:

=over 4

=item L<Net::Nslookup>

To discover the mail exchange servers for the email address provided.

=item L<IO::Socket::Telnet>

A nice socket interface to use, even if you're not using Telnet.

=back

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used, copied and redistributed under
the same terms as perl itself.

=cut

