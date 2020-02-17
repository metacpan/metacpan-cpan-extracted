package HTML::HTMLDoc;

use 5.006;
use strict;
use warnings;
use IO::File;
use IPC::Open3 qw();
use HTML::HTMLDoc::PDF;
use vars qw(@ISA $VERSION);

@ISA = qw();
$VERSION = '0.15';
my $DEBUG = 0;

###############
# create a new Object
# param:
# return: object:HTML::HTMLDOC
###############
sub new {
	my $package = shift;

	my $self = {};
	bless($self, $package);

	while (my $key = shift) {
		my $value = shift;
		$self->{'config'}->{$key} = $value;
	}

	$self->_init();

	return $self;
}

###############
# initialises the Object with the basic parameters
# param: -
# return: -
###############
sub _init {
	my $self = shift;

	if ((not defined $self->{'config'}->{'mode'}) || ($self->{'config'}->{'mode'} ne 'file' && $self->{'config'}->{'mode'} ne 'ipc')) {
		$self->{'config'}->{'mode'} = 'ipc';
	}

	if ( (!$self->{'config'}->{'tmpdir'}) || (!-d $self->{'config'}->{'tmpdir'})) {
		$self->{'config'}->{'tmpdir'} = '/tmp';
	}

	if ( defined($self->{'config'}->{'bindir'}) ) {
		$self->{'config'}->{'bindir'} .= "/" if ( $self->{'config'}->{'bindir'} !~ /\/$/ );
	} else {
		$self->{'config'}->{'bindir'} = '';
	}

	$self->{'errors'} = [];
	$self->{'doc_config'} = {};

	$self->set_page_size('universal');
	$self->portrait();
	$self->set_charset('iso-8859-1');
	$self->_set_doc_config('quiet');
	$self->set_output_format('pdf');
	
	# standard-header and footer
	$self->set_footer('.', '1', '.');
	$self->set_header('.', 't', '.');

}

###############
# Store or get a global configuration value
# testet
# param: key:STRING, value:STRING
# return: 1
###############
sub _config {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	my $ret;
	if (defined $value) {
		$self->{'config'}->{$key} = $value;
	} else {
		$ret = $self->{'config'}->{$key};
	}
	return $ret;
}

###############
# stores a specific value for formating the outputdoc
# testet
# param: key:STRING, value:STRING
# return: 1
###############
sub _set_doc_config {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	if (ref($value) && (ref($value) eq 'ARRAY') ) {
		# the value is an array, store it in an array too
		if ( !$self->{'doc_config'}->{$key} || ref($self->{'doc_config'}->{$key}) ne 'ARRAY') {
			# create a new array
			$self->{'doc_config'}->{$key} = [];
		}
		foreach my $single_value(@{$value}) {
			push(@{$self->{'doc_config'}->{$key}}, $single_value);
		}
	} else {
		$self->{'doc_config'}->{$key} = $value;
	}

	return 1;
}

###############
# deletes a specific config
# testet
# param: key:STRING
# return: value:STRING
###############
sub _delete_doc_config {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	if (exists $self->{'doc_config'}->{$key}) {
		my $set_value = $self->_get_doc_config($key);
		if ( (ref($set_value) eq 'ARRAY') && $value ) {
			# remove specific value only
			# find the position of the value
			for(my $i=0; $i<@{$set_value}; $i++) {
				if ( $set_value->[$i] eq $value ) {
					splice(@{$set_value}, $i, 1);
					last;
				}
			}
		} else {
			# delete the singlevalue
			delete $self->{'doc_config'}->{$key};
		}
	}
}


###############
# tells a specific value for formating the outputdoc
# testet
# param: key:STRING
# return: value:STRING
###############
sub _get_doc_config {
	my $self = shift;
	my $key = shift;
	return $self->{'doc_config'}->{$key};
}

###############
# returns all the configuration keys
# param: key:STRING
# return: value:STRING
###############
sub _get_doc_config_keys {
	my $self = shift;

	my @keys = keys %{$self->{'doc_config'}};
	print STDERR "Keys: @keys\n" if $DEBUG;
	return @keys;
}

###############
# tests if the parameter exists in the array
# of allowed params
# testet
# param: key:STRING, \@allowed
# return: 1/0
###############
sub _test_params {
	my $self = shift;
	my $param = shift;
	my $allowed = shift;

	my $ok = 0;
	foreach my $aparam (@{$allowed}) {
		if (lc($param) eq lc($aparam)) {
			$ok=1;
			last;
		}
	}

	return $ok;
}


#######################################
# 			public Methods for configuring behaviour and style of the
#			Document
#######################################

###############
# sets the size of the pages - default: a4
# testet
# param: letter, a4, WxH{in,cm,mm}
# return: 1/0
###############
sub set_page_size {
	my $self = shift;
	my $value = shift;

	if ( !$value && $value ne 'a4' && $value ne 'letter' && $value ne 'universal' && $value!~/^\d+x\d+(?:in|cm|mm)/ ) {
		$self->error("unknown value for pagesize: $value");
		return 0;
	}

	$self->_set_doc_config('size', $value);
    return 1;
}

###############
# reads out the page-size
# param: letter, a4, WxH{in,cm,mm}
# return: 1/0
###############
sub get_page_size {
	my $self = shift;
	return $self->_get_doc_config('size');
}

