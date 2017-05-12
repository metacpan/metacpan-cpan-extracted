package Imager::Simple;

use warnings;
use strict;

use base 'Class::Accessor::Fast';

use Carp ();
use Scalar::Util 'blessed';

use Imager;

__PACKAGE__->mk_accessors(qw(frames format));

=head1 NAME

Imager::Simple - Make easy things easy with Imager

=head1 VERSION

Version 0.010003

=cut

our $VERSION = '0.010003';

=head1 SYNOPSIS

C<Imager::Simple> simplyfies common tasks with L<Imager>.

  use Imager::Simple;

  # scale image "anim.gif" and assign output to a variable
  $scaled_data = eval {
    Imager::Simple->read('anim.gif')->scale(100, 100, 'min')->data;
  };
  if ($@) {
    die "error from Imager::Simple: $@";
  }

=head1 DESCRIPTION

L<Imager> is a powerful module for processing image data, but it is the
power that makes it sometimes hard to use for simple tasks, like for
example read an image, scale it, convert it to another format and save it
somewhere. This module tries to DWIM with as little effort as possible.

=head1 METHODS

=cut

# internal - get the first defined value
sub first_defined ($;@) { for (@_) { return $_ if defined } }

=head2 read

  $img = Imager::Simple->read($source, $type);

A constructor method that reads an image and returns an C<Image::Simple>
object. C<$source> can be

=over

=item a scalar

which is taken as a name of a file, that contains the image;

=item a reference to a scalar

that contains the image data itself;

=item a file handle

of an opened file from which the image data can be read.

=back

The C<$type> is optional. If given it must be an image type known by
L<Imager> like C<png> or C<jpeg>. If not given L<Imager> tries to guess the
image type.

Image data is read by L<Imager's read_multi() method|Imager::Files/Description>.
The returned object provides the individual images through the L</frames>
method. For most images C<< $img->frames >> is a reference to an array
with one element (C<< @{$img->frames} == 1 >>).

=cut

sub read {
    my ($self, $d, $type) = @_;
    my @args;
    my $ref = ref $d;

    $self = bless {}, $self unless ref $self;
    if ($ref) {
	# read through supplied code
	if ($ref eq 'CODE') {
	    @args = (callback => $d);
	}
	# get data from a filehandle
	elsif ($ref eq 'GLOB' or blessed($d) and $d->can('read')) {
	    @args = (fh => $d);
	}
	# read from scalar
	elsif ($ref eq 'SCALAR') {
	    @args = (data => $$d);
	}
    }
    else {
	@args = (file => $d);
    }
    push @args, 'type', $type if defined $type;
    @{$self->{frames}} = Imager->read_multi(@args)
	or Carp::croak(Imager->errstr);

    $self->{format} = $self->{frames}->[0]->tags(name => 'i_format');

    $self;
}

=head2 format

  $img->format('gif');

Accessor to the image's output format.

=head2 frames

C<Imager::Simple> supports multi-image files, e.g. GIF animations.
The individual images are stored in an array of L<Image|Image> objects,
that is available through the C<frames> method.

=head2 clone

TODO

=cut

sub clone {
    Carp::croak("not implemented yet");
}

=head2 scale

  $scaled_img = $img->scale(100);
  $scaled_img = $img->scale({y => 100});
  $scaled_img = $img->scale(100, 100, 'min');
  $scaled_img = $img->scale(100, 100, {type => 'min'});
  $scaled_img = $img->scale('min', {height => 100, width => 100});

Scale the image in place.

Accepts absolute and named arguments. Named arguments must be supplied
a hash reference as last argument. The order of absolute argument
positions is C<width>, C<height>, C<type>. All other arguments can only
be supplied as named arguments.
Possible names for the image width are C<width>, C<x> and C<xpixels> -
names for the image height are C<height>, C<y> and C<ypixels> - and
finally the type must be named C<type>. For all other known named
arguments see L<Imager::Transformations|Imager::Transformations/scale>.

Absolute and named arguments can be mixed, whereas absolute arguments
supersede named ones.

Image tags are copied from the old image(s) where applicable.

=cut

