# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for Math::Logic::Ternary::Trit

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02_trit.t'

#########################

use strict;
use warnings;
use Test::More tests => 388;
use Math::BigInt;
BEGIN { use_ok( 'Math::Logic::Ternary::Trit' ); }  # 1

#########################

my $r;

$r = eval { Math::Logic::Ternary::Trit->DOES('Math::Logic::Ternary::Object') };
is($r,                  1 );            # 2

my $n = Math::Logic::Ternary::Trit->nil;
isa_ok($n, 'Math::Logic::Ternary::Trit');  # 3
is($n->Sign,           $n );            # 4
is($n->Trits + 0,       1 );            # 5
is([$n->Trits]->[0],   $n );            # 6
is($n->as_int,          0 );            # 7
is($n->as_int_u,        0 );            # 8
is($n->as_int_v,        0 );            # 9
is($n->as_string,   '$nil');            # 10
is($n->Rtrits + 0,      0 );            # 11
is(@{[$n->Rtrits]} + 0, 0 );            # 12
is($n->Trit(-2),       $n );            # 13
is($n->Trit(-1),       $n );            # 14
is($n->Trit( 0),       $n );            # 15
is($n->Trit( 1),       $n );            # 16
$r = eval { $n->DOES('Math::Logic::Ternary::Object') };
is($r,                  1 );            # 17

my $t = Math::Logic::Ternary::Trit->true;
isa_ok($t, 'Math::Logic::Ternary::Trit');  # 18
is($t->Sign,           $t );            # 19
is($t->Trits + 0,       1 );            # 20
is([$t->Trits]->[0],   $t );            # 21
is($t->as_int,          1 );            # 22
is($t->as_int_u,        1 );            # 23
is($t->as_int_v,        1 );            # 24
is($t->as_string,  '$true');            # 25
is($t->Rtrits + 0,      1 );            # 26
is([$t->Rtrits]->[0],  $t );            # 27
is($t->Trit(-2),       $n );            # 28
is($t->Trit(-1),       $t );            # 29
is($t->Trit( 0),       $t );            # 30
is($t->Trit( 1),       $n );            # 31
$r = eval { $t->DOES('Math::Logic::Ternary::Object') };
is($r,                  1 );            # 32

my $f = Math::Logic::Ternary::Trit->false;
isa_ok($f, 'Math::Logic::Ternary::Trit');  # 33
is($f->Sign,           $f );            # 34
is($f->Trits + 0,       1 );            # 35
is([$f->Trits]->[0],   $f );            # 36
is($f->as_int,         -1 );            # 37
is($f->as_int_u,        2 );            # 38
is($f->as_int_v,        2 );            # 39
is($f->as_string, '$false');            # 40
is($f->Rtrits + 0,      1 );            # 41
is([$f->Rtrits]->[0],  $f );            # 42
is($f->Trit(-2),       $n );            # 43
is($f->Trit(-1),       $f );            # 44
is($f->Trit( 0),       $f );            # 45
is($f->Trit( 1),       $n );            # 46
$r = eval { $f->DOES('Math::Logic::Ternary::Object') };
is($r,                  1 );            # 47

is(Math::Logic::Ternary::Trit->from_bool(undef), $n);  # 48
is(Math::Logic::Ternary::Trit->from_bool( 1==1), $t);  # 49
is(Math::Logic::Ternary::Trit->from_bool( 1==2), $f);  # 50
is(Math::Logic::Ternary::Trit->from_bool(    0), $f);  # 51
is(Math::Logic::Ternary::Trit->from_bool( '**'), $t);  # 52

is($n->from_int(0<=>0), $n);            # 53
is($n->from_int(2<=>1), $t);            # 54
is($n->from_int(1<=>2), $f);            # 55
$r = eval { $n->from_int(-1234) };
ok(!defined $r);                        # 56
like($@, qr/^integer "-1234" out of range -1\.\.1 /);  # 57
$r = eval { $n->from_int(56789) };
ok(!defined $r);                        # 58
like($@, qr/^integer "56789" out of range -1\.\.1 /);  # 59

is($n->from_sign(0<=>0), $n);           # 60
is($n->from_sign(2<=>1), $t);           # 61
is($n->from_sign(1<=>2), $f);           # 62
$r = eval { $n->from_sign(-1234) };
is($r, $f);                             # 63
$r = eval { $n->from_sign(56789) };
is($r, $t);                             # 64

