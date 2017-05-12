#!perl

 use strict;
 use warnings;
 use Test::More;
 use FindBin::libs;
 use Test::Mojo;

 $ENV{MOJO_MODE} = 'test';
 
 #deploy an empty DB
 use_ok 'ExpenseTracker';

  my $t = Test::Mojo->new('ExpenseTracker');
  ok($t, 'Created the Mojo App');
  $t->app->model->deploy( { add_drop_table => 1 } );
  note 'Created empty db';
 
 # This will find step definitions and feature files in the directory you point
 # it at below
 use Test::BDD::Cucumber::Loader;

 # This harness prints out nice TAP
 use Test::BDD::Cucumber::Harness::TestBuilder;

 # Load a directory with Cucumber files in it. It will recursively execute any
 # file matching .*_steps.pl as a Step file, and .*\.feature as a feature file.
 # The features are returned in @features, and the executor is created with the
 # step definitions loaded.
 my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
        't/features/' );

 # Create a Harness to execute against. TestBuilder harness prints TAP
 my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new({});

 # For each feature found, execute it, using the Harness to print results
 $executor->execute( $_, $harness ) for @features;
 
 done_testing();