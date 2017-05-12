package Image::Magick::Thumbnail::PDF;
use strict;
use Carp;
require Exporter;
use File::Which;

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
$VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /(\d+)/g;

@ISA = qw(Exporter);
@EXPORT_OK = qw(create_thumbnail);
%EXPORT_TAGS = (
	all => \@EXPORT_OK,
);


$Image::Magick::Thumbnail::PDF::DEBUG = 0;
sub DEBUG : lvalue { $Image::Magick::Thumbnail::PDF::DEBUG }

sub create_thumbnail {

	# BEGIN GET PARAMS
	print STDERR __PACKAGE__."::create_thumbnail() DEBUG ON\ngetting arguments\n" if DEBUG;
	
	my ($abs_pdf,$abs_out,$page_number,$arg,$all);
	$abs_pdf = shift; $abs_pdf or croak(__PACKAGE__."::create_thumbnail() missing abs pdf argument");
	

	my $name_of_outfile_in_arguments=0;
	
	for (@_){
		my $val = $_;
		print " val [$val]\n" if DEBUG;

		if (ref $val eq 'HASH'){
			$arg = $val; print STDERR " got args hash ref\n" if DEBUG;
		}
		elsif ($val=~/^\d+$/){
			$page_number = $val; print STDERR " got page number $val\n" if DEBUG;			
		}		
		elsif ($val eq 'all_pages'){
			$all=1; print STDERR " got flag to do all pages\n" if DEBUG;
		}
		elsif ($val=~/[^\/]+\.\w{2,4}$/){
			$abs_out = $val; print STDERR " got abs out [$val]\n" if DEBUG;
			$name_of_outfile_in_arguments=1;
		}
		else { croak(__PACKAGE__."::create_thumbnail() bogus argument [$val]"); }	
	}

	$arg ||={};
	$arg->{restriction} ||= 125;
	unless( defined $arg->{frame} ){ $arg->{frame} = 6; print STDERR " frame defauls to $$arg{frame}\n" if DEBUG; }
	unless( defined $arg->{normalize}){ $arg->{normalize} = 1; print STDERR " normalize defauls to $$arg{normalize}\n" if DEBUG;  }


	# if we are putting a border, we still want the restriction asked for to be obeyed
	if ($arg->{frame}){
		$arg->{restriction} = ($arg->{restriction} - ($arg->{frame}  * 2) );
	}
	
	$all ||= 0;
	$page_number ||= 1;
		
	unless( $name_of_outfile_in_arguments ){		
		$abs_out = $abs_pdf; 
		$abs_out=~s/\.\w{3,5}$/\.png/;	
		print STDERR " abs out destination path should be: $abs_out\n" if DEBUG;		
	}
	

	$arg->{frame}=~/^\d+$/ or croak(__PACKAGE__."::create_thumbnail() argument 'frame' is not a number");

	$arg->{restriction}=~/^\d+$/ or 
		croak(__PACKAGE__."::create_thumbnail() argument 'restriction' is not a number");

	if (DEBUG){ 
		printf STDERR __PACKAGE__."::create_thumbnail() debug.. \n";
		printf STDERR " abs_pdf %s\n page_number %s\n abs_out %s, all? %s\n", $abs_pdf, $page_number, $abs_out, $all;
		### $arg
	}

	# END GET PARAMS









	require Image::Magick::Thumbnail;

	my $src = new Image::Magick;
	my $err = $src->Read($abs_pdf);#	warn("92 ++++ $err") if $err;
	print STDERR "ok read $abs_pdf\n" if DEBUG;
	
	
	if (!$all){
		# not all pages
			my $image = $src->[($page_number-1)];
			defined $image or warn("file [$abs_pdf] page number [$page_number] does not exist?") and return;
			my $out = _dopage($image,$abs_out,$page_number,$arg,$name_of_outfile_in_arguments);		
			return $out;
		}
	else {
			print STDERR "Do all pages\n" if DEBUG;
			my $pagenum = 1;
			my @outs;
			for ( @$src ){			
				my $out = _dopage($_,$abs_out,$pagenum,$arg);
				push @outs, $out;
				$pagenum++;
			}
			return \@outs;
	}



	sub _dopage {
			my ($image,$abs_out,$pagenum,$arg,$name_of_outfile_in_arguments) = @_;
			$pagenum = sprintf "%03d", $pagenum;
			print STDERR " _dopage() $pagenum " if DEBUG;
			
			unless( $name_of_outfile_in_arguments ){
				$abs_out=~s/(\.\w{3,5})$/-$pagenum$1/;
			}

			if ( $arg->{normalize} ){
				my $step = $arg->{restriction} * 2;	
				my ($i,$x,$y) = Image::Magick::Thumbnail::create($image,$step);
				$i->Normalize;
				$image = $i;
				print STDERR ' (normalized) ' if DEBUG;
			}

			if ($arg->{quality}){
				print STDERR " (quality $$arg{quality}) " if DEBUG;
				$image->Set( quality => $arg->{quality} );
			}

			
			my($thumb,$x,$y) = Image::Magick::Thumbnail::create($image,$arg->{restriction});

			if ($arg->{frame}){
				$image->Frame($arg->{frame}.'x'.$arg->{frame});
				print STDERR " (framed $$arg{frame}) " if DEBUG;
			}

			my $err= $thumb->Write($abs_out); #warn("141 +++ $err") if $err;

			print STDERR "$abs_out\n" if DEBUG;
			return $abs_out;		
	}

}