sub scale {
    my $self = shift;
    my $opt = ref $_[-1] eq 'HASH' ? pop : {};
    my (%args, %scale, @out, $out, $tag, $factor_x, $factor_y, $t);
    my @frames = @{$self->{frames}}
	or return $self;
    my ($screen_width, $screen_height);
    my ($width, $height);

    for (shift, $opt->{x}, $opt->{xpixels}, $opt->{width}) {
	$width = $_, last if defined;
    }
    for (shift, $opt->{y}, $opt->{ypixels}, $opt->{height}) {
	$height = $_, last if defined;
    }
    for (shift, $opt->{type}) {
	$args{type} = $_, last if defined;
    }
    for (qw(constrain qtype)) {
	$args{$_} = $t, last if defined($t = $opt->{$_});
    }
    for (qw(scalefactor xscalefactor yscalefactor)) {
	$scale{$_} = $t, last if defined($t = $opt->{$_});
    }
    for (my $i = 0; my $frame = $frames[$i]; ++$i) {

	if ($i == 0) {
	    if ($frame->tags(name => 'i_format') eq 'gif') {
		$args{xscalefactor} = $factor_x =
		    defined $width ?
			$width / $frame->tags(name => 'gif_screen_width') :
			first_defined $scale{xscalefactor}, $scale{scalefactor};
		$args{yscalefactor} = $factor_y =
		    defined $height ?
			$height / $frame->tags(name => 'gif_screen_height') :
			first_defined $scale{yscalefactor}, $scale{scalefactor} || $factor_x || 1;
	    }
	    else {
		$args{xscalefactor} = $factor_x =
		    defined $width ?
			$width / $frame->getwidth :
			first_defined $scale{xscalefactor}, $scale{scalefactor};
		$args{yscalefactor} = $factor_y =
		    defined $height ?
			$height / $frame->getheight :
			first_defined $scale{yscalefactor}, $scale{scalefactor} || $factor_x || 1;
	    }
	    $args{xscalefactor} = $factor_x = $factor_y
		unless defined $factor_x;
	}

	$out = $frame->scale(%args)
	    or Carp::croak($frame->errstr);

	if ($frame->tags(name => 'i_format') eq 'gif') {
	    $out->settag(name => 'gif_left', value => int($factor_x * $frame->tags(name => 'gif_left')));
	    $out->settag(name => 'gif_top', value => int($factor_y * $frame->tags(name => 'gif_top')));

	    $out->settag(name => 'gif_screen_width', value => ceil($factor_x * $frame->tags(name => 'gif_screen_width')));
	    $out->settag(name => 'gif_screen_height', value => ceil($factor_y * $frame->tags(name => 'gif_screen_height')));

	    for $tag (qw/gif_delay gif_user_input gif_loop gif_disposal/) {
		$out->settag(name => $tag, value => $frame->tags(name => $tag));
	    }

	    if ($frame->tags(name => 'gif_local_map')) {
		$out->settag(name => 'gif_local_map', value => 1);
	    }
	}

	push @out, $out;
    }
    $self->{frames} = \@out;

    $self;
}

=head2 write

  $img->write($destination);

Write image data to given destination.

C<$destination> can be:

=over 4

=item A scalar

is taken as a filename.

=item File handle or L<IO::Handle|IO::Handle> object

that must be opened in write mode and should be set to C<binmode>.

=item A scalar reference

points to a buffer where the image data has to be stored.

=item not given

in what case write acts like L<the data() method|/data> by returning
the image buffer.

=back

=cut

sub write {
    my ($self, $d) = @_;

    return $self->data unless defined $d;	# for convenience
    my $key;
    my $ref = ref $d;

    if ($ref) {
	# read through supplied code
	if ($ref eq 'CODE') {
	    $key = 'callback';
	}
	# get data from a filehandle
	elsif ($ref eq 'GLOB' or blessed($d) and $d->can('read')) {
	    $key = 'fh';
	}
	# read from scalar
	elsif ($ref eq 'SCALAR') {
	    $key = 'data';
	}
    }
    else {
	$key = 'file';
    }

    Imager->write_multi(
	    {
		$key => $d,
		type => $self->format,
		transp => 'threshold',
		tr_threshold => 50
	    },
	    @{$self->frames})
	or Carp::croak(Imager->errstr);

    $self;
}

=head2 data

Returns the raw image data.

=cut

sub data {
    my $self = shift;
    my $data;
    
    Imager->write_multi(
	    {
		data => \$data,
		type => $self->format,
		transp => 'threshold',
		tr_threshold => 50
	    },
	    @{$self->frames})
	or Carp::croak(Imager->errstr);

    $data;
}

1;

__END__

=head1 AUTHOR

Bernhard Graf C<< <graf at cpan.org> >>

=head1 BUGS

This module definitely needs more work. It only implements some basic functionality
(read, scale, write). No test have been written.

Please report any bugs or feature requests to
C<bug-imager-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Imager-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Imager::Simple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Imager-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Imager-Simple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Imager-Simple>

=item * Code repository

L<http://github.com/augensalat/Imager-Simple/tree/master>

=back

=head1 COPYRIGHT

Copyright 2007 - 2010 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

