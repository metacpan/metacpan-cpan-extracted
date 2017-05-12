package GFL::Image;


$GFL::Image::VERSION = '0.14a';

=head1 NAME

GFL::Image - An OO interface to P-e Gougelet's Graphic File Library

=head1 SYNOPSIS

  use GFL::Image;

  my $im = GFL::Image-> new;

  $im -> load("test.png");
  $im -> set( output => "jpeg",
              undolevel    => 5
	    );
  $im -> resize (320, 200);
  $im -> filter( maximum => 3,
  		 mediancross => 7
		 );
  $im -> undo;
  $im -> save("test.jpg");

  undef ($im);

=head1 DESCRIPTION

This module provides an Object Oriented interface to Pierre-E. Gougelet's Graphic File Library.

GFL provides a comprehensive set of image processing tools and can access
more than 300 image formats.

GFL is free for non-commercial use, you can grab the latest version at http://www.xnview.org.
People wanting to use it in a commercial application must ask authorization to the author.

=head1 METHODS

=over 2

=item *

Nearly all methods croak their I<usage> when called with improper or missing arguments.

=item *

All methods and attributes are B<case insensitive>. You may say either

	$a -> set( 'output' => 'bmp')

or

	$a -> Set( Output => 'bmp')

or even

	$a -> SeT(OUtPuT => 'bmp')

If the idea of loosing 3 seconds per 100000 method calls makes you sick,
use all I<lowercase> for B<method> names to avoid Autoloading overhead. (timed on a Duron 850Mhz)

=back

=cut

use strict;
use GFL;

use Carp;
require Exporter;

use vars qw($AUTOLOAD @EXPORT @ISA);

@ISA= qw(Exporter);
@EXPORT= qw( dumpallformats getfileinformations );

our %col_depth = ( 'binary' =>		$GFL::GFL_MODE_TO_BINARY,
		   '4g' =>		$GFL::GFL_MODE_TO_4GREY,
		   '8g' =>		$GFL::GFL_MODE_TO_8GREY,
		   '16g' =>		$GFL::GFL_MODE_TO_16GREY,
		   '32g' =>		$GFL::GFL_MODE_TO_32GREY,
		   '64g' =>		$GFL::GFL_MODE_TO_64GREY,
		   '128g' =>		$GFL::GFL_MODE_TO_128GREY,
		   '216g' =>		$GFL::GFL_MODE_TO_216GREY,
		   '256g' =>		$GFL::GFL_MODE_TO_256GREY,
		   '8' =>		$GFL::GFL_MODE_TO_8COLORS,
		   '16' =>		$GFL::GFL_MODE_TO_16COLORS,
		   '32' =>		$GFL::GFL_MODE_TO_32COLORS,
		   '64' =>		$GFL::GFL_MODE_TO_64COLORS,
		   '128' =>		$GFL::GFL_MODE_TO_128COLORS,
		   '216' =>		$GFL::GFL_MODE_TO_216COLORS,
		   '256' =>		$GFL::GFL_MODE_TO_256COLORS,
		   'truecolors' =>	$GFL::GFL_MODE_TO_TRUE_COLORS
		   );

our %bin_dither = ('floyd' =>		$GFL::GFL_MODE_FLOYD_STEINBERG,
		   'pattern'=>		$GFL::GFL_MODE_PATTERN_DITHER,
		   'halftone45'=>	$GFL::GFL_MODE_HALTONE45_DITHER,
		   'halftone90'=>	$GFL::GFL_MODE_HALTONE90_DITHER
		   );


BEGIN {
	GFL::gflLibraryInit();
}

END
{
	&GFL::gflLibraryExit;
}

=head2 GFL::Image->new

Create a new object.
Assigning attributes via C<new> is I<deprecated>.


=cut

sub new
{
	my $self = shift;
	my $type = ref($self) || $self;
	my %params = @_;
	$self = {};
	$self->{'_loadparams'} = GFL::new_LoadParams();
	$self->{'_saveparams'} = GFL::new_SaveParams();
	GFL::gflGetDefaultLoadParams($self->{'_loadparams'});
 	GFL::gflGetDefaultSaveParams($self->{'_saveparams'});
	$self ->{'_saveparams'}->{'Flags'} = $GFL::GFL_SAVE_WANT_FILENAME;
	$self->{'replaceextension'} = 0;
	$self->{'input'} = 'auto';
	# define a LIFO stack for Undos
	$self->{'_bitmaps'} = [];
	$self->{'undolevel'} = $params{'undolevel'} || 1;
	$self->{'dither'} = $params{'dither'};
	$self->{'binarydither'} = $params{'binarydither'} || 'floyd';
	$self->{'verbose'} = $params{'verbose'} || 0;
	$self->{'output'} = $params{'output'} ||'png';
	$self->{'_saveparams'}-> {'FormatIndex'} = GFL::gflGetFormatIndexByName($self->{'output'} );
	$self->{'channelorder'} = $params{'channelorder'} || 'interleaved';
	$self->{'compression'} = 'none';
	$self->{'linepadding'} = $params{'linepadding'} || 1;
	return bless $self, $type;
}

=head2 $o->set(attrib => value, ...)

Set single or multiple attributes.
Valid attributes are :

=over 4

=item UndoLevel

Define the number of possible undos.

