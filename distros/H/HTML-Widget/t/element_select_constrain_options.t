use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Select', 'foo' )->label('Foo')
    ->options( 0 => 'zero', 1 => 'one', 2 => 'two' )->constrain_options(1);
$w->element( 'Select', 'bar' )->label('Bar')
    ->options( 3 => 'three', 4 => 'four' )->constrain_values(1);

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
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label">Foo<select class="select" id="widget_foo" name="foo"><option value="0">zero</option><option selected="selected" value="1">one</option><option value="2">two</option></select></label><label class="labels_with_errors" for="widget_bar" id="widget_bar_label">Bar<select class="select" id="widget_bar" name="bar"><option value="3">three</option><option value="4">four</option></select></label><span class="error_messages" id="widget_bar_errors"><span class="in_errors" id="widget_bar_error_in">Invalid Input</span></span></fieldset></form>
EOF
}
