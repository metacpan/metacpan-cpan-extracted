package Image::DS9::OldConstants;

use strict;
use warnings;

our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

require Exporter;

@ISA = qw( Exporter );

# export nothing by default
@EXPORT = qw( );

# load EXPORT_OK with all of the symbols
Exporter::export_ok_tags($_) foreach keys %EXPORT_TAGS;

# now, create a tag which will import all of the symbols
$EXPORT_TAGS{all} = \@EXPORT_OK;

#####################################################################

use constant ON		=> 'on';
use constant OFF	=> 'off';
use constant YES	=> 'yes';
use constant NO		=> 'no';

BEGIN {
  
  our @symbols = qw( ON OFF YES NO );
  $EXPORT_TAGS{extra} = \@symbols;
}

#####################################################################

# Coordinate systems
use constant Coord_fk4      => 'fk4';
use constant Coord_fk5      => 'fk5';
use constant Coord_icrs     => 'icrs';
use constant Coord_galactic => 'galactic';
use constant Coord_ecliptic => 'ecliptic';
use constant Coord_linear   => 'linear';
use constant Coord_image    => 'image';
use constant Coord_physical => 'physical';

BEGIN {
  our @symbols = qw( Coord_fk4 Coord_fk5 Coord_icrs Coord_galactic 
		     Coord_ecliptic Coord_linear Coord_image
		     Coord_physical );
  $EXPORT_TAGS{coords} = \@symbols;
}

#####################################################################

# Coordinate formats
use constant CoordFmt_degrees     => 'degrees';
use constant CoordFmt_sexagesimal => 'sexagesimal';

BEGIN {
  our @symbols = qw( CoordFmt_degrees CoordFmt_sexagesimal );
  $EXPORT_TAGS{coord_fmts} = \@symbols;
}

#####################################################################

use constant B_about => 'about';
use constant B_buffersize => 'buffersize';
use constant B_cols => 'cols';
use constant B_factor => 'factor';
use constant B_filter => 'filter';
use constant B_function => 'function';
use constant B_average => 'average';
use constant B_sum => 'sum';
use constant B_to_fit => 'to fit';

BEGIN
{
  my @symbols = qw( B_about B_buffersize B_cols B_factor B_filter
		 B_function B_average B_sum B_fit);
  $EXPORT_TAGS{bin} = \@symbols;
}

#####################################################################

use constant CM_invert => 'invert';

BEGIN
{
  my @symbols = qw( CM_invert );
  $EXPORT_TAGS{colormap} = \@symbols;
}

#####################################################################

use constant D_tile   => 'tile';
use constant D_single => 'single';
use constant D_blink  => 'blink';


BEGIN 
{ 
  my @symbols = qw( D_blink D_tile D_single );
  $EXPORT_TAGS{ display } = \@symbols;
}

#####################################################################

use constant FT_MosaicImage	=> 'mosaicimage';
use constant FT_MosaicImages	=> 'mosaicimages';
use constant FT_Mosaic		=> 'mosaic';
use constant FT_Array		=> 'array';
use constant FT_Save		=> 'save';

BEGIN 
{
  my @symbols = qw( FT_MosaicImage FT_MosaicImages FT_Mosaic FT_Array FT_Save);
  $EXPORT_TAGS{filetype} = \@symbols;
}

#####################################################################

use constant FR_active	=> 'active';
use constant FR_all	=> 'all';
use constant FR_center  => 'center';
use constant FR_clear	=> 'clear';
use constant FR_delete  => 'delete';
use constant FR_first	=> 'first';
use constant FR_hide    => 'hide';
use constant FR_last	=> 'last';
use constant FR_new     => 'new';
use constant FR_next	=> 'next';
use constant FR_prev	=> 'prev';
use constant FR_refresh => 'refresh';
use constant FR_reset   => 'reset';
use constant FR_show	=> 'show';

