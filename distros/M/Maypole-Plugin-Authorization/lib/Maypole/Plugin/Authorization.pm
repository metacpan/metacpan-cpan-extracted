package Maypole::Plugin::Authorization;
use strict;
use warnings;

# This module provides role-based authorization for Maypole

our $VERSION = '0.10';

# 2005-01-27 djh v0.03	Modified get_authorized_* to make them work and
#			accept arguments, and improved docs
# 2005-01-28 djh v0.04	Added arg checking to get_authorized_* and an
# 			example for get_authorized_methods. Thanks to
#			Josef Chladek.
# 2005-02-08 djh v0.05	Improved error checking in authorize.
# 2005-08-20 djh v0.06	Improved docs suggested by Kieren Diment.
# 2005-08-20 djh v0.07	Added config options from Peter Speltz.
# 2005-08-22 djh v0.08	Added user_class default from Kieren Diment
# 2005-08-22 djh v0.09	Default {} if no config->auth
# 2005-08-24 djh v0.10	Allow entity other than model_class as requested
#			by Kieren Diment & Peter Speltz


#=======================================================================
#
# Initialization

Maypole::Config->mk_accessors('auth') unless Maypole::Config->can('auth');


# Code references to database queries could be cached at load time,
# except that Maypole::Application doesn't call our import function!

# Authorization checking query for use by authorize()
my $_cdbi_class;
my $_check_authorization;

