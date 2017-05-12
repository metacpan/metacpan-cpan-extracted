package Lorem::Role::HasHeaderFooter;
{
  $Lorem::Role::HasHeaderFooter::VERSION = '0.22';
}
use Moose::Role;

use Lorem::Types qw( MaybeLoremDoesStamp );
use MooseX::SemiAffordanceAccessor;

has 'header' => (
    is => 'rw',
    isa => 'Maybe[Lorem::Element::Box]',
    default => undef,
);

has 'header_margin' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);

has 'footer' => (
    is => 'rw',
    isa => 'Maybe[Lorem::Element::Box]',
    default => undef,
);

has 'footer_margin' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);



1;
