package Flickr::API::Cameras;

use strict;
use warnings;
use Carp;

use parent qw( Flickr::API );
our $VERSION = '1.28';

sub _initialize {

    my $self = shift;
    $self->_set_status(1,'API::Cameras initialized');
    return;

}

sub brands_list {

    my $self    = shift;
    my $rsp     = $self->execute_method('flickr.cameras.getBrands');
    my $listref = ();

    $rsp->_propagate_status($self->{flickr}->{status});

    if ($rsp->success() == 1) {

        foreach my $cam (@{$rsp->as_hash()->{brands}->{brand}}) {

            push (@{$listref},$cam->{name});

        }

        $self->_set_status(1,"flickr.camera.getBrands returned " . $#{$listref}  . " brands.");

    }
    else {


        $self->_set_status(0,"Flickr::API::Cameras Methods list/hash failed with response error");

        carp "Flickr::API::Cameras Methods list/hash failed with response error: ",$rsp->error_code()," \n ",
            $rsp->error_message(),"\n";

    }
    return $listref;
}




sub brands_hash {

    my $self      = shift;
    my $arrayref  = $self->brands_list();
    my $hashref;


    if ($arrayref) {

        %{$hashref} = map {$_ => 1} @{$arrayref};

    }
    else {

        $hashref = {};

    }
    return $hashref;
}

sub get_cameras {

    my $self   = shift;
    my $brand  = shift;
    my $rsp    = $self->execute_method('flickr.cameras.getBrandModels',
                                    {'brand' => $brand});
    my $hash = $rsp->as_hash();
    my $AoH  = {};
    my $desc = {};

    my $cam;

    $rsp->_propagate_status($self->{flickr}->{status});

    if ($rsp->success() == 1) {

        $AoH = $hash->{cameras}->{camera};

        foreach $cam (@{$AoH}) {

            $desc->{$brand}->{$cam->{id}}->{name}    = $cam->{name};
            $desc->{$brand}->{$cam->{id}}->{details} = $cam->{details};
            $desc->{$brand}->{$cam->{id}}->{images}  = $cam->{images};

        }

        $self->_set_status(1,"flickr.camera.getBrandModels returned " . $#{$AoH}  . " models.");

    }
    else {


        $self->_set_status(0,"Flickr::API::Cameras get_cameras failed with response error");

        carp "Flickr::API::Cameras get_cameras method failed with error code: ",$rsp->error_code()," \n ",
            $rsp->error_message(),"\n";


    }

    return $desc;
}


1;

__END__


=head1 NAME

Flickr::API::Cameras - An interface to the flickr.cameras.* methods.

=head1 SYNOPSIS

  use Flickr::API::Cameras;

  my $api = Flickr::API::Cameras->new({'consumer_key' => 'your_api_key'});

or

  my $api = Flickr::API::Cameras->import_storable_config($config_file);

  my @brands = $api->brands_list();
  my %brands = $api->brands_hash();

  my $cameras = $api->get_cameras($brands[1]);


=head1 DESCRIPTION

This object encapsulates the flickr cameras methods.

C<Flickr::API::Cameras> is a subclass of L<Flickr::API>, so you can access
Flickr's camera information easily.


=head1 SUBROUTINES/METHODS

=over

=item C<brands_list>

Returns an array of camera brands from Flickr's API.

=item C<brands_hash>

Returns a hash of camera brands from Flickr's API.


=item C<get_cameras>

Returns a hash reference to the descriptions of the cameras
for a particular brand.

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015, Louis B. Moore

This program is released under the Artistic License 2.0 by The Perl Foundation.

=head1 SEE ALSO

L<Flickr::API>.
L<Flickr|http://www.flickr.com/>,
L<http://www.flickr.com/services/api/>
L<https://github.com/iamcal/perl-Flickr-API>


=cut
