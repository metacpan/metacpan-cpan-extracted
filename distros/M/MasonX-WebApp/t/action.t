use strict;
use warnings;

use Test::More tests => 6;

use CGI qw( -no_debug );
use HTML::Mason::FakeApache;

# Trick ApacheHandler into loading without exploding
sub Apache::perl_hook { 1 }
sub Apache::server { 0 }

{
    package Test3;

    use base 'MasonX::WebApp';

    __PACKAGE__->ActionURIPrefix('/action/');
    __PACKAGE__->RequireAbortAfterAction(0);

    my %called;
    sub test1 { $called{test1} = 1 };
    sub test2 { $called{test2} = 1 };

    local $ENV{SCRIPT_NAME} = '/action/test1';

    %called = ();
    Test3->new
        ( apache_req => HTML::Mason::FakeApache->new,
          args       => {},
        );

    ::ok( $called{test1}, 'test1 action was called' );
    ::ok( ! $called{test2}, 'test2 action was not called' );

    local $ENV{SCRIPT_NAME} = '/action/test2';

    %called = ();
    Test3->new
        ( apache_req => HTML::Mason::FakeApache->new,
          args       => {},
        );

    ::ok( ! $called{test1}, 'test1 action was not called' );
    ::ok( $called{test2}, 'test2 action was called' );
}

{
    package Test4;

    use base 'MasonX::WebApp';

    __PACKAGE__->ActionURIPrefixRegex( qr{^/(?:submit|download)/} );
    __PACKAGE__->RequireAbortAfterAction(0);

    my %called;
    sub test1 { $called{test1} = 1 };
    sub test2 { $called{test2} = 1 };

    local $ENV{SCRIPT_NAME} = '/download/test1';

    %called = ();
    Test4->new
        ( apache_req => HTML::Mason::FakeApache->new,
          args       => {},
        );

    ::ok( $called{test1}, 'test1 action was called' );
    ::ok( ! $called{test2}, 'test2 action was not called' );
}
