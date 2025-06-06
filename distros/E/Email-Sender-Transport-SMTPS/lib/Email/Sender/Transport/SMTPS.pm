package Email::Sender::Transport::SMTPS;

use Moo;
use MooX::Types::MooseLike::Base qw(Bool Int Str);
# ABSTRACT: Email::Sender joins Net::SMTPS

use Email::Sender::Failure::Multi;
use Email::Sender::Success::Partial;
use Email::Sender::Util;
our $VERSION = '0.05';

has host => (is => 'ro', isa => Str,  default => sub { 'localhost' });
has ssl  => (is => 'ro', isa => Str);
my $SSLArgs = sub {
    my $ref = shift;
    die "ssl_args must be a hash reference" unless ref($ref) eq 'HASH';
    for my $key (keys %$ref) {
        die "Invalid key in ssl_args: $key (must start with SSL_)" unless $key =~ /^SSL_/;
    }
    return $ref;
};
has ssl_args => (
    is      => 'ro',
    isa     => $SSLArgs,
    default => sub { {} },
);
has port => (
  is  => 'ro',
  isa => Int,
  lazy    => 1,
  default => sub { return ($_[0]->ssl and $_[0]->ssl eq 'starttls') ? 587 : $_[0]->ssl ? 465 : 25; },
);

has timeout => (is => 'ro', isa => Int, default => sub { 120 });

has sasl_username => (is => 'ro', isa => Str);
has sasl_password => (is => 'ro', isa => Str);

has allow_partial_success => (is => 'ro', isa => Bool, default => sub { 0 });

has helo      => (is => 'ro', isa => Str);
has localaddr => (is => 'ro');
has localport => (is => 'ro', isa => Int);
has debug     => (is => 'ro', isa => Bool);

# I am basically -sure- that this is wrong, but sending hundreds of millions of
# messages has shown that it is right enough.  I will try to make it textbook
# later. -- rjbs, 2008-12-05
sub _quoteaddr {
  my $addr       = shift;
  my @localparts = split /\@/, $addr;
  my $domain     = pop @localparts;
  my $localpart  = join q{@}, @localparts;

  # this is probably a little too paranoid
  return $addr unless $localpart =~ /[^\w.+-]/ or $localpart =~ /^\./;
  return join q{@}, qq("$localpart"), $domain;
}

sub _smtp_client {
  my ($self) = @_;

  my $class = "Net::SMTP";
  if ($self->ssl) {
    require Net::SMTPS;
    $class = "Net::SMTPS";
  } else {
    require Net::SMTP;
  }

  my $smtp = $class->new( $self->_net_smtp_args );

  $self->_throw("unable to establish SMTP connection") unless $smtp;

  if ($self->sasl_username) {
    $self->_throw("sasl_username but no sasl_password")
      unless defined $self->sasl_password;

    unless ($smtp->auth($self->sasl_username, $self->sasl_password)) {
      if ($smtp->message =~ /MIME::Base64|Authen::SASL/) {
        Carp::confess("SMTP auth requires MIME::Base64 and Authen::SASL");
      }

      $self->_throw('failed AUTH', $smtp);
    }
  }

  return $smtp;
}

sub _net_smtp_args {
  my ($self) = @_;

  # compatible
  my $ssl = $self->ssl;
  $ssl = 'ssl' if $self->ssl and $self->ssl ne 'starttls';
  return (
    $self->host,
    Port    => $self->port,
    Timeout => $self->timeout,
    defined $ssl             ? (doSSL     => $ssl)             : (),
    defined $self->ssl_args  ? %{ $self->ssl_args }            : (),
    defined $self->helo      ? (Hello     => $self->helo)      : (),
    defined $self->localaddr ? (LocalAddr => $self->localaddr) : (),
    defined $self->localport ? (LocalPort => $self->localport) : (),
    defined $self->debug     ? (Debug     => $self->debug)     : (),
  );
}

sub _throw {
  my ($self, @rest) = @_;
  Email::Sender::Util->_failure(@rest)->throw;
}

sub send_email {
  my ($self, $email, $env) = @_;

  Email::Sender::Failure->throw("no valid addresses in recipient list")
    unless my @to = grep { defined and length } @{ $env->{to} };

  my $smtp = $self->_smtp_client;

  my $FAULT = sub { $self->_throw($_[0], $smtp); };

  $smtp->mail(_quoteaddr($env->{from}))
    or $FAULT->("$env->{from} failed after MAIL FROM:");

  my @failures;
  my @ok_rcpts;

  for my $addr (@to) {
    if ($smtp->to(_quoteaddr($addr))) {
      push @ok_rcpts, $addr;
    } else {
      # my ($self, $error, $smtp, $error_class, @rest) = @_;
      push @failures, Email::Sender::Util->_failure(
        undef,
        $smtp,
        recipients => [ $addr ],
      );
    }
  }

  # This logic used to include: or (@ok_rcpts == 1 and $ok_rcpts[0] eq '0')
  # because if called without SkipBad, $smtp->to can return 1 or 0.  This
  # should not happen because we now always pass SkipBad and do the counting
  # ourselves.  Still, I've put this comment here (a) in memory of the
  # suffering it caused to have to find that problem and (b) in case the
  # original problem is more insidious than I thought! -- rjbs, 2008-12-05

  if (
    @failures
    and ((@ok_rcpts == 0) or (! $self->allow_partial_success))
  ) {
    $failures[0]->throw if @failures == 1;

    my $message = sprintf '%s recipients were rejected during RCPT',
      @ok_rcpts ? 'some' : 'all';

    Email::Sender::Failure::Multi->throw(
      message  => $message,
      failures => \@failures,
    );
  }

  # restore Pobox's support for streaming, code-based messages, and arrays here
  # -- rjbs, 2008-12-04

  $smtp->data                        or $FAULT->("error at DATA start");

  my $msg_string = $email->as_string;
  my $hunk_size  = $self->_hunk_size;

  while (length $msg_string) {
    my $next_hunk = substr $msg_string, 0, $hunk_size, '';
    $smtp->datasend($next_hunk) or $FAULT->("error at during DATA");
  }

  $smtp->dataend                     or $FAULT->("error at after DATA");

  my $message = $smtp->message;

  $self->_message_complete($smtp);

  # We must report partial success (failures) if applicable.
  return $self->success({ message => $message }) unless @failures;
  return $self->partial_success({
    message => $message,
    failure => Email::Sender::Failure::Multi->new({
      message  => 'some recipients were rejected during RCPT',
      failures => \@failures
    }),
  });
}

