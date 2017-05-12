# ABSTRACT: Faker Standard Person Provider
package Faker::Provider::Person;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method name () {
    return $self->process(random => 'name');
}

method first_name () {
    return $self->process(random => 'first_name');
}

method last_name () {
    return $self->process(random => 'last_name');
}

method username () {
    return $self->process(random => 'username', all_markers => 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Person - Faker Standard Person Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::Person;

    my $faker = Faker->new;
    my $person = Faker::Provider::Person->new(factory => $faker);

    say $person->name;

=head1 DESCRIPTION

Faker::Provider::Person is a L<Faker> provider which provides fake data for a
person. B<Note: This is an early release available for testing and feedback and
as such is subject to change.>

=head1 METHODS

=head2 name

    $person->name;

    # John Doe
    # Jane Doe

The name method generates a random ficticious name for a person.

=head2 first_name

    $person->first_name;

    # John
    # Jane

The first_name method generates a random ficticious first name for a person.

=head2 last_name

    $person->last_name;

    # Doe
    # Smith

The last_name method generates a random ficticious last name for a person.

=head2 username

    $person->username;

    # gDoe
    # John.Doe
    # Doe.John

The username method generates a random ficticious username.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
