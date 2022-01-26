package Form::Tiny::PathValue;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef);

use namespace::clean;

our $VERSION = '2.04';

has "path" => (
	is => "ro",
	isa => ArrayRef,
	required => 1,
);

has "value" => (
	is => "ro",
	writer => "set_value",
);

# Is this value here only to reproduce structure?
has "structure" => (
	is => "ro",
	default => 0,
);

1;