###############
# sets the master-password of the doc
# testet
# param: password:STRING
# return: 1/0
###############
sub set_owner_password {
	my $self = shift;
	my $value = shift;
	$self->_set_doc_config('owner-password', $value);
	return 1;
}

###############
# sets the user-password of the doc
# testet
# param: password:STRING
# return: 1/0
###############
sub set_user_password {
	my $self = shift;
	my $value = shift;
	$self->_set_doc_config('user-password', $value);
	return 1;
}

# all,annotate,copy,modify,print,no-annotate,no-copy,no-modify,no-print,none
###############
# sets the master-password of the doc
# testet
# param: password:STRING
# return: 1/0
###############
sub set_permissions {
	my $self = shift;
	my @values = @_;

	my $thiskey = 'permissions';

	my @allowed = ('all','annotate','copy','modify','print','no-annotate','no-copy','no-modify','no-print','none');
	# test the set value
	if ($#values==-1) {
		$self->error("wrong permission set: no values");
		return 0;
	}
	for( my $i=0; $i<=$#values; $i++ ) {
		$values[$i] = lc($values[$i]);
		if ( !$self->_test_params($values[$i], \@allowed) ) {
			# wrong permission set
			$self->error("wrong permission set: $values[$i]");
			return 0;
		}
	}

	foreach my $value(@values) {
		# take care of the combination of the options
		if ( $value eq 'all' ) {
			# delete all
			$self->_delete_doc_config($thiskey);
		} elsif( $value eq 'none' ) {
			# delete all
			$self->_delete_doc_config($thiskey);
		} else {
			# delete the corresponding flag
			if ( $value =~/^no-(.+)/ ) {
				my $key = $1;
				$self->_delete_doc_config($thiskey, $key);
			} else {
				$self->_delete_doc_config($thiskey, "no-$value");
			}
		}

		$self->_set_doc_config('permissions', [$value]);
	}
	# enable encryption since without it there is no effect.
	$self->enable_encryption();
	return 1;
}

###############
# sets to duplex for two-sided printing
# testet
# param: -
# return: 1/0
###############
sub duplex_on {
	my $self = shift;

	$self->_set_doc_config('duplex', '');
	$self->_delete_doc_config('no-duplex');
	return 1;
}

###############
# disable duplex / two-sided printing
# testet
# param: -
# return: 1/0
###############
sub duplex_off {
	my $self = shift;

	$self->_set_doc_config('no-duplex', '');
	$self->_delete_doc_config('duplex');
	return 1;
}

###############
# sets the pages to portrait
# testet
# param: -
# return: 1/0
###############
sub landscape {
	my $self = shift;

	$self->_set_doc_config('landscape', '');
	$self->_delete_doc_config('portrait');
	return 1;
}

###############
# sets the pages to portrait
# testet
# param: -
# return: 1/0
###############
sub portrait {
	my $self = shift;

	$self->_set_doc_config('portrait', '');
	$self->_delete_doc_config('landscape');
	return 1;
}

###############
# turns the title on
# param: -
# return: 1/0
###############
sub title {
	my $self = shift;

	$self->_set_doc_config('title', '');
	$self->_delete_doc_config('no-title');
	return 1;
}

###############
# turns the title off
# param: -
# return: 1/0
###############
sub no_title {
	my $self = shift;

	$self->_set_doc_config('no-title', '');
	$self->_delete_doc_config('title');
	return 1;
}

###############
# sets the footer
# testet
# param: left:CHAR, center:CHAR, right:CHAR
# return: 1/0
###############
sub set_footer {
	my $self = shift;
	my $left = shift;
	my $center = shift;
	my $right = shift;

	my @allowed = ('.', ':', '/', '1', 'a', 'A', 'c', 'C', 'd', 'D', 'h', 'i', 'I', 'l', 't', 'T','u');
	if (!$self->_test_params($left, \@allowed) ) {
		$self->error("wrong left-footer-option: $left");
		return 0;
	}
	if (!$self->_test_params($center, \@allowed) ) {
		$self->error("wrong center-footer-option: $left");
		return 0;
	}
	if (!$self->_test_params($right, \@allowed) ) {
		$self->error("wrong right-footer-option: $left");
		return 0;
	}

	$self->_set_doc_config('footer', "${left}${center}${right}");

	return 1;
}

###############
# sets the header
# testet
# param: left:CHAR, center:CHAR, right:CHAR
# return: 1/0
###############
sub set_header {
	my $self = shift;
	my $left = shift;
	my $center = shift;
	my $right = shift;

	my @allowed = ('.', ':', '/', '1', 'a', 'A', 'c', 'C', 'd', 'D', 'h', 'i', 'I', 'l','L', 't', 'T','u');
	if (!$self->_test_params($left, \@allowed) ) {
		$self->error("wrong left-header-option: $left");
		return 0;
	}
	if (!$self->_test_params($center, \@allowed) ) {
		$self->error("wrong center-header-option: $left");
		return 0;
	}
	if (!$self->_test_params($right, \@allowed) ) {
		$self->error("wrong right-header-option: $left");
		return 0;
	}

	$self->_set_doc_config('header', "${left}${center}${right}");

	return 1;
}

