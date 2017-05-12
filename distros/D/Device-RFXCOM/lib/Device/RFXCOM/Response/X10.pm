use strict;
use warnings;
package Device::RFXCOM::Response::X10;
$Device::RFXCOM::Response::X10::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for X10 message from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_X10_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'x10' }


sub device { shift->{device} }


sub house { shift->{house} }


sub command { shift->{command} }


sub level { shift->{level} }


sub summary {
  my $self = shift;
  sprintf('%s/%s/%s%s',
          $self->type,
          $self->device ? $self->device : $self->house,
          $self->command,
          $self->level ? '['.$self->level.']' : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::X10 - Device::RFXCOM::Response class for X10 message from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for X10 messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'x10'.

=head2 C<device()>

This method returns the X10 device from the RF message.  That is,
C<a1>, C<a2>, ... C<a16>, ..., C<p1>, ..., C<p16>.  It will be
undefined if no unit code is present for the house code.

=head2 C<house()>

This method returns the X10 house code from the RF message.  That is,
C<a>, C<b>, ... C<p>.  It will be undefined if device() is defined.

=head2 C<command()>

This method returns the X10 command from the RF message.  For example,
C<on>, C<off>, C<bright>, C<dim>, etc.

=head2 C<level()>

This method returns the X10 level for C<bright> and C<dim> commands or
undef if the level is not defined for the command.

=head2 C<summary()>

This method returns a string summary of the X10 message.

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
