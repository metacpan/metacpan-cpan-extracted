#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;
$| = 1;

BEGIN
{
	plan skip_all => 'TODO: Adopt for Forst';
}

# =begin testing SETUP
{

  package MyApp::Mooseish;

  use Moose ();
  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      with_meta => ['has_table'],
      also      => 'Moose',
  );

  sub init_meta {
      shift;
      return Moose->init_meta( @_, metaclass => 'MyApp::Meta::Class' );
  }

  sub has_table {
      my $meta = shift;
      $meta->table(shift);
  }

  package MyApp::Meta::Class;
  use Moose;

  extends 'Moose::Meta::Class';

  has 'table' => ( is => 'rw' );
}



# =begin testing
{
{
    package MyApp::User;

    MyApp::Mooseish->import;

    has_table( 'User' );

    has( 'username' => ( is => 'ro' ) );
    has( 'password' => ( is => 'ro' ) );

    sub login { }
}

isa_ok( MyApp::User->meta, 'MyApp::Meta::Class' );
is( MyApp::User->meta->table, 'User',
    'MyApp::User->meta->table returns User' );
ok( MyApp::User->can('username'),
    'MyApp::User has username method' );
}


done_testing;

