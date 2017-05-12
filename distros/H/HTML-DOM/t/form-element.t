#!/usr/bin/perl -T

# This script tests the following DOM interfaces:
#    HTMLFormElement
#    HTMLSelectElement
#    HTMLOptGroupElement
#    HTMLOptionElement
#    HTMLOptionsCollection
#    HTMLInputElement
#    HTMLTextAreaElement
#    HTMLButtonElement
#    HTMLLabelElement
#    HTMLFieldSetElement
#    HTMLLegendElement

# Note: Some attributes are supposed to have their values normalised when
# accessed through the DOM 0 interface. For this reason, some attributes,
# particularly ‘align’, have weird capitalisations of their values when
# they are set. This is intentional.

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;
use Scalar::Util 'refaddr';
use HTML::DOM;

# Each call to test_attr or test_event runs 3 tests.

sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}

{
	my ($evt,$targ);
	my $eh = sub{
		($evt,$targ) = ($_[0]->type, shift->target);
	};
	
	sub test_event {
		my($obj, $event) = @_;
		($evt,$targ) = ();
		my $class = (ref($obj) =~ /[^:]+\z/g)[0];
		$obj->addEventListener($event=>$eh);
		is_deeply [$obj->$event], [],
			"return value of $class\'s $event method";
		is $evt, $event, "$class\'s $event method";
		is refaddr $targ, refaddr $obj, 
			"$class\'s $event event is on target";
		$obj->removeEventListener($event=>$eh);
	}

	END { undef $targ; } # Be nice to Devel::Object::Leak
}

my $doc = new HTML::DOM;	
my $form;

# A useful value for testing boolean attributes:
{package false; use overload 'bool' => sub {0}, '""'=>sub{"oenuueo"};}
my $false = bless [], 'false';

# -------------------------#
use tests 35; # HTMLFormElement

{
	is ref(
		$form = $doc->createElement('form'),
	), 'HTML::DOM::Element::Form',
		"class for form";
	;
	$form->attr(name => 'Fred');
	$form->attr('accept-charset' => 'utf-8');
	$form->attr(action => 'http:///');
	$form->attr(enctype => '');
	$form->attr(method => 'GET');
	$form->attr(target => 'foo');
	
	test_attr $form, qw/ name Fred George /;
	test_attr $form, qw/ acceptCharset utf-8 iso-8859-1 /;
	test_attr $form, qw/ action http:\/\/\/ http:\/\/remote.host\/ /;
	test_attr $form, enctype=>'',q/application\/x-www-form-urlencoded/;
	test_attr $form, qw| encoding application/x-www-form-urlencoded
	                     multipart/form-data |;
	test_attr $form, qw/ method get post /;
	test_attr $form, qw/ target foo phoo /;

	my $elements = $form->elements;
	isa_ok $elements, 'HTML::DOM::Collection::Elements';

	is $elements->length, 0, '$elements->length eq 0';
	is $form->length, 0, '$form->length eq 0';

	for (1..3) {
		(my $r = $doc->createElement('input'))
			->name('foo');
		$r->type('radio'); 
		$form->appendChild($r);
	}
	{
		# Make sure image buttons are ignored
		(my $r = $doc->createElement('input'))->type('image');
		$r->value("SIGN IN");
		$form->appendChild($r);
	}
	# ~~~ We need to test all possible formie types.

	is $form->length, 3, '$form->length';
	is $elements->length, 3., '$elements->length';

	# These two test that the event actually occurs:
	test_event $form, 'submit';
	test_event $form, 'reset';

	# These check for the default behaivour (reset doesn’t work yet):
	my $which;
	$form	->appendChild(my $el = $doc->createElement('input'))
		->type('submit');
	$form->addEventListener(submit => sub { $which .= '-form submit'});
	$form->addEventListener(reset => sub { $which .= '-form reset'});
	$el->addEventListener(click => sub { $which .= '-button'});
	$el->addEventListener(DOMActivate => sub { $which .= '-activate'});
	$el->click();
	$el->attr(type=>'reset');
	$el->click;
	is $which,
	   '-button-activate-form submit-button-activate-form reset',
		'default actions for form events';
	$which = '';
	$form	->appendChild($el = $doc->createElement('button'));
	$el->addEventListener(click => sub { $which .= '-button'});
	$el->addEventListener(DOMActivate => sub { $which .= '-activate'});
	$el->click();
	$el->attr(type=>'reset');
	$el->click;
	is $which,
	   '-button-activate-form submit-button-activate-form reset',
		'default actions for form events triggered by <button>s';
	# ~~~ I need tests to make sure that form elements are actually
	#     reset. Currently they are not.
}

