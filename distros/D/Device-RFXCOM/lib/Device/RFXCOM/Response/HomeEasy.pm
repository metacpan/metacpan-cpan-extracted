use strict;
use warnings;
package Device::RFXCOM::Response::HomeEasy;
$Device::RFXCOM::Response::HomeEasy::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for Home Easy message from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_HOMEEASY_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'homeeasy' }


sub address { shift->{address} }


sub unit { shift->{unit} }


sub command { shift->{command} }


sub level { shift->{level} }


sub summary {
  my $self = shift;
  sprintf('%s/%s.%s/%s%s',
          $self->type,
          $self->address,$self->unit,
          $self->command,
          $self->level ? '['.$self->level.']' : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::HomeEasy - Device::RFXCOM::Response class for Home Easy message from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Home Easy messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'homeeasy'.

=head2 C<address()>

This method returns the address of the home easy device that sent the
message.

=head2 C<unit()>

This method returns the unit of the home easy device that sent the
message.  It will be a number or the string 'group'.

=head2 C<command()>

This method returns the command from the home easy message.

=head2 C<level()>

This method returns the level from the home easy message.  This
is only defined for some types of preset/bright/dim messages.

=head2 C<summary()>

This method returns a string summary of the home easy message.

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
