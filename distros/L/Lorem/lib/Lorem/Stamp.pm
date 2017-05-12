package Lorem::Stamp;
{
  $Lorem::Stamp::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

with 'Lorem::Role::Stamp';

has 'macro' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
    default => sub { },
);

sub imprint {
    my ($self, $doc) = @_;    
    &{$self->macro}(@_);
}


1;
