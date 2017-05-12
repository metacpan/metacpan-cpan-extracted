package GBPVR::CDBI::Channel;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'GBPVR::CDBI';

__PACKAGE__->table('channel');
__PACKAGE__->columns(Primary => qw/oid/ );
__PACKAGE__->columns(All => qw/ oid name channelID channel_number favourite / );

sub favorite {
  my $self = shift;
  return $self->favourite( @_ );
}

1;
__END__

=head1 NAME

GBPVR::CDBI::Channel - GBPVR.channel table

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

=head1 ATTRIBUTES

oid, name, channelID, channel_number, favourite

=head1 METHODS

=head2 favorite

Alias for favourite

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