If C<undolevel> changes and happens to be lower than the current number of undos,
older undos are cleared accordingly (in FIFO order).


=item Verbose

Set the verbosity level on STDERR:

	False - no STDERR report
	1 - report normal operations + errors (anonymously)
	2 - normal operations + errors, with object identifier
	3 - the above plus various internal/cleaning operations


=item -- ATTRIBUTES CHANGING IMAGE EXPORTATION BEHAVIOR : --


=item Output

The format you want the image to be saved as.
Writable formats are:

	'alias'  : Alias Image File
	'arcib'  : ArcInfo Binary
	'bmp'    : Windows Bitmap
	'cin'    : Kodak Cineon
	'degas'  : Degas & Degas Elite
	'dkb'    : DKB Ray-Tracer
	'gif'    : CompuServe GIF
	'gpat'   : Gimp Pattern
	'grob'   : HP-48/49 GROB
	'hru'    : HRU
	'ico'    : Windows Icon
	'iff'    : Amiga IFF
	'jif'    : Jeff's Image Format
	'jpeg'   : JPEG / JFIF
	'miff'   : Image Magick file
	'mtv'    : MTV Ray-Tracer
	'palm'   : Palm Pilot
	'pbm'    : Portable Bitmap
	'pcl'    : Page Control Language
	'pcx'    : Zsoft Publisher's Paintbrush
	'pgm'    : Portable Greyscale
	'png'    : Portable Network Graphics
	'pnm'    : Portable Image
	'ppm'    : Portable Pixmap
	'psion3' : Psion Serie 3 Bitmap
	'psion5' : Psion Serie 5 Bitmap
	'qrt'    : Qrt Ray-Tracer
	'rad'    : Radiance
	'raw'    : Raw
	'ray'    : Rayshade
	'rla'    : Wavefront Raster file
	'sgi'    : Silicon Graphics RGB
	'soft'   : Softimage
	'tga'    : Truevision Targa
	'ti'     : TI Bitmap
	'tiff'   : TIFF Revision 6
	'uyvy'   : YUV 16Bits
	'uyvyi'  : YUV 16Bits Interleaved
	'vista'  : Vista
	'vivid'  : Vivid Ray-Tracer
	'wbmp'   : Wireless Bitmap (level 0)
	'wrl'    : VRML2
	'xbm'    : X11 Bitmap
	'xpm'    : X11 Pixmap

=item Dither

Boolean.

=item BinaryDither

Preferred dithering method for black & white pictures.

One of: B<floyd>, B<pattern>, B<halftone45>, B<halftone90>

Defaults to C<floyd>.

=item Quality

Defines picture quality (vs. size) for C<jpeg>, C<wic> , C<fpx> formats.

0 E<lt> C<value> E<gt> 100 (best quality)

=item CompressionLevel

Defines compression level for C<png> format.

0 E<lt> C<value> E<gt> 6 (best compression)

=item Interlaced

Boolean. For C<gif> format.

=item Progressive

Boolean. For C<jpeg> format.

=item ReplaceExtension

Boolean.
If set to C<True>, a correct extension is added to the C<filename> when saving,
or it's extension is replaced if incorrect.

=item ChannelOrder

Defines how to store channels in file.

One of: B<interleaved>, B<sequential>, B<separate>
Defaults to: C<interleaved>

=item Compression

Defines a desired compression method.

One of:

B<none>, B<rle>, B<lzw>, B<jpeg>, B<zip>, B<sgi_rle>, B<ccitt_rle>, B<ccitt_fax3>, B<ccitt_fax3_2d>, B<ccitt_fax4>, B<wavelet> or B<lzw_predictor>

# FIXME : This option does not seem to have any effect ...
I'll ask more informations to the GFL library's author.

=item -- ATTRIBUTES CHANGING IMAGE IMPORTATION BEHAVIOR : --

=item Input

The input format. Defaults to 'auto', where GFL tries to guess the format.

Input formats are too numerous to be listed here.
Just say C<dumpallformats()> for a comprehensive list.


=item LinePadding

An integer.

1 (I<default>), 2, 4, ...

=back

=cut

