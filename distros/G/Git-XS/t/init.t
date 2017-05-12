use Test::More tests => 6;

use Git::XS;
use File::Path;

my $repo = "t/test_repo";
File::Path::rmtree($repo);
mkdir $repo or die;

my $g = Git::XS->new(repo => $repo);
is ref($g), 'Git::XS', 'new() succeeded';

my $r = $g->init();
is ref($r), 'Git::XS', 'init() succeeded';

ok -f("$repo/.git/config"), 'init() actually worked';

File::Path::rmtree($repo);
mkdir $repo or die;

my $g2 = Git::XS->new(repo => $repo);
is ref($g2), 'Git::XS', 'new() succeeded';

my $r2 = $g->init(-bare);
is ref($r2), 'Git::XS', 'init(-bare) succeeded';

ok -f("$repo/config"), 'init(-bare) actually worked';

File::Path::rmtree($repo);
