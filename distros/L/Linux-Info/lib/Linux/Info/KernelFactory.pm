package Linux::Info::KernelFactory;

use warnings;
use strict;
use Carp qw(confess);
use Linux::Info::DistributionFactory;
use Linux::Info::KernelRelease;
use Linux::Info::KernelRelease::RedHat;
use Linux::Info::KernelRelease::Rocky;
use Linux::Info::KernelRelease::Ubuntu;

our $VERSION = '2.18'; # VERSION

# ABSTRACT: Factory class to create instances of Linux::Info::KernelRelease and subclasses


sub create {
    my $distro_name = Linux::Info::DistributionFactory->new->distro_name;
    my %map         = (
        redhat   => 'RedHat',
        rocky    => 'Rocky',
        ubuntu   => 'Ubuntu',
        alpine   => 'Alpine',
        raspbian => 'Raspbian',
    );

    if ( exists $map{$distro_name} ) {
        my $distro_class = 'Linux::Info::KernelRelease::' . $map{$distro_name};
        return $distro_class->new;
    }

    return Linux::Info::KernelRelease->new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::KernelFactory - Factory class to create instances of Linux::Info::KernelRelease and subclasses

=head1 VERSION

version 2.18

=head1 SYNOPSIS

    use Linux::Info::KernelFactory;
    my $release = Linux::Info::KernelFactory->create;

=head1 METHODS

=head2 create

Creates a instance of L<Linux::Info::KernelRelease> or any of it's subclasses.

The returned instance will be related to the Linux distribution where the
factory is executing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
