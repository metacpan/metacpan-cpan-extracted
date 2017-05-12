#/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

package Test::JavaScript;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

has_field 'javascript_code' => (
	type=>'JavaScript', 
	js_code => "    var testVar  =    'abc';",
	do_minify => 1,
);

has_field 'javascript_code_field' => (
	type=>'JavaScript', 
);
sub js_code_javascript_code_field {
	my $self = shift;
	return "var testVar = 'abc';";
}

has_field 'javascript_code_method_name' => (
	type=>'JavaScript', 
	set_js_code => "javascript_code_factory",
);
sub javascript_code_factory {
	my $self = shift;
	return "var testVar = 'abc';";
}

has_field 'javascript_code_method_ref' => (
	type=>'JavaScript', 
	render_method => \&javascript_tagcode_factory,
);
sub javascript_tagcode_factory {
	my $self = shift;
	return q(
<script type="text/javascript">
var testVar = 'abc';
</script>);
}


no HTML::FormHandler::Moose;

package ::main;

use_ok('Test::JavaScript');

my $form = Test::JavaScript->new();

ok($form, 'get form');

$form->process();

ok($form->field('javascript_code')->render, 'OK javascript_code');

my $expected = q(
<script type="text/javascript">var testVar='abc';
</script>);

ok($form->field('javascript_code')->render eq $expected, 'javascript_code minified render OK') || diag($form->field('javascript_code')->render);

$expected = q(
<script type="text/javascript">
    var testVar  =    'abc';
</script>);

$form->field('javascript_code')->do_minify(0);
ok($form->field('javascript_code')->render eq $expected, 'javascript_code original render OK') || diag($form->field('javascript_code')->render);

$expected = q(
<script type="text/javascript">
var testVar = 'abc';
</script>);

ok($form->field('javascript_code_field')->render  eq $expected, 'javascript_code_field render OK')  || diag($form->field('javascript_code_field')->render);

ok($form->field('javascript_code_method_name')->render eq $expected, 'javascript_code_method_name render OK') || diag($form->field('javascript_code_method_name')->render);

ok($form->field('javascript_code_method_ref')->render eq $expected, 'javascript_code_method_ref render OK') || diag($form->field('javascript_code_method_ref')->render);

done_testing;

1;
