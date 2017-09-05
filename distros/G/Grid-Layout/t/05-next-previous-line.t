#!/usr/bin/perl
use strict;
use warnings;

use Test::Simple tests => 28;
use Test::More;
# use Test::Files;
use Test::Exception;

use Grid::Layout;
use Grid::Layout::Render;

my $gl = Grid::Layout->new();

my $v_l_1 = $gl->add_vertical_line   ();
my $v_l_2 = $gl->add_vertical_line   ();
my $v_l_3 = $gl->add_vertical_line   ();
my $v_l_4 = $gl->add_vertical_line   ();
my $v_l_5 = $gl->add_vertical_line   ();

my $h_l_1 = $gl->add_horizontal_line ();
my $h_l_2 = $gl->add_horizontal_line ();
my $h_l_3 = $gl->add_horizontal_line ();
my $h_l_4 = $gl->add_horizontal_line ();


is($gl->_line('V', 0)->next_line   , $v_l_1);
is($gl->_line('V', 0)->next_line(1), $v_l_1);
is($gl->_line('V', 0)->next_line(2), $v_l_2);
is($v_l_1->next_line(3), $v_l_3->next_line(1));
is($v_l_1->next_line(3), $v_l_3->next_line   );

is($gl->_line('H', 0)->next_line   , $h_l_1);
is($gl->_line('H', 0)->next_line(1), $h_l_1);
is($gl->_line('H', 0)->next_line(2), $h_l_2);
is($h_l_1->next_line(3), $h_l_3->next_line(1));
is($h_l_1->next_line(3), $h_l_3->next_line   );


is($v_l_1->previous_line   , $gl->_line('V', 0));
is($v_l_1->previous_line(1), $gl->_line('V', 0));
is($gl->_line('V', 0), $v_l_2->previous_line(2));
is($v_l_1->previous_line(1), $v_l_3->previous_line(3));
is($v_l_1->previous_line   , $v_l_3->previous_line(3) );

is($gl->_line('H', 0), $h_l_1->previous_line   );
is($gl->_line('H', 0), $h_l_1->previous_line(1));
is($gl->_line('H', 0), $h_l_2->previous_line(2));
is($h_l_1->previous_line(1), $h_l_3->previous_line(3));
is($h_l_1->previous_line   , $h_l_3->previous_line(3));

throws_ok {$h_l_1->previous_line(2);} qr{Cannot return previous line 2, I am line 1};
throws_ok {$h_l_2->previous_line(3);} qr{Cannot return previous line 3, I am line 2};
throws_ok {$v_l_1->previous_line(2);} qr{Cannot return previous line 2, I am line 1};
throws_ok {$v_l_2->previous_line(3);} qr{Cannot return previous line 3, I am line 2};

throws_ok {$h_l_4->next_line(1);} qr{Cannot return next line 1, I am line 4};
throws_ok {$h_l_3->next_line(2);} qr{Cannot return next line 2, I am line 3};
throws_ok {$v_l_5->next_line(1);} qr{Cannot return next line 1, I am line 5};
throws_ok {$v_l_4->next_line(2);} qr{Cannot return next line 2, I am line 4};
