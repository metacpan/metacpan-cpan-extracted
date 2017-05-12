
use strict;
use warnings;
use lib 't/lib';
use Test::More;

eval 'use Moo; 1' or plan skip_all => 'Test requires Moo';

subtest 'apply roles via subref' => sub {
    my $warn;
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    eval q{
        package usecase::applyrole;
        use UseCase::Moo::ApplyRole 'Class', 'Plugin';
    };
    delete $SIG{__WARN__};

    ok !$@, 'lived' or diag $@;
    ok !$warn, 'no warnings' or diag $warn;
    ok usecase::applyrole->DOES( 'UseCase::Moo::ApplyRole::Role' ), 'role was applied';
};

subtest 'role requires attribute to exist' => sub {
    subtest 'cannot apply role at compile time' => sub {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };
        eval q{
            package usecase::rolewithrequires;
            use UseCase::Moo::ApplyRole 'Class', 'WithRequires';
            has my_attr => ( is => 'ro' );
        };
        delete $SIG{__WARN__};

        like $@, qr/Can't apply UseCase::Moo::ApplyRole::WithRequires/;
    };

    my $warn;
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    eval q{
        package usecase::rolewithrequires;
        use UseCase::Moo::ApplyRole 'Class';
        has my_attr => ( is => 'ro' );
        UseCase::Moo::ApplyRole->import_bundle( 'WithRequires' );
    };
    delete $SIG{__WARN__};

    ok !$@, 'lived' or diag $@;
    ok !$warn, 'no warnings' or diag $warn;
    ok usecase::applyrole->DOES( 'UseCase::Moo::ApplyRole::Role' ), 'role was applied';
};

done_testing;

