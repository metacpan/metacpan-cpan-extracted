use strict;
use warnings;
use Test::More 0.96;

my $user = $ENV{GOOGLECODE_USER};
my $pass = $ENV{GOOGLECODE_PASS};
my $proj = $ENV{GOOGLECODE_PROJECT};

plan skip_all => 'Set GOOGLECODE_PASS, GOOGLECODE_USER, and GOOGLECODE_PROJECT to run this test'
        unless $user and $pass and $proj;
plan tests => 2;

subtest old => sub {
    plan tests => 1;

    require Google::Code::Upload;
    Google::Code::Upload->import('upload');

    my $url = eval { upload('t/testfile.1', $proj, $user, $pass, 'TEST', [ 'Test', 'Deprecated']) };
    ok !$@ or diag $@;
    diag $url;
};

subtest new => sub {
    plan tests => 3;

    require Google::Code::Upload;
    my $gc = new_ok('Google::Code::Upload' => [username => $user, password => $pass, project => $proj]);
    can_ok $gc, qw(upload);

    my $url = eval { $gc->upload(
        file        => 't/testfile.2',
        summary     => 'summary',
        labels      => ['Test', 'Deprecated'],
        description => 'desc'
    )};
    ok !$@ or diag $@;
    diag $url;
};
