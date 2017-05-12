use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

use CGI qw( -no_debug );
use HTML::Mason::FakeApache;

# Trick ApacheHandler into loading without exploding
sub Apache::perl_hook { 1 }
sub Apache::server { 0 }

use Apache::Constants ();
use MasonX::WebApp;

sub Apache::Constants::OK { 200 }
sub Apache::Constants::REDIRECT { 302 }

{
    package Tie::STDOUT;

    use base 'Tie::Handle';

    sub TIEHANDLE { my $class = shift; bless {}, $class }

    sub PRINT { shift->{data} .= join '', grep { defined } @_ }

    sub data { $_[0]->{data} }
}

{
    my $app =
        MasonX::WebApp->new
            ( apache_req => HTML::Mason::FakeApache->new,
              args       => {},
            );

    throws_ok { $app->abort } 'MasonX::WebApp::Exception::Abort';
    ok $app->aborted, 'aborted() is true';
    is $app->abort_status, Apache::Constants::OK(), 'abort status is OK';
}

{
    my $app =
        MasonX::WebApp->new
            ( apache_req => HTML::Mason::FakeApache->new,
              args       => {},
            );

    my $stdout;
    {
        local *STDOUT;
        tie *STDOUT, 'Tie::STDOUT';
        throws_ok { $app->redirect( uri => '/' ) } 'MasonX::WebApp::Exception::Abort';

        $stdout = (tied *STDOUT)->data;
    }

    like $stdout, qr/Status:\s+302/i, 'output includes correct status code';
    like $stdout, qr/Location:\s+/i, 'output includes correct location header';

    ok $app->aborted, 'aborted() is true';
    is $app->abort_status, Apache::Constants::REDIRECT(), 'abort status is REDIRECT';
}

