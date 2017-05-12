# !perl
use strict;
use warnings;
use Test::More tests => 39;
use Git::Reduce::Tests::Opts qw(process_options);
use Cwd;

my $params = {};
my @include_opts = ("--include", "t/001-load.t"); 
my @include_args = ("include", "t/001-load.t"); 

{
    local @ARGV = (@include_opts);
    $params = process_options();
    for my $o ( qw|
        dir
        branch
        prefix
        remote
        no_delete
        no_push
        verbose
        test_extension
        | ) {
        ok(defined $params->{$o}, "'$o' option defined");
    }
    ok(  length($params->{include}), "'include' option populated");
    ok(! length($params->{exclude}), "'exclude' option not populated");
}

{
    my $branch = 'develop';
    my $prefix = 'smoke-me/';
    my $suffix = '_smoke-me';
    my $remote = 'upstream';
    my $no_delete = 1;
    my $no_push = 1;
    my $test_extension = 'test';
    local @ARGV = (
        @include_opts,
        '--branch' => $branch,
        '--prefix' => $prefix,
        '--remote' => $remote,
        '--no_delete' => $no_delete,
        '--no_push' => $no_push,
        '--test_extension' => $test_extension,
    );
    $params = process_options();
    is($params->{branch}, $branch, "Got explicitly set branch");
    is($params->{prefix}, $prefix, "Got explicitly set prefix");
    is($params->{remote}, $remote, "Got explicitly set remote");
    is($params->{no_delete}, $no_delete, "Got explicitly set no_delete");
    is($params->{no_push}, $no_push, "Got explicitly set no_push");
    is($params->{test_extension}, $test_extension, "Got explicitly set test_extension");
    ok(! $params->{suffix}, "Because 'prefix' is set, 'suffix' is not");
}

{
    my $no_delete = 1;
    my $no_push = 1;
    my $test_extension = 'test';
    my $suffix = '_my_suffix';
    local @ARGV = (
        @include_opts,
        '--no-delete' => $no_delete,
        '--no-push' => $no_push,
        '--test-extension' => $test_extension,
        '--suffix' => $suffix,
    );
    $params = process_options();
    is($params->{no_delete}, $no_delete, "Got explicitly set no-delete");
    is($params->{no_push}, $no_push, "Got explicitly set no-push");
    is($params->{test_extension}, $test_extension, "Got explicitly set test-extension");
    is($params->{suffix}, $suffix, "Got explicitly set suffix");
    ok(! $params->{prefix}, "Because 'suffix' is set, 'prefix' is not");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir, "verbose", @include_opts);
    local $@;
    eval { $params = process_options(); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided on command-line");
}

{
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local $@;
    eval { $params = process_options("dir" => $phony_dir, @include_args); };
    like($@, qr/Could not locate directory $phony_dir/,
        "Die on non-existent directory $phony_dir provided to process_options()");
}

{
    my $cwd = cwd();
    my $phony_dir = "/tmp/abcdefghijklmnop_foobar";
    local @ARGV = ("--dir", $phony_dir, @include_opts);
    $params = process_options("dir" => $cwd);
    is($params->{dir}, $cwd,
        "Argument provided directly to process_options supersedes command-line argument");
}

{
    my $include = "t/001-load.t";
    my $exclude = "t/999-load.t";
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude'   => $exclude,
    ); };
    like($@,
        qr/'include' and 'exclude' options are mutually exclusive; choose one or the other/,
        "Die on provision of both 'include' and 'exclude' options"
    );
}

{
    my $prefix = "my_prefix_";
    my $suffix = "_my_suffix";
    local $@;
    eval { $params = process_options(
        'prefix'   => $prefix,
        'suffix'   => $suffix,
    ); };
    like($@,
        qr/Only one of 'prefix' or 'suffix' may be supplied/,
        "Die on provision of both 'prefix' and 'suffix' arguments"
    );
}

{
    my $prefix = "my_prefix_";
    my $suffix = "_my_suffix";
    local $@;
    local @ARGV = ('--prefix' => $prefix, '--suffix' => $suffix, @include_opts);
    eval { $params = process_options(); };
    like($@,
        qr/Only one of '--prefix' or '--suffix' may be supplied/,
        "Die on provision of both 'prefix' and 'suffix' options"
    );
}

SKIP: {
    my ($stdout);
    eval { require IO::CaptureOutput; };
    skip "IO::CaptureOutput not installed", 1 if $@;
    local @ARGV = (@include_opts);
    IO::CaptureOutput::capture(
        sub { $params = process_options( "verbose" => 1 ); },
        \$stdout,
    );
    like($stdout, qr/'verbose'\s*=>\s*1/s,
        "Got expected verbose output: arguments to process_options()");
}

SKIP: {
    my ($stdout);
    eval { require IO::CaptureOutput; };
    skip "IO::CaptureOutput not installed", 1 if $@;
    local @ARGV = ("--verbose", @include_opts);
    IO::CaptureOutput::capture(
        sub { $params = process_options(); },
        \$stdout,
    );
    like($stdout, qr/'verbose'\s*=>\s*1/s,
        "Got expected verbose output: command-line argument");
}

{
    my $include = "t/001-load.t";
    my $exclude = "t/999-load.t";
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude',
    ); };
    like($@,
        qr/Must provide even list of key-value pairs to process_options/,
        "Die on odd number of arguments to process_options()"
    );
    $@ = undef;

    $params = process_options( 'include'   => $include );
    is($params->{include}, $include, "Got expected include");
    $params = undef;

    $params = process_options( 'exclude' => $exclude );
    is($params->{exclude}, $exclude, "Got expected exclude");
    ok(! $params->{include}, "Because 'exclude' is set, 'include' is not");
    $params = undef;

    my $prefix = 'my_prefix_';
    $params = process_options( 'prefix' => $prefix, 'include' => $include );
    is($params->{prefix}, $prefix, "Got expected prefix");
    ok(! $params->{suffix}, "Because 'prefix' is set, 'suffix' is not");
    $params = undef;

    my $suffix = '_my_suffix';
    $params = process_options( 'suffix' => $suffix, 'include' => $include );
    is($params->{suffix}, $suffix, "Got expected suffix");
    ok(! $params->{prefix}, "Because 'suffix' is set, 'prefix' is not");
    $params = undef;

    $include = '';
    $exclude = '';
    local $@;
    eval { $params = process_options(
        'include'   => $include,
        'exclude'   => $exclude,
    ); };
    like($@,
        qr/Must populate one of 'include' or 'exclude' with test files/,
        "Die on failure to populate one of 'include' or 'exclude'",
    );
}

