package Entities::Backend;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Moo::Role;
use namespace::autoclean;

# ABSTRACT: A role providing storage for the Entities user-management/authorization system.

=head1 NAME

Entities::Backend - A role providing storage for the Entities user-management/authorization system.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	use Entities;
	use Entities::Backend::SomeBackend;

	# see synopsis at L<Entities>

=head1 DESCRIPTION

This class defines a L<Moose role|Moose::Role> that is to be consumed by
backend classes that provide storage for the L<Entities> user management
and authorization systems. It defines a list of required methods that every
class that consumes this role must implement.

=head1 REQUIRES

The following method are required by any class consuming this role:

=head2 get_user_from_id( $id )

Receives an ID for a L<user entity|Entities::User> and attempts to find it
in the backend. If found, returns an L<Entities::User> object representing
that user. Returns a false value if the user was not found.

=cut

requires 'get_user_from_id';

=head2 get_user_from_name( $username )

Receives a username for a L<user entity|Entities::User> and attempts to find it
in the backend. If found, returns an L<Entities::User> object representing
that user. Returns a false value if the user was not found.

=cut

requires 'get_user_from_name';

=head2 get_role( $role_name )

Receives the name of a L<role entity|Entities::Role> and attempts to find it
in the backend. If found, returns an L<Entities::Role> object representing
that role. Returns a false value if the role was not found.

=cut

requires 'get_role';

=head2 get_action( $action_name )

Receives the name of an L<action entity|Entities::Action> and attempts to find it
in the backend. If found, returns an L<Entities::Action> object representing
that action. Returns a false value if the action was not found.

=cut

requires 'get_action';

=head2 get_plan( $plan_name )

Receives the name of a L<plan entity|Entities::Plan> and attempts to find it
in the backend. If found, returns an L<Entities::Plan> object representing
that plan. Returns a false value if the plan was not found.

=cut

requires 'get_plan';

=head2 get_feature( $feature_name )

Receives the name of a L<feature entity|Entities::Feature> and attempts to find it
in the backend. If found, returns an L<Entities::Feature> object representing
that feature. Returns a false value if the feature was not found.

=cut

requires 'get_feature';

=head2 get_customer( $customer_name )

Receives the name of a L<customer entity|Entities::Customer> and attempts to find it
in the backend. If found, returns an L<Entities::Customer> object representing
that customer. Returns a false value if the customer was not found.

=cut

requires 'get_customer';

=head2 save( $obj )

Receives a new or existing entity object (either L<User|Entities::User>, L<Role|Entities::Role>,
L<Action|Entities::Action>, L<Plan|Entities::Plan>, L<Customer|Entities::Customer>
or L<Feature|Entities::Feature>) and saves it to the backend. Should return
a true value if the save was successful or croak otherwise. To make it clear,
this method should insert new objects and update existing ones.

=cut

requires 'save';

=head1 SEE ALSO

L<Entities>, L<Entities::Backend::Memory>, L<Entities::Backend::MongoDB>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities::Backend

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
