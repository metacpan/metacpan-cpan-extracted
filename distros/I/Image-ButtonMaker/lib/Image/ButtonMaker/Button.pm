package Image::ButtonMaker::Button;
use strict;
use utf8;
use locale;
use Image::ButtonMaker::ButtonClass;
use Image::ButtonMaker::ClassContainer;
use Image::ButtonMaker::TextContainer;
use Image::ButtonMaker::TemplateCanvas;
use Image::ButtonMaker::ColorCanvas;


use Image::Magick;

our @property_names = qw(
                         FileType

                         WidthMin
                         WidthMax
                         HeightMin
                         HeightMax

                         ArtWorkType
                         ArtWorkHAlign
                         ArtWorkVAlign

                         MarginLeft
                         MarginRight
                         MarginTop
                         MarginBottom

                         CanvasType
                         CanvasTemplateImg
                         CanvasCutRight
                         CanvasCutLeft
                         CanvasCutTop
                         CanvasCutBottom
                         CanvasMatteColor

                         CanvasBackgroundColor
                         CanvasBorderColor
                         CanvasBorderWidth

                         Text
                         TextFont
                         TextColor
                         TextSize
                         TextAntiAlias
                         TextScale
                         TextUpperCase
                         TextPrefix
                         TextPostfix
                         NoLexicon

                         IconName
                         IconSpace
                         IconVerticalAdjust

                         AfterResizeY
                         AfterResizeX
                         );

our $error;
our $errorstr;

## Public'ish default attributes
my @default = (
               classname       => undef,   ## Image::ButtonMaker::ButtonClass name
               classcontainer  => undef,
               name            => undef,
               properties      => {},      ## Properties overriding Class properties
               print_warnings  => 0,
               die_on_errors   => 0,
               die_on_warnings => 0,
               );


## Private'ish default attributes
my @default_priv = (
                    internals  => {},      ## Internal object data
                    );


#### Class Methods ###################################################
#### Contstructor. Returns undef on error
sub new {
    my $invocant = shift;
    my $blessing = ref($invocant) || $invocant;

    reset_error();

    my %args = @_;
    my %prototype = ();

    #### Class argument check
    if(defined($args{classcontainer})) {
        $prototype{classcontainer} = $args{classcontainer};
    }

    if(defined($args{name})) {
        $prototype{name} = $args{name};
    } else {
        return set_error(1000,"name for button not given");
    }

    if(defined($args{classname})) {
        my $container = $prototype{classcontainer};
        return 
            set_error(1000, "Class name given, but no class container found")
            unless($container);

        return
            set_error(1000, "Class $args{classname} not found for button $args{name}")
            unless($container->lookup_class($args{classname}));
        $prototype{classname} = $args{classname};
    }

    #### Property check
    $prototype{properties} = {};

    if(defined($args{properties})) {
        my $prop = $args{properties};
        return
            set_error(1000, "Propeties must be a reference")
            unless(ref($prop) eq 'HASH');

        foreach my $pname (keys(%$prop)) {
            return 
                set_error(1000, "Unknown propety $pname")
                unless($invocant->is_property_legal($pname));
            $prototype{properties}->{$pname} = $prop->{$pname};
        }
    }

    #### Create the object
    my $object = {@default, %prototype, @default_priv};
    bless $object, $blessing;

    return $object;
}


#### This method is both instance and class method
sub is_property_legal {
    my $invocant = shift;
    my $prop = shift;

    foreach my $p (@property_names) {
        return 1 if ($p eq $prop);
    }
    return 0;
}


#### Instance Methods ###########################################################
sub lookup_name {
    my $self = shift;
    return $self->{name};
}

sub lookup_filename {
    my $self = shift;
    my $name = $self->lookup_name;
    my $type = $self->lookup_property('FileType');
    $type = 'png' unless($type);

    return $name.'.'.$type;
}

sub lookup_property {
    my $self = shift;
    my $propname = shift;
    reset_error();


    return 
        set_error(2000, "Illegal property $propname")
        unless($self->is_property_legal($propname));

    my $props = $self->{properties};

    return $props->{$propname}
        if(exists($props->{$propname}));


    if($self->{classname}) {
        my $container = $self->{classcontainer};
        my $class = $container->lookup_class($self->{classname});
        return
            set_error(2000, "Class not found ".$self->{classname})
            unless($class);

        return $class->lookup_property($propname);
    }

    return undef;
}

