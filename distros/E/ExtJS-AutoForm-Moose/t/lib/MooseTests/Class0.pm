package MooseTests::Class0;

use Moose;
use JSON::Any;

use Moose::Util::TypeConstraints;

with "ExtJS::AutoForm::Moose";

# Simple attributes
has 'str'   => ( is => "rw", isa => "Str" );
has 'num'   => ( is => "rw", isa => "Num" );
has 'int'   => ( is => "rw", isa => "Int" );
has 'bool'  => ( is => "rw", isa => "Bool" );
has 'tenum' => ( is => "rw", isa => enum([qw(val1 val2 val3)]) );

# Read-only attributes
has 'str_ro'   => ( is => "ro", isa => "Str" );
has 'num_ro'   => ( is => "ro", isa => "Num" );
has 'int_ro'   => ( is => "ro", isa => "Int" );
has 'bool_ro'  => ( is => "ro", isa => "Bool" );
has 'tenum_ro' => ( is => "ro", isa => enum([qw(val1 val2 val3)]) );

1;
