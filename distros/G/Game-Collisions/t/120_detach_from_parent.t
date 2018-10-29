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
use Test::More tests => 5;
use v5.14;
use lib 'lib';
use Game::Collisions;


my $box1 = Game::Collisions::AABB->new({
    x => 0,
    y => 0,
    length => 1,
    height => 1,
});
my $box2 = Game::Collisions::AABB->new({
    x => 1,
    y => 0,
    length => 1,
    height => 1,
});
my $box3 = Game::Collisions::AABB->new({
    x => 3,
    y => 0,
    length => 1,
    height => 1,
});
my $box4 = Game::Collisions::AABB->new({
    x => 2,
    y => 0,
    length => 3,
    height => 1,
});
my $box5 = Game::Collisions::AABB->new({
    x => 5,
    y => 0,
    length => 3,
    height => 1,
});


$box1->set_left_node( $box2 );
$box1->set_right_node( $box3 );
$box2->set_left_node( $box4 );
$box2->set_right_node( $box5 );

$box4->_detach_from_parent;
ok(! defined $box4->parent, "Box4 no longer attached to a parent" );
cmp_ok( $box1->left_node(), '==', $box5, "Box5 becomes new left node to box1" );

$box5->_detach_from_parent;
ok(! defined $box5->parent, "Box5 no longer attached to a parent" );
ok(! defined $box1->left_node, "Box1 no longer has a left node" );
ok( $box1->is_branch_node, "Box1 is still a branch node" );