###############
# turns the links on
# param: -
# return: 1/0
###############
sub links {
	my $self = shift;

	$self->_set_doc_config('links', '');
	$self->_delete_doc_config('no-links');
	return 1;
}

###############
# turns the links off
# param: -
# return: 1/0
###############
sub no_links {
	my $self = shift;

	$self->_set_doc_config('no-links', '');
	$self->_delete_doc_config('links');
	return 1;
}

###############
# sets the search path for files in a document
# param: -
# return: 1/0
###############
sub path {
	my $self = shift;
    my $sp = shift;

	$self->_set_doc_config('path', $sp);
	return 1;
}

###############
# sets the right margin
# testet
# param: margin|NUM, messure:in,cm,mm
# return: 1/0
###############
sub set_right_margin {
	my $self = shift;
	my $margin = shift;
	my $m = shift || 'cm';
	return $self->_set_margin('right', $margin, $m);
}

###############
# sets the left margin
# testet
# param: margin|NUM, messure:in,cm,mm
# return: 1/0
###############
sub set_left_margin {
	my $self = shift;
	my $margin = shift;
	my $m = shift || 'cm';
	return $self->_set_margin('left', $margin, $m);
}

###############
# sets the bottom margin
# param: margin|NUM, messure:in,cm,mm
# return: 1/0
###############
sub set_bottom_margin {
	my $self = shift;
	my $margin = shift;
	my $m = shift || 'cm';
	return $self->_set_margin('bottom', $margin, $m);
}

###############
# sets the top margin
# param: margin|NUM, messure:in,cm,mm
# return: 1/0
###############
sub set_top_margin {
	my $self = shift;
	my $margin = shift;
	my $m = shift || 'cm';
	return $self->_set_margin('top', $margin, $m);
}


sub _set_margin {
	my $self = shift;
	my $where = shift;
	my $margin = shift;
	my $m = shift;

	# test the values
	if ( $margin!~/^\d*\.?\d+$/ || ( ($m ne 'in') && ($m ne 'cm') && ($m ne 'mm') )) {
		$self->error("wrong arguments for $where-margin: $margin $m");
		return 0;
	}

	$self->_set_doc_config($where, "$margin$m");
	return 1;
}

###############
# sets the color of the body
# testet
# param: color:hex
# return: 1/0
###############
sub set_bodycolor {
	my $self = shift;

	my $ret;
	my $color = $self->_test_color(@_);
	if (!$color) {
		$self->error("wrong value set for bodycolor");
		$ret = 0;
	} else {
		$ret = $self->_set_doc_config('bodycolor', $color);
	}

	return $ret;
}

###############
# internal method for testing and converting colors
# testet
# param: color:hex || color: rgb || color: name
# return: color:hex
###############
sub _test_color {
	my $self = shift;
	my @colors = @_;
	my $ret;

	if( (@colors == 1) && $colors[0]=~/^#[0-9a-f]{6}$/i ) {
		# got hex-color
		return $colors[0];
	} elsif( @colors==3 ) {
		# 3 input values, test if regular rgb is given
		my ($r, $g, $b) = @colors;
		if ($r=~/^\d{1,3}$/ && $g=~/^\d{1,3}$/ && $b=~/^\d{1,3}$/
			&& $r>=0 && $r <=255 && $b>=0 && $b<=255 && $g>=0 && $g<=255) {
				$ret = sprintf("#%02x%02x%02x", $r, $g, $b);
		}
	} elsif( @colors==1 ) {
		foreach my $c( qw(red green blue cyan magenta yellow darkRed
			darkGreen darkBlue darkCyan darkMagenta darkYellow white
			lightGray gray darkGray black) ) {
				if ($c eq $colors[0]) {
					$ret = $c;
					last;
				}
			}
	}

	return $ret;
}

###############
# sets the default font for the body
# testet
# param: fontface:STRING
# return: 1/0
###############
sub set_bodyfont {
	my $self = shift;
	my $font = shift;

	my $ret = 0;
	my @allowed = qw(Arial Courier Helvetica Monospace Sans Serif Times);
	if ( !$self->_test_params($font, \@allowed) ) {
		$self->error("illegal font set $font");
	} else {
		$self->_set_doc_config('bodyfont', $font);
		$ret = 1;
	}

	return $ret;
}

###############
# sets the default font for the document
# testet
# param: fontface:STRING
# return: 1/0
###############
sub set_textfont {
	my $self = shift;
	my $font = shift;

	my $ret = 0;
	my @allowed = qw(Arial Courier Helvetica Monospace Sans Serif Times);
	if ( !$self->_test_params($font, \@allowed) ) {
		$self->error("illegal font set $font");
	} else {
		$self->_set_doc_config('textfont', $font);
		$ret = 1;
	}

	return $ret;
}

###############
# sets the font size for body text
# param: size:NUM
# return: 1/0
###############
sub set_fontsize {
	my $self = shift;
	my $fsize = shift;
	if ($fsize =~ /^\d+(\.\d+){0,1}$/) {
		return $self->_set_doc_config('fontsize', $fsize);
	} else {
		$self->error("illegal font size $fsize");
		return 0;
	}
}


###############
# takes an image-filename that is used as background
# for all Pages
# param: image:STRING
# return: 1/0
###############
sub set_bodyimage {
	my $self = shift;
	my $image = shift;

	if ( ! -f "$image" ) {
		$self->error("Backgroundimage $image could not be found");
		return 0;
	}

	$self->_set_doc_config('bodyimage', $image);
	return 1;
}

