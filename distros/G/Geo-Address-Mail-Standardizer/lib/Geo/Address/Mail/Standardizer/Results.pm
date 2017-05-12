package Geo::Address::Mail::Standardizer::Results;
use Moose;

has 'changed' => (
    is  => 'rw',
    isa => 'HashRef',
    traits => [ 'Hash' ],
    default => sub { {} },
    handles => {
        changed_count => 'count',
        changed_fields => 'keys',
        get_changed => 'get',
        is_changed => 'exists',
        set_changed => 'set',
    }
);

has 'standardized_address' => (
    is => 'rw',
    isa => 'Geo::Address::Mail',
    predicate => 'has_standardized_address'
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Geo::Address::Mail::Standardizer::Results - Results of address standardization

=head1 SYNOPSIS

    package Geo::Address::Mail::Standardizer::My;
    use Moose;

    with 'Geo::Address::Mail::Standardizer';

    # use it

    my $std = Geo::Address::Mail::Standardizer::My->new(...);
    my $address = Geo::Address::Mail::MyCountry;
    my $results = $std->standardize($address);

    $results->is_changed('state');
    my @changes = $results->changed_fields;

=head1 ATTRIBUTES

=head2 changed

HashRef of changed fields.  The keys are the names of the fields and the
values are the new values of those fields.

=head2 standardized_address

A L<Geo::Address::Mail> object (specifically of the subclass you passed in)
that has been standardized.

=head1 METHODS

=head2 changed_count

Returns a count of the number of fields changed during standardization.

=head2 changed_fields

Returns an array of field names that were changed as part of the standardization.

=head2 get_changed($name)

Returns the value of the specified field if it was changed.

=head2 has_standardized_address

Returns true if a standardized address has been set for this results.

=head2 is_changed($name)

Returns true if the specifid field name was changed, otherwise false.

=head2 set_changed($name, $value)

Records that the specified field was changed to the specified value.  Used
by Standardizer implementations to set values.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
