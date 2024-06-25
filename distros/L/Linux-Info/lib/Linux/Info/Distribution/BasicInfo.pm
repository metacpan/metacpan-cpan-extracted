package Linux::Info::Distribution::BasicInfo;

use warnings;
use strict;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_distro_id => 'distro_id',
    get_file_path => 'file_path',
};

our $VERSION = '2.18'; # VERSION

# ABSTRACT: simple class to exchange data between DistributionFinder and DistributionFactory classes


sub new {
    my ( $class, $distro_id, $file_path ) = @_;

    confess 'Must receive the Linux distribution ID as parameter'
      unless ( defined $distro_id );
    confess 'Must receive the file path as parameter'
      unless ( defined $file_path );

    my $self = {
        distro_id => $distro_id,
        file_path => $file_path,
    };
    bless $self, $class;
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::BasicInfo - simple class to exchange data between DistributionFinder and DistributionFactory classes

=head1 VERSION

version 2.18

=head1 METHODS

=head2 new

=head2 get_distro_id

Returns the respective Linux distribution ID (an string in lower case).

=head2 get_file_path

Returns the complete path to the file where the Linux distribution information
is stored.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
