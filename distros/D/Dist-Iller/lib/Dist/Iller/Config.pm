use 5.10.0;
use strict;
use warnings;

package Dist::Iller::Config;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Role for Dist::Iller configs
our $VERSION = '0.1409';

use Moose::Role;
use MooseX::AttributeShortcuts;
use namespace::autoclean;
use Module::Load qw/load/;
use Types::Standard qw/Bool Str Maybe InstanceOf/;
use YAML::Tiny;
use Path::Tiny;
use Try::Tiny;
use Carp qw/croak/;
use File::ShareDir 'dist_dir';
use String::CamelCase qw/camelize/;

requires qw/filepath/;

has main_module => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    traits => ['Documented'],
    default => sub { shift->meta->name },
    documentation => q{Override this attribute when there's more than one config in a distribution. It uses the main_module's sharedir location for the config files.},
    documentation_default => 'The package name',
);
has distribution_name => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    predicate => 1,
    default => sub { undef },
    traits => ['Documented'],
    documentation_order => 0,
);
has global => (
    is => 'ro',
    isa => Maybe[InstanceOf['Dist::Iller::DocType::Global']],
);


sub config_location {
    my $self = shift;
    my $package = $self->main_module;
    $package =~ s{::}{-}g;

    my $dir = path('.');

    try {
        $dir = path(dist_dir($package));
    }
    finally { };

    return $dir->child($self->filepath);
}

sub get_yaml_for {
    my $self = shift;
    my $doctype = shift;

    my $fullyaml = YAML::Tiny->read($self->config_location->absolute->stringify);

    my $yaml = (grep { $_->{'doctype'} eq $doctype } @{ $fullyaml })[0];
    return if !defined $yaml;

    my $doctype_class = sprintf 'Dist::Iller::DocType::%s', camelize($yaml->{'doctype'});
    try {
        load $doctype_class;
    }
    catch {
        croak "Can't load $doctype_class: $_";
    };

    return $doctype_class->new(config_obj => $self)->parse($yaml)->to_yaml;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::Config - Role for Dist::Iller configs

=head1 VERSION

Version 0.1409, released 2020-12-27.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
