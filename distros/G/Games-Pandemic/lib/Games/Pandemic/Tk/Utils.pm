#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Utils;
{
  $Games::Pandemic::Tk::Utils::VERSION = '1.120510';
}
# ABSTRACT: Tk utilities for gui building

use File::Spec::Functions qw{ catfile };
use Moose;
use POE;
extends 'Exporter';

use Games::Pandemic::Utils;

our @EXPORT = qw{ image pandemic_icon };

# -- public subs


sub image {
    my ($path, $toplevel) = @_;
    $toplevel //= $poe_main_window; # //FIXME: padre
    my $img = $poe_main_window->Photo($path);
    return $img if $img->width;
    return $toplevel->Photo("$toplevel-$path", -file=>$path);
}



sub pandemic_icon {
    return image( catfile($SHAREDIR, 'icon.png'), @_ );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Tk::Utils - Tk utilities for gui building

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This module exports some useful subs for tk guis.

=head1 METHODS

=head2 my $img = image( $path [, $toplevel ] );

Return a tk image loaded from C<$path>. If the photo has already been
loaded, return a handle on it. If C<$toplevel> is given, it is used as
base window to load the image.

=head2 my $img = pandemic_icon( [$toplevel] );

Return a tk image to be used as C<$toplevel> icon throughout the game.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


