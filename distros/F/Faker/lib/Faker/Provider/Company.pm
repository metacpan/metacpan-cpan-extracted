# ABSTRACT: Faker Standard Company Provider
package Faker::Provider::Company;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method name () {
    return $self->process(random => 'name');
}

method name_suffix () {
    return $self->process(random => 'name_suffix');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Company - Faker Standard Company Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::Company;

    my $faker = Faker->new;
    my $company = Faker::Provider::Company->new(factory => $faker);

    say $company->name;

=head1 DESCRIPTION

Faker::Provider::Company is a L<Faker> provider which provides fake company
data. B<Note: This is an early release available for testing and feedback and as
such is subject to change.>

=head1 METHODS

=head2 name

    $company->name;

    # Padberg Co.
    # Russel Ltd.
    # Murazik Co.

The name method generates a random ficticious company name.

=head2 name_suffix

    $company->name_suffix;

    # Ltd.
    # Inc.
    # Co.

The name_suffix method generates a random ficticious company name suffix.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