is($n->from_int_u(0), $n);              # 65
is($n->from_int_u(1), $t);              # 66
is($n->from_int_u(2), $f);              # 67
$r = eval { $n->from_int_u(-1) };
ok(!defined $r);                        # 68
like($@, qr/^integer "-1" out of range 0\.\.2 /);  # 69
$r = eval { $n->from_int_u(3) };
ok(!defined $r);                        # 70
like($@, qr/^integer "3" out of range 0\.\.2 /);  # 71

is($n->from_remainder(0), $n);          # 72
is($n->from_remainder(1), $t);          # 73
is($n->from_remainder(2), $f);          # 74
$r = eval { $n->from_remainder(-1) };
is($r, $f);                             # 75
$r = eval { $n->from_remainder(3) };
is($r, $n);                             # 76

is($n->from_string(  '$nil'),    $n);   # 77
is($n->from_string( '$true'),    $t);   # 78
is($n->from_string('$false'),    $f);   # 79
is($n->from_string(  '$NIL'),    $n);   # 80
is($n->from_string( '$True'),    $t);   # 81
is($n->from_string('$falSe'),    $f);   # 82

my $u;
$u = eval { $n->from_string('$Setun') };
ok(!defined $u);                        # 83
like($@, qr/^unknown trit name "\$Setun" /);  # 84

is($n->from_string(  'nil'),    $n);    # 85
is($n->from_string( 'true'),    $t);    # 86
is($n->from_string('false'),    $f);    # 87
is($n->from_string(  'NIL'),    $n);    # 88
is($n->from_string( 'True'),    $t);    # 89
is($n->from_string('falSe'),    $f);    # 90

$u = eval { $n->from_string('Setun') };
ok(!defined $u);                        # 91
like($@, qr/^unknown trit name "Setun" /);  # 92

my $b1 = Math::BigInt->new(-1);
my $b2 = Math::BigInt->new(2);
my $b3 = Math::BigInt->new(3);
my $obj = bless [], "Foobar";
is(Math::Logic::Ternary::Trit->from_various($t), $t);  # 93
is(Math::Logic::Ternary::Trit->from_various($b1), $f);  # 94
is(Math::Logic::Ternary::Trit->from_various($b2), $f);  # 95
is(Math::Logic::Ternary::Trit->from_various(undef), $n);  # 96
is(Math::Logic::Ternary::Trit->from_various(-1), $f);  # 97
is(Math::Logic::Ternary::Trit->from_various(2), $f);  # 98
is(Math::Logic::Ternary::Trit->from_various('false'), $f);  # 99
$r = eval { Math::Logic::Ternary::Trit->from_various($b3) };
ok(!defined $r);                        # 100
like($@, qr/^integer "3" out of range -1\.\.1 /);  # 101
$r = eval { Math::Logic::Ternary::Trit->from_various($obj) };
ok(!defined $r);                        # 102
like($@, qr/^cannot convert "Foobar" object to a trit /);  # 103
$r = eval { Math::Logic::Ternary::Trit->from_various([]) };
ok(!defined $r);                        # 104
like($@, qr/^cannot convert ARRAY reference to a trit /);  # 105
$r = eval { Math::Logic::Ternary::Trit->from_various(3) };
ok(!defined $r);                        # 106
like($@, qr/^integer "3" out of range -1\.\.1 /);  # 107
$r = eval { Math::Logic::Ternary::Trit->from_various('foo') };
ok(!defined $r);                        # 108
like($@, qr/^unknown trit name "foo" /);  # 109

is($n->not, $n);                        # 110
is($t->not, $f);                        # 111
is($f->not, $t);                        # 112

is($n->and($n), $n);                    # 113
is($n->and($t), $n);                    # 114
is($n->and($f), $f);                    # 115
is($t->and($n), $n);                    # 116
is($t->and($t), $t);                    # 117
is($t->and($f), $f);                    # 118
is($f->and($n), $f);                    # 119
is($f->and($t), $f);                    # 120
is($f->and($f), $f);                    # 121

is($n->or($n), $n);                     # 122
is($n->or($t), $t);                     # 123
is($n->or($f), $n);                     # 124
is($t->or($n), $t);                     # 125
is($t->or($t), $t);                     # 126
is($t->or($f), $t);                     # 127
is($f->or($n), $n);                     # 128
is($f->or($t), $t);                     # 129
is($f->or($f), $f);                     # 130

is($n->generic('u210'), $f);            # 131
is($t->generic('u210'), $t);            # 132
is($f->generic('u210'), $n);            # 133