BEGIN { 
  my @symbols = qw( FR_active FR_all FR_center FR_clear FR_delete
		       FR_first FR_hide FR_last FR_new FR_next FR_prev 
		       FR_refresh FR_reset FR_show );
  $EXPORT_TAGS{frame} = \@symbols;

}


#####################################################################

use constant MB_pointer		=> 'pointer';
use constant MB_crosshair	=> 'crosshair';
use constant MB_colorbar	=> 'colorbar';
use constant MB_pan		=> 'pan';
use constant MB_zoom		=> 'zoom';
use constant MB_rotate		=> 'rotate';
use constant MB_examine		=> 'examine';

BEGIN
{
  my @symbols = qw( MB_pointer MB_crosshair MB_colorbar MB_pan
		      MB_zoom MB_rotate MB_examine );

  $EXPORT_TAGS{mode} = \@symbols;
}

#####################################################################


use constant OR_X	=> 'x';
use constant OR_Y	=> 'y';
use constant OR_XY	=> 'xy';

BEGIN
{
  my @symbols = qw( OR_X OR_Y OR_XY );
  $EXPORT_TAGS{orient} = \@symbols;
}

#####################################################################

use constant Rg_coord       => 'coord';
use constant Rg_coordformat => 'coordformat';
use constant Rg_deleteall   => 'deleteall';
use constant Rg_delim       => 'delim';
use constant Rg_ds9         => 'ds9';
use constant Rg_file        => 'file';
use constant Rg_load        => 'load';
use constant Rg_format      => 'format';
use constant Rg_moveback    => 'moveback';
use constant Rg_movefront   => 'movefront';
use constant Rg_nl          => 'nl';
use constant Rg_pros        => 'pros';
use constant Rg_save        => 'save';
use constant Rg_saoimage    => 'saoimage';
use constant Rg_saotng      => 'saotng';
use constant Rg_selectall   => 'selectall';
use constant Rg_selectnone  => 'selectnone';
use constant Rg_semicolon   => 'semicolon';

use constant Rg_return_fmt   => 'return_fmt';
use constant Rg_raw         => 'raw';

BEGIN
{
  my @symbols = qw(
		   Rg_coord
		   Rg_coordformat
		   Rg_deleteall
		   Rg_delim
		   Rg_ds9
		   Rg_file
		   Rg_format
		   Rg_load
		   Rg_moveback
		   Rg_movefront
		   Rg_nl
		   Rg_pros
		   Rg_saoimage
		   Rg_saotng
		   Rg_save
		   Rg_selectall
		   Rg_selectnone
		   Rg_semicolon

		   Rg_return_fmt
		   Rg_raw
		  );


  $EXPORT_TAGS{regions} = \@symbols;
}

#####################################################################

use constant S_linear	=> 'linear';
use constant S_log	=> 'log';
use constant S_squared	=> 'squared';
use constant S_sqrt	=> 'sqrt';
use constant S_minmax	=> 'minmax';
use constant S_zscale	=> 'zscale';
use constant S_user	=> 'user';
use constant S_local	=> 'local';
use constant S_global	=> 'global';

use constant S_limits	=> 'limits';
use constant S_mode	=> 'mode';
use constant S_scope	=> 'scope';
use constant S_datasec  => 'datasec';


BEGIN 
{ 
  my @symbols = qw( S_linear S_log S_squared S_sqrt S_minmax S_zscale
		    S_user S_local S_global S_limits S_mode S_scope 
		    S_datasec
		  );

  $EXPORT_TAGS{scale} = \@symbols;
}

#####################################################################

use constant T_grid	 => 'grid';
use constant T_column	 => 'column';
use constant T_row	 => 'row';
use constant T_gap	 => 'gap';
use constant T_layout	 => 'layout';
use constant T_mode	 => 'mode';
use constant T_auto	 => 'automatic';
use constant T_manual	 => 'manual';


BEGIN 
{ 
  my @symbols  = qw(
		    T_grid T_column T_row T_gap T_layout T_mode T_auto T_manual
		   );
  $EXPORT_TAGS{tile} = \@symbols;
}

#####################################################################

