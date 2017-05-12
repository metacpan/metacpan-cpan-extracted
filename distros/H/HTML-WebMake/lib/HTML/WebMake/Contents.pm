#

package HTML::WebMake::Contents;


use HTML::WebMake::DataSource;
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

  bless ($self, $class);
  $self;
}

# -------------------------------------------------------------------------

sub add_text {
  my ($self, $name, $text, $location, $lastmod) = @_;

  # if the location does not map to a file in the filesystem we can
  # use for dependency checking, pass in undef as the $location parameter
  # and the text will be used directly.

  if (defined $location) {
    my $wmkf = new HTML::WebMake::File($self->{main}, $location);
    $self->{main}->set_file_modtime ($location, $lastmod);
    $self->{main}->add_content ($name, $wmkf, $self->{attrs}, $text);

  } else {
    $self->{main}->set_mapped_content ($name, $text, $self->{attrs}->{up});
  }
}

# -------------------------------------------------------------------------

sub add_location {
  my ($self, $name, $location, $lastmod) = @_;

  if (!defined $location)
  	{ carp __FILE__.": undef arg in add_location"; return; }

  # if the location does not map to a file in the filesystem we can
  # use for dependency checking, pass in undef as the $lastmod parameter.
  my $wmkf;
  $wmkf = new HTML::WebMake::File($self->{main}, $location);
  $self->{main}->set_file_modtime ($location, $lastmod);

  $self->{main}->add_content_defer_opening
		      ($name, $wmkf, $self->{attrs}, $self);
}

# and later, HTML::WebMake::Content will call this to get the text
# in question...
sub get_location {
  my ($self, $location) = @_;
  if (!defined $location)
  	{ carp __FILE__.": undef arg in get_location"; return ""; }
  if (!defined $self->{hdlr})
  	{ carp __FILE__.": undef hdlr in get_location"; return ""; }

  return $self->{hdlr}->get_location_contents ($location);
}

# -------------------------------------------------------------------------

sub as_string {
  my ($self) = @_;
  "<contents>";
}

# -------------------------------------------------------------------------

1;
