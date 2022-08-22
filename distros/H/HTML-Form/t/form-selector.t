#!perl

use strict;
use warnings;

use Test::More tests => 12;
use HTML::Form;

my $form = HTML::Form->parse(<<"EOT", base => "http://example.com", strict => 1);
<form>
<input name="n1" id="id1" class="A" value="1">
<input id="id2" class="A" value="2">
<input id="id3" class="B" value="3">
<select id="id4">
   <option>1
   <option>2
   <option>3
</selector>
<input id="#foo" name="#bar" class=".D" disabled>
</form>
EOT

#$form->dump;

is($form->value("n1"), 1);
is($form->value("^n1"), 1);
is($form->value("#id1"), 1);
is($form->value(".A"), 1);
is($form->value("#id2"), 2);
is($form->value(".B"), 3);

is(j(map $_->value, $form->find_input(".A")), "1:2");

$form->find_input("#id2")->name("n2");
$form->value("#id2", 22);
is($form->click->uri->query, "n1=1&n2=22");

# try some odd names
is($form->find_input("##foo")->name, "#bar");
is($form->find_input("#bar"), undef);
is($form->find_input("^#bar")->class, ".D");
is($form->find_input("..D")->id, "#foo");

sub j {
    join(":", @_);
}
