package Labyrinth::DIUtils;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::DIUtils - Digital Image Utilities for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::DIUtils;

  Labyrinth::DIUtils::Tool('GD');           # switch to GD
  Labyrinth::DIUtils::Tool('ImageMagick');  # switch to ImageMagick
  my $tool = Labyrinth::DIUtils::Tool;      # returns current tool setting

  my $hook = Labyrinth::DIUtils->new($file);
  my $hook = $hook->rotate($degrees);       # 0 - 360
  my $hook = $hook->reduce($xmax,$ymax);
  my $hook = $hook->thumb($thumbnail,$square);

=head1 DESCRIPTION

Handles the driver software for image manipulation;

=cut

#############################################################################
#Modules/External Subroutines                                               #
#############################################################################

use Labyrinth::Globals;
use Labyrinth::Writer;

#############################################################################
#Variables
#############################################################################

my $tool = 'Base';  # defaults to no processing

#############################################################################
#Subroutines
#############################################################################

=head1 FUNCTIONS

=over 4

=item Tool

Configuration function to determine which image package to load.

=back

=cut

sub Tool {
    @_ ? $tool = shift : $tool;
}

=head2 Contructor

=over 4

=item new()

Constructs the interface between Labyrinth and the image package.

=back

=cut

sub new {
    my $self = shift;
    my $file = shift;
    my $hook;

    if(!defined $file) {
        Croak("No image file specified to $self->new().");
    } elsif(!defined $tool) {
        Croak("No image tool specified for $self.");
    } else {
        my $class = "Labyrinth::DIUtils::$tool";
        eval { 
            eval "require $class";
            $hook = $class->new($file);
        };
        if($@ || !$hook) {
            Croak("Invalid image tool [$tool] specified for $self. [$@]");
        }
    }

    return $hook;   # a cheat, but does the job :)
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
