package Hey::Common;

our $VERSION = '0.01';

=cut

=head1 NAME

Hey::Common - Common functions used in other Hey::* modules

=head1 SYNOPSIS

  use Hey::Common;
  my $common = Hey::Common->new;
  
  my $money = $common->formatMoney(524.4);  # will return string "524.40"

=head1 DESCRIPTION

=head2 new

  my $common = Hey::Common->new;

This function provides access to all of these following methods.

=cut

sub new {
  my $class = shift;
  my %param = @_;
  my $self = bless({}, $class);
  return $self;
}

=cut

=head2 forceArray

  $data->{users} = $common->forceArray($data->{users});

The input can either be an array ref or non-array ref.  The output will either be
that same array ref, or the non-array ref as the only item in an array as a ref.

This is useful for items that might or might not be an array ref, but you are
expecting an array ref.

=cut

sub forceArray {
  my $self = shift;
  my $in = shift;
  if (ref($in) eq "ARRAY") {
    return $in;
  }
  my $out;
  push(@{$out}, $in);
  return $out;
}

=cut

=head2 randomCode

  $someRandomCode = $common->randomCode($lengthOfCodeRequested, $keyStringOfPermittedCharacters);

  $someRandomCode = $common->randomCode(); # defaults for length and key
  $someRandomCode = $common->randomCode(8); # choose a specific length, but default key
  $someRandomCode = $common->randomCode(12, 'abcdefg'); # choose a specific length and key

$lengthOfCodeRequested defaults to 16.

$keyStringOfPermittedCharacters defaults to 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.

=cut

sub randomCode {
  my $self = shift;
  my $length = shift || 16;
  my $key = shift || qq(abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789);
  my $value = "";
  while (length($value) < $length) {
    $value .= substr($key, int(rand() * length($key)), 1);
  }
  return $value;
}

=cut

=head2 deepCopy

  my $newCopyOfSomeHashRef = $common->deepCopy($someHashRef);

It makes a copy of a reference instead of making a reference to it.  There's some usefulness there.

=cut

sub deepCopy { # I don't know where this function came from, but it works nicely and has for years and years.  Source unknown.
  my $self = shift;
  my $this = shift;
  if (not ref($this)) {
    $this;
  } elsif (ref($this) eq "ARRAY") {
    [map $self->deepCopy($_), @{$this}];
  } elsif (ref($this) eq "HASH") {
    +{map { $_ => $self->deepCopy($this->{$_}) } keys(%{$this})};
  }
}

=cut

=head2 isAffirmative

  if ($common->isAffirmative('y')) {
    print "'y' is affirmative, so you'll see this.";
  }
  
  if ($common->isAffirmative('no')) {
    print "'no' is not affirmative, so you won't see this";
  }

This checks to see if the value is affirmative.

Things that are affirmative are: 'y', 'yes', 't', 'true', or any true numerical value.

=cut

sub isAffirmative {
  my $self = shift;
  my $in = lc(shift) || return undef;
  $in =~ s|\s+||g;
  if ($in =~ m|^t(r(u(e)?)?)?$|) {
    return true;
  }
  if ($in =~ m|^y(e(s)?)?$|) {
    return true;
  }
  if ($in =~ m|^\d+$| && $in > 0) {
    return true;
  }
  return undef;
}

=cut

=head2 isNegative

  if ($common->isNegative('y')) {
    print "'y' is not negative, so you won't see this.";
  }
  
  if ($common->isNegative('no')) {
    print "'no' is negative, so you'll see this";
  }

This checks to see if the value is negative.

Things that are negative are: 'n', 'no', 'f', 'false', any false numerical value (zero), or undef/null.

=cut

sub isNegative {
  my $self = shift;
  my $in = lc(shift) || return true;
  $in =~ s|\s+||g;
  if ($in =~ m|^f(a(l(s(e)?)?)?)?$|) {
    return true;
  }
  if ($in =~ m|^n(o)?$|) {
    return true;
  }
  if ($in =~ m|^\d+$| && $in <= 0) {
    return true;
  }
  if ($in =~ m|^$|) {
    return true;
  }
  return undef;
}

=cut

=head2 smtpClient

  my @aListOfRecipientEmailAddresses = ('george@somewhere.com', 'ed@server.com', 'ralph@elsewhere.com');

  my $contentOfEmailIncludingHeader = <<CONTENT;
  From: fred@someplace.com
  To: fred@someplace.com
  Subject: The email subject

  This is the email body area.  Fill it full of useful email content.
  
  Thanks,
  Fred
  Someplace Inc.
  CONTENT
  
  $common->smtpClient({ Host => 'smtp.server.someplace.com',
                        From => 'fred@someplace.com',
                        To => \@aListOfRecipientEmailAddresses,
                        Content => $contentOfEmailIncludingHeader });

'Host' is optional and defaults to 'localhost'.  Of course, you would need to be able to send email through whatever host you specify.

'From' is a single email address that is used as the envelope address.

'To' can be a single email address or a list of email addresses as a scalar or an array ref.

'Content' is the content of the email, with header and body included.

=cut

sub smtpClient {
  my $self = shift;
  my %param = @_;
  my $host = $param{host} || $param{Host} || "localhost";
  my $from = $param{from} || $param{From};
  my $content = $param{content} || $param{Content};
  my $to = $self->forceArray($param{to} || $param{To});
  use Net::SMTP;
  my $smtp = Net::SMTP->new($host);
  $smtp->mail($from);
  foreach my $ito (@{$to}) {
    $smtp->to($ito);
  }
  $smtp->data();
  $smtp->datasend($content);
  $smtp->dataend();
  $smtp->quit();
  return;
}

=cut

=head2 formatMoney

  my $money = 515.3;
  $money = $common->formatMoney($money);

$money is the non-formatted money amount.  It will be returned as a formatted string, but with no currency symbol.

=cut

sub formatMoney { # probably could use some work, but it works.
  my $self = shift;
  my $in = shift || 0;
  $in = $in * 100;
  $in = int($in.".00");
  $in = $in / 100;
  $in = "$in";
  unless ($in =~ m|\.|) {
    $in .= ".";
  }
  until ($in =~ m|\.\d{2}|) {
    $in .= "0";
  }
  return $in;
}

=cut

=head2 sha1

  my $something = 'This is something that will be hashed.';
  my $sha1Hash = $common->sha1($something);

$something is any value that you want hashed.  It can be a binary value or a simple scalar.

$sha1Hash is a simple sha1 hex of whatever you passed in.

=cut

sub sha1 {
  my $self = shift;
  my $input = shift;
  use Digest::SHA1 'sha1_hex';
  return sha1_hex($input);
}

=cut

=head1 AUTHOR

Dusty Wilson E<lt>module-Hey-Common@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson, hey.nu Network Community Services

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
