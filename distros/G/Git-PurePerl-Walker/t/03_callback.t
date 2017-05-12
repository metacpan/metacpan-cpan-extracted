use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use Path::Tiny qw(path);

use lib path($FindBin::Bin)->child("tlib")->absolute->stringify;
use t::util { '$repo' => 1 };

# FILENAME: 03_callback.t
# CREATED: 29/05/12 08:34:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: OnCommit::CallBack test
use Git::PurePerl::Walker::OnCommit::CallBack;

my $v;
my $i = 0;

my $caller_factory = Git::PurePerl::Walker::OnCommit::CallBack->new(
  callback => sub {
    $i++;
    $v = \@_;
  }
);

my $caller = $caller_factory->for_repository($repo);

$caller->handle( $repo->master );

is( $v->[0]->sha1, '010fb4bcf7d92c031213f43d0130c811cbb355e7', 'Callback triggered' );
