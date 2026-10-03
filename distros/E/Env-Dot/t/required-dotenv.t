#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Carp qw( croak );
use Cwd qw( getcwd );
use English '-no_match_vars';
use FindBin qw( $RealBin );
use File::Spec ();

use Test2::V1 qw( -utf8 );
use Test2::Tools::Subtest qw( subtest_streamed );
use Test2::Tools::GenTemp qw( gen_temp );
use Test::Script 1.28;

my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], 'lib');
}
use lib "$lib_path";

use Test2::Deny::Platform::DOSOrDerivative;
require Env::Dot::Test::ChdirGuard;

# make_script( $import_args )
#
# Return the source of a tiny Perl script that does `use Env::Dot <args>;`
# and then prints the FOO/BAR/BAZ environment variables, one per line, in
# the form "NAME: value". $import_args is injected verbatim after
# `Env::Dot` in the use-statement, so pass things like:
#     ''                              # no args  -> use Env::Dot;
#     ' read => { required => 1 }'    # required -> use Env::Dot read => { required => 1 };
sub make_script {
    my ($args) = @_;
    my $content = <<'EOF';
#!perl
## no critic (InputOutput::RequireCheckedSyscalls)
use strict; use warnings; use utf8; use 5.010;
use Env::Dot <args>;
say 'FOO: ' . ($ENV{FOO}//q{});
say 'BAR: ' . ($ENV{BAR}//q{});
say 'BAZ: ' . ($ENV{BAZ}//q{});
EOF
    $content =~ s/\<args>/$args/msx;
    return $content;
}

my $DOTENV = <<'EOF';
# shellcheck disable=SC2034
FOO=foo-var-with-no-whitespace
BAR=123.456
BAZ=
EOF

my $PRG = 'prg.pl';

# enter_test_dir( $dir )
#
# Prepare a gen_temp-created directory for running the test script and
# chdir into it. gen_temp writes plain files without the executable bit,
# so we chmod the script to 0755 first. Returns a ChdirGuard that MUST be
# kept in a lexical by the caller; when it goes out of scope the cwd is
# restored to what it was at the moment of this call.
sub enter_test_dir {
    my ($dir) = @_;
    chmod 0755, File::Spec->catfile($dir, $PRG) or croak "Cannot chmod: $OS_ERROR";
    my $guard = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $dir or croak "Cannot chdir: $OS_ERROR";
    return $guard;
}

# clear_test_env()
#
# Delete FOO, BAR, and BAZ from %ENV so the spawned test script starts
# from a clean slate. Without this, a value inherited from the user's
# shell could mask a bug where Env::Dot fails to set the variable.
sub clear_test_env {
    delete $ENV{$_} for qw( FOO BAR BAZ ); ## no critic (ControlStructures::ProhibitPostfixControls)
    return;
}

# assert_dotenv_loaded( $stdout )
#
# Assert that the test script's stdout shows FOO/BAR/BAZ populated from
# the .env fixture (see $DOTENV). Use this in cases where Env::Dot is
# expected to have successfully read the .env file.
sub assert_dotenv_loaded {
    my ($stdout) = @_;
    my @lines = split qr/\n/msx, $stdout;
    T2->like( $lines[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'FOO loaded from .env');
    T2->like( $lines[1], qr/^ BAR: \s 123 [.] 456 $/msx, 'BAR loaded from .env');
    T2->like( $lines[2], qr/^ BAZ: \s $/msx, 'BAZ loaded from .env (empty value)');
    return;
}

# assert_dotenv_not_loaded( $stdout )
#
# Assert that FOO/BAR/BAZ are all empty in the script's stdout. Use this
# when no .env file is present and Env::Dot is not required, so the vars
# should simply be unset.
sub assert_dotenv_not_loaded {
    my ($stdout) = @_;
    my @lines = split qr/\n/msx, $stdout;
    T2->like( $lines[0], qr/^ FOO: \s $/msx, 'FOO not set (no .env)');
    T2->like( $lines[1], qr/^ BAR: \s $/msx, 'BAR not set (no .env)');
    T2->like( $lines[2], qr/^ BAZ: \s $/msx, 'BAZ not set (no .env)');
    return;
}

# ##########################
# With .env

subtest_streamed '.env is not required by default (but is used) when present' => sub {
    my $dir = gen_temp( $PRG => make_script(q{}), '.env' => $DOTENV );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_runs([ $PRG, ], { stdout => \$stdout, }, 'Verify output');
    assert_dotenv_loaded($stdout);
    T2->done_testing;
};

subtest_streamed '.env is specifically not required when present' => sub {
    my $dir = gen_temp( $PRG => make_script(' read => { required => 0 }'), '.env' => $DOTENV );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_runs([ $PRG, ], { stdout => \$stdout, }, 'Verify output');
    assert_dotenv_loaded($stdout);
    T2->done_testing;
};

subtest_streamed '.env is specifically required when present' => sub {
    my $dir = gen_temp( $PRG => make_script(' read => { required => 1 }'), '.env' => $DOTENV );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_runs([ $PRG, ], { stdout => \$stdout, }, 'Verify output');
    assert_dotenv_loaded($stdout);
    T2->done_testing;
};

# ##########################
# No .env

subtest_streamed '.env is not required by default when not present' => sub {
    my $dir = gen_temp( $PRG => make_script(q{}) );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_runs([ $PRG, ], { stdout => \$stdout, }, 'Verify output');
    assert_dotenv_not_loaded($stdout);
    T2->done_testing;
};

subtest_streamed '.env is specifically not required when not present' => sub {
    my $dir = gen_temp( $PRG => make_script(' read => { required => 0 }') );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_runs([ $PRG, ], { stdout => \$stdout, }, 'Verify output');
    assert_dotenv_not_loaded($stdout);
    T2->done_testing;
};

subtest_streamed '.env is specifically required when not present' => sub {
    my $dir = gen_temp( $PRG => make_script(' read => { required => 1 }') );
    my $guard = enter_test_dir($dir);
    my $stdout;
    clear_test_env();
    script_fails( [ $PRG, ], { stdout => \$stdout, exit => 2, }, 'Verify failure' );
    T2->done_testing;
};

T2->done_testing;
