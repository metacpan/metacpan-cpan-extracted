package Image::Magick::Thumbnail::Simple;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.12';

require Image::Magick;

	my $error = q{};

#-------------------------------------------------------------------------------
# Module declaration
#-------------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my %argv = @_;
	my $class = ref( $proto ) || $proto;
	my $self = {
		SIZE    => $argv{'size'}    || undef,
		BLUR    => $argv{'blur'}    || 1,
		QUALITY => $argv{'quality'} || undef,
		WIDTH   => undef,
		HEIGHT  => undef,
	};
	bless( $self, $class );
	return $self;
}
#-------------------------------------------------------------------------------
# error
#-------------------------------------------------------------------------------
sub error {
	my $self = shift;
	return $error;
}
#-------------------------------------------------------------------------------
# size
#-------------------------------------------------------------------------------
sub size {
	my $self = shift;
	if( @_ ){ $self -> {SIZE} = shift }
	return $self -> {SIZE};
}
#-------------------------------------------------------------------------------
# blur
#-------------------------------------------------------------------------------
sub blur {
	my $self = shift;
	if( @_ ){ $self -> {BLUR} = shift }
	return $self -> {BLUR};
}
#-------------------------------------------------------------------------------
# quality
#-------------------------------------------------------------------------------
sub quality {
	my $self = shift;
	if( @_ ){ $self -> {QUALITY} = shift }
	return $self -> {QUALITY};
}
#-------------------------------------------------------------------------------
# width
#-------------------------------------------------------------------------------
sub width {
	my $self = shift;
	return $self -> {WIDTH};
}
#-------------------------------------------------------------------------------
# height
#-------------------------------------------------------------------------------
sub height {
	my $self = shift;
	return $self -> {HEIGHT};
}
#-------------------------------------------------------------------------------
# thumbnail
#-------------------------------------------------------------------------------
sub thumbnail {
	my $self = shift;
	my %args = @_;

	my $input   = $args{'input'};
	my $output  = $args{'output'};
	my $size    = $args{'size'}    || $self -> {SIZE};
	my $blur    = $args{'blur'}    || $self -> {BLUR};
	my $quality = $args{'quality'} || $self -> {QUALITY};

	#input
	if( !$input ){
		$error = 'No input specified';
		return;
	}

	# output
	if( !$output ){
		$error = 'No output specified';
		return;
	}

	# size
	if( !$size ){
		$error = 'No size or scale specified';
		return;
	}
	elsif( $size <= 0 ){
		$error = 'Invalid width';
		return;
	}

	my $image = new Image::Magick;

	$image -> Read( $input );
	my( $width, $height ) = $image -> Ping( $input );

	# horizonal
	if( $width > $height ){
		$self -> {HEIGHT} = int( $height * ( $size / $width ) );
		$self -> {WIDTH} = $size;
	}

	# vertical
	else {
		$self -> {WIDTH} = int( $width * ( $size / $height ) );
		$self -> {HEIGHT} = $size;
	}

	$image -> Set( quality => $quality ) if $quality;
	$image -> Resize(
		width  => $self -> {WIDTH},
		height => $self -> {HEIGHT},
		blur   => $blur,
	);
	$image -> Write( $output );
	return 1;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Image::Magick::Thumbnail::Simple - The thumbnail image is easily made without uselessness.

=head1 SYNOPSIS

=head2 It outputs it to the file. 

  use Image::Magick::Thumbnail::Simple;
  my $t = new Image::Magick::Thumbnail::Simple;
  $t -> thumbnail(
    input  => 'input.jpg',
    output => 'output.jpg',
    size   => 128,
  ) or die $t -> error;

=head2 It outputs it to the STDOUT. 

  use Image::Magick::Thumbnail::Simple;
  my $t = new Image::Magick::Thumbnail::Simple;
  binmode STDOUT;
  print "Content-type: image/jpeg\n\n";
  $t -> thumbnail(
    input  => 'input.jpg',
    output => 'jpg:-',
    size   => 128,
  ) or die $t -> error;

=head2 When specifying it when initializing it

It is succeeded to as long as it doesn't individually specify it at all the 
following. 

  $t = new Image::Magick::Thumbnail::Simple(
    size    => 128,
    blur    => 0.8,
    quality => 80,
  );

=head2 When changing

It is effective for jpeg format. 
The value is between from 0 to 100. 

  $t -> size( 128 );
  $t -> blur( 0.8 );
  $t -> quality( 80 );

=head2 When individually specifying it

The input and the output can be specified only for individual.

  $t -> thumbnail(
    input   => 'input,jpg',
    output  => 'output.jpg',
    size    => 128,
    blur    => 0.8,
    quality => 80,
  );

=head2 Width of thumbnail image

  $width = $t -> width;

=head2 Height of thumbnail image

  $height = $t -> height;

=head1 DESCRIPTION

The thumbnail image can be easily made by using Image::Magick.
A basic setting is the same as Image::Magick.
Only the processing of the resize of the image is treated.
The version opened to the public is 0.10.
In 0.12, it came to return a size that corrected of the explanation 
and was thumbnail.

=head1 SEE ALSO

Image::Magick

=head1 AUTHOR

Satoshi Ishikawa E<lt>cpan@penlabo.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Satoshi Ishikawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
