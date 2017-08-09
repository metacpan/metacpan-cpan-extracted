# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Basic tests for Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/03_word.t'

#########################

use strict;
use warnings;
use Test::More tests => 212;
use strict;
use warnings;
use Math::BigInt;
BEGIN { use_ok( 'Math::Logic::Ternary::Word' ); }  # 1

#########################

my $r;
$r = eval { Math::Logic::Ternary::Word->DOES('Math::Logic::Ternary::Object') };
is($r, 1);                              # 2

my $z3 = Math::Logic::Ternary::Word->from_trits(3);
isa_ok($z3, 'Math::Logic::Ternary::Word');  # 3
my $s3 = $z3->Trits;
is($s3, 3);                             # 4
my @t3 = $z3->Trits;
is(0+@t3, 3);                           # 5
isa_ok($t3[0], 'Math::Logic::Ternary::Trit');  # 6
is($t3[0]->is_nil, !0);                 # 7
isa_ok($t3[1], 'Math::Logic::Ternary::Trit');  # 8
is($t3[1]->is_nil, !0);                 # 9
isa_ok($t3[2], 'Math::Logic::Ternary::Trit');  # 10
is($t3[2]->is_nil, !0);                 # 11

my $n = $t3[0];
my $t = $n->st;
my $f = $n->sf;

my $w6 = Math::Logic::Ternary::Word->from_trits(6, $n, $f, $n, $t, $f, $t);
isa_ok($w6, 'Math::Logic::Ternary::Word');  # 12
my $s6 = $w6->Trits;
is($s6, 6);                             # 13
my @t6 = $w6->Trits;
is(0+@t6, 6);                           # 14
isa_ok($t6[0], 'Math::Logic::Ternary::Trit');  # 15
is($t6[0]->is_nil, !0);                 # 16
isa_ok($t6[1], 'Math::Logic::Ternary::Trit');  # 17
is($t6[1]->is_false, !0);               # 18
isa_ok($t6[2], 'Math::Logic::Ternary::Trit');  # 19
is($t6[2]->is_nil, !0);                 # 20
isa_ok($t6[3], 'Math::Logic::Ternary::Trit');  # 21
is($t6[3]->is_true, !0);                # 22
isa_ok($t6[4], 'Math::Logic::Ternary::Trit');  # 23
is($t6[4]->is_false, !0);               # 24
isa_ok($t6[5], 'Math::Logic::Ternary::Trit');  # 25
is($t6[5]->is_true, !0);                # 26
$r = eval { $w6->DOES('Math::Logic::Ternary::Object') };
is($r, 1);                              # 27

is($w6->Sign, $t);                      # 28
is($z3->Sign, $n);                      # 29
is($w6->Signu, $t);                     # 30
is($z3->Signu, $n);                     # 31
is($w6->Signv, $f);                     # 32
is($z3->Signv, $n);                     # 33
is(($w6->Negv)[0]->Signv, $t);          # 34

$r = eval { Math::Logic::Ternary::Word->from_trits(0) };
ok(!defined $r);                        # 35
like($@, qr/^missing arguments /);      # 36
$r = eval { Math::Logic::Ternary::Word->from_trits(1114111, $f) };
ok(!defined $r);                        # 37
like($@, qr/^illegal size, use 1\.\.\d+ /);  # 38
$r = eval { Math::Logic::Ternary::Word->from_trits(-1, $t) };
ok(!defined $r);                        # 39
like($@, qr/^illegal size, use 1\.\.\d+ /);  # 40
$r = eval { Math::Logic::Ternary::Word->from_trits(3, @t6) };
ok(!defined $r);                        # 41
like($@, qr/^too many trits for word size 3 /);  # 42