use constant WCS_align   => 'align';
use constant WCS_format  => 'format';
use constant WCS_reset   => 'reset';
use constant WCS_replace => 'replace';
use constant WCS_append  => 'append';

BEGIN
{
  my @symbols = qw( WCS_align WCS_format WCS_reset WCS_replace WCS_append );
  $EXPORT_TAGS{wcs} = \@symbols;
}

#####################################################################

use constant V_info      => 'info';
use constant V_panner    => 'panner';
use constant V_magnifier => 'magnifier';
use constant V_buttons   => 'buttons';
use constant V_colorbar  => 'colorbar';
use constant V_horzgraph => 'horzgraph';
use constant V_vertgraph => 'vertgraph';
use constant V_wcs       => 'wcs';
use constant V_detector  => 'detector';
use constant V_amplifier => 'amplifier';
use constant V_physical  => 'physical';
use constant V_image     => 'image';

BEGIN 
{ 
  my @symbols = qw( V_info V_panner V_magnifier V_buttons V_colorbar
		 V_horzgraph V_vertgraph V_wcs V_detector V_amplifier
		 V_physical V_image );

  $EXPORT_TAGS{view} = \@symbols;
}

#####################################################################

use constant DSS_name	=> 'name';
use constant DSS_coord  => 'coord';
use constant DSS_server => 'server';
use constant DSS_survey => 'survey';
use constant DSS_size   => 'size';

use constant DSS_SAO	=> 'sao';
use constant DSS_STSCI	=> 'stsci';
use constant DSS_ESO	=> 'eso';

use constant DSS_dss	=> 'dss';
use constant DSS_dss2red	=> 'dss2red';
use constant DSS_dss2blue	=> 'dss2blue';


BEGIN
{
  my @symbols = qw( DSS_name DSS_coord DSS_server DSS_survey DSS_size 
		    DSS_SAO DSS_STSCI DSS_ESO
		    DSS_dss DSS_dss2red DSS_dss2blue );

  $EXPORT_TAGS{dss} = \@symbols;
}

#####################################################################

1;

__END__

=pod

=head1 NAME

Image::DS9::OldConstants - contants to avoid typographic errors

=head1 DESCRIPTION

This module contains the constants previously defined in B<Image::DS9>.
The really shouldn't be used anymore, as there are two many tags, and
the prefixes are confusing and many.  These are here to ease
transition to the new constants.

=head2 The constants

Many constants have been defined to avoid typographic errors.  By
default they are not imported into the caller's namespace; they are
available via the B<Image::DS9::OldConstants> namespace,
e.g. B<Image::DS9::OldConstants::CM_invert>.  Since this is quite a
mouthful, various import tags are available which will import some, or
all of the constants into the caller's namespace.  For example:

	use Image::DS9::OldConstants qw( :frame :tile :filetype :display );

The following tags are available

	all
	bin
	colormap
	display
	filetype
	frame
	mode
	orient
	scale
	tile
	view


=over 8

=item all

This tag imports all of the symbols defined by the other tags, as
well as

	ON	=> 1
	OFF	=> 0
	YES	=> 'yes'
	NO	=> 'no'

=item bin

	B_about      => 'about'
	B_buffersize => 'buffersize'
	B_cols       => 'cols'
	B_factor     => 'factor'
	B_filter     => 'filter'
	B_function   => 'function'
	B_average    => 'average'
	B_sum        => 'sum'
	B_to_fit     => 'to fit'

=item colormap

	CM_invert    => 'invert'

=item coord_fmts

	CoordFmt_degrees     => 'degrees'
	CoordFmt_sexagesimal => 'sexagesimal'

=item coords

	Coord_fk4      => 'fk4'
	Coord_fk5      => 'fk5'
	Coord_icrs     => 'icrs'
	Coord_galactic => 'galactic'
	Coord_ecliptic => 'ecliptic'
	Coord_linear   => 'linear'
	Coord_image    => 'image'
	Coord_physical => 'physical'

