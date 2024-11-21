use v5.40;
use Test2::V0;
use utf8;

use Minima::App;
use Minima::View::JSON;

$ENV{PLACK_ENV} = 'deployment';

my $app  = Minima::App->new();
my $view = Minima::View::JSON->new(app => $app);

# Empty
is( $view->render, '{}', 'renders valid JSON without data' );

# UTF-8
my $s = '{"áèîõü":1}';
utf8::encode($s);
is( $view->render({áèîõü => 1}), $s, 'encodes UTF-8' );

# Pretty print in development
delete $ENV{PLACK_ENV};
is( $view->render([]), "[]\n", 'pretty prints in development mode' );

done_testing;
