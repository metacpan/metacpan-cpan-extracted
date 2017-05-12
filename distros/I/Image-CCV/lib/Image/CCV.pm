package Image::CCV;
use Exporter 'import';
require DynaLoader;
use Carp qw(croak);
use vars qw($VERSION @EXPORT @ISA);

$VERSION = '0.10'; 

@EXPORT = qw(sift detect_faces );

@ISA = qw(DynaLoader);

=head1 NAME

Image::CCV - Crazy-cool Computer Vision bindings for Perl

=head1 SYNOPSIS

    use Image::CCV qw(detect_faces);

    my $scene = "image-with-faces.png";

    my @coords = detect_faces( $scene );
    print "@$_\n" for @coords;

=head1 ALPHA WARNING

This code is very, very rough. It leaks memory left and right
and the API is very much in flux. But as I got easy results using
this code already, I am releasing it as is and will improve it and
the API as I go along.

See also L<http://libccv.org> for the C<libccv> website.

=cut

# TODO: Make ccv_array_t into a class, so automatic destruction works
# TODO: ccv_sift_param_t currently leaks. Add a DESTROY method.
# TODO: Turn C structs into Perl classes for memory management
#       BBF parameters: ccv_bbf_param_t

=head1 FUNCTIONS

=cut

=head2 C<< default_sift_params(%options) >>

Sets up the parameter block for C<< sift() >> and related routines. Valid
keys for C<%options> are:

=over 4

=item *

noctaves - number of octaves

=item *

nlevels - number of levels

=item *

up2x - boolean, whether to upscale

=item *

edge_threshold - edge threshold

=item *

norm_threshold - norm threshold

=item *

peak_threshold - peak threshold

=back

=cut

sub default_sift_params {
    my ($params) = @_;
    $params ||= {};

    my %default = (
	noctaves => 5,
	nlevels => 5,
	up2x => 1,
	edge_threshold => 5,
	norm_threshold => 0,
	peak_threshold => 0,
    );
    
    for (keys %default) {
    	if(! exists $params->{ $_ }) {
            $params->{ $_ } = $default{ $_ }
    	};
    };
    
    if( ref $params ne 'ccv_sift_param_tPtr') {
    	$params = myccv_pack_parameters(
    	    @{$params}{qw<
    	        noctaves
    	        nlevels
    	        up2x
    	        edge_threshold
    	        norm_threshold
    	        peak_threshold
    	    >}
    	);
    };
    
    $params
};

=head2 C<< get_sift_descriptor( $image, $parameters ); >>

    my $desc = get_sift_descriptor('image.png');
    print for @{ $desc->{keypoints} };

B<Not yet implemented>

=cut

sub get_sift_descriptor {
    my ($filename, $params) = @_;
    
    $params = default_sift_params( $params );
    
    my ($keypoints, $descriptor) = myccv_get_descriptor($filename);
    return {
    	keypoints => $keypoints,
    	descriptor => $descriptor,
    }
}

=head2 C<< sift( $object, $scene, $params ) >>

    my @common_features = sift( 'object.png', 'sample.png' );

Returns a list of 4-element arrayrefs. The elements are:

    object-x
    object-y
    scene-x
    scene-y

The parameters get decoded by C<get_default_params>.

=cut

sub sift {
    my ($object, $scene, $params) = @_;
    
    $params = default_sift_params( $params );
    
    myccv_sift( $object, $scene, $params);
};

=head2 C<< detect_faces( $png_file ) >>

    my @faces = detect_faces('sample.png');

Returns a list of 5-element arrayrefs. The elements are:

    x
    y
    width
    height
    confidence

=cut

sub detect_faces {
    my ($filename, $training_data_path) = @_;
    
    if(! $training_data_path ) {
    	($training_data_path = $INC{ "Image/CCV.pm" }) =~ s!.pm$!!;
    	$training_data_path .= '/facedetect';
    };
    
    if( ! -d $training_data_path ) {
    	croak "Training data path '$training_data_path' does not seem to be a directory!";    
    };
    myccv_detect_faces($filename, $training_data_path);
}

Image::CCV->bootstrap();

1;

=head1 LIMITATIONS

Due to the early development stages, there are several limitations.

=head2 Limited data transfer

Currently, the only mechanism to pass in image data to C<ccv> is by loading
grayscale PNG or JPEG images from disk. The plan is to also be able to pass
in image data as scalars or L<Imager> objects.

=head2 Limited result storage

Currently, there is no implemented way to store the results of applying
the SIFT algorithm to an image. This makes searching several images for the
same object slow and inconvenient.

=head2 Limited memory management

Memory currently is only allocated. Rarely is memory deallocated.

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/image-ccv>.

The upstream repository of C<libccv> is at

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

The support for C<libccv> can be found at L<http://libccv.org>.

=head1 TALKS

I've given one lightning talk about this module at Perl conferences:

L<German Perl Workshop, German|http://corion.net/talks/Image-CCV-lightning-talk/image-ccv-lightning-talk.de.html>

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-CCV>
or via mail to L<image-ccv-Bugs@rt.cpan.org>.

=head1 INSTALL

Compilation requires -dev header libraries, so make sure you have (at the time of writing, on *nix)
I<libjpeg8-dev> and I<libpng12-dev> installed.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2012-2013 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself. The CCV library
distributed with it comes with its own license(s). Please study these
before redistributing.

=cut
