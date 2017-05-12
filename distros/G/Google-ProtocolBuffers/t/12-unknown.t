use Test::More tests => 3;
use strict;
use warnings;
use Google::ProtocolBuffers;

Google::ProtocolBuffers->parse(<<'PROTO');

message Double {

  message NestedMessage {
    optional int32 a1 = 1;
    optional int32 a2 = 2;
  }

  enum NestedEnum {
    FOO = 1;
    BAR = 2;
    BAZ = 3;
  }

  // Singular
  optional    int32 a1  =   1;
  optional    int32 a2  =   2;
  optional    int32 a3  =   3;
  optional    int32 a4  =   4;


  optional    int64 b1  =   5;
  optional    int64 b2  =   6;

  optional   uint32 c1  =   7;
  optional   uint32 c2  =   8;
  optional   uint64 d1  =   9;
  optional   uint64 d2  =  10;
  optional   sint32 e1  =  11;
  optional   sint32 e2  =  12;
  optional   sint64 f1  =  13; 
  optional   sint64 f2  =  14; 
  optional  fixed32 g1  =  15;
  optional  fixed32 g2  =  16;
  optional  fixed64 h1  =  17;
  optional  fixed64 h2  =  18;
  optional sfixed32 i1  =  19;
  optional sfixed32 i2  =  20;
  optional sfixed64 j1  =  21;
  optional sfixed64 j2  =  22;
  optional    float k1  =  23;
  optional    float k2  =  24;
  optional   double l1  =  25;
  optional   double l2  =  26;
  optional     bool m1  =  27;
  optional     bool m2  =  28;
  optional   string n1  =  29;
  optional   string n2  =  30;
  optional    bytes o1  =  31;
  optional    bytes o2  =  32;

  optional group Group1 = 33 {
    optional int32 a1 = 1;
    optional int32 a2 = 2;
  }

  optional group Group2 = 34 {
    optional int32 a1 = 1;
    optional int32 a2 = 2;
  }

  optional NestedMessage   p1 = 35 ;
  optional NestedMessage   p2 = 36 ;
  optional NestedEnum      q1 = 37 ;
  optional NestedEnum      q2 = 38 ;
}

message Single {

  message NestedMessage {
    optional int32 a1 = 1;
    //optional int32 a2 = 2;
  }

  enum NestedEnum {
    FOO = 1;
    BAR = 2;
    BAZ = 3;
  }

  // Singular
  optional    int32 a1  =   1;
  //optional    int32 a2  =   2;
  optional    int32 a3  =   3;
  //optional    int32 a4  =   4;


  optional    int64 b1  =   5;
  //optional    int64 b2  =   6;

  optional   uint32 c1  =   7;
  //optional   uint32 c2  =   8;
  optional   uint64 d1  =   9;
  //optional   uint64 d2  =  10;
  optional   sint32 e1  =  11;
  //optional   sint32 e2  =  12;
  optional   sint64 f1  =  13; 
  //optional   sint64 f2  =  14; 
  optional  fixed32 g1  =  15;
  //optional  fixed32 g2  =  16;
  optional  fixed64 h1  =  17;
  //optional  fixed64 h2  =  18;
  optional sfixed32 i1  =  19;
  //optional sfixed32 i2  =  20;
  optional sfixed64 j1  =  21;
  //optional sfixed64 j2  =  22;
  optional    float k1  =  23;
  //optional    float k2  =  24;
  optional   double l1  =  25;
  //optional   double l2  =  26;
  optional     bool m1  =  27;
  //optional     bool m2  =  28;
  optional   string n1  =  29;
  //optional   string n2  =  30;
  optional    bytes o1  =  31;
  //optional    bytes o2  =  32;

  optional group Group1 = 33 {
    optional int32 a1 = 1;
    //optional int32 a2 = 2;
  }

  //optional group Group2 = 34 {
  //  optional int32 a1 = 1;
  //  optional int32 a2 = 2;
  //}

  optional NestedMessage   p1 = 35 ;
  //optional NestedMessage   p2 = 36 ;
  optional NestedEnum      q1 = 37 ;
  //optional NestedEnum      q2 = 38 ;
}
PROTO