sub set
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	scalar @_ or croak "usage: set(Attribute => Value [,Attribute2 => Value2, ...])\n";
	if (scalar(@_) % 2) { croak "Number of attributes to set does not match number of values"};
	$self-> _flush_lasterror;
	my %args = @_;

	foreach (keys %args)
	{
		my $errid = "$_ ${args{$_}}";
		$self->{'verbose'} and print STDERR "Setting $_ to ".$args{$_}.($self->{'verbose'}>1?" on object $self\n":"\n");
		/^undo/i   and do {
			($args{$_} >= 0) && do {
				$self->{'undolevel'} =$args{$_};
				# get rid of undos exceeding the new undolevel
				$self->_purge_undo;
				next
			};
			$self ->_append_error("$errid : UndoLevel must be a positive number");
			next;
		};
		/^output/i   and do {
			GFL::gflFormatIsWritableByName(lc($args{$_})) && do {
				$self->{'_saveparams'}->{'FormatIndex'} = GFL::gflGetFormatIndexByName(lc($args{$_}));
				$self->{'output'} = lc($args{$_});
				next;
			};
			GFL::gflFormatIsSupported(lc($args{$_})) && do {
				$self-> _append_error("$errid : Format is Read-only");
				next;
			};
			$self-> _append_error("$errid : Unsupported file format");
			next;
		};
		/^input/i and do {
			lc($args{$_})=~/^auto/i && do {
				$self->{'_loadparams'}->{'FormatIndex'} = -1;
				$self->{'input'} = 'auto';
				next;
			};

			GFL::gflFormatIsReadableByName(lc($args{$_})) && do {
				$self->{'_loadparams'}->{'FormatIndex'} = GFL::gflGetFormatIndexByName(lc($args{$_}));
				$self->{'input'} = lc($args{$_});
				next;
			};
			GFL::gflFormatIsSupported(lc($args{$_})) && do {
				$self-> _append_error("$errid : Format is Write-only");
				next;
			};
			$self-> _append_error("$errid : Unsupported file format");
			next;
		};
		/^verbos/i and do {
			(!$args{$_} or $args{$_} > 0) and do {
				$self->{'verbose'} = $args{$_} || 0;
				next
				};
			$self-> _append_error("$errid : Bad verbosity level");
			next;
		};
		/^dither/i and do {
			$self->{'dither'} = $args{$_} ? 1 : 0;
			next;
		};
		/^binary/i and do {
			if (exists $bin_dither{ $args{$_} })
			{
				$self->{'binarydither'} = $args{$_};
				next;
			}
			$self->_append_error("$errid : Not a valid method. Must be one of : floyd, pattern, halftone45, halftone90");
			next;
		};
		/^qual/i and do {
			if (!($args{$_}<0 or $args{$_}>100))
			{
				$self->{'_saveparams'}->{'Quality'} = $args{$_};
				next;
			}
			$self->_append_error("$errid : Value out of range 0..100");
			next;
		};
		/^compressionlev/i and do {
			if (!($args{$_}<0 or $args{$_}>6))
			{
				$self->{'_saveparams'}->{'CompressionLevel'} = $args{$_};
				next;
			}
			$self->_append_error("$errid : Value out of range 0..6");
			next;
		};
		/^interlace/i and do {
			$self->{'_saveparams'}->{'Interlaced'} = $args{$_} ? 1 : 0;
			next;
		};
		/^progress/i and do {
			$self->{'_saveparams'}->{'Progressive'} = $args{$_} ? 1 : 0;
			next;
		};
		/^replaceext/i and do {
			$self->{'_saveparams'}->{'Flags'} = $args{$_} ? ($GFL::GFL_SAVE_REPLACE_EXTENSION) : ($GFL::GFL_SAVE_WANT_FILENAME);
			next;
		};
		/^linepadd/i and do {
			$args{$_} > 0 and do
			{
			$self->{'_loadparams'}->{'LinePadding'} = $args{$_};
			$self->{'linepadding'} = $args{$_};
			next
			};
			$self->_append_error("$errid : Must be a positive number");
			next
		};
		/^channelo/i and do {
			if ($args{$_} =~/^(inter|sequ|sep)/i)
			{
				no strict;
				my $order = lc($1);
				SWCO:
				{
					$order eq 'inter' && do {
						$self->{'channelorder'} = 'interleaved';
						$self->{'_saveparams'}->{'ChannelOrder'} = $GFL::GFL_CORDER_INTERLEAVED;
						last SWCO
					};
					$order eq 'sequ' && do {
						$self->{'channelorder'} = 'sequential';
						$self->{'_saveparams'}->{'ChannelOrder'} = $GFL::GFL_CORDER_SEQUENTIAL;
						last SWCO
					} ;
					$order eq 'sep' && do {
						$self->{'channelorder'} = 'separate';
						$self->{'_saveparams'}->{'ChannelOrder'} = $GFL::GFL_CORDER_SEPARATE
					};
				}
			}
			else
			{
				$self-> _append_error("$errid : Not a valid Channel Order. Must be one of: interleaved, sequential or separate");
			}
			next
		};
		/^compression$/i and do {
			if ($args{$_} =~/^(none|auto|rle|lzw|jpeg|zip|sgi_rle|ccitt_(rle|fax3|fax3_2d|fax4)|wavelet|lzw_predictor)$/i)
			{
				no strict;
				my $compr = lc($1);
				SWCOMPR:
				{
					$self->{'compression'} = $compr;
					$compr eq 'none' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_NO_COMPRESSION;last SWCOMPR};
					$order eq 'rle' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_RLE;last SWCOMPR} ;
					$order eq 'lzw' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_LZW;last SWCOMPR} ;
					$order eq 'jpeg' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_JPEG;last SWCOMPR} ;
					$order eq 'zip' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_ZIP;last SWCOMPR} ;
					$order eq 'sgi_rle' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_SGI_RLE;last SWCOMPR} ;
					$order eq 'ccitt_rle' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_CCITT_RLE;last SWCOMPR} ;
					$order eq 'ccitt_fax3' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_CCITT_FAX3;last SWCOMPR} ;
					$order eq 'ccitt_fax3_2d' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_CCITT_FAX3_2D;last SWCOMPR} ;
					$order eq 'ccitt_fax4' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_CCITT_FAX4;last SWCOMPR} ;
					$order eq 'wavelet' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_WAVELET;last SWCOMPR} ;
					$order eq 'lzw_predictor' && do {$self->{'_saveparams'}->{'Compression'} = $GFL::GFL_LZW_PREDICTOR;last SWCOMPR} ;
				}
			}
			else
			{
				$self-> _append_error("$errid : Not a valid Compression method. Must be one of: none, rle, lzw, jpeg, zip, sgi_rle, ccitt_rle, ccitt_fax3, ccitt_fax3_2d, ccitt_fax4, wavelet or lzw_predictor");
			}
			next
		};



		$self-> _append_error("$_ : Not a writable/known attribute\n");

	}
	return $self->_check_error;

}

