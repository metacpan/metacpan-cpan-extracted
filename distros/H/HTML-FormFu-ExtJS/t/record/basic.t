use Test::More tests => 2;

use HTML::FormFu::ExtJS::Grid;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file("t/elements/text.yml");
is_deeply(
    $form->_record,
    [
        { name    => "test",  type => "string", mapping => "test" },
        { mapping => "test2", name => "test2",  type    => "string" }
    ]
);

ok( $form->render_items );
