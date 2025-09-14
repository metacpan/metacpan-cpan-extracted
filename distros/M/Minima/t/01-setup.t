use v5.40;
use Test2::V0;
use Path::Tiny;

require Minima::Setup;

my $dir = Path::Tiny->tempdir;
chdir $dir;

# No config
ok( lives { Minima::Setup->import }, 'loads without any config file' )
    or note($@);

# Passed non-existing file
like(
    dies { Minima::Setup->import('ThisFileDoesNotExist') },
    qr/Config file.*does not exist/,
    'dies for non-existing config file'
);

# Passed a good Perl file
my $config = $dir->child('config.pl');
$config->spew(q/{ secret => 'good perl file' }/);
ok(
    lives { Minima::Setup->import('config.pl') },
    'loads passed config'
) or note($@);
like(
    $Minima::Setup::config->{secret},
    'good perl file',
    'processes passed Perl config file'
);

# Passed a problematic Perl file
$config->spew('{');
like(
    dies { Minima::Setup->import($config) },
    qr/Failed to parse/,
    'dies for bad syntax in Perl config file'
);

$config->spew(q/"my-config"/);
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for Perl config not made of a hash ref'
);

$config->spew();
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for passed empty Perl config'
);

# Passed a Perl file with unusual extensions
$config = $dir->child('config.c');
$config->spew(q/{ secret => '.c' }/);
ok(
    lives { Minima::Setup->import($config) },
    'loads unusual extension'
) or note($@);
like(
    $Minima::Setup::config->{secret},
    '.c',
    'processes unusual extension as Perl'
);

$config = $dir->child('config');
$config->spew(q/{ secret => 'none' }/);
ok(
    lives { Minima::Setup->import($config) },
    'loads extensionless config as Perl'
) or note($@);
like(
    $Minima::Setup::config->{secret},
    'none',
    'processes extensionless config'
);

# Passed a good YAML file
$config = $dir->child('config.yaml');
$config->spew(q/extension: '.yaml'/);
ok(
    lives { Minima::Setup->import($config) },
    'loads .yaml config file',
) or note($@);
like(
    $Minima::Setup::config->{extension},
    '.yaml',
    'processes .yaml config file'
);

$config = $dir->child('config.yml');
$config->spew(q/extension: '.yml'/);
ok(
    lives { Minima::Setup->import($config) },
    'loads .yml config file',
) or note($@);
like(
    $Minima::Setup::config->{extension},
    '.yml',
    'processes .yaml config file'
);

# Passed a problematic YAML file
$config->spew('@');
like(
    dies { Minima::Setup->import($config) },
    qr/Failed to parse/,
    'dies for bad syntax in YAML file'
);

$config->spew('1');
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for YAML config not made of a dictionary'
);

$config->spew();
like(
    dies { Minima::Setup->import($config) },
    qr/not a hash reference/,
    'dies for passed empty YAML config'
);

# Passed nothing, expecting to use the default location
mkdir 'etc';
$config = $dir->child('etc/config.pl');
$config->spew(q/{ secret => 'default' }/);
ok( lives { Minima::Setup->import }, 'loads default Perl config' )
    or note($@);
like(
    $Minima::Setup::config->{secret},
    'default',
    'processes default Perl config'
);

$config->remove;
$config = $dir->child('etc/config.yml');
$config->spew(q/secret: '.yml'/);
ok(
    lives { Minima::Setup->import },
    'loads default YAML config (.yml)'
) or note($@);
like(
    $Minima::Setup::config->{secret},
    '.yml',
    'processes default YAML config (.yml)'
);

$config->remove;
$config = $dir->child('etc/config.yaml');
$config->spew(q/secret: '.yaml'/);
ok(
    lives { Minima::Setup->import },
    'loads default YAML config (.yaml)'
) or note($@);
like(
    $Minima::Setup::config->{secret},
    '.yaml',
    'processes default YAML config (.yaml)'
);

$config->spew('}');
like(
    dies { Minima::Setup->import },
    qr/Failed to parse default config/,
    'dies for bad syntax in default config'
);

$config->spew(q/"my-config"/);
like(
    dies { Minima::Setup->import },
    qr/not a hash reference/,
    'dies for default config not made of a hash ref'
);

$config->spew();
like(
    dies { Minima::Setup->import },
    qr/not a hash reference/,
    'dies for empty default config'
);

# Respects base_dir
my $base_config = $dir->child('base.pl');
$base_config->spew('{}');

Minima::Setup->import('base.pl');
like(
    $Minima::Setup::config->{base_dir},
    path('.')->absolute,
    'sets default base_dir'
);

$base_config->spew('{ base_dir => "/secret" }');
Minima::Setup->import('base.pl');
like(
    $Minima::Setup::config->{base_dir},
    '/secret',
    'respects existing base_dir'
);

chdir;

done_testing;
