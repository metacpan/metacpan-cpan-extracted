#!perl
use strict;
use warnings;
use utf8;
use Glib qw/TRUE FALSE/;
use Test::More;

use constant {
  MIN_INT64 => "-9223372036854775807",
  MAX_INT64 => "9223372036854775807",

  MIN_UINT64 => "0",
  MAX_UINT64 => "18446744073709551615"
};

if (Glib->CHECK_VERSION (2, 24, 0)) {
  plan tests => 223;
} else {
  plan skip_all => 'Need libglib >= 2.24';
}

my @leafs = (
  [ 'new_boolean', 'get_boolean', 'b', TRUE ],
  [ 'new_byte', 'get_byte', 'y', 2**8-1 ],
  [ 'new_int16', 'get_int16', 'n', 2**15-1 ],
  [ 'new_uint16', 'get_uint16', 'q', 2**16-1 ],
  [ 'new_int32', 'get_int32', 'i', 2**31-1 ],
  [ 'new_uint32', 'get_uint32', 'u', 2**32-1 ],
  [ 'new_int64', 'get_int64', 'x', MAX_INT64 ],
  [ 'new_uint64', 'get_uint64', 't', MAX_UINT64 ],
  [ 'new_handle', 'get_handle', 'h', 2**31-1 ],
  [ 'new_double', 'get_double', 'd', 0.25 ],
  [ 'new_string', 'get_string', 's', 'äöü⁂üöä' ],
  [ 'new_object_path', 'get_string', 'o', '/a/b/c' ],
  [ 'new_signature', 'get_string', 'g', 'ii' ],
);

{
  foreach my $l (@leafs) {
    my ($ctor, $getter, $type_string, $value) = @$l;
    note ($ctor);
    my $v = Glib::Variant->$ctor ($value);
    isa_ok ($v, 'Glib::Variant');
    isa_ok ($v->get_type, 'Glib::VariantType');
    ok ($v->is_of_type ($v->get_type));
    is ($v->get_type_string, $type_string);
    ok (!$v->is_container);
    is ($v->classify, $type_string);
    is ($v->$getter, $value);
  }

  ok (Glib::Variant::is_object_path ('/a/b/c'));
  ok (Glib::Variant::is_signature ('ii'));
}

note ('new_variant');
{
  {
    my $child = Glib::Variant->new_byte (23);
    my $wrapper = Glib::Variant->new_variant ($child);
    isa_ok ($wrapper, 'Glib::Variant');
    is ($wrapper->get_type_string, 'v');
    is ($wrapper->classify, 'v');
    {
      my $wrapped_child = $wrapper->get_variant;
      is ($wrapped_child->get_byte, 23);
    }
    undef $child;
    {
      my $wrapped_child = $wrapper->get_variant;
      is ($wrapped_child->get_byte, 23);
    }
  }
  {
    my $child = Glib::Variant->new_byte (23);
    my $wrapper = Glib::Variant->new_variant ($child);
    undef $wrapper;
    is ($child->get_byte, 23);
  }
}

note ('new_bytestring');
SKIP: {
  skip 'new_bytestring', 6
    unless Glib->CHECK_VERSION (2, 26, 0);

  {
    my $bs = "\x{a3}\x{ff}";
    my $v = Glib::Variant->new_bytestring ($bs);
    isa_ok ($v, 'Glib::Variant');
    is ($v->get_type_string, 'ay');
    is ($v->classify, 'a');
    is ($v->get_bytestring, $bs);
  }

  {
    my $bs = "\x{a3}\x{ff}";
    utf8::upgrade ($bs);
    my $v = Glib::Variant->new_bytestring ($bs);
    is ($v->get_bytestring, $bs);
  }

  {
    my $bs = "\x{a3}\x{ff}";
    utf8::encode ($bs);
    my $v = Glib::Variant->new_bytestring ($bs);
    is ($v->get_bytestring, $bs);
  }
}

note ('new_maybe');
{
  my $child_type = 'y';
  my $child = Glib::Variant->new_byte (42);
  {
    my $wrapper = Glib::Variant->new_maybe ($child_type, undef);
    isa_ok ($wrapper, 'Glib::Variant');
    is ($wrapper->get_type_string, 'my');
    is ($wrapper->classify, 'm');
    ok (! defined $wrapper->get_maybe);
    is ($wrapper->n_children, 0);
  }
  {
    my $wrapper = Glib::Variant->new_maybe (undef, $child);
    isa_ok ($wrapper, 'Glib::Variant');
    is ($wrapper->get_type_string, 'my');
    is ($wrapper->classify, 'm');
    is ($wrapper->get_maybe->get_byte, $child->get_byte);
    is ($wrapper->n_children, 1);
    is ($wrapper->get_child_value (0)->get_byte, 42);
  }
  {
    my $wrapper = Glib::Variant->new_maybe ($child_type, $child);
    isa_ok ($wrapper, 'Glib::Variant');
    is ($wrapper->get_type_string, 'my');
    is ($wrapper->classify, 'm');
    is ($wrapper->get_maybe->get_byte, $child->get_byte);
    is ($wrapper->n_children, 1);
    is ($wrapper->get_child_value (0)->get_byte, $child->get_byte);
  }
}

