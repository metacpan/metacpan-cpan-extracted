#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 12;

# TODO test that the package used is correctly cleaned when an object is deleted.

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  my $package;
  {
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$foo = 1');
    no strict 'refs';
    $package = $eval->package();
    ok(%{"${package}::"}, 'package is created'.$s);
  }{
    no strict 'refs';
    ok(!%{"${package}::"}, 'package is deleted'.$s);
  }{
    ok(Eval::Safe->new(safe => $safe, package => 't::Eval::Safe::Root'), 'create explicit package'.$s);
    # Validate that the package is correctly deleted by the first object and
    # that it can be re-used by the second one.
    ok(Eval::Safe->new(safe => $safe, package => 't::Eval::Safe::Root'), 'create explicit package twice'.$s)
  }
}

my $package;
{
  my $eval = Eval::Safe->new(safe => 0);
  $package = $eval->package();
  $eval->eval("\$${package}::Sub::foo = 1");
  no strict 'refs';
  ok(%{"${package}::Sub::"}, 'sub package is created');
}{
  no strict 'refs';
  ok(!%{"${package}::Sub::"}, 'sub package is deleted');
}{
  my $eval = Eval::Safe->new(safe => 1);
  $package = $eval->package();
  $eval->eval('$Sub::foo = 1');
  no strict 'refs';
  ok(%{"${package}::Sub::"}, 'sub package is created safe');
}{
  no strict 'refs';
  ok(!%{"${package}::Sub::"}, 'sub package is deleted safe');
}

# It's not clear if all the content of the packages is correctly destroyed, as
# can be seen in this example:
# perl -MSafe -e '$foo::a = 1; Safe->new("foo"); print eval(q($foo::a))."\n"'
#
# Deleting the content of the package would require something like:
# %{*{"foo::"}{HASH}} = (); delete *{main::}{HASH}{foo::}; undef %${foo::};
