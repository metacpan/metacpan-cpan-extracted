#!/usr/bin/perl
use strict;
use warnings;

# This is an example Maypole application class that uses
# Maypole::Plugin::Authorization, to help you to understand how to use
# the authorization plugin. It hasn't been run recently, so I don't
# guarantee it works! Learning how to fix it if necessary is a valuable
# skill to have :)

# Start off with pretty standard Maypole driver stuff ...

package BeerDB;
use Maypole::Application qw(
	-Debug
	Authentication::UserSessionCookie
	Authorization
	);

BeerDB->setup("dbi:mysql:beer_d_b");
BeerDB->config->uri_base("http://localhost/cgi-bin/beer.cgi");
BeerDB->config->template_root("/var/www/beerdb");
BeerDB->config->rows_per_page(10);
BeerDB->config->display_tables([qw[beer brewery pub style
		users permissions auth_roles role_assignments
    ]]);
BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
BeerDB::Pub->untaint_columns(     printable => [qw/name notes url/] );
BeerDB::Style->untaint_columns(   printable => [qw/name notes/] );
BeerDB::Beer->untaint_columns(
        printable => [qw/abv name price notes/],
        integer   => [qw/style brewery score/],
        date      => [ qw/date/],
    );

# Authorization stuff

# Show UserSessionCookie where to find user and password
BeerDB->config->auth({
        user_class     => 'BeerDB::Users',
        user_field     => 'UID',
        password_field => 'password',	# this is actually the default
    });

# Make relationships between authorization tables so Maypole will
# display them correctly (you can let Class::DBI::Loader or some other
# module do this if you wish
BeerDB::Permissions->has_a(    auth_role_id => 'BeerDB::AuthRoles');
BeerDB::RoleAssignments->has_a(user_id      => 'BeerDB::Users');
BeerDB::RoleAssignments->has_a(auth_role_id => 'BeerDB::AuthRoles');
BeerDB::AuthRoles->has_many(users =>
			[ 'BeerDB::RoleAssignments' => 'user_id' ]);
BeerDB::Users->has_many(auth_roles =>
			[ 'BeerDB::RoleAssignments' => 'auth_role_id' ]);

# Declare the column types for the authorization tables so users will be
# able to edit them using Maypole
BeerDB::Users->untaint_columns(      printable => [qw/name UID password/]);
BeerDB::AuthRoles->untaint_columns(  printable => [qw/name/]);
BeerDB::Permissions->untaint_columns(printable =>
			[qw/auth_role_id model_class method/]);
BeerDB::RoleAssignments->untaint_columns(printable =>
			[qw/user_id auth_role_id/]);

# Here is an example of an 'authenticate' method that invokes the
# Authorization module. Customize this to suit your needs.
use Maypole::Constants;
sub authenticate {
    my ($self, $r) = @_;
    $r->get_user;
    if ($r->user) {
        if ($r->template  &&  $r->template =~ /logout$/) {
	    $r->logout; # user clicked on a logout link, so log him out
	    $r->template('frontpage');
	    return OK;
	}
        return OK unless $r->model_class; # let all users see frontpage etc
        if ($self->authorize($r)) {
            return OK;
        } else {
            # Maypole's strange way of saying DECLINED ...
            $r->template('error');
            $r->error("Sorry, you don't have permission to look at that");
            return OK;
        }
    } else { # no current user
        return OK if $r->table eq "users" and $r->action eq "subscribe";
        $r->template('login');	# Force them to the login page.
        return OK;
    }
}

# end authorization stuff


use Class::DBI::Loader::Relationship;
BeerDB->config->{loader}->relationship($_) for (
        "a brewery produces beers",
        "a style defines beers",
        "a pub has beers on handpumps");

1;
