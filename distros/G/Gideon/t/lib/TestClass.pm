package TestClass;
use Moose;

with 'Gideon::Meta::Class::Trait::Persisted';

has id => ( is => 'rw', isa => 'Num' );

__PACKAGE__->meta->make_immutable;
1;
