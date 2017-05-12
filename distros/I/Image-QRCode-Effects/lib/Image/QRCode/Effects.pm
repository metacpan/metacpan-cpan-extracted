package Image::QRCode::Effects;

use 5.006;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Slurp qw(write_file);
use Image::Magick;
use Imager;
use Imager::QRCode;
use File::Temp qw(tempfile);
use Params::Validate qw(:all);
use Scalar::Util qw(looks_like_number);

my $rx_colour = { regex => qr/^#[a-f\d]+$/i };
my $valid_size = { regex => qr/^\d+x\d+$/i };
my $num = { callbacks => { 'numeric' => sub { looks_like_number(shift) } } };
my $optional_num = { %$num, optional => 1 };
my $short_enough = { callbacks => { 'under 100 characters' => sub { length(shift) < 100 } } };
my $opt_boolean = { type => BOOLEAN, default => 0 };
my $file_exists = { callbacks => { 'valid file' => sub { -f shift } } };

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {}, $class;
	if (my $qrcode = delete $args{qrcode}) {
		$self->_set_file_from_imager($qrcode);
	}
	elsif (my $file = delete $args{infile}) {
		$self->_set_file_from_file($file);
	}
	else {
		$self->_set_file_from_args(%args);
	}
	return $self;
}

sub _set_file_from_file {
	my $self = shift;
	my ($file) = validate_pos(@_, $file_exists);
	$self->{file} = $file;
}

sub _set_file_from_args {
	my $self = shift;
	my %args = @_;
	my $plot = delete $args{plot} or die "Missing 'plot' parameter to new()";
	my $qrcode = Imager::QRCode->new(%args);
	my $img = $qrcode->plot($plot);
	$self->_set_file_from_imager($img);
}

sub _set_file_from_imager {
	my $self = shift;
	my ($qrcode) = validate_pos(@_, { can => 'write' });
	my $ft = File::Temp->new(TEMPLATE => "qrcode_XXXXXX", TMPDIR => 1, SUFFIX => '.png', UNLINK => 1);
	$self->{_ft} = $ft;
	$qrcode->write(file => $ft);
	close $ft;

	$self->_set_file_from_file($ft->filename);
}

sub write {
  my $self = shift;
  my %p = validate(@_, {
      outfile => 1,
      plasma => $opt_boolean,
      round_corners => $opt_boolean,
      wave => $opt_boolean,
      gradient => $opt_boolean,
      inner_shadow => $opt_boolean,
      colour => { %$rx_colour, default => '#000000' },
      gradient_colour => { %$rx_colour, optional => 1 },
      size => { %$valid_size, default => '600x600' },
      wavelength => { %$num, default => 30 },
      amplitude => { %$num, default => 1.5 },
      corner_sigma => { %$num, default => 2.2 },
      corner_threshold => { regex => qr/^\d+%,\d+%$/, default => '42%,58%' },
      shadow_colour => { %$rx_colour, default => '#000000' },
      gradient_type => { regex => qr/^(normal|radial|plasma)$/, default => 'normal' },
  });

  my $im = Image::Magick->new;
  my $size = $p{size};

  my $file = $self->{file};
  if (!-f "$file") {
    die "Internal error: file $file has not been set";
  }

  # Resize the image, without smoothing
  $im->read($file);
  $im->Resize(geometry => $size, filter => 'Point');

  # Apply the wave, if requested
  if ($p{wave}) {
    my $amplitude = $p{amplitude};
    my $wavelength = $p{wavelength};
    $im->Wave(amplitude => $amplitude, wavelength => $wavelength);
  }

  # Round the corners
  if ($p{round_corners}) {
    $im->GaussianBlur(sigma => $p{corner_sigma});
  }

  # Get rid of the greyness
  $im->Level(levels => $p{corner_threshold});

  # Do the inner shadow
  my $inner_shadow;
  if ($p{inner_shadow}) {
    my $drop = $im->Clone();
    $drop->Transparent(color => '#FFFFFF', invert => 1);
    my $stencil = $drop->Clone();
    $drop->Set(background => $p{shadow_colour});
    $drop->Shadow(opacity => 80, sigma => 3, x => 3, y => 3);
    $stencil->Set(background => 'none'); #XXX: this needed?
    $drop->Composite(image => $stencil);
    $inner_shadow = $drop;
  }

  # fill with a gradient or colour
  my $fill;
  my $col;
  if ($p{gradient}) {
    my $from = $p{colour};
    my $to = $p{gradient_colour};
    my $type = 'gradient';
    $type = 'radial-gradient' if $p{gradient_type} eq 'radial';
    $type = 'plasma' if $p{gradient_type} eq 'plasma';
    if ($type eq 'plasma' && !$to) {
      $fill = "$type:$from";
    }
    else {
      $to ||= $from;
      $fill = "$type:$from-$to";
    }
  }
  elsif (($col = $p{colour}) && $p{plasma} ) {
    if (my $to = $p{gradient_colour}) {
      $fill = "plasma:$col-$to";
    }
    else {
      $fill = "plasma:$col";
    }
  }
  elsif ($col = $p{colour}) {
    $fill = "xc:$col";
  }
  else {
    die "Colour required";
  }

  # create a blank image to fill
  my $white = Image::Magick->new;
  $white->Set(size => $size);
  $white->ReadImage('xc:white');

  # fill with the colour, masked with the barcode
  my $filled = Image::Magick->new;
  $filled->Set(size => $size);
  $filled->ReadImage($fill);
  $im->Negate();
  $white->Composite(image => $filled, mask => $im, color => 'white');

  # put the transparent stencil on top if we've got an inner shadow
  if ($inner_shadow) {
    $white->Composite(image => $inner_shadow);
  }

  # Finally, write the file
  my $outfile = $p{outfile};
  $white->write($outfile);
}

