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
use Test::Requires {
    'Test::Output' => '0',
};



# =begin testing SETUP
{

  package MooseX::Debugging;

  use Moose::Exporter;

  Moose::Exporter->setup_import_methods(
      base_class_roles => ['MooseX::Debugging::Role::Object'],
  );

  package MooseX::Debugging::Role::Object;

  use Moose::Role;

  after 'BUILDALL' => sub {
      my $self = shift;

      warn "Made a new " . ( ref $self ) . " object\n";
  };
}



# =begin testing
{
{
    package Debugged;

    use Moose;
    MooseX::Debugging->import;
}

stderr_is(
    sub { Debugged->new },
    "Made a new Debugged object\n",
    'got expected output from debugging role'
);
}


done_testing;

