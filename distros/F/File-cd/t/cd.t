use strict;
use warnings;
use Test::More;

# in Windows, changing directory across volumes also works, but how do i test
# it in unknown environment?

use File::cd;

use Cwd ();
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile curdir updir);
use File::Temp ();
use FindBin    ();

my $TEST_DIR = catfile($FindBin::Bin, 'files');
setup_test_files();

sub setup_test_files {
    File::Path::make_path($TEST_DIR) or die unless -d $TEST_DIR;
    for my $file (map { catfile($TEST_DIR, $_) } qw(foo bar baz quu quux)) {
        unless (-f $file) {
            touch($file);
            note "creating $file";
        }
    }
}

sub cleanup {
    if (-d $TEST_DIR) {
        File::Path::remove_tree($TEST_DIR)
          or die "Could not delete $TEST_DIR";
    }
}

sub touch {
    my $file = shift;
    open my $fh, '>', $file or die $!;
    close $fh or die $!;
}

sub go_up_one_level {
    chdir updir or die $!;
}

sub go_up_two_level {
    chdir updir or die $!;
    chdir updir or die $!;
}

sub sub_that_dies {
    die "I don't feel so good";
}

subtest cd => sub {
    my $orig_dir   = Cwd::realpath(curdir);
    my $inside_dir = Cwd::realpath("$FindBin::Bin/../");

    cd $inside_dir => sub {
        is $inside_dir, Cwd::realpath("$FindBin::Bin/../"),
          'from inside coderef';
    };
    is $orig_dir, Cwd::realpath(curdir), 'go back to original directory';

    File::cd::cd $inside_dir => sub {
        is $inside_dir, Cwd::realpath("$FindBin::Bin/../"),
          'from inside coderef, invoked with full name';
    };
    is $orig_dir, Cwd::realpath(curdir), 'go back to original directory';

    is(Cwd::realpath(curdir), $orig_dir, 'go back to the original directory');

};

subtest exceptions => sub {
    my $inexistent = 'foobarbazquuquux';
    local $@;
    eval {
        cd $inexistent => sub { }
    };
    if ($@) {
        like $@, qr/Directory '$inexistent' does not exist/;
    }
    else {
        fail;
    }
};

subtest 'cd to temporary dir' => sub {
    my $temp_dir      = File::Temp->newdir;
    my $temp_dir_name = Cwd::realpath($temp_dir->dirname);

    cd $temp_dir => sub {
        is $temp_dir_name, Cwd::cwd();
    };
};

subtest 'invoke some functions inside the coderef' => sub {
    my $orig_dir   = Cwd::realpath(curdir);
    my $inside_dir = Cwd::realpath("$FindBin::Bin/../");

    cd $inside_dir => sub {
        go_up_one_level;
        go_up_two_level;
        local $@;
        eval { sub_that_dies };
        note 'Ignoring error' if $@;
        go_up_one_level;
    };
    is $orig_dir, Cwd::cwd(), 'go back to original directory';
};

subtest 'return value in scalar context' => sub {
    my $expected_files = [qw(bar baz foo quu quux)];
    my $files = cd $TEST_DIR => sub {
        [ glob '*' ];
    };

    is_deeply $files, $expected_files;

    my $files_hashref = cd $TEST_DIR => sub {
        my %f = map { $_ => catfile($TEST_DIR, $_) } glob '*';
        \%f;
    };

    is_deeply $files_hashref,
      { map { $_ => catfile($TEST_DIR, $_) } @$expected_files }

};

subtest 'return value in list context' => sub {
    my $expected_files = [qw(bar baz foo quu quux)];

    my @files = cd $TEST_DIR => sub {
        glob '*';
    };

    is_deeply \@files, [qw(bar baz foo quu quux)];

    my %files_hash = cd $TEST_DIR => sub {
        map { $_ => catfile($TEST_DIR, $_) } glob '*';
    };

    is_deeply \%files_hash,
      { map { $_ => catfile($TEST_DIR, $_) } @$expected_files };
};

subtest 'nested cds' => sub {
    my $one_level_up = Cwd::realpath(updir);
    my $two_level_up = Cwd::realpath(catfile(updir, updir));

    cd updir() => sub {
        is Cwd::cwd, $one_level_up;

        cd updir() => sub {
            is Cwd::cwd, $two_level_up;

            cd $FindBin::Bin => sub {
                is Cwd::cwd(), $FindBin::Bin;
            };
        };
    };
};

cleanup();
done_testing();
