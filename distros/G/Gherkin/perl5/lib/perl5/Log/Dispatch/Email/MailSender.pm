package Log::Dispatch::Email::MailSender;

# By: Joseph Annino
# (c) 2002
# Licensed under the same terms as Perl
#

use strict;
use warnings;

our $VERSION = '2.70';

use Log::Dispatch::Types;
use Mail::Sender ();
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Email );

{
    my $validator = validation_for(
        params => {
            smtp         => { default => 'localhost' },
            port         => { default => 25 },
            authid       => 0,
            authpwd      => 0,
            auth         => 0,
            tls_required => 0,
            replyto      => 0,
            fake_from    => 0,
        },
        slurpy => 1,
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $smtp         = delete $p{smtp};
        my $port         = delete $p{port};
        my $authid       = delete $p{authid};
        my $authpwd      = delete $p{authpwd};
        my $auth         = delete $p{auth};
        my $tls_required = delete $p{tls_required};
        my $replyto      = delete $p{replyto};
        my $fake_from    = delete $p{fake_from};

        my $self = $class->SUPER::new(%p);

        $self->{smtp} = $smtp;
        $self->{port} = $port;

        $self->{authid}       = $authid;
        $self->{authpwd}      = $authpwd;
        $self->{auth}         = $auth;
        $self->{tls_required} = $tls_required;

        $self->{fake_from} = $fake_from;
        $self->{replyto}   = $replyto;

        return $self;
    }
}

sub send_email {
    my $self = shift;
    my %p    = @_;

    local ( $?, $@, $SIG{__DIE__} ) = ( 0, undef, undef );
    return
        if eval {
        my $sender = Mail::Sender->new(
            {
                from         => $self->{from} || 'LogDispatch@foo.bar',
                fake_from    => $self->{fake_from},
                replyto      => $self->{replyto},
                to           => ( join ',', @{ $self->{to} } ),
                subject      => $self->{subject},
                smtp         => $self->{smtp},
                port         => $self->{port},
                authid       => $self->{authid},
                authpwd      => $self->{authpwd},
                auth         => $self->{auth},
                tls_required => $self->{tls_required},

                #debug => \*STDERR,
            }
        );

        die "Error sending mail ($sender): $Mail::Sender::Error"
            unless ref $sender;

        ref $sender->MailMsg( { msg => $p{message} } )
            or die "Error sending mail: $Mail::Sender::Error";

        1;
        };

    warn $@ if $@;
}

1;

# ABSTRACT: Subclass of Log::Dispatch::Email that uses the Mail::Sender module

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Email::MailSender - Subclass of Log::Dispatch::Email that uses the Mail::Sender module

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Email::MailSender',
              min_level => 'emerg',
              to        => [qw( foo@example.com bar@example.org )],
              subject   => 'Big error!'
          ]
      ],
  );

  $log->emerg("Something bad is happening");

=head1 DESCRIPTION

This is a subclass of L<Log::Dispatch::Email> that implements the send_email
method using the L<Mail::Sender> module.

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the parameters
documented in L<Log::Dispatch::Output> and L<Log::Dispatch::Email>:

=over 4

=item * smtp ($)

The smtp server to connect to. This defaults to "localhost".

=item * port ($)

The port to use when connecting. This defaults to 25.

=item * auth ($)

Optional. The SMTP authentication protocol to use to login to the server. At
the time of writing Mail::Sender only supports LOGIN, PLAIN, CRAM-MD5 and
NTLM.

Some protocols have module dependencies. CRAM-MD5 depends on Digest::HMAC_MD5
and NTLM on Authen::NTLM.

=item * authid ($)

Optional. The username used to login to the server.

=item * authpwd ($)

Optional. The password used to login to the server.

=item * tls_required ($)

Optional. If you set this option to a true value, Mail::Sender will fail
whenever it's unable to use TLS.

=item * fake_from ($)

The From address that will be shown in headers. If not specified we use the
value of from.

=item * replyto ($)

The reply-to address.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
