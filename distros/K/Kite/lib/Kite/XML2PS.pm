#========================================================================
# Kite::XML2PS
#
# DESCRIPTION 
#   Perl module to convert a curve definition from OpenKite XML format
#   to PostScript, with automatic page tiling and registration mark
#   control.
# 
# AUTHORS
#   Simon Stapleton <simon@tufty.co.uk> wrote the original xml2ps.pl
#   utility which performs the XML -> PostScript conversion.
#
#   Andy Wardley <abw@kfs.org> re-packaged it into a module for 
#   integration into the Kite bundle.
#
# COPYRIGHT
#   Copyright (C) 2000 Simon Stapleton, Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# VERSION
#   $Id: XML2PS.pm,v 1.3 2000/10/17 12:19:28 abw Exp $
#
#========================================================================

package Kite::XML2PS;

require 5.004;

use strict;
use Kite::Base;
use Kite::XML::Parser;

use base qw( Kite::Base );
use vars qw( $VERSION $ERROR $DEBUG $PARAMS );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

# define parameters for this class, used by Kite::Base init() method
$PARAMS = {
    FILENAME => undef,
    TITLE    => '',
    REGMARKS => 1,
    BORDER   => 5,
    MAP      => 1,
};


#------------------------------------------------------------------------
# init($config)
#
# Initialisation method called by the base class new() constructor 
# method.  Calls the base class init() to set any parameters from the
# $PARAMS hash and then calls process_file() to process the XML 
# file to generate internal PATH and IMAGE definitions.
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    # call base class to read config params
    $self->SUPER::init($config)
	|| return undef;

    # process file
    $self->process_file()
	|| return undef;

    # OK
    return $self;
}


#------------------------------------------------------------------------
# process_file()
# process_file($filename)
#
# Processes the file specified as a parameter, or set internally as 
# the FILENAME item, reading the XML contained therein and generating 
# internal PATH and IMAGE definitions which can be retrieved via the 
# path() and image() methods (handled automatically by the base class
# AUTOLOAD method).
#------------------------------------------------------------------------

sub process_file {
    my $self = shift;
    my $file = @_ ? shift : $self->{ FILENAME };
    my ($parser, $doc);

    return $self->error('no filename specified') 
	unless defined $file;

    # parse XML file, trapping any errors thrown via die()
    $parser = Kite::XML::Parser->new();
    eval {
	$doc = $parser->parsefile($file);
    };
    return $self->error($@)
	if $@;

    my $path  = 'newpath ';
    my $image = '';
    my ($x, $y, $xt, $yt, $angle, $anglet);

    $self->{ KITE } = $doc;
    $self->{ TITLE } ||= $doc->title();

    # generate PS for each kite part
    foreach my $part (@{ $doc->part() })
    {
	$xt = $part->layout->x() || 0;
	$yt = $part->layout->y() || 0;
	$anglet = $part->layout->angle || 0;

	$image .= "gsave $xt mm $yt mm translate $anglet rotate ";
	$path  .= "$xt mm $yt mm translate $anglet rotate ";

	# add path segments as a series of PS moveto/lineto ops
	foreach my $curve (@{ $part->markup->curve })
	{
	    $image .= "gsave ";

	    my $linetype = $curve->linetype || "normal";

	    if ($linetype eq 'normal') {
		$image .= "0.5 setlinewidth ";
	    }
	    elsif ($linetype eq 'heavy') {
		$image .= "0.75 setlinewidth ";
	    }
	    elsif ($linetype eq "light") {
		$image .= "0.25 setlinewidth ";
	    }
	    elsif ($linetype eq "dotted") {
		$image .= "0.55 setlinewidth [3 5 1 5] 0 setdash ";
	    }

	    my $incurve = undef;

	    foreach my $point (@{ $curve->point })
	    {
		$x = $point->x;
		$y = $point->y;

		if (defined $incurve)
		{
		    $image .= "$x mm $y mm lineto ";
		    $path  .= "$x mm $y mm lineto ";
		}
		else
		{
		    $image .= "newpath $x mm $y mm moveto ";
		    $path  .= "$x mm $y mm moveto ";
		    $incurve = 1;
		}
	    }

	    # add text using PS pathtext function
	    foreach my $text (@{ $curve->text || [] })
	    {
		my $font = $text->font || "Helvetica";
		my $size = $text->size || "6";
		$text = $text->char;
		for ($text) {	# remove leading and trailing whitespace
		    s/^\s*//;
		    s/\s*$//;
		}
		$image  .= "gsave /$font findfont $size mm scalefont setfont ";
		$image  .= "($text) 0 pathtext grestore ";
	    }
	    $image .= "stroke grestore ";
	}

	# add transformations
	$path  .= "$anglet neg rotate $xt neg mm $yt neg mm translate ";
	$image .= "grestore ";
    }

    # save image and path definitions internally and return happy
    $self->{ IMAGE } = $image;
    $self->{ PATH  } = $path;

    return 1;
}


