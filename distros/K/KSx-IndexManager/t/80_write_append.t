#!perl

use strict;
use warnings;
use Test::More 'no_plan';
use Iterator::Simple qw(iter);
use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

use lib 't/lib';
use My::Manager;
use My::Schema;


my $mgr = My::Manager->new({
  root   => $dir,
  schema => 'My::Schema',
});

sub add_ok {
  my ($self, $meth, $docs, $query, $count, $label) = @_;
  eval { $self->$meth($docs) };
  is $@, '', "$label: no error adding docs";

  is(
    $self->searcher->search(
      query => $query,
    )->total_hits,
    $count, "$meth/$label: correct number of docs",
  );
}

add_ok(
  $mgr, 'write', [ map { { id => $_ } } 1..10 ],
  'untyped', 10, 'array',
);

add_ok(
  $mgr, 'append', iter([ map { { id => $_ } } 11..15 ]),
  'untyped', 15, 'iter',
);

