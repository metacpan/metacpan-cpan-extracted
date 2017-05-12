package Geo::Address::Mail::US;
use warnings;
use strict;
use Moose;
use MooseX::Storage;
with qw(MooseX::Storage::Deferred);

use Moose::Util::TypeConstraints;
use Regexp::Common qw(zip);

extends 'Geo::Address::Mail';

subtype 'Geo::Address::Mail::USPostalCode',
    => as 'Str',
    => where { $_ =~ /^$RE{zip}{US}$/ };

has '+postal_code' => (
    isa => 'Geo::Address::Mail::USPostalCode'
);

has 'street2' => (
    is => 'rw',
    isa => 'Str'
);

has 'state' => (
    is => 'rw',
    isa => 'Str'
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

Geo::Address::Mail::US - A Mailing Address in the United States

=head1 SYNOPSIS

Geo::Address::Mail::US is a subclass of L<Geo::Address::Mail> that provides
specific validation and attributes for mailing addresses located in the United
States.

    use Geo::Address::Mail::US;

    my $add = Geo::Address::Mail::US->new(
        name => 'Cory G Watson',
        street => '123 Main St',
        street2 => 'Apt 3B',
        city => 'Testville',
        postal_code => '12345'
    );

=head1 ATTRIBUTES

Geo::Address::Mail::US has all the attributes of L<Geo::Address::Mail>.  The
following attributes are either modified or new.

=head2 postal_code

Postal codes are validated to conform to the USPS ZIP (and optional +4)
standard.

=head2 street2

Addresses in the United States often have an Apartment number, Suite number
or other sub-street unit.  This field provides for that.

=head2 state

The state for this address. Added in US as not all countries have the
concept of a state.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
