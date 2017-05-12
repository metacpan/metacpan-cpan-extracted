package Elive::DAO::Array;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

use parent qw{Elive::DAO::_Base};

use Scalar::Util;
use Elive::Util;

__PACKAGE__->mk_classdata('element_class');
__PACKAGE__->mk_classdata('separator' => ',');
__PACKAGE__->has_metadata( '_is_copy' );

=head1 NAME

Elive::DAO::Array - Base class for arrays

=head1 DESCRIPTION

Base class for arrays within entities. E.g. members property of
Elive::Entity::participantList.

=cut

=head1 METHODS

=cut

sub _build_array {
    my $class = shift;
    my $spec = shift;

    my $type = Elive::Util::_reftype( $spec );
    $spec = [$spec] if ($type && $type ne 'ARRAY');

    my @args;

    if ($type) {
	@args = map {Elive::Util::string($_)} @$spec;
    }
    else {
	@args = split($class->separator, Elive::Util::string($spec));
    }

    return \@args;
}

our $class = __PACKAGE__;
coerce $class => from 'ArrayRef|Str'
          => via {
	      $class->new( $_ );
          };

=head2 stringify

Serialises array members by joining individual elements.

=cut

sub stringify {
    my $class = shift;
    my $spec  = shift;
    my $type = shift || $class->element_class;

    $spec = $class
	if !defined $spec && ref $class;
    my $arr = $class->_build_array( $spec );

    return join($class->separator, sort map {Elive::Util::string($_, $type)} @$arr)
}

=head2 new

   my $array_obj = Elive::DAO::Array->new($array_ref);

=cut

sub new {
    my ($class, $spec) = @_;
    my $array = $class->_build_array( $spec );
    return bless($array, $class);
}

=head2 add 

    $group->members->add('111111', '222222');

Add elements to an array.

=cut

sub add {
    my ($self, @elems) =  @_;

    if (my $element_class = $self->element_class) {
	foreach (@elems) {
	    $_ = $element_class->new($_)
		if ref && ! Scalar::Util::blessed($_);
	}
    }

    push (@$self, @elems);

    return $self;
}

1;