=head2 $o->get( attrib, ... )

Get single or multiple attributes.

Valid (case insensitive) attributes are all Set-able attributes plus :

=over 4

=item FileInformations

Brings you a hash reference containing various informations about the current loaded file
(B<as it is on the disk, not as it is in memory !> - this does not reflect any manipulations you have applied)

e.g:

 $infos = $a->get(FileInformations) || die $a->lasterror;
 foreach (keys %$infos)
 {
 print "$_ => $infos->{$_}\n" if $infos->{$_};
 }

sample output:

	Origin => 16
	Description => Sgi RGB
	Width => 182
	CompressionDescription => Sgi Rle
	BitsPerPlane => 8
	FileSize => 98145
	NumberOfPlanes => 3
	FormatName => sgi
	NumberOfImages => 1
	FormatIndex => 4
	Height => 170
	BytesPerPlane => 182
	Compression => 5

=over 4

=item *

remember this is an hash B<reference>, so you must access every member like this:

$infos->{'Width'}

=item *

FileInformations attribute change only when you open a new file.

=item *

To retrieve informations about a file I<before> loading it, see
function C<GetFileInformations()>

=item *

For informations about the current state of the image B<in memory>,
see C<BitmapInformations> attribute.

=back

=item BitmapInformations

Brings you a hash I<reference> containing various informations about the current working Bitmap.

Sample Hash:

	Xdpi => 68
	BytesPerLine => 546
	Width => 182
	BitsPerComponent => 8
	Ydpi => 68
	Data => GFL_UINT8Ptr=SCALAR(0x81834ec)
	Height => 170
	BytesPerPixel => 3
	TransparentIndex => -1
	Type => 16

remember this is an hash B<reference>, so you must access every member like this:

$infos->{'Width'}

=item NumberOfColours / NumberOfColors

Return the number of unique colors in the working bitmap.

=item Width

Width in pixels of the current working bitmap

=item Height

Height in pixels of the current working bitmap

=back

=cut

sub get
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	scalar @_ or croak "usage: get(Attribute [,Attribute2 ...])\n";
	$self-> _flush_lasterror;
	my @wanted;
	foreach my $attribute(@_)
	{
		$attribute=~/^numberofcol/i and do {
			my $img = $self-> {'_curbitmap'};
			if (my $numcol = GFL::gflGetNumberOfColorsUsed($img))
			{
				push @wanted, $numcol;
			}
			else
			{
				$self->_append_error("Can't get number of colors from GFL");
			}
			next;
		};
		$attribute=~/^fileinf/i and do {
			if ($self->{_info})
			{
				push @wanted, $self->{'_info'};
			}
			else{
				$self->_append_error("Can't get file informations");
			}
			next;
		};
		$attribute=~/^bitmapinf/i and do {
			if ($self->{_curbitmap})
			{
				push @wanted, $self->{'_curbitmap'};
			}
			else{
				$self->_append_error("Can't get bitmap informations : no bitmap loaded");
			}
			next;
		};
		$attribute=~/^width/i and do {
			push @wanted, $self->{'_curbitmap'}->{'Width'};
			next;
		};
		$attribute=~/^height/i and do {
			push @wanted, $self->{'_curbitmap'}->{'Height'};
			next;
		};
		$attribute=~/^lasterr/i and do {
			croak "Can't retrieve LastError attribute via get... use ->lasterror() method instead.\n";
		};
		$attribute=~/^qualit/i and do {
				push @wanted, $self->{'_saveparams'}->{'Quality'};
				next;
		};
		$attribute=~/^compressionlev/i and do {
			push @wanted, $self->{'_saveparams'}->{'CompressionLevel'};
			next;
		};
		$attribute=~/^interlace/i and do {
			push @wanted, ($self->{'_saveparams'}->{'Interlaced'} ? 1 : 0);
			next;
		};
		$attribute=~/^progress/i and do {
			push @wanted, ($self->{'_saveparams'}->{'Progressive'} ? 1 : 0);
			next;
		};
		$attribute=~/^replaceext/i and do {
			push @wanted, (($self->{'_saveparams'}->{'Flags'} == $GFL::GFL_SAVE_REPLACE_EXTENSION )? 1 : 0);
			next;
		};

		if (exists $self->{lc($attribute)})
		{
			push @wanted, $self->{lc($attribute)};
		}
		else
		{
			$self->_append_error("$attribute attribute does not exist") unless (exists $self->{lc($attribute)});
		}
	}
	wantarray ? @wanted : $wanted[0];
}

=head2 $o->load( filename [, ImageIndex])

Open the given file.

=over 2

=item *

- If C<input> attribute is set to 'auto' (the default), GFL will attempt to guess the format.

=item *

- C<ImageIndex> indicates which image should be loaded in the case of a multi-image or animated file. It is I<zero-based>.

=back

=cut