sub set_property {
    my $self = shift;
    my $propname  = shift;
    my $propvalue = shift;

    return 
        set_error(2000, "Illegal property $propname")
        unless($self->is_property_legal($propname));

    $self->{properties}{$propname} = $propvalue;

    return 1;
}

#### Render Button (this sub is not as scary as it looks)
sub render {
    my $self  = shift;
    reset_error();

    my $idata = $self->{internals};

    #### Prepare Artwork
    my $artobject;
    my $artWorkType = $self->lookup_property('ArtWorkType');
    if($artWorkType eq 'text') {
        $artobject = $self->__prepare_simple_text;
    }
    elsif($artWorkType eq 'icon+text') {
        $artobject = $self->__prepare_icon_plus_text;
    }
    elsif($artWorkType eq 'text+icon') {
        $artobject = $self->__prepare_text_plus_icon;
    }
    else {
        return set_error(3000, "ArtWorkType : $artWorkType not recognized");
    }

    return undef
        unless($artobject);

    #### Compute Artwork Size
    my ($artWidth, $artHeight, $artMaxAsc, $artMinDesc) = $artobject->compute_size;
    $idata->{artWidth}   = $artWidth;
    $idata->{artHeight}  = $artHeight;
    $idata->{artMaxAsc}  = $artMaxAsc;
    $idata->{artMinDesc} = $artMinDesc;

    #### Prepare Canvas
    my $canvasobject;
    if($self->lookup_property('CanvasType') eq 'pixmap') {
        $canvasobject = $self->__prepare_pix_canvas;
    }
    elsif($self->lookup_property('CanvasType') eq 'color') {
        $canvasobject = $self->__prepare_color_canvas;
    }

    return undef if($error);

    ## Render part should not depend on low level implementation of objects

    ## Fetch margins
    my $leftMargin   = $self->lookup_property('MarginLeft')   || 0;
    my $rightMargin  = $self->lookup_property('MarginRight')  || 0;
    my $topMargin    = $self->lookup_property('MarginTop')    || 0;
    my $bottomMargin = $self->lookup_property('MarginBottom') || 0;

    #### Compute canvas width and height
    ##   Compute width
    my $canvasWidth  = $artWidth + $rightMargin + $leftMargin;
    {
        my $minimumWidth = $self->lookup_property('WidthMin') || 1;
        my $maximumWidth = $self->lookup_property('WidthMax') || 10000;
        $self->warn("Minium Width is bigger than MaximumWidth: $minimumWidth > $maximumWidth")
            if($minimumWidth > $maximumWidth);
        if($minimumWidth) {
            $canvasWidth = $minimumWidth if($canvasWidth < $minimumWidth);
        }
        if($maximumWidth) {
            if($canvasWidth > $maximumWidth) {
                $canvasWidth = $maximumWidth;
                $self->warn("Truncated Width. The artwork is to big to fit in now.");
            }
        }
    }

    ##   Compute height
    my $canvasHeight = 0;
    {
        my $haligntype = $self->lookup_property('ArtWorkVAlign');
        if($haligntype eq 'baseline') {
            $canvasHeight = $artMaxAsc + $topMargin + $bottomMargin;
        }
        else {
            $canvasHeight = $artHeight + $topMargin + $bottomMargin;
        }
    }

    {
        my $minimumHeight = $self->lookup_property('HeightMin') || 1;
        my $maximumHeight = $self->lookup_property('HeightMax') || 10000;
        $self->warn("MiniumHeight is bigger than MaximumHeight: $minimumHeight > $maximumHeight")
            if($minimumHeight > $maximumHeight);
        if($minimumHeight) {
            $canvasHeight = $minimumHeight if($canvasHeight < $minimumHeight);
        }
        if($maximumHeight) {
            if($canvasHeight > $maximumHeight) {
                $canvasHeight = $maximumHeight;
                $self->warn("Truncated Height. The artwork is to big to fit in now.");
            }
        }
    }

    #### Render Canvas
    my $canvas = $canvasobject->render($canvasWidth, $canvasHeight);

    #### Compute alignment of artwork on canvas
    ##   horizontal alignment:
    my $hAlign = 0;
    {
        my $restSpace  = $canvasWidth - $leftMargin - $rightMargin;
        my $haligntype = $self->lookup_property('ArtWorkHAlign');
        if($haligntype eq 'left') {
            $hAlign = $leftMargin;
        }
        elsif($haligntype eq 'right') {
            $hAlign = $leftMargin + $restSpace - $artWidth;
            }
        elsif($haligntype eq 'center') {
            use integer;
            $hAlign = $leftMargin + ($restSpace - $artWidth)/2;
        }
        else {
            $self->warn("Unknown horizontal align type: $haligntype");
        }
    }

    ##   vertical alignment
    my $vAlign = 0;
    {
        my $restSpace  = $canvasHeight - $topMargin - $bottomMargin;
        my $valigntype = $self->lookup_property('ArtWorkVAlign');
        if($valigntype eq 'top') {
            $vAlign = $topMargin;
        }
        elsif($valigntype eq 'bottom') {
            $vAlign = $topMargin + $restSpace - $artHeight;
        }
        elsif($valigntype eq 'baseline') {
            $vAlign = $topMargin + $restSpace - $artMaxAsc;
        }
        else {
            print "What is $valigntype?\n";
            $self->warn("Unknown vertical align type: $valigntype");
        }
    }

    ## Render Artwork
    my $artwork = $artobject->render($canvas, $hAlign, $vAlign);

    $self->__after_resize($artwork);

    return $artwork;
}


