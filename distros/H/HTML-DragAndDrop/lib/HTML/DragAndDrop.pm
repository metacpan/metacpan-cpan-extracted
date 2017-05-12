package HTML::DragAndDrop;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::DragAndDrop ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';
use Carp;
our $module = "DragDrop.pm";
use strict;
use CGI;


# Preloaded methods go here.
sub new {
    my ($class, %arg) = @_;
    my $self = {};
    $self->{javascript_dir} = $arg{javascript_dir} || '/';
    $self->{javascript_dir} .= "/" unless ($self->{javascript_dir} =~ m:/$:);
    $self->{tooltip} = $arg{tooltip};
    $self->{dragables} = {};
    bless($self, $class);
    return $self;
}

sub add_dragable($%) {
    my ($self, %args) = @_;
    $self->{dragables}->{$args{name}} = \%args;
}

sub output_html($) {
    my ($self) = @_;
    # The order in which we parse the objects, is not the order in which 
    # we need to output them
    my $output = '';
    my $script_include_output;
    my $dragables_output;
    my $javascript = $self->{javascript_dir} . 'wz_dragdrop.js';
    $script_include_output .= 
        qq(\n<script type="text/javascript" src="$javascript"></script>\n);

    foreach my $d (keys %{$self->{dragables}}) {

        my $name = $self->{dragables}->{$d}->{name};
        my $width = $self->{dragables}->{$d}->{width};
        my $height = $self->{dragables}->{$d}->{height};
        my $class = $self->{dragables}->{$d}->{class} || 'dragable';

        my $copy = $self->{dragables}->{$d}->{copy};
        $copy = 0 if (!$copy);
        for (0 .. $copy) {
            my $left = $self->{dragables}->{$d}->{left};
            my $top = $self->{dragables}->{$d}->{top};
            my $use_name;
            if ($_ == 0) {
                $use_name = $name if ($_ == 0);
            } else {
                $use_name = $name . 'div' . $_;
            }
            my $tooltip;
            my $tooltip_output = '';
            if ($self->{tooltip}) {
                $tooltip = $self->{dragables}->{$d}->{tooltip};
                if ($tooltip) {
                    $tooltip =~ s/'/\\'/g;
                    $tooltip_output = qq(onmouseover="return escape('$tooltip');");
                }
            }
            if ($self->{dragables}->{$d}->{src}) {
                # Image
                my $src = $self->{dragables}->{$d}->{src};
                $dragables_output .= qq(<img name="$use_name" src="$src" width="$width" height="$height" style="position: absolute; left: $left; top: $top;" class="$class" $tooltip_output alt="$use_name" />\n);
            } elsif ($self->{dragables}->{$d}->{content}) {
                # A div?
                my $content = $self->{dragables}->{$d}->{content};
                $dragables_output .= qq(<div class="$class" id="${use_name}" style="position: absolute; left: $left; top: $top; width: $width; height: $height;" $tooltip_output>$content</div>\n);
            }
        }
    }

    $output .= $script_include_output;
    $output .= $dragables_output;
    return $output;
}

sub output_script($) {
    my ($self) = @_;
    my $dragables;
    my $output = '';

    foreach my $d (keys %{$self->{dragables}}) {
        my $name = $self->{dragables}->{$d}->{name};
        my $features = $self->{dragables}->{$d}->{features};
        $features = '+' . $features unless($features =~ m/^\+/ || $features =~ m/^\s*$/);
        my $src = $self->{dragables}->{$d}->{src};
        my $copy = $self->{dragables}->{$d}->{copy};
        my $to_add = qq("$name");
        if ($src && $copy) {
            $to_add .= "+COPY+$copy";
        }
        $to_add .= $features if ($features);
        $dragables .= $to_add . ',';
    }
    $dragables =~ s/,$//;

    if ($dragables) {
        $output .= qq(<script language="Javascript" type="text/javascript">\n);
        $output .= "SET_DHTML($dragables);\n";
        $output .= qq(</script>\n);

    }
    if ($self->{tooltip}) {
        my $javascript = $self->{javascript_dir} . 'wz_tooltip.js';
        $output .= qq(<script type="text/javascript" src="$javascript"></script>\n);
    }
    return $output;
}

1;
__END__

=head1 NAME

HTML::DragAndDrop - Provides a perl interface for easy use of Walter Zorn's 
dragdrop Javascript library.  See 
http://www.walterzorn.com/dragdrop/dragdrop_e.htm.  


