#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 20;

use_ok('File::FStore');

{
    # Domains:
    my %res = map{$_ => 1} File::FStore->known('domains');
    ok(delete($res{digests}),    'Domain digests is known');
    ok(delete($res{properties}), 'Domain properies is known');
    is(scalar(keys %res), 0,     'No additional domains');
}

{
    # Properties:
    my %res = map{$_ => 1} File::FStore->known('properties');
    ok(delete($res{size}),        'Property size is known');
    ok(delete($res{inode}),       'Property inode is known');
    ok(delete($res{mediasubtype}),'Property mediasubtype is known');
    ok(delete($res{contentise}),  'Property contentise is known');
    ok(delete($res{inodeise}),    'Property inodeise is known');
    is(scalar(keys %res), 0,      'No additional properties');
}

{
    # Digests:
    my %res = map{$_ => 1} File::FStore->known('digests');
    ok(delete($res{'sha-1-160'}),'Digest sha-1-160 is known');
    ok(delete($res{'sha-2-512'}),'Digest sha-2-512 is known');
    ok(delete($res{'sha-3-512'}),'Digest sha-3-512 is known');
}

{
    # Link styles:
    my %res = map{$_ => 1} File::FStore->known('link_styles');
    ok(delete($res{'none'}),    'Link style X is known');
    ok(delete($res{'1-level'}), 'Link style X is known');
    ok(delete($res{'2-level'}), 'Link style X is known');
    is(scalar(keys %res), 0,    'No additional link styles');
}

{
    # Store styles:
    my %res = map{$_ => 1} File::FStore->known('store_styles');
    ok(delete($res{'1-level-contentise'}),  'Store style X is known');
    ok(delete($res{'2-level-contentise'}),  'Store style X is known');
    is(scalar(keys %res), 0,                'No additional store styles');
}

exit 0;
