
use Mojo::Base -strict;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Cwd qw( abs_path );
use Test::Mojo;
use Test::More;

my $conf = abs_path( catfile( dirname( __FILE__ ), 'share', 'allow_origin.conf' ) );
$ENV{MOJO_CONFIG} = $conf;
my $t = Test::Mojo->new( 'Mercury' );

$t->app->plugin( 'Config', { file => $conf } );

my @paths = qw( /bus /sub /pub /push /pull );

for my $path ( @paths ) {
    subtest $path => sub {
        subtest 'example.com - host only' => sub {
            subtest 'correct origin' => sub {
                $t->websocket_ok( $path . '/fry', { Origin => 'http://example.com' } )
                  ->status_is( 101 )
                  ->finish_ok;
            };

            subtest 'bad origin' => sub {
                $t->ua->websocket(
                    $path . '/leela',
                    { Origin => 'http://example.net' },
                    sub {
                        my ( $ua, $tx ) = @_;
                        ok !$tx->is_websocket, 'did not succeed';
                        is $tx->res->code, 401, 'unauthorized';
                        Mojo::IOLoop->stop;
                    },
                );
                Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
            };

            subtest 'no origin' => sub {
                $t->ua->websocket(
                    $path . '/bender',
                    sub {
                        my ( $ua, $tx ) = @_;
                        ok !$tx->is_websocket, 'did not succeed';
                        is $tx->res->code, 401, 'unauthorized';
                        Mojo::IOLoop->stop;
                    },
                );
                Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
            };
        };
    };
}

done_testing;
