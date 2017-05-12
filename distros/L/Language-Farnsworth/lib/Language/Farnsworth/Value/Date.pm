package Language::Farnsworth::Value::Date;

use strict;
use warnings;

use Language::Farnsworth::Dimension;
use base 'Language::Farnsworth::Value';
require Language::Farnsworth::Value::Pari;
use Language::Farnsworth::Error;

{ #slight inefficiency here, but it fixes the circular reference issue
	my $time;
    sub TYPE_TIME	{return $time if $time; $time=new Language::Farnsworth::Value::Pari(0, {time=>1})}
}

use DateTime;
#use DateTime::Format::DateManip;
#use Date::Manip;
use DateTimeX::Easy;

use utf8;

our $VERSION = 0.6;

use overload 
    '+' => \&add,
    '-' => \&subtract,
    '*' => \&mult,
    '/' => \&div,
	'%' => \&mod,
	'**' => \&pow,
	'<=>' => \&compare,
	'bool' => \&bool;

use base qw(Language::Farnsworth::Value);

#this is the REQUIRED fields for Language::Farnsworth::Value subclasses
#
#dimen => a Language::Farnsworth::Dimension object
#
#this is so i can make a -> conforms in Language::Farnsworth::Value, to replace the existing code, i'm also planning on adding some definitions such as, TYPE_PARI, TYPE_STRING, TYPE_LAMBDA, TYPE_DATE, etc. to make certain things easier

sub new
{
  my $class = shift;
  my $value = shift;
  my $outmagic = shift; #i'm still not sure on this one

  error "Non string or date given as \$value to constructor" unless (ref($value) eq "" || ref($value) eq "DateTime") && defined($value);

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;

  if (ref($value) ne "DateTime")
  {
	my $dt = DateTimeX::Easy->parse($value);
	error "failed to parse date!" unless defined $dt;
	
	my $tz = $dt->time_zone();
	
	if ($tz->is_floating())
	{
	  $dt->set_time_zone('UTC'); #force it to UTC		
	}


	$self->{date} = $dt;
  }
  else
  {
	$self->{date} = $value;
  }
 
  return $self;
}

sub getdate
{
	return $_[0]->{date};
}

sub type
{
	return "Date";
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of Date" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  
  if ($two->isa("Language::Farnsworth::Value::Pari"))
  {
	  if ($two->conforms(TYPE_TIME()))
	  {
		  return new Language::Farnsworth::Value::Date($one->getdate()->clone()->add(seconds => "".$two->getpari()));
	  }
	  else
	  {
		  error "Scalar value given to addition of date";
	  }
  }
  else
  {
	  return $two->add($one, !$rev) unless ($two->ismediumtype());
	  
	  if (!$two->istype("Date"))
	  {
	    error "Given non date to date operation";
	  }

	  error "Adding dates does nothing useful.";
  }
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of dates" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  
  if ($two->isa("Language::Farnsworth::Value::Pari"))
  {
	  if ($two->conforms(TYPE_TIME()))
	  {
		 if (!$rev) #we're first!
		 {
			 return new Language::Farnsworth::Value::Date($one->getdate()->clone()->add(seconds => "".(-$two->getpari())));
		 }
		 else
		 {
			 error "And just now what is that supposed to do? a negative date? what the hell is that?";
		 }
	  }
	  else
	  {
		  error "Scalar value given to addition to string" if ($two->isa("Language::Farnsworth::Value::Pari"));
	  }
  }
  else
  {
	  return $two->subtract($one, !$rev) unless ($two->ismediumtype());
	  
	  if (!$two->istype("Date"))
	  {
	    error "Given non date to date operation";
	  }

	  my $diff;
	  $diff = $one->getdate()->subtract_datetime_absolute($two->getdate()) unless $rev;
	  $diff = $two->getdate()->subtract_datetime_absolute($one->getdate()) if $rev;

	  my ($secs, $nano) = $diff->in_units('seconds','nanoseconds');
	  my $rdiff = $secs + 0.000000001 *$nano;

	  my $ret = Language::Farnsworth::Value::Pari->new($rdiff, {time => 1});

	  return $ret;
  }
}

sub modulus
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus of date" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to modulus of date" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mod($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Date"))
  {
    error "Given non date to date operation";
  }

  error "Modulusing dates? what did you think this would do, create a black hole?";
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to multiplication of dates" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to multiplcation of dates" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mult($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Date"))
  {
    error "Given non date to date operation";
  }

  error "Multiplying dates? what did you think this would do, create a black hole?";
}

sub div
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to division" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to division to date" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->div($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Date"))
  {
    error "Given non date to dates operation";
  }

  error "Dividing dates? what did you think this would do, create a black hole?";
}

sub bool
{
	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
	#print "BOOLCONV\n";
	#print Dumper($self);
	#print "ENDBOOLCONV\n";
	return 1; #what else should it be?
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to exponentiation of dates" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Exponentiating dates? what did you think this would do, create a black hole?" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->pow($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Date"))
  {
    error "Given non date to date operation";
  }

  error "Exponentiating dates? what did you think this would do, create a black hole?";
}

sub compare
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to compare of dates" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to division of dates" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->compare($one, !$rev) unless ($two->ismediumtype());

  my $rv = $rev ? -1 : 1;
  #check for $two being a simple value
  my $tv = $two->getdate();
  my $ov = $one->getdate();

  #i also need to check the units, but that will come later
  #NOTE TO SELF this needs to be more helpful, i'll probably do something by adding stuff in ->new to be able to fetch more about the processing 
  error "Unable to process different types in compare of dates\n" unless $one->conforms($two); #always call this on one, since $two COULD be some other object 

  #moving this down so that i don't do any math i don't have to
  my $new = $ov <=> $tv;
  
  return $new * $rv;
}

