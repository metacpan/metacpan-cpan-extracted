package Elive::DAO::_Base;
use warnings; use strict;

use parent qw{Class::Data::Inheritable};

=head1 NAME

Elive::DAO::_Base - Base class for DAO objects

=cut

our $DEBUG;
BEGIN {
    $DEBUG = $ENV{ELIVE_DEBUG};
}

sub debug {
    my ($class, $level) = @_;

    if (defined $level) {
	$DEBUG = $level;
    }

    return $DEBUG || 0;
}

sub _refaddr {
    my $self = shift;
    return Scalar::Util::refaddr( $self );
}

our %Meta_Data;

#
# create metadata properties. NB this will be stored inside out to
# ensure our object is an exact image of the data.
#

=head2 has_metadata

Associate an inside-out property with objects of a given class.

=cut

sub has_metadata {

    my $class = shift;
    my $accessor = shift;

    my $accessor_fun = $class->can($accessor);

    unless ($accessor_fun) {

	no strict 'refs';

	$accessor_fun = sub {
	    my $self = shift;
	    my $ref = $self->_refaddr
		or return;

	    if (@_) {
		$Meta_Data{ $ref }{ $accessor } = $_[0];
	    }

	    return $Meta_Data{ $ref }{ $accessor };
	};

	*{$class.'::'.$accessor} = $accessor_fun;
    }

    return $accessor_fun;
}

__PACKAGE__->mk_classdata('_connection');
__PACKAGE__->has_metadata('_object_connection');

sub connection {
    my $self = shift;
    my $connection;
    $connection = $self->_object_connection(@_)
	if ref $self;
    $connection ||= $self->_connection(@_);
    return $connection;
}

sub DEMOLISH {
    my $self = shift;
    delete $Meta_Data{ $self->_refaddr };
    return;
}

1;
