use strict;
use warnings;
package Device::RFXCOM::Response;
$Device::RFXCOM::Response::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for data from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { shift->{type} }


sub header_byte { shift->{header_byte} }


sub master { shift->{master} }


sub hex_data { unpack 'H*', shift->data }


sub data { shift->{data} }


sub length { length shift->data }


sub bytes { shift->{bytes} }


sub messages { shift->{messages} || [] }


sub duplicate { shift->{duplicate} }


sub summary {
  my $self = shift;
  my $str = join "\n  ", map { $_->summary } @{$self->messages};
  sprintf('%s %s %02x.%s%s%s',
          $self->master ? 'master' : 'slave',
          $self->type,
          $self->header_byte,
          $self->hex_data,
          $self->duplicate ? '(dup)' : '',
          $str =~ /\n/ ? ":\n  ".$str : $str ne '' ? ': '.$str : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response - Device::RFXCOM::Response class for data from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Base class for RFXCOM response modules.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns the type of the response.  It will be one of:

=over

=item unknown

for a message that could not be decoded

=item version

for a response to a version check request

=item mode

for a response to a mode setting request

=item empty

for an empty message

=back

or it will be a string representing the type of device from which the
message originated.

=head2 C<header_byte()>

This method returns the header byte contains the length in buts and
master/slave flag for the message.

=head2 C<master()>

This method returns true of the message originated from the master
receiver or false of it originated from a slave receiver.

=head2 C<hex_data()>

This method returns a hex string representing the payload of the RF
message.

=head2 C<data()>

This method returns the binary string of the payload of the RF
message.

=head2 C<length()>

This method returns the length of the payload of the RF message (in bytes).

=head2 C<bytes()>

This method returns an array reference of bytes representing the
payload of the RF message.

=head2 C<messages()>

This method returns an array reference of message objects generated
from the payload.

=head2 C<duplicate()>

This method returns a true value if the message was identical to another
sent recently.

=head2 C<summary()>

This method returns a string summary of the contents of the RF message.
(If there are multiple message objects produced from the payload then
this may be a multiline string.)

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
