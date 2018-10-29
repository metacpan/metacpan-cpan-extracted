# Copyright (c) 2018  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 1;
use Test::Deep;
use v5.14;
use lib 'lib';
use Game::Collisions;


my $collide = Game::Collisions->new;
my $box1 = $collide->make_aabb({
    x => 0,
    y => 0,
    length => 4,
    height => 4,
});
my $box2 = $collide->make_aabb({
    x => 1,
    y => 1,
    length => 1,
    height => 1,
});
my $box3 = $collide->make_aabb({
    x => 2,
    y => 1,
    length => 2,
    height => 2,
});
my $box4 = $collide->make_aabb({
    x => 3,
    y => 1,
    length => 1,
    height => 1,
});
my $box5 = $collide->make_aabb({
    x => 3,
    y => 2,
    length => 1,
    height => 1,
});
my $box6 = $collide->make_aabb({
    x => 0,
    y => 1,
    length => 1,
    height => 1,
});


$box1->set_left_node( $box2 );
$box1->set_right_node( $box3 );
$box3->set_left_node( $box4 );
$box3->set_right_node( $box5 );

my $sibling = $box1->find_best_sibling_node( $box6 );
cmp_ok( $sibling, '==', $box2, "Box2 is best sibling" );
