package Language::Farnsworth::Value::Boolean;

use strict;
use warnings;

use Language::Farnsworth::Dimension;
use Language::Farnsworth::Error;
use base 'Language::Farnsworth::Value';

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

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;

  $self->{truthiness} = $value ? 1 : 0;
  
  return $self;
}

sub gettruth
{
	return $_[0]->{truthiness};
}

sub type
{
	return "Boolean";
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of Boolean" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to addition of boolean" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->add($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }


  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Adding booleans is not a good idea\n"; 
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to subtraction of Boolean" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to subtraction to Booleans" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->subtract($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }

  error "Subtracting Booleans? what did you think this would do, create a black hole?";
}

sub modulus
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to modulus to boolean" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mod($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }

  error "Modulusing booleans? what did you think this would do, create a black hole?";
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to multiplication of boolean" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to multiplcation to boolean" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mult($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }

  error "Multiplying arrays? what did you think this would do, create a black hole?";
}

sub div
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to division of booleans" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to division of booleans" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->div($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }

  error "Dividing booleans? what did you think this would do, create a black hole?";
}

sub bool
{
	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
	#print "BOOLCONV\n";
	#print Dumper($self);
	#print "ENDBOOLCONV\n";
	return $self->gettruth()?1:0;
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to exponentiation of booleans" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Exponentiating booleans? what did you think this would do, create a black hole?" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->pow($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Boolean"))
  {
    error "Given non boolean to boolean operation";
  }


  error "Exponentiating arrays? what did you think this would do, create a black hole?";
}

sub compare
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to compare of boolean" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to division of boolean" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->compare($one, !$rev) unless ($two->ismediumtype());

  my $rv = $rev ? -1 : 1;
  #check for $two being a simple value
  my $tv = $two->gettruth();
  my $ov = $one->gettruth();

  #i also need to check the units, but that will come later
  #NOTE TO SELF this needs to be more helpful, i'll probably do something by adding stuff in ->new to be able to fetch more about the processing 
  error "Unable to process different types in compare of booleans\n" unless $one->conforms($two); #always call this on one, since $two COULD be some other object 

  #moving this down so that i don't do any math i don't have to
  my $new = $tv <=> $ov;
  
  return $new * $rv;
}