=item display

	D_tile   => 'tile'
	D_single => 'single'
	D_blink  => 'blink'


=item dss

	DSS_name   => 'name'
	DSS_coord  => 'coord'
	DSS_server => 'server'
	DSS_survey => 'survey'
	DSS_size   => 'size'

	DSS_SAO	   => 'sao'
	DSS_STSCI  => 'stsci'
	DSS_ESO	   => 'eso'

	DSS_dss    => 'dss'
	DSS_dss2red	=> 'dss2red'
	DSS_dss2blue	=> 'dss2blue'


=item file

	FT_MosaicImage	=> 'mosaicimage'
	FT_MosaicImages	=> 'mosaicimages'
	FT_Mosaic	=> 'mosaic'
	FT_Array	=> 'array'
	FT_Save		=> 'save'

=item frame

	FR_active  => 'active'
	FR_all	   => 'all'
	FR_center  => 'center'
	FR_clear   => 'clear'
	FR_delete  => 'delete'
	FR_first   => 'first'
	FR_hide    => 'hide'
	FR_last    => 'last'
	FR_new     => 'new'
	FR_next    => 'next'
	FR_prev    => 'prev'
	FR_refresh => 'refresh'
	FR_reset   => 'reset'
	FR_show    => 'show'

=item mode

	MB_pointer	=> 'pointer'
	MB_crosshair	=> 'crosshair'
	MB_colorbar	=> 'colorbar'
	MB_pan		=> 'pan'
	MB_zoom		=> 'zoom'
	MB_rotate	=> 'rotate'
	MB_examine	=> 'examine'

=item orient

	OR_X	=> 'x'
	OR_Y	=> 'y'
	OR_XY	=> 'xy'

=item regions

	Rg_movefront   => 'movefront'
	Rg_moveback    => 'moveback'
	Rg_selectall   => 'selectall'
	Rg_selectnone  => 'selectnone'
	Rg_deleteall   => 'deleteall'
	Rg_file        => 'file'
	Rg_load	       => 'load'
	Rg_save	       => 'save'

	Rg_format      => 'format'
	Rg_coord       => 'coord'
	Rg_coordformat => 'coordformat'
	Rg_delim       => 'delim'

	Rg_nl          => 'nl
	Rg_semicolon   => 'semicolon'

	Rg_ds9         => 'ds9'
	Rg_saotng      => 'saotng'
	Rg_saoimage    => 'saoimage'
	Rg_pros        => 'pros'

	Rg_return_fmt
	Rg_raw


=item scale


	S_linear   => 'linear'
	S_log	   => 'log'
	S_squared  => 'squared'
	S_sqrt     => 'sqrt'

	S_minmax   => 'minmax'
	S_zscale   => 'zscale'
	S_user     => 'user'

	S_local    => 'local'
	S_global   => 'global'

	S_limits   => 'limits'
	S_mode     => 'mode'
	S_scope    => 'scope'
        S_datasec  => 'datasec'

=item tile

	T_grid	 => 'grid'
	T_column => 'column'
	T_row	 => 'row'
	T_gap	 => 'gap'
	T_layout => 'layout'
	T_mode	 => 'mode'
	T_auto	 => 'automatic'
	T_manual => 'manual'


=item view

	V_info      => 'info'
	V_panner    => 'panner'
	V_magnifier => 'magnifier'
	V_buttons   => 'buttons'
	V_colorbar  => 'colorbar'
	V_horzgraph => 'horzgraph'
	V_vertgraph => 'vertgraph'
	V_wcs       => 'wcs'
	V_detector  => 'detector'
	V_amplifier => 'amplifier'
	V_physical  => 'physical'
	V_image     => 'image'

=item wcs

	WCS_align   => 'align'
	WCS_format  => 'format'
	WCS_reset   => 'reset'
	WCS_replace => 'replace'
	WCS_append  => 'append'

=back


=head1 REQUIREMENTS

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius ( djerius@cfa.harvard.edu )

=head1 SEE ALSO

perl(1), Image::DS9

=cut
