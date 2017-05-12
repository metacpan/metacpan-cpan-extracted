#!perl

use strict;
use warnings;

use Test::More tests => 19;

use lib 't/lib';
use My::Manager;
use My::Schema;

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

sub invindexer_ok {
  my ($self, $label) = @_;
  $label = "invindexer/$label";
  my $invindexer = eval { $self->open };
  is $@, "", "$label: no error getting invindexer";
  isa_ok $invindexer, $self->invindexer_class, "$label: got a good object";
  $invindexer->add_doc({ id => $_ }) for 1..10;
  $invindexer->finish;
  ok -e $self->path, "$label: created " . $self->path;
  ok -e $self->path . "/segments_2.yaml",
    "$label: created segments";
}

sub searcher_ok {
  my ($self, $label) = @_;
  $label = "searcher/$label";
  my $searcher = eval { $self->searcher };
  is $@, "", "$label: no error getting searcher";
  isa_ok $searcher, $self->searcher_class, "$label: got a good object";
}

my $mgr = My::Manager->new({
  root => "$dir/root",
  schema => 'My::Schema',
  context => { color => "blue", id => 5 },
});

invindexer_ok($mgr, "no plugins");
searcher_ok  ($mgr, "no plugins");

My::Manager->add_plugins(
  Partition => { key => 'color' },
);

invindexer_ok($mgr, "partition on color");
searcher_ok  ($mgr, "partition on color");

My::Manager->add_plugins(
  Partition => { key => 'id' },
);

invindexer_ok($mgr, "partition on color id");
searcher_ok  ($mgr, "partition on color id");

ok -e "$dir/root/blue/5/segments_2.yaml", "segments_2.yaml exists for deepest index";
