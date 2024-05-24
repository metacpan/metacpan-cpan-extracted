package Linux::Info::DistributionFactory;

use warnings;
use strict;
use Hash::Util qw(lock_hash lock_keys);
use Carp       qw(confess);
use Data::Dumper;

use Linux::Info::DistributionFinder;

use Linux::Info::Distribution::Custom::Amazon;
use Linux::Info::Distribution::Custom::CentOS;
use Linux::Info::Distribution::Custom::CloudLinux;
use Linux::Info::Distribution::Custom::RedHat;

use Linux::Info::Distribution::OSRelease::Alpine;
use Linux::Info::Distribution::OSRelease::Amazon;
use Linux::Info::Distribution::OSRelease::CentOS;
use Linux::Info::Distribution::OSRelease::Debian;
use Linux::Info::Distribution::OSRelease::RedHat;
use Linux::Info::Distribution::OSRelease::Rocky;
use Linux::Info::Distribution::OSRelease::Ubuntu;

our $VERSION = '2.12'; # VERSION

# ABSTRACT: implements a factory for Distribution subclasses


my %os_release_distros = (
    rocky      => 'Rocky',
    ubuntu     => 'Ubuntu',
    redhat     => 'RedHat',
    rhel       => 'RedHat',
    amazon     => 'Amazon',
    amzn       => 'Amazon',
    CloudLinux => 'CloudLinux',
    centos     => 'CentOS',
    alpine     => 'Alpine',
);
lock_hash(%os_release_distros);


sub new {
    my ( $class, $finder ) = @_;
    my $finder_class = 'Linux::Info::DistributionFinder';

    if ( defined($finder) ) {
        confess "You must pass a instance of $finder_class"
          unless ( ( ref $finder ne '' ) and ( $finder->isa($finder_class) ) );
    }
    else {
        $finder = $finder_class->new;
    }

    my $self = { finder => $finder, };
    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}


sub distro_name {
    return shift->create->get_name;
}


sub create {
    my $self      = shift;
    my $info      = $self->{finder}->search_distro;
    my $distro_id = $info->get_distro_id;

    unless ( $self->{finder}->has_custom ) {
        my $base_class = 'Linux::Info::Distribution::OSRelease';

        if ( exists $os_release_distros{$distro_id} ) {
            my $class = $base_class . '::' . $os_release_distros{$distro_id};
            return $class->new( $info->get_file_path );
        }
        else {
            return $base_class->new( $info->get_file_path );
        }
    }

    my $distro_name;

    if ( exists $os_release_distros{$distro_id} ) {
        $distro_name = $os_release_distros{$distro_id};
    }
    else {
        confess( 'Do not know how to handle the id ' . $distro_id );
    }

    my $class = "Linux::Info::Distribution::Custom::$distro_name";
    return $class->new($info);

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::DistributionFactory - implements a factory for Distribution subclasses

=head1 VERSION

version 2.12

=head1 SYNOPSIS

    use Linux::Info::DistributionFactory;
    use Linux::Info::DistributionFinder;

    my $instance = Linux::Info::DistributionFactory->new(
        Linux::Info::DistributionFinder->new
    );
    print $instance->distro_name, "\n";

=head1 DESCRIPTION

This class implements the design pattern of Factory to handle how to create all
existing variations of subclass of L<Linux::Info::Distribution> subclasses.

=head1 METHODS

=head2 new

Creates and return a new instance.

Expects a instance of L<Linux::Info::DistributionFinder> as a parameter.

=head2 distro_name

Returns the current Linux distribution name from where the Factory was created.

=head2 create

Creates and return a instance of L<Linux::Info::Distribution> subclasses, based
on the several criterias to define the source and format of the data.

Instances will be returned based on subclasses of
L<Linux::Info::Distribution::OSRelease> or
L<Linux::Info::Distribution::Custom>.

The first attempt is to use the file F</etc/os-release> to fetch information.
In this case, if a subclass of L<Linux::INfo::Distribution::OSRelease> is not
available, this class will be used instead, which means less attributes will
be available.

If the file is not available, others will be attempted.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