sub load
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $file = shift or return $self->_throw_error('usage: load(filename [, ImageIndex])');
	my $index = shift;
	$self->{'_loadparams'}->{'ImageWanted'} = $index || 0;
	my $ptr = GFL::new_BitmapPtr();
	my $info = GFL::new_FileInformation();
	my $error = GFL::gflLoadBitmap( $file, $ptr, $self->{'_loadparams'}, $info);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "Loaded image $file".($self->{'verbose'}>1?" into object $self":"")."\n" if $self->{'verbose'};
		_free($self->{'_info'}) if ref($self->{'_info'});
		$self-> {'_info'} = $info;
		$self-> _set_curbitmap($ptr);
		my $ul = $self->{'undolevel'};
		$self-> {'undolevel'} = 0;
		$self-> _purge_undo;
		$self-> {'undolevel'} = $ul;
		};
	$self->{'_loadparams'}->{'ImageWanted'} &&= 0;
	_free($ptr);
	return $self->_check_error($error);
}

=head2 $o->loadpreview( filename, width, height [, ImageIndex])

Open a custom size preview for the given file.

The preview becomes the current working bitmap.

=over 2

=item *

- If C<input> is set to 'auto' (the default), GFL will attempt to guess the format.

=item *

- C<width> and C<height> will be rounded to the nearest integer value if fractionals.

=item *

- C<ImageIndex> indicates which image should be loaded in the case of a multi-image or animated file. It is I<zero-based>.

=back

e.g:

	$i = getfileinformations('foo.png') or die;
	$a = GFL::Image->new;
	$a -> loadpreview('foo.png', $i->{'Width'}/3, $i->{'Height'}/3);

=cut

sub loadpreview
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my ($file, $width, $height) = @_;
	$file && $width && $height or return $self->_throw_error('usage: loadpreview(filename, width, height [, ImageIndex])');
	my $index = shift;
	$self->{'_loadparams'}->{'ImageWanted'} = $index || 0;
	my $ptr = GFL::new_BitmapPtr();
	my $info = GFL::new_FileInformation();
	# round to the nearest integer
	for($width,$height)
	{
	 	$_ = int( (int($_+ .5) > $_) ? ++$_ : $_);
	}
	my $error = GFL::gflLoadPreview( $file, $width, $height, $ptr, $self->{'_loadparams'}, $info);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "Loaded preview image $file".($self->{'verbose'}>1?" into object $self":"")."\n" if $self->{'verbose'};
		_free($self->{'_info'}) if ref($self->{'_info'});
		$self-> {'_info'} = $info;
		$self-> _set_curbitmap($ptr);
		my $ul = $self->{'undolevel'};
		$self-> {'undolevel'} = 0;
		$self-> _purge_undo;
		$self-> {'undolevel'} = $ul;
	};
	$self->{'_loadparams'}->{'ImageWanted'} &&= 0;
	_free($ptr);
	return $self->_check_error($error);
}

=head2 $o->save( filename )

Save the current Bitmap using attribute C<Output> as format.

Be aware that there is no checking to see if current C<Output> format support the actual color depth.

If the GFL library reports " Can't save this bitmap in this format !", see C<ChangeDepth()> method.

=cut

sub save
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $file = shift or return $self->_throw_error('Usage: Save( filename )');

	if (!GFL::gflFormatIsWritableByName($self->{'output'}))
	{
		confess "Impossible error : Format is Read-only. Did you use the set() accessor ?";
	}
	my $img = $self-> {'_curbitmap'};
	my $error = GFL::gflSaveBitmap( $file, $img, $self->{_saveparams});
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "Saved image $file".($self->{'_saveparams'}->{'Flags'}==$GFL::GFL_SAVE_REPLACE_EXTENSION ?" with auto extension":"").($self->{'verbose'}>1?" from object $self":"")."\n" if $self->{'verbose'};
		};
	return $self->_check_error($error);
}

=head2 $o->resize( Width, Height [, 'quick'])

Rescale the image to the given Width/Height values.

=over 2

=item *

If the keyword 'Quick' is given as third argument, resize method is set to quick ;
otherwise, Bilinear method applies.

=item *

If C<Width> and C<Height> are fractionals, they are rounded to the nearest integer.

=back

=cut

sub resize
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $x = shift;
	my $y = shift;
	$x &&$y or croak "usage: resize(new_Width, new_Height [, 'quick'])";
	#round to the nearest integer
	for($x,$y)
	{
	 	$_ = int( (int($_+ .5) > $_) ? ++$_ : $_);
	}
	my $flag = shift;
	($x eq '' or $y eq '') && return $self->_throw_error('Bad resize argument');
	$flag=($flag=~/quick/i) ? $GFL::GFL_RESIZE_QUICK : $GFL::GFL_RESIZE_BILINEAR;
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflResize( $img, $trans, $x, $y, $flag, 0 );
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for ".($flag==$GFL::GFL_RESIZE_QUICK?"quick":"bilinear")." resize ($x,$y)".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->flip( 'vertical' or 'horizontal' )

Flip image on the given axis.

=cut

sub flip
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $direction = shift or croak "usage: flip('horizontal' || 'vertical')\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = ($direction=~/^v/i) ? (GFL::gflFlipVertical( $img, $trans)) :
					  (GFL::gflFlipHorizontal( $img, $trans));
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for flip $direction".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->negate

Negate current image

=cut

sub negate
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflNegative( $img, $trans);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for negate".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->crop(x, y, width, height)

