package Form::Tiny::FieldData;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef InstanceOf);
use Form::Tiny::PathValue;

use namespace::clean;

our $VERSION = '1.13';

has "items" => (
	is => "ro",
	isa => ArrayRef [
		(InstanceOf ["Form::Tiny::PathValue"])
		->plus_coercions(
			[
				ArrayRef, q{
					Form::Tiny::PathValue->new(
						path => shift @$_,
						value => shift @$_,
						structure => shift @$_
					)
				}
			]
		)
	],
	coerce => 1,
);

1;
