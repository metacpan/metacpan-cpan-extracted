package Math::Geometry::Construction::Role::Input;
use Moose::Role;

use 5.008008;

use Carp;
use Math::Vector::Real;

=head1 NAME

C<Math::Geometry::Construction::Role::Input> - format conversions

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


# This method is also used during construction time, so $self might
# just be a class name.
sub import_point {
    my ($self, $construction, $value) = @_;

    croak "Invalid construction object."
	if(!eval { $construction->isa('Math::Geometry::Construction') });

    return undef if(!defined($value));
    return $value
	if(eval { $value->isa('Math::Geometry::Construction::Point') });
    return $construction->add_point(position => $value, hidden => 1);
}

1;


__END__

=pod

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Methods


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

