use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub get_line_coverage {
    Devel::Cover::Report::Codecov::get_line_coverage(@_);
}

subtest 'if false' => sub {
    is get_line_coverage(undef, undef), undef;
};

subtest statement => sub {
    subtest 'if uncoverable' => sub {
        my $statement = Test::MockObject->new;
        $statement->mock(uncoverable => sub { 1 });
        $statement->mock(covered => sub { 0 });

        is get_line_coverage([ $statement ]), undef;
    };

    subtest 'if covered' => sub {
        my $statement = Test::MockObject->new;
        $statement->mock(uncoverable => sub { 0 });
        $statement->mock(covered => sub { 1024 });

        is get_line_coverage([ $statement ]), 1024;
    };
};

subtest branch => sub {
    my $statement = Test::MockObject->new;
    $statement->mock(uncoverable => sub { 0 });
    $statement->mock(covered => sub { 8 });

    my $branch = Test::MockObject->new;
    $branch->mock(covered => sub { 5 });
    $branch->mock(total => sub { 10 });

    is get_line_coverage([ $statement ], [ $branch ]), '5/10';
};

done_testing;