=head1 NAME

Image::QRCode::Effects - Create snazzy QRCodes.

=head1 SYNOPSIS

    use Image::QRCode::Effects;

    my $image = Image::QRCode::Effects->new(
        level => 'H',
        plot  => 'just another perl hacker',
    );

    $image->write(
        outfile         => 'qrcode.jpg',
        colour          => '#1500ff',
        inner_shadow    => 1,
        round_corners   => 1,
        gradient        => 1,
        gradient_colour => '#ffa200',
        gradient_type   => 'radial',
    );

=cut

=head1 DESCRIPTION

This module provides a collection of effects commonly used on QRCodes to make them look interesting. 

It's designed for use with L<Imager::QRCode>, although it'll likely work with
any barcode images. Providing you don't stray too far from the default parameters,
the resulting barcode should be easily readable.

=head1 CONSTRUCTOR

=head2 new(%args)

    # Takes same arguments as Imager::QRCode, and additional 'plot' text
    my $qrcode = Imager::QRCode->new(
        plot          => 'Fire walk with me',
        size          => 2,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new( 255, 255, 255 ),
        darkcolor     => Imager::Color->new( 0, 0, 0 ),
    );

    # Or from file
    my $qr = Image::QRCode::Effects->new( infile => '/path/to/barcode.jpg' );

    # Or from Imager object (eg. Imager::QRCode, after calling ->plot)
    my $qr = Image::QRCode::Effects->new( qrcode => $qrcode );

Returns an C<Image::QRCode::Effects> object, ready to call L</write>. For the
parameters to L<Imager::QRCode>, see that module's documentation.

=head1 METHODS

=head2 write(%args)

    $qrcode->write(
        outfile => '/my/new/barcode.jpg',

        # dimensions
        size => '600x600', # optional, default is '600x600'

        # basic fill colour
        colour => '#00ff00',    # default #000000

        # extra fill effects
        gradient        => 1,           # optional, default 0
        gradient_colour => '#ff0000',
        gradient_type   => 'normal',    # normal|radial|plasma

        # effects
        # wave effect
        wave       => 1,                # optional, default 0
        wavelength => 30,
        amplitude  => 1.5,

        # inner shadow effect
        inner_shadow  => 1,             # optional, default 0
        shadow_colour => '#cccccc',     # default #000000

        # rounded corners effect
        round_corners    => 1,           # optional, default 0
        corner_sigma     => 2.2,
        corner_threshold => '42%,58%',
    );

Writes the barcode with effects to the specified C<outfile>.

There are three main effects: a wave-like effect, rounded corners and an inner
shadow. In addition, there are several gradient fill options. These can be
combined and each have parameters that can be altered to create unique images.

Parameters:

=over

=item C<outfile> - File to write to. Required.

=item C<size> - Dimensions of new image. Defaults to '600x600'.

=item C<colour> - Primary fill colour of the barcode

=item C<gradient> - Boolean, whether to fill the barcode with a gradient. Default is 0.

=item C<gradient_colour> - Gradient colour to fill when C<gradient = 1>.

=item C<gradient_type> - Type of gradient. Can be C<normal> (default), C<radial> or C<plasma>.

=item C<wave> - Boolean, whether to warp the barcode with a wave effect. Default is 0.

=item C<wavelength> - The length of the waves when C<wave = 1>.

=item C<amplitude> - The amplitude of the waves when C<wave = 1>.

=item C<inner_shadow> - Boolean, whether to apply an inner shadow. Default is 0.

=item C<shadow_colour> - Colour of the shadow when C<inner_shadow = 1>.

=item C<round_corners> - Boolean, whether to round the corners of the barcode. Default is 0.

=item C<corner_sigma> - Can be changed to adjust the 'roundedness' of the corners when C<round_corners = 1>. Default is 2.2

=item C<corner_threshold> - Can be changed to adjust the 'sharpness' of the corners when C<round_corners = 1>. Default is '42%,58%'.

=back

=head1 SEE ALSO

L<Imager::QRCode>

L<Image::Magick>

=head1 AUTHOR

Mike Cartmell, C<< <mcartmell at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Mike Cartmell

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