Crop image starting at (x,y) coordinates from current C<Origin>

=cut

sub crop
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	scalar @_ == 4 or croak "usage: crop (X_origin, Y_origin, Width, Height)";
	my ($x, $y, $w, $h) = @_;
	my $img = $self-> {'_curbitmap'};
	return $self->_throw_error ("x/y coordinates exceed image size") if ($x > $img->{'Width'} or $y > $img->{'Height'});
	my $trans = GFL::new_BitmapPtr();
	my $rect = GFL::new_Rect($x, $y, $w, $h);
	my $error = GFL::gflCrop( $img, $trans, $rect);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for crop origin:($x,$y) W/H:${w}x${h}".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans,$rect);
	return $self->_check_error($error);
}

=head2 $o->contrast(-100...100)


=cut

sub contrast
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $contrast = shift;
	($contrast <= 100 and $contrast >= -100) or croak "usage: contrast(-100..100)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflContrast( $img, $trans, $contrast);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for contrast $contrast".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}
=head2 $o->brightness(-100...100)


=cut
sub brightness
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $brightness = shift;
	($brightness <= 100 and $brightness >= -100) or croak "usage: brightness(-100..100)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflBrightness( $img, $trans, $brightness);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for brightness $brightness".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->gamma(0.01 <-> 5.0)


=cut

sub gamma
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $gamma = shift;
	($gamma <= 5.0 and $gamma >= 0.01) or croak "usage: gamma(0.01 <-> 5.0)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflGamma( $img, $trans, $gamma);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for gamma $gamma".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->rotate( Angle )

Apply a rotation of "Angle" degrees.

=cut

sub rotate
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $angle = shift or croak "usage: rotate(n_degrees)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflRotate( $img, $trans, $angle);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for rotate $angle".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->soften( percent )

=cut

sub soften
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $percent = shift;
	($percent < 1 or $percent > 100) and croak "usage: soften(n_percent)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflSoften( $img, $trans, $percent);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for soften $percent".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->blur( percent )

=cut

sub blur
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $percent = shift;
	($percent < 1 or $percent > 100) and croak "usage: blur(n_percent)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflBlur( $img, $trans, $percent);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for blur $percent".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->sharpen( percent )

=cut

sub sharpen
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $percent = shift;
	($percent < 1 or $percent > 100) and croak "usage: sharpen(n_percent)\n";
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflSharpen( $img, $trans, $percent);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for sharpen $percent".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	_free($trans);
	return $self->_check_error($error);
}

=head2 $o->filter(filter_type => filter_size, ...)

Apply the given filters.

Where filter_type is one of:
C<average>, C<gaussianblur>, C<maximum>, C<minimum>, C<medianbox>, C<mediancross>

And filter_size is one of:
C<3>, C<5>, C<7>, C<9>, C<11>, C<13>

Multiple filters are applied following arguments order.

=cut

sub filter
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	(scalar @_ and !(scalar(@_)%2)) or  croak "usage: filter(filter_type => filter_size, [filter_type => filter_size, ...])\n
		Where filter_type is one of: average, gaussianblur, maximum, minimum, medianbox, mediancross\n
		And filter_size is one of: 3, 5, 7, 9, 11, 13\n
		Multiple filters are applied in arguments order.\n";
	$self -> _flush_lasterror;
	my %set= (3=> 1, 5 =>1, 7=>1, 9=>1, 11=>1, 13=>1);
	my($img, $trans, $error);
	my $error_stack  = '';
	while (my $filter = shift, my $value= shift)
	{
		$set{$value} or return $self->_throw_error($error_stack."Bad filter size for $filter (must be one of 3, 5, 7, 9, 11, 13)");
		$img = $self-> {'_curbitmap'};
		$trans = GFL::new_BitmapPtr();
		FILTERSW:
		{
			$filter =~/^aver/i and do { $error = GFL::gflAverage( $img, $trans, $value); last FILTERSW};
			$filter =~/^gauss/i and do { $error = GFL::gflGaussianBlur( $img, $trans, $value); last FILTERSW};
			$filter =~/^max/i and do { $error = GFL::gflMaximum( $img, $trans, $value); last FILTERSW};
			$filter =~/^min/i and do { $error = GFL::gflMinimum( $img, $trans, $value); last FILTERSW};
			$filter =~/^medianbox/i and do { $error = GFL::gflMedianBox( $img, $trans, $value); last FILTERSW};
			$filter =~/^mediancross/i and do { $error = GFL::gflMedianCross( $img, $trans, $value); last FILTERSW};
			_free($trans);
			return $self->_throw_error($error_stack. "unknown filter: $filter");
		}
		if ($error == $GFL::GFL_NO_ERROR)
		{
			print STDERR "OK for $filter $value".($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
			$self->_set_curbitmap($trans);
			$self->_purge_undo();
		}
		else
		{
			$error_stack .= ($self->_check_error($error))[1];
		}
		_free($trans);
	}
	return ($error_stack)?$self->_throw_error($error_stack): $self->_check_error;
}

=head2 $o->ChangeDepth( new_depth )

Change the color depth of current working bitmap.

new_depth is one of:

	binary, 4g, 8g, 16g, 32g, 64g, 128g, 216g,
	256g, 8, 16, 32, 64, 128, 216, 256 ,truecolors

