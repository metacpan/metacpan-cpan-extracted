# Copyright (c) 2016  Timm Murray
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
use Test::More tests => 12;
use strict;
use warnings;
use Game::Asset;


my $asset = Game::Asset->new({
    file => 't_data/test1.zip',
});
isa_ok( $asset => 'Game::Asset' );

my %mappings = $asset->mappings;
cmp_ok( $mappings{yml}, 'eq', 'Game::Asset::YAML',
    "YAML mapping automatically set" );
cmp_ok( $mappings{pm}, 'eq', 'Game::Asset::PerlModule',
    "Perl Module mapping automatically set" );
cmp_ok( $mappings{txt}, 'eq', 'Game::Asset::PlainText',
    "Plain Text mapping automatically set" );
cmp_ok( $mappings{nll}, 'eq', 'Game::Asset::Null',
    "Null mapping set from index.yml" );

my @entries = map { $_->[0] }
    sort { $a->[1] cmp $b->[1] }
    map {[ $_, $_->name ]} $asset->entries;
cmp_ok( scalar @entries, '==', 5, "Correct number of entries" );
cmp_ok( $entries[0]->name, 'eq', 'bar', "Correct first entry" );
cmp_ok( $entries[1]->name, 'eq', 'baz', "Correct second entry" );
cmp_ok( $entries[2]->name, 'eq', 'foo', "Correct third entry" );
cmp_ok( $entries[3]->name, 'eq', 'qux', "Correct fourth entry" );

my $foo = $asset->get_by_name( 'foo' );
cmp_ok( $foo->name, 'eq', 'foo', "Got asset by name" );
cmp_ok( $foo->type, 'eq', 'yml', "Got type" );
