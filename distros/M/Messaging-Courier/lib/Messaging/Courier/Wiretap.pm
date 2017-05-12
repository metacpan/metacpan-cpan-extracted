package Messaging::Courier::Wiretap;
use strict;
use warnings;

use EO;
use Messaging::Courier;
use Regexp::Common;
use base qw( EO Class::Accessor::Chained );
__PACKAGE__->mk_accessors(qw( courier ));

our $VERSION = '0.42';

sub init {
  my $self = shift;

  if ($self->SUPER::init( @_ )) {
    my $courier = Messaging::Courier->new;
    $self->courier($courier);
    return 1;
  } else {
    return 0;
  }
}

sub tap {
  my $self    = shift;
  my $timeout = shift || 0;
  my $mailbox = $self->courier->mailbox;

  if ($timeout && $timeout !~ /^$RE{num}{real}$/) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a number';
  }

  if ($timeout && $timeout < 0) {
    throw EO::Error::InvalidParameters
      text => 'timeout must be a positive number';
  }

  my($service_type, $sender, $groups, $mess_type, $endian, $message) =
    Spread::receive( $mailbox, $timeout );

  return $message;
}

1;

__END__

=head1 NAME

Courier - asynchronous and synchronous access to a message queue.

=head1 SYNOPSIS

  use Messaging::Courier::Wiretap;
  my $w = Messaging::Courier::Wiretap->new();
  my $xml = $w->tap(0.1);

=head1 DESCRIPTION

C<Courier::Wiretap> is a wiretap onto the Courier message queue. It
allows you to inspect messages that travel on the queue. It returns
these in XML format.

=head1 METHODS

=head2 new

This is the constructor. It currently takes no arguments.

=head2 tap([TIMEOUT])

This method receives a message from the queue in raw XML. If called
without a TIMEOUT or a TIMEOUT set to zero any call to receive will
block. If a timeout is specified receive does not block but returns
undef in the case that it does not receive a message.

=head1 SEE ALSO

Courier

=head1 AUTHOR

Leon Brocard <lbrocard@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

=cut









