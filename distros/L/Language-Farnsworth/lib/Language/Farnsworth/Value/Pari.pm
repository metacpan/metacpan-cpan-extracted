package Language::Farnsworth::Value::Pari;

use strict;
use warnings;
no warnings 'redefine'; #wtf are these coming from?

use Math::Pari;
use Language::Farnsworth::Dimension;
use base 'Language::Farnsworth::Value';
use Language::Farnsworth::Error;
use Data::Dumper;

use utf8;

our $VERSION = 0.5;

use overload 
    '+' => \&add,
    '-' => \&subtract,
    '*' => \&mult,
    '/' => \&div,
	'%' => \&mod,
	'**' => \&pow,
	'<=>' => \&compare,
	'bool' => \&bool,
	'"' => \&toperl;

use base qw(Language::Farnsworth::Value);

{
	my $plain;
	sub TYPE_PLAIN 	{return $plain if $plain; $plain=new Language::Farnsworth::Value::Pari(0)}
}

#this is the REQUIRED fields for Language::Farnsworth::Value subclasses
#
#dimen => a Language::Farnsworth::Dimension object
#
#this is so i can make a -> conforms in Language::Farnsworth::Value, to replace the existing code, i'm also planning on adding some definitions such as, TYPE_PARI, TYPE_STRING, TYPE_LAMBDA, TYPE_DATE, etc. to make certain things easier

sub new
{
  my $class = shift;
  my $value = shift;
  my $dimen = shift; #should only really be used internally?
  my $outmagic = shift; #i'm still not sure on this one
  my $hex = shift;
  my $valueone = shift; #sentinal value 

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;
  $self->{valueone} = $valueone; #sentinal value for increment and postcrement, ignores dimens

  if (ref($dimen) eq "Language::Farnsworth::Dimension")
  {
    $self->{dimen} = $dimen;
  }
  else
  {
	  $dimen = {} if !defined($dimen);
	  $self->{dimen} = new Language::Farnsworth::Dimension($dimen);
  }

  $value =~ s/(ee|E)/e/i; #fixes double ee's, i could probably eventually remove this, but it doesn't do any harm for now
  
  if ($hex)
  {
	$self->{pari} = parsehex($value);
  }
  else
  {
	$self->{pari} = PARI $value;
  }

  return $self;
}

sub isvalueone
{
	return $_[0]->{valueone};
}

sub type
{
	my $self = shift;
	my $scope = shift;
	return $self->{dimen}->Dump($scope); #TODO: This should instead use the output code once it moves here.
}

#helpers for parsing hex, binary, and octal formats, could also extend support to others
sub parsehex
{
    my $input = shift;
    if ($input =~ /0x(.*)/i)
    {
		return parsedigits(16, $1, $input);
    }
    elsif ($input =~ /0b(.*)/i)
    {
		return parsedigits(2, $1, $input);
    }
	elsif ($input =~ /0(.*)/i)
    {
		return parsedigits(8, $1, $input);
    }
	else
	{
		error("How did you manage to get here? \$input=$input at Pari.pm");
	}
}

