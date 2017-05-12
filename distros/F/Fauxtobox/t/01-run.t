#!perl

use Test::More tests => 115;

use warnings FATAL => 'all';
use strict;

use Fauxtobox;

is "hello"->$_apply(sub { $_[0] x 2 }), "hellohello";
is "hello"->$_qr, qr/hello/;

is "hello"->$_m(qr/e/), "hello" =~ m/e/;
is(() = "hello"->$_m_g(qr/[eo]/), () = "hello" =~ m/[eo]/g);

{
    my $s = "hello";
    my $t = "hello";

    # tmp variables here because 5.10.0 panics otherwise
    my $tmp1 = $s->$_s(qr/([eo])/, sub { "($1)" });
    my $tmp2 = $t =~ s/([eo])/"($1)"/e;
    is $tmp1, $tmp2;
    is $s, $t;
}

{
    my $s = "hello";
    my $t = "hello";

    # tmp variables here because 5.10.0 panics otherwise
    my $tmp1 = $s->$_s_g(qr/([eo])/, sub { "($1)" });
    my $tmp2 = $t =~ s/([eo])/"($1)"/ge;
    is $tmp1, $tmp2;
    is $s, $t;
}

is "hello"->$_s_r (qr/([eo])/, sub { uc $1 }), "hEllo";
is "hello"->$_s_gr(qr/([eo])/, sub { uc $1 }), "hEllO";

is __FILE__->$_test_e, -e __FILE__;
is __FILE__->$_test_s, -s __FILE__;

is 42->$_abs, abs 42;
is +(-42)->$_abs, abs -42;

is 1->$_atan2(2), atan2 1, 2;

is ref []->$_bless('hello'), 'hello';
is ref do { package ABC; []->$::_bless }, 'ABC';

{
    my $xs = ["foo\n", "bar", "baz\n", "quux\n"];
    is $xs->[0]->$_chomp, 1;
    is $xs->[0], "foo";
    is $xs->$_chomp, 2;
    is_deeply $xs, ["foo", "bar", "baz", "quux"];
}
{
    my $xs = ["foo\n", "bar", "baz\n", "quux\n"];
    is $xs->[0]->$_chop, "\n";
    is $xs->[0], "foo";
    is $xs->$_chop, "\n";
    is_deeply $xs, ["fo", "ba", "baz", "quux"];
}

is 65->$_chr, chr 65;

is 1->$_cos, cos 1;

is "hello"->$_crypt("AB"), crypt "hello", "AB";

is ""->$_defined, defined "";
is undef->$_defined, defined undef;

{
    my $h = { 'A' .. 'D' };
    is $h->$_delete('C'), 'D';
    is_deeply $h, {A => 'B'};
}

is eval { "hello\n"->$_die }, undef;
is $@, "hello\n";

is "2 + 2"->$_eval, eval "2 + 2";

{
    my $h = { 'A' .. 'D' };
    is $h->$_exists('B'), exists $h->{'B'};
    is $h->$_exists('C'), exists $h->{'C'};
}

is 1.5->$_exp, exp 1.5;

is_deeply '{A,B}{C,D}'->$_glob, [glob '{A,B}{C,D}'];

is 0->$_gmtime, gmtime 0;

is_deeply [1 .. 10]->$_grep(sub { $_[0] % 2 }), [ grep { $_ % 2 } 1 .. 10 ];

is "20"->$_hex, hex "20";

is "hello"->$_index("l"), index "hello", "l";
is "hello"->$_index("l", 3), index "hello", "l", 3;

is 2.7->$_int, int 2.7;

is ['A' .. 'C']->$_join('-'), join '-', 'A' .. 'C';

{
    my $h = { 'A' .. 'D' };
    is_deeply [ sort $h->$_keys->$_list ], [ sort keys %$h ];
}

is "HEllO"->$_lc, lc "HEllO";

is "HEllO"->$_lcfirst, lcfirst "HEllO";

is "hello"->$_length, length "hello";

is 0->$_localtime, localtime 0;

is 10->$_log, log 10;

is_deeply [1 .. 10]->$_map(sub { $_[0] * 3 }), [ map { $_ * 3 } 1 .. 10 ];

is "20"->$_oct, oct "20";

is "A"->$_ord, ord "A";

is 123456->$_pack('N'), pack 'N', 123456;
is [123456, "hello", 42]->$_pack('V N/a* C'), pack 'V N/a* C', 123456, "hello", 42;

{
    my $xs = ['A' .. 'C'];
    is $xs->$_pop, 'C';
    is_deeply $xs, ['A', 'B'];
}

{
    my $s = "hello";
    is $s->$_pos, pos $s;
    $s->$_pos(3);
    is pos($s), 3;
    is $s->$_pos, pos $s;
}

