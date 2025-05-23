#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Stubb;

use File::Path qw(remove_tree);
use File::Spec;
use File::Temp qw(tempdir);

use File::Stubb::Home;

my $TMPDIR = tempdir;
my $TMP = File::Spec->catfile($TMPDIR, 'stubb');
my $TEMPLATES = File::Spec->catfile(qw/t data templates/);

sub slurp {

    my ($file) = @_;

    local $/ = undef;
    open my $fh, '<', $file
        or die "Failed to open $file for reading: $!\n";
    my $slurp = <$fh>;
    close $fh;

    return $slurp;

}

sub new_stubb {

    local @ARGV = @_;

    return File::Stubb->init;

}

$ENV{ STUBB_TEMPLATES } = $TEMPLATES;

my $stubb;

$stubb = new_stubb($TMP, 'basic');
isa_ok($stubb, 'File::Stubb');

is($stubb->{ Mode }, 0, 'mode ok');
is_deeply(
    $stubb->{ Files },
    [ $TMP ],
    'files ok'
);
is($stubb->{ Template }, File::Spec->catfile($TEMPLATES, 'basic.stubb'), 'template ok');
is($stubb->{ Subst }, undef, 'subst ok');
is_deeply(
    $stubb->{ TempDir },
    [ $TEMPLATES, File::Spec->catfile(home, '.stubb') ],
    'template directory ok'
);
is($stubb->{ Verbose }, 1, 'verbose ok');
is($stubb->{ Hidden }, undef, 'hidden ok');
is($stubb->{ FollowLinks }, undef, 'follow symlinks ok');
is($stubb->{ CopyPerms }, undef, 'copy perms ok');
is($stubb->{ Defaults }, undef, 'defaults ok');
is($stubb->{ IgnoreConf }, undef, 'ignore config ok');

ok($stubb->run, "stubb doesn't die");

is(
    slurp($TMP),
    <<'HERE',
My favorite number: ^^one^^
My third favorite number: ^^three^^
My three favorite numbers: ^^one^^, ^^two^^, ^^three^^, 4
HERE
    'file render ok'
);

unlink $TMP;

$stubb = new_stubb("$TMP.basic");
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");
ok(-f "$TMP.basic", 'file render ok');

unlink "$TMP.basic";

$stubb = new_stubb('-t', 'basic', $TMP);
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");
ok(-f $TMP, 'file render ok');

unlink $TMP;

$stubb = new_stubb($TMP, 'basic', '-s', 'one => 1, two => 2, three => 3, four => \\,');
isa_ok($stubb, 'File::Stubb');

is_deeply(
    $stubb->{ Subst },
    {
        one   => '1',
        two   => '2',
        three => '3',
        four  => ','
    },
    'subst ok'
);

ok($stubb->run, "stubb doesn't die");

is(
    slurp($TMP),
    <<'HERE',
My favorite number: 1
My third favorite number: 3
My three favorite numbers: 1, 2, 3, ,
HERE
    'file render ok'
);

unlink $TMP;

$stubb = new_stubb($TMP, 'basic', '-qACWUI', '-d', $TEMPLATES);
isa_ok($stubb, 'File::Stubb');

is_deeply(
    $stubb->{ TempDir },
    [ $TEMPLATES, $TEMPLATES, File::Spec->catfile(home, '.stubb') ],
    'template directory ok'
);
is($stubb->{ Verbose }, 0, 'verbose ok');
is($stubb->{ Hidden }, 0, 'hidden ok');
is($stubb->{ CopyPerms }, 0, 'copy perms ok');
is($stubb->{ FollowLinks }, 0, 'follow symlinks ok');
is($stubb->{ Defaults }, 0, 'defaults ok');
is($stubb->{ IgnoreConf }, 1, 'ignore config ok');

$stubb = new_stubb($TMP, 'basic', '-acw');
isa_ok($stubb, 'File::Stubb');

is($stubb->{ Hidden }, 1, 'hidden ok');
is($stubb->{ CopyPerms }, 1, 'copy perms ok');
is($stubb->{ FollowLinks }, 1, 'follow symlinks ok');

$stubb = new_stubb($TMP, 'dir', '-s', 'one => 1, two => 2');
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");

ok(-d $TMP, 'directory render ok');
ok(-f File::Spec->catfile($TMP, '1.txt'), 'directory render ok');
ok(-d File::Spec->catfile($TMP, '2'), 'directory render ok');

remove_tree($TMP, { safe => 1 });

$stubb = new_stubb($TMP, 'dir-json');
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");

ok(-d $TMP, 'directory render ok');
ok(-f File::Spec->catfile($TMP, '.1.txt'), 'directory render ok');
ok(-d File::Spec->catfile($TMP, '2'), 'directory render ok');

remove_tree($TMP, { safe => 1 });

$stubb = new_stubb($TMP, 'dir-json', '-I');
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");

ok(-d $TMP, 'directory render ok');
ok(! -f File::Spec->catfile($TMP, '.^^one^^.txt'), 'directory render ok');
ok(-d File::Spec->catfile($TMP, '^^two^^'), 'directory render ok');

remove_tree($TMP, { safe => 1 });

$stubb = new_stubb($TMP, 'dir-json', '-AU');
isa_ok($stubb, 'File::Stubb');

ok($stubb->run, "stubb doesn't die");

ok(-d $TMP, 'directory render ok');
ok(! -f File::Spec->catfile($TMP, '.^^one^^.txt'), 'directory render ok');
ok(-d File::Spec->catfile($TMP, '^^two^^'), 'directory render ok');

remove_tree($TMP, { safe => 1 });

done_testing;

END {
    if (-d $TMPDIR) {
        remove_tree($TMPDIR, { safe => 1 });
    }
}

# vim: expandtab shiftwidth=4
