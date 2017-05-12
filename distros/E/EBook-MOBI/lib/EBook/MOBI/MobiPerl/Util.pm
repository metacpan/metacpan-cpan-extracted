package EBook::MOBI::MobiPerl::Util;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/Util.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

BEGIN {
    # Optionally load GD
    eval 'require GD';
}

use strict;

our $VERSION = 2011.11.26;

use Module::Loaded;
use Image::BMP;
use Image::Size;
use File::Copy;
use File::Spec;

use HTML::TreeBuilder;

my $rescale_large_images = 0;


sub is_cover_image {
    my $file = shift;

    die 'ERROR: GD not available ' unless is_loaded('GD');

    my $res = 0;
    if (not -e "$file") {
	die "ERROR: File does not exist: $file";
    }
    my $p = new GD::Image ($file);
    if (not defined $p) {
	print STDERR "Could not read image file: $file\n";
	return $res;
    }
    my ($x, $y) = $p->getBounds();
#    my $x = $p->width;
#    my $y = $p->height;
    if ($x == 510 and $y == 680) {
	print STDERR "GUESSING COVERIMAGE: $file\n";
	$res = 1;
    }
    if ($x == 600 and $y == 800) {
	print STDERR "GUESSING COVERIMAGE: $file\n";
	$res = 1;
    }
    return $res;
}

#
# OPF related functions
#