sub parsedigits
{
	my ($base, $digits, $input) = @_;
	my $value = PARI '0';
	my $div = $value + 1.0;
	my $flag = 0;

	for my $d (split //, $digits)
	{
		$flag=1,next if ($d eq '.' && !$flag); #only set $flag once, that way it'll trigger invalid digit properly afterwords
		my $v = checkdigit($d, $base, $input);
		$value = $value * $base + $v; #build it up from left to right we need to multiply by $base each iterartion, starting at 0 this causes no issues at all
		$div *= $base if $flag;		
	}

	return $value/$div if $flag;
	return $value;
}

sub checkdigit
{
	my ($digit, $base, $input) = @_;
	my $valid = "0123456789ABCDEF";
	my $v = index($valid, uc $digit);

	print("Invalid digit '$digit' in number '$input' for base $base");

	if ($v == -1 || $v >= $base)
	{
		error("Invalid digit '$digit' in number '$input' for base $base");
	}

	return $v;
}

####
#THESE FUNCTIONS WILL BE MOVED TO Language::Farnsworth::Value, or somewhere more appropriate

sub getdimen
{
	my $self = shift;
	return $self->{dimen};
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub getpari
{
	my $self = shift;
	return $self->{pari};
}

sub toperl
{
	my $self = shift;
	return $self->getpari()."";
}

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of scalar" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->add($one, !$rev) unless ($two->isa(__PACKAGE__));

  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Unable to process different units in addition\n" unless ($one->conforms($two)); 

  #moving this down so that i don't do any math i don't have to

  #ONLY THIS MODULE SHOULD EVER TOUCH ->{pari} ANYMORE! this might change into, NEVER
  return new Language::Farnsworth::Value::Pari($one->getpari() + $two->getpari(), $one->getdimen());
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to subtraction of scalar" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->subtract($one, !$rev) unless ($two->isa(__PACKAGE__));

  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Unable to process different units in subtraction\n" unless ($one->conforms($two)); 

  #moving this down so that i don't do any math i don't have to
  if (!$rev)
  {
	  return new Language::Farnsworth::Value::Pari($one->getpari() - $two->getpari(), $one->getdimen()); #if !$rev they are in order
  }
  else
  {
	  #i've never seen this happen, we'll see if it works
	  error "some mistake happened here in subtraction\n"; #to test later on
  }
}

sub mod
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus" unless (ref($two));

  #as odd as this seems, we need it in order to allow overloading later on
  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->mod($one, !$rev) unless ($two->isa(__PACKAGE__));

  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Unable to process different units in modulus\n" unless ($one->conforms($two)); 

  #moving this down so that i don't do any math i don't have to
  if (!$rev)
  {
	  return new Language::Farnsworth::Value::Pari($one->getpari() % $two->getpari(), $one->getdimen()); #if !$rev they are in order
  }
  else
  {
      return new Language::Farnsworth::Value::Pari($two->getpari() % $one->getpari(), $one->getdimen()); #if !$rev they are in order
  }
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "ARRAY REF WTF?" if (ref($two) eq "ARRAY");
  error "Non reference given to multiplication of scalar" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->mult($one, !$rev) unless ($two->isa(__PACKAGE__));

  my $nd = $one->getdimen()->merge($two->getdimen()); #merge the dimensions! don't cross the streams though

  #moving this down so that i don't do any math i don't have to
  return new Language::Farnsworth::Value::Pari($one->getpari() * $two->getpari(), $nd);
}

sub div
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to division of scalar" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->div($one, !$rev) unless ($two->isa(__PACKAGE__));

  #these are a little screwy SO i'll probably comment them more later
  #probably after i find out that they're wrong
  my $qd = $rev ? $two->getdimen() : $one->getdimen();
  my $dd = $rev ? $one->getdimen()->invert() : $two->getdimen()->invert();

  my $nd = $qd->merge($dd);
  
  if (!$rev)
  {
	  return new Language::Farnsworth::Value::Pari($one->getpari() / $two->getpari(), $nd); #if !$rev they are in order
  }
  else
  {
      return new Language::Farnsworth::Value::Pari($two->getpari() / $one->getpari(), $nd); #if !$rev they are in order
  }
}

sub bool
{
	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
#	print "PARI BOOLCONV\n";
	#print Dumper($self);
	#print "ENDBOOLCONV\n";
	return $self->getpari()?1:0;
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to exponentiation of scalar" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->pow($one, !$rev) unless ($two->isa(__PACKAGE__));

  if (!$two->conforms($one->TYPE_PLAIN))
  {
	  error "A number with units as the exponent doesn't make sense";
  }

  #moving this down so that i don't do any math i don't have to
  my $new;
  if (!$rev)
  {
	  $new = new Language::Farnsworth::Value::Pari($one->getpari() ** $two->getpari(), $one->getdimen()->mult($two->getpari())); #if !$rev they are in order
  }
  else
  {
	  error "Wrong order in ->pow()";
  }

  return $new;
}

sub compare
{
  my ($one, $two, $rev) = @_;
  
  error "Non reference given to exponentiation" unless (ref($two));

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  return $two->compare($one, !$rev) unless ($two->isa(__PACKAGE__));

  my $rv = $rev ? -1 : 1;
  #check for $two being a simple value
  my $tv = $two->getpari();
  my $ov = $one->getpari();

  #i also need to check the units, but that will come later
  #NOTE TO SELF this needs to be more helpful, i'll probably do something by adding stuff in ->new to be able to fetch more about the processing 
  error "Unable to process different units in compare\n" unless $one->conforms($two); #always call this on one, since $two COULD be some other object 

  #moving this down so that i don't do any math i don't have to
  my $new;
  
  if ($ov == $tv)
  {
	return 0;
  }
  elsif ($ov < $tv)
  {
	return -1;
  }
  elsif ($ov > $tv)
  {
	return 1;
  }
}

1;