
package HTML::WebMake::Out;


use Carp;
use strict;

use vars	qw{
  	@ISA 
};




###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;

  my ($file, $name, $attrs) = @_;
  my $self = { %$attrs };	# copy the attrs
  bless ($self, $class);
  my $attrval;

  $self->{main} = $file->{main};
  $self->{name} = $name;

  $attrval = $attrs->{'format'};
  $attrval ||= $self->{main}->{metadata}->get_attrdefault ('format');
  if (defined $attrval) {
    if ($attrval eq 'text/html') {
      delete $self->{format};
    } else {
      $self->{format} =
	  HTML::WebMake::FormatConvert::format_name_to_zname($attrval);
    }
  }

  if (defined $attrs->{root}) {
    $self->{main}->fail ("<out> tags cannot have root attribute: $name");
  }

  # is this out the "main" URL for any content items in it?
  $attrval = $attrs->{'ismainurl'};
  if (!defined $attrval) {
    $attrval = $self->{main}->{metadata}->get_attrdefault ('ismainurl');
  }
  if (defined $attrval) {
    $self->{ismainurl} = $self->{main}->{util}->parse_boolean ($attrval);
  }

  $attrval = $attrs->{'clean'};
  if (!defined $attrval) {
    $attrval = $self->{main}->{metadata}->get_attrdefault ('clean');
  }
  $self->{clean} = $attrval;

  $self;
}

# -------------------------------------------------------------------------

sub get_format {
  my ($self) = @_;

  if (!defined $self->{format}) { return 'text/html'; }
  HTML::WebMake::FormatConvert::format_zname_to_name($self->{format});
}

# -------------------------------------------------------------------------

sub get_text {
  my ($self) = @_;

  my $name = $self->{name};
  my $txt = '${OUT:'.$name.'}';
  $self->{main}->subst ($name, \$txt);
  $txt;
}

# -------------------------------------------------------------------------

sub use_for_content_urls {
  my ($self) = @_;
  my $ret = $self->{ismainurl};
  return (defined $ret) ? ($ret+0) : 1;
}

# -------------------------------------------------------------------------

1;