my $c3 = $z3->convert_trits($t, $f, $n);
isa_ok($c3, 'Math::Logic::Ternary::Word');  # 43
$s3 = $c3->Trits;
is($s3, 3);                             # 44
@t3 = $c3->Trits;
is(0+@t3, 3);                           # 45
isa_ok($t3[0], 'Math::Logic::Ternary::Trit');  # 46
is($t3[0]->is_true, !0);                # 47
isa_ok($t3[1], 'Math::Logic::Ternary::Trit');  # 48
is($t3[1]->is_false, !0);               # 49
isa_ok($t3[2], 'Math::Logic::Ternary::Trit');  # 50
is($t3[2]->is_nil, !0);                 # 51

$r = eval { $z3->convert_trits(@t6) };
ok(!defined $r);                        # 52
like($@, qr/^too many trits for word size 3 /);  # 53

my $u6 = $w6->convert_words($z3, $c3);
is($u6->as_int, -54);                   # 54
$u6 = $w6->convert_words($z3, $t, $f);
is($u6->as_int, -54);                   # 55

my @w = $u6->Words(3);
is(0+@w, 2);                            # 56
is($w[0]->Trits + 0, 3);                # 57
is($w[0]->as_int, 0);                   # 58
is($w[1]->as_int, -2);                  # 59
@w = $c3->Words(3);
is(0+@w, 1);                            # 60
is($w[0]->Trits + 0, 3);                # 61
is($w[0]->as_int, -2);                  # 62
@w = $c3->Words(6);
is(0+@w, 1);                            # 63
is($w[0]->Trits + 0, 6);                # 64
is($w[0]->as_int, -2);                  # 65

$u6 = $w6->convert_base27('%pe');
is($u6->as_int, -292);                  # 66
is($u6->as_int_u, 692);                 # 67
is($u6->as_int_v, -346);                # 68
is($u6->as_string, '@ffttff');          # 69
is($u6->as_base27, '%Pe');              # 70
$u6 = $w6->convert_base27('rl');
is($u6->as_int, -231);                  # 71
is($u6->as_int_u, 498);                 # 72
is($u6->as_int_v, -480);                # 73
is($u6->as_string, '@fnnttn');          # 74
is($u6->as_base27, '%Rl');              # 75

# check in scalar and array context
my ($scalar, $scalar2);
($scalar, $scalar2) = $u6->as_string;
is($scalar, '@fnnttn');                 # 76
is($scalar2, undef);                    # 77
$scalar = $u6->as_string;
is($scalar, '@fnnttn');                 # 78
($scalar, $scalar2) = $u6->as_base27;
is($scalar, '%Rl');                     # 79
is($scalar2, undef);                    # 80
$scalar = $u6->as_base27;
is($scalar, '%Rl');                     # 81

$r = eval { $w6->convert_base27('+x') };
ok(!defined $r);                        # 82
like($@, qr/^illegal base27 character "\+"/ );  # 83

$u6 = $w6->convert_string('@ntftff');
is($u6->as_int, 59);                    # 84
is($u6->as_int_u, 152);                 # 85
is($u6->as_int_v, 32);                  # 86
is($u6->as_string, '@ntftff');          # 87
is($u6->as_base27, '%be');              # 88
$u6 = $w6->convert_string('@tnttf');
is($u6->as_int, 92);                    # 89
is($u6->as_int_u, 95);                  # 90
is($u6->as_int_v, 89);                  # 91
is($u6->as_string, '@ntnttf');          # 92
is($u6->as_base27, '%ck');              # 93
$u6 = $w6->convert_string('tfffnn');
is($u6->as_int, 126);                   # 94
is($u6->as_int_u, 477);                 # 95
is($u6->as_int_v, -117);                # 96
is($u6->as_string, '@tfffnn');          # 97
is($u6->as_base27, '%eR');              # 98
$u6 = $w6->convert_string('%ma');
is($u6->as_int, 352);                   # 99
is($u6->as_int_u, 352);                 # 100
is($u6->as_int_v, -188);                # 101
is($u6->as_string, '@tttnnt');          # 102
is($u6->as_base27, '%ma');              # 103

$r = eval { $w6->convert_string('fnnfxf') };
ok(!defined $r);                        # 104
like($@, qr/^illegal base3 character "x"/ );  # 105
$r = eval { $w6->convert_string('$true')->as_int };
is($r, 1);                              # 106