# -------------------------#
use tests 49; # HTMLSelectElement and HTMLOptionsCollection

SKIP: { skip 'not written yet', 5; # ~~~ just a guess
use tests 5;
# ~~~ I need to write tests that make sure that H:D:NodeList::Magic's
#     STORE and DELETE methods call ->ownerDocument on the detached node.
#     (See the comment in H:D:Node::replaceChild for what it's for.)
}

{
	is ref(
		my $elem = $doc->createElement('select'),
	), 'HTML::DOM::Element::Select',
		"class for select";
	$elem->appendChild(my $opt1 = $doc->createElement('option'));
	$elem->appendChild(my $opt2 = $doc->createElement('option'));
	
	is $elem->[0], $opt1, 'select ->[]';
	$opt1->attr('selected', 'selected');
	$opt1->attr('value', 'foo');
	$opt2->attr('value', 'bar');
	
	is $elem->type, 'select-one', 'select ->type';
	is $elem->value, 'foo', 'select value';
	test_attr $elem, selectedIndex => 0, 1;
	is $elem->value, 'bar', 'select value again';
	is $elem->length, 2, 'select length';
	
	$form->appendChild($elem);
	is $elem->form ,$form, 'select form';

	my $opts = options $elem;
	isa_ok $opts, 'HTML::DOM::Collection::Options';
	isa_ok tied @$elem, 'HTML::DOM::NodeList::Magic',
		'tied @$select'; # ~~~ later I’d like to change this to
		# check whether @$elem and @$opts are the same array, but
		# since they currently are not (an implementation defici-
		# ency), I can’t do that yet.

	is $opts->[0], $opt1, 'options ->[]';
	$opts->[0] = undef;
	is $opts->[0], $opt2, 'undef assignment to options ->[]';
	is $opts->length, 1, 'options length';
	eval{$opts->length(323)};
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
		'error thrown by options->length';

	ok!$elem->disabled              ,     'select: get disabled';
	ok!$elem->disabled(1),          , 'select: set/get disabled';
	ok $elem->disabled              ,     'select: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'select’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'select’s disabled is deleted when set to false';
	ok!$elem->multiple              ,     'select: get multiple';
	ok!$elem->multiple(1),          , 'select: set/get multiple';
	ok $elem->multiple              ,     'select: get multiple again';
	is $elem->getAttribute('multiple'), 'multiple',
	 'select’s multiple is set to "multiple" when true';
	$elem->multiple($false);
	is $elem->attr('multiple'), undef,
	 'select’s multiple is deleted when set to false';
	$elem->name('foo');
	$elem->size(5);
	$elem->tabIndex(3);
	test_attr $elem, qw/ name     foo bar /;
	test_attr $elem, qw/ size     5   1   /;
	test_attr $elem, qw/ tabIndex 3   4   /;

	is $elem->add($opt1, $opt2), undef, 'return value of select add';
	is join('',@$elem), "$opt1$opt2", 'select add';
	$elem->add(my $opt3 = $doc->createElement('option'), undef);

	is $elem->[2], $opt3, 'select add with null 2nd arg';
	$elem->remove(1);
	is $elem->[1], $opt3, 'select remove';

	test_event $elem, 'blur';
	test_event $elem, 'focus';

	$elem->multiple(1);
	is $elem->type, 'select-multiple', 'multiple select ->type';
	$elem->[0]->selected(1);
	$elem->[1]->selected(1);
	is $elem->selectedIndex, 0, 'selectedIndex with multiple';
	$elem->[0]->selected(0);
	is $elem->selectedIndex, 1, 'selectedIndex with multiple (2)';
	$elem->[1]->selected(0);
	is $elem->selectedIndex, -1, 'selectedIndex with multiple (2)';
}

# -------------------------#
use tests 9; # HTMLOptGroupElement

{
	is ref(
		my $elem = $doc->createElement('optgroup'),
	), 'HTML::DOM::Element::OptGroup',
		"class for optgroup";

	ok!$elem->disabled            ,     'optgroup: get disabled';
	ok!$elem->disabled(1),        , 'optgroup: set/get disabled';
	ok $elem->disabled            ,     'optgroup: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'optgroup’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'optgroup’s disabled is deleted when set to false';

	$elem->attr(label => 'foo');
	test_attr $elem, qw;label   foo bar;;
}

