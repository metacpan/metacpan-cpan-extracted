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
use Test::More tests => 10;
use v5.14;
use lib 'lib';
use Game::Collisions;


my $collide = Game::Collisions->new;

$collide->make_aabb({
    x => 0,
    y => 0,
    length => 1,
    height => 1,
});
my $root = $collide->{root_aabb};
isa_ok( $root, 'Game::Collisions::AABB', "Root node setup" );
ok(! defined $root->left_node, "No deeper nodes setup" );
ok(! defined $root->right_node, "No deeper nodes setup" );
cmp_ok( $root->length, '==', 1, "Root size set" );
cmp_ok( $root->height, '==', 1, "Root size set" );

$collide->make_aabb({
    x => 1,
    y => 0,
    length => 1,
    height => 3,
});
my $new_root = $collide->{root_aabb};
cmp_ok( $new_root, '!=', $root, "New root in place" );
cmp_ok( $new_root->right_node, '==', $root,
    "Old root now on right of new root" );
cmp_ok( $new_root->left_node->x, '==', 1, "New AABB put in place on left" );
cmp_ok( $new_root->length, '==', 2, "Root expanded to fill space" );
cmp_ok( $new_root->height, '==', 3, "Root exapnded to fill space" );
