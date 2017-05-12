use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;

subtest 'generate' => sub {
    my $app_id = 12345;
    my $fb = Facebook::OpenGraph->new(+{
        app_id => $app_id,
    });

    is($fb->js_cookie_name, sprintf('fbsr_%d',$app_id));
};

subtest 'w/o app_id' => sub {
    throws_ok(
        sub { Facebook::OpenGraph->new->js_cookie_name() },
        qr/app_id must be set/
    );
};

done_testing;
