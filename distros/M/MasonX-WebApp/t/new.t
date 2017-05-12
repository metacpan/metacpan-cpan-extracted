use strict;
use warnings;

use Test::More tests => 1;

use CGI qw( -no_debug );
use HTML::Mason::FakeApache;

# Trick ApacheHandler into loading without exploding
sub Apache::perl_hook { 1 }
sub Apache::server { 0 }

use MasonX::WebApp;

{
    my $app =
        MasonX::WebApp->new
            ( apache_req => HTML::Mason::FakeApache->new,
              args       => {},
            );

    isa_ok $app, 'MasonX::WebApp';
}
