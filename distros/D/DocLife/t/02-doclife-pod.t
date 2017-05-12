use HTTP::Request::Common;
use DocLife::Pod;
use Plack::Test;
use Test::More;

my $app = DocLife::Pod->new(
    root => 'lib'
);

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/DocLife.pm');
    like $res->content, qr/Document Viewer written in Perl, to run under Plack/, 'normal';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/DocLife/Pod.pm');
    like $res->content, qr/Pod Viewer/, 'normal';
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/DocLife/Markdown.pm');
    like $res->content, qr/Markdown Viewer/, 'normal';
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

done_testing();
