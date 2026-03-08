#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Carp qw( croak );
use Cwd  qw( getcwd );
use English '-no_match_vars';
use FindBin    qw( $RealBin );
use File::Spec ();
my $lib_path;

BEGIN {
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], q{.}, q{..}, 'lib' );
}
use lib "$lib_path";

use Test2::V0;
use Test2::Tools::GenTemp qw( gen_temp );
use Test2::Deny::Platform::DOSOrDerivative;
use Test::Script 1.28;

use Data::Dumper;

{

    package Env::Dot::Test::ChdirGuard;
    use Carp qw( croak );
    use English '-no_match_vars';
    sub new { my ( $class, $dir ) = @_; return bless { dir => $dir }, $class; }
    sub DESTROY { my ($self) = @_; chdir $self->{'dir'} or croak "Cannot chdir: $OS_ERROR"; return; }
}

# ##########################
# With .env

subtest '.env is not required by default when present' => sub {
    is( 1, 1 );

    # script_runs(['bin/envdot', '--version', ]);
    # script_runs(['bin/envdot', '--version', ], { interpreter_options => [ '-T' ], }, 'Runs with taint check enabled');
    #
    my $stdout;

    # my $prg = File::Spec->rel2abs(File::Spec->catfile(__FILE__, 'by-default', 'prg.pl'));
    # my $prg = File::Spec->rel2abs(File::Spec->catfile(__FILE__, 'by-default', 'prg.pl'));
    my $prg      = 'prg.pl';
    my $test_dir = File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'by-default' ) );

    # diag 'test_dir: ' . getcwd;
    # diag 'cwd: ' . getcwd;
    # diag "prg: $prg";
    # my $orgdir = getcwd;
    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";
    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );

    # diag "stdout: $stdout";
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s 123 [.] 456 $/msx,                'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx,                            'Correct stdout' );

    # like( $stdout, qr{^FOO: \s foo-var-with-no-whitespace
    #     BAR: \s 123\.456
    #     BAZ: \s \n$}msx, 'Correct stdout');

    done_testing;
};

subtest '.env is specifically not required when present' => sub {
    my $stdout;
    my $prg      = 'prg.pl';
    my $test_dir = File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'specifically-not-required' ) );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s 123 [.] 456 $/msx,                'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx,                            'Correct stdout' );

    done_testing;
};

subtest '.env is specifically required when present' => sub {
    my $stdout;
    my $prg      = 'prg.pl';
    my $test_dir = File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'specifically-required' ) );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s 123 [.] 456 $/msx,                'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx,                            'Correct stdout' );

    done_testing;
};

# ##########################
# No .env

subtest '.env is not required by default when present' => sub {
    my $stdout;
    my $prg      = 'prg.pl';
    my $test_dir = File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'by-default-no-envdot-present' ) );
    my $o        = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";
    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx, 'Correct stdout' );

    # like( $stdout, qr{^FOO: \s foo-var-with-no-whitespace
    #     BAR: \s 123\.456
    #     BAZ: \s \n$}msx, 'Correct stdout');

    done_testing;
};

subtest '.env is specifically not required when present' => sub {
    my $stdout;
    my $prg = 'prg.pl';
    my $test_dir =
      File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'specifically-not-required-no-envdot-present' ) );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx, 'Correct stdout' );

    done_testing;
};

subtest '.env is specifically required when present' => sub {
    my $stdout;
    my $prg      = 'prg.pl';
    my $test_dir = File::Spec->rel2abs( File::Spec->catdir( 't', 'required-dotenv', 'specifically-required-no-envdot-present' ) );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_fails( [ $prg, ], { stdout => \$stdout, exit => 2, }, 'Verify failure' );

    # diag "stdout: $stdout";
    # script_runs([ $prg, ], { stdout => \$stdout, }, 'Verify output');
    # like( (split qr/\n/msx, $stdout)[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'Correct stdout');
    # like( (split qr/\n/msx, $stdout)[1], qr/^ BAR: \s 123 [.] 456 $/msx, 'Correct stdout');
    # like( (split qr/\n/msx, $stdout)[2], qr/^ BAZ: \s $/msx, 'Correct stdout');

    done_testing;
};

done_testing;
