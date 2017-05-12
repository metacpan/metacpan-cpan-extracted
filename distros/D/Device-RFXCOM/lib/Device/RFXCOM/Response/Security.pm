use strict;
use warnings;
package Device::RFXCOM::Response::Security;
$Device::RFXCOM::Response::Security::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for Security messages from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_SECURITY_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'security' }


sub device { shift->{device} }


sub event { shift->{event} }


sub tamper { shift->{tamper} }


sub min_delay { shift->{min_delay} }


sub summary {
  my $self = shift;
  $self->type.'/'.$self->device.'/'.$self->event.
    ($self->tamper ? '/tamper' : '').
    ($self->min_delay ? '/min' : '')
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::Security - Device::RFXCOM::Response class for Security messages from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Security messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'security'.

=head2 C<device()>

This method returns a string representing the device that sent the
security RF message.

=head2 C<event()>

This method returns a string representing the type of event described
by the security RF message.

=head2 C<tamper()>

This method returns true of the C<tamper> flag was set in the security
RF message.

=head2 C<min_delay()>

This method returns true of the C<min_delay> flag was set in the
security RF message.

=head2 C<summary()>

This method returns a string summary of the security message.

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