note ('new_array');
{
  my $child_type = 'y';
  my $children = [map { Glib::Variant->new_byte ($_) } (23, 42, 65)];
  {
    my $array = Glib::Variant->new_array ($child_type, []);
    isa_ok ($array, 'Glib::Variant');
    is ($array->get_type_string, 'ay');
    is ($array->classify, 'a');
    is ($array->n_children, 0);
  }
  {
    my $array = Glib::Variant->new_array (undef, $children);
    isa_ok ($array, 'Glib::Variant');
    is ($array->get_type_string, 'ay');
    is ($array->classify, 'a');
    is ($array->n_children, 3);
    is ($array->get_child_value (2)->get_byte, $children->[2]->get_byte);
  }
  {
    my $array = Glib::Variant->new_array ($child_type, $children);
    isa_ok ($array, 'Glib::Variant');
    is ($array->get_type_string, 'ay');
    is ($array->classify, 'a');
    is ($array->n_children, 3);
    is ($array->get_child_value (2)->get_byte, $children->[2]->get_byte);
  }
}

note ('new_tuple');
{
  my $children = [Glib::Variant->new_byte (23),
                  Glib::Variant->new_string ('forty-two'),
                  Glib::Variant->new_double (0.25)];
  {
    my $tuple = Glib::Variant->new_tuple ([]);
    isa_ok ($tuple, 'Glib::Variant');
    is ($tuple->get_type_string, '()');
    is ($tuple->classify, '(');
    is ($tuple->n_children, 0);
  }
  {
    my $tuple = Glib::Variant->new_tuple ($children);
    isa_ok ($tuple, 'Glib::Variant');
    is ($tuple->get_type_string, '(ysd)');
    is ($tuple->classify, '(');
    is ($tuple->n_children, 3);
    is ($tuple->get_child_value (2)->get_double, $children->[2]->get_double);
  }
}

note ('new_dict_entry');
{
  my $key = Glib::Variant->new_string ('forty-two');
  my $value = Glib::Variant->new_byte (23);
  {
    my $entry = Glib::Variant->new_dict_entry ($key, $value);
    isa_ok ($entry, 'Glib::Variant');
    is ($entry->get_type_string, '{sy}');
    is ($entry->classify, '{');
    is ($entry->get_child_value (1)->get_byte, $value->get_byte);
  }
}

note ('lookup_value');
SKIP: {
  skip 'lookup_value', 3
    unless Glib->CHECK_VERSION (2, 28, 0);
  my $entries = [map { Glib::Variant->new_dict_entry (Glib::Variant->new_string ($_->[0]),
                                                      Glib::Variant->new_byte ($_->[1])) }
                     (['one' => 1], ['two' => 2], ['four' => 4], ['eight' => 8])];
  my $array = Glib::Variant->new_array ('{sy}', $entries);
  is ($array->lookup_value ('one', 'y')->get_byte, 1);
  is ($array->lookup_value ('two', undef)->get_byte, 2);
  ok (! defined $array->lookup_value ('fourr', undef));
}

note ('printing and parsing');
{
  {
    my $a = Glib::Variant->new_byte (23);
    my $text = $a->print (TRUE);
    is ($text, 'byte 0x17');
    is (Glib::Variant::parse (undef, $text)->get_byte, 23);
    is (Glib::Variant::parse ('y', $text)->get_byte, 23);
  }

  SKIP: {
    skip 'parse error tests', 1
      unless Glib->CHECK_VERSION (2, 28, 0);
    my $text = 'byte 0x17';
    eval { Glib::Variant::parse ('b', $text)->get_byte };
    ok (Glib::Error::matches ($@, 'Glib::Variant::ParseError', 'type-error'));
  }
}

note ('misc.');
{
  my $a = Glib::Variant->new_byte (23);
  my $b = Glib::Variant->new_byte (42);

  ok (defined $a->get_size);
  ok (defined $a->hash);
  ok ($a->equal ($a));
  ok (! $a->equal ($b));
  is ($a->get_normal_form->get_byte, $a->get_byte);
  ok ($a->is_normal_form);
  is ($a->byteswap->get_byte, $a->get_byte);

  SKIP: {
    skip 'compare', 2
      unless Glib->CHECK_VERSION (2, 26, 0);
    cmp_ok ($a->compare ($b), '<', 0);
    cmp_ok ($b->compare ($a), '>', 1);
  }
}

