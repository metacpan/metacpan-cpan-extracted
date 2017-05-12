package Language::Farnsworth::Units;

use strict;
use warnings;

use Data::Dumper;
use Language::Farnsworth::Value::Pari;
use Math::Pari;
use Language::Farnsworth::Output;
use Language::Farnsworth::Error;

our $lock = 0;

sub new
{
	#i should make a constructor that copies, but that'll come later
	my $self = {units=>{1=>new Language::Farnsworth::Value::Pari(1)}, dimens=>{}}; #hack to make things work right
	bless $self;
}

sub addunit
{
	my $self = shift;
	my $name = shift;
	my $value = shift;

	error("won't redefine existing units") if (exists($self->{units}{$name}) && $lock);
	$self->{units}{$name} = $value;
	$self->{units}{$name."s"} = $value; #HACK! #causes issues with ms not meaning milliseconds, need to change lookup code!
}

sub getunit
{
	my $self = shift;
	my $name = shift;

	my $return;

	if ($self->_isunit($name))
	{
		$return = $self->{units}{$name};
	}
	elsif ($self->hasprefix($name))
	{
		my ($preval, undef, $realname) = $self->getprefix($name);
#		print "GETTING PREFIXES: $name :: $preval :: $realname ::".Dumper($preval, $realname) if (($name eq "mg") || ($name eq "l") || $name eq "milli");

		$return = $preval * $self->{units}{$realname};
	}

#	print "GETTING UNIT: $name : $return : ".Dumper($return) if (($name eq "mg") || ($name eq "l") || $name eq "milli");
	return $return;
}

sub hasprefix
{
	my $self = shift;
	my $name = shift;

	#sort them by length, solves issues with longer ones not being found first
	my @keys = keys %{$self->{prefix}};
	for my $pre (sort {length($b) <=> length($a)} @keys)
	{
		if ($name =~ /^\Q$pre\E(.*)$/)
		{
			return 1 if ($self->_isunit($1) || !length($1));
		}
	}
	return 0; #no prefix!
}

sub getprefix
{
	my $self = shift;
	my $name = shift;

	#sort them by length, solves issues with longer ones not being found first
	for my $pre (sort {length($b) <=> length($a)} keys %{$self->{prefix}})
	{
		#print "CHECKING PREFIX: $pre\n" if ($name eq "mg");
		if ($name =~ /^\Q$pre\E(.*)$/)
		{
			my $u = $1;
			#print "FOUND: $name == $pre * $u\n";
			#print Dumper($self->{prefix}{$pre}) if ($name eq "mg");
			$u = 1 unless length($1); #to make certain things work right
			return ($self->{prefix}{$pre},$pre,$u) if ($self->_isunit($1) || !length($1));
		}
	}
	return undef; #to cause errors when not there
}

sub isunit
{
	my $self = shift;
	my $name = shift;

	return $self->hasprefix($name) || $self->_isunit($name); 
}

sub _isunit
{
	my $self = shift;
	my $name = shift;
	return exists($self->{units}{$name});
}

sub adddimen
{
	my $self = shift;
	my $name = shift;
	my $default = shift; #primitive unit for the dimension, all other units are defined against this
	my $val = new Language::Farnsworth::Value::Pari(1, {$name => 1}); #i think this is right
	Language::Farnsworth::Output::addcombo($name,$val);
	$self->{dimens}{$name} = $default;
    $self->addunit($default, $val);
}

#is this useful? yes, need it for display
sub getdimen
{
	my $self = shift;
	my $name = shift;

	return $self->{dimens}{$name};
}

sub setprefix
{
	my $self = shift;
	my $name = shift;
	my $value = shift;

	#print "SETTING PREFIX: $name : $value\n" if ($name eq "m");
	$self->{prefix}{$name} = $value;
}

1;
