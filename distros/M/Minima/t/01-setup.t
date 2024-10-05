use v5.40;
use Test2::V0;
use Path::Tiny;

require Minima::Setup;

my $dir = Path::Tiny->tempdir;
chdir $dir;

# No config
ok( lives { Minima::Setup->import }, 'loads without config.pl' )
    or note($@);

# Passed non-existing file
like(
    dies { Minima::Setup->import('ThisFileDoesNotExist') },
    qr/Config file.*does not exist/,
    'dies for non-existing config file'
);

# Passed a good file
my $config = $dir->child('config.pl');
$config->spew('{}');
ok( lives { Minima::Setup->import }, 'loads passed config' )
    or note($@);

# Passed a problematic file
$config->spew('{');
like(
    dies { Minima::Setup->import($config) },
    qr/Failed to parse/,
    'dies for bad syntax in config file'
);

$config->spew(q/"my-config"/);
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for config not made of a hash ref',
);

$config->spew();
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for passed empty config',
);

# Passed nothing, expecting to use the default location
mkdir 'etc';
$config = $dir->child('etc/config.pl');
$config->spew('{}');
ok( lives { Minima::Setup->import }, 'loads default config' )
    or note($@);

$config->spew('}');
like(
    dies { Minima::Setup->import },
    qr/Failed to parse default config/,
    'dies for bad syntax in default config',
);

$config->spew(q/"my-config"/);
like(
    dies { Minima::Setup->import },
    qr/not a hash reference/,
    'dies for default config not made of a hash ref',
);

$config->spew();
like(
    dies { Minima::Setup->import },
    qr/not a hash reference/,
    'dies for empty default config',
);

chdir;

done_testing;
