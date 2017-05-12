use strict;
use warnings;

use Test::More tests => 36;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new->method('post')->action('/foo/bar');

$w->element( 'Textfield', 'age' )->label('Age')->size(3);
$w->element( 'Textfield', 'name' )->label('Name')->size(60);
$w->element( 'Submit',    'ok' )->value('OK');

$w->legend('Fool');

$w->constraint( 'Integer', 'age' )->message('No integer.');
$w->constraint( 'Length',  'age' )->min(1)->max(3)->message('Wrong length.');
$w->constraint( 'Range',   'age' )->min(22)->max(24)->message('Wrong range.');
$w->constraint( 'Regex',   'age' )->regex(qr/\D+/)
    ->message('Contains digit characters.');
$w->constraint( 'Not_Integer', 'name' );
$w->constraint( 'All', 'age', 'name' )->message('Missing value.');

# Without query
{
    my $f = $w->result;
    is( $f->as_xml, <<EOF, 'XML output is form' );
<form action="/foo/bar" id="widget" method="post"><fieldset class="widget_fieldset"><legend id="widget_legend">Fool</legend><label for="widget_age" id="widget_age_label">Age<input class="textfield" id="widget_age" name="age" size="3" type="text" /></label><label for="widget_name" id="widget_name_label">Name<input class="textfield" id="widget_name" name="name" size="60" type="text" /></label><input class="submit" id="widget_ok" name="ok" type="submit" value="OK" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            age  => 23,
            name => 'sri',
            ok   => 'OK',
        } );

    my $f = $w->process($query);
    isa_ok( $f, 'HTML::Widget::Result',
        'Result is HTML::Widget::Result object' );

    my @e = $f->has_errors;

    ok( $f->valid('name'), 'Field name is valid' );
    is( $e[0], 'age', 'Field age has errors' );

    is( $f->valid('name'), 1, 'Field name is valid' );
    is( !$f->valid('age'), 1, 'Field age is not valid' );
    is( !$f->valid('foo'), 1, 'Field foo is not valid' );

    is( !$f->has_errors('name'), 1, 'Field name has no errors' );
    is( $f->has_errors('age'),   1, 'Field foo has errors' );
    is( $f->has_error('foo'),    0, 'Field foo has no errors' );

    is( $f->param('name'), 'sri', 'Param name is accessible' );
    is( $f->param('age'),  undef, 'Param age is not accessible' );
    is( $f->param('foo'),  undef, 'Param foo is not defined' );

    is( $f->params->{name},    'sri', 'Param name is defined' );
    is( $f->params->{age},     undef, 'Param age is not defined' );
    is( $f->parameters->{foo}, undef, 'Param foo is not defined' );

    $f->add_valid( 'bar', 'dude' );

    is( $f->params->{bar}, 'dude', 'Bar is dude' );
    is( $f->param('bar'),  'dude', 'Bar is dude' );
    is( $f->valid('bar'),  1,      'Bar is valid' );

    my $c = $f->element('age');
    isa_ok( $c, 'HTML::Widget::Container', 'Element is a container object' );
    isa_ok( $c->element, 'HTML::Element', 'Element is a HTML::Element object' );
    isa_ok( $c->error,   'HTML::Element', 'Error is a HTML::Element object' );
    is( $c->javascript, '', 'JavaScript is empty' );

    is( $c->element_xml, <<EOF, 'Element XML output is ok' );
<label class="labels_with_errors" for="widget_age" id="widget_age_label">Age<span class="fields_with_errors"><input class="textfield" id="widget_age" name="age" size="3" type="text" value="23" /></span></label>
EOF
    is( $c->error_xml, <<EOF, 'Error XML output is ok' );
<span class="error_messages" id="widget_age_errors"><span class="regex_errors" id="widget_age_error_regex">Contains digit characters.</span></span>
EOF
    is( $c->javascript_xml, <<EOF, 'JavScript XML output is ok' );
