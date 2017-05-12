use strict;
use warnings;

use Test::More tests => 5;
use FindBin;
use Path::Tiny qw(path);
use Scalar::Util qw( refaddr );

use lib path($FindBin::Bin)->child("tlib")->absolute->stringify;
use t::util { '$repo' => 1 };

# FILENAME: 04_list.t
# CREATED: 29/05/12 08:34:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: OnCommit::List test
use Git::PurePerl::Walker::OnCommit::CallBack;
use Git::PurePerl::Walker::OnCommit::List;

my $v = [];
my $i = [ 0, 0 ];

my $list_factory = Git::PurePerl::Walker::OnCommit::List->new();

$list_factory->add_event(
  Git::PurePerl::Walker::OnCommit::CallBack->new(
    callback => sub {
      $i->[0]++;
      $v->[0] = \@_;
    }
  )
);
$list_factory->add_event(
  Git::PurePerl::Walker::OnCommit::CallBack->new(
    callback => sub {
      $i->[1]++;
      $v->[1] = \@_;
    }
  )
);
my $li = $list_factory->for_repository($repo);

$li->handle( $repo->master );

is( $v->[0]->[0]->sha1, '010fb4bcf7d92c031213f43d0130c811cbb355e7', 'Callback triggered' );
is( $v->[1]->[0]->sha1, '010fb4bcf7d92c031213f43d0130c811cbb355e7', 'Callback 2 triggered' );
isnt( refaddr $li->events->[0], refaddr $list_factory->events->[0], "callback is cloned x1" );
isnt( refaddr $li->events->[1], refaddr $list_factory->events->[1], "callback is cloned x2" );

my $c = Git::PurePerl::Walker::OnCommit::CallBack->new(
  callback => sub {
    $i->[2]++;
    $v->[2] = \@_;
  }
);
$li->add_event($c);
isnt( refaddr $li->events->[2], refaddr $c, "callback is cloned x3" );
