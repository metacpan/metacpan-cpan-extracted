package Log::Dispatch::Email::MIMELite;

use strict;
use warnings;

our $VERSION = '2.70';

use MIME::Lite;

use base qw( Log::Dispatch::Email );

sub send_email {
    my $self = shift;
    my %p    = @_;

    my %mail = (
        To      => ( join ',', @{ $self->{to} } ),
        Subject => $self->{subject},
        Type    => 'TEXT',
        Data    => $p{message},
    );

    $mail{From} = $self->{from} if defined $self->{from};

    local $? = 0;
    unless ( MIME::Lite->new(%mail)->send ) {
        warn 'Error sending mail with MIME::Lite';
    }
}

1;

# ABSTRACT: Subclass of Log::Dispatch::Email that uses the MIME::Lite module

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Email::MIMELite - Subclass of Log::Dispatch::Email that uses the MIME::Lite module

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Email::MIMELite',
              min_level => 'emerg',
              to        => [qw( foo@example.com bar@example.org )],
              subject   => 'Big error!'
          ]
      ],
  );

  $log->emerg("Something bad is happening");

=head1 DESCRIPTION

This is a subclass of L<Log::Dispatch::Email> that implements the
send_email method using the L<MIME::Lite> module.

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
