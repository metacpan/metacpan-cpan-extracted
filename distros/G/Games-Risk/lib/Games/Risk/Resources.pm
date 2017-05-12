#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Resources;
# ABSTRACT: utility module to load bundled resources
$Games::Risk::Resources::VERSION = '4.000';
use POE            qw{ Loop::Tk };
use File::Basename qw{ basename };
use File::Spec::Functions;
use Tk;
use Tk::JPEG;
use Tk::PNG;

use Games::Risk::Utils qw{ $SHAREDIR };


use base qw{ Exporter };
our @EXPORT_OK = qw{ get_image map_path maps };
my (%images, %maps);


#--
# SUBROUTINES

# -- public subs

#
# my $img = get_image( $name );
#
# return the Tk image called $name.
#
sub get_image {
    return $images{ $_[0] };
}


#
# my $path = map_path( $name );
#
# return the absolute path of the map $name.
#
sub map_path {
    my ($map) = @_;
    return $maps{$map};
}


#
# my @maps = maps();
#
# return the names of all the maps bundled with GR.
#
sub maps {
    my @maps = sort keys %maps;
    return @maps;
}


# -- private subs

#
# _find_maps( $dirname );
#
# find all maps bundled with the package.
#
sub _find_maps {
    my ($dirname) = @_;

    my $glob = catfile($dirname, 'maps', '*.map');
    %maps = map { ( basename($_,qw{.map}) => $_ ) } glob $glob;
}


#
# _load_images( $dirname );
#
# load images from $dirname/images/*.png
#
sub _load_images {
    my ($dirname) = @_;

    my $glob = catfile($dirname, 'images', '*.png');
    foreach my $path ( glob $glob ) {
        my $name = basename( $path, qw{.png} );
        $images{$name} = $poe_main_window->Photo(-file => $path);
    }
}


#
# _load_tk_icons( $dirname );
#
# load tk icons from $dirname/images/tk_icons.
# code & artwork taken from Tk::ToolBar
#
sub _load_tk_icons {
    my ($dirname) = @_;

    my $path = $dirname->file( 'images', 'tk_icons');
    open my $fh, '<', $path or die "can't open '$path': $!";
    while (<$fh>) {
        chomp;
        last if /^#/; # skip rest of file
        my ($name, $data) = (split /:/)[0, 4];
        $images{$name} = $poe_main_window->Photo(-data => $data);
    }
    close $fh;
}


#--
# INITIALIZATION

# FIXME: all of this is ugly and should go away
_load_tk_icons($SHAREDIR);
_load_images($SHAREDIR);
_find_maps($SHAREDIR);


1;

__END__

=pod

=head1 NAME

Games::Risk::Resources - utility module to load bundled resources

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    use Games::Risk::Resources qw{ image };
    my $image = get_image('actexit16');

=head1 DESCRIPTION

This module is a focal point to access all resources bundled with
C<Games::Risk>. Indeed, instead of each package to reinvent its loading
mechanism, this package provides handy functions to do that.

Moreover, by loading all the images at the same location, it will ensure
that they are not loaded twice, cutting memory eating.

=head1 SUBROUTINES

C<Games::Risk::Resources> deals with various resources bundled within
the distribution. It doesn't export anything by default, but the
following subs are available for your import pleasure.

=head2 Image resources

The images used for the GUI are bundled and loaded as C<Tk::Photo> of
C<$poe_main_window>.

=over 4

=item my $img = get_image( $name )

Return the Tk image called C<$name>. It can be directly used within Tk.

=back

=head2 Map resources

Map resources are playable maps, to allow more playing fun.

=over 4

=item my $path = map_path( $name )

Return the absolute path of the map C<$name>.

=item my @names = maps( )

Return the names of all the maps bundled with C<Games::Risk>.

=back

=head1 SEE ALSO

L<Games::Risk>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
