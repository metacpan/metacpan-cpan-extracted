package Entities::Backend::Memory;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw/ArrayRef/;
use namespace::autoclean;

with 'Entities::Backend';

# ABSTRACT: A simple backend that stores all data in memory, for testing and development purposes.

=head1 NAME

Entities::Backend::Memory - A simple backend that stores all data in memory, for testing and development purposes.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	use Entities;
	use Entities::Backend::Memory;

	# see synopsis at L<Entities>

=head1 DESCRIPTION

This L<backend|Entities::Backend> for the L<Entities> user management
and authorization system stores all entities and relations between them
in memory. It is only meant for quick testing and rapid development. Please,
do not use this in production environments.

=head1 UNIQUE METHODS

The following method are unique to this backend only.

=head2 new()

Creates a new instance of this module.

=head2 roles( [\@roles] )

In scalar context, returns an array-ref of all <role objects|Entities::Role>
stored in memory. In list context returns an array. If a list of role
objects is provided, it will replace the current list.

=cut

has 'roles' => (
	is => 'rw',
	isa => ArrayRef
);

=head2 users( [\@users] )

In scalar context, returns an array-ref of all <user objects|Entities::User>
stored in memory. In list context returns an array. If a list of user
objects is provided, it will replace the current list.

=cut

has 'users' => (
	is => 'rw',
	isa => ArrayRef
);

=head2 actions( [\@actions] )

In scalar context, returns an array-ref of all <action objects|Entities::Action>
stored in memory. In list context returns an array. If a list of action
objects is provided, it will replace the current list.

=cut

has 'actions' => (
	is => 'rw',
	isa => ArrayRef
);

=head2 plans( [\@plans] )

In scalar context, returns an array-ref of all <plan objects|Entities::Plan>
stored in memory. In list context returns an array. If a list of plan
objects is provided, it will replace the current list.

=cut

has 'plans' => (
	is => 'rw',
	isa => ArrayRef
);

=head2 customers( [\@customers] )

In scalar context, returns an array-ref of all <customer objects|Entities::Customer>
stored in memory. In list context returns an array. If a list of customer
objects is provided, it will replace the current list.

=cut

has 'customers' => (
	is => 'rw',
	isa => ArrayRef
);

=head2 features( [\@features] )

In scalar context, returns an array-ref of all <feature objects|Entities::Feature>
stored in memory. In list context returns an array. If a list of feature
objects is provided, it will replace the current list.

=cut

has 'features' => (
	is => 'rw',
	isa => ArrayRef
);

=head1 METHODS IMPLEMENTED

The following methods implement the methods that the L<Entities::Backend>
Moose role requires backend classes to implement. See the documentation
of that role for more information on these methods.

=head2 get_user_from_id( $user_id )

=cut

sub get_user_from_id {
	my ($self, $id) = @_;

	foreach ($self->users) {
		return $_ if $_->id == $id;
	}

	return;
}

=head2 get_user_from_name( $username )

=cut

sub get_user_from_name {
	my ($self, $username) = @_;

	foreach ($self->users) {
		return $_ if $_->username eq $username;
	}

	return;
}

=head2 get_role( $role_name )

=cut

sub get_role {
	my ($self, $name) = @_;

	foreach ($self->roles) {
		return $_ if $_->name eq $name;
	}

	return;
}

=head2 get_customer( $customer_name )

=cut

sub get_customer {
	my ($self, $name) = @_;

	foreach ($self->customers) {
		return $_ if $_->name eq $name;
	}

	return;
}

=head2 get_plan( $plan_name )

=cut

sub get_plan {
	my ($self, $name) = @_;

	foreach ($self->plans) {
		return $_ if $_->name eq $name;
	}

	return;
}

=head2 get_feature( $feature_name )

=cut

sub get_feature {
	my ($self, $name) = @_;

	foreach ($self->features) {
		return $_ if $_->name eq $name;
	}

	return;
}

=head2 get_action( $action_name )

=cut

sub get_action {
	my ($self, $name) = @_;

	foreach ($self->actions) {
		return $_ if $_->name eq $name;
	}

	return;
}

=head2 save( $obj )

=cut

sub save {
	my ($self, $obj) = @_;

	unless ($obj->has_id) {
		my $coll =	$obj->isa('Entities::User') ? 'users' :
				$obj->isa('Entities::Role') ? 'roles' :
				$obj->isa('Entities::Action') ? 'actions' :
				$obj->isa('Entities::Feature') ? 'features' :
				$obj->isa('Entities::Plan') ? 'plans' :
				$obj->isa('Entities::Customer') ? 'customers' :
				'unknown';

		croak "Can't find out the type of object received, it is not a valid Entity"
			if $coll eq 'unknown';

		my @array = $self->$coll;
		$obj->_set_id(scalar @array + 1);
		push(@array, $obj);
		$self->$coll(\@array);
	}

	return 1;
}

=head1 METHOD MODIFIERS

The following list documents any method modifications performed through
the magic of L<Moose>.

=head2 around qw/roles actions users plans customers features/

If any of the above methods are called in list context, this method
modifier will automatically dereference the results into an array.

=cut

around qw/roles actions users plans customers features/ => sub {
	my ($orig, $self) = (shift, shift);

	if (scalar @_) {
		return $self->$orig(@_);
	} else {
		my $ret = $self->$orig || [];
		return wantarray ? @$ret : $ret;
	}
};

=head1 SEE ALSO

L<Entities>, L<Entities::Backend>, L<Entities::Backend::MongoDB>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities::Backend::Memory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Entities>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Entities>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Entities>

=item * Search CPAN

L<http://search.cpan.org/dist/Entities/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
