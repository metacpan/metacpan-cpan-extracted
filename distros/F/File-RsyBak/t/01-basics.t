#!perl

use 5.010;
use strict;
use warnings;
use Test::More;

use File::chdir;

$ENV{PATH} = "/usr/local/bin:/usr/bin:/bin";
if (!which("rsync")) {
    plan skip_all => "Can't find rsync";
}

use File::Temp    qw(tempdir);
use File::Which   qw(which);
use File::RsyBak  qw(backup);
use File::Slurper qw(write_text);
use String::ShellQuote;

my $tmpdir = tempdir(CLEANUP => 1);
$CWD = $tmpdir;

test_backup(
    n_sources => 1,
    name      => "single source",
    test_hist => 1,
);
test_backup(
    n_sources => 1,
    extra_dir => 1,
    name      => "single source with forced extra_dir",
);
test_backup(
    n_sources => 2,
    name      => "multiple sources",
);

test_backup(
    n_sources             => 1,
    name                  => "extra_rsync_opts",
    test_extra_rsync_opts => 1, # currently is tested when n_sources=1
);

# XXX test rsync_cp_opts

done_testing();
if (Test::More->builder->is_passing) {
    $CWD = "/";
} else {
    diag("tmpdir = $tmpdir");
}

sub test_backup {
    my %args = @_;
    my $name = $args{name};
    my $msource = $args{n_sources} > 1;

    delete_source();
    prepare_source();
    delete_target();

    my %bargs = (target => "$tmpdir/target", histories=>[2, 1]);
    if ($msource) {
        $bargs{source} = ["$tmpdir/src1", "$tmpdir/src2/"]; # test handling /
    } else {
        $bargs{source} = "$tmpdir/src1";
    }
    $bargs{extra_dir} = 1 if $args{extra_dir};
    if ($args{test_extra_rsync_opts}) {
        $bargs{extra_rsync_opts} = ['--exclude', '/file1'];
    }

    backup(%bargs);

    if ($msource || $args{extra_dir}) {
        ok((-f "$tmpdir/target/current/src1/dir1/dir2/file3"),
           "$name (files copied, extra_dir)");
    } else {
        ok((-f "$tmpdir/target/current/dir1/dir2/file3"),
           "$name (files copied, no extra_dir)");

        if ($args{test_extra_rsync_opts}) {
            ok(!(-f "$tmpdir/target/current/file1"),
               "(extra rsync opts, --exclude, in effect)");
        } else {
            ok( (-f "$tmpdir/target/current/file1"),
                "(no extra rsync opts, --exclude, in effect)");
        }

    }
    if ($msource) {
        ok((-f "$tmpdir/target/current/src2/file1"),
           "$name (all sources copied)");
    }


    # XXX test hardlink, test changing files

    if ($args{test_hist}) {
        # XXX test -N in history level
        do { backup(%bargs); sleep 1 } for 1..2*1*2;
        my @h1 = <$tmpdir/target/hist.*>;
        my @h2 = <$tmpdir/target/hist2.*>;
        #my @h3 = <$tmpdir/target/hist3.*>;
        is(scalar(@h1), 2, "level-1 backup histories");
        is(scalar(@h2), 1, "level-2 backup histories");
        #is(scalar(@h3), 2, "level-3 backup histories");
    }
}

sub prepare_source {
    mkdir "src1";
    mkdir "src1/dir1";
    mkdir "src1/dir1/dir2";
    write_text("src1/file1", "test1");
    write_text("src1/dir1/file2", "test2");
    write_text("src1/dir1/dir2/file3", "test3");

    mkdir "src2";
    write_text("src2/file1", "TEST1");
}

sub delete_source {
    system "rm -rf src1 src2";
}

sub delete_target {
    system "rm -rf target";
}
