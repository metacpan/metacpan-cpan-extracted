package Flickr::Tools::Cameras;

use Flickr::API::Cameras;
use Types::Standard qw ( InstanceOf );
use Carp;
use Moo;
use strictures;
use namespace::clean;
use 5.010;

with qw(Flickr::Roles::Caching);

our $VERSION = '1.22';

extends 'Flickr::Tools';

has '+_api_name' => (
    is       => 'ro',
    isa      => sub { $_[0] eq 'Flickr::API::Cameras' },
    required => 1,
    default  => 'Flickr::API::Cameras',
);

sub getBrands {
    my ( $self, $args ) = @_;
    my $brands;
    my $pre_expire = 0;

    $self->_set_cache_hit(1);

    if ( defined( $args->{clear_cache} ) and $args->{clear_cache} ) {
        $pre_expire = 1;
    }

    if ( defined( $args->{list_type} ) and $args->{list_type} =~ m/list/i ) {

        $self->_set_cache_key('brands_list');

        $brands = $self->_cache->get( $self->cache_key,
            expire_if => sub { $pre_expire } );
        if ( !defined $brands ) {
            $brands = $self->{_api}->brands_list;
            $self->_set_cache_hit(0);
            $self->_cache->set( $self->cache_key, $brands,
                $self->cache_duration );
        }
    }
    else {

        $self->_set_cache_key('brands_hash');

        $brands = $self->_cache->get( $self->cache_key,
            expire_if => sub { $pre_expire } );
        if ( !defined $brands ) {
            $brands = $self->{_api}->brands_hash;
            $self->_set_cache_hit(0);
            $self->_cache->set( $self->cache_key, $brands,
                $self->cache_duration );
        }
    }
    return $brands;
}

sub getBrandModels {
    my ( $self, $args ) = @_;
    my $models     = {};
    my $pre_expire = 0;

    $self->_set_cache_hit(1);

    if ( defined( $args->{clear_cache} ) and $args->{clear_cache} ) {
        $pre_expire = 1;
    }

    if ( exists( $args->{Brand} ) ) {

        $self->_set_cache_key( 'Models ' . $args->{Brand} );

        $models = $self->_cache->get( $self->cache_key,
            expire_if => sub { $pre_expire } );
        if ( !defined $models ) {
            $models = $self->{_api}->get_cameras( $args->{Brand} );
            $self->_set_cache_hit(0);
            $self->_cache->set( $self->cache_key, $models,
                $self->cache_duration );
        }
    }
    else {

        carp
"\nCannot return models unless a required argument: Brand is passed in\n";

    }

    return $models;

}

1;

__END__

=head1 NAME

Flickr::Tools::Cameras - Perl interface to the Flickr::API for cameras

=head1 VERSION

CPAN:        1.22

Development: 1.22_01


=head1 SYNOPSIS

 use strict;
 use warnings;
 use Flickr::Tools::Cameras;
 use 5.010;

 my $config = "~/my_config.st";  # config in Storable format from L<Flickr::API>

 my $camera_tool = Flickr::Tools::Cameras->new({config_file => $config});

 my $arrayref = $camera_tool->getBrands({list_type => 'List'});
 my $hashref  = $camera_tool->getBrands;  #hashref is the default

 if (exists($hashref->{mybrand}) {

    $camera_tool->getBrandModels({Brand => 'mybrand'});

 }

 if ($tool->cache_hit) {

    say "got brandModels from cache";

  }

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS


=over

=item C<getBrands>

=item C<getBrandModels>


=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None known of, yet.

=head1 BUGS AND LIMITATIONS

Yes

=head1 AUTHOR

Louis B. Moore <lbmoore@cpan.org>

=head1 LICENSE AND COPYRIGHT


Copyright (C) 2015 Louis B. Moore <lbmoore@cpan.org>


This program is released under the Artistic License 2.0 by The Perl Foundation.
L<http://www.perlfoundation.org/artistic_license_2_0>


=cut