###############
# takes an image-filename that is used as logoimage
# param: image:STRING
# return: 1/0
###############
sub set_logoimage {
	my $self = shift;
	my $image = shift;

	if ( ! -f "$image" ) {
		$self->error("Logoimage $image could not be found");
		return 0;
	}

	$self->_set_doc_config('logoimage', $image);
	return 1;
}

###############
# returns a previous set logo-image
# param: -
# return: image:STRING
###############
sub get_logoimage {
	my $self = shift;
	return $self->_get_doc_config('logoimage');
}

###############
# takes an image-filename that is used as letterhead
# param: image:STRING
# return: 1/0
###############
sub set_letterhead {
	my $self = shift;
	my $image = shift;

	if ( ! -f "$image" ) {
		$self->error("Letterhead $image could not be found");
		return 0;
	}

	$self->_set_doc_config('letterhead', $image);
	
	# tell htmldoc to use this letterhead
	$self->set_header('.', 'L', '.');
	
	return 1;
}

###############
# returns a previous set letterhead image
# param: -
# return: image:STRING
###############
sub get_letterhead {
	my $self = shift;
	return $self->_get_doc_config('letterhead');
}


###############
# set the witdh in px for the background image
# param: width:INT
# return: 1/0
###############
sub set_browserwidth {
	my $self = shift;
	my $width = shift;

	if ($width !~ /^\d+$/) {
		$self->error("wrong browserwidth $width set");
		return 0;
	}

	$self->_set_doc_config('browserwidth', $width);
	return 1;
}

###############
# sets the compression level
# param:
# return: 1/0
###############
sub set_compression {
	my $self = shift;
	my $comp = shift;
	return $self->_set_doc_config('compression', $comp);
}

###############
# sets the JPEG-Kompression
# param: 0-100 (default 50)
# return: 1/0
###############
sub set_jpeg_compression {
	my $self = shift;
	my $comp = shift;
	$comp = 75 if (not defined $comp);
	return $self->_set_doc_config('jpeg', $comp);
}

###############
# sets the JPEG-Kompression value to the highest quality
# param: -
# return: 1/0
###############
sub best_image_quality {
	my $self = shift;
	return $self->set_jpeg_compression(100);
}

###############
# sets the JPEG-Kompression value to the highest quality
# param: -
# return: 1/0
###############
sub low_image_quality {
	my $self = shift;
	return $self->set_jpeg_compression(25);
}

###############
# sets the pagemode
# param: mode:[document,outline,fullscreen]
# return: 1/0
###############
sub set_pagemode {
	my $self = shift;
	my $value = shift;

	#--pagemode {document,outline,fullscreen}
	if (!$self->_test_params($value, ['document', 'outline', 'fullscreen']) ) {
    #if ($value ne 'document' && $value ne 'outline' && $value ne 'fullscreen') {
		$self->error("wrong pagemode: $value");
		return 0;
	}

	$self->_set_doc_config('pagemode', $value);
}

###############
# sets the page layout when opened in the viewer
# param: mode:[single,one,twoleft,tworight]
# return: 1/0
###############
sub set_pagelayout {
	my $self = shift;
	my $value = shift;

	#--pagemode {document,outline,fullscreen}
	if (!$self->_test_params($value, ['single', 'one', 'twoleft', 'tworight']) ) {
    #if ($value ne 'document' && $value ne 'outline' && $value ne 'fullscreen') {
		$self->error("wrong pagelayout: $value");
		return 0;
	}

	$self->_set_doc_config('pagelayout', $value);
}



###############
# sets the charset
# param: charset
# return: 1/0
###############
sub set_charset {
	my $self = shift;
	my $charset = shift;

	$self->_set_doc_config('charset', $charset);
	return 1;
}

###############
# embedding the used fonts into the pdf-file
# testet
# param:
# return: 1/0
###############
sub embed_fonts {
	my $self = shift;
	$self->_delete_doc_config('no-embedfonts');
	$self->_set_doc_config('embedfonts', '');
	return 1;
}

###############
# no font embedding
# testet
# param:
# return: 1/0
###############
sub no_embed_fonts {
	my $self = shift;
	$self->_delete_doc_config('embedfonts');
	$self->_set_doc_config('no-embedfonts', '');
	return 1;
}

###############
# turns colors on in doc
# param: charset
# return: 1/0
###############
sub color_on {
	my $self = shift;

	$self->_set_doc_config('color', '');
	$self->_delete_doc_config('grey', '');
	return 1;
}

###############
# turns colors off in doc
# param:
# return: 1/0
###############
sub color_off {
	my $self = shift;

	$self->_set_doc_config('grey', '');
	$self->_delete_doc_config('color', '');
	return 1;
}

###############
# turns encryption off
# param: -
# return: 1/0
###############
sub enable_encryption {
	my $self = shift;

	$self->_set_doc_config('encryption', '');
	$self->_delete_doc_config('no-enryption', '');
	return 1;
}

###############
# turns encryption off
# param: -
# return: 1/0
###############
sub disable_encryption {
	my $self = shift;

	$self->_set_doc_config('no-encryption', '');
	$self->_delete_doc_config('enryption', '');
	return 1;
}

