use v5.40;
use Test2::V0;
use Path::Tiny;

use Minima;
use Minima::Project;

my $dir = Path::Tiny->tempdir;
chdir $dir;

ok(
    lives { Minima::Project::create($dir) },
    'lives on empty directory'
);

like(
    dies { Minima::Project::create($dir) },
    qr/must be empty/,
    'dies for non-empty directory'
);

like(
    dies { Minima::Project::create($dir->child('app.psgi')) },
    qr/must be a directory/,
    'dies for file passed as directory'
);

my $cpanfile = path('cpanfile')->slurp;
my ($version) = $cpanfile =~ /'([^']+)';/;

ok(
    defined $version,
    'has version on cpan file'
);

like(
    $version,
    Minima->VERSION,
    q/version matches Minima's version/
);

chdir;

done_testing;
