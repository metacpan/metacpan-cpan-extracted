# ABSTRACT: Faker Standard Internet Provider
package Faker::Provider::Internet;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method domain_name () {
    return join '.', $self->domain_word, $self->root_domain;
}

method domain_word () {
    my $factory = $self->factory;
    my $company = $factory->provider('Company');
    my $string  = lc $company->name;

    $string =~ s/\W+/-/g;
    $string =~ s/^\W+|\W+$//g;

    return $string;
}

method email_address () {
    return lc $self->process(random => 'email');

}

method email_domain () {
    return lc $self->process(random => 'email_domain');
}

method ip_address () {
    return $self->ip_address_v4;
}

method ip_address_v4 () {
    return join '.',
        $self->random_between(0, 255), $self->random_between(0, 255),
        $self->random_between(0, 255), $self->random_between(0, 255);
}

method ip_address_v6 () {
    return join ':',
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535))),
        sprintf('%04s', sprintf("%02x", $self->random_between(0, 65535)));
}

method root_domain () {
    return $self->process(random => 'root_domain');
}

method url () {
    return $self->process(random => 'url');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Internet - Faker Standard Internet Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::Internet;

    my $faker = Faker->new;
    my $internet = Faker::Provider::Internet->new(factory => $faker);

    say $internet->domain_name;

=head1 DESCRIPTION

Faker::Provider::Internet is a L<Faker> provider which provides fake Internet
data. B<Note: This is an early release available for testing and feedback and
as such is subject to change.>

=head1 METHODS

=head2 domain_name

    $internet->domain_name;

    # douglas-schaefer-and-heaney.biz
    # pouros-ltd.info
    # o-reilly-mertz-and-pagac.net

The domain_name method generates a random ficticious domain name.

=head2 domain_word

    $internet->domain_word;

    # fahey-kuphal
    # buckridge-o-hara-and-olson
    # renner-gottlieb-and-mills

The domain_word method generates a random ficticious domain word.

=head2 email_address

    $internet->email_address;

    # xpaucek@yahoo.com
    # ifarrell@hotmail.com
    # reichel.kristian@wolff-hand.biz

The email_address method generates a random ficticious email address.

=head2 email_domain

    $internet->email_domain;

    # gmail.com
    # hotmail.com
    # yahoo.com

The email_domain method generates a random ficticious email domain.

=head2 ip_address

    $internet->ip_address;

    # 127.139.44.27
    # 151.238.203.220
    # 217.2.93.202

The ip_address method generates a random ficticious ip address.

=head2 ip_address_v4

    $internet->ip_address_v4;

    # 164.211.250.223
    # 17.204.157.48
    # 44.168.220.190

The ip_address_v4 method generates a random ficticious ip address v4.

=head2 ip_address_v6

    $internet->ip_address_v6;

    # a3db:be38:1d95:c7d4:390f:c9d7:1169:0d37
    # de69:0f5f:7d53:a317:e406:d908:3ecd:250a
    # d8ca:978f:6aab:fd01:91ab:5046:bc9b:1f6e

The ip_address_v6 method generates a random ficticious ip address v6.

=head2 root_domain

    $internet->root_domain;

    # info
    # info
    # org

The root_domain method generates a random ficticious root domain.

=head2 url

    $internet->url;

    # http://raynor-volkman-and-upton.org/
    # http://www.crona-ledner-and-parisian.net/
    # https://stracke-pty.org/

The url method generates a random ficticious url.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