###############
# sets the outputformat of the document
# param: format:STRING
# return: 1/0
###############
sub set_output_format {
	my $self = shift;
	my $f = shift;

	my @allowed = qw(epub html pdf pdf11 pdf12 pdf13 pdf14 ps ps1 ps2 ps3);
	if( !$self->_test_params($f, \@allowed)) {
		$self->error("Wrong output format set $f");
		return 0;
	}

	$self->_set_doc_config('format', $f);
	return 1;
}


####################################################
#
# 			Methods for outputting the result
#
####################################################



###############
# sets the html-page that should be rendered
# param: html:STRING
# return: 1/0
###############
sub set_html_content {
	my $self = shift;
	my $html = shift;

	$self->{'html'} = $html;
	return 1;
}

###############
# returns the html-content
# param: -
# return: html:STRING
###############
sub get_html_content {
	my $self = shift;

	if (ref($self->{'html'}) eq 'SCALAR') {
		return ${$self->{'html'}};
	}

	return $self->{'html'};
}           

###############
# sets the filename of the html-page that should be rendered
# param: input_file:STRING
# return: 1/0
###############
sub set_input_file {
	my $self = shift;
	my $infile = shift;

    if (-f $infile) {
        $self->{'input_file'} = $infile;
        $self->{'config'}->{'mode'} = 'file';
        return 1;
    }
    return 0;
}

###############
# returns the input htmlfile
# param: -
# return: input_file:STRING
###############
sub get_input_file {
	my $self = shift;
	return $self->{'input_file'};
}


###############
# private: opens a temporary file and sets the
# html-content in
# param: -
# return: filename:STRING
###############
sub _prepare_input_file {
	my $self = shift;
                 
	my $i=0;
	my $filename;
	return $filename if (defined ($filename = $self->{'input_file'}));

	while($i<1000) {
		my $randpart = int(rand(1000));
		$filename = $self->{'config'}->{'tmpdir'} . "/htmldoc$randpart.html";

		if (-f $filename) {
			$i++;
			next;
		} else {
			last;
		}
	}

	my $file = new IO::File($filename, 'w');
	if (!$file) {
		warn "could not open tempfile $!";
		return undef;
	}
	$file->print($self->get_html_content());
	$file->close();
	$self->{'config'}->{'tmpfile'} = $filename;

	return $filename;
}

###############
# private: cleans up, deletes the tempfile
# param: -
# return: -
###############
sub _cleanup {
	my $self = shift;
	unlink($self->{'config'}->{'tmpfile'})
		if ( (defined $self->{'config'}->{'tmpfile'}) && (-f $self->{'config'}->{'tmpfile'}) );
}

###############
# finaly produces the pdf-output
# param: -
# return: pdf:STRING
###############
sub generate_pdf {
	my $self = shift;

	# save the env-var for restoring it later
	my $old_htmldoc_env = $ENV{'HTMLDOC_NOCGI'};
	$ENV{'HTMLDOC_NOCGI'} = 'yes';

	my $params = $self->_build_parameters();
	my $pdf;

	#if ($self->{'config'}->{'mode'} eq 'ipc') {
	if ($self->_config('mode') eq 'ipc') {
		# we are in normale Mode, use IPC
		my ($pid, $error);
    	($pid,$pdf,$error) = $self->_run($self->{'config'}->{'bindir'}."htmldoc  $params --webpage -", $self->get_html_content());
	} else {
		# we are in file-mode
		my $filename = $self->_prepare_input_file();
		return undef if (!$filename);
		$pdf = `$self->{'config'}->{'bindir'}htmldoc $params --webpage $filename`;
    	$self->_cleanup();
	}
	
	# restore old value 
	if (not defined $old_htmldoc_env) {
		delete $ENV{'HTMLDOC_NOCGI'};
	} else {
		$ENV{'HTMLDOC_NOCGI'} = $old_htmldoc_env;
	}

	my $doc = new HTML::HTMLDoc::PDF(\$pdf);
	
	return $doc;
}

###############
# generates a string for the configuration of htmldoc
# testet
# param: -
# return: params:STRING
###############
sub _build_parameters {
	my $self = shift;

	my $paramstring='';

	foreach my $key($self->_get_doc_config_keys()) {
		my $value = $self->_get_doc_config($key) || '';
		if ( ref($value) eq 'ARRAY' ) {
			# an array, set the option multiple
			foreach my $single_v(@{$value}) {
				$paramstring .= " --$key $single_v";
			}
		} else {
			if ($key eq 'compression' || $key eq 'jpeg') {
				$paramstring .= " --$key=$value";
			} else {
				$paramstring .= " --$key $value";
			}
		}

	}
	
	return $paramstring;
}

sub _run {
	my $self = shift;
	my $command = shift;
	my $input = shift;

	# create new Filehandles
	my ($stdin,$stdout,$stderr) = (IO::Handle->new(),IO::Handle->new(),IO::Handle->new());
	my $pid = IPC::Open3::open3($stdin,$stdout,$stderr, $command);
	if (!$pid) {
		$self->error("Cannot fork [COMMAND: '$command'].");
		return (0);
	}

	print $stdin $input;
	close $stdin;

	my $output = join('',<$stdout>);
	close $stdout;

	my $error = join('',<$stderr>);
	close $stderr;

	wait();


	if ($DEBUG) {
		print STDERR "\n********************************************************************\n";
		print STDERR "COMMAND : \n$command [PID $pid]\n";
		print STDERR "STDIN  :  \n$input\n";
		print STDERR "STDOUT :  \n$output\n";
		print STDERR "STDERR :  \n$error\n";
		print STDERR "\n********************************************************************\n";
	}

	return($pid,$output,$error);
}


