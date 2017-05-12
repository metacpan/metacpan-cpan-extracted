#

package HTML::WebMake::Media;


use HTML::WebMake::DataSource;
use HTML::WebMake::MediaContent;
use Carp;
use strict;

use vars	qw{
  	@ISA
};

@ISA = qw(HTML::WebMake::DataSource);


###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $src, $name, $attrs) = @_;
  my $self = $class->SUPER::new (@_);

  if(defined $attrs->{'map'}) {
    $self->{'map'} = $main->{util}->parse_boolean ($attrs->{'map'});
  } else {
    $self->{'map'} = $main->{metadata}->get_attrdefault ('map');
  }

  bless ($self, $class);
  $self;
}

# -------------------------------------------------------------------------

sub add_text {
  my ($self, $name, $text, $location, $lastmod) = @_;

  # the <media> tag can only be used to refer to binary media, such
  # as images, which can be accessed by a web browser.  Therefore
  # trying to load media from a database or delimiter-separated-values
  # file is pointless, as the web browser cannot load media from there.
  carp "cannot use <media> tag with the $self->{proto} protocol\n";
}

# -------------------------------------------------------------------------

sub add_location {
  my ($self, $name, $location, $lastmod) = @_;

  my $url = $self->{hdlr}->get_location_url ($location);
  $self->{main}->add_url ($name, $url);

  # add a placeholder piece of content with the same name so
  # that metadata can be attached to Media items.
  # this is code formerly separated to Main::add_media_placeholder_content
  # but here it can read media object atributes

  my $cont = new HTML::WebMake::MediaContent ($self->{main}, $name, {
	    'format'		=> 'text/html',
	    'map'		=> $self->{'map'},
	  });

    $cont->add_ref_from_url ($url);
  }

# -------------------------------------------------------------------------

  sub as_string {
    my ($self) = @_;
    "<media>";
  }

# -------------------------------------------------------------------------

  1;