1;

__END__

=pod

=head1 NAME

Image::Magick::Thumbnail::PDF - make thumbnail of a page in a pdf document

=head1 SYNOPSIS

	use Image::Magick::Thumbnail::PDF 'create_thumbnail';
   
	my $out = create_thumbnail('/home/myself/mypdfile.pdf');
	
=head1 DESCRIPTION

I wanted a quick sub to make a thumbnail of a pdf.
The goal of this module is to make a quick thumbnail of a page in a pdf.

They give the viewer an idea of what is inside the document, but is not meant as a replacement
for the actual file.

This module is a quick interface to a predetermined use of convert.
There are a ton of ways to do this via ImageMagick and convert, etc. I took what seemed to make most
sense from various suggestions/ideas, and slapped this together. If you think something can be 
better, please contact the L<AUTHOR>.

No subroutines are exported by default.

You must import as:

	use Image::Magick::Thumbnail::PDF 'create_thumbnail';
   
	my $abs_thumb = create_thumbnail('/abs/path/to.pdf');
	
Or you can do this also:

	Image::Magick::Thumbnail::PDF;
	
	my $abs_thumb = Image::Magick::Thumbnail::PDF::create_thumbnail('/abs/path/to.pdf');

The second example is a lot of text but improves legibility in a lot of code.

By default this will make a normalized thumbnail with a 6 pixel light grey border, 125 pixel max height
and 125 pixel max width png image, which in the above example returns '/abs/path/to-001.pdf'.

The subroutine create_thumbnail() takes 1 required argument and optionally 4 arguments in any order.
The first argument must always be the pdf file you want to make a thumbnail of.

=head1 create_thumbnail()

=head2 First Argument, Absolute Path to PDF file

Absolute path to the pdf you want to make a thumbnail for. 
Required. This is the only required argument.
Will not check if the thumbnail exists already or not.

=head2 Second Argument, Absolute Path to Thumbnail destination.

Absolute path you want the thumbnail to be output to (the destination). 
Optional.
By default, it is the same as the first argument but the .pdf is replaced with a .png extension.

=head2 Third Argument, Page Number

A page number. 
Optional.
Default is page 1. There is no page 0. 
Furthermore, if instead of a number you providing the string 'all_pages', will trigger to make a 
thumbnail of each page and return an array ref with absolute paths to each thumbnail.

=head2 Fourth Argument, Output Options

Hash ref. 
Optional.
Hash ref with one or more of the following keys and values:

=over 4

=item normalize

Boolean.
Default is true. 
This increases contrast and makes thin lines appear thicker.

=item frame

Number.
Default is 6.
Places light grey frame border around the image.

=item restriction

Number.
Default is 125.
This is the maximum pixels tall and wide the thumbnail will be. 
Regardless of what the frame is set to, your thumbnail will fall within these dimensions.
If you pass false, it will default to 125.

=item quality

Number.
This will set JPEG/MIFF/PNG compression level.
No default set- if no value is set, this is not performed.
If your thumbnails occupy too much space, you may want to use this.
This only really worls well with jpg.

=back

=head2 Return Value

If you are making one thumbnail: Returns absolute path of the thumbnail made.

If you are making all pages: Returns array ref with absolute paths of all thumbnails made.

=head2 Errors

If the subroutine is provided really dumb arguments, it croaks.
Otherwise it carps and returns undef on failures.

=head1 EXAMPLES

