use Test2::V0;
use Test2::Tools::Subtest qw(subtest_streamed);

# When this test is run with no args, it runs all tests if finds under
# a subdirectory of the name of this test.  You can also run one or more
# tests by putting them on the command line

use Devel::Chitin::OpTree;
use Devel::Chitin::Location;
use IO::File;

my @tests = plan_tests(@ARGV);
plan tests => scalar(@tests);
$_->() foreach @tests;

sub plan_tests {
    if (@_) {
        map { make_specific_test($_) } @_;
    } else {
        make_all_tests();
    }
}

sub make_specific_test {
    my $file = shift;
    return sub { run_one_test( $file ) };
}

sub make_all_tests {
    my($dir) = (__FILE__ =~ m/(.*?)\.t$/);
    my @subdirs = _contents_under_dir($dir);
    map { make_subdir_test($_) } @subdirs;
}

sub make_subdir_test {
    my $subdir = shift;
    sub {
        my @tests = _contents_under_dir($subdir);
        subtest_streamed $subdir => sub {
            plan tests => scalar(@tests);

            run_one_test($_) foreach @tests;
        };
    };
}

sub _contents_under_dir {
    my $dir = shift;
    grep { ! m/^\./ } glob("${dir}/*");
}

my $should_skip;
{ no warnings 'redefine';
  sub skip { $should_skip = shift; die $should_skip }
}

sub run_one_test {
    my $file = shift;

    my $fh = IO::File->new($file) || die "Can't open $file: $!";
    my $test_code = do {
        local $/;
        <$fh>;
    };
    $fh->close;

    (my $subname = $file) =~ s#/|-|\.#_#g;
    my $test_as_sub = sprintf('sub %s { %s }', $subname, $test_code);
    $should_skip = '';
    my $exception = do {
        local $@;
        eval $test_as_sub;
        $@;
    };
    if ($should_skip) {
        return pass("$file skipped: $should_skip");
    } elsif ($exception) {
        die "Couldn't compile code for $file: $exception";
    }

    (my $expected = $test_code) =~ s/\b(?:my|our)\b\s*//mg;
    $expected =~ s/^.*?# omit\n//mg;  # remove lines that don't deparse to anything
    $expected =~ s/\s*(?<!\$)#.*?$//mg;  # remove comments and don't match $#something
    $expected =~ s/^\n//mg; # remove empty lines

    my $ops = _get_optree_for_sub_named($subname);
    local $@;
    my $got = eval { $ops->deparse };
    is("$got\n", $expected, $file)
        || do {
            diag("Showing whitespace:\n>>" . join("<<\n>>", split("\n", $got)) . "<<");
            diag('$@: ' . $@ . "\nTree:\n");
            $ops->print_as_tree;
        };
}

sub _get_optree_for_sub_named {
    my $subname = shift;
    Devel::Chitin::OpTree->build_from_location(
        Devel::Chitin::Location->new(
            package => 'main',
            subroutine => $subname,
            filename => __FILE__,
            line => 1,
        )
    );
}

