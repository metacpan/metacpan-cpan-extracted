use Test::More tests => 23;

use Graphics::Primitive::Container;
use Graphics::Primitive::TextBox;
use Graphics::Primitive::CSS;

my $styler = Graphics::Primitive::CSS->new(
    styles => '
    .foo {
        background-color: #fff;
        border-width: 3px;
        color: #ff00ff;
        font-family: Arial;
        font-weight: bold;
        margin-left: 2px;
        padding: 1px 2px 3px 4px;
        text-align: center;
        vertical-align: center;
    }
    #bar {
        background-color: aliceblue;
        border-bottom-width: 1px;
        border-left-width: 2px;
        border-right-width: 3px;
        border-top-color: #00ff00;
        border-top-width: 4px;
        font-size: 7pt;
        margin: 1px 2px 3px 4px;
    }'
);

my $container = Graphics::Primitive::Container->new;
my $tbox1 = Graphics::Primitive::TextBox->new(class => 'foo');
my $tbox2 = Graphics::Primitive::TextBox->new(name => 'bar');
$container->add_component($tbox1);
$container->add_component($tbox2);

my $res = $styler->apply($container);
ok($res, 'apply reports ok');

cmp_ok($tbox1->background_color->r, '==', 1, 'background-color applied');
cmp_ok($tbox1->border->left->width, '==', 3, 'border-width applied');
cmp_ok($tbox1->color->r, '==', 1, 'color applied');
cmp_ok($tbox1->font->family, 'eq', 'Arial', 'font-family applied');
cmp_ok($tbox1->font->weight, 'eq', 'bold', 'font-weight applied');
cmp_ok($tbox1->horizontal_alignment, 'eq', 'center', 'text-align applied');
cmp_ok($tbox1->vertical_alignment, 'eq', 'center', 'vertical-align applied');
cmp_ok($tbox1->padding->top, '==', 1, 'padding (top) applied');
cmp_ok($tbox1->padding->right, '==', 2, 'padding (right) applied');
cmp_ok($tbox1->padding->bottom, '==', 3, 'padding (bottom) applied');
cmp_ok($tbox1->padding->left, '==', 4, 'padding (left) applied');


cmp_ok($tbox2->background_color->as_css_hex, 'eq', '#f0f8ff', 'name background_color applied');
cmp_ok($tbox2->border->bottom->width, '==', 1, 'border-top-width applied');
cmp_ok($tbox2->border->left->width, '==', 2, 'border-left-width applied');
cmp_ok($tbox2->border->right->width, '==', 3, 'border-right-width applied');
cmp_ok($tbox2->border->top->color->g, '==', 1, 'border-top-color applied');
cmp_ok($tbox2->border->top->width, '==', 4, 'border-top-width applied');
cmp_ok($tbox2->font->size, '==', 7, 'font size applied');
cmp_ok($tbox2->margins->top, '==', 1, 'margin (top) applied');
cmp_ok($tbox2->margins->right, '==', 2, 'margins (right) applied');
cmp_ok($tbox2->margins->bottom, '==', 3, 'margins (bottom) applied');
cmp_ok($tbox2->margins->left, '==', 4, 'margins (left) applied');
