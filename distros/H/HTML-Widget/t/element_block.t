use strict;
use warnings;

use Test::More tests => 28;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

my $e = $w->element( 'Block', 'foo' );
$e->element( 'Textfield', 'bar' )->value('bar')->label('Bar');

my $fs = $e->element( 'Fieldset', 'fs' )->legend('FS');
$fs->element( 'Textfield', 'baz' );

my $fs2 = $e->element( 'Fieldset', 'fs2' );
$fs2->element( 'Textfield', 'bartwo' );
$fs2->element( 'Textfield', 'baztwo' );

my $fsn = $fs2->element( 'Fieldset', 'fsnest' );
$fsn->element( 'Textfield', 'barnest' )->value('Barnest');

# Not completely sure if NullContainers should be used for real,
# but test them anyway as they're the base for Block.
my $nc = $e->element( 'NullContainer', 'nc' );
$nc->element( 'Textfield', 'norp' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output' );
<form id="widget" method="post"><div id="widget_foo"><label for="widget_foo_bar" id="widget_foo_bar_label">Bar<input class="textfield" id="widget_foo_bar" name="bar" type="text" value="bar" /></label><fieldset class="widget_fieldset" id="widget_foo_fs"><legend id="widget_foo_fs_legend">FS</legend><input class="textfield" id="widget_foo_fs_baz" name="baz" type="text" /></fieldset><fieldset class="widget_fieldset" id="widget_foo_fs2"><input class="textfield" id="widget_foo_fs2_bartwo" name="bartwo" type="text" /><input class="textfield" id="widget_foo_fs2_baztwo" name="baztwo" type="text" /><fieldset class="widget_fieldset" id="widget_foo_fs2_fsnest"><input class="textfield" id="widget_foo_fs2_fsnest_barnest" name="barnest" type="text" value="Barnest" /></fieldset></fieldset><input class="textfield" id="widget_foo_nc_norp" name="norp" type="text" /></div></form>
EOF
}

