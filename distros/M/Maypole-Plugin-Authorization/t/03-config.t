# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl t/03-config.t'
use strict;
use warnings;

use lib 'lib'; # Where MPA should live


# 03-config
#
# These tests check the various configuration options

#########################

use Test::More tests => 7;
my $DEBUG = 0;


########################################################################
#
#  SIMULATION
#
#  Before we run the tests, we need to simulate its environment.
#  That is, we need some objects that behave a bit like Maypole.
#
########################################################################

# Simulate the configuration
{
package Maypole::Config;					# singleton

my $self;
sub new { return $self || ($self = bless {}, __PACKAGE__) }
sub auth { return Maypole::Config::Auth->new }
sub mk_accessors { print STDERR "mk_accessors called\n"; }
}

{
package Maypole::Config::Auth;					# singleton

my $self;
sub new { return $self || ($self =
		bless {
#			user_class        => 'Model::User',  *NO* user class
			permission_table  => 'ask_the_teacher',
			role_assign_table => 'team_building',
			user_fk           => 'clusterf**k',
		}, __PACKAGE__)
	}
}

# Simulate a DBI statement handle
# 
# This class also simulates the database content
# $self->{x} is set to either classes or methods when the statement is
# created. execute checks whether the supplied args are sensible in the
# particular case (get_*_classes or get_*_methods). If permission should
# be granted, it leaves $self->{x} alone, but if not, it deletes it.
# fetchall_arrayref then returns an appropriate data structure depending
# on the value of $self->{x}
{
package Statement;

sub new
{
  my ($self, $x, $u) = @_;
  return bless { x => $x, u => $u }, __PACKAGE__;
}

sub execute
{
  my ($self, $userid, $class) = @_;
  my $user = $self->{u};
  if ($self->{x} eq 'classes') {
    delete $self->{x} unless $userid == $user and not defined $class
  }
  elsif ($self->{x} eq 'methods') {
    print STDERR "execute: userid=$userid, user=$user, class=$class\n"
      if $DEBUG;
    delete $self->{x} unless $userid == $user and $class eq 'Model::Class';
  }
  else {
    delete $self->{x}
  }
}

sub fetchall_arrayref
{
  my $self = shift;
  return [] unless $self->{x};
  return [['Model::Class']] if $self->{x} eq 'classes';
  return [['action']] if $self->{x} eq 'methods';
}

}


# Simulate CDBI
{
package Model;

our $saved_sql;
our %init;

sub set_sql {
  my ($class, $name, $sql) = @_;
  $saved_sql = $sql;
  $init{$name} = 1;
}

}


# Simulate a user
{
package Model::User;						# singleton

use base 'Model';

my $hash;
sub new { return $hash || ($hash = bless {id => 42}, __PACKAGE__) }
sub id { return shift->{id} }

sub select_val
{
  my ($self, $userid, $class, $method) = @_;
  return $userid == $self->{id}
    and $class eq 'Model::Class' and $method eq 'action';
}

sub sql_check_authorization    {
  die "not initialized" unless $Model::init{check_authorization};
  return $hash;
}

sub sql_get_authorized_classes {
  die "not initialized" unless $Model::init{get_authorized_classes};
  return Statement->new('classes', $hash->{id});
}

sub sql_get_authorized_methods {
  die "not initialized" unless $Model::init{get_authorized_methods};
 return Statement->new('methods', $hash->{id});
}
}


# Simulate a request object
{
package Request;						# singleton

use base 'Model::User';
use base 'Maypole::Plugin::Authorization';

my $hash;
sub new
{
  return ($hash = bless {
 	model => 'Model::Class',
	user  => Model::User->new,
	}, __PACKAGE__);
}

sub action { return 'action' }
sub config { return new Maypole::Config }
sub model_class { shift->{model} }
sub user { return shift->{user} }

}

# Simulate ... what? ... an unfortunate side-effect of Maypole that's
# exploited by the wonderful Maypole::Plugin::Authentication::Abstract 
# and Maypole::Plugin::Authentication::UserSessionCookie and therefore
# also demanded of us by developers :(  Sigh ...
{
package Request::User;
use base 'Model::User';
}


########################################################################
#
#  TESTS
#
#  We can test the configuration options of the module
#  now we have a suitable environment.
#
########################################################################


# First load the module

require_ok('Maypole::Plugin::Authorization');

# We have preset our configuration with:
#  1/ no user_class supplied
#  2/ permission table supplied
#  3/ role assignment table supplied
#  4/ user id foreign key supplied
# So now call each of authorized(), get_authorized_classes() and
# get_authorized_methods() and check whether they use the default settings
# or the actual values supplied.


# Test authorize method
my $r = new Request;
ok(Maypole::Plugin::Authorization->authorize($r),
  'authorize handles basic case');
$Model::saved_sql =~ s/\s+/ /g;
is($Model::saved_sql,
  "SELECT p.id FROM ask_the_teacher AS p, team_building AS r WHERE r.clusterf**k = ? AND p.model_class = ? AND (p.method = ? OR p.method = '*') AND p.auth_role_id = r.auth_role_id LIMIT 1",
  'manual configuration was used');

# Test get_authorized_classes method
my @c = Request->new->get_authorized_classes;
ok((@c == 1 and $c[0] eq 'Model::Class'),
  'get_authorized_classes handles basic case');
$Model::saved_sql =~ s/\s+/ /g;
is($Model::saved_sql,
  "SELECT DISTINCT p.model_class FROM ask_the_teacher AS p, team_building AS r WHERE r.clusterf**k = ? AND p.auth_role_id = r.auth_role_id",
  'manual configuration was used');

# Test get_authorized_methods method
my @m = Request->new->get_authorized_methods;
ok((@m == 1 and $m[0] eq 'action'),
  'get_authorized_methods handles basic case');
$Model::saved_sql =~ s/\s+/ /g;
is($Model::saved_sql,
  "SELECT p.method FROM ask_the_teacher AS p, team_building AS r WHERE r.clusterf**k = ? AND p.model_class = ? AND p.auth_role_id = r.auth_role_id",
  'manual configuration was used');