is($n->generic('b012012012', $n), $n);  # 134
is($n->generic('b012012012', $t), $t);  # 135
is($n->generic('b012012012', $f), $f);  # 136
is($t->generic('b012012012', $n), $n);  # 137
is($t->generic('b012012012', $t), $t);  # 138
is($t->generic('b012012012', $f), $f);  # 139
is($f->generic('b012012012', $n), $n);  # 140
is($f->generic('b012012012', $t), $t);  # 141
is($f->generic('b012012012', $f), $f);  # 142

is($n->generic('b000111222', $n), $n);  # 143
is($n->generic('b000111222', $t), $n);  # 144
is($n->generic('b000111222', $f), $n);  # 145
is($t->generic('b000111222', $n), $t);  # 146
is($t->generic('b000111222', $t), $t);  # 147
is($t->generic('b000111222', $f), $t);  # 148
is($f->generic('b000111222', $n), $f);  # 149
is($f->generic('b000111222', $t), $f);  # 150
is($f->generic('b000111222', $f), $f);  # 151

is($n->generic('b201201120', $n), $f);  # 152
is($n->generic('b201201120', $t), $n);  # 153
is($n->generic('b201201120', $f), $t);  # 154
is($t->generic('b201201120', $n), $f);  # 155
is($t->generic('b201201120', $t), $n);  # 156
is($t->generic('b201201120', $f), $t);  # 157
is($f->generic('b201201120', $n), $t);  # 158
is($f->generic('b201201120', $t), $f);  # 159
is($f->generic('b201201120', $f), $n);  # 160

is($n->generic('t012120201120201012201012120', $n, $n), $n);  # 161
is($n->generic('t012120201120201012201012120', $n, $t), $t);  # 162
is($n->generic('t012120201120201012201012120', $n, $f), $f);  # 163
is($n->generic('t012120201120201012201012120', $t, $n), $t);  # 164
is($n->generic('t012120201120201012201012120', $t, $t), $f);  # 165
is($n->generic('t012120201120201012201012120', $t, $f), $n);  # 166
is($n->generic('t012120201120201012201012120', $f, $n), $f);  # 167
is($n->generic('t012120201120201012201012120', $f, $t), $n);  # 168
is($n->generic('t012120201120201012201012120', $f, $f), $t);  # 169
is($t->generic('t012120201120201012201012120', $n, $n), $t);  # 170
is($t->generic('t012120201120201012201012120', $n, $t), $f);  # 171
is($t->generic('t012120201120201012201012120', $n, $f), $n);  # 172
is($t->generic('t012120201120201012201012120', $t, $n), $f);  # 173
is($t->generic('t012120201120201012201012120', $t, $t), $n);  # 174
is($t->generic('t012120201120201012201012120', $t, $f), $t);  # 175
is($t->generic('t012120201120201012201012120', $f, $n), $n);  # 176
is($t->generic('t012120201120201012201012120', $f, $t), $t);  # 177
is($t->generic('t012120201120201012201012120', $f, $f), $f);  # 178
is($f->generic('t012120201120201012201012120', $n, $n), $f);  # 179
is($f->generic('t012120201120201012201012120', $n, $t), $n);  # 180
is($f->generic('t012120201120201012201012120', $n, $f), $t);  # 181
is($f->generic('t012120201120201012201012120', $t, $n), $n);  # 182
is($f->generic('t012120201120201012201012120', $t, $t), $t);  # 183
is($f->generic('t012120201120201012201012120', $t, $f), $f);  # 184
is($f->generic('t012120201120201012201012120', $f, $n), $t);  # 185
is($f->generic('t012120201120201012201012120', $f, $t), $f);  # 186
is($f->generic('t012120201120201012201012120', $f, $f), $n);  # 187

is($n->xor($n), $n);                    # 188
is($n->xor($t), $n);                    # 189
is($n->xor($f), $n);                    # 190
is($t->xor($n), $n);                    # 191
is($t->xor($t), $f);                    # 192
is($t->xor($f), $t);                    # 193
is($f->xor($n), $n);                    # 194
is($f->xor($t), $t);                    # 195
is($f->xor($f), $f);                    # 196

is($n->eqv($n), $n);                    # 197
is($n->eqv($t), $n);                    # 198
is($n->eqv($f), $n);                    # 199
is($t->eqv($n), $n);                    # 200
is($t->eqv($t), $t);                    # 201
is($t->eqv($f), $f);                    # 202
is($f->eqv($n), $n);                    # 203
is($f->eqv($t), $f);                    # 204
is($f->eqv($f), $t);                    # 205