# With mocked basic query - okay
{
    my $query = HTMLWidget::TestLib->mock_query( {
            bar     => 'yada',
            baz     => '23',
            bartwo  => 'ping',
            baztwo  => '18',
            barnest => 'yellow',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output with query' );
<form id="widget" method="post"><div id="widget_foo"><label for="widget_foo_bar" id="widget_foo_bar_label">Bar<input class="textfield" id="widget_foo_bar" name="bar" type="text" value="yada" /></label><fieldset class="widget_fieldset" id="widget_foo_fs"><legend id="widget_foo_fs_legend">FS</legend><input class="textfield" id="widget_foo_fs_baz" name="baz" type="text" value="23" /></fieldset><fieldset class="widget_fieldset" id="widget_foo_fs2"><input class="textfield" id="widget_foo_fs2_bartwo" name="bartwo" type="text" value="ping" /><input class="textfield" id="widget_foo_fs2_baztwo" name="baztwo" type="text" value="18" /><fieldset class="widget_fieldset" id="widget_foo_fs2_fsnest"><input class="textfield" id="widget_foo_fs2_fsnest_barnest" name="barnest" type="text" value="yellow" /></fieldset></fieldset><input class="textfield" id="widget_foo_nc_norp" name="norp" type="text" /></div></form>
EOF
}

# With mocked basic query - errors
$w->constraint( 'Integer', 'bar', 'baz', 'bartwo', 'baztwo' );
{
    my $query = HTMLWidget::TestLib->mock_query( {
            bar    => 'yada',
            baz    => '23',
            bartwo => 'ping',
            baztwo => '18',
            norp   => 'Nil',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output with query and errors' );
<form id="widget" method="post"><div id="widget_foo"><label class="labels_with_errors" for="widget_foo_bar" id="widget_foo_bar_label">Bar<span class="fields_with_errors"><input class="textfield" id="widget_foo_bar" name="bar" type="text" value="yada" /></span></label><span class="error_messages" id="widget_foo_bar_errors"><span class="integer_errors" id="widget_foo_bar_error_integer">Invalid Input</span></span><fieldset class="widget_fieldset" id="widget_foo_fs"><legend id="widget_foo_fs_legend">FS</legend><input class="textfield" id="widget_foo_fs_baz" name="baz" type="text" value="23" /></fieldset><fieldset class="widget_fieldset" id="widget_foo_fs2"><span class="fields_with_errors"><input class="textfield" id="widget_foo_fs2_bartwo" name="bartwo" type="text" value="ping" /></span><span class="error_messages" id="widget_foo_fs2_bartwo_errors"><span class="integer_errors" id="widget_foo_fs2_bartwo_error_integer">Invalid Input</span></span><input class="textfield" id="widget_foo_fs2_baztwo" name="baztwo" type="text" value="18" /><fieldset class="widget_fieldset" id="widget_foo_fs2_fsnest"><input class="textfield" id="widget_foo_fs2_fsnest_barnest" name="barnest" type="text" /></fieldset></fieldset><input class="textfield" id="widget_foo_nc_norp" name="norp" type="text" value="Nil" /></div></form>
EOF
}

# Introspection
my @el = $e->get_elements();
is( scalar(@el), 4, 'foo has 4 els' );
isa_ok( $el[0], 'HTML::Widget::Element::Textfield', 'foo 1st el is textfield' );
isa_ok( $el[1], 'HTML::Widget::Element::Fieldset',  'foo 2nd el is fieldset' );
my @fsl = $el[1]->get_elements();
is( scalar(@fsl), 1, 'fs has 1' );
isa_ok( $fsl[0], 'HTML::Widget::Element::Textfield', 'fs 1st el is textfield' );

isa_ok(
    $e->get_element( name => 'bar' ),
    'HTML::Widget::Element::Textfield',
    'el bar by name'
);
isa_ok(
    $e->get_element( type => 'Fieldset' ),
    'HTML::Widget::Element::Fieldset',
    'el fs by type'
);

my @full_el = $e->find_elements();
is( scalar(@full_el), 11, 'find_elements' );
my @a_types = map { ref($_); } @full_el;
my @e_types = map "HTML::Widget::Element::$_", qw(
    Block
    Textfield
    Fieldset
    Textfield
    Fieldset
    Textfield
    Textfield
    Fieldset
    Textfield
    NullContainer
    Textfield
);
ok( eq_array( \@a_types, \@e_types ), 'find_elements types' );
my @a_names = map { $_->name; } @full_el;
my @e_names = qw(foo bar fs baz fs2 bartwo baztwo fsnest barnest nc norp);
ok( eq_array( \@a_names, \@e_names ), 'find_elements names' );

@full_el = $e->find_elements( type => 'Textfield' );
is( scalar(@full_el), 6, 'find_elements by type' );
@a_types = map { ref($_); } @full_el;
@e_types = map "HTML::Widget::Element::$_", ('Textfield') x 6;
ok( eq_array( \@a_types, \@e_types ), 'find_elements types' );
@a_names = map { $_->name; } @full_el;
@e_names = qw(bar baz bartwo baztwo barnest norp);
ok( eq_array( \@a_names, \@e_names ), 'find_elements names' );

@full_el = $e->find_elements( name => 'bartwo' );
is( scalar(@full_el), 1, 'find_elements by name' );
is( ref( $full_el[0] ),
    'HTML::Widget::Element::Textfield',
    'find_element type'
);
is( $full_el[0]->name, 'bartwo', 'find_element name' );

# This may change:
my @fs2l = $el[2]->get_elements( type => 'OrderedList' );
is( scalar(@fs2l), 0, 'fs2 has no ordered lists' );
@fs2l = $el[2]->get_elements( type => 'Textfield' );
is( scalar(@fs2l), 2, 'fs2 has 2 textfields' );
@fs2l = $el[2]->get_elements( name => 'baztwo' );
is( scalar(@fs2l), 1, 'fs2 has 1 baztwo' );
is( $fs2l[0]->name, 'baztwo', 'baztwo name ok' );

# Container introspection
{
    my $query = HTMLWidget::TestLib->mock_query( {
            bar    => 'yada',
            baz    => '23',
            bartwo => 'ping',
            baztwo => '18',
        } );

    my $f    = $w->process($query);
    my $foop = $f->element('fs');
    ok( not($foop), 'fs not a top-level element' );
    $foop = $f->element('foo');
    isa_ok( $foop, 'HTML::Widget::BlockContainer', 'result foo' );
    $foop = $f->find_result_element('fs');
    isa_ok( $foop, 'HTML::Widget::BlockContainer', 'find_result_element fs' );
    my @c = $f->elements_for('fs2');
    is( scalar(@c), 3, 'elements_for fs2' );
    isa_ok( $c[1], 'HTML::Widget::Container' );
}

# EOF
