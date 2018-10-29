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
use Test::More tests => 8;
use v5.14;
use lib 'lib';
use Game::Collisions;


my $collide = Game::Collisions->new;
isa_ok( $collide, 'Game::Collisions' );

my $box1 = $collide->make_aabb({
    x => 0,
    y => 0,
    length => 1,
    height => 1,
    user_data => "foobar",
});
isa_ok( $box1, 'Game::Collisions::AABB' );

my $box2 = $collide->make_aabb({
    x => 2,
    y => 0,
    length => 1,
    height => 1,
});
my $box3 = $collide->make_aabb({
    x => 1,
    y => 0,
    length => 2,
    height => 1,
});

ok(! $box1->does_collide( $box2 ), "Box1 does not collide with Box2" );
ok( $box1->does_collide( $box3 ), "Box1 just touches box3" );
ok( $box2->does_collide( $box3 ), "Box2 overlaps box3" );
ok(! $box3->does_fully_enclose( $box1 ), "Box3 does not enclose box1" );
ok( $box3->does_fully_enclose( $box2 ), "Box3 does enclose box2" );
cmp_ok( $box1->user_data, 'eq', 'foobar', "User data is retrieved" );
