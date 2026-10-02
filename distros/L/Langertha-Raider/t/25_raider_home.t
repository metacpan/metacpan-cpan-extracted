use strict;
use warnings;
use Test2::V0;
use Path::Tiny;

use Langertha::Raider::Home;

my $H = 'Langertha::Raider::Home';

{
  local $ENV{HOME} = '/some/home';
  is $H->home_dir, '/some/home', 'home_dir is $ENV{HOME}';
  is $H->home_base->stringify, '/some/home/.raider', 'home_base defaults to ~/.raider';
  is $H->home_base('/other')->stringify, '/other/.raider', 'home_base under a given home';
}

{
  local $ENV{HOME};
  delete $ENV{HOME};
  is $H->home_dir, (getpwuid($<))[7], 'without HOME the password database answers';
}

{
  no warnings 'redefine';
  local *Langertha::Raider::Home::home_dir = sub { undef };
  is scalar($H->home_base), undef, 'no home at all: home_base returns nothing';
  is [ $H->home_base ], [], '... an empty list in list context';
}

is $H->dir_name, '.raider', 'dir_name';
is $H->project_base('/proj')->stringify, '/proj/.raider', 'project_base';
is $H->project_base('rel')->stringify, path('rel')->absolute->child('.raider')->stringify,
  'relative root becomes absolute';
ok $H->project_base('/x')->is_absolute, 'result is an absolute Path::Tiny';
is $H->project_base('/x')->child('packs')->stringify, '/x/.raider/packs', 'children chain';

done_testing;
