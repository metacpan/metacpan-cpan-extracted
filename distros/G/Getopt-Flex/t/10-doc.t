use strict;
use warnings;
use Test::More tests => 17;
use Test::Warn;
use Getopt::Flex;

my $foo;
my $bar;
my @arr;
my %has;

my $cfg = {
    'usage' => 'foo [OPTIONS...] [FILES...]',
    'desc' => 'Use this to manage your foo files',
};

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'desc' => 'Expects a string naming the foo',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
        'desc' => 'When set, indicates to use bar',
    },
    'alpha|beta|gamma|zeta|eta|tau|mu|nu|sigma|phi|delta|theta|nahassapemapetilon123' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
        'desc' => 'Pass any greek letters to this argument',
    }
};

my $usage = 'Usage: '.$cfg->{'usage'}."\n";
my $desc = 'Use this to manage your foo files'."\n";
my $help = <<EOH;
Usage: foo [OPTIONS...] [FILES...]

Use this to manage your foo files

Options:

      --alpha, --beta,          Pass any greek letters to this argument
      --delta, --eta, --gamma, 
      --mu, 
      --nahassapemapetilon123, 
      --nu, --phi, --sigma, 
      --tau, --theta, --zeta
  -b, --bar                     When set, indicates to use bar
  -f, --foo                     Expects a string naming the foo
EOH

my $op = Getopt::Flex->new({spec => $sp, config => $cfg});

is($op->get_usage(), $usage, 'usage is correct');
is($op->get_desc(), $desc, 'desc is correct');
is($op->get_help(), $help, 'help is correct');

$cfg = {
    'usage' => 'foo [OPTIONS...] [FILES...]',
    'desc' => 'Use this to manage your foo files',
};

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'desc' => 'Expects a string naming the foo',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
        'desc' => 'When set, indicates to use bar',
    },
    'alpha|beta|gamma|zeta|eta|tau|mu|nu|sigma|phi|delta|theta|nahassapemapetilon1234' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
        'desc' => 'Pass any greek letters to this argument',
    }
};

$usage = 'Usage: '.$cfg->{'usage'}."\n";
$desc = 'Use this to manage your foo files'."\n";
$help = <<EOH;
Usage: foo [OPTIONS...] [FILES...]

Use this to manage your foo files

Options:

      --alpha, --beta,          Pass any greek letters to this argument
      --delta, --eta, --gamma, 
      --mu, --nu, --phi, 
      --sigma, --tau, --theta, 
      --zeta
  -b, --bar                     When set, indicates to use bar
  -f, --foo                     Expects a string naming the foo
EOH

warning_like { $op = Getopt::Flex->new({spec => $sp, config => $cfg}) } qr/too long for doc/, 'Warned option name too long';

is($op->get_usage(), $usage, 'usage is correct');
is($op->get_desc(), $desc, 'desc is correct');
is($op->get_help(), $help, 'help is correct');

$cfg = {
    'desc' => 'Use this to manage your foo files',
};

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'desc' => 'Expects a string naming the foo',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
        'desc' => 'When set, indicates to use bar',
    },
    'alpha|beta|gamma|zeta|eta|tau|mu|nu|sigma|phi|delta|theta|nahassapemapetilon1234' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
        'desc' => 'Pass any greek letters to this argument',
    }
};

$usage = "\n";
$desc = 'Use this to manage your foo files'."\n";
$help = <<EOH;
Use this to manage your foo files

Options:

      --alpha, --beta,          Pass any greek letters to this argument
      --delta, --eta, --gamma, 
      --mu, --nu, --phi, 
      --sigma, --tau, --theta, 
      --zeta
  -b, --bar                     When set, indicates to use bar
  -f, --foo                     Expects a string naming the foo
EOH

warning_like { $op = Getopt::Flex->new({spec => $sp, config => $cfg}) } qr/too long for doc/, 'Warned option name too long';

is($op->get_usage(), $usage, 'usage is correct');
is($op->get_desc(), $desc, 'desc is correct');
is($op->get_help(), $help, 'help is correct');

$cfg = {
    'desc' => 'Use this to manage your foo files',
};

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'desc' => 'Expects a string naming the foo',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
        'desc' => 'When set, indicates to use bar',
    },
    'alpha|beta|gamma|zeta|eta|tau|mu|nu|sigma|phi|delta|theta|nahassapemapetilon1234' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
    }
};

$usage = "\n";
$desc = 'Use this to manage your foo files'."\n";
$help = <<EOH;
Use this to manage your foo files

Options:

  -b, --bar                     When set, indicates to use bar
  -f, --foo                     Expects a string naming the foo
EOH

$op = Getopt::Flex->new({spec => $sp, config => $cfg});

is($op->get_usage(), $usage, 'usage is correct');
is($op->get_desc(), $desc, 'desc is correct');
is($op->get_help(), $help, 'help is correct');

$cfg = {
    'desc' => 'Use this to manage your foo files',
};

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
    },
    'alpha|beta|gamma|zeta|eta|tau|mu|nu|sigma|phi|delta|theta|nahassapemapetilon1234' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
    }
};

$usage = "\n";
$desc = 'Use this to manage your foo files'."\n";
$help = <<EOH;
Use this to manage your foo files
EOH

$op = Getopt::Flex->new({spec => $sp, config => $cfg});

is($op->get_usage(), $usage, 'usage is correct');
is($op->get_desc(), $desc, 'desc is correct');
is($op->get_help(), $help, 'help is correct');
