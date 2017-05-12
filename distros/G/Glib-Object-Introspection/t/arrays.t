#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;
use utf8;

plan tests => 68;

ok (Regress::test_strv_in ([ '1', '2', '3' ]));

my $int_array = [ 1, 2, 3 ];
is (Regress::test_array_int_in ($int_array), 6);
is_deeply (Regress::test_array_int_out (), [0, 1, 2, 3, 4]);
# FIXME: This leaks.  See <https://bugzilla.gnome.org/show_bug.cgi?id=745336>.
is_deeply (Regress::test_array_int_inout ($int_array), [3, 4]);
is (Regress::test_array_gint8_in ($int_array), 6);
is (Regress::test_array_gint16_in ($int_array), 6);
is (Regress::test_array_gint32_in ($int_array), 6);
is (Regress::test_array_gint64_in ($int_array), 6);
is (Regress::test_array_gtype_in ([ 'Glib::Object', 'Glib::Int64' ]), "[GObject,gint64,]");
is (Regress::test_array_fixed_size_int_in ([ 1, 2, 3, 4, 5 ]), 15);
is_deeply (Regress::test_array_fixed_size_int_out (), [ 0, 1, 2, 3, 4 ]);
is_deeply (Regress::test_array_fixed_size_int_return (), [ 0, 1, 2, 3, 4 ]);
is_deeply (Regress::test_strv_out_container (), [ '1', '2', '3' ]);
is_deeply (Regress::test_strv_out (), [ 'thanks', 'for', 'all', 'the', 'fish' ]);
is_deeply (Regress::test_strv_out_c (), [ 'thanks', 'for', 'all', 'the', 'fish' ]);
is_deeply (Regress::test_strv_outarg (), [ '1', '2', '3' ]);

is_deeply (Regress::test_array_int_full_out (), [0, 1, 2, 3, 4]);
is_deeply (Regress::test_array_int_none_out (), [1, 2, 3, 4, 5]);
Regress::test_array_int_null_in (undef);
is (Regress::test_array_int_null_out, undef);

my $test_list = [1, 2, 3];
is_deeply (Regress::test_glist_nothing_return (), $test_list);
is_deeply (Regress::test_glist_nothing_return2 (), $test_list);
is_deeply (Regress::test_glist_container_return (), $test_list);
is_deeply (Regress::test_glist_everything_return (), $test_list);
Regress::test_glist_nothing_in ($test_list);
Regress::test_glist_nothing_in2 ($test_list);
Regress::test_glist_null_in (undef);
is (Regress::test_glist_null_out (), undef);

is_deeply (Regress::test_gslist_nothing_return (), $test_list);
is_deeply (Regress::test_gslist_nothing_return2 (), $test_list);
is_deeply (Regress::test_gslist_container_return (), $test_list);
is_deeply (Regress::test_gslist_everything_return (), $test_list);
Regress::test_gslist_nothing_in ($test_list);
Regress::test_gslist_nothing_in2 ($test_list);
Regress::test_gslist_null_in (undef);
is (Regress::test_gslist_null_out (), undef);

# -----------------------------------------------------------------------------

my $int_array_ref = [-1..2];
my $boxed_array_ref = [map { Glib::Boxed::new ('GI::BoxedStruct', long_ => $_) } (1, 2, 3)];
my $string_array_ref = [qw/0 1 2/];
my $byte_array_ref = [0, ord '1', 0xFF, ord '3'];

# Init-like.
SKIP: {
  skip 'init-like', 1
    unless check_gi_version (1, 32, 0);
  is_deeply ([GI::init_function ([qw/a b c/])], [Glib::TRUE, [qw/a b/]]);
}

# Fixed size.
is_deeply (GI::array_fixed_int_return (), $int_array_ref);
is_deeply (GI::array_fixed_short_return (), $int_array_ref);
GI::array_fixed_int_in ($int_array_ref);
GI::array_fixed_short_in ($int_array_ref);
is_deeply (GI::array_fixed_out (), $int_array_ref);
is_deeply (GI::array_fixed_out_struct (), [{long_ => 7, int8 => 6}, {long_ => 6, int8 => 7}]);
is_deeply (GI::array_fixed_inout ($int_array_ref), [reverse @$int_array_ref]);

