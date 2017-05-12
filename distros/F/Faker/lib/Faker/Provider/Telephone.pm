# ABSTRACT: Faker Standard Telephone Number Provider
package Faker::Provider::Telephone;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method number () {
    return $self->process(random => 'number', all_markers => 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Telephone - Faker Standard Telephone Number Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::PhoneNumber;

    my $faker = Faker->new;
    my $phone = Faker::Provider::Telephone->new(factory => $faker);

    say $phone->number;

=head1 DESCRIPTION

Faker::Provider::Telephone is a L<Faker> provider which provides fake phone data.
B<Note: This is an early release available for testing and feedback and as such
is subject to change.>

=head1 METHODS

=head2 number

    $phone->number;

    # (882) 119-2218
    # (131) 225-5649
    # 378 916 6044

The number method generates a random ficticious telephone number.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
