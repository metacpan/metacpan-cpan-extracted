package Finance::Card::Discover::Account::Profile;

use strict;
use warnings;

use Object::Tiny qw(
    account prefix_name first_name middle_name last_name suffix_name email
    phone city country zipcode state street_line1 street_line2 street_line3
);

sub new {
    my ($class, $data, %params) = @_;

    return bless {
        account  => $params{account},
        map(
            {( "${_}_name" => $data->{"${_}name"} )}
            qw(prefix first middle last suffix)
        ),
        email   => $data->{email},
        phone   => $data->{phonenumber},
        city    => $data->{city},
        country => $data->{country},
        zipcode => $data->{postcode},
        state   => $data->{stateprovince},
        map({( "street_line$_" => $data->{"streetline$_"} )} (1 .. 3)),
    }, $class;
}


1;

__END__

=head1 NAME

Finance::Card::Discover::Account::Profile

=head1 DESCRIPTION

This module provides a class representing an account profile.

=head1 ACCESSORS

=over

=item * account

The associated L<Finance::Card::Discover::Account> object.

=item * prefix_name

=item * first_name

=item * middle_name

=item * last_name

=item * suffix_name

Name components.

=item * email

=item * phone

=item * street_line1

=item * street_line2

=item * street_line3

=item * city

=item * state

=item * zipcode

=item * country

Contact information.

=back

=cut