my @it = (
    ['%NN', -364, 728, -364],
    ['%NO', -363, 726, -366],
    ['%Vm', -122, 607, -425],
    ['%WN', -121, 242,  122],
    ['%XQ',  -91, 182,  182],
    ['%XS',  -89, 181,  181],
    ['%QX', -273, 546, -546],
    ['%QY', -272, 547, -545],
    ['%Sb', -214, 518, -514],
    ['%_Z',   -1,   2,    2],
    ['%__',    0,   0,    0],
    ['%_a',    1,   1,    1],
    ['%bf',   60, 150,   30],
    ['%dm',  121, 121,   61],
    ['%eN',  122, 485, -121],
    ['%fS',  154, 424,  -62],
    ['%ml',  363, 363, -183],
    ['%mm',  364, 364, -182],
);

my ($bok, $uok, $vok) = (1, 1, 1);
foreach my $tc (@it) {
    my ($s, $b, $u, $v) = @{$tc};
    my $bi = $w6->convert_int($b);
    my $ui = $w6->convert_int_u($u);
    my $vi = $w6->convert_int_v($v);
    $bok &&= $s eq $bi->as_base27;
    $uok &&= $s eq $ui->as_base27;
    $vok &&= $s eq $vi->as_base27;
}
ok($bok, 'balanced integer conversion');  # 107
ok($uok, 'unbalanced integer conversion');  # 108
ok($vok, 'base(-3) integer conversion');  # 109

my $str = '3' x 13;
my $bgi = Math::BigInt->new($str);
my @res = qw(%lVRYTTbgl %hUeOSQZYl %OlRfQmfQO);
$r = Math::Logic::Ternary::Word->from_int(27, $str);
is($r->as_base27, $res[0]);             # 110
$r = Math::Logic::Ternary::Word->from_int(27, $bgi);
is($r->as_base27, $res[0]);             # 111
$r = Math::Logic::Ternary::Word->from_int_u(27, $str);
is($r->as_base27, $res[1]);             # 112
$r = Math::Logic::Ternary::Word->from_int_u(27, $bgi);
is($r->as_base27, $res[1]);             # 113
$r = Math::Logic::Ternary::Word->from_int_v(27, $str);
is($r->as_base27, $res[2]);             # 114
$r = Math::Logic::Ternary::Word->from_int_v(27, $bgi);
is($r->as_base27, $res[2]);             # 115

$r = eval { $w6->convert_int(-365) };
ok(!defined $r);                        # 116
like($@, qr/^number too large for word size 6 /);  # 117
$r = eval { $w6->convert_int(365) };
ok(!defined $r);                        # 118
like($@, qr/^number too large for word size 6 /);  # 119
$r = eval { $w6->convert_int_u(729) };
ok(!defined $r);                        # 120
like($@, qr/^number too large for word size 6 /);  # 121
$r = eval { $w6->convert_int_v(-547) };
ok(!defined $r);                        # 122
like($@, qr/^number too large for word size 6 /);  # 123
$r = eval { $w6->convert_int_v(183) };
ok(!defined $r);                        # 124
like($@, qr/^number too large for word size 6 /);  # 125

$r = eval { Math::Logic::Ternary::Word->from_trits(0) };
ok(!defined $r);                        # 126
like($@, qr/^missing arguments /);      # 127
$r = eval { Math::Logic::Ternary::Word->from_trits(0, ($n) x 6)->as_int };
is($r, 0);                              # 128
$r = eval { Math::Logic::Ternary::Word->from_int(0, -1) };
ok(!defined $r);                        # 129
like($@, qr/^missing size information /);  # 130
$r = eval { Math::Logic::Ternary::Word->from_int(3, 0.5) };
ok(!defined $r);                        # 131
like($@, qr/^integer argument expected /);  # 132
$r = eval { Math::Logic::Ternary::Word->from_int_u(3, -1) };
ok(!defined $r);                        # 133
like($@, qr/^negative number has no unbalanced representation /);  # 134
$r = eval { Math::Logic::Ternary::Word->from_string(0, '$false')};
is($r, $f);                             # 135
$r = eval { Math::Logic::Ternary::Word->from_string(1, '$false') };
isa_ok($r, 'Math::Logic::Ternary::Word');  # 136
$r = eval { $r->Sign };
is($r, $f);                             # 137
$r = eval { Math::Logic::Ternary::Word->from_string(0, '#ntf') };
ok(!defined $r);                        # 138
like($@, qr/^illegal base3 character "#" /);  # 139

