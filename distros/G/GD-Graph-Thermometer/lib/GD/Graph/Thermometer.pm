package GD::Graph::Thermometer;

use warnings;
use strict;
use Carp;
use CGI;
use GD;
use GD::Text::Align;
use Data::Dumper;
use constant PI => 3.14;

use vars qw($VERSION);
$VERSION = '0.05';

my $cgi = CGI->new();

sub new {
  my $self = shift;
  my $args = shift;

  my $missing_arguments = 0;
  foreach my $key qw( goal current ){
    if(!defined($args->{$key})) { $missing_arguments++ };
  }
  if($missing_arguments){
    croak "GD::Graph::Thermometer requires that the 'goal' and 'current' keys be defined in its constructor.  All other arguments are optional and default values will be substituted for any missing values";
  }

  if(!defined($args->{'title'})){
    $args->{'title'} = "";
    carp "The call to GD::Graph::Thermometer failed to define a title for the resulting graph.";
  }

  if(!defined($args->{'width'})){
    $args->{'width'} = '100';
  }

  if(!defined($args->{'height'})){
    $args->{'height'} = '200';
  }

  my $image = new GD::Image($args->{width},$args->{height});
  my $colors = $self->_define_colors($image, {
       background_color => $args->{'background_color'},
          outline_color => $args->{'outline_color'},
             text_color => $args->{'text_color'},
          mercury_color => $args->{'mercury_color'}
       });

  my $top = ($args->{'height'} * .04);
  my $bottom = ($args->{'height'} * .80);
  my $diff = $bottom - $top;
  my $left_text_margin = ($args->{'width'} * .38);
  my $diameter = ($args->{'width'} * .36);

  # background, set tranparent if you want
  $image->filledRectangle( 0, 0, $args->{'width'}, $args->{'height'}, $colors->{'background_color'} );

  # $image->rectangle($x1,$y1,$x2,$y2,$color)
  if($args->{'transparent'} == '1'){
    $image->transparent($colors->{'background_color'});
  }
  $image->rectangle(($args->{'width'} * .16),($args->{'height'} * .04),($args->{'width'} * .32),($args->{'height'} * .85),$colors->{'outline_color'});

  # $image->filledEllipse($cx,$cy,$width,$height,$color)
  $image->filledEllipse(($args->{'width'} * .24),($args->{'height'} * .90),($args->{'width'} * .36),($args->{'width'} * .36),$colors->{'mercury_color'});
  
  # mercury rising . . .
  $image->filledRectangle(($args->{'width'} * .16),($args->{'height'} * .80),($args->{'width'} * .32),($args->{'height'} * .85),$colors->{'mercury_color'});
  
  # add labels to graph 
  $image = $self->_add_labels($image,$args->{'goal'},$args->{'current'},$colors->{'text_color'},$colors->{'mercury_color'},$left_text_margin,$top,$bottom,$diff,$args->{'width'},$args->{'height'});

  # display title
  $self->_display_title($image,$colors->{'text_color'},$args->{'title'},$args->{'width'},$bottom);

  # render image as a .png file
  $self->_render_image($image, $args->{'image_path'}, $args->{'type'});

  return;
}

sub _render_image {
  my $self = shift;
  my $image = shift;
  my $image_path = shift;
  my $type = shift;

  if(!defined($type)){
    $type = 'png';
  }

  if(defined($image_path)){
    open( "IMAGE", ">", "$image_path") || die "Couldn't open file: $image_path.  $!\n";
    binmode( IMAGE );
    print IMAGE $image->$type();
    close IMAGE;
  } else {
    print $cgi->header("image/$type");
    binmode STDOUT;
    print $image->$type;
  }

  return;
}

sub _add_labels {
  my($self,$image,$goal,$current,$text_color,$red,$left_text_margin,$top,$bottom,$diff,$w,$h) = @_;
  my $text = new GD::Text::Align(
         $image,
         font => gdTinyFont,
         text => $goal.' Goal',
        color =>  $text_color,
       valign => "center",
       halign => "left",
       );
    
  #draw goal at top
  $text->draw($left_text_margin,$top);
  
  #draw start at bottom
  if (($current / $goal) > .10){
    $text->set_text('0 Start');
    $text->draw($left_text_margin,$bottom);
  }
  my $curpix = ($h * .80) - ($diff/$goal) * $current;

  # draw 
  $text->set_text("$current Current");
  $text->draw($left_text_margin,$curpix);
  $image->filledRectangle(($w * .16),$curpix,($w * .32),($h * .85),$red);
  return $image;
}

sub _display_title {
  my ($self,$image,$color,$title,$w,$bottom) = @_;
  my $set_title = GD::Text::Align->new($image,
      vtitle => 'top',
      htitle => 'right',
      color => $color,
    );
  $set_title->set_font('arial', 12);
  $set_title->set_text($title);
  my @bb = $set_title->bounding_box(($w * .10), $bottom, (PI/2));
  $set_title->draw(($w * .10),$bottom,(PI/2));
  return $image;
}
    
