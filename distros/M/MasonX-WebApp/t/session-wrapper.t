use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use File::Temp;

use CGI qw( -no_debug );
use HTML::Mason::FakeApache;

# Trick ApacheHandler into loading without exploding
sub Apache::perl_hook { 1 }
sub Apache::server { 0 }

{
    package Test1;

    use base 'MasonX::WebApp';

    __PACKAGE__->UseSession(0);

    my $app =
        Test1->new
            ( apache_req => HTML::Mason::FakeApache->new,
              args       => {},
            );

    ::throws_ok { $app->session } 'MasonX::WebApp::Exception',
                'Cannot call session() when UseSession is false';
}

{
    package Test2;

    use base 'MasonX::WebApp';

    my $dir;
    BEGIN { $dir = File::Temp::tempdir( CLEANUP => 1 ) };

    __PACKAGE__->SessionWrapperParams( { class          => 'File',
                                         directory      => $dir,
                                         lock_directory => $dir,
                                       },
                                     );

    my $app =
        Test2->new
            ( apache_req => HTML::Mason::FakeApache->new,
              args       => {},
            );

    ::isa_ok $app->session_wrapper, 'Apache::Session::Wrapper';
    ::isa_ok tied %{ $app->session }, 'Apache::Session';
}
