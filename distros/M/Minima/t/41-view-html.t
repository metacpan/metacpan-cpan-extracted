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

# Basic template check
{
    my $view = Minima::View::HTML->new(app => $app);

    my $t_home = $dir->child('home.ht');
    $t_home->spew('h');
    my $t_about = $dir->child('about.tt');
    $t_about->spew('t');
    my $t_contact = $dir->child('contact.tpl');
    $t_contact->spew('c');

    # no template
    like(
        dies { $view->render },
        qr/no template/i,
        'dies if it has no template set'
    );

    # typo in name
    $view->set_template('home.t');
    $view->add_directory('.');
    like(
        dies { $view->render },
        qr/not found/i,
        'dies for non-existing template'
    );

    # auto add extension
    $view->set_template('home');
    is( $view->render, 'h', 'renders properly' );
    pass( 'automatically adds .ht extension' );

    # customize default extension
    $config->{template_ext} = 'tt';
    $view->set_template('about');
    is( $view->render, 't', 'adds custom template extension' );
    delete $config->{template_ext};

    # pass name with extension
    $view->set_template('contact.tpl');
    is( $view->render, 'c', 'respects named file extension' );
}

# Manipulating the include path
{
    my $view = Minima::View::HTML->new(app => $app);

    $dir->child('templates')->mkdir;
    $dir->child('js')->mkdir;
    my $t_inner = $dir->child('templates/inner.ht');
    $t_inner->spew('i');
    my $t_js = $dir->child('js/script.js');
    $t_js->spew('js');
    my $t_home = $dir->child('home.ht');
    $t_home->spew('h');

    # default template directories
    $view->set_template('inner');
    is( $view->render, 'i', 'accesses default templates include path');

    $view->set_template('script.js');
    is( $view->render, 'js', 'accesses default js include path');

    # can clear defaults
    $view->clear_directories;
    like(
        dies { $view->render },
        qr/not found/i,
        'clears include path'
    );

    # set clear as default
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

    # set a custom list
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

    # added directories have preference over existing ones
    my $inner_home = $dir->child('templates/home.ht');
    $inner_home->spew('t/h');
    $view->add_directory('templates');
    is( $view->render, 't/h', 'newly added directories take precedence' );

    # custom list keeps order
    $config->{templates_dir} = [qw/. templates/];
    $view = Minima::View::HTML->new(app => $app);
    $view->set_template('home');
    is( $view->render, 'h', 'respects custom list order' );

    delete $config->{templates_dir};
}

# Data
{
    my $view = Minima::View::HTML->new(app => $app);
    my $t_home = $dir->child('home.ht');
    $view->add_directory('.');

    # pass on render
    $view->set_template('home');
    $t_home->spew('[% d %]');
    is( $view->render({ d => 'secret' }), 'secret', 'passes data' );

    # managed data
    $t_home->spew('[% view.title %]');
    $view->set_title('secret title');
    is( $view->render, 'secret title', 'passes view data' );

    # config
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

    delete $config->{tt};
}

# Includes before & after template
{
    my $view = Minima::View::HTML->new(app => $app);
    $view->set_template('home');
    $view->add_directory('.');

    my $t_home = $dir->child('home.ht');
    $t_home->spew('@');

    my $i = 0;
    $dir->child("$_.ht")->spew(++$i) for qw/ pre1 pre2 post1 post2 /;

    $view->add_before_template('pre1');
    $view->add_before_template('pre2');
    $view->add_after_template('post1');
    $view->add_after_template('post2');
    is( $view->render, '12@34', 'includes extra templates correctly' );
}

# Handles extensions on body open & close
{
    my $view = Minima::View::HTML->new(app => $app);
    $view->set_template('extras');
    $view->add_directory('.');

    my $extras = $dir->child('extras.ht');
    $extras->spew(<<~T);
        %% foreach i in view.body_open ; include \$i ; end
        %% foreach i in view.body_close; include \$i ; end
        T

    my $i = 0;
    $dir->child($_)->spew(++$i) for qw/ o1.ht o2.tpl c1.ht /;

    $view->add_body_open('o1');
    $view->add_body_open('o2.tpl');
    $view->add_body_close('c1');
    is( $view->render, '123', 'handles extensions on body extras' );
}

chdir;

done_testing;