is($n->is_nil,   !0);                   # 206
is($t->is_nil,   !1);                   # 207
is($f->is_nil,   !1);                   # 208
is($n->is_true,  !1);                   # 209
is($t->is_true,  !0);                   # 210
is($f->is_true,  !1);                   # 211
is($n->is_false, !1);                   # 212
is($t->is_false, !1);                   # 213
is($f->is_false, !0);                   # 214

is($n->mpx($n, $n, $n), $n);            # 215
is($n->mpx($n, $n, $t), $n);            # 216
is($n->mpx($n, $n, $f), $n);            # 217
is($n->mpx($n, $t, $n), $n);            # 218
is($n->mpx($n, $t, $t), $n);            # 219
is($n->mpx($n, $t, $f), $n);            # 220
is($n->mpx($n, $f, $n), $n);            # 221
is($n->mpx($n, $f, $t), $n);            # 222
is($n->mpx($n, $f, $f), $n);            # 223
is($n->mpx($t, $n, $n), $t);            # 224
is($n->mpx($t, $n, $t), $t);            # 225
is($n->mpx($t, $n, $f), $t);            # 226
is($n->mpx($t, $t, $n), $t);            # 227
is($n->mpx($t, $t, $t), $t);            # 228
is($n->mpx($t, $t, $f), $t);            # 229
is($n->mpx($t, $f, $n), $t);            # 230
is($n->mpx($t, $f, $t), $t);            # 231
is($n->mpx($t, $f, $f), $t);            # 232
is($n->mpx($f, $n, $n), $f);            # 233
is($n->mpx($f, $n, $t), $f);            # 234
is($n->mpx($f, $n, $f), $f);            # 235
is($n->mpx($f, $t, $n), $f);            # 236
is($n->mpx($f, $t, $t), $f);            # 237
is($n->mpx($f, $t, $f), $f);            # 238
is($n->mpx($f, $f, $n), $f);            # 239
is($n->mpx($f, $f, $t), $f);            # 240
is($n->mpx($f, $f, $f), $f);            # 241
is($t->mpx($n, $n, $n), $n);            # 242
is($t->mpx($n, $n, $t), $n);            # 243
is($t->mpx($n, $n, $f), $n);            # 244
is($t->mpx($n, $t, $n), $t);            # 245
is($t->mpx($n, $t, $t), $t);            # 246
is($t->mpx($n, $t, $f), $t);            # 247
is($t->mpx($n, $f, $n), $f);            # 248
is($t->mpx($n, $f, $t), $f);            # 249
is($t->mpx($n, $f, $f), $f);            # 250
is($t->mpx($t, $n, $n), $n);            # 251
is($t->mpx($t, $n, $t), $n);            # 252
is($t->mpx($t, $n, $f), $n);            # 253
is($t->mpx($t, $t, $n), $t);            # 254
is($t->mpx($t, $t, $t), $t);            # 255
is($t->mpx($t, $t, $f), $t);            # 256
is($t->mpx($t, $f, $n), $f);            # 257
is($t->mpx($t, $f, $t), $f);            # 258
is($t->mpx($t, $f, $f), $f);            # 259
is($t->mpx($f, $n, $n), $n);            # 260
is($t->mpx($f, $n, $t), $n);            # 261
is($t->mpx($f, $n, $f), $n);            # 262
is($t->mpx($f, $t, $n), $t);            # 263
is($t->mpx($f, $t, $t), $t);            # 264
is($t->mpx($f, $t, $f), $t);            # 265
is($t->mpx($f, $f, $n), $f);            # 266
is($t->mpx($f, $f, $t), $f);            # 267
is($t->mpx($f, $f, $f), $f);            # 268
is($f->mpx($n, $n, $n), $n);            # 269
is($f->mpx($n, $n, $t), $t);            # 270
is($f->mpx($n, $n, $f), $f);            # 271
is($f->mpx($n, $t, $n), $n);            # 272
is($f->mpx($n, $t, $t), $t);            # 273
is($f->mpx($n, $t, $f), $f);            # 274
is($f->mpx($n, $f, $n), $n);            # 275
is($f->mpx($n, $f, $t), $t);            # 276
is($f->mpx($n, $f, $f), $f);            # 277
is($f->mpx($t, $n, $n), $n);            # 278
is($f->mpx($t, $n, $t), $t);            # 279
is($f->mpx($t, $n, $f), $f);            # 280
is($f->mpx($t, $t, $n), $n);            # 281
is($f->mpx($t, $t, $t), $t);            # 282
is($f->mpx($t, $t, $f), $f);            # 283
is($f->mpx($t, $f, $n), $n);            # 284
is($f->mpx($t, $f, $t), $t);            # 285
is($f->mpx($t, $f, $f), $f);            # 286
is($f->mpx($f, $n, $n), $n);            # 287
is($f->mpx($f, $n, $t), $t);            # 288
is($f->mpx($f, $n, $f), $f);            # 289
is($f->mpx($f, $t, $n), $n);            # 290
is($f->mpx($f, $t, $t), $t);            # 291
is($f->mpx($f, $t, $f), $f);            # 292
is($f->mpx($f, $f, $n), $n);            # 293
is($f->mpx($f, $f, $t), $t);            # 294
is($f->mpx($f, $f, $f), $f);            # 295

