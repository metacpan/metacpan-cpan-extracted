use strict;
use warnings;


use Model;
use View::bullet;
use View::bullet::text;
use View::table;


my $model = Model->new;

# View 1

my $view = View::bullet->new;
$view->render($model);
warn $view->as_HTML;

# View 2

my $cols = 3;
my $tabular_model = $model->reform_data($cols); 

my $view = View::table->new;
$view->render($tabular_model);
warn $view->as_HTML;

# Extra credit - render bullets as text

my $view = View::bullet::text->new;
my $text = $view->render($model);
warn 'text', $text;