#### Write image to file ##################################################
##  Target directory is optional
sub write {
    my $self = shift;
    my $target_dir = shift;

    reset_error();

    my $name = $self->{name};
    return set_error(4000, "Button name not defined")
        unless($name);

    my $img = $self->render;
    return undef if($error);
    
    my $filename = $self->lookup_filename;

    $filename = "$target_dir/$filename" if(length($target_dir));

    my $err = $img->Write($filename);
    return set_error(4000, "Could not write file $filename: $err")
        if($err);

    return $img;
}

### Print Warnings to Standard Error
sub warn {
    my $self = shift;
    print STDERR (@_, "\n") if($self->{print_warnings});
    die "EXITING" if($self->{die_on_warnings});
    return;
}

#### Package methods #########################################################
#### Set and reset package-wide error codes
sub reset_error {
    $error = 0;
    $errorstr = '';
    return;
}


sub set_error {
    $error = shift;
    $errorstr = shift;
    #FIXME(!!!) die_on_errors unimplemented
    return @_;
}


### Private'ish methods #########################################################
sub __prepare_pix_canvas {
    my $self = shift;
    reset_error();

    my $imageName = $self->lookup_property('CanvasTemplateImg');
    return
        set_error(3000, "Could not find file for canvas: $imageName")
        unless(-f $imageName);

    my $i         = Image::Magick->new();
    my $res       = $i->Read($imageName);

    return
        set_error(3000, "Could not read image file $imageName")
        if($res);

    my $cut_left   = $self->lookup_property('CanvasCutLeft')    || 0;
    my $cut_right  = $self->lookup_property('CanvasCutRight')   || 0;
    my $cut_top    = $self->lookup_property('CanvasCutTop')     || 0;
    my $cut_bottom = $self->lookup_property('CanvasCutBottom')  || 0;
    my $matte_color= $self->lookup_property('CanvasMatteColor') || 'rgba(128,128,128,255)';

    my $canvas = Image::ButtonMaker::TemplateCanvas->new(cut_left   => $cut_left,
                                                         cut_right  => $cut_right,
                                                         cut_top    => $cut_top,
                                                         cut_bottom => $cut_bottom,
                                                         matte_color=> $matte_color,
                                                         template   => $i
                                                         );

    return
        set_error(3000, "Could not create new pixmap canvas :".$Image::ButtonMaker::TemplateCanvas::errorstr)
        unless($canvas);

    return $canvas;
}


