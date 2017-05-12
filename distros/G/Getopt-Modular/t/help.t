#!perl

use Test::More qw(no_plan); # tests => 1;

BEGIN {
    use_ok( 'Getopt::Modular', '-namespace', 'GM');
}

use Data::Dumper;

GM->acceptParam(
                'foo|f' => {
                    spec => '!',
                    help => qq[helpful foo that has a really nice, long annoying run-on boring description],
                    default => 5,
                },
                'zoo|Z' => {
                    spec => '=s',
                    help => qq[zoo],
                    valid_values => sub { qw/abbc bccd cdde/ },
                },
                'bar|b' => {
                    spec => '!',
                    help => qq[helpful bar that has a really nice, long annoying run-on boring description],
                    default => 1,
                    help_bool => [ qw/ yuck yum / ],
                },
               );

my @l = GM->getHelpRaw();
is_deeply($l[1]{param}, [ qw(--foo --nofoo -f) ], 'parameters right');
like($l[1]{help}, qr/helpful foo/, 'help right');
like($l[1]{default}, qr/on/, 'default right') or diag(Dumper $l[0]);
is_deeply($l[2]{valid_values}, [ qw(abbc bccd cdde) ], 'valid values right');

SKIP: {
    eval { require Text::Table; 1 } or skip 'Optional module Text::Table missing', 3;

    my $help = GM->getHelp();
    like("$help", qr/helpful foo/);
    like("$help", qr/\[on\]/);
    like("$help", qr/nofoo.*Current\s+value/);
};

SKIP: {
    eval { require Text::Table; require Text::Wrap; 1 } or skip 'Optional modules Text::Table and/or Text::Wrap missing', 7;

    my $help = GM->getHelpWrap();
    like("$help", qr/helpful foo/);
    like("$help", qr/\[on\]/);
    like("$help", qr/nofoo.*description/);
    like("$help", qr/abbc\s*,\s*bccd\s*,\s*cdde/);
    unlike("$help", qr/nofoo.*long/);

    $help = GM->getHelpWrap(30);
    like("$help", qr/helpful foo/);
    like("$help", qr/\[yum\].*\[on\]/sm);
    like("$help", qr/nofoo.*really nice/);
};

