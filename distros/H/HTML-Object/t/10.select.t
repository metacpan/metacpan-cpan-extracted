#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Element::Select' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Element::Select' );
};

can_ok( 'HTML::Object::DOM::Element::Select', 'add' );
can_ok( 'HTML::Object::DOM::Element::Select', 'autofocus' );
can_ok( 'HTML::Object::DOM::Element::Select', 'blur' );
can_ok( 'HTML::Object::DOM::Element::Select', 'checkValidity' );
can_ok( 'HTML::Object::DOM::Element::Select', 'disabled' );
can_ok( 'HTML::Object::DOM::Element::Select', 'focus' );
can_ok( 'HTML::Object::DOM::Element::Select', 'item' );
can_ok( 'HTML::Object::DOM::Element::Select', 'labels' );
can_ok( 'HTML::Object::DOM::Element::Select', 'length' );
can_ok( 'HTML::Object::DOM::Element::Select', 'multiple' );
can_ok( 'HTML::Object::DOM::Element::Select', 'name' );
can_ok( 'HTML::Object::DOM::Element::Select', 'namedItem' );
can_ok( 'HTML::Object::DOM::Element::Select', 'onchange' );
can_ok( 'HTML::Object::DOM::Element::Select', 'oninput' );
can_ok( 'HTML::Object::DOM::Element::Select', 'options' );
can_ok( 'HTML::Object::DOM::Element::Select', 'remove' );
can_ok( 'HTML::Object::DOM::Element::Select', 'reportValidity' );
can_ok( 'HTML::Object::DOM::Element::Select', 'required' );
can_ok( 'HTML::Object::DOM::Element::Select', 'selectedIndex' );
can_ok( 'HTML::Object::DOM::Element::Select', 'selectedOptions' );
can_ok( 'HTML::Object::DOM::Element::Select', 'setCustomValidity' );
can_ok( 'HTML::Object::DOM::Element::Select', 'size' );
can_ok( 'HTML::Object::DOM::Element::Select', 'type' );
can_ok( 'HTML::Object::DOM::Element::Select', 'validationMessage' );
can_ok( 'HTML::Object::DOM::Element::Select', 'validity' );
can_ok( 'HTML::Object::DOM::Element::Select', 'value' );
can_ok( 'HTML::Object::DOM::Element::Select', 'willValidate' );

my $html = <<EOT;
<!doctype html>
<html>
    <head><title>Demo</title></head>
    <body>
        <select>
            <option id="un" value="one">One</option>
            <option id="deux" value="two" selected>Two</option>
            <option id="trois" value="three">Three</option>
        </select>
    </body>
</html>
EOT
my $p = HTML::Object::DOM->new;
my $doc = $p->parse_data( $html ) || BAIL_OUT( $p->error );
my $sel = $doc->getElementsByTagName( 'select' )->first;
isa_ok( $sel => 'HTML::Object::DOM::Element::Select' );
# XXX
# $sel->debug(4);
is( $sel->options->length, 3, 'select->options->length' );
is( $sel->selectedOptions->length, 1, 'select->selectedOptions->length' );
is( $sel->selectedIndex, 1, 'select->selectedIndex' );
ok( !$sel->options->first->defaultSelected, 'first option not selected' );
ok( $sel->options->second->defaultSelected, 'second option is selected' );
ok( !$sel->options->third->defaultSelected, 'third option not selected' );
my $elem = $sel->item(1);
isa_ok( $elem => 'HTML::Object::DOM::Element::Option' );
is( $elem->value, 'two', 'select->item(1)->value' );
ok( $elem->defaultSelected, 'defaultSelected' );

is( $sel->namedItem('un')->value, 'one', 'namedItem' );

# Adding an option
my $opt = $doc->createElement( 'option' );
$opt->value = 'four';
$opt->text  = 'Four';
$sel->add( $opt );
is( $sel->options->length, 4, 'select->options->length' );
# diag( $sel->as_string ) if( $DEBUG );

# Remove
my $rv = $sel->remove(1);
diag( "Possible error: ", $sel->error ) if( !defined( $rv ) && $DEBUG );
isa_ok( $rv, 'HTML::Object::DOM::Element::Option' );
is( $rv, $elem, 'remove' );
is( $sel->options->length, 3 );
is( $sel->selectedIndex, undef, 'select->selectedIndex' );
is( $sel->selectedOptions->length, 0, 'select->selectedOptions->length' );

subtest 'option' => sub
{
    $opt->defaultSelected = 1;
    ok( $opt->defaultSelected, 'defaultSelected' );
    ok( !$opt->disabled, 'disabled' );
    is( $opt->form, undef, 'form' );
    is( $opt->index, 2, 'index' );
    is( $opt->label, 'Four', 'label' );
    ok( $opt->selected, 'selected' );
    ok( $opt->attributes->has( 'selected' ), 'attribute selected exists' );
    is( $opt->text, 'Four', 'text' );
    is( $opt->value, 'four', 'value' );
    # Test setting values
    # $opt->debug( $DEBUG );
    $opt->label = "new element";
    ok( $opt->attributes->has( 'label' ), 'option has a label now' );
    is( $opt->label, 'new element', 'option->label = "some value"' );
    # diag( $opt->as_string ) if( $DEBUG );
    $opt->text = "Two + two";
    is( $opt->text, 'Two + two', 'option->text = "some value"' );
    $opt->value = 'Vier';
    is( $opt->value, 'Vier', 'option->value = "some value"' );
};

done_testing();

__END__

