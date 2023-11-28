#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

use Cwd 'abs_path';
use File::chdir;
use File::MoreUtil qw(file_exists);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use File::Trash::FreeDesktop;

my $dir = tempdir(CLEANUP=>1);

$ENV{HOME} = $dir;
$CWD = $dir;
my $trash = File::Trash::FreeDesktop->new(home_only=>1);

write_text("f1", "f1");
write_text("f2", "f2");
mkdir "sub";
write_text("sub/f1", "sub/f1");
write_text("sub/f2", "sub/f2");

my $ht = $trash->_home_trash;
diag "home trash is $ht";

subtest "list_contents" => sub {
    $trash->trash("f1");
    $trash->trash("f2");

    my @contents;

    @contents = $trash->list_contents();
    is(scalar(@contents), 2);
    is($contents[0]{entry}, "f1");
    is($contents[1]{entry}, "f2");

    # path filter
    @contents = $trash->list_contents({path=>"$dir/f1"});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f1");

    # path_wildcard filter
    @contents = $trash->list_contents({path_wildcard=>"$dir/*2"});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f2");

    # path_re filter
    @contents = $trash->list_contents({path_re=>qr/[1]$/});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f1");

    # filename filter
    @contents = $trash->list_contents({filename=>"f2"});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f2");

    # path_wildcard filter
    @contents = $trash->list_contents({filename_wildcard=>"f[13]"});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f1");

    # path_re filter
    @contents = $trash->list_contents({filename_re=>qr/^f[24]$/});
    is(scalar(@contents), 1);
    is($contents[0]{path}, "$dir/f2");

    $trash->recover("$dir/f1");
    $trash->recover("$dir/f2");
};

subtest "trash" => sub {
    my $tfile = $trash->trash("f1");
    is(abs_path($tfile), abs_path("$dir/.local/share/Trash/files/f1"),
       "return value of trash()");
    ok((!(-e "f1")), "f1 removed");
    ok((-f ".local/share/Trash/info/f1.trashinfo"), "f1.trashinfo created");
    ok((-f ".local/share/Trash/files/f1"), "files/f1 created");

    $trash->trash("sub/f1");
    ok((!(-e "sub/f1")), "sub/f1 removed");
    ok((-f ".local/share/Trash/info/f1.2.trashinfo"), "f1.2.trashinfo created");
    ok((-f ".local/share/Trash/files/f1.2"), "files/f1.2 created");

    $trash->trash("f2");
    ok((!(-e "f2")), "f2 removed");
    ok((-f ".local/share/Trash/info/f2.trashinfo"), "f2.trashinfo created");
    ok((-f ".local/share/Trash/files/f2"), "files/f2 created");
};
# state at this point: T(f1 sub/f1 f2)

subtest "recover" => sub {
    $trash->recover("$dir/f1", $ht);
    ok((-f "f1"), "f1 recreated");
    ok(!(-f "sub/f1"), "sub/f1 NOT recreated");
};
# state at this point: f1 sub/f1 T(f2)

subtest "erase" => sub {
    $trash->erase("f2", $ht);
    ok(!(-e "f2"), "f2 removed");
    ok(!(-e ".local/share/Trash/info/f2.trashinfo"),"f2.trashinfo removed");
    ok(!(-e ".local/share/Trash/files/f2"), "files/f2 removed");

    write_text("f3", "");
    $trash->trash("f3");
    write_text("f4", "");
    $trash->trash("f4");
    # opt: filename_pattern
    $trash->erase({filename_wildcard=>"f[34]"});
    ok(!(-e "f3"), "f3 removed");
    ok(!(-e "f4"), "f4 removed");
};
# state at this point: f1 sub/f1 T()

subtest "empty" => sub {
    $trash->trash("sub"); # also test removing directories
    $trash->empty($ht);
    ok(!(-e "sub"), "sub removed");
};
# state at this point: T()

