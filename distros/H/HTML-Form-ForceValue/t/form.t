#!perl -w

use strict;
use Test::More tests => 8;

use HTML::Form;

my $f = HTML::Form->parse(<<EOT, base=>"http://www.example.com");
<form action="http://example.com/">
  <input type='checkbox' name='check_box' checked="checked" />
  <select name='single_select'>
    <option>foo</option>
    <option>bar</option>
    <option>baz</option>
  </select>
</form>
EOT

$f->strict(1) if $f->can('strict');

eval { $f->value(single_select => 'quux') };
like($@, qr/illegal value/i, "can't set select element to invalid option");

eval { $f->value(single_select => 'fingo') };
like($@, qr/illegal value/i, "can't set select element to invalid option");

eval { $f->find_input('single_select')->force_value('fingo') };
like($@, qr/method/, "no force_value method yet");

{
  my $none_such = $f->find_input('none_such');
  is($none_such, undef, "no none_such input");
}

use_ok('HTML::Form::ForceValue');

eval { $f->find_input('single_select')->force_value('fingo') };
is($@, '', "using force_value forces it");

eval { $f->force_value(none_such => '10'); };
is($@, '', 'using force_value creates a non-existent field');
is($f->value('none_such'), 10, "and the value is correct");