{
    my $f = sub ($\$;$@) {};
    is $f->$_prototype, prototype $f;
    is "CORE::push"->$_prototype, prototype "CORE::push";
}


{
    my $xs = ['A' .. 'C'];
    is $xs->$_push('D', 'E'), 5;
    is_deeply $xs, ['A' .. 'E'];
}

is "hello"->$_quotemeta, quotemeta "hello";
is "a_.]\\\$^z"->$_quotemeta, quotemeta "a_.]\\\$^z";

is undef->$_ref, ref undef;
is "hallo"->$_ref, ref "hallo";
is []->$_ref, ref [];
{
    package Tref;
    sub new { +{}->$::_bless($_[0]) }
    sub ref { CORE::ref($_[0]) . ' (fake)' }
}
{
    my $obj = Tref->new;
    is ref($obj), 'Tref';
    is $obj->$_ref, 'Tref (fake)';
}

is "hello"->$_reverse, "olleh";
is_deeply ["hello", "world"]->$_reverse, ["world", "hello"];

is "hello"->$_rindex("l"), rindex "hello", "l";
is "hello"->$_rindex("l", 2), rindex "hello", "l", 2;

{
    my $xs = ['A' .. 'C'];
    is $xs->$_shift, 'A';
    is_deeply $xs, ['B', 'C'];
}

is 1->$_sin, sin 1;

is_deeply [qw(the quick brown fox jumps over the lazy dog)]->$_sort,
          [sort qw(the quick brown fox jumps over the lazy dog)];
is_deeply [qw(the quick brown fox jumps over the lazy dog)]->$_sort(
              sub { length($_[1]) <=> length($_[0]) || $_[0] cmp $_[1] }
          ),
          [sort { length($b) <=> length($a) || $a cmp $b }
              qw(the quick brown fox jumps over the lazy dog)
          ];

{
    my $xs = ['A' .. 'D'];
    is_deeply [ $xs->$_splice(1, 2, 'X', 'Y', 'Z') ], [ 'B', 'C' ];
    is_deeply $xs, ['A', 'X', 'Y', 'Z', 'D'];
    is_deeply [ $xs->$_splice(2, 1) ], [ 'Y' ];
    is_deeply $xs, ['A', 'X', 'Z', 'D'];
    is_deeply [ $xs->$_splice(-2) ], [ 'Z', 'D' ];
    is_deeply $xs, ['A', 'X'];
    is_deeply [ $xs->$_splice ], [ 'A', 'X' ];
    is_deeply $xs, [];
}

is_deeply " the quick brown fox"->$_split, [ qw( the quick brown fox) ];
is_deeply " the quick brown fox"->$_split(qr/[oe]/), [ split /[oe]/, " the quick brown fox" ];
is_deeply "a::"->$_split(qr/:/, -1), ["a", "", ""];
is_deeply "a=b=c=d"->$_split(qr/=/, 2), ["a", "b=c=d"];

is 2->$_sprintf('[%4.2d]'), sprintf '[%4.2d]', 2;
is ["hello", 42]->$_sprintf('%s %d'), sprintf '%s %d', "hello", 42;

is 2->$_sqrt, sqrt 2;

{
    my $s = 'ABCD';
    is $s->$_substr(1, 2, 'XYZ'), 'BC';
    is $s, 'AXYZD';
    is $s->$_substr(2, 1), 'Y';
    is $s, 'AXYZD';
    is $s->$_substr(-2), 'ZD';
    is $s, 'AXYZD';
    is $s->$_substr(0, -1, ''), 'AXYZ';
    is $s, 'D';
}

is "hEllo"->$_uc, uc "hEllo";

is_deeply [ "\x42"->$_unpack('C') ], [ unpack 'C', "\x42" ];
is_deeply [ "abcd\0\0\0\5hello\1"->$_unpack('V N/a* C') ], [ unpack 'V N/a* C', "abcd\0\0\0\5hello\1" ];

{
    my $xs = ['A' .. 'C'];
    is $xs->$_unshift('D', 'E'), 5;
    is_deeply $xs, ['D', 'E', 'A', 'B', 'C'];
}

{
    my $h = { 'A' .. 'D' };
    is_deeply [ sort $h->$_values->$_list ], [ sort values %$h ];
}

is "ab"->$_vec(3, 4), vec("ab", 3, 4);
{
    my $s = '';
    my $t = '';
    is $s->$_vec(10, 2, 3), vec($t, 10, 2) = 3;
    is $s, $t;
}

{
    my $w;
    local $SIG{__WARN__} = sub { $w = $_[0] };
    "hello\n"->$_warn;
    is $w, "hello\n";
}

0->$_exit;
