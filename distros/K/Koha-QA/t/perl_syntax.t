use Modern::Perl;

use Test::More tests => 7;
use Test::NoWarnings;
use File::Temp qw(tempfile);
use Koha::QA::PerlSyntax;

my $expected_messages = {};

sub check_syntax {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::PerlSyntax->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'Valid Perl code in content' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
use strict;
use warnings;
my $x = 1;
print "hello\n";
INPUT

    my @errors = check_syntax($input);
    is( scalar @errors, 0, 'Valid Perl code should have no errors' );
};

subtest 'Valid Perl code in file' => sub {
    plan tests => 1;

    my ( $fh, $filename ) = tempfile( UNLINK => 0, TEMPDIR => 1, SUFFIX => '.pl' );
    print $fh <<'INPUT';
use strict;
use warnings;
my $x = 1;
print "hello\n";
INPUT
    close $fh;

    my $checker  = Koha::QA::PerlSyntax->new( { file => $filename } );
    my $is_valid = $checker->check();
    my @errors   = $checker->errors();

    is( $is_valid, 1, 'Valid file should pass syntax check' );

    unlink $filename;
};

subtest 'Syntax error - missing semicolon' => sub {
    plan tests => 5;
    my $input = <<'INPUT';
use strict;
use warnings;
my $x = 1
print "hello";
my @array = (1, 2, 3;
INPUT

    my @errors = check_syntax($input);
    is( scalar @errors,      1 );
    is( $errors[0]->{error}, 'perl_syntax_compil_error' );
    like( $errors[0]->{message}, qr{^syntax error at \S+ line 4, near "print"$} );
    is( $errors[0]->{line_number}, '4' );
    is( $errors[0]->{line},        'print "hello";' );
};

subtest 'Syntax error - Variable not defined' => sub {
    plan tests => 5;
    my $input = <<'INPUT';
use strict;
print "$foo";
INPUT

    my @errors = check_syntax($input);
    is( scalar @errors,      1 );
    is( $errors[0]->{error}, 'perl_syntax_compil_error' );
    like(
        $errors[0]->{message},
        qr{^Global symbol "\$foo" requires explicit package name \(did you forget to declare "my \$foo"\?\) at \S+ line 2\.$}
    );
    is( $errors[0]->{line_number}, '2' );
    is( $errors[0]->{line},        'print "$foo";' );
};

subtest 'Compilation aborted - Missing deps' => sub {
    plan tests => 3;
    my $input = <<'INPUT';
use Foo::Bar;
print "foo";
INPUT

    my @errors = check_syntax($input);
    is( scalar @errors,      1 );
    is( $errors[0]->{error}, 'perl_syntax_compil_aborted' );
    like(
        $errors[0]->{message},
        qr{^Can't locate Foo\/Bar.pm in \@INC}
    );
};

subtest 'Exceptions' => sub {
    plan tests => 2;

    my $input = <<'INPUT';
use strict;
use warnings;
my $test = 'content';
use constant FOO => 1;
use constant FOO => 2;
INPUT

    subtest 'No exception passed, should fail' => sub {
        plan tests => 5;
        my @errors = check_syntax($input);
        is( scalar @errors, 1, '"Constant subroutine redefined" error should fail syntax check' );
        is( $errors[0]->{error}, 'perl_syntax_warning' );
        like(
            $errors[0]->{message},
            qr{^Constant subroutine main::FOO redefined at /usr/\S+ line \d+.$}
        );
        is( $errors[0]->{line_number}, undef );
        is( $errors[0]->{line},        undef );
    };

    subtest 'No exception passed, should fail' => sub {
        plan tests => 1;
        my @errors = check_syntax( $input, { exceptions => [q{^Constant subroutine .* redefined}] } );
        is( scalar @errors, 0, '"Constant subroutine redefined" error should be ignored and should pass syntax check' );
    };
};