# Variable size.
SKIP: {
  skip 'variable size', 7
    unless check_gi_version (1, 36, 0);
  is_deeply (GI::array_return (), $int_array_ref);
  is_deeply ([GI::array_return_etc (23, 42)], [[23, 0, 1, 42], 23+42]);
  GI::array_in ($int_array_ref);
  GI::array_in_len_before ($int_array_ref);
  GI::array_in_len_zero_terminated ($int_array_ref);
  GI::array_string_in ([qw/foo bar/]);
  GI::array_uint8_in ([map { ord } qw/a b c d/]);
  GI::array_struct_in ($boxed_array_ref);
  GI::array_struct_value_in ($boxed_array_ref);
  GI::array_struct_take_in ($boxed_array_ref);
  is ($boxed_array_ref->[2]->long_, 3);
  GI::array_simple_struct_in ([map { { long_ => $_ } } (1, 2, 3)]);
  GI::multi_array_key_value_in ([qw/one two three/],
                                [map { Glib::Object::Introspection::GValueWrapper->new ('Glib::Int', $_) } (1, 2, 3)]);
  GI::array_enum_in ([qw/value1 value2 value3/]);
  GI::array_in_guint64_len ($int_array_ref);
  GI::array_in_guint8_len ($int_array_ref);
  is_deeply (GI::array_out (), $int_array_ref);
  is_deeply ([GI::array_out_etc (23, 42)], [[23, 0, 1, 42], 23+42]);
  is_deeply (GI::array_inout ($int_array_ref), [-2..2]);
  is_deeply ([GI::array_inout_etc (23, $int_array_ref, 42)], [[23, -1, 0, 1, 42], 23+42]);
  GI::array_in_nonzero_nonlen (23, [map { ord } qw/a b c d/]);
}

# Zero-terminated.
SKIP: {
  skip 'zero-terminated', 5
    unless check_gi_version (1, 32, 0);
  is_deeply (GI::array_zero_terminated_return (), $string_array_ref);
  is (GI::array_zero_terminated_return_null (), undef);
  is_deeply ([map { $_->long_ } @{GI::array_zero_terminated_return_struct ()}],
             [42, 43, 44]);
  GI::array_zero_terminated_in ($string_array_ref);
  is_deeply (GI::array_zero_terminated_out (), $string_array_ref);
  is_deeply (GI::array_zero_terminated_inout ($string_array_ref), [qw/-1 0 1 2/]);
  # The variant stuff is tested in variants.t.
}

# GArray.
SKIP: {
  skip 'GArray', 11
    unless check_gi_version (1, 34, 0);
  is_deeply (GI::garray_int_none_return (), $int_array_ref);
  is_deeply (GI::garray_uint64_none_return (), [0, "18446744073709551615"]);
  is_deeply (GI::garray_utf8_none_return (), $string_array_ref);
  is_deeply (GI::garray_utf8_container_return (), $string_array_ref);
  is_deeply (GI::garray_utf8_full_return (), $string_array_ref);
  GI::garray_int_none_in ($int_array_ref);
  GI::garray_uint64_none_in ([0, "18446744073709551615"]);
  GI::garray_utf8_none_in ($string_array_ref);
  is_deeply (GI::garray_utf8_none_out (), $string_array_ref);
  is_deeply (GI::garray_utf8_container_out (), $string_array_ref);
  is_deeply (GI::garray_utf8_full_out (), $string_array_ref);
  # FIXME: is_deeply (GI::garray_utf8_full_out_caller_allocated (), $string_array_ref);
  is_deeply (GI::garray_utf8_none_inout ($string_array_ref), [-2..1]);
  is_deeply (GI::garray_utf8_container_inout ($string_array_ref), [-2..1]);
  # FIXME: This leaks.  See <https://bugzilla.gnome.org/show_bug.cgi?id=745336>.
  is_deeply (GI::garray_utf8_full_inout ($string_array_ref), [-2..1]);
}

# GPtrArray.
SKIP: {
  skip 'GPtrArray', 9
    unless check_gi_version (0, 12, 0);
  is_deeply (GI::gptrarray_utf8_none_return (), $string_array_ref);
  is_deeply (GI::gptrarray_utf8_container_return (), $string_array_ref);
  is_deeply (GI::gptrarray_utf8_full_return (), $string_array_ref);
  GI::gptrarray_utf8_none_in ($string_array_ref);
  is_deeply (GI::gptrarray_utf8_none_out (), $string_array_ref);
  is_deeply (GI::gptrarray_utf8_container_out (), $string_array_ref);
  is_deeply (GI::gptrarray_utf8_full_out (), $string_array_ref);
  is_deeply (GI::gptrarray_utf8_none_inout ($string_array_ref), [-2..1]);
  is_deeply (GI::gptrarray_utf8_container_inout ($string_array_ref), [-2..1]);
  # FIXME: This leaks.  See <https://bugzilla.gnome.org/show_bug.cgi?id=745336>.
  is_deeply (GI::gptrarray_utf8_full_inout ($string_array_ref), [-2..1]);
}

# GByteArray.
SKIP: {
  skip 'GByteArray', 1
    unless check_gi_version (0, 12, 0);
  is_deeply (GI::bytearray_full_return (), $byte_array_ref);
  GI::bytearray_none_in ($byte_array_ref);
}
