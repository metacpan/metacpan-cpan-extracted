use strict;
use warnings;

use Test::More;

use GitStore;
use Path::Class;
use Git::PurePerl;

eval "use MooseX::Storage; 1"
    or plan skip_all => 'MooseX::Storage required for test';

plan tests => 1;

my $dir = './t/test';
dir($dir)->rmtree;

my $gitobj = Git::PurePerl->init( directory => $dir );

{
  package Point;
  use Moose;
  MooseX::Storage->import();

  with Storage( format => 'YAML', io => 'GitStore');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');
}

my $p = Point->new(x => 10, y => 10);

$p->store('my_point', git_repo => $dir);

my $p2 = Point->load('my_point', git_repo => $dir);

is_deeply $p2 => { x => 10, y => 10, git_repo => './t/test' };