Values containing a "g" like "32g" mean greyscale.

If the C<dither> attribute is set (boolean), then image is dithered with Adaptative algorithm.

If, additionaly, wanted colordepth is 'binary', then dither will read the C<binarydither>
attribute and use the corresponding algorithm.

=cut


sub changedepth
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	my $depth = shift;
	exists $col_depth{lc($depth)} or	croak ("usage: colordepth(new_depth)\n
		Where new_depth is one of:
		binary, 4g, 8g, 16g, 32g, 64g, 128g, 216g,
		256g, 8, 16, 32, 64, 128, 216, 256 ,truecolors\n");
	my $dither;
	my $mode = $col_depth{lc($depth)};
	if($self->{'dither'})
	{
		if ($mode == $GFL::GFL_MODE_TO_BINARY)
		{
			$dither = $bin_dither{ $self->{'binarydither'} }
		}
		else
		{
			$dither = $GFL::GFL_MODE_ADAPTIVE;
		}
	}
	else
	{
		$dither = $GFL::GFL_MODE_NO_DITHER;
	}
	my $img = $self-> {'_curbitmap'};
	my $trans = GFL::new_BitmapPtr();
	my $error = GFL::gflChangeColorDepth($img, $trans, $mode, $dither);
	($error==$GFL::GFL_NO_ERROR) and do {
		print STDERR "OK for colordepth $depth".($dither?" with dithermode $dither":"").($self->{'verbose'}>1?" ($self)":"")."\n" if $self->{'verbose'};
		$self->_set_curbitmap($trans);
		$self->_purge_undo();
		};
	return $self->_check_error($error);
}

=head2 $o->LastError

Retrieve the last error message.

=cut

sub lasterror
{
	my $self=shift;
	my $type = ref($self) || croak "Not an object";
	return $self->{'lasterror'}
}


=head1 FUNCTIONS

Those functions aren't really methods : they do not process the object when called from it.
Thus, they don't have error handling as defined in ERROR HANDLING section.
However, if C<getfileinformations(filename)> is called as a method on an object, you may retrieve
an eventual error via C<$obj-E<gt>lasterror>;

getfileinformations() and dumpallformats() are also exported (in lowercase) in your namespace,
so you can use them from scratch.

=head2 GFL::Image->GetFileInformations(filename[,format]) or getfileinformations(filename[,format])

Returns a hash reference containing detailed informations about a given file, or B<false> on error.
If C<format> is not defined, GFL tries to autodetect it.

See also C<FileInformations> attribute.

=cut

sub getfileinformations
{

	my $self=shift;
	my $filename;
	if (ref($self))
	{
		print STDERR "Retrieving file informations for $filename".($self->{'verbose'}>1 ? " (function call)":"")."\n" if $self->{'verbose'};
		$filename=shift or return $self->get('fileinformations');
	}
	else
	{
		$self=~/^GFL::/ or unshift(@_, $self);
		$filename=shift or croak("usage: \$hashref = GFL::Image->GetFileInformations(filename[,format])");
	}
	my $format = shift;
	$format = $format ? GFL::gflGetFormatIndexByName(lc($format)) : -1;
	my $info = GFL::new_FileInformation();
	my $error = GFL::gflGetFileInformation($filename, $format,$info);
	return $info if ($error == $GFL::GFL_NO_ERROR);
	_free($info);
	ref($self) && do{
		(print STDERR "ERROR:\nCouldn't get file informations for $filename".($self->{'verbose'}>1? " (function call)":" ").": ". GFL::gflGetErrorString($error)) if $self->{'verbose'};
		return $self->_check_error($error);
	};
	0;
}

=head2 GFL::Image->enableLZW

If you've got a patent from UNISIS, you may enable LZW compression (this is class wide).
This compression algorithm is used by GIF & TIFF formats.

Always the same sad story...

=cut

sub enablelzw
{
	my $self=shift;
	GFL::gflEnableLZW(1);
	1;
}

=head2 GFL::Image->DumpAllFormats or dumpallformats()

Issue the complete list of supported formats with description and Read/Write flag.

=cut

sub dumpallformats
{
	my $self=shift;
	my $num = GFL::gflGetNumberOfFormat();
	my %formats;
	print STDERR " There are $num formats available (GFL v.".GFL::gflGetVersion()." - LibFormat v.".GFL::gflGetVersionOfLibformat().")\n\n";
	for (my $i=0; $i<$num; $i++)
	{
		$formats{GFL::gflGetFormatNameByIndex($i)} = "R: ".(GFL::gflFormatIsReadableByIndex($i)?"*":"-") . " W: ".(GFL::gflFormatIsWritableByIndex($i)?"*":"-")."\t".GFL::gflGetFormatDescriptionByIndex($i)."\n";
	}
	for (sort keys %formats)
	{
		print STDERR $_. "\t\t" . $formats{$_};
	}
	ref($self) and return $self->_check_error($GFL::GFL_NO_ERROR);
}

sub undo
{
	my $self = shift;
	my $type = ref($self) || croak "Not an object";
	$self-> _flush_lasterror;
	return $self->_throw_error("No stack. Can't undo") unless (scalar @{$self->{'_bitmaps'}});
	$self->{'verbose'} and print STDERR "Reverting last change".($self->{'verbose'}>1?" on object $self\n":"\n");
	GFL::gflFreeBitmap($self->{'_curbitmap'});
	$self->{'_curbitmap'} =	pop @{$self->{'_bitmaps'}};
	wantarray ? (0,'OK'):1;
}