is($n->id, $n);                         # 296
is($t->id, $t);                         # 297
is($f->id, $f);                         # 298

is($n->eqn, $t);                        # 299
is($t->eqn, $f);                        # 300
is($f->eqn, $f);                        # 301

is($n->eqt, $f);                        # 302
is($t->eqt, $t);                        # 303
is($f->eqt, $f);                        # 304

is($n->eqf, $f);                        # 305
is($t->eqf, $f);                        # 306
is($f->eqf, $t);                        # 307

is($n->nen, $f);                        # 308
is($t->nen, $t);                        # 309
is($f->nen, $t);                        # 310

is($n->net, $t);                        # 311
is($t->net, $f);                        # 312
is($f->net, $t);                        # 313

is($n->nef, $t);                        # 314
is($t->nef, $t);                        # 315
is($f->nef, $f);                        # 316

is($n->incr($n), $n);                   # 317
is($n->incr($t), $t);                   # 318
is($n->incr($f), $f);                   # 319
is($t->incr($n), $t);                   # 320
is($t->incr($t), $f);                   # 321
is($t->incr($f), $n);                   # 322
is($f->incr($n), $f);                   # 323
is($f->incr($t), $n);                   # 324
is($f->incr($f), $t);                   # 325

is($n->decr($n), $n);                   # 326
is($n->decr($t), $f);                   # 327
is($n->decr($f), $t);                   # 328
is($t->decr($n), $t);                   # 329
is($t->decr($t), $n);                   # 330
is($t->decr($f), $f);                   # 331
is($f->decr($n), $f);                   # 332
is($f->decr($t), $t);                   # 333
is($f->decr($f), $n);                   # 334

my @tv = (0, 1, -1);
my ($ok_r, $ok_c) = (1, 1);
foreach my $a (@tv) {
    foreach my $b (@tv) {
        foreach my $c (@tv) {
            foreach my $d (@tv) {
                my $sum = $a+$b+$c+$d;
                my $sr  = ($sum + 1) % 3 - 1;
                my $sc  = ($sum - $sr) / 3;
                my @trits = map { $n->from_int($_) } $a, $b, $c, $d;
                my $tr  = $trits[0]->sum( @trits[1..3])->as_int;
                my $tc  = $trits[0]->sumc(@trits[1..3])->as_int;
                $ok_r &&= $tr == $sr;
                $ok_c &&= $tc == $sc;
            }
        }
    }
}
ok($ok_r, 'balanced three-value addition, result trit');  # 335
ok($ok_c, 'balanced three-value addition, carry trit');  # 336

my @tvu = (0, 1, 2);
($ok_r, $ok_c) = (1, 1);
foreach my $a (@tvu) {
    foreach my $b (@tvu) {
        foreach my $c (@tvu) {
            foreach my $d (@tvu) {
                my $sum = $a+$b+$c+$d;
                my $sr  = $sum % 3;
                my $sc  = ($sum - $sr) / 3;
                my @trits = map { $n->from_int_u($_) } $a, $b, $c, $d;
                my $tr  = $trits[0]->sum(  @trits[1..3])->as_int_u;
                my $tc  = $trits[0]->sumcu(@trits[1..3])->as_int_u;
                $ok_r &&= $tr == $sr;
                $ok_c &&= $tc == $sc;
            }
        }
    }
}
ok($ok_r, 'unbalanced three-value addition, result trit');  # 337
ok($ok_c, 'unbalanced three-value addition, carry trit');  # 338

