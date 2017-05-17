package Dist::Zooky::Role::Core;
$Dist::Zooky::Role::Core::VERSION = '0.24';
# ABSTRACT: role for core plugins

use strict;
use warnings;
use Params::Check qw[check];
use Moose::Role;

requires '_build_metadata';

has 'metadata' => (
  is => 'ro',
  isa => 'HashRef',
  init_arg => undef,
  lazy => 1,
  builder => '_build_metadata',
);

sub _version_to_number {
    my $self = shift;
    my %hash = @_;

    my $version;
    my $tmpl = {
        version => { default => '0.0', store => \$version },
    };

    check( $tmpl, \%hash ) or return;

    return $version if $version =~ /^\.?\d/;
    return '0.0';
}

sub _vcmp {
    my $self = shift;
    my ($x, $y) = @_;

    s/_//g foreach $x, $y;

    return $x <=> $y;
}

no Moose::Role;

qq[And Dist::Zooky too!];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Role::Core - role for core plugins

=head1 VERSION

version 0.24

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