=head1 SYNOPSIS

    use HTML::DragAndDrop;

    my $dd = HTML::DragAndDrop->new(
        javascript_dir => '/javascript/',
    );

    $dd->add_dragable(
        name => 'dragable1',
        src => '/images/www3.png',
        width => 64, height => 64,
    );

    print $dd->output_html;
    print $dd->output_script;

=head1 DESCRIPTION

The HTML::DragAndDrop module provides a Perl interface to Walter Zorn's 
Javascript Drag and Drop library.  See 
http://www.walterzorn.com/dragdrop/dragdrop_e.htm.  

Walter's Javascript library provides:

    A Cross-browser JavaScript DHTML Library which adds Drag Drop 
    functionality to layers and to any desired image, even those 
    integrated into the text flow.

=head2 METHODS

=over 4

=head1 new

    my $dd = CGI::DragDrop->new(
        javascript_dir => '/javascript/',
    );

Create a new DragDrop object.  The various options are described below:

=item javascript_dir

Defaults to /.  This is the url path to the directory containing 
wz_dragdrop.js.  It can be relative or absolute.

=head2 add_dragable

    $dd->add_dragable(
        name => 'drag1',
        width => 120, height => 120,
        left => 10, top => 60,
        content => $html_to_display,
        # or
        # src => $image_url,
        class => $css_class,
        features => $features,
    );

This function defines the div tag or image tag that will be dragable.  The 
dragable item must have a name.  If your dragable object is an image, then 
it must also have a width and a height.

=over 4

=item name

The name is the HTML id attribute if the dragable object is not an image, 
otherwise it is the HTML name attribute.  It is output in the html tag, and 
is compulsary for a dragable object.

=item width

The width (and height) attribute is compulsory for images.  It works just 
like defining the width in the HTML or stylesheet.  You must use an absolute 
value for the width (e.g. 240px) and not a relative value (33%).


=item height

The height (and width) attribute is compulsory for images.  It works just 
like defining the height in the HTML or stylesheet.  You must use an absolute 
value for the height (e.g. 240px) and not a relative value (33%).

=item left

Defines how far from the left of edge of the containing object the dragable 
object will be when the page loads.  The containing object is usually the 
browser window, but could be another html tag, for example a div tag.  For 
those who are stylesheet savvy, this is the left absolute positioning style.

=item top

Defines how far from the top of edge of the containing object the dragable 
object will be when the page loads.  The containing object is usually the 
browser window, but could be another html tag, for example a div tag.  For 
those who are stylesheet savvy, this is the top absolute positioning style.

=item content

If content is provided, the module will create a div tag with an id of the 
name provided, that contains the content.  The content can be straight text 
or html.  If both content and src (image) attributes are present, the src 
will be used.

=item src

The source is the url of an image to use.  The module generates an IMG tag 
with a name of the name provided.

=item class

If a class is specified the dragable object will be created with the class 
given, otherwise it will have a class of "dragable".  This is for use with 
stylesheets, and is especially handy when using the content attribute.

=item features