sub _init_authorization_query {
    my $r = shift;

    # Build a SQL query that checks whether a given user_id is
    # authorized to invoke a particular method in a model_class
    # and add it to a class that can run SQL queries for us
    my $conf     = $r->config->auth || {};
    my $p_table  = $conf->{permission_table}  || 'permissions';
    my $ra_table = $conf->{role_assign_table} || 'role_assignments';
    my $user_fk  = $conf->{user_fk}	      || 'user_id';
    $_cdbi_class = $conf->{user_class}        || (ref $r).'::User';

    $_cdbi_class->set_sql(check_authorization => 
	"SELECT p.id FROM $p_table AS p, $ra_table AS r
	  WHERE r.$user_fk  = ? 
	  AND   p.model_class = ?
	  AND  (p.method = ? OR p.method = '*')
	  AND   p.auth_role_id = r.auth_role_id
	  LIMIT 1");

    $_check_authorization = $_cdbi_class->can('sql_check_authorization');
}


# Query to find lists of authorized methods for get_authorized_classes()
my $_get_authorized_classes;

sub _init_get_authorized_classes {
    my $r = shift;

    my $conf     = $r->config->auth || {};
    my $p_table  = $conf->{permission_table}  || 'permissions';
    my $ra_table = $conf->{role_assign_table} || 'role_assignments';
    my $user_fk  = $conf->{user_fk}	      || 'user_id';
    $_cdbi_class = $conf->{user_class}        || (ref $r).'::User';

    $_cdbi_class->set_sql(get_authorized_classes => 
	"SELECT DISTINCT p.model_class FROM $p_table AS p, $ra_table AS r
	  WHERE r.$user_fk = ?
	  AND   p.auth_role_id = r.auth_role_id");

    $_get_authorized_classes =
	$_cdbi_class->can('sql_get_authorized_classes');
}


# Query to find lists of authorized methods for get_authorized_methods()
my $_get_authorized_methods;

sub _init_get_authorized_methods {
    my $r = shift;

    my $conf     = $r->config->auth || {};
    my $p_table  = $conf->{permission_table}  || 'permissions';
    my $ra_table = $conf->{role_assign_table} || 'role_assignments';
    my $user_fk  = $conf->{user_fk}	      || 'user_id';
    $_cdbi_class = $conf->{user_class}        || (ref $r).'::User';

    $_cdbi_class->set_sql(get_authorized_methods =>
	"SELECT p.method FROM $p_table AS p, $ra_table AS r
	  WHERE r.$user_fk = ?
	  AND   p.model_class = ?
	  AND   p.auth_role_id = r.auth_role_id");

    $_get_authorized_methods =
	 $_cdbi_class->can('sql_get_authorized_methods');
}


#=======================================================================

# Main permission-checking method

sub authorize {
    my ($self, $r, $entity) = @_;

    # Validate and extract values for permission check
    $entity	 ||= $r->model_class;
    return undef unless $r->user and $entity;
    my $userid     = $r->user->id;
    my $method     = $r->action;

    # Make sure the SQL query has been prepared, then check the permissions
    _init_authorization_query($r) unless $_check_authorization;
    return $_cdbi_class->sql_check_authorization->
				select_val($userid, $entity, $method);
}


# Auxiliary method for finding list of authorized classes

sub get_authorized_classes {
    my ($r, $userid) = @_;

    # Validate and extract parameters
    return unless $r->user or $userid;
    $userid ||= $r->user->id;

    # Make sure the SQL query has been prepared, then run it
    _init_get_authorized_classes($r) unless $_get_authorized_classes;
    my $sth = $_cdbi_class->sql_get_authorized_classes;
    $sth->execute($userid);
    return map { $_->[0] } @{$sth->fetchall_arrayref};
}


# Auxiliary method for finding list of authorized methods

sub get_authorized_methods {
    my ($r, $userid, $class) = @_;

    # Validate and extract parameters
    return unless $r->user or $userid;
    $userid ||= $r->user->id;
    $class  ||= $r->model_class;
    return unless $class;

    # Make sure the SQL query has been prepared, then run it
    _init_get_authorized_methods($r) unless $_get_authorized_methods;
    my $sth = $_cdbi_class->sql_get_authorized_methods;
    $sth->execute($userid, $class);
    return map { $_->[0] } @{$sth->fetchall_arrayref};
}

1;

__END__

=head1 NAME

Maypole::Plugin::Authorization - Provide role-based authorization for Maypole applications

=head1 SYNOPSIS

  # In your main application driver class ...

  package BeerDB;
  use Maypole::Application qw(
	Authentication::UserSessionCookie
	Authorization);
  use Maypole::Constants;

  # Configuration will depend on the database design, which loader is
  # used etc, so this is just one possibility ...
  BeerDB->config->auth({
    user_class => 'BeerDB::Users',
    # other keys may be needed as well for the authentication module
  });

  sub authenticate {
    my ($self, $r) = @_;
    ...
    if ($self->authorize($r)) {
        return OK;
    } else {
        # take application-specific authorization failure action
	...
    }
    ...
  }

  # make web page show just tables for this user
  sub additional_data {
    my $r = shift;
    $r->config->display_tables(
	[ map { $_->table } $r->get_authorized_classes ]
    );
  }

  # meanwhile in a template somewhere ...

  [% ok_methods = request.get_authorized_methods %]
  Can be used to decide whether to display an edit button, for example


=head1 DESCRIPTION

This module provides simple role-based authorization for L<Maypole>.
It uses the database to store permissions, which fits well with Maypole.

It determines whether I<users> are authorized to invoke specific
I<methods> in I<classes>. Normally these will be I<actions> in model
classes. Permission to invoke methods is not granted directly; it is
assigned to I<roles>, and each user may be assigned one or more roles.

The methods made available in your request object are described next,
followed by an example database schema. Then we explain how you can
customize the schema using configuration. Finally there are some hints
on how to administer the database tables and a list of the various use
cases associated with authorization.

As well as this description there are a few other files shipped in the
distribution that you may want to look at:

=over

=item t/beerdb.db

A sqlite database containing tables and data for the example beer
database, along with authorization tables and data.

=item t/beerdb.sql

A file containing SQL to create and load the sqlite database

=item ex/beer_d_b.sql

A file containing SQL to create and load a MySQL InnoDB version of the
database.

=item ex/BeerDB.pm

An example of a Maypole driver class that uses authorization. It may get
you started towards your own application.

Note that there is a different F<BeerDB.pm> in the F<t> directory that
is just designed to make the tests run, not to help you!

=back


=head1 METHODS

=head2 authorize

The C<authorize> method is called in the driver's authenticate method,
though it is explicitly passed the request object and so can be called
from elsewhere if desired.

    package BeerDB;

    sub authenticate {
        my ($self, $r) = @_;
        ...
        if ($self->authorize($r)) {
            return OK;
        } else {
            # take application-specific auth failure action
        }
        ...
    }

It returns a true value if authorization is granted and C<undef> if not.

C<authenticate> needs to deal with requests with no model class before
calling this method because the response is application-specific.
If such a request gets this far, we just turn it down.
Similarly, C<authenticate> needs to handle requests with no user without
calling C<authorize>.

Normally, C<authorize()> uses information in the request (C<$r>) to decide
whether to grant authorization. In particular, it checks whether the
C<permissions> table has a record matching the request's I<model class>
and I<action> with the user. It is possible to vary this scheme and store
different information in the permissions table instead of the model class,
perhaps the class's C<moniker> or the name of its associated database table.
To do this, make sure that you have the right values in the permissions table,
and pass the value to be tested explicitly to authorize(). For example:

  $authorized = $self->authorize($r, $r->model_class->moniker);

or

  $authorized = $self->authorize($r, $r->table);


=head2 get_authorized_classes

  $r->get_authorized_classes;		# current user
  $r->get_authorized_classes($user_id);	# specific user

C<get_authorized_classes> returns the list of classes for which the
current user has some permissions. This can be used to build the list of
tabs in the navbar, for instance. If called with a user id as argument,
it returns the list of classes for which that user has some permissions.


=head2 get_authorized_methods

  $r->get_authorized_methods;
  # methods current user can execute in current model class

  $r->get_authorized_methods($user_id);
  # methods specific user can execute in current model class

  $r->get_authorized_methods($user_id, $class_name);
  # methods specific user can execute in nominated model class
  # (or use moniker or table name etc in place of the model class)

  $r->get_authorized_methods(undef, $class_name);
  # methods current user can execute in nominated model class
  # (or use moniker or table name etc in place of the model class)

C<get_authorized_methods> finds the list of methods that the current
user is entitled to invoke on the current model class. This can be used
to build a menu of permitted actions, for example. If called with a user
id as an argument it returns the list of methods that the given user can
execute in the current model class. Similarly, if called with a class
name, it returns the list of methods that the current user can execute
in that class, while if called with both as arguments, it returns the
list of methods the given user is allowed to call in the stated class.

Like C<authorize()>, it is possible to use some other value instead of
the model class, provided that the permissions has matching values.

Here is an example of a possible way to use this method in templates to
decide whether to display buttons for various actions that a user may or
may not be authorized to use:

  [% MACRO if_auth_button(obj, action, permitted_method) BLOCK ;
         IF permitted_method == '*' OR permitted_method == action ;
             button(obj, action) ;
         END ;
     END ;
  %]

  # ... and in other templates ...

  [% ok_methods = request.get_authorized_methods ;
     FOR meth = ok_methods ;
          if_auth_button(item, 'edit', meth) ;
          if_auth_button(item, 'delete', meth) ;
     END ;
  %]


=head1 DATABASE STRUCTURE

The module depends on four database tables to store the necessary data.

=over

=item users

The C<users> table records details of each individual who has an account
on the system.
It is not used by this module; only the id values are used as foreign
keys in the role_assignments table.
This table is used by L<Maypole::Plugin:Authentication::UserSessionCookie>
to do user authentication and session management. 
Refer to that module to understand the columns in this table.
Additional columns can be added to suit whatever other needs you have.

=item auth_roles

Users are not given permissions directly because that causes an
explosion in the table size and an administrative headache.
Instead roles are given permissions and users acquire those permissions
by being assigned to roles. The C<auth_roles> table just records the
name of the role. You could add things like a description if you wish.
The table is not called C<roles> in case your application wants to use
that name for its own purposes.

=item role_assignments

C<role_assignments> is a classic many-many link table. Records contain
the id of a user and of a role which the user has been assigned.

=item permissions

The C<permissions> table authorizes a specific role to execute a
particular method in a particular class. The classes are expected to be
the model subclasses and the methods will be the actions, but the scheme
will also work in other situations. To reduce administrative burden and
table size, it is allowed to use a '*' wildcard instead of a method name;
this grants permission to all methods in the class. It would be possible
to add a similar wildcard for classes but there's probably no action
that you want to allow on B<all> classes!

=back

One possible set of table definitions (DDL) to implement this scheme are
shown below. The DDL uses various MySQL features and you may need to adapt
it for other databases. The DDL also uses the InnoDB table type, because
this supports foreign key checks within the database and it allows us to
show how these constraints should be set up. You can use other table types
and rely on L<Class::DBI> to maintain integrity. If you do this, remove
'TYPE=InnoDB' from the end of each table definition.

Note that in some Linux distributions InnoDB support is in a different
package to the base MySQL release. So if you have trouble, use your
distribution's package manager to check that InnoDB support is installed.

  CREATE TABLE users (
	id		INT NOT NULL AUTO_INCREMENT,
	name		VARCHAR(100) NOT NULL,
	UID		VARCHAR(20) NOT NULL,
	password	VARCHAR(20) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (UID)
  ) TYPE=InnoDB;

  CREATE TABLE auth_roles (
	id		INT NOT NULL AUTO_INCREMENT,
	name		VARCHAR(40) NOT NULL,
	PRIMARY KEY (id)
  ) TYPE=InnoDB;

  CREATE TABLE role_assignments (
	id		INT NOT NULL AUTO_INCREMENT,
	user_id		INT NOT NULL,
	auth_role_id	INT NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (user_id, auth_role_id),
	INDEX (auth_role_id),
	FOREIGN KEY (user_id) REFERENCES users (id),
	FOREIGN KEY (auth_role_id) REFERENCES auth_roles (id)
  ) TYPE=InnoDB;

  CREATE TABLE permissions (
	id		INT NOT NULL AUTO_INCREMENT,
	auth_role_id	INT NOT NULL,
	model_class	VARCHAR(100) NOT NULL,
	method		VARCHAR(100) NOT NULL,
	PRIMARY KEY (id),
	UNIQUE (auth_role_id, model_class, method),
	INDEX (model_class(20)),
	INDEX (method(20)),
	FOREIGN KEY (auth_role_id) REFERENCES auth_roles (id)
  ) TYPE=InnoDB;


=head1 CONFIGURATION

Maypole::Plugin::Authorization runs without any configuration,
sharing the C<auth> component of your Maypole configuration with
whichever authentication plugin you are using.
You can also customize some aspects of it with explicit configuration:

=over

=item user_class

The name of the model subclass that represents the I<users> table.
It defaults to C<BeerDB::User>, where C<BeerDB> is the name of your
application driver class.
This subclass is used to execute the authorization SQL queries.

=item permission_table

The name of the permissions table. It defaults to I<permissions>.

=item role_assign_table

The name of the table that assigns users to roles.
It defaults to I<role_assignments>.

=item user_fk

The name of the foreign key column in the role assignment table that
identifies the user. It defaults to I<user_id>.

=back


=head1 ADMINISTRATION

The permissions database can be maintained by any person who is assigned
to the I<admin> role. Most administration is performed using normal
Maypole actions and templates such as list, search, addnew, view, edit
and delete.

User administration is separated out to a I<user-admin> role. I don't
yet know whether this will prove beneficial but these people are the
only ones who can access passwords and personal details.

There needs to be special code to allow users to edit their own
passwords, since that is a data-dependent permission as opposed to the
metadata-dependent nature of the authorizations scheme. Such code is
part of the application's authentication scheme.

There is a I<default> role that should be assigned to every user.
Perhaps it should be hardwired in the SQL so that users don't have to be
actually added to the role?


=head1 USE CASES

=over

=item Create new user

User administration mechanisms belong in the domain of the
authentication system, though this authorization module imposes a few
additional requirements.
This action should be permitted to the user-admin role. Newly created
users should automatically be assigned to the 'default' role.

=item User changes password

Should be permitted to the individual user only and perhaps to the
user-admin role.

=item Grant/change/revoke user privileges

=item Create/delete role

=item Alter actions permitted to role

People assigned to the admin role can edit the role_assignments,
permissions and auth_roles tables in the normal Maypole way.

=item Update list of classes

=item Update list of methods

Presently, administrators need to type in the names of the model
subclasses and the actions. The methods C<get_authorized_classes> and
C<get_authorized_methods> could be used to build a specialized template
to populate the relevant form elements.

=item Determine list of classes

This is the C<get_authorized_classes> method.
Given a user ID, find the list of classes for which s/he has some
permissions. This can be used to build the list of tabs in the navbar.

=item Determine list of methods

This is the C<get_authorized_methods> method.
Given a user ID and class name, find the list of methods that the user
is entitled to invoke. This can be used to build a menu of permitted
actions.

=back


=head1 ALTERNATIVES AND FUTURES

There are several alternative possibilities for authorizable entities
and permission checking in addition to the example implementation
provided. You can consider them if you have special requirements:

1/ Authorize all actions (i.e. methods with the Exported attribute).
Permission could be enforced in the model's process method just before
calling the action.
PRO: simple to implement, uniform and easy-to-understand
CON: not as flexible as alternatives

2/ Explicit call to authorize() at the beginning of every method that
needs to be authorized.
PRO: Flexible. Very simple to implement initially. Obvious in code
where auth occurs. Auth can be done at points other than method entry
if needed.
CON: Error-prone and awkward to maintain. Increases code complexity.

3/ Provide some other attribute that can be attached to methods to
require them to be authorized, or perhaps in combination with Exported.
For example, the Exported attribute could automatically invoke
authorization as would a new 'Auth' attribute, while a new 'NoAuth'
attribute would declare that the action could proceed without
authorization.

=head1 AUTHOR

Dave Howorth, djh#cpan.org

Please ask any questions on the L<Maypole> mailing list
and monitor that list for any announcements.

=head1 THANKS TO

Everybody on the Maypole list, for support, help and code.

=head1 LICENCE

Copyright (c) 2004-2005 Dave Howorth.
You may distribute this code under the same terms as Perl itself.

=cut

