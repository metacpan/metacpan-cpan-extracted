use Test::More tests => 1;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

use lib qw(t/lib);

my $form = new HTML::FormFu::ExtJS;

$form->populate({ elements => { type => '+MyApp::Element::MyField' } });

ok($form->render);