subtest "trash nonexisting file" => sub {
    dies_ok  { $trash->trash("f3") } "trash nonexisting file -> dies";
    lives_ok { $trash->trash({on_not_found=>'ignore'}, "f3") }
        "on_not_found=ignore";
};
# state at this point: T()

# state at this point: T()

subtest "recover" => sub {
    write_text("f3", "");
    write_text("f4", "");
    $trash->trash("f3");
    $trash->trash("f4");
    # option: filename_re
    $trash->recover({filename_re=>qr/f[34]/});
    ok((-f "f3"), "f3 recovered");
    ok((-f "f4"), "f4 recovered");
    unlink "f3", "f4";
};
# state at this point: T()

write_text("f3", "f3a");
$trash->trash("f3");
write_text("f3", "f3b");
subtest "recover to an existing file" => sub {
    dies_ok { $trash->recover("$dir/f3") } "restore target already exists";
    is(read_text("f3"), "f3b", "existing target not replaced");
    lives_ok { $trash->recover({on_target_exists=>'ignore'}, "$dir/f3") }
        "on_target_exists=ignore";
    is(read_text("f3"), "f3b", "existing target not replaced");
    unlink "f3";
    lives_ok { $trash->recover("$dir/f3") } "can recover after target cleared";
    is(read_text("f3"), "f3a", "the correct file recovered");
};
# state at this point: f3 T()

subtest "recover: mtime opt" => sub {
    write_text("f10", "f10.10");
    utime 1, 10, "f10";
    $trash->trash("f10");

    write_text("f10", "f10.20");
    utime 1, 20, "f10";
    $trash->trash("f10");

    $trash->recover({mtime=>20, filename=>"f10"});
    is(read_text("f10"), "f10.20", "f10 (mtime 20) recovered first");
    unlink "f10";
    $trash->recover({mtime=>10, filename=>"f10"});
    is(read_text("f10"), "f10.10", "f10 (mtime 10) recovered");
    $trash->empty($ht);
};
# state at this point: f1 T()

subtest "recover: suffix opt" => sub {
    write_text("f10", "f10.a");
    $trash->trash({suffix=>"a"}, "f10");

    write_text("f10", "f10.b");
    $trash->trash({suffix=>"b"}, "f10");

    write_text("f10", "f10.another-b");
    dies_ok { $trash->recover({suffix=>"b", filename=>"f10"}) }
        "suffix already exists -> dies";
    unlink "f10";

    $trash->recover({suffix=>"b", filename=>"f10"});
    is(read_text("f10"), "f10.b", "f10 (suffix b) recovered first");
    unlink "f10";
    $trash->recover({suffix=>"a", filename=>"f10"});
    is(read_text("f10"), "f10.a", "f10 (suffix a) recovered");
    $trash->empty($ht);
};
# state at this point: f1 T()

subtest "trash symlink" => sub {
    plan skip_all => "symlink() not available"
        unless eval { symlink "", ""; 1 };

    write_text("f21", "");
    symlink "f21", "s21";

    $trash->trash("s21");
    ok(!file_exists("s21"), "s21 deleted");
    ok( file_exists("f21"), "f21 not deleted");

    $trash->recover("$dir/s21");
    ok( file_exists("s21"), "s21 recovered");
    ok((-l "s21"), "s21 still a symlink");
    ok( file_exists("f21"), "f21 still not deleted");

    symlink "/", "s22";
    $trash->trash("s22"); # doesn't die because trying to create /.Trash-1000

    unlink "f21";
};
# state at this point: f1 T()

# TODO test: {trash,recover,erase} in $topdir/.Trash-$uid
# TODO test: list_trashes
# TODO test: empty for all trashes
# TODO test: test errors ...
#   - die on fail to create $topdir/.Trash-$uid
# TODO: deleting/listing/recovering a symlink with invalid target (-f false)

DONE_TESTING:
done_testing;
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/" unless $ENV{DEBUG_KEEP_TEMPDIR};
} else {
    diag "there are failing tests, not deleting test data dir ($dir)";
}
