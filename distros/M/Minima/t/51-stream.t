use v5.40;
use experimental 'class';
use Test2::V0;
use HTTP::Request::Common;
use Plack::Test;

use Minima::App;

# Prepare a tmp dir
my $dir = Path::Tiny->tempdir;
chdir $dir;
mkdir 'etc';

# Basic routes and controller
my $routes = $dir->child('etc/routes.map');
$routes->spew("* / C a\n");

my $class = $dir->child('C.pm');
$class->spew(<<~'EOF'
    use v5.40;
    use experimental 'class';
    class C {
        field $app :param;
        field $route :param;
        method a {
            sub {
                my $w = shift->([ 200, [] ]);
                $w->write('streaming');
                $w->close;
            }
        };
    }
    EOF
);

{
    local @INC = ( $dir->absolute, @INC );

    # Test object
    my $app = Minima::App->new();
    my $test = Plack::Test->create(sub { $app->set_env(shift); $app->run });

    # Basic responses
    my $res = $test->request(GET '/');
    is( $res->content, "streaming", 'handles streaming properly' );

    $res = $test->request(HEAD '/');
    is( length($res->content), 0, 'returns empty body for HEAD (streaming)' );
}

chdir;

done_testing;
