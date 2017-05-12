package Language::Farnsworth::Value::String;

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
  my $value = shift;
  my $lang = shift;
  my $outmagic = shift; #i'm still not sure on this one

  error "Non string given as \$value to constructor" unless ref($value) eq "" && defined($value);

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;

  {
	no warnings 'uninitialized';
	$self->{string} = "".$value;
  }
  $self->{lang} = $lang || "";
  
  return $self;
}

sub getstring
{
	return $_[0]->{string};
}

sub getlang
{
	return $_[0]->{lang};
}

sub type
{
	return "String";
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of string" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to addition of string" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->add($one, !$rev) unless ($two->ismediumtype());

  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }


  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  my $new;
  $new = $one->getstring() . $two->getstring() unless $rev;
  $new = $two->getstring() . $one->getstring() if $rev;

  my $lang = "";
  $lang = $one->getlang() if ($one->getlang() eq $two->getlang()); #if we know their language, and they're the same, just keep it

  return new Language::Farnsworth::Value::String($new); #return new string
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to subtraction of string" unless (ref($two));

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to subtraction to strings" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->subtract($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }

  error "Subtracting strings? what did you think this would do, create a black hole?";
}

sub modulus
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus of string" unless (ref($two));

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to modulus of string" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mod($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }

  error "Modulusing strings? what did you think this would do, create a black hole?";
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to multiplication of string" unless (ref($two));

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to multiplcation of string" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mult($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }

  error "Multiplying strings? what did you think this would do, create a black hole?";
}

sub div
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to division of string" unless (ref($two));

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to division of string" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->div($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }

  error "Dividing string? what did you think this would do, create a black hole?";
}

sub bool
{
	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
	#print "BOOLCONV\n";
	#print Dumper($self);
	#print "ENDBOOLCONV\n";
	return length($self->getstring())?1:0;
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error  "Non reference given to exponentiation of string" unless (ref($two));

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Exponentiating strings? what did you think this would do, create a black hole?" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->pow($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("String"))
  {
    error "Given non string to string operation";
  }
  
  error "Exponentiating strings? what did you think this would do, create a black hole?";
}

sub __compare
{
	my ($a1, $a2) = @_;
	my $same = 0;
	my $ea = each_array(@$a1, @$a2);
	
	while(my ($first, $second) = $ea->()) 
	{ 
		$same = $first > $second ? 1 : -1 and last if $first != $second 
	} # shortcircuits

	return $same;
}

sub compare
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to compare of string" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to division to string" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->compare($one, !$rev) unless ($two->ismediumtype());

  my $rv = $rev ? -1 : 1;
  #check for $two being a simple value
  my $tv = $two->getstring();
  my $ov = $one->getstring();

  #i also need to check the units, but that will come later
  #NOTE TO SELF this needs to be more helpful, i'll probably do something by adding stuff in ->new to be able to fetch more about the processing 
  error "Unable to process different units in compare\n" unless $one->conforms($two); #always call this on one, since $two COULD be some other object 

  #moving this down so that i don't do any math i don't have to
  my $new = $ov cmp $tv;
  
  return $new * $rv;
}

