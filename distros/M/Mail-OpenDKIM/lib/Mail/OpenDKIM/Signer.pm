package Mail::OpenDKIM::Signer;

use 5.010000;
use strict;
use warnings;

use Error qw(:try);
use Carp;
use Mail::OpenDKIM;
use Mail::OpenDKIM::PrivateKey;  # Including this allows callers to only include Signer.pm
use Mail::OpenDKIM::Signature;

=head1 NAME

Mail::OpenDKIM::Signer - generates a DKIM signature for a message

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Use this class to generate a signature for inclusion in the header of an email.

It provides enough of a subset of the functionaility of Mail::DKIM::Signer to allow
use of the OpenDKIM library with simple drop-in replacements. Mail::OpenDKIM::Signer
offloads the signing work to the OpenDKIM library, and is therefore far quicker.

=head1 SUBROUTINES/METHODS

=head2 new

Creates the signer.

=cut

# singleton for the DKIM library handle object.
# goes away when program exits.
our $oh;

sub new {
  my ($class, %args) = @_;

  my $self = {
  };

  # on first time through, init the OpenDKIM library
  unless ($oh) {
    $oh = Mail::OpenDKIM->new();
    $oh->dkim_init();
  }

  my $algorithm;

  if(!$args{Algorithm}) {
    croak('Missing algorithm');
  }
  elsif($args{Algorithm} eq 'rsa-sha1') {
    $algorithm = DKIM_SIGN_RSASHA1;
  }
  elsif($args{Algorithm} eq 'rsa-sha256') {
    $algorithm = DKIM_SIGN_RSASHA256;
  }
  else {
    croak("Unsupported algorithm: $args{Algorithm}");
  }

  my ($h, $b);

  if(!$args{Method}) {
    croak('Missing method');
  }
  elsif($args{Method} =~ /(.+)\/(.+)/) {
    $h = $1;
    $b = $2;
  }
  else {
    $h = $args{Method};
    $b = $h;
  }

  my ($hdrcanon_alg, $bodycanon_alg);

  if($h eq 'relaxed') {
    $hdrcanon_alg = DKIM_CANON_RELAXED;
  }
  elsif($h eq 'simple') {
    $hdrcanon_alg = DKIM_CANON_SIMPLE;
  }
  else {
    croak("Unsupported method: $h");
  }

  if($b eq 'relaxed') {
    $bodycanon_alg = DKIM_CANON_RELAXED;
  }
  elsif($b eq 'simple') {
    $bodycanon_alg = DKIM_CANON_SIMPLE;
  }
  else {
    croak("Unsupported method: $b");
  }

  my $signer;

  try {
    $signer = $oh->dkim_sign({
      id => 'MLM',
      secretkey => $args{Key}->data(),
      selector => $args{Selector},
      domain => $args{Domain},
      hdrcanon_alg => $hdrcanon_alg,
      bodycanon_alg => $bodycanon_alg,
      sign_alg => $algorithm,
      length => -1
    });
  } catch Error with {
    my $ex = shift;
    croak($ex->stringify);
  };

  $self->{_signer} = $signer;  # Mail::OpenDKIM::DKIM object
  $self->{_signature} = Mail::OpenDKIM::Signature->new(%args);

  bless $self, $class;

  return $self;
}

=head2 PRINT

Feed part of the message to the signer.

=cut

sub PRINT
{
  my $self = shift;

  return unless(@_);

  my $signer = $self->{_signer};

  foreach(@_) {
    $signer->dkim_chunk({ chunkp => $_, len => length($_) });
  }
}

=head2 CLOSE

Call this when when you have finished feeding in the message to the signer.

=cut

sub CLOSE
{
  my $self = shift;

  my $signer = $self->{_signer};

  $signer->dkim_chunk({ chunkp => '', len => 0 });

  if($signer->dkim_eom() != DKIM_STAT_OK) {
    croak($signer->dkim_geterror());
  }
  my $args = {
    initial => 0,
    buf => undef,
    len => undef
  };

  $self->{_signer}->dkim_getsighdr_d($args);

  $self->{_signature}->data($$args{buf});
}

=head2 signature

Access the generated Mail::OpenDKIM::Signature object.

=cut

sub signature
{
  my $self = shift;

  return $self->{_signature};
}

=head2 dkim_options

For further information, refer to http://www.opendkim.org/libopendkim/

=cut

sub dkim_options
{
  my ($self, $args) = @_;

  return $oh->dkim_options($args);
}

sub DESTROY
{
  my $self = shift;

  if($self->{_signer}) {
    $self->{_signer}->dkim_free();
  }
}

END {
  $oh->dkim_close() if $oh;
}

=head2 EXPORT

This module exports nothing.

=head1 SEE ALSO

Mail::DKIM::Signer

=head1 NOTES

This module does not yet implement all of the API of Mail::DKIM::Signer

The PRINT method is expensive.  To increase performance we recommend that you
minimise the number of calls to this function, perhaps by storing the message
in a buffer before passing it to this function.

=head1 AUTHOR

Nigel Horne, C<< <nigel at mailermailer.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-opendkim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-OpenDKIM>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::OpenDKIM::Signer


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

This module is Copyright 2011 Khera Communications, Inc.  It is
licensed under the same terms as Perl itself.

=cut

1;