my $double  = {
    a1  =>   1,
    a2  =>   2,
    a3  =>   3,
    a4  =>   4,
    b1  =>   5,
    b2  =>   6,
    c1  =>   7,
    c2  =>   8,
    d1  =>   9,
    d2  =>  10,
    e1  =>  11,
    e2  =>  12,
    f1  =>  13, 
    f2  =>  14, 
    g1  =>  15,
    g2  =>  16,
    h1  =>  17,
    h2  =>  18,
    i1  =>  19,
    i2  =>  20,
    j1  =>  21,
    j2  =>  22,
    k1  =>  23,
    k2  =>  24,
    l1  =>  25,
    l2  =>  26,
    m1  =>  1,
    m2  =>  1,
    n1  =>  "asdf",
    n2  =>  "zxcv",
    o1  =>  "123",
    o2  =>  "098",

    Group1 =>  {
        a1 => 1,
        a2 => 2,
  },

    Group2 => {
        a1 => 1,
        a2 => 2,
  },

    p1 => { a1 => 100, a2 => 200 },
    p2 => { a1 => 300, a2 => 400 },
    q1 => 2 ,
    q2 => 2 ,
};

my $single = { 
    a1  =>   1,
    a3  =>   3,
    b1  =>   5,
    c1  =>   7,
    d1  =>   9,
    e1  =>  11,
    f1  =>  13, 
    g1  =>  15,
    h1  =>  17,
    i1  =>  19,
    j1  =>  21,
    k1  =>  23,
    l1  =>  25,
    m1  =>  1,
    n1  =>  "asdf",
    o1  =>  "123",

    Group1 =>  {
        a1 => 1,
  },

    p1 => { a1 => 100, },
    q1 => 2 ,
};

my $str = Double->encode($double);
is($str, 
    "\x{08}\x{01}\x{10}\x{02}\x{18}\x{03}\x{20}\x{04}\x{28}\x{05}\x{30}\x{06}".
    "\x{38}\x{07}\x{40}\x{08}\x{48}\x{09}\x{50}\x{0a}\x{58}\x{16}\x{60}\x{18}".
    "\x{68}\x{1a}\x{70}\x{1c}\x{7d}\x{0f}\x{00}\x{00}\x{00}\x{85}\x{01}\x{10}".
    "\x{00}\x{00}\x{00}\x{89}\x{01}\x{11}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}".
    "\x{00}\x{91}\x{01}\x{12}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{9d}".
    "\x{01}\x{13}\x{00}\x{00}\x{00}\x{a5}\x{01}\x{14}\x{00}\x{00}\x{00}\x{a9}".
    "\x{01}\x{15}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{b1}\x{01}\x{16}".
    "\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{bd}\x{01}\x{00}\x{00}\x{b8}".
    "\x{41}\x{c5}\x{01}\x{00}\x{00}\x{c0}\x{41}\x{c9}\x{01}\x{00}\x{00}\x{00}".
    "\x{00}\x{00}\x{00}\x{39}\x{40}\x{d1}\x{01}\x{00}\x{00}\x{00}\x{00}\x{00}".
    "\x{00}\x{3a}\x{40}\x{d8}\x{01}\x{01}\x{e0}\x{01}\x{01}\x{ea}\x{01}\x{04}".
    "\x{61}\x{73}\x{64}\x{66}\x{f2}\x{01}\x{04}\x{7a}\x{78}\x{63}\x{76}\x{fa}".
    "\x{01}\x{03}\x{31}\x{32}\x{33}\x{82}\x{02}\x{03}\x{30}\x{39}\x{38}\x{8b}".
    "\x{02}\x{08}\x{01}\x{10}\x{02}\x{8c}\x{02}\x{93}\x{02}\x{08}\x{01}\x{10}".
    "\x{02}\x{94}\x{02}\x{9a}\x{02}\x{05}\x{08}\x{64}\x{10}\x{c8}\x{01}\x{a2}".
    "\x{02}\x{06}\x{08}\x{ac}\x{02}\x{10}\x{90}\x{03}\x{a8}\x{02}\x{02}\x{b0}".
    "\x{02}\x{02}"
);
is_deeply(Double->decode($str), $double);

is_deeply(Single->decode($str), $single);