For a complete understanding of the features available, see Walter Zorn's 
site.  The features are passed directly in to the javascript library 
functions.  If you want to use more than one feature, join them in a string 
with '+' characters.  For example: 'RESIZABLE+VERTICAL+CURSOR_HAND', will 
give you a resizable object, that only moves along the vertical axis, and 
the mouse cursor displays a hand when hovering over the object.  A basic 
description of the features available is below:

    feature            applies to    description
    --------           -----------   ------------
    CLONE              images        Makes a single, dragable clone
    COPY               images        Makes x dragable copies, e.g. COPY+5
    CURSOR_DEFAULT     all           Default cursor onmouseover
    CURSOR_CROSSHAIR   all	     Crosshair cursor onmouseover
    CURSOR_HAND        all           Hand cursor onmouseover
    CURSOR_MOVE        all           Move cursor onmouseover
    CURSOR_E_RESIZE    all           East resize cursor onmouseover
    CURSOR_NE_RESIZE   all           NorthEast resize cursor onmouseover
    CURSOR_NW_RESIZE   all           NorthWest resize cursor onmouseover
    CURSOR_N_RESIZE    all           North resize cursor onmouseover
    CURSOR_SE_RESIZE   all           SouthEast resize cursor onmouseover
    CURSOR_SW_RESIZE   all           SouthWest resize cursor onmouseover
    CURSOR_W_RESIZE    all           West resize cursor onmouseover
    CURSOR_TEXT        all           Text cursor onmouseover
    CURSOR_WAIT        all           Wait cursor onmouseover
    CURSOR_HELP        all           Help cursor onmouseover
    DETACH_CHILDREN    layers        Dragable objects inside the div 
                                     don't move with it
    HORIZONTAL         all           Only move on the horizontal axis
    MAXWIDTH           all           Maximum width to resize to
    MAXHEIGHT          all           Maximum height to resize to
    MINWIDTH           all           Minimum width to resize to
    MINHEIGHT          all           Minimum height to resize to
    MAXOFFBOTTOM       all           Maximum downwards movement
    MAXOFFLEFT         all           Maximum left movement
    MAXOFFRIGHT        all           Maximum right movement
    MAXOFFTOP          all           Maximum upwards movement
    NO_ALT             images        De-activates the ALT and TITLE attributes
    NO_DRAG            all           Object is not dragable
    RESET_Z            all           Restores the object's z-index once dropped
    RESIZABLE          all           Object can be resized
    SCALABLE           all           Object maintains width/height ratio 
                                     when resized
    SCROLL             all           Browser window will scroll as objects 
                                     are dragged to the edge
    VERTICAL           all           Only move on the vertical axis


=head2 output_html

The output_html method returns all the html to generate the dragable objects.  
The output MUST be printed before the output of the output_script method.

=head2 output_script

The output_script method returns the javascript needed to make the objects 
dragable (or have whatever other features you have given them), in a script 
block.  The output of this method MUST be printed after the output of the 
output_html method.

=head1 SEE ALSO

See Walter Zorn's website http://www.walterzorn.com.

And the examples below

=head1 EXAMPLES

=head2 Example One - An Image

This example shows an image that can be dragged around the browser window.

To run this example, you will need the image script.png in a web-accessible 
directory called images.  (e.g. you should be able to access it as 
/images/script.png).  You will also need Walter Zorn's wz_dragdrop.js in a 
web-accessible directory called javascript.

    #!/usr/bin/perl
    use strict;
    use warnings;
    use CGI;
    use HTML::DragAndDrop;

    my $q = new CGI;
    my $dd = HTML::DragAndDrop->new(
        javascript_dir => '/javascript/',
    );

    $dd->add_dragable(
        name => 'dragable1',
        src => '/images/script.png',
        width => 64, height => 64,
    );

    print $q->header, $q->start_html;
    print $dd->output_html;
    print $dd->output_script;
    print $q->end_html;

=head2 Example Two - Some div tags

This example shows two div tags.  On that can be dragged around the browser 
window and another than can only be dragged a limited distance in the 
horizontal plane but cannot be dragged vertically.

To run this example you will need Walter Zorn's wz_dragdrop.js in a 
web-accessible directory called javascript.

    #!/usr/bin/perl
    use strict;
    use warnings;
    use CGI;
    use CGI::Carp qw(fatalsToBrowser);
    use HTML::DragAndDrop;

    my $q = new CGI;
    my $dd = HTML::DragAndDrop->new(
        javascript_dir => '/javascript/',
    );

    print $q->header;
    print $q->start_html(
        -title => 'D+D',
        -style => {code => '
            .dragable {
                border: 3pt ridge lightsteelblue;
                font-family: verdana, arial, sans-serif;
                color: #006;
                background: #EEEEEE;
                padding: 1em;
                font-weight: bold;
            }
        '}
    );

    $dd->add_dragable(
        name => 'drag1',
        width => '120px', height => '120px',
        left => '200px', top => '60px',
        content => 'Constrained horzontal movement only',
        features => 'CURSOR_HAND+HORIZONTAL+MAXOFFLEFT+200+MAXOFFRIGHT+200',
    );

    $dd->add_dragable(
        name => 'drag2',
        width => '120px', height => '120px',
        left => '300px', top => '200px',
        content => 'Any movement allowed',
        features => 'CURSOR_HAND',
    );

    print $dd->output_html;
    print $dd->output_script;
    print $q->end_html;

=head1 AUTHOR

Becky Alcorn, E<lt>becky@unisolve.com.auE<gt>
Simon Taylor, E<lt>simon@unisolve.com.auE<gt>
Unisolve Pty Ltd

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Unisolve Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