sub _hunk_size { 2**20 } # send messages to DATA in hunks of 1 mebibyte

sub success {
  my $self = shift;
  my $success = Moo::Role->create_class_with_roles('Email::Sender::Success', 'Email::Sender::Role::HasMessage')->new(@_);
}

sub partial_success {
  my $self = shift;
  my $partial_success = Moo::Role->create_class_with_roles('Email::Sender::Success::Partial', 'Email::Sender::Role::HasMessage')->new(@_);
}

sub _message_complete { $_[1]->quit; }

with 'Email::Sender::Transport';
no Moo;
1;
__END__

=encoding utf-8

=head1 NAME

Email::Sender::Transport::SMTPS - Email::Sender joins Net::SMTPS

=head1 SYNOPSIS

	use Email::Sender::Simple qw(sendmail);
	use Email::Sender::Transport::SMTPS;
	use Try::Tiny;

	my $transport = Email::Sender::Transport::SMTPS->new(
	    host => 'smtp.gmail.com',
	    ssl  => 'starttls',
	    sasl_username => 'myaccount@gmail.com',
	    sasl_password => 'mypassword',
        debug => 0, # or 1
	);

	# my $message = Mail::Message->read($rfc822)
	#         || Email::Simple->new($rfc822)
	#         || Mail::Internet->new([split /\n/, $rfc822])
	#         || ...
	#         || $rfc822;
	# read L<Email::Abstract> for more details

	use Email::Simple::Creator; # or other Email::
	my $message = Email::Simple->create(
	    header => [
	        From    => 'myaccount@gmail.com',
	        To      => 'to@mail.com',
	        Subject => 'Subject title',
	    ],
	    body => 'Content.',
	);

	try {
	    sendmail($message, { transport => $transport });
	} catch {
	    die "Error sending email: $_";
	};

=head1 DESCRIPTION

B<DEPRECATED>. Please use L<Email::Sender::Transport::SMTP> instead.

This transport is used to send email over SMTP, either with or without secure
sockets (SSL/TLS). it uses the great L<Net::SMTPS>.

=head1 ATTRIBUTES

The following attributes may be passed to the constructor:

=over 4

=item C<host>: the name of the host to connect to; defaults to C<localhost>

=item C<ssl>: 'ssl' / 'starttls' / undef, if true, passed to L<Net::SMTPS> doSSL.

=item C<port>: port to connect to; defaults to 25 for non-SSL, 465 for 'ssl' and 587 for 'starttls'

=item C<timeout>: maximum time in secs to wait for server; default is 120

=item C<sasl_username>: the username to use for auth; optional

=item C<sasl_password>: the password to use for auth; required if C<username> is provided

=item C<allow_partial_success>: if true, will send data even if some recipients were rejected; defaults to false

=item C<helo>: what to say when saying HELO; no default

=item C<localaddr>: local address from which to connect

=item C<localport>: local port from which to connect

=item C<debug>: enable debug info for Net::SMTPS

=back

=head1 PARTIAL SUCCESS

If C<allow_partial_success> was set when creating the transport, the transport
may return L<Email::Sender::Success::Partial> objects.  Consult that module's
documentation.

=head1 EXAMPLES

=head2 send email with Gmail

  my $transport = Email::Sender::Transport::SMTPS->new({
    host => 'smtp.gmail.com',
    ssl  => 'starttls',
    sasl_username => 'myaccount@gmail.com',
    sasl_password => 'mypassword',
  });

=head2 send email with mandrillapp

  my $transport = Email::Sender::Transport::SMTPS->new(
    host => 'smtp.mandrillapp.com',
    ssl  => 'starttls',
    sasl_username => 'myaccount@blabla.com',
    sasl_password => 'api_key',
    helo => 'fayland.me',
  );

=head2 send with Amazon SES

  my $transport = Email::Sender::Transport::SMTPS->new(
    host => 'email-smtp.us-east-1.amazonaws.com',
    ssl  => 'starttls',
    sasl_username => 'xx',
    sasl_password => 'zzz',
  );

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