The following example creates /abs/file-000.png 125x125 thumbnail image of first page.

	create_thumbnail('/abs/file.pdf');

To create a thumb for page 5 instead:
	
	create_thumbnail('/abs/file.pdf',5); # creates '/abs/file-005.png'

To create a thumb for page 6 with restriction 200, a frame of 2 px, and no normalize:

	create_thumbnail(
		'/abs/file.pdf',
		6,
		{ 
			restriction => 200, 
			frame => 2, 
			normalize => 0,
		},
	); # creates '/abs/file-006.png' 

To save a thumbnail of page 3 named differently, in another palce

	create_thumbnail(
		'/abs/file.pdf',
		'/abs/another/page3.png',
		3,
		{ 
			restriction => 200, 
			frame => 2, 
			normalize => 0 
		},
	); # creates '/abs/file-006.png' 

To make all thumbnails of all pages:

	my $all = create_thumbnail('/abs/file.pdf','all_pages');

	# $all = [ '/abs/file-001.png',  '/abs/file-002.png',  '/abs/file-003.png' ];

A default thumbnail is about 3k, If you ask to output a jpg and set quality to 30,
you get a low quality 0.9 k image:

	my $out = create_thumbnail('/abs/file.pdf','/abs/file.jpg', { quality => 30 });


Ok, you don't like having file-002.png as a thumbnail name.. You want file_page2.png :

	my $out = create_thumbnail('/abs/file.pdf',2,'/abs/file_page2.png');

Beware! The following examples fo NOT make a thumbnail of page 2 :

	create_thumbnail('/abs/file.pdf','/abs/file_page2.png');
	create_thumbnail('/abs/file.pdf',3,'/abs/file_page2.png');

Remember that to make a thumbnail of ANY page other then page 1, you must specify 'all_pages' 
or pass a number as argument.

=head1 A note on 'normalize' and 'border'

These options are provided because a lot of pdfs are hard copy documents scanned in and turned into pdf.
This kind of document is by and large (by the thousands of documents I see fly by our network) very popular,
and usually white paper space with scant black text. When it sizes down, you see nothing! 
So, by I<default>,
normalize is set to true, and a 6 pixel light grey border is added to the thumbnail. This is a dramatic improvement
for thumbnails of such documents.

Normalize is used to accentuate lines. This creates an extra step in the process, the image is sized
down about halfway between the target size and the original size, the filter is applied, and then resized down
again. So- if you do or do not use normalize (on by default) you will see a large change in time taken.

In the following example, turn normalize to false and the frame border to nothing;

	create_thumbnail('/path/to/my.pdf',{ normalize => 0, frame => 0 });

I B<strongly> encourage to try the defaults first. 


=head1 A note on making all thumbnails

This can be slow! This can be useful offline, but I don't suggest it real-time. If this is being used in some cgi,
consider forking. You try it out.

The following example makes all thumbnails:

	my $all = create_thumbnail('/abs/file.pdf','all_pages');

The returned value is an array ref holding ['/abs/file-001.png',  '/abs/file-002.png',  '/abs/file-003.png'].


=head1 TODO

GIF spit out all thumbs of all pages into one gif.
NOT IMPLEMENTED presently.

The following example makes '/abs/file.gif', which is an animated gif with heach frame being a page in the document.

	create_thumbnail('/abs/file.pdf','all_pages','/abs/file.gif');

=head1 GIF OUTPUT

If you make all thumbnails and specify as output a .gif file, the output image is an animated gif, with 
each page in its own frame. This may or may not be what you desire.

=head1 DEBUG

Note that if you enable debugger 

	$Image::Magick::Thumbnail::PDF::DEBUG = 1;

You will see that a restriction of 125 changes to 113.. how come? Because we compensate for the frame size.
Asking for a thumbnail no wider or taller then 125 px gives you just that. 

=head1 NOTES

The arguments can be provided in any order. I read somewhere that good code is liberal in what it
receives as input and conservative in its output- kind of what 'people' should be like.

=head1 CAVEATS

There are three ghostscripts out there, ESP Ghostscript, AFPL Ghostscript, and GNU Ghostscript.

=head1 PREREQUISITES

Image::Magick 
Image::Magick::Thumbnail
Smart::Comments
File::Which
Carp
ESP Ghostscript, NOT AFPL Ghostscript, this is tested for.

=head1 SEE ALSO

ImageMagick on the web, convert.
L<Image::Magick::Thumbnail>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.
   
=cut