my @bi =
    (
        '%big_math_logic_ternary_word',
        Math::BigInt->new( '38478909024171501623683942175727506761'),
        Math::BigInt->new( '87951275701305703766751842967396770320'),
        Math::BigInt->new('-21807274878614472831317059890550783580'),
        '%big_maTh_lOgic_TeRNaRY_WORd',
    );
my $w81 = Math::Logic::Ternary::Word->from_string( 0, $bi[0]);
is($w81->Trits + 0, 81);                # 140
$r = $w81->as_int;
is($r, $bi[1]);                         # 141
$r = $w81->as_int_u;
is($r, $bi[2]);                         # 142
$r = $w81->as_int_v;
is($r, $bi[3]);                         # 143
$r = $w81->convert_int($bi[1]);
is($r->as_base27, $bi[4]);              # 144
$r = $w81->convert_int_u($bi[2]);
is($r->as_base27, $bi[4]);              # 145
$r = $w81->convert_int_v($bi[3]);
is($r->as_base27, $bi[4]);              # 146

my ($w9) = $w6->Words(9);
my $w1 = Math::Logic::Ternary::Word->from_trits(1, $t);
is($w9->Trits + 0, 9);                  # 147
is($w9->Rtrits + 0, 6);                 # 148
is($w9->is_equal($w6), !0);             # 149
is($w9->is_equal($t),  !1);             # 150
is($w9->is_equal($w9), !0);             # 151
is($w6->is_equal($w9), !0);             # 152
is($t->is_equal($w9),  !1);             # 153
is($w1->is_equal($t),  !0);             # 154
is($w1->is_equal($f),  !1);             # 155
is($w1->is_equal($n),  !1);             # 156
is($t->is_equal($w1),  !0);             # 157
is($f->is_equal($w1),  !1);             # 158
is($n->is_equal($w1),  !1);             # 159
my $ok = 1;
my @t9 = (@t6, ($n) x 3);
foreach my $i (-10 .. 9) {
    $ok &&= $w9->Trit($i)->as_int == ($t9[$i] || $n)->as_int;
}
ok($ok, 'selecting trits by index');    # 160

my $w3 = Math::Logic::Ternary::Word->from_various(0, $n, $t, $f);
is($w3->as_string, '@ftn');             # 161
is($w3->convert_bools(undef, 0, 'foo')->as_string, '@tfn');  # 162
is($w3->convert_various(undef, 0, 'foo')->as_string, '@tfn');  # 163
is($w3->convert_various($n, $f, $t)->as_string, '@tfn');  # 164
is($w3->convert_various($t)->as_string, '@nnt');  # 165
is($w3->convert_various($w1, $w1, $w1)->as_string, '@ttt');  # 166
is($w3->convert_various($w1)->as_string, '@nnt');  # 167
is($w3->convert_various(13)->as_string, '@ttt');  # 168
is($w3->convert_various('+13')->as_string, '@ttt');  # 169
is($w3->convert_various('-13')->as_string, '@fff');  # 170
my $big = Math::BigInt->new(-1);
is($w3->convert_various($big)->as_string, '@nnf');  # 171
$r = eval { $w3->convert_various($big, $big, $big) };
ok(!defined $r);                        # 172
like($@, qr/^cannot convert multiple "Math::BigInt" objects into ternary word /);  # 173
my $obj = bless [], 'Some::Thing';
$r = eval { $w3->convert_various($obj) };
ok(!defined $r);                        # 174
like($@, qr/^cannot convert "Some::Thing" object into ternary word /);  # 175
is($w3->convert_various('nft')->as_string, '@nft');  # 176
is($w3->convert_various('$false')->as_string, '@nnf');  # 177
is($w3->convert_various('@nft')->as_string, '@nft');  # 178
is($w3->convert_various('%m')->as_string, '@ttt');  # 179
is($w3->convert_various('')->as_string, '@nnn');  # 180
is($w3->convert_various()->as_string, '@nnn');  # 181
$r = eval { $w3->convert_various([]) };
ok(!defined $r);                        # 182
like($@, qr/^cannot convert ARRAY reference into ternary word /);  # 183
$r = eval { $w3->convert_various('x01y') };
ok(!defined $r);                        # 184
like($@, qr/^illegal base3 character "y" /);  # 185

