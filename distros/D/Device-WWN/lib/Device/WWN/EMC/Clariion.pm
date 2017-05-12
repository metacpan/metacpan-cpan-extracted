package Device::WWN::EMC::Clariion;
use strict; use warnings;
our $VERSION = '1.01';
use Moose;
extends 'Device::WWN';
#use Carp::Clan qw{ ^Device::WWN($|::) croak };

sub accept_wwn {
    my ( $self, $wwn ) = @_;
    return $wwn =~ /^5006016/;
}

has 'port' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
sub _build_port {
    my $self = shift;
    my $id = hex substr( $self->vendor_id, 0, 1 );
    if ( $id >= 0 && $id <= 7 ) {
        return sprintf( 'SPA%x', $id );
    } elsif ( $id >= 8 && $id <= 15 ) {
        return sprintf( 'SPB%x', $id - 8 );
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Device::WWN::EMC::Clariion - Device::WWN subclass for EMC CLARiiON WWNs

=head1 SYNOPSIS

    use Device::WWN;
    my $wwn = Device::WWN->new( TODO );
    TODO

=head1 DESCRIPTION

This module is a subclass of L<Device::WWN|Device::WWN> which provides
additional information about EMC CLARiiON World Wide Names.

See L<Device::WWN|Device::WWN> for more information.

Note that there doesn't appear to be a way to extract a Clariion serial number
from it's WWN, all you can get is the port information.

=head1 METHODS

=head2 accept_wwn( $wwn )

This is called as a class method by L<Device::WWN> and returns a true value
if the WWN provided can be handled by this subclass.

=head2 port

Returns the port the WWN belongs to.

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/device-wwn>.  This is where you can
always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Device::WWN|Device::WWN>

L<http://www.jasonkohles.com/software/device-wwn>

=head1 AUTHOR

Jason Kohles C<< <email@jasonkohles.com> >>

L<http://www.jasonkohles.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008, 2009 Jason Kohles

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