#------------------------------------------------------------------------
# doc()
#
# Generate a complete PostScript document to print the kite parts,
# with automatic multiple page tiling (page-size independant), 
# registration marks and many other glorious features.  Returns the 
# generated PostScript as a string.
#------------------------------------------------------------------------

sub doc {
    my $self = shift;
    
    require Kite::PScript::Defs;
    require Template;
 
    my $doc = $self->ps_template();
    my $template = Template->new( POST_CHOMP => 1);
    my $vars = { 
	defs => bless { }, 'Kite::PScript::Defs',
    };
    my @keys = qw( kite title regmarks border map image path );
    @$vars{ @keys } = @$self{ map { uc } @keys };

    my $out = '';
    $template->process(\$doc, $vars, \$out)
	|| return $self->error($template->error());
    return $out;
}

#------------------------------------------------------------------------
# ps_template()
#
# Returns a Template Toolkit template for generating the PostScript.
#------------------------------------------------------------------------

sub ps_template {
    return <<'EOF';
[% USE fix = format('%.2f') -%]
%!PS-Adobe-3.0
[% IF title %]
%%Title: [% title %]
[% END %]
%%EndComments

[% defs.mm %]
[% defs.lines %]
[% defs.cross %]
[% defs.dot %]
[% defs.circle %]
[% defs.crop %]

/border [% border %] mm def
[% defs.clip +%]
[% regmarks ? defs.reg : defs.noreg +%]
[% defs.tiles +%]
[% defs.tilemap +%]
[% defs.pathtext %]

% define image, path and page procedures for tiling
/tileimage {
  [% image %]
} def

/tilepath {
  [% path %]
} def

/tilepage {
  regmarks
[% IF title %]
  /Times-Roman findfont 24 scalefont setfont
  clipblx 3 mm add clipbly 3 mm add moveto
  ([% title %]) show
[% END %]
[% "  tilemap\n" IF map %]
} def    

tilepath tiles
[% defs.dotiles %]

EOF
}    
    
1;

__END__
	

=head1 NAME

Kite::XML2PS - reads an XML curve definition file and generates PostScript

=head1 SYNOPSIS

    use Kite::XML2PS;

    my $ps = Kite::XML2PS( filename => 'example.xml' )
        || die $Kite::XML2PS::ERROR, "\n";

    # return PostScript definitions for image and image path
    print "image definition: ", $ps->image();
    print "image path: ", $ps->path();

    # generate entire PostScript document with tiling, etc.
    print $ps->doc();

=head1 DESCRIPTION

Module for converting an XML file containing curve definitions (see 
xml/kiteparts.dtd) into PostScript.

=head1 PUBLIC METHODS

=head2 new(\%config)

Constuctor method called to create a new Kite::XML2PS object.  Accepts
a reference to a hash array of configuration items or a list of 
C<name =E<gt> value> pairs.  The following items may be specified:

=over 4

=item filename

Specifies a filename from which the XML definition should be read.
This parameter is mandatory.  The XML content of this document should
conform to the OpenKite layout format as specified in the
xml/kiteparts.dtd file (relative to the distribution root directory).

=item title

Optional parameter which can be used to set the title for the document.
Setting this value will override any title defined in the XML document.

=item regmarks

Enables registration marks when set to any true value.

=item border

Specifies a border width in mm (default: 5mm).  The clipping area
will be inset this distance from the imageable area on the page.  This
is useful for printers that can't actually print to the edge of the area
that they think they can.

=item map

The tiling procedure adds a small map to the top left hand corner of 
each page, indicating the position of the current page within the 
tiling set.  This option can be set to 0 to disable this feature.

=back

The file specified via the C<filename> option will be parsed and converted
into PostScript definitions for the image as a whole (IMAGE) and the 
outline path (PATH).  These can then be retrieved via the image() and 
path() method calls.

On error, the constructor returns undef.  The error message generated can
be retrieved by calling the error() class method, or by examining the 
$Kite::XML2PS::ERROR variable.

=head2 doc()

Returns a PostScript document containing the kite parts layed out as 
specified in the input file.  The output is automatically tiled onto
multiple pages.

=head2 image() 

Returns a PostScript string defining the image for the parts parsed from
the input file.

=head2 path()

Returns a PostScript string defining the the outline path of the parts
parsed from the input file.

=head1 AUTHORS

Simon Stapleton <simon@tufty.co.uk> wrote the original xml2ps.pl
utility which performs the XML -> PostScript conversion.

Andy Wardley <abw@kfs.org> re-packaged it into a module for integration
into the Kite bundle.

=head1 REVISION

$Revision: 1.3 $

=head1 COPYRIGHT

Copyright (C) 2000 Simon Stapleton, Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See also L<Kite>, L<Kite::PScript::Defs> and L<okxml2ps>.

=cut


