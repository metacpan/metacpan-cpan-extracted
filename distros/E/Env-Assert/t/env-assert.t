#!perl
## no critic [BuiltinFunctions::ProhibitStringyEval]
use strict;
use warnings;

use Cwd        qw( getcwd abs_path );
use File::Spec ();

use Test2::V1 qw( -utf8 -x -strict -warnings ), -include => ['Data::Dumper'];
use Test2::Tools::Subtest qw( subtest_streamed );

use Carp       qw( croak );
use English    qw( -no_match_vars );    # Avoids regex performance
use FileHandle ();
use File::Path qw( make_path );
use File::Temp ();

# use Test2::Require::Platform::Unix;

sub create_test_file {
    my ( $dirs, $fn, $content ) = @_;
    my $dir = File::Temp->newdir(
        TEMPLATE => 'temp-envassert-test-XXXXX',
        CLEANUP  => 1,
        DIR      => File::Spec->tmpdir,
    );
    my $dir_path = abs_path( $dir->dirname );
    make_path( File::Spec->catdir( $dir_path, @{$dirs} ) );

    my $fh = FileHandle->new( File::Spec->catfile( $dir_path, @{$dirs}, $fn ), 'w' );
    print {$fh} $content || croak;
    $fh->close;

    return $dir, $dir_path;
}

subtest_streamed 'Use Env::Assert plain without import arguments' => sub {
    my $content = <<'EOF';
# shellcheck disable=SC2034,SC2125

# Simply assert the var exists
ALERT_EMAIL=^.*$

# Looks like a domain address
SITE_URL=^https

# POSIX regular expressions supported
GITHUB_TOKEN=^[[:word:]]{1,}$
EOF

    my ( $temp_dir, $dir_path ) = create_test_file( [], q{.envdesc}, $content );

    # Do not use __FILE__ because its value is not absolute and not updated
    # when chdir is done.
    my $this = getcwd;
    ($this) = $this =~ /(.+)/msx;    # Make it non-tainted
    my $subdir_path = File::Spec->catdir($dir_path);
    T2->diag( 'Change to ' . $subdir_path );
    chdir $subdir_path || croak;

    my %new_env = (
        ALERT_EMAIL  => 'alert@example.com',
        SITE_URL     => 'https://www.example.com',
        GITHUB_TOKEN => '0123456789qwertyuiop',
    );

    # We need to replace the current %ENV, not change individual values.
    local %ENV        = %new_env;
    local $EVAL_ERROR = undef;
    my $code = <<'EOF';
use Env::Assert;
1;
EOF
    my $r = eval $code;
    T2->is( $EVAL_ERROR, q{}, 'use Env::Assert okay' );
    T2->is( $r,          1,   'evaled okay' );

    chdir $this;

    T2->done_testing;
};

subtest_streamed 'Wrong import argument' => sub {

    my %new_env = (
        ALERT_EMAIL  => 'alert@example.com',
        SITE_URL     => 'https://www.example.com',
        GITHUB_TOKEN => '0123456789qwertyuiop',
    );

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $code = <<'EOF';
use Env::Assert qw(not_assert);
1;
EOF
    my $r = eval $code;
    T2->match( $EVAL_ERROR, qr/^Unknown \s argument \s 'not_assert' .*$/msx, 'use Env::Assert failed' );
    T2->is( $r, undef, 'evaled okay' );

    # T2->is($EVAL_ERROR, q{}, 'use Env::Dot failed' );

    T2->done_testing;
};

subtest_streamed 'Inline env desc file' => sub {
    my %new_env = (
        NUMVAR  => '12345',
        TEXTVAR => 'example_text',
    );

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $code = <<'EOF';
use Env::Assert assert => {
    envdesc => q{
NUMVAR=^\d+$
TEXTVAR=^\w+$
},
};
1;
EOF
    my $r = eval $code;
    T2->is( $EVAL_ERROR, q{}, 'use Env::Assert okay' );
    T2->is( $r,          1,   'evaled okay' );

    # like($EVAL_ERROR, qr/^Unknown \s argument \s 'not_assert' .*$/msx, 'use Env::Assert failed' );
    # T2->is( $r, undef, 'evaled okay');
    # T2->is($EVAL_ERROR, q{}, 'use Env::Dot failed' );

    T2->done_testing;
};

=for comment

subtest_streamed 'Point to another env desc file' => sub {
    my $content = <<'EOF';
# shellcheck disable=SC2034,SC2125

A_NUMVAR=^[[:digit:]]+$
A_TEXTVAR=^[[:word:]]+$
EOF
    my ( $temp_dir, $subdir_filepath ) = create_test_file( [], q{.envdesc}, $content );

    my %new_env = (
        A_NUMVAR  => '12345',
        A_TEXTVAR => 'example_text',
    );

    # We need to replace the current %ENV, not change individual values.
    local %ENV = %new_env;

    local $EVAL_ERROR = undef;
    my $code = <<"EOF";
use Env::Assert assert => {
    envdesc_file => '$subdir_filepath' . q{/} . q{.envdesc},
};
1;
EOF
    local $EVAL_ERROR = undef;
    my $r = eval $code;
    T2->is( $EVAL_ERROR, q{}, 'use Env::Assert successful' );
    T2->is( $r,          1,   'evaled okay' );

    T2->done_testing;
};

=cut

T2->done_testing;
