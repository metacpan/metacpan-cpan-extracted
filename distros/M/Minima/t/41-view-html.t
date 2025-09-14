use v5.40;
use Test2::V0;

use Minima::App;
use Minima::View::HTML;

my $dir = Path::Tiny->tempdir;
chdir $dir;

$ENV{PLACK_ENV} = 'development';
my $config = {};
my $app = Minima::App->new(
    configuration => $config,
);
my $view = Minima::View::HTML->new(app => $app);

my $t_home = $dir->child('home.ht');
$t_home->spew('h');
my $t_about = $dir->child('about.tt');
$t_about->spew('t');
my $t_contact = $dir->child('contact.tpl');
$t_contact->spew('c');

# Basic template check
like(
    dies { $view->render },
    qr/no template/i,
    'dies if it has no template set'
);

$view->set_template('home.t');
$view->add_directory('.');
like(
    dies { $view->render },
    qr/not found/i,
    'dies for non-existing template'
);

$view->set_template('home');
is( $view->render, 'h', 'renders properly' );
pass( 'automatically adds .ht extension' );

$config->{template_ext} = 'tt';
$view->set_template('about');
is( $view->render, 't', 'adds custom template extension' );
delete $config->{template_ext};

$view->set_template('contact.tpl');
is( $view->render, 'c', 'respects named file extension' );

# Manipulating the include path
$dir->child('templates')->mkdir;
$dir->child('js')->mkdir;
my $t_inner = $dir->child('templates/inner.ht');
$t_inner->spew('i');
my $t_js = $dir->child('js/script.js');
$t_js->spew('js');

$view->set_template('inner');
is( $view->render, 'i', 'accesses default templates include path');

$view->set_template('script.js');
is( $view->render, 'js', 'accesses default js include path');

$view->clear_directories;
like(
    dies { $view->render },
    qr/not found/i,
    'clears include path'
);

$config->{templates_dir} = undef;
$view = Minima::View::HTML->new(app => $app);
$view->set_template('home');
like(
    dies { $view->render },
    qr/not found/i,
    'respects clear include list'
);

$config->{templates_dir} = [];
$view = Minima::View::HTML->new(app => $app);
$view->set_template('home');
like(
    dies { $view->render },
    qr/not found/i,
    'respects empty include list'
);

$config->{templates_dir} = [qw/./];
$view = Minima::View::HTML->new(app => $app);
$view->set_template('inner');
like(
    dies { $view->render },
    qr/not found/i,
    'respects custom include list'
);

$view->set_template('home');
is( $view->render, 'h', 'reads custom include list' );

# Data
$view->set_template('home');
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
$dir->child("$_.ht")->spew(++$i) for qw/ pre1 pre2 post1 post2 /;
$view->add_before_template('pre1');
$view->add_before_template('pre2');
$view->add_after_template('post1');
$view->add_after_template('post2');
is( $view->render, '12@34', 'includes extra templates correctly' );

chdir;

done_testing;