($ok_r, $ok_c) = (1, 1);
foreach my $a (@tvu) {
    foreach my $b (@tvu) {
        foreach my $c (0, 1, -1) {
            my $sum = $a+$b+$c;
            my $sr  = $sum % 3;
            my $sc  = ($sum - $sr) / -3;
            my @trits =
                ($n->from_int_u($a), $n->from_int_u($b), $n->from_int($c));
            my $tr  = $trits[0]->add( @trits[1, 2])->as_int_v;
            my $tc  = $trits[0]->addcv(@trits[1, 2])->as_int;
            $ok_r &&= $tr == $sr;
            $ok_c &&= $tc == $sc;
        }
    }
}
ok($ok_r, 'base(-3) two-value addition, result trit');  # 339
ok($ok_c, 'base(-3) two-value addition, carry trit');  # 340

$r = eval { Math::Logic::Ternary::Trit::nonexistent() };
ok(!defined $r);                        # 341
like($@, qr/^Undefined subroutine /);   # 342

$r = eval { Math::Logic::Ternary::Trit::nonexistent(0) };
ok(!defined $r);                        # 343
like($@, qr/^Undefined subroutine /);   # 344

$r = eval { $n->nonexistent };
ok(!defined $r);                        # 345
like($@, qr/^Can't locate /);           # 346

$r = eval { Math::Logic::Ternary::Trit->nonexistent };
ok(!defined $r);                        # 347
like($@, qr/^Can't locate /);           # 348

$r = eval { $n->pty };
ok(!defined $r);                        # 349
like($@, qr/^too few arguments, expected 1 more /);  # 350

$r = $n->can('as_int_u');
is(ref($r), 'CODE');                    # 351
is(eval { $r->($f) }, 2);               # 352

$r = $n->can('not');
is(ref($r), 'CODE');                    # 353

$r = $n->can('gtu');
is(ref($r), 'CODE');                    # 354
is(eval { $r->($f, $t) }, $t);          # 355

$r = $n->can('b012122010');
ok(!defined $r);                        # 356

$r = $n->can('x111');
ok(!defined $r);                        # 357

$r = eval { $n->generic('nonexistent') };
ok(!defined $r);                        # 358
like($@, qr/^unknown operator name "nonexistent"/);  # 359

$r = eval { $f->mpx };
ok(!defined $r);                        # 360
like($@, qr/^too few arguments, expected 3 more /);  # 361

my $my_op = Math::Logic::Ternary::Trit->make_generic(
    'Q' .
    '000001011000001011000001011' .
    '000001011001011111011111112' .
    '000001011011111112001011111'
);
is($my_op->($n, $n, $n, $n), $n);       # 362
is($my_op->($t, $f, $f, $f), $f);       # 363
is($my_op->($f, $t, $f, $f), $f);       # 364

my @op = Math::Logic::Ternary::Trit->trit_operators;
my %ar = map {@{$_}[0, 1]} @op;
my $nop = @op;
print "# got $nop named trit operators\n";
ok($nop >= 9, 'operator list minimum length');  # 365
is($nop - keys %ar, 0, 'no duplicate list entries');  # 366
my $cant = grep { !$n->can($_->[0]) } @op;
is($cant, 0, 'no missing methods');     # 367
is($ar{'true'}, 0);                     # 368
is($ar{'not'}, 1);                      # 369
is($ar{'and'}, 2);                      # 370
is($ar{'or'}, 2);                       # 371
is($ar{'xor'}, 2);                      # 372
is($ar{'eqv'}, 2);                      # 373
is($ar{'incr'}, 2);                     # 374
is($ar{'add'}, 3);                      # 375
is($ar{'max'}, 3);                      # 376
is($ar{'sum'}, 4);                      # 377
is($ar{'mpx'}, 4);                      # 378

my @lfsr = ($t, ($n) x 8);
my $gen_ok = 1;
foreach my $count (1..500) {
    my $on = join q[], 'b', @tvu[ map { $_->as_int_u } @lfsr ];
    my $r = $n->generic($on, $n);
    if ($r != $lfsr[0]) {
        $gen_ok = 0;
        last;
    }
    my $t = pop @lfsr;
    unshift @lfsr, $t->not;
    $lfsr[4] = $lfsr[4]->incr($t);
}
ok($gen_ok, 'generic op mass production works');  # 379

is($t->is_equal($t), !0);               # 380
is($t->is_equal($f), !1);               # 381
is($t->is_equal($n), !1);               # 382
is($f->is_equal($t), !1);               # 383
is($f->is_equal($f), !0);               # 384
is($f->is_equal($n), !1);               # 385
is($n->is_equal($t), !1);               # 386
is($n->is_equal($f), !1);               # 387
is($n->is_equal($n), !0);               # 388

__END__