# -------------------------#
use tests 31; # HTMLOptionElement

{
	is ref(
		my $elem = $doc->createElement('option'),
	), 'HTML::DOM::Element::Option',
		"class for option";

	is_deeply [$elem->form], [], 'option->form when there isn’t one';
	$form->appendChild(my $sel = $doc->createElement('select'));
	($form->content_list)[-1]->appendChild($elem);
	is $elem->form, $form, 'option->form';
	
	$elem->attr(selected => 1);
	ok $elem->defaultSelected,
		'option->defaultSelected reflects the selected attribute';
	ok $elem->defaultSelected(0),  'option: set/get defaultSelected';
	ok!$elem->defaultSelected,     'option: get defaultSelected again';
	$elem->defaultSelected(1);
	is $elem->getAttribute('selected'), 'selected',
	 'option’s selected is set to "selected" when defaultSelected';
	$elem->defaultSelected($false);
	is $elem->attr('selected'), undef,
	 'option’s selected is deleted when defaultSelected is false';
	
	is $elem->text, '', 'option->text when empty';
	$elem->appendChild($doc->createTextNode(''));
	is $elem->text, '', 'option->text when blank';
	$elem->firstChild->data('foo');
	is $elem->text, 'foo', 'option->text when set to something';

	# I don’t know whether this is valid, but I’m supporting it anyway:
	$elem->appendChild(my $p = $doc->createElement('p'));
	$p->appendChild($doc->createTextNode('fffoo'));
	is $elem->text, 'foofffoo', 'option->text w/ multiple child nodes';	$elem->splice_content(-1,1);

	is $elem->index, 0, 'option->index';
	($form->content_list)[-1]->unshift_content(
		$doc->createElement('option'));
	is $elem->index, 1, 'option->index again';

	ok!$elem->disabled            ,     'option: get disabled';
	ok!$elem->disabled(1),        , 'option: set/get disabled';
	ok $elem->disabled            ,     'option: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'option’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'option’s disabled is deleted when set to false';

	$elem->attr(label => 'foo');
	test_attr $elem, qw;label   foo bar;;

	$elem->defaultSelected(1);
	ok $elem->selected,
		'option->selected is taken from the attr by default';
	ok $elem->selected(0), 'set/get option->selected';
	ok $elem->selected, 'set option->selected didn’t work';
	$sel->multiple(1); $elem->selected(0);
	ok!$elem->selected, 'set option->selected worked';
	ok $elem->defaultSelected, 'and defaultSelected was unaffected';

	# Make sure that selected can be set when the option is orphaned.
	{
		use tests 2; # just the tests in this block
		my $sel = $doc->createElement('select');
		my $opt = $doc->createElement('option');
		ok eval{
		 $opt->selected(1); 1
		}, 'opt->selected does not die when opt is orphaned';
		$sel->selectedIndex; # it used to cache this
		$sel->appendChild($_)
		 for $doc->createElement('option'), $opt;
		is $sel->selectedIndex, 1,
		 'opt->selected affects selectIndex when unorphaned';
	}

	test_attr $elem, value => 'foo', 'bar';; # gets its value from text
	is $elem->text,'foo', 'text is unaffected when value is set';
	
}

# -------------------------#
use tests 76; # HTMLInputElement