sub __prepare_color_canvas {
    my $self = shift;
    reset_error();

    my $background_color = $self->lookup_property('CanvasBackgroundColor');
    my $border_color     = $self->lookup_property('CanvasBorderColor');
    my $border_width     = $self->lookup_property('CanvasBorderWidth');


    my %args;
    $args{background_color} = $background_color if(length($background_color));
    $args{border_color}     = $border_color if(length($border_color));
    $args{border_width}     = $border_width if($border_width);

    my $canvas = Image::ButtonMaker::ColorCanvas->new(%args);

    return
        set_error(3000, "Could not create new color canvas :".$Image::ButtonMaker::ColorCanvas::errorstr)
        unless($canvas);

    return $canvas;
}


sub __add_text_to_container {
    my $self = shift;
    my $container = shift;

    my $text = $self->lookup_property('Text');
    $text = $text . $self->lookup_property('TextPostfix')
      if($self->lookup_property('TextPostfix'));
    $text = $self->lookup_property('TextPrefix') . $text
         if($self->lookup_property('TextPrefix'));
    $text = uc($text)
      if($self->lookup_property('TextUpperCase'));

    my $font = $self->lookup_property('TextFont');
    my $size = $self->lookup_property('TextSize');
    my $fill = $self->lookup_property('TextColor');
    my $aali = $self->lookup_property('TextAntiAlias');

    $aali = 'true'  if(lc($aali) eq 'yes');
    $aali = 'false' if(lc($aali) eq 'no');
    $aali = 'true' unless($aali);

    my $scale = $self->lookup_property('TextScale');
    $scale = 1 unless defined($scale);

    my $res = $container->add_cell(type      => 'text',
                                   font      => $font,
                                   text      => $text,
                                   size      => $size,
                                   fill      => $fill,
                                   antialias => $aali,
                                   scale     => $scale,
                                   );
    return
        set_error(3000, "Could not add cell : ".$container->get_errstr()."")
        if($res);
    return 1;
}


sub __add_icon_to_container {
    my $self = shift;
    my $container = shift;

    my $iconFile = $self->lookup_property('IconName');
    return set_error(3000, "No Icon name specified")
        unless($iconFile);
    return set_error(3000, "Could not find icon file : $iconFile")
        unless(-f $iconFile);

    my $icon = Image::Magick->new();
    my $res = $icon->Read($iconFile);
    return set_error(3000, "Could not load icon file: $iconFile")
        if($res);

    my $vertfix = $self->lookup_property('IconVerticalAdjust');

    $res = $container->add_cell( 
                                 type  => 'icon', 
                                 image => $icon,
                                 vertfix => $vertfix,
                                 );
    return 1;
}

sub __prepare_simple_text {
    my $self = shift;

    my $tc = Image::ButtonMaker::TextContainer->new(
                                                    layout => 'horizontal',
                                                    align  => 'baseline',
                                                    );

    ## There is no proper error handling in TextContainer constructor
    return set_error(3000, "Could not create TextContainer")
        unless($tc);

    my $res = $self->__add_text_to_container($tc);
    return undef unless($res);

    ## return the canvas object. call compute_size and render on it later
    return $tc;
}


sub __prepare_text_plus_icon {
    my $self = shift;

    my $tc = Image::ButtonMaker::TextContainer->new(
                                                    layout => 'horizontal',
                                                    align  => 'baseline',
                                                    );

    ## There is no proper error handling in TextContainer constructor
    return set_error(3000, "Could not create TextContainer")
        unless($tc);

    my $res = $self->__add_text_to_container($tc);
    return undef unless($res);

    my $space = $self->lookup_property('IconSpace');
    if($space) {
        return set_error(3000, "Invalid IconSpace Param : $space")
            unless($space =~ m|^\d+$|);
        $tc->add_cell(type  => 'space',
                      width => $space,
                      );
    }
    $res = $self->__add_icon_to_container($tc);
    return undef unless($res);
    return $tc;

}

sub __prepare_icon_plus_text {
    my $self = shift;

    my $tc = Image::ButtonMaker::TextContainer->new(
                                                    layout => 'horizontal',
                                                    align  => 'baseline',
                                                    );

    ## There is no proper error handling in TextContainer constructor
    return set_error(3000, "Could not create TextContainer")
        unless($tc);

    my $res = $self->__add_icon_to_container($tc);
    return undef unless($res);

    my $space = $self->lookup_property('IconSpace');
    if($space) {
        return set_error(3000, "Invalid IconSpace Param : $space")
            unless($space =~ m|^\d+$|);
        $tc->add_cell(type  => 'space',
                      width => $space,
                      );
    }

    $res = $self->__add_text_to_container($tc);
    return undef unless($res);
    return $tc;

}

