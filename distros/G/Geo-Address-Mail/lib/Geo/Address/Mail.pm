package Geo::Address::Mail;
use warnings;
use strict;
use Moose;

use Class::MOP;
use MooseX::Storage;

with qw(MooseX::Storage::Deferred);
with qw(MooseX::Clone);

our $VERSION = '0.04';

=head1 NAME

Geo::Address::Mail - A Mailing Address on Earth

=head1 SYNOPSIS

Geo::Address::Mail provides a generic object representation of a mailing
address that may be subclassed to provide more specific typing of attributes.
The core class, Geo::Address::Mail provides common, loosely typed attributes
and methods.

    use Geo::Address::Mail::US;

    my $add = Geo::Address::Mail::US->new(
        name => 'Cory G Watson',
        street => '123 Main St',
        city => 'Testville',
        postal_code => '12345'
    );

=head1 SUBCLASSING

The real reason for Geo::Address::Mail is to provide a common class that can
be used to build mailing address objects for other countries.

Subclasses are expected additional type refinement and attributes.
For example, L<Geo::Address::Mail::US> uses a more specific type for
validation USPS ZIP codes and adds a C<street2> attribute for an optional
additional line of addressing.

=head2 SUBCLASS NAMING

Subclasses should be named with C<Geo::Address::Mail> and the two-letter
ISO-3166 country codes.

=head1 ADDITIONAL USES

Using a common address object enables a family of distributions that provide
interesting address functionality such as L<Geo::Address::Mail::Standardizer>.

=head1 ATTRIBUTES

=head2 city

The city/town/village/municipality in which this address resides.

=cut

has 'city' => (
    is => 'rw',
    isa => 'Str'
);

=head2 company

The name of the company that is to receive the mail piece.

=cut

has 'company' => (
    is => 'rw',
    isa => 'Str'
);

=head2 country

The country in which this address resides.  This is likely not necessary
unless the address is in a different country.

=cut

has 'country' => (
    is => 'rw',
    isa => 'Str'
);

=head2 name

The name of the person that is to receive the mail piece.

=cut

has 'name' => (
    is => 'rw',
    isa => 'Str'
);

=head2 postal_code

The postal code of the address.  Called the ZIP code in the US.

=cut

has 'postal_code' => (
    is => 'rw',
    isa => 'Str',
);

=head2 street

The number and name of the street that is to receive the mail piece.

  2020 Main St

=cut

has 'street' => (
    is => 'rw',
    isa => 'Str'
);

=head1 METHODS

=head2 clone(%prams)

Close this Geo::Address::Mail instance, replacing any of the attributes
specified in the new instance.

=cut

=head2 new_for_country ($code, ...)

Attempts to load and instantiate a subclass of Geo::Address::Mail based on the
provided two-letter code (upper or lower case).  Any remaining arguments are
passed to the constructor of the specified class.  B<Note:> you will have to
have the class for the specified country accessible.

  # Instantiate a US address
  my $usaddr = Geo::Address::Mail->new_for_country('US', { ... });

=cut

sub new_for_country {
    my $self = shift;
    my $code = shift;

    # Upper-case it, just in case
    $code = uc($code);

    my $class = 'Geo::Address::Mail::'. $code;
    Class::MOP::load_class($class);
    return $class->new(@_);
}

=head2 standardize ($partial_name_of_standardizer_class, ...)

Shortcut to use a L<Geo::Address::Mail::Standardizer>.  You can provide
either the partial name (the bits B<after> Standardizer, e.g. 'USPS::AMS' for
L<Geo::Address::Mail::Standardizer::USPS::AMS>) or a full class name (prefixed
with a +, e.g. '+My::Standardizer').  Returns whatever is returned by the
C<standardize> method of the requested Standardizer implementation.

B<Note:> Any argument passed after the name of the class will be passed on
to the constructer of the loaded standardizer.

=cut

sub standardize {
    my $self = shift;
    my $std = shift;

    my $stdclass = $std;
    if($std =~ /^\+/) {
        $stdclass =~ s/^\+//g;
    } else {
        $stdclass = 'Geo::Address::Mail::Standardizer::'.$stdclass;
    }

    Class::MOP::load_class($stdclass);
    my $instance = $stdclass->new(@_);
    return $instance->standardize($self);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

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
