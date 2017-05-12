#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use File::Write::Rotate;
use Taint::Runtime qw(untaint);

my $dir = tempdir(CLEANUP=>1);
$CWD = $dir;

test_rotate(
    # correctly rename, only keep N histories, doesn't touch other prefixes,
    # handle compress suffix
    name   => "basic rotate",
    args   => [prefix=>"a", histories=>3],
    files_before  => [qw/a a.1 a.2.gz a.3  b b.1 b.2 b.3 b.4/],
    before_rotate => sub {
        write_text("a"  ,    "zero");
        write_text("a.1",    "one");
        write_text("a.2.gz", "two");

        write_text("b.1"   , "untouched");
    },
    files_after   => [qw/a.1 a.2 a.3.gz    b b.1 b.2 b.3 b.4/],
    after_rotate  => sub {
        is(scalar read_text("a.1"),    "zero", "a -> a.1");
        is(scalar read_text("a.2"),    "one",  "a.2 -> a.2.gz");
        is(scalar read_text("a.3.gz"), "two",  "a.2.gz -> a.3.gz");

        is(scalar read_text("b.1"), "untouched",  "b.1 untouched");
    },
);

test_rotate(
    name   => "period, suffix",
    args   => [prefix=>"a", suffix=>".log", histories=>2],
    files_before  => [qw/a.2010-01
                         a.2011.log a.2012-10.log a.2012-11.log a.2012-12.log/],
    files_after   => [qw/a.2010-01
                         a.2012-11.log a.2012-12.log.1/],
);

test_rotate(
    name => "period, suffix (complex, no delete)",
    args => [prefix=>"a", suffix=>".log", histories=>10],
    files_before => [qw/a.2012-09.log a.2012-10.log a.2012-10.log.1 a.2012-10.log.2 a.2012-11.log   a.2012-11.log.1/],
    files_after =>  [qw/a.2012-09.log a.2012-10.log a.2012-10.log.1 a.2012-10.log.2 a.2012-11.log.1 a.2012-11.log.2/]
);

test_rotate(
    name => "period, suffix (complex, rotate and delete)",
    args => [prefix=>"a", suffix=>".log", histories=>3],
    files_before => [qw/a.2012-09.log a.2012-10.log a.2012-10.log.1 a.2012-10.log.2 a.2012-11.log   a.2012-11.log.1/],
    files_after =>  [qw/              a.2012-10.log                                 a.2012-11.log.1 a.2012-11.log.2/]
);


test_rotate(
    name => "period, suffix (complex, delete_only)",
    args => [prefix=>"a", suffix=>".log", histories=>3],
    rotate_args => [delete_only => 1],
    files_before => [qw/a.2012-09.log a.2012-10.log a.2012-10.log.1 a.2012-10.log.2 a.2012-11.log a.2012-11.log.1/],
    files_after =>  [qw/              a.2012-10.log                                 a.2012-11.log a.2012-11.log.1/]
);


{
    my $executed_hook_before_rotate;
    my $executed_hook_after_rotate;
    test_rotate(
        name   => "hook_before_rotate, hook_after_rotate",
        args   => [
            prefix=>"a", suffix=>".log", histories=>2,
            hook_before_rotate => sub {
                my ($self, $files) = @_;
                is_deeply($files, [qw/a.2011.log
                                      a.2012-10.log
                                      a.2012-11.log
                                      a.2012-12.log/]) or
                    diag explain $files;
                $executed_hook_before_rotate = 1;
            },
            hook_after_rotate => sub {
                my ($self, $renamed, $deleted) = @_;
                is_deeply($renamed, ["a.2012-12.log.1"], 'renamed argument')
                    or diag explain $renamed;
                is_deeply($deleted, [qw/
                                           a.2011.log
                                           a.2012-10.log
                                       /], 'deleted argument')
                    or diag explain $deleted;
                $executed_hook_after_rotate = 1;
            },
        ],
        files_before  => [qw/a.2010-01
                             a.2011.log a.2012-10.log a.2012-11.log a.2012-12.log/],
        files_after   => [qw/a.2010-01
                             a.2012-11.log a.2012-12.log.1/],
        after_rotate => sub {
            ok($executed_hook_before_rotate, "hook_before_rotate executed");
            ok($executed_hook_after_rotate , "hook_after_rotate executed");
        },
    );
}

{
    use tainting;
    test_rotate(
        # test rename and unlink works under tainting
        name   => "under tainting",
        args   => [prefix=>"a", histories=>3],
        files_before  => [qw/a a.1 a.2 a.3/],
        before_rotate => sub {
            write_text($_, "") for (qw/a a.1 a.2 a.3/);
        },
        files_after   => [qw/a.1 a.2 a.3/],
        after_rotate  => sub {
        },
    );
}

DONE_TESTING:
done_testing;
if (Test::More->builder->is_passing) {
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $dir";
}

sub test_rotate {
    my (%args) = @_;

    subtest $args{name} => sub {

        my $fwr = File::Write::Rotate->new(
            dir => $dir,
            @{$args{args}}
        );

        my $dh;

        # remove all files first
        opendir $dh, ".";
        while (my $e = readdir($dh)) {
            next if $e eq '.' || $e eq '..';
            untaint \$e;
            remove_tree($e);
        }

        write_text($_, "") for @{$args{files_before}};
        $args{before_rotate}->($fwr) if $args{before_rotate};

        $fwr->_rotate_and_delete($args{rotate_args} ? @{$args{rotate_args}} : ());

        undef $fwr;

        my @files;
        opendir $dh, ".";
        while (my $e = readdir($dh)) {
            next if $e eq '.' || $e eq '..';
            push @files, $e;
        }
        @files = sort @files;

        is_deeply(\@files, $args{files_after}, "files_after")
            or diag explain \@files;

        $args{after_rotate}->($fwr) if $args{after_rotate};
    };
}
