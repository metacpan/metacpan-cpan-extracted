package Lorem::Role::Style::HasDimensions;
{
  $Lorem::Role::Style::HasDimensions::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Lorem::Types qw( LoremStyleDimension );
use MooseX::Types::Moose qw( Undef );

has [qw(width height)] => (
    is => 'rw',
    isa => LoremStyleDimension|Undef,
);

has [qw(min_width min_height)] => (
    is => 'rw',
    isa => LoremStyleDimension|Undef,
);

has [qw(max_width max_height)] => (
    is => 'rw',
    isa => LoremStyleDimension|Undef,
);



1;
