use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;
use Test::Mock::Guard;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub get_file_coverage {
    Devel::Cover::Report::Codecov::get_file_coverage(@_);
}

subtest basic => sub {
    my $guard = mock_guard(
        'Devel::Cover::Report::Codecov',
        {
            get_file_lines    => sub {
                my $file = shift;
                is $file, 'lib/Test/File.pm';
                return 3;
            },
            get_line_coverage => sub {
                my ($statement, $branch) = @_;
                is $branch, undef;
                return $statement;
            },
        });

    my $db     = Test::MockObject->new;
    my $cover  = Test::MockObject->new;
    my $file   = Test::MockObject->new;
    my $stmt   = Test::MockObject->new;
    my $branch = Test::MockObject->new;

    $db->mock(cover => sub { $cover });
    $cover->mock(file => sub { $file });
    $file->mock(statement => sub { $stmt });
    $file->mock(branch => sub { $branch });
    $stmt->mock(location => sub {
        my (undef, $n) = @_;
        return [ undef, 0, undef, 5 ]->[$n];
    });
    $branch->mock(location => sub { undef });

    cmp_deeply
        { get_file_coverage('lib/Test/File.pm', $db) },
        { 'lib/Test/File.pm' => [ undef, 0, undef, 5 ] };

    is $guard->call_count('Devel::Cover::Report::Codecov', 'get_file_lines'), 1;
    is $guard->call_count('Devel::Cover::Report::Codecov', 'get_line_coverage'), 3;

    ok $db->called('cover');
    ok $cover->called('file');
    ok $file->called('statement');
    ok $file->called('branch');
    ok $stmt->called('location');
    ok $branch->called('location');
};

done_testing;
