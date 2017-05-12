use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Upload', 'foo' )->label('Foo')->accept('text/plain')
    ->maxlength(1000)->size(30);
$w->element( 'Upload', 'bar' );

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;

    ok( $w->enctype() eq 'multipart/form-data',
        'enctype automatically set to multipart/form-data' );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form enctype="multipart/form-data" id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label">Foo<input accept="text/plain" class="upload" id="widget_foo" maxlength="1000" name="foo" size="30" type="file" /></label><input class="upload" id="widget_bar" name="bar" type="file" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '23',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form enctype="multipart/form-data" id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label">Foo<span class="fields_with_errors"><input accept="text/plain" class="upload" id="widget_foo" maxlength="1000" name="foo" size="30" type="file" value="yada" /></span></label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><input class="upload" id="widget_bar" name="bar" type="file" value="23" /></fieldset></form>
EOF
}
