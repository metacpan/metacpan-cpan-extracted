package Google::Checkout::XML::Writer;

#--
#-- Writing XML document. Base class.
#--

use strict;
use warnings;

use XML::Writer;
use Google::Checkout::General::GCO;
use Google::Checkout::General::Error;
use Google::Checkout::General::Util qw/make_xml_safe/;

sub new 
{
  my ($class, %args) = @_;

  my $self = { _end_tags => 0, _xml_content => ''};

  $self->{_xml_writer} = XML::Writer->new(OUTPUT => \$self->{_xml_content}, UNSAFE => 1);
  $self->{_xml_writer}->xmlDecl("UTF-8");

  if ($args{root})
  {
    $self->{_end_tags}++;
    $self->{_xml_writer}->startTag($args{root});
  }

  return bless $self => $class;
}

sub add_element
{
  my ($self, %args) = @_;

  return Google::Checkout::General::Error->new(
           @{$Google::Checkout::General::Error::ERRORS{MISSING_ELEMENT_NAME}}) 
             unless $args{name};
  
  $args{attr} = [] unless $args{attr};

  $args{data} = make_xml_safe($args{data}) if ($args{data});

  if ((defined $args{data})||(! $args{close})) {
    $self->{_xml_writer}->startTag($args{name}, @{$args{attr}});
    $self->{_xml_writer}->raw($args{data}) if defined $args{data};
  } else {
    $self->{_xml_writer}->emptyTag($args{name}, @{$args{attr}});
    return 1;
  }

  if ($args{close})
  {
    $self->{_xml_writer}->endTag();
  }
  else
  {
    $self->{_end_tags}++;
  }
 
  return 1;
}

sub close_element
{
  my ($self) = @_;

  $self->{_end_tags}--;
  $self->{_xml_writer}->endTag();

  return 1;
}

sub done
{
  my ($self) = @_;

  $self->{_xml_writer}->endTag() for (1..$self->{_end_tags});

  $self->{_xml_writer}->end();

  $self->{_xml_content} =~ y/\n\r//d;

  return $self->{_xml_content};
}

1;