note ('convenience constructor and accessor');
{
  note (' leafs');
  foreach my $l (@leafs) {
    my ($ctor, $getter, $type_string, $value) = @$l;
    my $v = Glib::Variant->new ($type_string, $value);
    is ($v->get_type_string, $type_string);
    is ($v->get ($type_string), $value);
  }

  note (' list context');
  {
    my ($v) = Glib::Variant->new ('i', 23);
    is ($v->get ('i'), 23);

    my ($v1, $v2, $v3) = Glib::Variant->new ('ids', 23, 0.25, 'äöü');
    is ($v1->get ('i'), 23);
    is ($v2->get ('d'), 0.25);
    is ($v3->get ('s'), 'äöü');
  }

  note (' variant');
  {
    my $child = Glib::Variant->new_byte (23);
    my $wrapper = Glib::Variant->new ('v', $child);
    is ($wrapper->get_type_string, 'v');
    {
      my $wrapped_child = $wrapper->get ('v');
      is ($wrapped_child->get_byte, 23);
    }
  }

  note (' array');
  {
    my $v1 = Glib::Variant->new ('as', ['äöü', 'Perl', '💑']);
    is_deeply ($v1->get ('as'), ['äöü', 'Perl', '💑']);

    my $v2 = Glib::Variant->new ('aai', [[23, 42], [2, 3], [4, 2]]);
    is_deeply ($v2->get ('aai'), [[23, 42], [2, 3], [4, 2]]);

    is (Glib::Variant->new ('ai', [])->n_children, 0);
    is (Glib::Variant->new ('ai', undef)->n_children, 0);
  }

  note (' maybe');
  {
    my $v1 = Glib::Variant->new ('mi', undef);
    ok (! defined $v1->get ('mi'));

    my $v2 = Glib::Variant->new ('mi', 23);
    is ($v2->get ('mi'), 23);

    my $v3 = Glib::Variant->new ('mai', undef);
    ok (! defined $v3->get ('mai'));

    my $v4 = Glib::Variant->new ('mai', [23, 42]);
    is_deeply ($v4->get ('mai'), [23, 42]);
  }

  note (' tuple');
  {
    my $v1 = Glib::Variant->new ('()');
    is ($v1->n_children, 0);

    my $v2 = Glib::Variant->new ('(si)', ['äöü', 23]);
    is_deeply ($v2->get ('(si)'), ['äöü', 23]);

    my $v3 = Glib::Variant->new ('a(si)', [['äöü', 23], ['Perl', 42], ['💑', 2342]]);
    is_deeply ($v3->get ('a(si)'), [['äöü', 23], ['Perl', 42], ['💑', 2342]]);
  }

  note (' dict entry');
  {
    my $v1 = Glib::Variant->new ('{si}', ['äöü', 23]);
    is_deeply ($v1->get ('{si}'), ['äöü', 23]);

    my $v2 = Glib::Variant->new ('a{si}', [['äöü', 23], ['Perl', 42], ['💑', 2342]]);
    is_deeply ($v2->get ('a{si}'), [['äöü', 23], ['Perl', 42], ['💑', 2342]]);

    my $v3 = Glib::Variant->new ('a{si}', {'äöü' => 23, 'Perl' => 42, '💑' => 2342});
    is_deeply ($v2->get ('a{si}'), [['äöü', 23], ['Perl', 42], ['💑', 2342]]);
  }
}

note ('variant dict');
SKIP: {
  skip 'dict', 12
    unless Glib->CHECK_VERSION (2, 40, 0);

  my $v = Glib::Variant->new ('a{sv}', {
    'äöü' => Glib::Variant->new_uint16 (23),
    'Perl' => Glib::Variant->new_uint32 (42),
    '💑' => Glib::Variant->new_uint64 (2342)});
  my $d = Glib::VariantDict->new ($v);

  ok ($d->contains ('äöü'));
  ok ($d->contains ('Perl'));
  ok ($d->contains ('💑'));

  is ($d->lookup_value ('äöü', 'q')->get_uint16 (), $v->lookup_value ('äöü', 'q')->get_uint16 ());
  is ($d->lookup_value ('Perl', 'u')->get_uint32 (), $v->lookup_value ('Perl', 'u')->get_uint32 ());
  is ($d->lookup_value ('💑', 't')->get_uint64 (), $v->lookup_value ('💑', 't')->get_uint64 ());

  $d->insert_value ('GNU', Glib::Variant->new_string ('RMS'));
  ok ($d->contains ('GNU'));
  ok ($d->remove ('GNU'));
  ok (not $d->contains ('GNU'));

  my $d_v = $d->end ();
  is ($d_v->lookup_value ('äöü', 'q')->get_uint16 (), $v->lookup_value ('äöü', 'q')->get_uint16 ());
  is ($d_v->lookup_value ('Perl', 'u')->get_uint32 (), $v->lookup_value ('Perl', 'u')->get_uint32 ());
  is ($d_v->lookup_value ('💑', 't')->get_uint64 (), $v->lookup_value ('💑', 't')->get_uint64 ());
}
