#/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

package Test::JSON;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

has_field 'json_data' => (
	type=>'JSON', 
	data => { a => 1, b => [ 2, 'three'] },
	do_minify => 1,
);

has_field 'json_data_field' => (
	type=>'JSON', 
);
sub data_json_data_field {
	my $self = shift;
	return { a => 1, b => [ 2, 'three'] };
}

has_field 'json_data_method' => (
	type=>'JSON', 
	set_data => "json_data_factory",
	data_key => 'json_data_field',
);
sub json_data_factory {
	my $self = shift;
	return { a => 1, b => [ 2, 'three'] };
}

has_field 'json_data_specialK' => (
	type=>'JSON', 
	data => { a => 1, b => [ 2, 'three'] },
	data_key => 'specialK',
	do_minify => 1,
);

has_field 'json_data_opts' => (
	type=>'JSON', 
	data => { a => 1, b => [ 2, 'three'] },
	json_opts => { pretty => 0 },
	do_minify => 0,
);

has_field 'json_data_property' => (
	type=>'JSON', 
	do_minify => 1,
	set_data => "json_data_factory",
	data_key => 'jsObject.',
);

has_field 'json_data_object' => (
	type=>'JSON', 
	do_minify => 1,
	set_data => "json_data_factory",
	data_key => '.jsProperty',
);

has_field 'json_data_objectProperty' => (
	type=>'JSON', 
	do_minify => 1,
	set_data => "json_data_factory",
	data_key => 'jsObject.jsProperty',
);

no HTML::FormHandler::Moose;

package ::main;

use_ok('Test::JSON');

my $form = Test::JSON->new();

ok($form, 'get form');

$form->process();

ok($form->field('json_data')->render, 'OK json_data');

my $expected = q(
<script type="text/javascript">var json_data={"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data')->render eq $expected, 'json_data minified render OK') || diag($form->field('json_data')->render);

$expected = q(
<script type="text/javascript">
  var json_data = {
   "a" : 1,
   "b" : [
      2,
      "three"
   ]
};
</script>);

$form->field('json_data')->do_minify(0);
ok($form->field('json_data')->render eq $expected, 'json_data original render OK') || diag($form->field('json_data')->render);

$expected = q(
<script type="text/javascript">
  var json_data_field = {
   "a" : 1,
   "b" : [
      2,
      "three"
   ]
};
</script>);

ok($form->field('json_data_field')->render  eq $expected, 'json_data_field render OK')  || diag($form->field('json_data_field')->render);

ok($form->field('json_data_method')->render eq $expected, 'json_data_method render OK') || diag($form->field('json_data_method')->render);

$expected = q(
<script type="text/javascript">var specialK={"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data_specialK')->render eq $expected, 'json_data_specialK render OK') || diag($form->field('json_data_specialK')->render);

$expected = q(
<script type="text/javascript">
  var json_data_opts = {"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data_opts')->render eq $expected, 'json_data_opts render OK') || diag($form->field('json_data_opts')->render);

$expected = q(
<script type="text/javascript">jsObject.json_data_property={"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data_property')->render eq $expected, 'json_data_property render OK') || diag($form->field('json_data_property')->render);

$expected = q(
<script type="text/javascript">json_data_object.jsProperty={"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data_object')->render eq $expected, 'json_data_object render OK') || diag($form->field('json_data_object')->render);

$expected = q(
<script type="text/javascript">jsObject.jsProperty={"a":1,"b":[2,"three"]};
</script>);

ok($form->field('json_data_objectProperty')->render eq $expected, 'json_data_objectProperty render OK') || diag($form->field('json_data_objectProperty')->render);

done_testing;

1;
