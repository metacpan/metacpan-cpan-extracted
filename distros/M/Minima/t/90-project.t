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

chdir;
$dir = Path::Tiny->tempdir;
chdir $dir;

ok(
    lives { Minima::Project::create(undef) },
    'uses current directory if undef passed'
);

ok(
    lives { Minima::Project::create($dir->child('NewDirectory')) },
    'creates a new directory if needed'
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

{
    my $output;
    open my $fake_stdout, '>', \$output;
    my $real_stdout = select $fake_stdout;

    Minima::Project::create(
        $dir->child('AnotherNewDirectory'),
        { verbose => 1 },
    );

    select $real_stdout;
    close $fake_stdout;

    like(
        $output,
        qr/mkdir|spew/,
        'outputs text in verbose mode'
    );
}

chdir;

done_testing;
