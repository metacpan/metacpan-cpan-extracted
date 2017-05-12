package Entities::Customer;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use DateTime;
use Moo;
use MooX::Types::MooseLike::Base qw/Any Str ArrayRef/;
use MooX::Types::MooseLike::Email qw/EmailAddress/;
use Scalar::Util qw/blessed/;
use namespace::autoclean;

# ABSTRACT: An abstract entity that owns users and subscribes to plans.

=head1 NAME

Entities::Customer - An abstract entity that owns users and subscribes to plans.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	used internally, see L<Entities>

=head1 DESCRIPTION

A customer is a company, organization or individual that have subscribed
to use the services of your L<ability-based|Abilities> webapp, possibly
paying for it. This customer entity can subscribe to different <plans|Entities::Plan>
and use the <features|Entities::Feature> provided with these plans (or
explicitely given to the customer). The customer is the parent of one or
more <users|Entities::User>. If a user belongs to a certain company, they
will only be able to perform actions according to the limits and features
provided with the customer's plans.

This entity class C<does> the L<Abilities::Features> L<Moose role|Moose::Role>.

NOTE: you are not meant to create customer objects directly, but only through
the C<new_customer()> method in L<Entities>.

=head1 METHODS

=head2 new( name => 'somecustomer', email_address => 'customer@customer.com',
[ features => [], plans => [], created => $dt_obj, modified => $other_dt_obj,
parent => $entities_obj, id => 123 ] )

Creates a new instance of this module. Only 'name' and 'email_address'
are required.

=head2 id()

Returns the ID of the customer, if set.

=head2 has_id()

Returns a true value if the customer object has an ID attribute.

=head2 _set_id( $id )

Sets the ID of the customer object to the provided value. Only to be used
internally.

=cut

has 'id' => (
	is => 'ro',
	isa => Any,
	predicate => 'has_id',
	writer => '_set_id'
);

=head2 name()

Returns the name of the customer.

=cut

has 'name' => (
	is => 'ro',
	isa => Str,
	required => 1
);

=head2 email_address()

Returns the email address of the customer. In case of a company or organization,
this should probably be a certain contact in the organization, possibly
in the financial department.

=head2 set_email_address( $email )

Changes the email address of the customer to the provided value.

=cut

has 'email_address' => (
	is => 'ro',
	isa => EmailAddress,
	required => 1,
	writer => 'set_email_address'
);

=head2 plans( [\@plans] )

In scalar context, returns an array-ref of all plan names that customer
is subscribed to. In list context, returns an array. If an array-ref of
plan names is provided, it will replace the current list of plans of the
customer.

=head2 has_plans()

Returns a true value if the customer is subscribed to any plan.

=cut

has 'plans' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_plans'
);

=head2 features( [\@features] )

In scalar context, returns an array-ref of all feature names that have
been provided for the customer (directly! not through plans). In list context
returns an array. If an array-ref of feature names is provided, it will
replace the current list of features the customer owns.

=head2 has_features()

Returns a true value if the customer has been provided with any feature
directly.

=cut

has 'features' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_features'
);

=head2 created()

Returns a L<DateTime> object in the time the customer object has been
created.

=cut

has 'created' => (
	is => 'ro',
	isa => sub { croak 'created must be a DateTime object' unless blessed $_[0] && blessed $_[0] eq 'DateTime' },
	default => sub { DateTime->now() }
);

=head2 modified( [$dt] )

Returns a L<DateTime> object in the last time the customer object has been
modified. If a DateTime object is provided, it will be set as the new
value of this attribute.

=cut

has 'modified' => (
	is => 'rw',
	isa => sub { croak 'modified must be a DateTime object' unless blessed $_[0] && blessed $_[0] eq 'DateTime' },
	default => sub { DateTime->now() }
);

=head2 parent()

Returns the L<Entities::Backend> instance that stores this object.

=cut

has 'parent' => (
	is => 'ro',
	isa => sub { croak 'parent must be an Entities::Backend' unless blessed $_[0] && $_[0]->does('Entities::Backend') },
	weak_ref => 1
);

with 'Abilities::Features';

=head2 add_plan( $plan_name )

Subscribes the customer to the plan named C<$plan_name>. Croaks if the
plan does not exist, warns if the customer is already subscribed to it.
Returns the customer object itself.

=cut