my @op = Math::Logic::Ternary::Word->word_operators;
my %ar = map {@{$_}[0, 1]} @op;
my $nop = @op;
print "# got $nop named word operators\n";
ok($nop >= 9, 'operator list minimum length');  # 186
is($nop-keys %ar, 0, 'no duplicate list entries');  # 187
my $cant = grep { !$w3->can($_->[0]) } @op;
is($cant, 0, 'no missing methods');     # 188
is($ar{'Neg'}, 1);                      # 189
is(exists($ar{'Negu'}), !1);            # 190
is($ar{'Lshift'}, 1);                   # 191
is($ar{'Rshift'}, 1);                   # 192
is($ar{'Sign'},   1);                   # 193
is($ar{'Sort2'},  2);                   # 194
is($ar{'Add'},    2);                   # 195
is($ar{'Subt'},   2);                   # 196
is($ar{'Sort3'},  3);                   # 197
is($ar{'Mul'},    2);                   # 198
is($ar{'Div'},    2);                   # 199
is($ar{'Ldiv'},   3);                   # 200
is($ar{'Sum'},    3);                   # 201
is($ar{'Mpx'},    4);                   # 202

my $e_args_checked     = 0;
my $e_args_reported    = 0;
my $e_context_checked  = 0;
my $e_context_reported = 0;
foreach my $opr (@op) {
    my ($name, $minargs, $varargs, $retvals) = @{$opr};
    if (1 < $minargs) {
        my @rr = eval { $w3->$name };
        if (@rr) {
            print "# op $name does not catch missing args!\n";
            ++$e_args_checked;
        }
        elsif (
            'Mpx' eq $name && $@ !~ /^too few arguments, expected 3 more / ||
            'Mpx' ne $name && $@ !~ /^missing arguments /
        ) {
            my $msg = $@;
            $msg =~ s/\n.*//s;
            print "# op $name does not report missing args correctly!\n";
            print "# the message was: $msg\n";
            ++$e_args_reported;
        }
    }
    if (1 < $retvals) {
        my $rr = eval { $w3->$name(($w3) x ($minargs - 1)) };
        if (defined $rr) {
            print "# op $name does not catch wrong context!\n";
            ++$e_context_checked;
        }
        elsif ($@ !~ /^array context expected /) {
            my $msg = $@;
            $msg =~ s/\n.*//s;
            print "# op $name does not report wrong context correctly!\n";
            print "# the message was: $msg\n";
            ++$e_context_reported;
        }
    }
}
is($e_args_checked,     0);             # 203
is($e_args_reported,    0);             # 204
is($e_context_checked,  0);             # 205
is($e_context_reported, 0);             # 206

my @fm = Math::Logic::Ternary::Word->word_formatters;
my %sn = map {($_->[0] => 1)} @fm;
my $nfm = @fm;
print "# got $nfm named word formatters\n";
is($nfm - keys %sn, 0, 'no duplicate list entries');  # 207
my $hant = grep { !$w3->can($_->[0]) } @fm;
is($hant, 0, 'no missing methods');     # 208
is($sn{'as_string'}, 1);                # 209
is($sn{'as_int'   }, 1);                # 210
is($sn{'as_int_u' }, 1);                # 211
is($sn{'as_int_v' }, 1);                # 212

__END__
