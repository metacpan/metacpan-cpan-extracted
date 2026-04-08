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
    $lib_path = File::Spec->catdir( ( $RealBin =~ /(.+)/msx )[0], 'lib' );
}
use lib "$lib_path";

use Test2::V0;
use Test2::Deny::Platform::DOSOrDerivative;
use Test::Script 1.28;

# use Data::Dumper;

{

    package Env::Dot::Test::ChdirGuard;
    use Carp qw( croak );
    use English '-no_match_vars';
    sub new { my ( $class, $dir ) = @_; return bless { dir => $dir }, $class; }
    sub DESTROY { my ($self) = @_; chdir $self->{'dir'} or croak "Cannot chdir: $OS_ERROR"; return; }
}

sub make_content {
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

sub make_dotenv {
    my $content = <<'EOF';
# shellcheck disable=SC2034
FOO=foo-var-with-no-whitespace
BAR=123.456
BAZ=
EOF

    # $content =~ s/\<args>/$args/msx;
    return $content;
}

sub make_tempdir {
    use File::Temp ();
    my $dir = File::Temp->newdir( CLEANUP => 1 );
    return $dir;
}

sub make_script_file {
    my ( $dir, $fp, $content ) = @_;
    my $full_fp = File::Spec->catfile( $dir, $fp );
    open my $fh, '>:encoding(UTF-8)', $full_fp or croak "Cannot open($full_fp): $OS_ERROR";
    print {$fh} $content or croak "Cannot print: $OS_ERROR";
    close $fh            or croak "Cannot close: $OS_ERROR";
    chmod 0755, $full_fp or croak "Cannot chmod: $OS_ERROR";    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return $full_fp;
}

sub make_dotenv_file {
    my ( $dir, $content ) = @_;
    my $full_fp = File::Spec->catfile( $dir, '.env' );
    open my $fh, '>:encoding(UTF-8)', $full_fp or croak "Cannot open($full_fp): $OS_ERROR";
    print {$fh} $content or croak "Cannot print: $OS_ERROR";
    close $fh            or croak "Cannot close: $OS_ERROR";

    # chmod 0755, $full_fp or croak "Cannot chmod: $OS_ERROR"; ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    return $full_fp;
}

subtest 'Test testing method make_tempdir' => sub {
    my $tmp_dir_path;
    {
        my $tmp_dir = make_tempdir();

        # diag 'Created temp dir: ' . $tmp_dir;
        ok( -d $tmp_dir, 'Temp dir is created' );
        $tmp_dir_path = q{} . $tmp_dir;
    }

    ok( !-d $tmp_dir_path, 'Temp dir is deleted' );

    done_testing;
};

subtest 'Test testing methods make_tempdir and make_script_file' => sub {
    my $prg     = 'prg.pl';
    my $content = <<'EOF';
#!/usr/bin/env perl
## no critic (InputOutput::RequireCheckedSyscalls)
use strict; use warnings; use utf8; use 5.010;
say 'USER: ' . ($ENV{USER}//q{<null>});
EOF

    my $tmp_dir = make_tempdir();

    # diag 'Created temp dir: ' . $tmp_dir;

    my $prg_fp = make_script_file( $tmp_dir, $prg, $content );
    ok( -f $prg_fp, 'Prg file exists' );
    ok( -x $prg_fp, 'Prg file is executable' );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $tmp_dir or croak "Cannot chdir: $OS_ERROR";

    my $stdout;
    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ USER: \s .+ $/msx, 'Correct stdout' );

    done_testing;
};

# ##########################
# With .env

subtest '.env is not required by default (but is used) when present' => sub {
    my $stdout;
    my $prg = 'prg.pl';

    # my $test_dir = File::Spec->rel2abs(File::Spec->catdir('t', 'required-dotenv', 'by-default'));
    my $content  = make_content(q{});
    my $dotenv   = make_dotenv();
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp    = make_script_file( $test_dir, $prg, $content );
    my $dotenv_fp = make_dotenv_file( $test_dir, $dotenv );
    my $o         = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";
    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s foo-var-with-no-whitespace $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s 123 [.] 456 $/msx,                'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx,                            'Correct stdout' );

    done_testing;
};

subtest '.env is specifically not required when present' => sub {
    my $stdout;
    my $prg = 'prg.pl';

    # my $test_dir = File::Spec->rel2abs(File::Spec->catdir('t', 'required-dotenv', 'specifically-not-required'));
    my $content  = make_content(' read => { required => 0 }');
    my $dotenv   = make_dotenv();
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp    = make_script_file( $test_dir, $prg, $content );
    my $dotenv_fp = make_dotenv_file( $test_dir, $dotenv );

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
    my $prg = 'prg.pl';

    # my $test_dir = File::Spec->rel2abs(File::Spec->catdir('t', 'required-dotenv', 'specifically-required'));
    my $content  = make_content(' read => { required => 1 }');
    my $dotenv   = make_dotenv();
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp    = make_script_file( $test_dir, $prg, $content );
    my $dotenv_fp = make_dotenv_file( $test_dir, $dotenv );

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

subtest '.env is not required by default when not present' => sub {
    my $stdout;
    my $prg = 'prg.pl';

    # my $test_dir = File::Spec->rel2abs(File::Spec->catdir('t', 'required-dotenv', 'by-default-no-envdot-present'));
    my $content  = make_content(q{});
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp = make_script_file( $test_dir, $prg, $content );
    my $o      = Env::Dot::Test::ChdirGuard->new(getcwd);
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

subtest '.env is specifically not required when not present' => sub {
    my $stdout;
    my $prg = 'prg.pl';

    # my $test_dir = File::Spec->rel2abs(File::Spec->catdir('t', 'required-dotenv', 'specifically-not-required-no-envdot-present'));
    my $content  = make_content(' read => { required => 0 }');
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp = make_script_file( $test_dir, $prg, $content );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_runs( [ $prg, ], { stdout => \$stdout, }, 'Verify output' );
    like( ( split qr/\n/msx, $stdout )[0], qr/^ FOO: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[1], qr/^ BAR: \s $/msx, 'Correct stdout' );
    like( ( split qr/\n/msx, $stdout )[2], qr/^ BAZ: \s $/msx, 'Correct stdout' );

    done_testing;
};

subtest '.env is specifically required when not present' => sub {
    my $stdout;
    my $prg      = 'prg.pl';
    my $content  = make_content(' read => { required => 1 }');
    my $test_dir = make_tempdir();

    # diag $test_dir;
    my $prg_fp = make_script_file( $test_dir, $prg, $content );

    my $o = Env::Dot::Test::ChdirGuard->new(getcwd);
    chdir $test_dir or croak "Cannot chdir: $OS_ERROR";

    script_fails( [ $prg, ], { stdout => \$stdout, exit => 2, }, 'Verify failure' );

    done_testing;
};

done_testing;
