package Location::GeoTool::Aura;

################################################################
#
#  Geometric Functions 
#  Location::GeoTool::Aura
#  

use 5.008;
use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
$VERSION = 0.96;

use Location::GeoTool;
use Carp;

__PACKAGE__->_make_accessors(
  qw(sw se nw ne)
);

sub _new
{
  bless {sw=>$_[1],se=>$_[2],nw=>$_[3],ne=>$_[4]}, $_[0];
}

sub create_vertex{_new(@_)}

sub create_side
{
  my $class = shift;
  my ($south,$west,$north,$east,$datum,$format) = @_;

  bless {
    sw => Location::GeoTool->create_coord($south,$west,$datum,$format),
    se => Location::GeoTool->create_coord($south,$east,$datum,$format),
    nw => Location::GeoTool->create_coord($north,$west,$datum,$format),
    ne => Location::GeoTool->create_coord($north,$east,$datum,$format),
  },$class;
}

sub AUTOLOAD 
{
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.+://;
	return if ($method eq "DESTROY");
  if (($method =~ /^format_\w+$/) || ($method =~ /^datum_\w+$/))
  {
    return Location::GeoTool::Aura->_new(map { $self->$_->$method } ('sw','se','nw','ne'));
  }
	else
	{
		croak qq{Can't locate object method "$method" via package "Location::Area::DoCoMo::iArea::Aura"};
	}
}

sub array
{
	my $self = shift;
  my %second = map { $_ => $self->$_->format_second } ('sw','se','nw','ne');
  my $north = ($second{ne}->lat > $second{nw}->lat) ? $self->ne->lat : $self->nw->lat;
  my $south = ($second{se}->lat > $second{sw}->lat) ? $self->sw->lat : $self->se->lat;
  my $east = ($second{ne}->long > $second{se}->long) ? $self->ne->long : $self->se->long;
  my $west = ($second{nw}->long > $second{sw}->long) ? $self->sw->long : $self->nw->long;

	return ($south,$west,$north,$east);
}

sub get_center
{
	my $self = shift;
  my $center1 = $self->nw->direction_point($self->se)->pivot(0,0.5)->to_point;
  my $center2 = $self->ne->direction_point($self->sw)->pivot(0,0.5)->to_point;
  return $center1->direction_point($center2)->pivot(0,0.5)->to_point;
}

sub _make_accessors 
{
  my($class, @attr) = @_;
  for my $attr (@attr) {
    no strict 'refs';
    *{"$class\::$attr"} = sub { shift->{$attr} };
  }
}

1;