{
	is ref(
		my $elem = $doc->createElement('input'),
	), 'HTML::DOM::Element::Input',
		"class for input";

	$elem->attr(value => 'foo');
	test_attr $elem, qw/defaultValue foo bar/;

	ok!$elem->defaultChecked   ,     'input: get defaultChecked';
	ok!$elem->defaultChecked(1), 'input: set/get defaultChecked';
	ok $elem->attr('checked')  ,
		'defaultChecked is linked to the checked attribute';
	ok $elem->defaultChecked   ,     'input: get defaultChecked again';
	is $elem->getAttribute('checked'), 'checked',
	 'input’s checked is set to "checked" when defaultChecked is true';
	$elem->defaultChecked($false);
	is $elem->attr('checked'), undef,
	 'input’s checked is deleted when defaultChecked is set to false';

	is_deeply [$elem->form], [], 'input->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'input->form';
	
	$elem->attr(accept    => 'text/plain,text/richtext');
	$elem->attr(accesskey => 'F');
	$elem->attr(align     => 'tOp');
	$elem->attr(alt       => '__');
	no warnings qw)qw);
	test_attr $elem, qw-accept    text/plain,text/richtext
	                                                  application/pdf-;
	test_attr $elem, qw-accessKey F                   G              -;
	test_attr $elem, qw-align     top                 middle         -;
	test_attr $elem, qw-alt       __                  KanUreediss?   -;

	$elem->defaultChecked(1);
	$elem->checked(0);
	ok $elem->defaultChecked,
		'changing input->checked does not affect defaultChecked';
	ok!$elem->checked            ,     'input: get checked';
	ok!$elem->checked(1),        , 'input: set/get checked';
	ok $elem->checked            ,     'input: get checked again';

	ok!$elem->disabled            ,     'input: get disabled';
	ok!$elem->disabled(1),        , 'input: set/get disabled';
	ok $elem->disabled            ,     'input: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'input’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'input’s disabled is deleted when set to false';

	$elem->attr(maxlength  => 783);
	$elem->attr(name => 'Achaimenides');
	test_attr $elem, qw-maxLength    783 94-;
	test_attr $elem, qw-name Achaimenides Gormistas-;

	$elem->attr(readonly => 1);
	ok $elem->readOnly            ,     'input: get readOnly';
	ok $elem->readOnly(0),        , 'input: set/get readOnly';
	ok!$elem->readOnly            ,     'input: get readOnly again';
	$elem->readOnly(1);
	is $elem->getAttribute('readonly'), 'readonly',
	 'input’s readonly is set to "readonly" when true';
	$elem->readOnly($false);
	is $elem->attr('readonly'), undef,
	 'input’s readonly is deleted when set to false';

	$elem->attr(size  => 783);
	$elem->attr(src => 'arnold.gif');
	$elem->attr(tabindex => '7');
	test_attr $elem, qw-size     783        94    -;
	test_attr $elem, qw-src      arnold.gif fo.pdf-;
	test_attr $elem, qw-tabIndex 7          8     -;

	$elem->attr(type => 'suBmit');
	test_attr $elem, qw-type submit password-;

	$elem->attr(usemap => 1);
	ok $elem->useMap            ,     'input: get useMap';
	ok $elem->useMap(0),        , 'input: set/get useMap';
	ok!$elem->useMap            ,     'input: get useMap again';

	$elem->attr(value => '$6.00');
	test_attr $elem, qw-value     $6.00 £6.00-;
	is $elem->attr('value'), '$6.00',
		'modifying input->value leaves the value attr alone';

	$doc->default_event_handler_for(click=>undef);
	test_event($elem,$_) for qw/ blur focus select click /;

	# ->checked(1) on a radio button
	my $form = $doc->createElement('form');
	$form->innerHTML("<input type=radio name=c>"x2);
	($elem = $form->childNodes->[0])->checked(1);
	$form->childNodes->[1]->checked(1);
	ok !$elem->checked,
	 "->checked(1) on a radio button unchecks other buttons";
}

# -------------------------#
use tests 48; # HTMLTextAreaElement

{
	is ref(
		my $elem = $doc->createElement('textarea'),
	), 'HTML::DOM::Element::TextArea',
		"class for textarea";

	is $elem->defaultValue, '', 'textarea->defaultValue when empty';
	$elem->appendChild($doc->createTextNode(''));
	is $elem->defaultValue, '', 'textarea->defaultValue when blank';
	$elem->firstChild->data('foo');
	test_attr $elem, qw/defaultValue foo bar/;
	is $elem->firstChild->data, 'bar',
		'setting textarea->defaultValue modifies its child node';

	is_deeply [$elem->form], [], 'textarea->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'textarea->form';
	
	$elem->attr(accesskey => 'F');
	$elem->attr(cols      => 7   );
	test_attr $elem, qw-accessKey F                   G              -;
	test_attr $elem, qw-cols      7                   89             -;

	ok!$elem->disabled            ,     'textarea: get disabled';
	ok!$elem->disabled(1),        , 'textarea: set/get disabled';
	ok $elem->disabled            ,     'textarea: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'textarea’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'textarea’s disabled is deleted when set to false';

	$elem->attr(name => 'Achaimenides');
	test_attr $elem, qw-name Achaimenides Gormistas-;

	$elem->attr(readonly => 1);
	ok $elem->readOnly            ,     'textarea: get readOnly';
	ok $elem->readOnly(0),        , 'textarea: set/get readOnly';
	ok!$elem->readOnly            ,     'textarea: get readOnly again';
	$elem->readOnly(1);
	is $elem->getAttribute('readonly'), 'readonly',
	 'textarea’s readonly is set to "readonly" when true';
	$elem->readOnly($false);
	is $elem->attr('readonly'), undef,
	 'textarea’s readonly is deleted when set to false';

	$elem->attr(rows  => 783);
	$elem->attr(tabindex => '7');
	test_attr $elem, qw-rows     783        94    -;
	test_attr $elem, qw-tabIndex 7          8     -;

	is $elem->type, 'textarea', 'textarea->type';

	$elem->defaultValue('$6.00');
	test_attr $elem, qw-value     $6.00 £6.00-;
	is $elem->defaultValue, '$6.00',
		'modifying input->value leaves the default value alone';

	test_event($elem,$_) for qw/ blur focus select /;
}