sub add_plan {
	my ($self, $plan_name) = @_;

	croak "You must provide a plan name." unless $plan_name;

	# is the customer already in this plan?
	if ($self->in_plan($plan_name)) {
		carp "Customer ".$self->name." is already in plan $plan_name.";
		return $self;
	}

	# find the plan, does it exist?
	my $plan = $self->get_plan($plan_name);
	croak "plan $plan_name does not exist." unless $plan;

	# add the customer to the plan
	my @plans = $self->plans;
	push(@plans, $plan_name);
	$self->plans(\@plans);

	return $self;
}

=head2 drop_plan( $plan_name )

Cancels the customer's subscription to the plan named C<$plan_name>. Warns
if the customer is not subscribed to that plan. Will not croak if the
plan doesn't exist. Returns the customer object itself.

=cut

sub drop_plan {
	my ($self, $plan_name) = @_;

	croak "You must provide a plan name." unless $plan_name;

	# is the customer even in this plan?
	unless ($self->in_plan($plan_name)) {
		carp "Customer ".$self->name." doesn't have plan $plan_name.";
		return $self;
	}

	# remove the plan
	my @plans;
	foreach ($self->plans) {
		next if $_ eq $plan_name;
		push(@plans, $_);
	}
	$self->plans(\@plans);

	return $self;
}

=head2 add_feature( $feature_name )

Gives the customer the feature named C<$feature_name>. Croaks if the feature
does not exist, warns if it's already provided to the customer. Returns
the customer object itself.

=cut

sub add_feature {
	my ($self, $feature_name) = @_;

	croak "You must provide a feature name." unless $feature_name;

	# does the customer already have that feature?
	if ($self->has_direct_feature($feature_name)) {
		carp "Customer ".$self->name." already has feature $feature_name.";
		return $self;
	}

	# find the feature, does it exist?
	my $feature = $self->parent->get_feature($feature_name);
	croak "Feature $feature_name does not exist." unless $feature;

	# add the feature to the customer
	my @features = $self->features;
	push(@features, $feature_name);
	$self->features(\@features);

	return $self;
}

=head2 drop_feature( $feature_name )

Removes the feature named C<$feature_name> from the customer. This only
removes the feature if it was directly provided to the customer, and not
through plans, so it's possible the customer might still have that feature
after removal if they are still subscribed to a plan that provides it.

Warns if the customer doesn't have that feature, doesn't croak if the
feature does not exist at all. Returns the customer object itself.

=cut

sub drop_feature {
	my ($self, $feature_name) = @_;

	croak "You must provide a feature name." unless $feature_name;

	# does the customer even have this feature?
	unless ($self->has_direct_feature($feature_name)) {
		carp "Customer ".$self->name." doesn't have feature $feature_name.";
		return $self;
	}

	# remove the feature
	my @features;
	foreach ($self->features) {
		next if $_ eq $feature_name;
		push(@features, $_);
	}
	$self->features(\@features);

	return $self;
}

=head2 has_direct_feature( $feature_name )

Returns a true value if the customer was directly provided with the
feature named C<$feature_name>.

=cut

sub has_direct_feature {
	my ($self, $feature_name) = @_;

	unless ($feature_name) {
		carp "You must provide a feature name.";
		return;
	}

	# find the feature
	foreach ($self->features) {
		return 1 if $_ eq $feature_name;
	}

	return;
}

=head2 get_plan( $plan_name )

Returns the plan object of the plan named C<$plan_name>.

=cut

sub get_plan { shift->parent->get_plan(@_) }

=head1 METHOD MODIFIERS

The following list documents any method modifications performed through
the magic of L<Moose>.

=head2 around qw/plans features/

If the C<plans()> and C<features()> methods are called with no arguments
and in list context - will automatically dereference the array-ref into
arrays.

=cut

around qw/plans features/ => sub {
	my ($orig, $self) = (shift, shift);

	if (scalar @_) {
		return $self->$orig(@_);
	} else {
		my $ret = $self->$orig || [];
		return wantarray ? @$ret : $ret;
	}
};

=head2 after anything_that_changes_object

Automatically saves the object to the backend after any method that changed
it was executed. Also updates the 'modified' attribute with the current time
before saving. Note, however, that the C<plans()> and C<features()> methods
are not here, since they are only meant to be used for writing internally.

=cut

after qw/set_email_address add_plan drop_plan add_feature drop_feature/ => sub {
	$_[0]->modified(DateTime->now);
	$_[0]->parent->save($_[0]);
};

=head1 SEE ALSO

L<Entities>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities::Customer

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
