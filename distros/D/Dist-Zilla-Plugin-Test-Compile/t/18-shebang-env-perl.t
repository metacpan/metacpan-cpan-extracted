use strict;
use warnings;

use Test::More 0.96;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::DZil;
use Path::Tiny;
use File::pushd 1.004 'pushd';
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ ExecDir => ],
                [ 'Test::Compile' => { fail_on_warning => 'none' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source bin foo)) => <<'EXECUTABLE',
#!/usr/bin/env perl -w
my $foo = 1;
print "oh noes\n" if $foo = 2;
EXECUTABLE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(t 00-compile.t));
ok( -e $file, 'test created');

my @warnings = warnings {
    subtest 'run the generated test' => sub
    {
        my $wd = pushd $build_dir;
        $tzil->plugin_named('MakeMaker')->build;

        do $file;
        note 'ran tests successfully' if not $@;
        fail($@) if $@;
    };
};

my $re = '^' .  quotemeta("Found = in conditional, should be == at bin\/foo line 3. at $file line ");
cmp_deeply(
    \@warnings,
    [
        re(qr/^$re/),
    ],
    'got the right warnings, showing we tested the script with "#!/usr/bin/env perl"',
)
    or diag 'got warning(s): ', explain(\@warnings);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