# -------------------------#
use tests 21; # HTMLButtonElement

{
	is ref(
		my $elem = $doc->createElement('button'),
	), 'HTML::DOM::Element::Button',
		"class for button";

	is_deeply [$elem->form], [], 'button->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'button->form';
	
	$elem->attr(accesskey => 'F');
	test_attr $elem, qw-accessKey F                   G              -;

	ok!$elem->disabled            ,     'button: get disabled';
	ok!$elem->disabled(1),        , 'button: set/get disabled';
	ok $elem->disabled            ,     'button: get disabled again';
	is $elem->getAttribute('disabled'), 'disabled',
	 'button’s disabled is set to "disabled" when true';
	$elem->disabled($false);
	is $elem->attr('disabled'), undef,
	 'button’s disabled is deleted when set to false';

	$elem->attr(name => 'Achaimenides');
	test_attr $elem, qw-name Achaimenides Gormistas-;

	$elem->attr(tabindex => '7');
	$elem->attr(value => 'not much');
	test_attr $elem, qw-tabIndex 7          8     -;
	test_attr $elem,    value=> 'not much','a lot' ;

	$elem->attr(type => 'bUtton');
	is $elem->type, 'button', 'button->type';
}

# -------------------------#
use tests 9; # HTMLLabelElement

{
	is ref(
		my $elem = $doc->createElement('label'),
	), 'HTML::DOM::Element::Label',
		"class for label";

	is_deeply [$elem->form], [], 'label->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'label->form';
	
	$elem->attr(accesskey => 'F');
	$elem->attr(for       => 'me');
	test_attr $elem, qw-accessKey F  G   -;
	test_attr $elem, qw-htmlFor   me &you-;
}

# -------------------------#
use tests 3; # HTMLFieldSetElement

{
	is ref(
		my $elem = $doc->createElement('fieldset'),
	), 'HTML::DOM::Element::FieldSet',
		"class for fieldset";

	is_deeply [$elem->form], [], 'fieldset->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'fieldset->form';
}

# -------------------------#
use tests 9; # HTMLLegendElement

{
	is ref(
		my $elem = $doc->createElement('legend'),
	), 'HTML::DOM::Element::Legend',
		"class for legend";

	is_deeply [$elem->form], [], 'legend->form when there isn’t one';
	$form->appendChild($elem);
	is $elem->form, $form, 'legend->form';

	$elem->attr(accesskey => 'F');
	$elem->attr(align     => 'LEFT');
	test_attr $elem, qw-accessKey F    G   -;
	test_attr $elem, qw-align     left right -;
}

# -------------------------#
use tests 7; # HTML::DOM::Collection::Elements

{
	my $elem = $doc->createElement('form');
	$elem->appendChild($doc->createElement('input')) for 1..4;
	$_->type('checkbox'), $_->name('foo') for ($elem->childNodes)[0,1];
	$_->type('radio'), $_->name('bar') for ($elem->childNodes)[2,3];
	
	ok $elem->elements->{foo}->DOES('HTML::DOM::NodeList'),
		'hdce returns a nodelist for multiple equinominal elems';
	ok $elem->elements->{bar}->DOES('HTML::DOM::NodeList'),
		'but let’s check it again, just to be sure';
	is $elem->elements->{foo}->[0], $elem->childNodes->[0],
		'contents of hdce’s special node lists (1)';
	is $elem->elements->{foo}->[1], $elem->childNodes->[1],
		'contents of hdce’s special node lists (2)';
	is $elem->elements->{bar}->[0], $elem->childNodes->[2],
		'contents of hdce’s special node lists (3)';
	is $elem->elements->{bar}->[1], $elem->childNodes->[3],
		'contents of hdce’s special node lists (4)';
	my $foo = $elem->elements->{bar};
	ok $foo->length,
		'the nodelist returned by the collection continues to ' .
		'work when the nodelist is out of scope';
		# I mistakenly had a misplaced weaken() during development.
}

