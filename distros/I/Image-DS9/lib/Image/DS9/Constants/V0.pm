package Image::DS9::Constants::V0;

# ABSTRACT:  predefined constants

use v5.10.0;

use strict;
use warnings;

our $VERSION = 'v1.0.1';

require constant;

use parent 'Exporter';

our @EXPORT;    ## no critic( Modules::ProhibitAutomaticExportation)

my @values = (
    ( map { 'wcs' . $_ } ( 'a' .. 'z' ) ),
    (
        'about',       'abs',          'active',     'align',      'all',         'amplifier',
        'append',      'array',        'automatic',  'average',    'background',  'black',
        'blink',       'blue',         'boxcar',     'buffersize', 'buttons',     'center',
        'clear',       'colorbar',     'cols',       'column',     'command',     'copy',
        'coordinate',  'coordformat',  'crosshair',  'cyan',       'datasec',     'degrees',
        'delete',      'deleteall',    'delim',      'depth',      'destination', 'detector',
        'dss',         'dss2blue',     'dss2red',    'ecliptic',   'eso',         'examine',
        'exclude',     'factor',       'file',       'filename',   'filter',      'first',
        'fits',        'fk4',          'fk5',        'format',     'function',    'galactic',
        'gap',         'gaussian',     'global',     'green',      'grid',        'gz',
        'hide',        'horzgraph',    'icrs',       'image',      'include',     'info',
        'invert',      'interpolate',  'interval',   'jpeg',       'last',        'layout',
        'level',       'limits',       'linear',     'load',       'local',       'log',
        'magenta',     'magnifier',    'manual',     'minmax',     'mode',        'mosaic',
        'mosaicimage', 'mosaicimages', 'moveback',   'movefront',  'name',        'new',
        'next',        'nl',           'no',         'off',        'on',          'orientation',
        'page',        'pagescale',    'pagesize',   'palette',    'pan',         'panner',
        'paste',       'physical',     'png',        'pointer',    'ppm',         'prev',
        'pros',        'radius',       'red',        'refresh',    'rel',         'replace',
        'resample',    'reset',        'resolution', 'rotate',     'row',         'sao',
        'saoimage',    'saotng',       'save',       'scope',      'selectall',   'selected',
        'selectnone',  'semicolon',    'server',     'setup',      'sexagesimal', 'show',
        'single',      'size',         'sky',        'skyformat',  'smooth',      'source',
        'sqrt',        'squared',      'state',      'strip',      'stsci',       'sum',
        'survey',      'system',       'tiff',       'tile',       'to',          'to fit',
        'tofit',       'type',         'url',        'user',       'value',       'vertgraph',
        'wcs',         'white',        'x',          'xy',         'y',           'yellow',
        'yes',         'zoom',         'zscale',
    ) );


sub gen_list {
    my $pfx = '_';

    if ( @_ > 1 && $_[1] eq 'Prefix' ) {
        ( undef, $pfx ) = splice( @_, 1, 2 );
    }

    my @list;

    for my $value ( @values ) {
        ( my $name = $value ) =~ s/\W/_/g;
        $name = $pfx . $name;
        constant->import( $name, $value );
        push @list, $name;
    }

    @list;
}


sub import {
    @EXPORT = gen_list;    # we want it to muck about with @_;

    __PACKAGE__->export_to_level( 1, @_ );
}

sub list {
    # need to add extra arg to front to make gen_list happy

    unshift @_, __PACKAGE__;
    my @list = sort &gen_list;
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    my $len = 0;
    do { my $l = length( $_ ); $len = $l if $l > $len }
      foreach @list;
    printf( "%-${len}s => '%s'\n", $_, &$_ ) foreach @list;

}


#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Constants::V0 - predefined constants

=head1 VERSION

version v1.0.1

=head1 SYNOPSIS

  # import all of the constants
  use Image::DS9::Constants;

  # import a subset
  use Image::DS9::Constants qw( _const1 _const2 );

  # change the prefix
  use Image::DS9::Constants Prefix => 'X_';

  # change the prefix and import a subset
  use Image::DS9::Constants
     Prefix => 'X_', qw( X_const1 X_const2 );

  # list the available constants;
  use Image::DS9::Constants;
  Image::DS9::Constants::list;
  Image::DS9::Constants::list( Prefix => 'X_' );

=head1 DESCRIPTION

This module provides a large number of Perl constants for option strings used
to communicate with B<DS9>.  The constants have a default prefix of C<_>,
which may be changed by the user (see L</SYNOPSIS>).  See the documentation
for the Perl B<constant> module for information on what constitutes a legal
constant name (for instance, two leading underscores are not allowed).

To determine what the constants are, use the B<list> function:

  perl -MImage::DS9::Constants \
          -e 'Image::DS9::Constants::list'

This will print a listing of all of the constants.  To specify a different
prefix,

  perl -MImage::DS9::Constants \
          -e 'Image::DS9::Constants::list( Prefix => "XX")'

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