###############
# set or retrieve an occurred error
# param: -
# return: pdf:STRING
###############
sub error {
	my $self = shift;
	my $error = shift;

	if (defined $error) {
		push(@{$self->{'errors'}}, $error);
	} else {
		if (wantarray()) {
			return @{$self->{'errors'}};
		} else {
			return $self->{'errors'}->[0];
		}
	}
}

1;
__END__

=head1 NAME

HTML::HTMLDoc - Perl interface to the htmldoc program for producing PDF Files from HTML content.

=head1 SYNOPSIS

  use HTML::HTMLDoc;

  my $htmldoc = new HTML::HTMLDoc();

  # generate from a string of HTML:
  $htmldoc->set_html_content(qq~<html><body>A PDF file</body></html>~);
  
  # or generate from an HTML file:
  $htmldoc->set_input_file($filename); 

  # create the PDF
  my $pdf = $htmldoc->generate_pdf();

  # print the content of the PDF
  print $pdf->to_string();
  
  # save to a file
  $pdf->to_file('foo.pdf');


=head1 DESCRIPTION

This module provides an OO interface to the HTMLDOC program.  HTMLDOC is a command
line utility which creates PDF and PostScript files from HTML 3.2.  It is actively
maintained and available via the package manager (apt, yum) of the major Linux distros.

HTML 3.2 is very limited for web interfaces, but it can do a lot when preparing a 
document for printing.  The complete list of supported HTML tags is listed here:
L<https://www.msweet.org/htmldoc/htmldoc.html#HTMLREF>

The HTMLDOC home page at L<https://www.msweet.org/htmldoc> and includes complete
documentation for the program and a link to the GitHub repo.

You will need to install HTMLDOC prior to installing this module, and it is
recommended to experiment with the 'htmldoc' command prior to utilizing this module.

All the config-setting modules return true for success or false for failure. You can 
test if errors occurred by calling the error-method.

Normaly this module uses IPC::Open3 for communication with the HTMLDOC process.
This works in PSGI and CGI environments, but if you are working in a Mod_Perl environment,
you may need to set the file mode in new():
	
	my $htmldoc = new HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp');


=head1 METHODS

=head2 new()

Creates a new Instance of HTML::HTMLDoc.

Optional parameters are:

=over 4

=item *
mode=>['file'|'ipc'] defaults to ipc

=item *
tmpdir=>$dir defaults to /tmp

=item *
bindir=>$dir directory containing your preferred htmldoc executable, such as /usr/local/bin.  Useful when you have installed from source.

=back

The tmpdir is used for temporary html-files in filemode. Remember to set the file-permissions
to write for the executing process.

=head2 set_page_size($size)

Sets the desired size of the pages in the resulting PDF-document. $size is one of:

=over 4

=item *
universal (default) == 8.27x11in (210x279mm)

=item *
a4 == 8.27x11.69in (210x297mm)

=item *
letter == 8.5x11in (216x279mm)

=item *
WxH{in,cm,mm} eg '10x10cm'

=back


=head2 set_owner_password($password)

Sets the owner-password for this document. $password can be any string. This only has effect if encryption is enabled.
see enable_encryption().

=head2 set_user_password($password)

Sets the user-password for this document. $password can be any string. If set, User will be asked for this
password when opening the file. This only has effect if encryption is enabled, see enable_encryption().


=head2 set_permissions($perm)

Sets the permissions the user has to this document. $perm can be:

=over 4

=item *
all

=item *
annotate

=item *
copy

=item *
modify

=item *
print

=item *
no-annotate

=item *
no-copy

=item *
no-modify

=item *
no-print

=item *
none

Setting one of this flags automatically enables the document-encryption ($htmldoc->enable_encryption())
for you, because setting permissions will have no effect without it.

Setting 'all' and 'none' will delete all other previously set options. You can set multiple options if
you need, eg.:

$htmldoc->set_permissions('no-copy');
$htmldoc->set_permissions('no-modify');

This one will do the same:
$htmldoc->set_permissions('no-copy', 'no-modify');

=back 

=head2 links()

Turns link processing on.

=head2 no_links()

Turns the links off.
 

=head2 path()

Specifies the search path for files in a document. Use this method if your images are not shown.

Example:

$htmldoc->path("/home/foo/www/myimages/");

=head2 landscape()

Sets the format of the resulting pages to landscape.

=head2 portrait()

Sets the format of the resulting pages to portrait.

=head2 title()

Turns the title on.

=head2 no_title()

Turns the title off.

=head2 set_right_margin($margin, $messure)

Set the right margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

=head2 set_left_margin($margin, $messure)

Set the left margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

=head2 set_bottom_margin($margin, $messure)

Set the bottom margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.


=head2 set_top_margin($margin, $messure)

Set the top margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

=head2 set_bodycolor($color)

