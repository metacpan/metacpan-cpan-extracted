use strict;
use warnings;
package MetaCPAN::Client::Package;
# ABSTRACT: A package data object (02packages.details entry)
$MetaCPAN::Client::Package::VERSION = '2.028000';
use Moo;

with 'MetaCPAN::Client::Role::Entity';

my %known_fields = (
    scalar   => [qw< author distribution dist_version file module_name version >],
    arrayref => [qw<>],
    hashref  => [],
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

MetaCPAN::Client::Package - A package data object (02packages.details entry)

=head1 VERSION

version 2.028000

=head1 SYNOPSIS

    my $package = $mcpan->package('MooseX::Types');

=head1 DESCRIPTION

A MetaCPAN package (02packages.details) entity object.

=head1 ATTRIBUTES

=head2 module_name

Returns the name of the module.

=head2 file

The file path in CPAN for the module (latest release)

=head2 distribution

The distribution in which the module exist

=head2 version

The (latest) version of the module

=head2 dist_version

The (latest) version of the distribution

=head2 author

The pauseid of the release author

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
