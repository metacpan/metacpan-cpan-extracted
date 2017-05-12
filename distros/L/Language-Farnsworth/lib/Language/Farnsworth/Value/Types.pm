package Language::Farnsworth::Value::Types;

use strict;
use warnings;

use base qw/Exporter/;

require Language::Farnsworth::Value::Boolean;
require Language::Farnsworth::Value::Array;
require Language::Farnsworth::Value::String;
require Language::Farnsworth::Value::Date;
require Language::Farnsworth::Value::Pari;
require Language::Farnsworth::Value::Lambda;
require Language::Farnsworth::Value::Undef;

our @EXPORT = qw(TYPE_BOOLEAN TYPE_STRING TYPE_DATE TYPE_PLAIN TYPE_TIME TYPE_LAMBDA TYPE_UNDEF TYPE_ARRAY VALUE_ONE);


{
	my $boolean;
	my $string;
	my $date;
	my $plain;
	my $time;
	my $lambda;
	my $undef;
	my $array;
	my $valueone;

	sub TYPE_BOOLEAN{return $boolean if $boolean; $boolean=new Language::Farnsworth::Value::Boolean(0)}
	sub TYPE_STRING	{return $string if $string; $string=new Language::Farnsworth::Value::String("")}
	sub TYPE_DATE	{return $date if $date; $date=new Language::Farnsworth::Value::Date("today")}
	#this tells it that it is the same as a constraint of "1", e.g. no units
	sub TYPE_PLAIN 	{return $plain if $plain; $plain=new Language::Farnsworth::Value::Pari(0)}
	sub VALUE_ONE   {return $valueone if $valueone; $valueone=new Language::Farnsworth::Value::Pari(1,{},undef,undef,1)}
	#this tells it that it is the same as a constraint of "1 s", e.g. seconds
	sub TYPE_TIME	{return $time if $time; $time=new Language::Farnsworth::Value::Pari(0, {time=>1})}
	sub TYPE_LAMBDA	{return $lambda if $lambda; $lambda=new Language::Farnsworth::Value::Lambda()}
	sub TYPE_UNDEF  {return $undef if $undef; $undef=new Language::Farnsworth::Value::Undef()}
	sub TYPE_ARRAY	{return $array if $array; $array=new Language::Farnsworth::Value::Array([])}
}

1;