# -*- perl -*-
# t/001-opts.t
use 5.14.0;
use warnings;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More;
use Capture::Tiny qw( capture_stdout );
use File::Spec;

my $ptg = File::Spec->catfile('', qw| path to gitdir |);
my $pttf = File::Spec->catfile('', qw| path to test file |);

{
    local $@;
    eval { process_options('verbose'); };
    like($@, qr/Must provide even list of key-value pairs to process_options\(\)/,
        "Got expected error message: odd number of arguments to proces_options()"
    );
}

{
    local $@;
    eval { process_options('targets' => 't/phony.t'); };
    like($@, qr/Value of 'targets' must be an array reference/,
        "Got expected error message: 'targets' takes array ref"
    );
}

{
    local $@;
    eval {
        process_options(
            last_before => '12345ab',
            first => '67890ab',
        );
    };
    like($@, qr/Must define only one of 'last_before' and 'first'/,
        "Got expected error message: Provide only one of 'last_before' and 'first'"
    );
}

{
    local $@;
    eval { process_options(); };
    like($@, qr/Must define one of 'last_before' and 'first'/,
        "Got expected error message: Provide one of 'last_before' and 'first'"
    );
}

{
    local $@;
    eval {
        process_options(
            last_before => '12345ab',
            # gitdir => $ptg,
            targets => [ $pttf ],
            last => '67890ab',
        );
    };
    like($@, qr/Undefined parameter: gitdir/,
        "Got expected error message: Lack 'gitdir'"
    );
}

{
    local $@;
    eval {
        process_options(
            last_before => '12345ab',
            gitdir => $ptg,
            targets => [ $pttf ],
            # last => '67890ab',
        );
    };
    like($@, qr/Undefined parameter: last/,
        "Got expected error message: Lack 'last'"
    );
}

my %params_expected = ();
my %these_params_expected = ();
my (%args, $params);

# Below is the smallest set of elements we must provide in %args
# Could substitute 'first' for 'last_before'
%args = (
    last_before => '12345ab',
    gitdir => $ptg,
    last => '67890ab',
);
%params_expected = map { $_ => 1 } ( qw|
  branch
  configure_command
  gitdir
  last
  last_before
  make_command
  outputdir
  probe
  repository
  short
  test_command
  verbose
|);

$params = process_options(%args);
ok($params, "process_options() returned true value");
ok(ref($params) eq 'HASH', "process_options() returned hash reference");
for my $k (sort keys %params_expected) {
    ok(defined($params->{$k}), "A value has been defined for $k: $params->{$k}");
}
is(scalar keys %$params, scalar keys %params_expected,
    "Got expected number of parameters with defined value");
%these_params_expected = map { $_ => 1 } grep { ! exists $args{$_} } keys %params_expected;
for my $k (sort keys %these_params_expected) {
    ok(defined($params->{$k}), "A default value was assigned to $k: $params->{$k}");
}
is(scalar keys %$params, (scalar keys %these_params_expected) + (scalar keys %args),
    "Got expected number of parameters assigned from default values");

%args = (
    last_before => '12345ab',
    gitdir => $ptg,
    targets => [ $pttf ],
    last => '67890ab',
);
$params_expected{targets} = 1;
$params = process_options(%args);
ok($params, "process_options() returned true value");
ok(ref($params) eq 'HASH', "process_options() returned hash reference");
for my $k (sort keys %params_expected) {
    ok(defined($params->{$k}), "A value has been defined for $k: $params->{$k}");
}
is(scalar keys %$params, scalar keys %params_expected,
    "Got expected number of parameters with defined value");
%these_params_expected = map { $_ => 1 } grep { ! exists $args{$_} } keys %params_expected;
for my $k (sort keys %these_params_expected) {
    ok(defined($params->{$k}), "A default value was assigned to $k: $params->{$k}");
}
is(scalar keys %$params, (scalar keys %these_params_expected) + (scalar keys %args),
    "Got expected number of parameters assigned from default values");

$args{verbose} = 1;
my ($stdout, @result);
($stdout, @result) = capture_stdout {process_options(%args);};
like($stdout, qr/Arguments provided to process_options\(\):/s,
    "Got expected verbose output with 'verbose' in arguments to process_options()");
my $fmake = '';
($fmake) = $stdout =~ m/For 'make', %Config has:\s(.*)\Z/s;
chomp($fmake);
ok($fmake, "Perl 5 \%Config identified '$fmake' for 'make'");
$args{verbose} = undef;

my @cl_opts = (
    "--verbose",
    "--last_before" => '12345ab',
    "--gitdir" => $ptg,
    "--last" => '67890ab',
);
{
    local @ARGV = (@cl_opts);
    ($stdout, @result) = capture_stdout {process_options(%args);};
    like($stdout, qr/Command-line arguments:/s,
        "Got expected verbose output with 'verbose' on command-line");
}

done_testing();

