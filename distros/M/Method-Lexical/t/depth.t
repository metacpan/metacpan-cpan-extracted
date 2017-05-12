#!/usr/bin/env perl

use strict;
use warnings;

package Class99;

sub new {
    my $class = shift;
    bless [], ref($class) || $class;
}

sub test { 1 }

package Class98;
our @ISA = qw(Class99);

package Class97;
our @ISA = qw(Class98);

package Class96;
our @ISA = qw(Class97);

package Class95;
our @ISA = qw(Class96);

package Class94;
our @ISA = qw(Class95);

package Class93;
our @ISA = qw(Class94);

package Class92;
our @ISA = qw(Class93);

package Class91;
our @ISA = qw(Class92);

package Class90;
our @ISA = qw(Class91);

package Class89;
our @ISA = qw(Class90);

package Class88;
our @ISA = qw(Class89);

package Class87;
our @ISA = qw(Class88);

package Class86;
our @ISA = qw(Class87);

package Class85;
our @ISA = qw(Class86);

package Class84;
our @ISA = qw(Class85);

package Class83;
our @ISA = qw(Class84);

package Class82;
our @ISA = qw(Class83);

package Class81;
our @ISA = qw(Class82);

package Class80;
our @ISA = qw(Class81);

package Class79;
our @ISA = qw(Class80);

package Class78;
our @ISA = qw(Class79);

package Class77;
our @ISA = qw(Class78);

package Class76;
our @ISA = qw(Class77);

package Class75;
our @ISA = qw(Class76);

package Class74;
our @ISA = qw(Class75);

package Class73;
our @ISA = qw(Class74);

package Class72;
our @ISA = qw(Class73);

package Class71;
our @ISA = qw(Class72);

package Class70;
our @ISA = qw(Class71);

package Class69;
our @ISA = qw(Class70);

package Class68;
our @ISA = qw(Class69);

package Class67;
our @ISA = qw(Class68);

package Class66;
our @ISA = qw(Class67);

package Class65;
our @ISA = qw(Class66);

package Class64;
our @ISA = qw(Class65);

package Class63;
our @ISA = qw(Class64);

package Class62;
our @ISA = qw(Class63);

package Class61;
our @ISA = qw(Class62);

package Class60;
our @ISA = qw(Class61);

package Class59;
our @ISA = qw(Class60);

package Class58;
our @ISA = qw(Class59);

package Class57;
our @ISA = qw(Class58);

package Class56;
our @ISA = qw(Class57);

package Class55;
our @ISA = qw(Class56);

package Class54;
our @ISA = qw(Class55);

package Class53;
our @ISA = qw(Class54);

package Class52;
our @ISA = qw(Class53);

package Class51;
our @ISA = qw(Class52);

package Class50;
our @ISA = qw(Class51);

package Class49;
our @ISA = qw(Class50);

package Class48;
our @ISA = qw(Class49);

package Class47;
our @ISA = qw(Class48);

package Class46;
our @ISA = qw(Class47);

package Class45;
our @ISA = qw(Class46);

package Class44;
our @ISA = qw(Class45);

package Class43;
our @ISA = qw(Class44);

package Class42;
our @ISA = qw(Class43);

package Class41;
our @ISA = qw(Class42);

package Class40;
our @ISA = qw(Class41);

package Class39;
our @ISA = qw(Class40);

package Class38;
our @ISA = qw(Class39);

package Class37;
our @ISA = qw(Class38);

package Class36;
our @ISA = qw(Class37);

package Class35;
our @ISA = qw(Class36);

package Class34;
our @ISA = qw(Class35);

package Class33;
our @ISA = qw(Class34);

package Class32;
our @ISA = qw(Class33);

package Class31;
our @ISA = qw(Class32);

package Class30;
our @ISA = qw(Class31);

package Class29;
our @ISA = qw(Class30);

package Class28;
our @ISA = qw(Class29);

package Class27;
our @ISA = qw(Class28);

package Class26;
our @ISA = qw(Class27);

package Class25;
our @ISA = qw(Class26);

package Class24;
our @ISA = qw(Class25);

package Class23;
our @ISA = qw(Class24);

package Class22;
our @ISA = qw(Class23);

package Class21;
our @ISA = qw(Class22);

package Class20;
our @ISA = qw(Class21);

package Class19;
our @ISA = qw(Class20);

package Class18;
our @ISA = qw(Class19);

package Class17;
our @ISA = qw(Class18);

package Class16;
our @ISA = qw(Class17);

package Class15;
our @ISA = qw(Class16);

package Class14;
our @ISA = qw(Class15);

package Class13;
our @ISA = qw(Class14);

package Class12;
our @ISA = qw(Class13);

package Class11;
our @ISA = qw(Class12);

package Class10;
our @ISA = qw(Class11);

package Class9;
our @ISA = qw(Class10);

package Class8;
our @ISA = qw(Class9);

package Class7;
our @ISA = qw(Class8);

package Class6;
our @ISA = qw(Class7);

package Class5;
our @ISA = qw(Class6);

package Class4;
our @ISA = qw(Class5);

package Class3;
our @ISA = qw(Class4);

package Class2;
our @ISA = qw(Class3);

package Class1;
our @ISA = qw(Class2);

package main;

use Test::More tests => 5;

use constant {
    PUBLIC  => 1,
    PRIVATE => 2
};

my $test = Class1->new();
my $name = 'test';

is($test->test(), PUBLIC, 'ordinary inherited method works');

{
    use Method::Lexical 'Class99::test' => sub { PRIVATE };

    is($test->test(),  PRIVATE, 'lexical method override works');
    is($test->test(),  PRIVATE, 'lexical method override works again');
    is($test->$name(), PRIVATE, 'lexical method override works (dynamic)');
    is($test->$name(), PRIVATE, 'lexical method override works again (dynamic)');
}
