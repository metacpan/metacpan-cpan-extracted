use v5.40;
use Test2::V0;

use Minima::App;
use Minima::View::HTML;

$ENV{PLACK_ENV} = 'development';
my $config = {};
my $app = Minima::App->new(
    configuration => $config,
);
my $view = Minima::View::HTML->new(app => $app);

my $dir = Path::Tiny->tempdir;
chdir $dir;
my $t_home = $dir->child('home.tt');
$t_home->spew('h');

# Basic template check
like(
    dies { $view->render },
    qr/no template/i,
    'dies if it has no template set'
);

$view->set_template('home.t');
$view->set_directory('.');
like(
    dies { $view->render },
    qr/not found/i,
    'dies for non-existing template'
);

$view->set_template('home');
is( $view->render, 'h', 'renders properly' );
pass( 'automatically adds .tt extension' );

# Data
$t_home->spew('[% d %]');
is( $view->render({ d => 'secret' }), 'secret', 'passes data' );

$t_home->spew('[% view.title %]');
$view->set_title('secret title');
is( $view->render, 'secret title', 'passes view data' );

# Config
$t_home->spew('%% view.title');
is( $view->render, 'secret title', 'handles outline tags' );
$config->{tt} = { OUTLINE_TAG => '@@'}; # break default '%%'
isnt( $view->render, 'secret title', 'allows config overwrites' );

# CSS
$t_home->spew('@@ view.classes');
is( $view->render, 'home', 'outputs template name as css class' );

$view->set_name_as_class(0);
is( $view->render, '', 'supresses template name correctly' );

$view->add_class('a');
$view->add_class('b');
is( $view->render, 'a b', 'outputs proper class set' );

# Includes
$t_home->spew('@');
my $i = 0;
$dir->child("$_.tt")->spew(++$i) for qw/ pre1 pre2 post1 post2 /;
$view->add_pre('pre1');
$view->add_pre('pre2');
$view->add_post('post1');
$view->add_post('post2');
is( $view->render, '12@34', 'includes extra templates correctly' );

chdir;

done_testing;