<script type="text/javascript">
<!--

//-->
</script>
EOF
    is( $c->as_xml, <<EOF, 'Container XML output is ok' );
<label class="labels_with_errors" for="widget_age" id="widget_age_label">Age<span class="fields_with_errors"><input class="textfield" id="widget_age" name="age" size="3" type="text" value="23" /></span></label>
<span class="error_messages" id="widget_age_errors"><span class="regex_errors" id="widget_age_error_regex">Contains digit characters.</span></span>
EOF

    my @errors = $f->errors;
    is( $errors[0]->name, 'age', 'Expected error' );

    is( $errors[0],
        'Contains digit characters.',
        'Field contains digit characters'
    );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form action="/foo/bar" id="widget" method="post"><fieldset class="widget_fieldset"><legend id="widget_legend">Fool</legend><label class="labels_with_errors" for="widget_age" id="widget_age_label">Age<span class="fields_with_errors"><input class="textfield" id="widget_age" name="age" size="3" type="text" value="23" /></span></label><span class="error_messages" id="widget_age_errors"><span class="regex_errors" id="widget_age_error_regex">Contains digit characters.</span></span><label for="widget_name" id="widget_name_label">Name<input class="textfield" id="widget_name" name="name" size="60" type="text" value="sri" /></label><input class="submit" id="widget_ok" name="ok" type="submit" value="OK" /></fieldset></form>
EOF
}

# Embed
{
    my $w2 = HTML::Widget->new('foo')->action('/foo');
    my $w3 = HTML::Widget->new('bar');

    $w3->element( 'Textfield', 'baz' );

    $w2->embed($w);
    $w2->embed($w3);

    my $f = $w2->process;
    is( $f->as_xml, <<EOF, 'XML output is form' );
<form action="/foo" id="foo" method="post"><fieldset class="widget_fieldset" id="foo_widget"><legend id="foo_widget_legend">Fool</legend><label for="foo_widget_age" id="foo_widget_age_label">Age<input class="textfield" id="foo_widget_age" name="age" size="3" type="text" /></label><label for="foo_widget_name" id="foo_widget_name_label">Name<input class="textfield" id="foo_widget_name" name="name" size="60" type="text" /></label><input class="submit" id="foo_widget_ok" name="ok" type="submit" value="OK" /></fieldset><fieldset class="widget_fieldset" id="foo_bar"><input class="textfield" id="foo_bar_baz" name="baz" type="text" /></fieldset></form>
EOF
}

# Merge
{
    my $w2 = HTML::Widget->new('foo')->action('/foo');
    my $w3 = HTML::Widget->new('bar');

    $w3->element( 'Textfield', 'baz' );

    $w2->merge($w);
    $w2->merge($w3);

    my $f = $w2->process;
    is( $f->as_xml, <<EOF, 'XML output is form' );
<form action="/foo" id="foo" method="post"><fieldset class="widget_fieldset"><label for="foo_age" id="foo_age_label">Age<input class="textfield" id="foo_age" name="age" size="3" type="text" /></label><label for="foo_name" id="foo_name_label">Name<input class="textfield" id="foo_name" name="name" size="60" type="text" /></label><input class="submit" id="foo_ok" name="ok" type="submit" value="OK" /><input class="textfield" id="foo_baz" name="baz" type="text" /></fieldset></form>
EOF
}

# *_ref methods

{
    my @element    = $w->get_elements;
    my @filter     = $w->get_filters;
    my @constraint = $w->get_constraints;

    is_deeply( $w->get_elements_ref,    \@element,    'get_elements_ref' );
    is_deeply( $w->get_filters_ref,     \@filter,     'get_filters_ref' );
    is_deeply( $w->get_constraints_ref, \@constraint, 'get_constraints_ref' );

    my $f = $w->process;

    my @f_element = $f->elements;

    is_deeply( $f->elements_ref, \@f_element, 'elements_ref' );
}