sub get_tree_from_opf {
    my $file = shift;
    my $config = shift;
    my $linksinfo = shift;

#    my ($vol,$dir,$basefile) = File::Spec->splitpath ($file);
#    print STDERR "OPFFILE: $vol - $dir - $basefile\n";

    my $opf = new MobiPerl::Opf ($file);
    my $tochref = $opf->get_toc_href ();
    my @opf_spine_ids = $opf->get_spine_ids ();
    my @opf_manifest_ids = $opf->get_manifest_ids ();
    my $title = $opf->get_title ();
    print STDERR "OPFTITLE: $title\n";
    if ($config->title ()) {
	$title = $config->title ();
    }
    $title = $config->prefix_title () . $title;
    $config->title ($title);

    my $author = $opf->get_author ();
    print STDERR "OPFAUTHOR: $author\n";
    if (not $config->author ()) {
	$config->author ($author);
    }



    #
    # If cover image not assigned search all files in current dir
    # and see if some file is a coverimage
    #
    
    my $coverimage = $opf->get_cover_image ();
    if ($coverimage eq "") {
	opendir DIR, ".";
	my @files = readdir (DIR);
	foreach my $f (@files) {
	    if ($f =~ /\.jpg/ or 
		$f =~ /\.JPG/ or 
		$f =~ /\.gif/) {
#		print STDERR "Checking if file is coverimage: $f\n";
		if (MobiPerl::Util::is_cover_image ($f)) {
		    $coverimage = $f;
		}
	    }
	}
    }
    print STDERR "Coverimage: $coverimage\n";

    my $html = HTML::Element->new('html');
    my $head = HTML::Element->new('head');

    #
    # Generate guide tag, specific for Mobipocket and is
    # not understood by HTML::TreeBuilder...
    #

    
    my $guide = HTML::Element->new('guide');
    if ($tochref) {
	print STDERR "Util.pm: GENERATE GUIDE SECTION: $tochref\n";
	my $tocref = HTML::Element->new('reference', 
					title=>"Table of Contents",
					type=>"toc",
					href=>"\#$tochref");
	$guide->push_content ($tocref);
    }

    if ($config->add_cover_link ()) {
	print STDERR "Util.pm: GENERATE GUIDE SECTION ADDCOVVERLINK\n";
	my $coverref = HTML::Element->new('reference', 
					  title=>"Cover",
					  type=>"cover",
					  href=>"\#addedcoverlink");
	$guide->push_content ($coverref);
    }
    $head->push_content ($guide);

    my $titleel = HTML::Element->new('title');
    $titleel->push_content ($title);
    $head->push_content ($titleel);

    #
    # Generate body
    #

    my $body = HTML::Element->new('body');

#				  topmargin => "0",
#				  leftmargin => "0",
#				  bottommargin => "0",
#				  rightmargin => "0");


    my $coverp = HTML::Element->new('p', 
				    id=>"addedcoverlink",
				    align=>"center");
    my $coverimageel = HTML::Element->new('a', 
					  onclick => 
					  "document.goto_page_relative(1)");
    $coverp->push_content ($coverimageel);

    if ($config->add_cover_link ()) {
	$body->push_content ($coverp);
	$body->push_content (HTML::Element->new('mbp:pagebreak'));
    }

#<p align="center"><a onclick="document.goto_page_relative(1)"><img src="pda_cover.gif" hisrc="pc_cover.gif" /></a></p>

    #
    # Add TOC first also if --tocfirst
    #
    if ($tochref and $config->toc_first ()) {
	print STDERR "ADDING TOC FIRST ALSO: $tochref\n";
	my $tree = new HTML::TreeBuilder ();
	$tree->ignore_unknown (0);
	$tree->parse_file ($tochref) || die "1-Could not find file: $tochref\n";
###	check_for_links ($tree);
	$linksinfo->check_for_links ($tree);
	my $b = $tree->find ("body");
	$body->push_content ($b->content_list());
	$body->push_content (HTML::Element->new('mbp:pagebreak'));
    }


    #
    # All files in manifest
    #

    foreach my $id (@opf_spine_ids) {
	my $filename = $opf->get_href ($id);
	my $mediatype = $opf->get_media_type ($id);

	print STDERR "SPINE: adding $id - $filename - $mediatype\n";

	next unless ($mediatype =~ /text/); # only include text content

	my $tree = new HTML::TreeBuilder ();
	$tree->ignore_unknown (0);

	open FILE, "<$filename" or die "2-Could not find file: $filename\n";
	{
	    local $/;
	    my $content = <FILE>;
	    $content =~ s/&\#226;&\#8364;&\#166;/&\#8230;/g;
	    # fixes bug in coding
	    $tree->parse ($content);
	    $tree->eof();
	}

	if ($config->{FIXHTMLBR}) {
	    fix_html_br ($tree, $config);
	}

	$linksinfo->check_for_links ($tree);

	print STDERR "Adding: $filename - $id\n";

#	print STDERR "FILETOLINKCHECK:$filename:\n";
	if ($linksinfo->link_exists ($filename)) {
#	    print STDERR "FILETOLINKCHECK:$filename: SUCCESS\n";
	    my $a = HTML::Element->new('a', name => $filename);
	    $body->push_content ($a);
	}
	print STDERR "+";
	my $b = $tree->find ("body");
	print STDERR "+";
	my @content = $b->content_list();
	print STDERR "+";
	foreach my $c (@content) {
	    $body->push_content ($c);
#	    print STDERR $c;
	    print STDERR ".";
	}
	print STDERR "+";
    }
    print STDERR "All spine elements have been added\n";

    if ($config->cover_image ()) {
	$coverimage = $config->cover_image ();
    }

    if ($coverimage) {
	copy ("../$coverimage", $coverimage); # copy if specified --coverimage
	$linksinfo->add_cover_image ($coverimage);
	if ($config->add_cover_link ()) {
	    my $el = HTML::Element->new ('img', src => "$coverimage");
	    $coverimageel->push_content ($el);
	    $linksinfo->check_for_links ($coverimageel);
	}
    }

    if ($config->thumb_image ()) {
	$linksinfo->add_thumb_image ($config->thumb_image ());
    } else {
	if ($coverimage) {
	    $linksinfo->add_thumb_image ($coverimage);
	}
    }

    #
    #  Fix anchor to positions given by id="III"...
    #
    # filepos="0000057579"
    #

    my @refs = $body->look_down ("href", qr/^\#/);
    push @refs, $head->look_down ("href", qr/^\#/);
    my @hrefs = ();
    my @refels = ();
    my %href_to_ref = ();
    foreach my $r (@refs) {
	$r->attr ("filepos", "0000000000");
	my $key = $r->attr ("href");
	$key =~ s/\#//g;
	push @hrefs, $key;
	push @refels, $r;
#	$r->attr ("href", undef);
    }

    $html->push_content ($head);
    $html->push_content ($body);
    my $data = $html->as_HTML ();
    foreach my $i (0..$#hrefs) {
	my $h = $hrefs[$i];
	my $r = $refels[$i];
	my $searchfor1 = "id=\"$h\"";
	my $searchfor2 = "<a name=\"$h\"";
	
###	print STDERR "SEARCHFOR1: $searchfor1\n";
	my $pos = index ($data, $searchfor1);
	if ($pos >= 0) {
	    #
	    # search backwards for <
	    #
	    
	    while (substr ($data, $pos, 1) ne "<") {
		$pos--;
	    }

##	    $pos -=4; # back 4 positions to get to <h2 id=
	    my $form = "0" x (10-length($pos)) . "$pos";
	    print STDERR "POSITION: $pos - $searchfor1 - $form\n";
	    $r->attr ("filepos", "$form");
	} else {
###	    print STDERR "SEARCHFOR2: $searchfor2\n";
	    $pos = index ($data, $searchfor2);
	    if ($pos >= 0) {
		my $form = "0" x (10-length($pos)) . "$pos";
###		print STDERR "POSITION: $pos - $searchfor2 - $form\n";
		$r->attr ("filepos", "$form");
	    } else {
	    }
	}
    }
    

#    my @anchors = $body->look_down ("id", qr/./);
#    foreach my $a (@anchors) {
#	my $name = $a->attr("id");
#	my $tag = $a->tag ();
#	my $text = $a->as_trimmed_text ();
#	if ($link_exists{$name}) {
#	    $a->delete_content ();
#	    my $ael = HTML::Element->new('a', name => $name);
#	    $ael->push_content ($text);
#	    $a->push_content ($ael);
#	}
#	print STDERR "ANCHORS: $tag - $name - $text\n";
#    }



#    $html->push_content ($head);
#    $html->push_content ($body);
    return $html;
}


#
# lit file functons
#

sub unpack_lit_file {
    my $litfile = shift;
    my $unpackdir = shift;

    print STDERR "Unpack file $litfile in dir $unpackdir\n";

    mkdir $unpackdir;

    opendir DIR, $unpackdir;
    my @files = readdir (DIR);
    foreach my $f (@files) {
	if ($f =~ /^\./) {
	    next;
	}
	if ($f =~ /^\.\./) {
	    next;
	}
#    print STDERR "FILE: $f\n";
	unlink "$unpackdir/$f";
    }

    system ("clit \"$litfile\" $unpackdir") == 0
	or die "system (clit $litfile $unpackdir) failed: $?";

}

sub get_thumb_cover_image_data {
    my $filename = shift;

    die 'ERROR: GD not available ' unless is_loaded('GD');

##    print STDERR "COVERIMAGE: $filename\n";
    my $data = "";

    if (not -e $filename) {
	print STDERR "Image file does not exist: $filename\n";
	return $data;
    }

    my $p = new GD::Image ("$filename");
    my ($x, $y) = $p->getBounds();
#    my $x = $p->width;
#    my $y = $p->height;
##    add_text_to_image ($p, $opt_covertext);

# pdurrant
# Make thumb 320 high and proportional width
# latest Mobipocket Creator makes Thumbnails 320 high
    my $scaled = scale_gd_image ($p, 320/$y);
    print STDERR "Resizing image $x x $y -> $x*320/$y x 320 -> scaled.jpg\n";

#    my $scaled = scale_gd_image ($p, 180, 240);
#    print STDERR "Resizing image $x x $y -> 180 x 240 -> scaled.jpg\n";
    return $scaled->jpeg ();
}

sub scale_gd_image {
    my $im = shift;
    my $x = shift;
    my $y = shift;

    die 'ERROR: GD not available ' unless is_loaded('GD');

    my ($w0, $h0) = $im->getBounds();
#    my $w0 = $im->width;
#    my $h0 = $im->height;
    my $w1 = $w0*$x;
    my $h1 = $h0*$x;
    print STDERR "SCALE GD: $w0 $h0 -> $w1 $h1\n";
    if (defined $y) {
	$w1 = $x;
	$h1 = $y;
    }
    my $res = new GD::Image ($w1, $h1);
    $res->copyResized ($im, 0, 0, 0, 0, $w1, $h1, $w0, $h0);
    return $res;
}


sub get_text_image {
    my $width = shift;
    my $height = shift;
    my $text = shift;
#    my $image = Image::Magick->new;
#    $image->Set(size=>"$width x $height");
#    $image->ReadImage('xc:white');
#    $image->Draw (pen => "red",
#		  primitive => "text",
#		  x => 200,
#		  y => 200,
#		  font => "Bookman-DemiItalic",
#		  text => "QQQQ$text, 200, 200",
#		  fill => "black",
#		  pointsize => 40);
#    $image->Draw(pen => 'red', fill => 'red', primitive => 'rectangle',
#		 points => '20,20 100,100');
#    $image->Write (filename => "draw2.jpg");
}

sub get_gd_image_data {
    my $im = shift;
    my $filename = shift;
    my $quality = shift;

    $quality = -1 if not defined $quality;

    #
    # For some strange reason it does not work if using
    # the gif file with size 600x800
    #

##    if ($filename =~ /\.gif/ or $filename =~ /\.GIF/) {
##	return $im->gif ();
##    }

    if ($quality <= 0) {
	return $im->jpeg ();
    } else {
	return $im->jpeg ($quality);
    }
}

sub add_text_to_image {
    my $im = shift;
    my $text = shift;
    my $x = $im->Get ("width");
    my $y = $im->Get ("height");

    if (defined $text and $text) {
	print STDERR "DRAW TEXT: $text\n";
	my $textim = get_text_image ($x, $y, $text);
	$im->Draw (primitive => "text",
		   text => $text,
		   points => "50,50",
		   fill => "red",
		   pointsize => 72);
    }
    $im->Write (filename => "draw.jpg");

}

sub get_image_data {
    my $filename = shift;
    my $rescale = shift;
    my $config = shift;

    die 'ERROR: GD not available ' unless is_loaded('GD');

    $rescale_large_images = $rescale if defined $rescale;

    my $scale_factor;
    $scale_factor = $config->scale_all_images() if defined $config;

    # pdurrant
    # make maxsize exactly 60KiB

    my $maxsize = 61440;
    $maxsize = $config->get_image_max_bytes () if defined $config;
    print STDERR "GET IMAGE DATA (file - maxsize): $filename - $maxsize\n";

#    my $maxsize = 61000;
    my $maxwidth = 480;
    my $maxheight = 640;

    my $data = "";

    if (not -e $filename) {
	print STDERR "Image file does not exist: $filename\n";
	return $data;
    }

    my $filesize = -s $filename;
    my ($x, $y, $type) = imgsize ($filename);

    print STDERR "Reading data from file: $filename - $x x $y - $type\n";

#    if ($filesize < $maxsize and $x < $maxwidth and $y<$maxheight
#	and $type ne "PNG") {

    # pdurrant
    # do not resize large images if the filesize is OK, 
    # even if pixel dimensions are large
    if ($filesize < $maxsize and 
	((not $rescale_large_images) || ($x <= $maxwidth and $y <= $maxheight))
	and $type ne "PNG"
	and (not defined $scale_factor or $scale_factor == 1.0)) {
	
	# No transformation has to be done, keep data as is
	print STDERR "No transformation: $filename - $x x $y\n";
	open(IMG, $filename) or die "can't open $filename: $!";
	binmode(IMG);       # now DOS won't mangle binary input from GIF
	my $buff;
	while (read(IMG, $buff, 8 * 2**10)) {
	    $data .= $buff;
	}
	return $data;
    }


    my $p = new GD::Image ("$filename");
    if (not defined $p) {
	my $im = new Image::BMP (file => "$filename");
	if (defined $im) {
	    my $w = $im->{Width};
	    my $h = $im->{Height};
	    print STDERR "BMP IMAGE $filename: $w x $h\n";
	    $p = new GD::Image ($w, $h);
	    foreach my $x (0..$w-1) {
		foreach my $y (0..$h-1) {
		    my ($r,$g,$b) = $im->xy_rgb ($x, $y);
		    my $index = $p->colorExact ($r, $g, $b);
		    if ($index == -1) {
			$index = $p->colorAllocate ($r, $g, $b);
		    }
		    $p->setPixel ($x, $y, $index);
		}
	    }
	}
##	open IMAGE, ">dummy-$filename.jpg";
##	print IMAGE $p->jpeg ();
##	close IMAGE;
    }
    ($x, $y) = $p->getBounds(); # reuse of $x and $y...
#    my $x = $p->width;
#    my $y = $p->height;

    #
    # If I do not resize 600x800 images it does not work on Gen3
    #
    # check this one more time, 600x800 gif and jpeg with size
    # less than 64K does not work on Gen3
    #
    # pdurrant
    # as of July 2008, 
    # 600x800 with size less than 61440 does work on Gen3
    # so must use the --imagerescale argument to get 600x800.

    if (defined $scale_factor and $scale_factor != 1.0) {
	print STDERR "SCALE IMAGE: $scale_factor\n";
	$p = MobiPerl::Util::scale_gd_image ($p, $scale_factor);
    }

    if ($rescale_large_images) {
	my $xdiff = $x-$maxwidth;
	my $ydiff = $y-$maxheight;
	if ($ydiff > $xdiff) {
	    if ($y > $maxheight) {
		my $scale = $maxheight*1.0/$y;
		$p = MobiPerl::Util::scale_gd_image ($p, $scale);
	    }
	} else {
	    if ($x > $maxwidth) {
		my $scale = $maxwidth*1.0/$x;
		$p = MobiPerl::Util::scale_gd_image ($p, $scale);
	    }
	}
    }

    #
    #   Scale if scale option given
    #   or does it work just setting width?
    #

  ##  $filename =~ s/\....$/\.gif/;
  ##  print STDERR "UTIL FILENAME: $filename\n";

    my $quality = -1;
    my $size = length (MobiPerl::Util::get_gd_image_data ($p, $filename));

    if ($size > $maxsize) {
	$quality = 100;
	while (length (MobiPerl::Util::get_gd_image_data ($p, $filename, $quality)) >
	       $maxsize and $quality >= 0) {
	    $quality -= 10;
	}
	if ($quality < 0) {
	    die "Could not shrink image file size for $filename";
	}
    } 

##    if ($y < 640 and $x < 480 and defined $opt_scale) {
##	my $scale = $opt_scale;
##	$p = MobiPerl::Util::scale_gd_image ($p, $scale);
##	print STDERR "Rescaling $$scale\n";
##    }


    $data = MobiPerl::Util::get_gd_image_data ($p, $filename, $quality);
    return $data;
}

sub iso2hex($) {
    my $hex = '';
    for (my $i = 0; $i < length($_[0]); $i++) {
	my $ordno = ord substr($_[0], $i, 1);
	$hex .= sprintf("%lx", $ordno);
    }

    $hex =~ s/ $//;;
    $hex = "0x$hex";
    return $hex;
}

sub fix_html {
    my $tree = shift;

    print STDERR "FIX HTML\n";

    #
    # Fix strange HTML code
    #

    my @paras = $tree->find ("p");
    my $inside_para = 0;
    my $newp;
    foreach my $p (@paras) {
	if (not $inside_para) {
	    $newp = HTML::Element->new("p");
	    $inside_para = 1;
	}
	my $html = $p->as_HTML ();
##	print STDERR "$html\n";
	if ($html =~ /\&nbsp\;/) {
##	    print STDERR $newp->as_HTML ();
	    my $h = $newp->as_HTML ();
##	    if ($h =~ /All three Stewards/) {
##		last;
##	    }
	    $p->replace_with ($newp);
	    $inside_para = 0;
	    print STDERR "P";
	} else {
	    my @span = $p->find ("span");
	    foreach my $span (@span) {
		$span->replace_with ($span->content_list ());
	    }
	    $p->normalize_content ();
	    $newp->push_content ($p->content_list ());
	    $newp->push_content (" ");
	    $p->delete ();
	    print STDERR "+";
	}
    }
}

sub fix_html_br {
    my $tree = shift;
    my $config = shift;

    print STDERR "FIX HTML BR\n";

    #
    # Fix strange HTML code with <br /><br /> instead if <p>
    #

    my $b = $tree->find ("body");
    print STDERR "+";
    my @content = $b->content_list();
    print STDERR "+";
    my @paras = ();
    my $p = HTML::Element->new("p");
    push @paras, $p;
    my $i = 0;
    while ($i <= $#content) {
#	print STDERR "-";
	my $c = $content[$i];
	if ($c and ref($c) eq "HTML::Element") {
	    my $tag = $c->tag;
	    if ($tag eq "br" and ref($c) eq "HTML::Element" and
		defined $content[$i+1] and ref ($content[$i+1]) and
		$content[$i+1]->tag eq "br") {
		$p = HTML::Element->new("p");
		push @paras, $p;
		if ($config->{KEEPBR}) {
#		    $p->push_content (HTML::Element->new("br"));
		    $p->push_content (HTML::Element->new("br"));
		}
		$i++;
		if ($i % 10 == 0) {
		    print STDERR "P";
		}
	    } else {
#		print STDERR $c->as_HTML;
		$p->push_content ($c);
	    }
##	    print STDERR "TAG:$tag:\n";
	} else {
	    if (ref($c)) {
#		print STDERR $c->as_HTML;
	    } else {
#		print STDERR $c;
	    }
	    $p->push_content ($c);
	}
	$i++;
    }
    $b->delete_content ();
    $b->push_content (@paras);
}

sub fix_pre_tags {
    my $tree = shift;

    print STDERR "FIX PRE TAGS\n";

    my @pres = $tree->find ("pre");

    foreach my $pre (@pres) {
	print STDERR "FIX PRE TAGS: $pre\n";
	my $p = HTML::Element->new("p", align => "left");

	my @content = $pre->content_list ();
	my $text = $content[0];


	my @lines = split ("\n", $text);
	foreach my $line (@lines) {
	    my $br = HTML::Element->new("br");
	    $line =~ s/\s/&nbsp\;/g;

##	    print STDERR $line;
	    $p->push_content ($line);
	    $p->push_content ($br);
	    $p->push_content ("\n");
	}
	$pre->replace_with ($p);
    }

}

sub remove_java_script {
    my $tree = shift;

    print STDERR "REMOVE SCRIPT CODE\n";

    my @scripts = $tree->find ("script");

    foreach my $script (@scripts) {
	print STDERR "REMOVING SCRIPT NODE: $script\n";
	$script->detach ();
    }
}


return 1;

__END__

=head1 NAME

EBook::MOBI::MobiPerl::Util

=head1 INFO

For information about this code, please visit L<https://dev.mobileread.com/trac/mobiperl>

=cut

