package Labyrinth::DIUtils::Base;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::DIUtils::Base - Base Digital Image Driver for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::DIUtils::Base;

  my $hook = Labyrinth::DIUtils::Base->new($file);
  my $hook = $hook->rotate($degrees);       # 0 - 360
  my $hook = $hook->reduce($xmax,$ymax);
  my $hook = $hook->thumb($thumbnail,$square);

=head1 DESCRIPTION

Handles the driver software for image manipulation; Do not use
this module directly, access via Labyrinth::DIUtils.

This package is a basic package, for use with websites that do not require
any image processing. To provide image processing, install one of the drivers
available, currently these are:

=over

=item * Labyrinth::DIUtils::GD

Uses GD graphics library.

=item * Labyrinth::DIUtils::ImageMagick

Uses ImageMagick image library.

=back

=cut

#############################################################################
#Modules/External Subroutines                                               #
#############################################################################

#############################################################################
#Subroutines
#############################################################################

=head1 METHODS

=head2 Contructor

=over 4

=item new($file)

The constructor. Passed a single mandatory argument, which is then used as the
image file for all image manipulation.

=back

=cut

sub new {
    my $self  = shift;
    my $image = shift;

    my $atts = {
        'image'     => $image,
        'object'    => undef,
    };

    # create the object
    bless $atts, $self;
    return $atts;
}


=head2 Image Manipulation

=over 4

=item rotate($degrees)

By default no processing performed.

=cut

sub rotate {
    my $self = shift;
    my $degs = shift || return;

    return  unless($self->{image});
    return;
}

=item reduce($xmax,$ymax)

By default no processing performed.

=cut

sub reduce {
    my $self = shift;
    my $xmax = shift || 100;
    my $ymax = shift || 100;

    return  unless($self->{image});
    return;
}

=item thumb($thumbnail,$square)

By default no processing performed.

=back

=cut

sub thumb {
    my $self = shift;
    my $file = shift;
    my $smax = shift || 100;

    return  unless($self->{image});
    return;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth::DIUtils

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
