use strict;
use warnings;
package MetaCPAN::Client::Mirror;
# ABSTRACT: A Mirror data object
$MetaCPAN::Client::Mirror::VERSION = '2.028000';
use Moo;
use Carp;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar => [qw<
        aka_name
        A_or_CNAME
        ccode
        city
        continent
        country
        dnsrr
        freq
        ftp
        http
        inceptdate
        name
        note
        org
        region
        reitredate
        rsync
        src
        tz
    >],

    arrayref => [qw< contact location >],

    hashref  => [qw<>],
);

my @known_fields =
    map { @{ $known_fields{$_} } } qw< scalar arrayref hashref >;

foreach my $field (@known_fields) {
    has $field => (
        is      => 'ro',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->data->{$field};
        },
    );
}

sub _known_fields { return \%known_fields }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::Mirror - A Mirror data object

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $mirror = $mcpan->mirror('eutelia.it');

=head1 DESCRIPTION

A MetaCPAN mirror entity object.

=head1 ATTRIBUTES

=head2 name

The name of the mirror, which is what you passed

=head2 org

The organization that maintains the mirror.

=head2 ftp

An FTP url for the mirror.

=head2 rsync

An rsync url for the mirror.

=head2 src

=head2 city

The city where the mirror is located.

=head2 country

The name of the country where the mirror is located.

=head2 ccode

The ISO country code for the mirror's country.

=head2 aka_name

=head2 tz

=head2 note

=head2 dnsrr

=head2 region

=head2 inceptdate

=head2 freq

=head2 continent

=head2 http

=head2 reitredate

=head2 A_or_CNAME

=head2 contact

Array-Ref.

=head2 location

Array-Ref.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