#### Resizing the picture after it has been rendered
sub __after_resize {
    my $self = shift;
    my $pic  = shift;
    my $afterResizeX = $self->lookup_property('AfterResizeX');
    my $afterResizeY = $self->lookup_property('AfterResizeY');
    $self->warn("Both AfterResizeX and AfterResizeY are set")
        if($afterResizeX && $afterResizeY);

    my($height, $width) = $pic->Get('rows', 'columns');

    if($afterResizeX) {
        my $factor    = $afterResizeX/$width;
        my $newHeight = $height * $factor;
        $newHeight = sprintf("%.0f",$newHeight);
        $pic->Resize(height => $newHeight, width => $afterResizeX);
    }

    if($afterResizeY) {
        my $factor   = $afterResizeY/$height;
        my $newWidth = $width * $factor;
        $newWidth    = sprintf("%.0f", $newWidth);
        $pic->Resize(height => $afterResizeY, width => $newWidth);
    }

    return $pic;
}

### The End ################################################################
1;

__END__

=head1 NAME

Image::ButtonMaker::Button - A Button object for the ButtonMaker module

=head1 SYNOPSIS

  use Image::ButtonMaker::Button;

  my $but = Image::ButtonMaker::Button->new
           ( print_warnings => 1,
             name  => 'submitButton',

             properties => {
                            WidthMin         => 100,
                            HeightMin        => 55,
                            HeightMax        => 55,

                            CanvasType        => 'pixmap',
                            CanvasTemplateImg => 'pinky.png',
                            CanvasCutRight    => 1,
                            CanvasCutLeft     => 1,
                            CanvasCutTop      => 2,
                            CanvasCutBottom   => 2,

                            ArtWorkType   => 'text',
                            ArtWorkHAlign => 'center',
                            ArtWorkVAlign => 'baseline',

                            Text          => 'Submit Form',
                            TextColor     => '#000000',
                            TextSize      => 18,
                            TextFont      => '/home/users/piotr/head/uws-hosts/globals/autobuttons/fonts/arial.ttf',
                            TextAntiAlias => 'no',

                            MarginLeft   => 25,
                            MarginRight  => 30,
                            MarginTop    => 8,
                            MarginBottom => 24,

                            AfterResizeY => 30,
                            }

           ) or die "$Image::ButtonMaker::Button::errorstr";

  my $img = $but->render || die "$Image::ButtonMaker::Button::errorstr";

=head1 DESCRIPTION

This module is used to create single button objects and is capable of
rendering image objects. The module uses B<Image::Magick> as a backend
and some methods return and deal with B<Image::Magick> objects.

=head1 METHODS

=over 4

=item B<new>

This is a class method and a constuctor for Image::ButtonMaker::Button.
When a Image::ButtonMaker::Button object is created, it also creates some
lower-level objects for internal use.

Most of the parameters for the B<new> method are actually parameters 
for these lower level objects.


=over 4

=item * name

Name of the button. I is used by the B<write> method to compute the 
filename.

=item * classname

Name of button class. It is only used, when Image::ButtonMaker::Button 
is used from inside the Image::ButtonMaker module.

=item * classcontainer

Reference to a Image::ButtonMaker::ClassContainer object. It is only used, when 
Image::ButtonMaker::Button is used from inside the Image::ButtonMaker module.

=item * print_warnings

Boolean attribute. Send warnings to STDERR.

=item * die_on_errors

Boolean attrbute.

=item * die_on_warnings

Boolean attribute. A warning could be: "Text does not fit into button" or 
a similar 'minor' error.

=item * properties

Hash reference. It is a hash of legal button-properties. Following properties are
allowed:

=over 4

=item * FileType

File type of the file generated by the B<write> method. Could be 'png' or 'gif'
or something more exotic, as long as Image::Magick supports it.

=item * WidthMin

Minimum width of the generated button.

=item * WidthMax 

Maximum width of the generated button.

=item * HeightMin

Minimum height of the generated button.

