package Image::Magick::NFPADiamond;

use 5.00;
use strict "vars";
use strict "subs";
use Image::Magick;

our $VERSION = '1.00';

=head1 Name

Image::Magick::NFPADiamond - This module renders a NFPA diamond using ImageMagick

=head1 Synopsis

   use Image::Magick::NFPADiamond;

   my $diamond=Image::Magick::NFPADiamond->new(red=>3, blue=>0, yellow=>1);
   $diamond->save('warning.jpg');

=head1 Description

This module composes a NFPA diamond or I<fire diamond> image using ImageMagick perl module.

=head1 Methods

=head2 Image::Magick::NFPADiamond::new()


The constructor takes a series of arguments in a hash notation style, none of wich are mandatory:

=over

=item red

=item blue

=item yellow

The values to appear inside the red, yellow and blud diamonds. Should be a number, but any string would do.

=item white

The text to appear inside the white diamond. Any string would do. A C<-W-> has a special meaning and produces
a strikethrough W to signal a hazardous material that shouln't be mixed with water. C<JackDaniels> is a synonim for this.

=item size

The size of the resulting image expressed as a single integer. The resulting image is always a square of size x size. 
If this argument is missing, a size of 320 is assumed.

=back

=head2 save([I<file>])

The save() method writes the image to a specified argument. The argument may be a filename, but anything acceptable by
ImageMagick should work.

=head2 response([I<format>])

The response method() writes the image to STDOUT. This is usefull for a CGI implementation (see the sample below).
The argument is a ImageMagick format argument (like 'jpg','gif','png', etc).

=head2 handle()

Returns the underlying Magick image so it can be used as an element to another one

=head1 Restrictions

The diamond generation is done according to the following diagram:

=for html <img src="blueprint.jpg">

All 4 text are scaled the same, based on the 'AAAA' string on 24px
as a seed. This should cover strings like 'ALK', 'ACID'. A longer text will overlap.

The red and blue regions are colored using the ImageMagick provided 'red' and 'yellow' colors.
The blue region is '#0063FF' to get a lighter tone.

=head1 Sample

This script works both with PerlEx and Apache

	#!perl

	#This Perl script will produce a dynamic NFPA alike diamond
	use strict "vars";
	use strict "subs";

	use CGI;
	use Image::Magick::NFPADiamond;

	my $request=new CGI;

    #Using $request->Vars allows for a query_string like 'red=1&blue=2' to work
	my $img=Image::Magick::NFPADiamond->new($request->Vars) || die "Fail\n";

	print $request->header(-type=> "image/jpeg",  -expires=>'+3d');
	binmode STDOUT;
    $img->response('jpg');

=head1 See Also

L<http://www.imagemagick.org/script/perl-magick.php>, the PerlMagick man page.

=head1 AUTHOR

Erich Strelow <estrelow@ceresita.cl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Erich Strelow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 Disclaimer

This module is provided "as is". This is in no way a sanctioned nor official nor verified version of the NFPA standard.


=cut

sub new() {
	my $class=shift();
	my %params=@_;
    
	my $size;

	if (exists $params{size}) {
		$size=$params{size};
	} else {
		$size=320; #Default for size
	}

    my $canvas=Image::Magick->new(size => $size.'x'.$size);
	$canvas->Read('xc:white');

	my $self={canvas => $canvas, size=>$size};
	bless ($self,$class);
	$self->_doit();

	#Using "AAAA" as the seed to get the text metrics
	my @metrics = $canvas->QueryFontMetrics(family=>'Arial', text => "AAAA", stroke=> 'black',  align=>'Center', pointsize=>24);
	my $scale=($size/4/$metrics[4]).','.($size/4/$metrics[1]);
    
	$canvas->Annotate(family=>'Arial',scale => $scale, text => $params{red}, x => $size/2, y => $size*3/8,stroke=> 'black',  align=>'Center', pointsize=>24)
       if exists $params{red};

	$canvas->Annotate(family=>'Arial',scale => $scale, text => $params{blue}, x => $size/4, y => $size*5/8,stroke=> 'black',  align=>'Center', pointsize=>24)
       if exists $params{blue};

    $canvas->Annotate(family=>'Arial',scale => $scale, text => $params{yellow}, x => $size*3/4, y => $size*5/8,stroke=> 'black',  align=>'Center', pointsize=>24)
       if exists $params{yellow};

    if ($params{white} =~ /-W-|JackDaniels/) {
        #Setting up the no-water sign
        $canvas->Annotate(family=>'Arial',scale => $scale,  text => "W", x => $size/2, y => $size*7/8,stroke=> 'black',  align=>'Center', pointsize=>24);
		
		#Don't have a clue how to render a strikethrough font, I crafty place a line over the W
		$canvas->Draw(primitive =>'line', points=> ($size*3/8).','.($size*6.4/8).' '.($size*5/8).','.($size*6.4/8), stroke=> 'black', strokewidth => (8*$size/400));
    } else {
       $canvas->Annotate(family=>'Arial',scale => $scale,  text => $params{white}, x => $size/2, y => $size*7/8,stroke=> 'black',  align=>'Center', pointsize=>24)
          if exists $params{white};
    }
	return $self;
}

sub handle() { return shift()->{canvas}; }

sub _diamond() {
	my $self=shift();
	my $x=shift();
	my $y=shift();
	my $fill=shift();
    my $w=shift();

	my $p=($x + $w/2).','.$y.' '.
	    $x.','.($y + $w/2).' '.
		($x + $w/2).','.($y + $w).' '.
		($x + $w).','.($y+$w/2).' '.
		($x + $w/2).','.$y
	;
	$x=$self->{canvas}->Draw(primitive => 'polyline', points => $p,fill => $fill, stroke=>'black');
    print $x if ($x); 
}

sub _doit($)
{
	my $self=shift();
	my $s=$self->{size};
	$self->_diamond($s/4,0,'red', $s/2);
	$self->_diamond(0,$s/4,'#0063FF', $s/2);
	$self->_diamond($s/2,$s/4,'yellow', $s/2);

	$self->_diamond(0,0,'none',$s);
}


sub response() {
	
	my $self=shift();
	my $format='jpg';
	if (@_) {
		$format=shift();
	}
	#For some reason, I can't get a simple save to "-" to work on this
	my @blob = $self->handle()->ImageToBlob(magick=>$format);

	for ( @blob) {
	   print;
	}
}

sub save() {
	my $self=shift();
    my $file=shift();
	return $self->{canvas}->Write($file);

}
1;
