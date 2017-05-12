package Language::Farnsworth::Value::Undef;

use strict;
use warnings;

use Language::Farnsworth::Dimension;
use base 'Language::Farnsworth::Value';
use Language::Farnsworth::Error;

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
  my $outmagic = shift; #i'm still not sure on this one

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;
 
  return $self;
}

sub type
{
	return "undef";
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of undef" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to addition to undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->add($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undef operation";
  }

  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Adding undefs is not a good idea\n"; 
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to subtraction of undef" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to subtraction to undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->subtract($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undef operation";
  }

  error "Subtracting undef? what did you think this would do, create a black hole?";
}

sub modulus
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus of undef" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to modulus to undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mod($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undefoperation";
  }

  error "Modulusing undef? what did you think this would do, create a black hole?";
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to multiplication of undef" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to multiplcation of undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mult($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undef operation";
  }

  error "Multiplying undefs? what did you think this would do, create a black hole?";
}

sub div
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to division of undef" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to division of undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->div($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undef operation";
  }

  error "Dividing undef? what did you think this would do, create a black hole?";
}

sub bool
{
	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
	#print "BOOLCONV\n";
	#print Dumper($self);
	#print "ENDBOOLCONV\n";
	return 0;
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to exponentiation of undef" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Exponentiating undef? what did you think this would do, create a black hole?" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->pow($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Undef"))
  {
    error "Given non undef to undef operation";
  }


  error "Exponentiating undefs? what did you think this would do, create a black hole?";
}

sub compare
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to compare of undef" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to compare of undef" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->compare($one, !$rev) unless ($two->ismediumtype());

  return 0;
}

sub toperl
{
	return undef;
}
