package Log::Log4perl::Appender::AmazonSES;

use parent qw(Log::Log4perl::Appender);

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(any pairs);
use Net::Domain 'hostfqdn';
use Net::SMTP;

use Readonly;

Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

Readonly::Scalar our $DEFAULT_HOST => 'email-smtp.us-east-1.amazonaws.com';
Readonly::Scalar our $DEFAULT_PORT => '465';

our $VERSION = '1.0.0';

########################################################################
sub new {
########################################################################
  my ( $class, %options ) = @_;

  my $host = delete $options{Host};
  $host //= delete $options{host};

  $host //= $DEFAULT_HOST;

  $options{Port} //= delete $options{port};
  $options{Port} //= $DEFAULT_PORT;

  $options{Hello} //= delete $options{domain};
  $options{Hello} //= hostfqdn;

  my $from    = delete $options{from};
  my $to      = delete $options{to};
  my $subject = delete $options{subject};

  foreach my $p ( pairs( from => $from, to => $to, subject => $subject ) ) {
    croak $p->[0] . ' is a required parameter'
      if !$p->[1];
  }

  my $auth = eval { init_auth( delete $options{auth} ); };

  $options{SSL} = $TRUE;
  $options{Debug} //= delete $options{debug};

  my $self = bless {
    host    => $host,
    auth    => $auth,
    to      => $to,
    from    => $from,
    subject => $subject,
    options => \%options
  }, $class;

  return $self;
}

########################################################################
sub init_auth {
########################################################################
  my ($auth) = @_;

  if ( !$auth || !ref $auth ) {
    if ( $ENV{SES_SMTP_USER} && $ENV{SES_SMTP_PASS} ) {
      $auth = {
        user     => $ENV{SES_SMTP_USER},
        password => $ENV{SES_SMTP_PASS},
      };
    }
  }

  croak sprintf 'auth.user and auth.password are required parameters'
    if !$auth->{user} || !$auth->{password};

  return $auth;
}

########################################################################
sub log {  ## no critic
########################################################################
  my ( $self, %params ) = @_;

  my $smtp = Net::SMTP->new( $self->{host}, %{ $self->{options} }, )
    or croak 'ERROR: unable to create a Net::SMTP instance';

  if ( any { $self->{options}->{Port} eq $_ } qw(25 587) ) {
    $smtp->starttls()
      or croak sprintf 'TLS negotiation with %s failed', $self->{host};
  }

  my $auth = $self->{auth};

  $smtp->auth( $auth->{user}, $auth->{password} );

  $smtp->mail( $self->{from} );
  $smtp->to( split /\s*,\s*/xsm, $self->{to} );

  $smtp->data;

  $smtp->datasend( sprintf "From: %s\n",    $self->{from} );
  $smtp->datasend( sprintf "To: %s\n",      $self->{to} );
  $smtp->datasend( sprintf "Subject: %s\n", $self->{subject} );
  $smtp->datasend( sprintf "\n%s\n",        $params{message} );

  $smtp->dataend
    or carp 'ERROR: could not send message';

  $smtp->quit;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Log::Log4perl::Appender::AmazonSES - Send via Amazon SES (SMTP over TLS)

=head1 SYNOPSIS

  use Log::Log4perl::Appender::AmazonSES;

  my $app = Log::Log4perl::Appender::AmazonSES->new(
    Host    => 'email-smtp.us-east-1.amazonaws.com',
    Port    => '465'
    Hello   => 'localhost.localdomain',
    Timeout => 2,
    Debug   => 0,
    from    => 'me@example.com',
    to      => 'you@example.com',
    subject => 'Alert: there has been an error',
  );

  $app->log(message => "A message via Amazon SES email");

=head1 DESCRIPTION

This appender uses the L<Net::SMTP> module to send mail via Amazon
SES. Essentially a flavor of L<Log::Log4perl::Appender::Net::SMTP> with
some intelligent options and restrictions.

This module was created to provide a straightforward, well-documented
method for sending Log4perl alerts via Amazon SES. While other email
appenders exist, getting them to work with modern, authenticated SMTP
services can be challenging due to outdated dependencies or sparse
documentation. This appender aims to "just work" by using Net::SMTP
directly with the necessary options for SES.

=head1 OPTIONS

=over 2

=item B<from> (required)

The email address of the sender.

=item B<to> (required)

The email address of the recipient. You can put several addresses separated
by a comma.

=item B<subject> (required)

The subject of the email.

=item B<Other Net::SMTP options>

=over 4

=item Hello

Defaults to your fully qualified host's name. You can also use C<domain>.

=item Port

Default port for connection to the SMTP mail host. Amazon supports 25,
465, 587, 2587. The connection will be upgrade to SSL for non-SSL
ports.

Default: 465

=item Debug

Outputs debug information from Net:::SMTP

Default: false

=back

=back

=head1 EXAMPLE LOG4PERL CONFIGURATION

=head2 Use Environment Variables (Best Practice)

 log4perl.rootLogger = INFO, Mailer
 log4perl.appender.Mailer = Log::Log4perl::Appender::AmazonSES
 log4perl.appender.Mailer.from       = ...
 log4perl.appender.Mailer.to         = ...
 log4perl.appender.Mailer.subject    = ...
 log4perl.appender.Mailer.layout = Log::Log4perl::Layout::PatternLayout
 log4perl.appender.Mailer.layout.ConversionPattern = %d - %p > %m%n

=head2 Specify Credentials

 log4perl.rootLogger = INFO, Mailer
 log4perl.appender.Mailer = Log::Log4perl::Appender::AmazonSES
 log4perl.appender.Mailer.from       = ...
 log4perl.appender.Mailer.to         = ...
 log4perl.appender.Mailer.subject    = ...
 log4perl.appender.Mailer.auth.user       = <YOUR AMAZON SES USER>
 log4perl.appender.Mailer.auth.password   = <YOUR AMAZON SES PASSWORD>
 log4perl.appender.Mailer.layout = Log::Log4perl::Layout::PatternLayout
 log4perl.appender.Mailer.layout.ConversionPattern = %d - %p > %m%n

=head1 AUTHENTICATION

You must either supply your authentication parameters in the
configuration of set SES_SMTP_USER and SES_SMTP_PASS environment
variables.

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Log4perl>, L<Net::SMTP>