Sets the background of all pages to this background color. $color is a hex-coded color-value (eg. #FFFFFF),
a rgb-value (eg set_bodycolor(0,0,0) for black) or a color name (eg. black)

=head2 set_bodyfont($font)

Sets the default font of the content. Currently the following fonts are supported:

Arial Courier Helvetica Monospace Sans Serif Symbol Times
 
=head2 set_fontsize($fsize)

Sets the default font size for the body text to the number of points, e.g. 12 for 12-point font.  1 point = 1/72 of an inch.

=head2 set_textfont($font)

Sets the default font of the document. Currently the following fonts are supported:

Arial Courier Helvetica Monospace Sans Serif Symbol Times

=head2 set_bodyimage($image)

Sets the background image for the document. $image is the path to the image in your filesystem.

=head2 set_logoimage($image)

Sets the logo-image for the document. $image is the path to the image in your filesystem. The supported formats are BMP, GIF, JPEG, and PNG.
Remember to specify the 'l'-option somewhere in header or footer using set_header() or/and set_footer().

$htmldoc-E<gt>set_logoimage('mylogo.gif');
$htmldoc-E<gt>set_header('.', 'l', '.');

=head2 get_logoimage()

Reads out a previous set logo-image. You will get the filename to the image.

=head2 set_letterhead($image)

Sets the image to use as a letter for the document. $image is the path to the image in your filesystem. 
The image should be 72DPI, and for portrait mode, 620-650 pixels wide and 72-90 pixels tall.
The supported formats are BMP, GIF, JPEG, and PNG.

This only works when the header is set to '.L.', and this method will automatically set_header()
to create that settings.

NOTE: This option is compatible with HTMLDOC 1.9.8 and higher. As of Feb. 14, 2020, that version is
available from cloning (and manual compile) from the HTMLDOC Git rep: L<https://github.com/michaelrsweet/htmldoc>

$htmldoc-E<gt>set_letterhead('myletterhead.png');

=head2 get_letterhead()

Reads out a previous set letterhead image. You will get the filename to the image.

=head2 set_browserwidth($width)

Specifies the browser width in pixels. The browser width is used to scale images and pixel measurements when generating PostScript and PDF files. It does not affect the font size of text.

The default browser width is 680 pixels which corresponds roughly to a 96 DPI display. Please note that your images and table sizes are equal to or smaller than the browser width, or your output will overlap or truncate in places.

=head2 set_compression($level)

Specifies that Flate compression should be performed on the output file. The optional level parameter is a number from 1 (fastest and least amount of compression) to 9 (slowest and most amount of compression).

This option is only available when generating Level 3 PostScript or PDF files.

=head2 set_jpeg_compression($quality)

$quality is a value between 1 and 100. Defaults to 75.

Sets the quality of the images in the PDF. Low values result in poor image quality but also in low file sizes for the PDF. High values result in good image quality but also in high file sizes.
You can also use methods best_image_quality() or low_image_quality(). For normal usage, including photos or similar a value of
75 should be ok. For high quality results use 100. If you want to reduce file size you have to play with the value to find a
compromise between quality and size that fits your needs.


=head2 best_image_quality()

Set the jpg-image quality to the maximum value. Call this method if you want to produce high quality PDF-Files. Note that this could produce huge file sizes
depending on how many images you include and how big they are. See set_jpeg_compression(100).


=head2 low_image_quality()

Set the jpg-image quality to a low value (25%). Call this method if you have many or huge images like photos in your PDF and you do not want exploding file sizes for your
resulting document. Note that calling this method could result in poor image quality. If you want some more control see method set_jpeg_compression() which allows you to
set the value of the compression to other values than 25%.

=head2 set_pagelayout($layout)

Specifies the initial page layout in the PDF viewer. The layout parameter can be one of the following:

=over 4

=item *
single - A single page is displayed.

=item *
one - A single column is displayed.

=item *
twoleft - Two columns are displayed with the first page on the left.

=item *
tworight - Two columns are displayed with the first page on the right.

=back

This option is only available when generating PDF files. 

=head2 set_pagemode($mode)

specifies the initial viewing mode of the document. $mode is one of:

=over 4

=item *
document - The document pages are displayed in a normal window.

=item *
outline - The document outline and pages are displayed.

=item *
fullscreen - The document pages are displayed on the entire screen.

=back


=head2 set_charset($charset)

Defines the charset for the output document. The following charsets are currenty supported:

cp-874 cp-1250 cp-1251 cp-1252 cp-1253 cp-1254 cp-1255
cp-1256 cp-1257 cp-1258 iso-8859-1 iso-8859-2 iso-8859-3
iso-8859-4 iso-8859-5 iso-8859-6 iso-8859-7 iso-8859-8
iso-8859-9 iso-8859-14 iso-8859-15 koi8-r utf-8


=head2 color_on()

Defines that color output is desired.

=head2 color_off()

Defines that b&w output is desired.


=head2 duplex_on()

Enables output for two-sided printing.

=head2 duplex_off()

Sets output for one-sided printing.

=head2 enable_encryption()

Snables encryption and security features for the document.

=head2 disable_encryption()

Enables encryption and security features for the document.

=head2 set_output_format($format)

Sets the format of the output-document. $format can be one of:

=over 4

=item *
html

=item *
epub

=item *
pdf (default)

=item *
pdf11

=item *
pdf12

=item *
pdf13

=item *
pdf14

=item *
ps

=item *
ps1

=item *
ps2

=item *
ps3

=back


=head2 set_html_content($html)

This is the function to set the html-content as a scalar. See set_input_file($filename)
to use a present file from your filesystem for input

=head2 get_html_content()

Returns the previous set html-content.


=head2 set_input_file($input_filename)

This is the function to set the input file name.  It will also switch the
operational mode to 'file'.


=head2 get_input_file()

Returns the previous set input file name.


=head2 set_header($left, $center, $right)

Defines the data that should be displayed in header. One can choose from the following chars for each left,
center and right:

=over 4

=item *
B<.> A period indicates that the field should be blank.


=item *
B<:> A colon indicates that the field should contain the current and total number of pages in the chapter (n/N).


=item *
B</> A slash indicates that the field should contain the current and total number of pages (n/N).


=item *
B<1> The number 1 indicates that the field should contain the current page number in decimal format (1, 2, 3, ...)


=item *
B<a> A lowercase "a" indicates that the field should contain the current page number using lowercase letters.


=item *
B<A> An uppercase "A" indicates that the field should contain the current page number using UPPERCASE letters.


=item *
B<c> A lowercase "c" indicates that the field should contain the current chapter title.


=item *
B<C> An uppercase "C" indicates that the field should contain the current chapter page number.


=item *
B<d> A lowercase "d" indicates that the field should contain the current date.


=item *
B<D> An uppercase "D" indicates that the field should contain the current date and time.


=item *
B<h> An "h" indicates that the field should contain the current heading.


=item *
B<i> A lowercase "i" indicates that the field should contain the current page number in lowercase roman numerals (i, ii, iii, ...)


=item *
B<I> An uppercase "I" indicates that the field should contain the current page number in uppercase roman numerals (I, II, III, ...)


=item *
B<l> A lowercase "l" indicates that the field should contain the logo image.


=item *
B<T> An uppercase "L" indicates that the logo image should stretch across the entire header.  Use only in the center.  (Works with htmldoc source as of Feb. 10, 2020.)

=item *
B<t> A lowercase "t" indicates that the field should contain the document title.


=item *
B<T> An uppercase "T" indicates that the field should contain the current time.

=item *
B<T> An lowercase "u" indicates that the field should contain the current filename or URL.


=back

Example:

Setting the header to contain the title left, nothing in center and actual pagenumber right do the follwing

$htmldoc-E<gt>set_header('t', '.', '1');


=head2 set_footer($left, $center, $right)

Defines the data that should be displayed in footer. See set_header() for details setting the left, center and right
value.


=head2 embed_fonts()

Specifies that fonts should be embedded in PostScript and PDF output. This is especially useful when generating documents in character sets other than ISO-8859-1.


=head2 no_embed_fonts()

Turn the font-embedding previously enabled by embed_fonts() off.


=head2 generate_pdf()

Generates the output-document. Returns a instance of HTML::HTMLDoc::PDF. See the perldoc of this class
for details


=head2 error()

In scalar content returns the last error that occurred, in list context returns all errors that occurred.


=head2 EXPORT

None by default.


=head1 AUTHORS

Eric Chernoff - ericschernoff at	gmail.com - is the primary maintainer starting from the 0.12 release.

The module was created and developed by Michael Frankl - mfrankl at    seibert-media.de


=head1 LICENSE

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 CREDITS

Many portions of this documentation pertaining to the options / configuration were copied and pasted from the HTMLDOC User Manual by Michael R Sweet at L<https://www.msweet.org/htmldoc/htmldoc.html>.

Thanks very much to:

Rajat Bhatia

Keith W. Sheffield

Christoffer Landtman

Aleksey Serba

Helen Hamster

Najib

for suggestions and bug fixes for versions 0.10 and earlier.


=head1 FAQ

=over

=item * Q: Where are the images that I specified in my HTML-Code?

A: The images that you want to include have to be found by the process that is generating your PDF (that is
using this Module). If you call the images relatively in your html-code like:
<img src="test.gif"> or <img src="./myimages/test.gif">
make sure that your perl program can find them. Note that a perl program can change the working
directory internal (See perl -f chdir). You can find out the working directory using:

use Cwd;
print Cwd::abs_path(Cwd::cwd);

The module provides a method path($p). Use this if you want to specify where the images you want to use
can be found. Example:

$htmldoc->path("/home/foo/www/myimages/");

=item * Q: How can I do a page break?

A: You can include a HTML-Comment that will do a page break for you at the point it is located:
<!-- PAGE BREAK -->

=item * Q: The Module works in shell but not with mod_perl

A: Use htmldoc in file-Mode:

my $htmldoc = new HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp');

=back

=head1 BUGS

Please use the GitHub Issue Tracker to report any bugs or missing functions.

L<https://github.com/ericschernoff/HTMLDoc/issues>

If you have difficulty with any of the features of this module, please test them
via the native 'htmldoc' command prior to reporting an issue.

=head1 SEE ALSO

L<https://www.msweet.org/htmldoc/htmldoc.html>.

L<https://github.com/michaelrsweet/htmldoc>.

L<PDF::API2>

L<PDF::Create>

L<CAM::PDF>

=cut
