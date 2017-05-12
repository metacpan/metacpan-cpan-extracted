use HTTP::Request::Common;
use DocLife;
use Plack::Test;
use Test::More;

my $app = DocLife->new(
    root => 't/doc',
    suffix => '.md'
);

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/Test');
    like $res->content, qr/Test Page/, 'normal';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/Hoge');
    is $res->code, 404, 'not found.';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/../Test');
    is $res->code, 403, 'forbidden.';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/Test2..');
    like $res->content, qr/Test2 Page/, 'normal';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/xx/Test3');
    like $res->content, qr/Test3 Page/, 'normal';
};

done_testing();