# -------------------------#
use tests 7; # reset

{
	my $doc = new HTML::DOM;
	$doc->write('
		<title></title>
		<form name=f>
			<input type=radio name=foo checked id=foo1>
			<input type=radio name=foo id=foo2>
			<input type=checkbox checked name=chek1>
			<input type=checkbox name=chek2>
			<input type=text name=tekxt value=defufou>
			<input type=password name=etet value=",fdbjq">
			<select name=multi multiple>
				<option selected>
				<option selected>
				<option>
				<option>
			</select>
			<select name=cyngle>
				<option>
				<option selected>
				<option>
				<option>
			</select>
		</form>
	');
	$doc->close();

	my $form = $doc->{f};
	$form->{foo}[1]->checked(1);
	$form->{chek1}->checked(0);
	$form->{chek2}->checked(1);
	$form->{tekxt}->value('onhoen');
	$form->{etet}->value('-ontotneh');
	for($form->{multi}) {
		$_->[1]->selected(0);
		$_->[3]->selected(1);
	}
	$form->{cyngle}->selectedIndex(2);

	$form->reset; # Wham!

	ok $form->{foo}[0]->checked,                      'A whole buncha';
	ok $form->{chek1}->checked,                        ' tests that';
	ok !$$form{chek2}->checked,                         ' see whether';
	is $$form{tekxt}->value, 'defufou',                 ' the various';
	is $$form{etet}->value, ',fdbjq',                  ' formies were';
	is join(',', grep selected $_, @{$$form{multi}}),
	   join(',', @{$$form{multi}}[0,1]),             ' reset properly';
	is $$form{cyngle}->selectedIndex, 1;
}

# -------------------------#
use tests 29; # magic element-form association
{
 # Every element of this array has three tests to go with it
 my @formies = qw 'select input textarea button label fieldset object';

 $doc->innerHTML( '<table><tR><td><form><td><selecT></select><input>
                   <textarea></textarea><button></button><label></label>
                   <fieldset></fieldset><object></object>' );
 my $form = $doc->forms->[0];
 for(@formies) {
  is $doc->find($_)->form, $form,
   "The parser magically links $_ elements to implicitly closed forms.";
 }
 is $form->elements->length, 4,
  'form->elements lists the magically linked items';
 is +()=$form->elements, 4, # yes, this test actually failed in 0.028
  'form->elements lists the magically linked items in list context';
 my $td = ($doc->find('td'))[1];
 for(@formies) {
  my $elem = $doc->find($_);
  $td->removeChild($elem);
  is +()=$elem->form, 0,
    "The magic link on $_ elements is broken when the node is removed.";
  $td->appendChild($elem);
  is +()=$elem->form, 0,
    "The link on $_ elements is not restored when the node is put back.";
 }
 is $form->elements->length, 0,
  'The magically linked items are no longer listed in form->elements.';
 $doc->innerHTML( '<table><tr><td><form><td><form></form><input>' );
 is $doc->forms->[0], $doc->find('input')->form,
  '<td><form><td><form></form><input> links input to the first form';
 $doc->innerHTML( '<table><tr><td><form><td><form><td><input>' );
 is $doc->forms->[1], $doc->find('input')->form,
  '<td><form><td><form><td><input> links input to the second form';
 $doc->innerHTML('<p>');
 $doc->body->innerHTML( '<table><tr><td><form><td><input>' );
 is +()=$doc->find('input')->form, 0,
  'elem->innerHTML creates no magical form element associations';

 # Make sure that the current magic form does not get inputs from other
 # forms associated with it.
 $doc->innerHTML('<div><form></div><form><input>');
 is $doc->forms->[0]->elements->length, 0,
  'magic forms are not attached inputs that are inside other forms';
 is $doc->forms->[1]->elements->length, 1,
  'magic forms do not steal inputs from other forms';
}

# ~~~ I need to write tests for HTML::DOM::Collection::Elements’s namedItem
#     method. In .009 it dies if there are radio buttons. I don’t think it
#     works for more than two buttons.