sub _define_colors {
  my $self = shift;
  my $image = shift;
  my $custom_colors = shift;

  my $background_color;
  if (defined($custom_colors->{'background_color'})) {
    $background_color = $image->colorAllocate(
        $custom_colors->{'background_color'}[0],
        $custom_colors->{'background_color'}[1],
        $custom_colors->{'background_color'}[2]
      );
  } else {
    $background_color = $self->_white($image);
  }

  my $outline_color;
  if (defined($custom_colors->{'outline_color'})) {
    $outline_color = $image->colorAllocate(
        $custom_colors->{'outline_color'}[0],
        $custom_colors->{'outline_color'}[1],
        $custom_colors->{'outline_color'}[2]
      );
  } else {
    $outline_color = $self->_black($image);
  }

  my $text_color;
  if (defined($custom_colors->{'text_color'})) {
    $text_color = $image->colorAllocate(
        $custom_colors->{'text_color'}[0],
        $custom_colors->{'text_color'}[1],
        $custom_colors->{'text_color'}[2]
      );
  } else {
    $text_color = $self->_black($image);
  }

  my $mercury_color;
  if (defined($custom_colors->{'mercury_color'})) {
    $mercury_color = $image->colorAllocate(
        $custom_colors->{'mercury_color'}[0],
        $custom_colors->{'mercury_color'}[1],
        $custom_colors->{'mercury_color'}[2]
      );
  } else {
    $mercury_color = $self->_red($image);
  }

  my $colors = {
    background_color => $background_color,
       outline_color => $outline_color,
          text_color => $text_color,
       mercury_color => $mercury_color
       };

  return $colors;
}

sub _black {
  my $self = shift;
  my $image = shift;
  my $color = $image->colorAllocate(0,0,0);
  return $color;
}

sub _white {
  my $self = shift;
  my $image = shift;
  my $color = $image->colorAllocate(255,255,255);
  return $color;
}

sub _red {
  my $self = shift;
  my $image = shift;
  my $color = $image->colorAllocate(255,0,0);
  return $color;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

GD::Graph::Thermometer - Generate progress graph on the fly

=head1 VERSION

This document describes GD::Graph::Thermometer version 0.0.1

=head1 SYNOPSIS

    use GD::Graph::Thermometer;
    my $result = GD::Graph::Thermometer->new({
                 image_path => '/path/to/image.png',
                       type => 'png',
                       goal => '80000',
                    current => '20000',
                      title => 'Funding the League for the Year ($)',
                      width => '100',
                     height => '200',
                transparent => '1',
           background_color => [ r, g, b ],
                 text_color => [ r, g, b ],
              outline_color => [ r, g, b ],
              mercury_color => [ r, g, b ]
        });

=head1 DESCRIPTION

When deployed in production, the current value ought to
be dynamically calculated based on a query of the database
tracking contributions or volunteers or whatever the goal
represented by the graph represents.

=head2 my $result = GD::Graph::Thermometer->new({});

This module exports only one method, its constructor, ->new(),
which creates a .png (by default) image file of the thermometer
graph with the path and name defined in its constructor.  If no
image_path is defined in the constructor, then the module will
print the image directly to STDOUT.

The anonymous hash fed to the constructor must define values
for the keys: goal and current.  Otherwise a fatal error will
be thrown.  Current should represent the progress made toward
the goal being graphed since the beginning of the campaign.

The output format defaults to png if the key 'type' is
undefined, otherwise a user may specify png, gif or jpeg
as the output format.  These correspond to the GD::Image->
methods by the same name, which are used to implement the
->_render_image() internal method.

The size parameters will default to 100 pixels wide by 200
pixels tall, if those arguments are missing from the anonymous
hash given to the constructor.  If title is not defined a
warning will be thrown, but the graph will still be generated.  

The colors for the background, text, outline and mercury
will default to white, black, black and red respectively,
if not otherwise defined in the constructor.  If defined in
the constructor, they should be defined as an anonymous array
of three values ( => [ r, g, b ],), range 0 - 255, suitable
for feeding to the GD::Image->colorAllocate() method.  If the
transparent key is set to '1', any area of the image set to
either the default or a custom background color will render
as transparent for inclusion on a web page.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Couldn't open file . . . >>

The system user under which this module was invoked does not
have sufficient permission to write to the result image file.
Make sure that the user has write permission on the target
directory, or alternately, touch the file into existance and
use chown and chmod to give write permissions on the result
file itself to the user which will invoke the module.  If this
is run by your web server, that user is likely nobody, apache,
www-data or something similiar.

=item C<< The call to GD::Graph::Thermometer failed to define
a title for the resulting graph. >>

Add "title => 'This is the title of my graph'," to your
constructor, otherwise the module will throw this error and
produce a graph without an explanatory title.

[=item C<< Error message here, perhaps with %s placeholders >>]

[Description of error here]

=back

=head1 CONFIGURATION AND ENVIRONMENT

GD::Graph::Thermometer requires no configuration files or
environment variables.

=head1 DEPENDENCIES

This module depends on GD and GD::Text::Align.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

At present this module will produce a reasonable looking graphic
when the image uses its default size (100 x 200 pixels).
For reasons I don't yet quite understand, changing these
arguments creates distorted images.  Perhaps future development
might address this issue.

Please report any bugs or feature requests to
C<bug-gd-graph-thermometer@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Hugh Esco  C<< <hesco@campaignfoundations.com> >>

=head1 ACKNOWLEDGEMENTS

This module would not have been possible without the work of
Lincoln Stein, who's GD:: heirarchy of modules makes this
possible.  And while I'm at it, let me also thank him for
CGI.pm, which has made all of our lives much easier.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Hugh Esco C<<
<hesco@campaignfoundations.com> >>. All rights reserved.

This module was created to serve an immediate need.  However it
is not central to the current focus of my development work.
While I am not abandoning this code as unmaintained, I
do invite others, particularly those with more experience
developing modules in the GD:: heirarchy to consider adopting
and maintaining this module.  Please contact me by email if
you are interested.

This module is free software; you can redistribute it and/or
modify it under the terms of the Gnu Public License. See L<gpl>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS
NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE
COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE
"AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR
IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE
IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO
IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO
MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY
THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT
NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE
OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF
THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH
HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
