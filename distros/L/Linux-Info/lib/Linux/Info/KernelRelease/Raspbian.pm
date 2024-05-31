package Linux::Info::KernelRelease::Raspbian;

use warnings;
use strict;
use parent 'Linux::Info::KernelRelease';
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_binutils_version => 'binutils_version',
    get_build_number     => 'build_number',
};

our $VERSION = '2.16'; # VERSION

# ABSTRACT: a subclass of Linux::Info::KernelRelease specific to parse Alpine kernel information

sub _set_proc_ver_regex {
    my $self = shift;
    $self->{proc_regex} =
qr/^Linux\sversion\s(?<version>\d+\.\d+\.\d+\+?)\s\((?<compiled_by>[\w\.\-\@]+)\)\s\(arm-linux-\w+-gcc-\d+\s\(.*\)\s(?<gcc_version>\d+\.\d+\.\d+),\sGNU\sld\s\(.*\)\s(?<binutils_version>\d+\.\d+)\)\s\#(?<build_number>\d+)\s(?<build_datetime>.*)/;
}


sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{type} = undef;
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::KernelRelease::Raspbian - a subclass of Linux::Info::KernelRelease specific to parse Alpine kernel information

=head1 VERSION

version 2.16

=head1 METHODS

=head2 new

Extends parent method to further parse the kernel version string to fetch
additional information.

=head2 get_binutils_version

Returns the binutils package version used to compile the kernel.

=head2 get_build_number

Returns the number of the building this kernel was created.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
