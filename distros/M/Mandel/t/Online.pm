package
  t::Online;

use Mojo::Base -strict;
use Test::More;
use Mandel ();

sub mandel {
  my $db = "mandel_test_$0"; $db =~ s/\W/_/g;
  my $connection = Mandel->connect("mongodb://localhost/$db");
  my $person = $connection->model(person => {})->model('person');
  my $cat = $connection->model(cat => {})->model('cat');
  my $dinosaur = $connection->model(dinosaur => {})->model('dinosaur');

  $person->relationship(has_many => cats => $cat->document_class)->monkey_patch;
  $person->relationship(list_of => kittens => $cat->document_class)->monkey_patch;
  $person->field([qw( age name )], {});

  $dinosaur->relationship(has_one => cat => $cat->document_class)->monkey_patch;
  $dinosaur->field([qw( name )], {});

  $cat->relationship(belongs_to => person => $person->document_class)->monkey_patch;
  $cat->field([qw( type name )], {});

  $connection;
}

sub import {
  strict->import;
  warnings->import;
  plan skip_all => 'Set TEST_ONLINE to test' unless $ENV{TEST_ONLINE};
}

1;
