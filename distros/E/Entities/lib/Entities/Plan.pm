package Entities::Plan;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw/Any Str ArrayRef/;
use Scalar::Util qw/blessed/;
use namespace::autoclean;

# ABSTRACT: A collection of features (possibly scoped and limited) customers can subscribe to.

=head1 NAME

Entities::Plan - A collection of features (possibly scoped and limited) customers can subscribe to.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	used internally, see L<Entities>

=head1 DESCRIPTION

A plan is merely a collection of features. Customer get access to these
features by subscribing to a plan. In a paid webapp, for example, you
might have plans such as 'Free', 'Small', 'Medium' and 'Large', with
feature count increasing from plan to plan. Plans can also inherit from
other plans to make things a little easier.

This entity class C<does> the L<Abilities::Features> L<Moose role|Moose::Role>.

NOTE: you are not meant to create plan objects directly, but only through
the C<new_plan()> method in L<Entities>.

=head1 METHODS

=head2 new( name => 'someplan', [ description => 'Just some plan',
features => [], plans => [], created => $dt_obj, modified => $other_dt_obj,
parent => $entities_obj, id => 123 ] )

Creates a new instance of this module. Only 'name' is required.

=head2 id()

Returns the ID of the plan, if set.

=head2 has_id()

Returns a true value if the plan object has an ID attribute.

=head2 _set_id( $id )

Sets the ID of the plan object to the provided value. Only to be used
internally.

=cut

has 'id' => (
	is => 'ro',
	isa => Any,
	predicate => 'has_id',
	writer => '_set_id'
);

=head2 name()

Returns the name of the plan.

=cut

has 'name' => (
	is => 'ro',
	isa => Str,
	required => 1
);

=head2 description()

Returns the description text of this plan.

=head2 set_description( $desc )

Changes the description of the object to the provided value.

=cut

has 'description' => (
	is => 'ro',
	isa => Str,
	writer => 'set_description'
);

=head2 features( [\@features] )

In scalar context, returns an array-ref of all feature names this plan
directly has. In list context returns an array. If an array-ref of feature
names is provided, it replaces the current list.

=head2 has_features()

Returns a true value if the plan has been assigned any features.

=cut

has 'features' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_features'
);

=head2 plans( [\@plans] )

In scalar context, returns an array-ref of plan names this plan inherits
from. In list context returns an array. If an array-ref of plan names
is provided, it will replace the current list.

=head2 has_plans()

Returns a true value if the plan object inherits from any other plan.

=cut

has 'plans' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => ['has_plans']
);

=head2 created()

Returns a L<DateTime> object in the time the plan object has been created.

=cut

has 'created' => (
	is => 'ro',
	isa => sub { croak 'created must be a DateTime object' unless blessed $_[0] && blessed $_[0] eq 'DateTime' },
	default => sub { DateTime->now() }
);

=head2 modified( [$dt] )

Returns a DateTime object in the last time the object has been modified.
If a DateTime object is provided, it is set as the new modified value.

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

=head2 add_feature( $feature_name )

Adds the feature named C<$feature_name> to the plan. Croaks if the
feature does not exist, warns if the plan already has that feature.
Returns the plan object itself.

=cut

sub add_feature {
	my ($self, $feature_name) = @_;

	croak "You must provide a feature name." unless $feature_name;

	# does the plan already have that feature?
	if ($self->has_feature($feature_name)) {
		carp "Plan ".$self->name." already has feature ".$feature_name;
		return $self;
	}

	# find this feature, does it even exist?
	my $feature = $self->parent->get_feature($feature_name);
	croak "feature $feature_name does not exist." unless $feature;

	# add this feature
	my @features = $self->features;
	push(@features, $feature_name);
	$self->features(\@features);

	return $self;
}

=head2 drop_feature( $feature_name )

Removes the feature named C<$feature_name> from the plan. This only
removes the feature if it was directly provided to the plan, and not
through inheritance, so it's possible the plan will still have that feature
after removal if it inherits it from a plan that provides it.

Warns if the plan doesn't have that feature, doesn't croak if the
feature does not exist at all. Returns the plan object itself.

=cut

sub drop_feature {
	my ($self, $feature_name) = @_;

	croak "You must provide a feature name." unless $feature_name;

	# does the plan even have this feature?
	unless ($self->has_direct_feature($feature_name)) {
		carp "Plan ".$self->name." doesn't have feature $feature_name.";
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

Returns a true value if the plan was directly provided with the
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

=head2 take_from_plan( $plan_name )

Setup an inheritance from the plan named C<$plan_name>. This plan will
then inherit all features from that plan. Croaks if the provided plan
does not exist, warns if the plan object already inherits from it.
Returns the plan object itself.

=cut

sub take_from_plan {
	my ($self, $plan_name) = @_;

	croak "You must provide a plan name." unless $plan_name;

	# does this plan already inherit from the provided plan?
	if ($self->in_plan($plan_name)) {
		carp "Plan ".$self->name." already takes from ".$plan_name;
		return $self;
	}

	# find the plan, does it even exist?
	my $plan = $self->get_plan($plan_name);
	croak "plan $plan_name does not exist." unless $plan;

	# add the plan
	my @plans = $self->plans;
	push(@plans, $plan_name);
	$self->plans(\@plans);

	return $self;
}

=head2 dont_take_from_plan( $plan_name )

This badly named method removes the inheritance between the current plan
object and the plan named C<$plan_name>. Warns if the plan doesn't inherit
from the provided plan. Doesn't croak if C<$plan_name> can't be found.

Returns the plan object itself.

=cut

sub dont_take_from_plan {
	my ($self, $plan_name) = @_;

	croak "You must provide a plan name." unless $plan_name;

	# is the plan even inheriting this plan?
	unless ($self->in_plan($plan_name)) {
		carp "Plan ".$self->name." doesn't have plan $plan_name.";
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

after qw/set_description add_feature drop_feature take_from_plan dont_take_from_plan/ => sub {
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

    perldoc Entities::Plan

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
