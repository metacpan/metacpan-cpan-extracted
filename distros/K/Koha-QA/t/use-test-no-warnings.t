use Modern::Perl;

use Test::More tests => 4;
use Test::NoWarnings;
use File::Temp qw(tempfile);
use Koha::QA::TestNoWarnings;

my $expected_messages = {};

sub check_no_warnings {
    my ( $content, $params ) = @_;
    $params ||= {};
    my $checker = Koha::QA::TestNoWarnings->new( { content => $content, %$params } );
    $checker->check();
    return $checker->errors();
}

subtest 'Test has "use Test::NoWarnings;"' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
use Test::More;
use Test::NoWarnings;
ok(1);
done_testing();
INPUT

    my @errors = check_no_warnings($input);
    is( scalar @errors, 0, 'Tests using Test::NoWarnings have no errors' );
};

subtest 'Test has commented "use Test::NoWarnings;"' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
use Test::More;
#use Test::NoWarnings;
ok(1);
done_testing();
INPUT

    my @errors = check_no_warnings($input);
    is_deeply(
        \@errors,
        [
            {
                message => q{Test file does not use Test::NoWarning},
                error   => q{test_no_warnings},
            }
        ],
        'Tests using Test::NoWarnings but commented have errors'
    );
};

subtest 'Test does not have "use Test::NoWarnings;"' => sub {
    plan tests => 1;
    my $input = <<'INPUT';
use Test::More;
ok(1);
done_testing();
INPUT

    my @errors = check_no_warnings($input);
    is_deeply(
        \@errors,
        [
            {
                message => q{Test file does not use Test::NoWarning},
                error   => q{test_no_warnings},
            }
        ],
        'Tests not using Test::NoWarnings have errors'
    );
};
