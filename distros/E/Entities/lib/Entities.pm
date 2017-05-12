package Entities;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Entities::User;
use Entities::Role;
use Entities::Action;
use Entities::Customer;
use Entities::Plan;
use Entities::Feature;
use Moo;
use namespace::autoclean;

# ABSTRACT: User management and authorization for web applications and subscription-based services.

=head1 NAME

Entities - User management and authorization for web applications and subscription-based services.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	use Entities;

	# create a new Entities object, with a MongoDB backend
	my $ent = Entities->new(backend => 'MongoDB');

	# create a new role
	my $role = $ent->new_role(name => 'members');
	$role->grant_action('make_mess')
	     ->inherit_from('limited_members');

	# create a new user
	my $user = $ent->new_user(username => 'someone');
	$user->add_email('someone@someplace.com')
	     ->add_to_role('members');
	     ->grant_action('stuff');

	# check user can do stuff
	if ($user->can_perform('stuff')) {
		&do_stuff();
	} else {
		croak "Listen, you just can't do that. C'mon.";
	}

=head1 DESCRIPTION

Entities is a complete system of user management and authorization for
web applications and subscription-based web services, implementing what
I call 'ability-based authorization', as defined by L<Abilities> and
L<Abilities::Features>.

This is a reference implementation, meant to be both extensive enough to
be used by web applications, and to serve as an example of how to use and
create ability-based authorization systems.

=head2 ENTITIES?

Ability-based authorization deals with six types of "entities":

=over

=item * Customers (represented by L<Entities::Customer>)

A customer is an abstract entity that merely serves to unify the people
who are actually using your app (see "users"). It can either be a person,
a company, an organization or whatever. Basically, the customer is the
"body" that signed up for your service and possibly is paying for it. A
customer can have 1 or more users.

=item * Users (represented by L<Entities::User>)

A user is a person that belongs to a certain customer and has received
access to your app. They are the actual entities that are interacting with
your application, not their parent customer entities. Users have
the ability to perform actions (see later), probably only within their
parent entity's scope and maybe to a certain limit
(see L</"SCOPING AND LIMITING">).

=item * Plans (represented by L<Entities::Plan>)

A plan is a group of features (see below), with certain limits and
scoping restrictions, that customers subscribe to. You are probably familiar
with this concept from web services you use (like GitHub, Google Apps, etc.).

A customer can subscribe to one or more plans (plans do not have to be
related in any way), so that users of that customer can use the features
provided with those plans.

=item * Features (represented by L<Entities::Feature>)

A feature is also an abstract entity used to define "something" that customers
can use on your web service. Perhaps "SSL Encryption" is a feature provided
with some (but not all) of your plans. Or maybe "Opening Blogs" is a feature
of all your plans, with different limits set on this feature for every plan.

In other words, features are as they're named: the features of your app.
It's your decision who gets to use them.

=item * Actions (represented by L<Entities::Action>)

Actions are the core of 'ability-based authorization'. They define the
actual activities that users can perform inside your app. For example,
'creating a new blog post' is an action that a user can perform. Another
example would be 'approving comments'. Maybe even 'creating new users'.

Actions, therefore, are units of "work" you define in your code. Users will
be able to perform such a unit of work only if they are granted with the 'ability'
to perform the action the defines it, and only if this action is within
the defined 'scope' and 'limit' of the parent customer. A certain ability
can be bestowed upon a user either explicitly, or via roles (see below).

=item * Roles (represented by L<Entities::Role>)

Roles might be familiar to you from 'role-based authorization'. Figuratively
speaking, they are 'masks' that users can wear. A role is nothing but a
group of actions. When a user is assigned a certain role, they consume
all the actions defined in that role, and therefore the user is able to
perform them. You will most likely find yourself creating roles such as
'admins', 'members', 'guests', etc.

Roles are self-inheriting, i.e. a role can inherit the actions of another
role.

=back

=head2 SCOPING AND LIMITING

Scoping is the process of asserting that customers and their users are
only allowed to perform actions in their own scope. For example, let's say
your web service is a hosted blogging platform. Customers of your service
are allowed to create blogs (i.e. they have the 'blogs' feature), and their
users are allowed to post to these blogs, edit the posts and remove them
(i.e. they have the 'create_post', 'edit_post' and 'delete_post' actions).
Scoping means ensuring users can only create, edit and delete posts in their
parent customer's blogs only.

Limiting is the process of, well, limiting the amount of times a customer
can use a certain feature. Returning to our hosted blog example, the customer's
plan might limit the number of blogs the customer can own to a certain number,
let's say six. When a user of that customer attempts to create a new blog,
a check must be made that the customer has yet to reach the maximum amount
of blogs. Users, in themselves, are common features in many plan-based
web services. A customer might be able to create, for example, up to
five users in a certain plan. Limiting is, therefore, an important part
of plan-based web services.

Obviously, the L<Entities> system cannot do scoping and limiting for you,
so you have to do this yourself. However, I do have plans to provide some
simple features in upcoming releases to make these processes easier.

=head1 ATTRIBUTES

=head2 backend

Holds the storage backend object. This will be an object that C<does> the
role L<Entities::Backend>.

=cut

has 'backend' => (
	is => 'ro',
	does => 'Entities::Backend',
	required => 1
);

=head1 CONSTRUCTOR

=head2 new( backend => $backend )

Creates a new instance of the Entities module. Requires a backend object
to be used for storage (see L<Entities::Backend> for more information
and a list of currently available backends).

=head1 OBJECT METHODS

=head2 new_role( name => 'somerole', [ description => 'Just some role',
is_super => 0, roles => [], actions => [], created => $dt_obj,
modified => $other_dt_obj, parent => $entities_obj, id => 123 ] )

Creates a new L<Entities::Role> object, stores it in the backend and
returns it.

=head2 new_user( username => 'someguy', passphrase => 's3cr3t', [ realname => 'Some Guy',
is_super => 0, roles => [], actions => [], customer => $customer_obj, id => 123,
emails => [], created => $dt_obj, modified => $other_dt_obj, parent => $entities_obj ] )

Creates a new L<Entities::User> object, stores it in the backend and
returns it.

=head2 new_action( name => 'someaction', [ description => 'Just some action',
parent => $entities_obj, id => 123 ] )

Creates a new L<Entities::Action> object, stores it in the backend and
returns it.

=head2 new_plan( name => 'someplan', [ description => 'Just some plan',
features => [], plans => [], created => $dt_obj, modified => $other_dt_obj,
parent => $entities_obj, id => 123 ] )

Creates a new L<Entities::Plan> object, stores it in the backend and
returns it.

=head2 new_feature( name => 'somefeature', [ description => 'Just some feature',
parent => $entities_obj, id => 123 ] )

Creates a new L<Entities::Feature> object, stores it in the backend
and returns it.

=head2 new_customer( name => 'somecustomer', email_address => 'customer@customer.com',
[ features => [], plans => [], created => $dt_obj, modified => $other_dt_obj,
parent => $entities_obj, id => 123 ] )

Creates a new L<Entities::Customer> object, stores it in the backend
and returns it.

=cut

no strict 'refs';
foreach my $entity (qw/role user action plan feature customer/) {
	*{"new_$entity"} = sub {
		my $self = shift;

		# create a new object
		my $class = 'Entities::'.ucfirst($entity);
		push(@_, parent => $self->backend);
		my $obj = $class->new(@_);

		# save object in storage backend
		$self->backend->save($obj);

		return $obj;
	};
}
use strict 'refs';

=head1 SEE ALSO

L<Abilities>, L<Abilities::Features>, L<Catalyst::Authentication::Abilities>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities

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
