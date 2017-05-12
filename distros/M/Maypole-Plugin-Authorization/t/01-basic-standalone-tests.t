# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as
# 'perl t/01-basic-standalone-tests.t'
use strict;
use warnings;

use lib 'lib'; # Where MPA should live


# 01-basic-tests
#
# This test runs without any external dependencies to make sure the
# Authorization modules itself appears to be intact

#########################

use Test::More tests => 16;
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
			user_class => 'Model::User'
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

# Simulate a user (and CDBI :)
{
package Model::User;						# singleton

my $hash;
sub new { return $hash || ($hash = bless {id => 42}, __PACKAGE__) }
sub id { return shift->{id} }
sub set_sql { }
sub select_val
{
  my ($self, $userid, $class, $method) = @_;
  return $userid == $self->{id}
    and $class eq 'Model::Class' and $method eq 'action';
}

sub sql_check_authorization    { return $hash }
sub sql_get_authorized_classes { return Statement->new('classes', $hash->{id})}
sub sql_get_authorized_methods { return Statement->new('methods', $hash->{id})}
}

# Simulate a request object
{
package Request;						# singleton

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


########################################################################
#
#  TESTS
#
#  We can test the basic behaviour of the module
#  now we have a suitable environment.
#
########################################################################

# First test we can load the module

require_ok('Maypole::Plugin::Authorization');


# Test we can call each method successfully

# Test authorize method
my $r = new Request;
ok(Maypole::Plugin::Authorization->authorize($r),
  'authorize handles basic case');

# Test get_authorized_classes method
my @c = Request->new->get_authorized_classes;
ok((@c == 1 and $c[0] eq 'Model::Class'),
  'get_authorized_classes handles basic case');

# Test get_authorized_methods method
my @m = Request->new->get_authorized_methods;
ok((@m == 1 and $m[0] eq 'action'),
  'get_authorized_methods handles basic case');


# Test various combinations of parameters

# Test get_authorized_classes method with explicit userid
$r = new Request;
$r->user->{id} = 27;
@c = $r->get_authorized_classes(27);
ok((@c == 1 and $c[0] eq 'Model::Class'),
  'get_authorized_classes handles explicit userid');

@c = $r->get_authorized_classes(42);
ok(@c == 0,
  'get_authorized_classes handles unauthorized user');

# Test get_authorized_methods method with explicit userid
@m = $r->get_authorized_methods(27);
ok((@m == 1 and $m[0] eq 'action'),
  'get_authorized_methods handles explicit userid');

@m = $r->get_authorized_methods(42);
ok(@m == 0,
  'get_authorized_methods handles unauthorized user');

# Test get_authorized_methods method with explicit class
@m = $r->get_authorized_methods(undef, 'Model::Class');
ok((@m == 1 and $m[0] eq 'action'),
  'get_authorized_methods handles explicit class');

@m = $r->get_authorized_methods(undef, 'Model::Car');
ok(@m == 0,
  'get_authorized_methods handles unauthorized class');

# Test get_authorized_methods method with explicit userid and class
@m = $r->get_authorized_methods(27, 'Model::Class');
ok((@m == 1 and $m[0] eq 'action'),
  'get_authorized_methods handles explicit userid and class');

@m = $r->get_authorized_methods(27, 'Model::Car');
ok(@m == 0,
  'get_authorized_methods handles unauthorized class no.2');

@m = $r->get_authorized_methods(16, 'Model::Class');
ok(@m == 0,
  'get_authorized_methods handles unauthorized user no.2');


# Test missing implicit parameters

delete $r->{user};
@c = $r->get_authorized_classes;
ok(@c == 0,
  'get_authorized_classes handles no user');

@m = $r->get_authorized_methods;
ok(@m == 0,
  'get_authorized_methods handles no user');

$r = new Request;
delete $r->{model};
@m = $r->get_authorized_methods;
ok(@m == 0,
  'get_authorized_methods handles no model class');

