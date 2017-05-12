# ABSTRACT: Faker Localized en_US Company Provider
package Faker::Provider::en_US::Company;

use Faker::Base;

extends 'Faker::Provider::Company';

our $VERSION = '0.12'; # VERSION

method buzzword_type1 () {
    return $self->process(random => 'buzzword_type1');
}

method buzzword_type2 () {
    return $self->process(random => 'buzzword_type2');
}

method buzzword_type3 () {
    return $self->process(random => 'buzzword_type3');
}

method description () {
    my $does = $self->random_item([
        'Delivers',
        'Excels at',
        'Offering',
        'Best-in-class for'
    ]);

    return join ' ', $does,
        $self->jargon_prop_word,
        $self->jargon_buzz_word;
        $self->jargon_edge_word,
}

method jargon_buzz_word () {
    return $self->process(random => 'jargon_buzz');
}

method jargon_edge_word () {
    return $self->process(random => 'jargon_edge');
}

method jargon_prop_word () {
    return $self->process(random => 'jargon_prop');
}

method tagline () {
    return join ' ',
        $self->buzzword_type3,
        $self->buzzword_type2,
        $self->buzzword_type1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::en_US::Company - Faker Localized en_US Company Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::en_US::Company;

    my $faker = Faker->new(locale => 'en_US');
    my $company = Faker::Provider::en_US::Company->new(factory => $faker);

    say $company->tagline;

=head1 DESCRIPTION

Faker::Provider::en_US::Company is a L<Faker> provider localized under en_US,
which provides fake company data. Faker::Provider::en_US::Company inherits all
attributes and methods from L<Faker::Provider::Company> and implements the
following new ones. B<Note: This is an early release available for testing and
feedback and as such is subject to change.>

=head1 METHODS

=head2 buzzword_type1

    $address->buzzword_type1;

    # leverage
    # utilize
    # deliver

The buzzword_type1 method generates a random business-related verb, common in
the en_US locale.

=head2 buzzword_type2

    $address->buzzword_type2;

    # frictionless
    # back-end
    # next-generation

The buzzword_type2 method generates a random business-related adjective, common
in the en_US locale.

=head2 buzzword_type3

    $address->buzzword_type3;

    # architectures
    # applications
    # networks

The buzzword_type3 method generates a random business-related noun, common in
the en_US locale.

=head2 description

    $address->description;

    # Offering tangible Inverse adapter
    # Excels at clear-thinking Cross-group middleware
    # Offering transitional Advanced help-desk

The description method generates a random company description based on
buzzwords, common in the en_US locale.

=head2 jargon_buzz_word

    $address->jargon_buzz_word;

    # synergy
    # ability
    # focusgroup

The jargon_buzz_word method generates a random business-related buzzword, common
in the en_US locale.

=head2 jargon_edge_word

    $address->jargon_edge_word;

    # Function-based
    # Triple-buffered
    # Future-proofed

The jargon_edge_word method generates a random business-related marketing
jargon, common in the en_US locale.

=head2 jargon_prop_word

    $address->jargon_prop_word;

    # explicit
    # 3rdgeneration
    # mobile

The jargon_prop_word method generates random business-related proposition,
common in the en_US locale.

=head2 tagline

    $address->tagline;

    # e-tailers robust incubate
    # mindshare global transition
    # paradigms visionary e-enable

The tagline method generates a random ficticious nonsense business-related
tagline, common in the en_US locale.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
