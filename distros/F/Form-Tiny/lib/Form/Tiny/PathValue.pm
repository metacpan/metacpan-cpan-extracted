package Form::Tiny::PathValue;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(ArrayRef);

use namespace::clean;

our $VERSION = '1.11';

has "path" => (
	is => "ro",
	isa => ArrayRef,
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
