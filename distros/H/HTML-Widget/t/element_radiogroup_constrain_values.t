use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'RadioGroup', 'foo' )->values( [ 0, 1, 2 ] )->constrain_values(1);
$w->element( 'RadioGroup', 'bar' )->values( [ 3, 4 ] )->constrain_values(1);

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 1, bar => 1 } );

    my $f = $w->process($query);

    my @constraints = $w->get_constraints;
    cmp_ok( scalar(@constraints), '==', 2, 'Two implicit IN constraints' );
    cmp_ok( scalar( @{ $constraints[0]->in } ),
        '==', 3, 'Three keys for constraint 0' );
    cmp_ok( scalar( @{ $constraints[1]->in } ),
        '==', 2, 'Two keys for constraint 1' );

    ok( $f->valid('foo') );
    ok( !$f->valid('bar') );

    ok( $f->has_errors('bar') );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><fieldset class="radiogroup_fieldset" id="widget_foo"><span class="radiogroup"><label for="widget_foo_1" id="widget_foo_1_label"><input class="radio" id="widget_foo_1" name="foo" type="radio" value="0" />0</label><label for="widget_foo_2" id="widget_foo_2_label"><input checked="checked" class="radio" id="widget_foo_2" name="foo" type="radio" value="1" />1</label><label for="widget_foo_3" id="widget_foo_3_label"><input class="radio" id="widget_foo_3" name="foo" type="radio" value="2" />2</label></span></fieldset><span class="labels_with_errors" id="widget_bar"><fieldset class="radiogroup_fieldset"><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input class="radio" id="widget_bar_1" name="bar" type="radio" value="3" />3</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="4" />4</label></span></fieldset></span><span class="error_messages" id="widget_bar_errors"><span class="in_errors" id="widget_bar_error_in">Invalid Input</span></span></fieldset></form>
EOF
}