=item * HeightMax

Maximum height of the generated button.

=item * ArtWorkType

The type of graphics, that will be rendered into the button. Options are
'text', 'text+icon' or 'icon+text'

=item * ArtWorkHAlign

Horizontal alignment of the graphics inside the button. The legal options
are 'left', 'right', 'center'

=item * ArtWorkVAlign

Horizontal alignment of the graphics inside the button. The legal options
are 'top', 'bottom' and 'baseline'. Where 'top' and 'bottom' place the graphics
at top or bottom of the available space, the 'baseline' option is a bit different.
What it does is to place the baseline of the rendered text, which is the line
between the ascendant and descendant parts of the text, and place it at the line
defined by MarginBottom.

=item * MarginLeft

Left margin of the artwork area.

=item * MarginRight

Right margin of the artwork area.

=item * MarginTop

Top margin of the artwork area/

=item * MarginBottom

Bottom margin of the artwork area. When using ArtworkVAlign, the bottom margin
will be crossed by some letters like 'y' or 'j'.

=item * CanvasType

Canvas is the template of the button. At this point two types of canvas are supported
and they are 'pixmap' and 'color'. 'pixmap' type uses a template which is sliced up and
stretched for each button, while 'color' is just for plain rectangular buttons with plain
background and a maybe a border.

=item * CanvasTemplateImg

When CanvasType is set to 'pixmap' this is the path tho the template image. The 
image must be readable by Image::Magick to be usefull.

=item * CanvasCutRight

When CanvasType is set to 'pixmap' this is the number of pixels, that will be cut
off and placed in the right stretch area.

=item * CanvasCutLeft

When CanvasType is set to 'pixmap' this is the number of pixels, that will be cut
off and placed in the left stretch area.

=item * CanvasCutTop

When CanvasType is set to 'pixmap' this is the number of pixels, that will be cut
off and placed in the top stretch area.

=item * CanvasCutBottom

When CanvasType is set to 'pixmap' this is the number of pixels, that will be cut
off and placed in the bottom stretch area.

=item * CanvasBackgroundColor

When CanvasType is set to 'color' this is the background color.

=item * CanvasBorderColor

When CanvasType is set to 'color' this is the border color.


=item * CanvasBorderWidth

When CanvasType is set to 'color' this is the border width. Border is only
drawn when CanvasBorderWidth is different from 0.

=item * Text

This is the text to be rendered inside a button.

=item * TextFont

A path to a .ttf (True Type Font) file containing your favorite font to be used 
inside the button.

=item * TextColor

A color of the text. Can be an RGB value like '#ff00aa' or some symbolic name
understood by Image::Magick.

=item * TextSize

Text size. F.ex '9' or maybe even '11'

=item * TextAntiAlias

Make the text nice and soft in the edges. Options are 'yes' or 'no'.

=item * TextScale

Scale factor for the text. This one defaults to 1.0.

=item * NoLexicon

=item * IconName

If the ArtworkType is 'text+icon' or 'icon+text' this must contain the path
to the icon image.

=item * IconSpace

Amount of horizontal space between the text and the icon.

=item * IconVerticalAdjust

Sometimes it is nice to be able to lift or lower the icon compared to the text.
This is the amount of pixels for that. Positive values lift and negative lower 
the icon.

=item * AfterResizeY

Resize button to height AfterResizeY after it has been rendered. It 
can be used for solving problems with antialiasing of text and icons
by rendering a really big image, and resizing it to smaller size 
afterwards.

=item * AfterResizeX

Resize button to with AfterResizeX after it has been rendered.

=back

=item  B<render>

Render the button.

=item B<write>

Write the button to file with prefix from the 'name' attribute of the object
and suffix defined by the FileType property.

=item B<lookup_name>

Return $self->{name}

=item B<lookup_filename>

Return $self->{name} suffixed with the FileType button property

=item B<lookup_property>($property_name)

Lookup and return a button property. If running from ButtonMaker with a 
ClassContainer object defined, the property can be obtained from the
class definition or a parent class.

=item B<set_property>

Set a button property inside the object.

=back

=back

=head1 AUTHORS

Piotr Czarny <F<picz@sifira.dk>> wrote this module and this crappy
documentation.

=cut
