use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Object::WithIntAndString') };

SCOPE: {
  my $o = Object::WithIntAndString->newIntAndString("Hello", 54);
  check_obj($o);

  is($o->GetInt(), 54);
  is($o->GetString(), "Hello");

  $o->SetInt(2);
  is($o->GetInt(), 2);
  $o->SetString("foo");
  is($o->GetString(), "foo");
}

SCOPE: {
  my $o = Object::WithIntAndString->new;
  check_obj($o);

  is($o->GetInt(), 0);
  is($o->GetString(), "");

  $o->SetInt(3);
  is($o->GetInt(), 3);
  $o->SetString("fOo");
  is($o->GetString(), "fOo");
}


sub check_obj {
  my $o = shift;
  isa_ok($o, 'Object::WithIntAndString');
  can_ok($o, $_) foreach qw(new SetString SetInt GetInt GetString Sum);
  ok(!$o->can($_)) foreach qw(SetValue);
}