sub _set_curbitmap
{
	my $self=shift;
	my $bitmap = shift;
	push @{$self-> {'_bitmaps'}}, $self->{'_curbitmap'} if ref($self->{'_curbitmap'});
	$self->{'_curbitmap'} =  GFL::addr_of_Bitmap($bitmap);
}

sub _purge_undo
{
	my $self=shift;
	while (scalar(@{$self->{'_bitmaps'}}) > ($self->{'undolevel'}))
	{
		my $img = shift(@{$self->{'_bitmaps'}});
		$self->{'verbose'}>2 and print STDERR "\t- Flushing old undo $img on object $self\n";
		GFL::gflFreeBitmap($_);
	}
	1;
}

sub _check_error
{
	my $self=shift;
	my $error = shift;
	$error eq '' and do {
		$self->{'lasterror'} or return wantarray ? (0,'OK'):1;
		$self->{'verbose'} and print STDERR ($self->{'verbose'}>1?"$self report an ":"")."ERROR: ".$self->{'lasterror'}."\n";
		return wantarray ? (1, $self->{'lasterror'}):0;
	};
	if ($error == $GFL::GFL_NO_ERROR)
	{
		$self->{'lasterror'} = '';
		return wantarray ? (0,'OK'):1;
	}
	$self->{'lasterror'} = GFL::gflGetErrorString($error);
	$self->{'verbose'} and print STDERR ($self->{'verbose'}>1?"$self report an ":"")."ERROR: ".$self->{'lasterror'}."\n";
	return  wantarray ?
		(1, $self->{'lasterror'}) : 0;
}

sub _throw_error
{
	my $self = shift;
	$self->{'lasterror'} = shift;
	$self->{'verbose'} and print STDERR ($self->{'verbose'}>1?"$self report an ":"")."ERROR: ".$self->{'lasterror'}."\n";
	return wantarray ? (1, $self->{'lasterror'}):0;
}

sub _append_error
{
	my $self = shift;
	$self->{'lasterror'} .= "\n". shift;
	1;
}

sub _flush_lasterror
{
	my $self=shift;
	$self->{'lasterror'} &&= '';
}

sub _free {
	# free a previously allocated (via GFL::new_*) pointer or struct
	# this is gore SWIG stuff. See "libgfl.i", the SWIG interface file for libgfl.h
	foreach my $ptr(@_)
	{
		bless($ptr, "GFL_MEMALLOCPtr");
		GFL::free_GflStruct($ptr);
	}
}

sub _round
{

}

sub DESTROY {
	my $self=shift or return;
	ref($self->{'_loadparams'}) and do {
		$self->{'verbose'}>2 and print STDERR "\t- Cleaning LoadParams struct $_ from object $self\n";
		_free ($self->{'_loadparams'});
	};
	ref($self->{'_saveparams'}) and do {
		$self->{'verbose'}>2 and print STDERR "\t- Cleaning SaveParams struct $_ from object $self\n";
		_free ($self->{'_saveparams'});
	};
	ref($self->{'_curbitmap'}) and do {
		$self->{'verbose'}>2 and print STDERR "\t- Cleaning image $_ from object $self\n";
		GFL::gflFreeBitmap($self->{'_curbitmap'});
	};
	foreach (@{$self->{'_bitmaps'}})
	{
		$self->{'verbose'}>2 and print STDERR "\t- Cleaning undo $_ from object $self\n";
		GFL::gflFreeBitmap($_);
	}
}

sub AUTOLOAD
{
	### case insensitivity for method calls
	my $func;
	($func = $AUTOLOAD) =~ s/(.*::)(.*)/$1.lc($2)/e && do
	{
		goto &$func unless $func eq $AUTOLOAD;
	};
	die "Undefined subroutine $AUTOLOAD\n";
}

=head1 ERROR HANDLING

Well, TIMTOWTDI...

To begin with, all methods except B<get()> bring back a status report which is different
in LIST and SCALAR context.

=over 2

=item *

Error reporting in LIST context

Here, you are testing for I<error>. You get a list with two values :

- first value is B<true> if the function B<failed>, false otherwise.

- second value is either an error string or the string C<'OK'>

e.g:

	@error = $a -> rotate(100);
	if ($error[0])
	{
		print STDERR $error[1];
	}

=item *

Error reporting in SCALAR context

Here, you are testing for I<Success>.
You get B<true> if the method B<succeeded>, false otherwise.

e.g:

	$a-> rotate(100) && $success++;


=item *

error reporting via B<LastError> attribute

In either SCALAR or LIST context, the B<LastError> attribute is always updated with
false or an error message after a method call.

As using C<get()> would also affect C<lasterror>, you must retrieve it via the special accessor C<-E<gt>lasterror>.

Thus, you can say:

	$b = $a -> get('dither');
	$errormsg = $a ->lasterror and print "couldn't get dither value : $errormsg\n";

=item *

error reporting on STDERR

See the L<Verbose> attribute if you want reports on STDERR.

=back

=head1 COPYRIGHT

copyright 2001
Germain Garand (germain@ebooksfrance.com)

This wrapper is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

GD(3), Image::Magick(3)

=cut

1;
