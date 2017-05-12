#!/usr/bin/perl -w

use Test::More tests => 4;
use Test::NoWarnings;
use Mac::Alias::Parse;
use MIME::Base64;
use Data::Dumper;

{
    local($/) = "";
    $sample1 = decode_base64(<DATA>);
}

$expect1 = {
    target => {
        kind => 0,
        created => 3418992225,
        createdUTC => 3419017425,
        long_name => 'a.out',
        name => 'a.out',
        inode => 1575488
    },
    folder => {
        name => 'parsealias',
        inode => 1572374
    },
    inode_path => [ 1572374, 1232561, 280375 ],
    posix_homedir_length => 19,
    posix_path => '/wiml/src/parsealias/a.out',
    carbon_path => 'Users:wiml:src:parsealias:a.out',
    volume => {
        type => 0,
        signature => 'H+',
        flags => 2304,
        name => 'Users',
        long_name => 'Users',
        created => 3414603965,
        createdUTC => 3414629165,
        posix_path => '/Volumes/Users'
    }
};

sub test_roundtrip {
    my($sample_bytes, $sample_rec) = @_;
    my($got, $regot);

    $got = Mac::Alias::Parse::unpack_alias($sample_bytes);
    is_deeply($got, $sample_rec);
    $regot = Mac::Alias::Parse::pack_alias(%$got);

    # We check the first 150 bytes for equality here.
    # Unfortunately the rest of the alias record
    # is tag-length-value structures whose order is
    # unimportant, and we don't generate them in the
    # same order that MacOS does.
    is(substr($regot, 0, 150), substr($sample_bytes, 0, 150));

    # Failing a byte-exact roundtrip back to alias record,
    # at least test that we can once again parse it back to
    # the fields we expect.
    is_deeply(Mac::Alias::Parse::unpack_alias($regot), $got);
}

&test_roundtrip($sample1, $expect1);

__END__

AAAAAAFKAAIAAAVVc2VycwAAAAAAAAAAAAAAAAAAAAAAAAAAAADLhri9SCsAAAAX
/hYFYS5vdXQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAABgKQMvJrmEAAAAAAAAAAP////8AAAkAAAAAAAAA
AAAAAAAAAAAACnBhcnNlYWxpYXMAEAAIAADLhxstAAAAEQAIAADLyhDRAAAAAQAM
ABf+FgASzrEABEc3AAIAH1VzZXJzOndpbWw6c3JjOnBhcnNlYWxpYXM6YS5vdXQA
AA4ADAAFAGEALgBvAHUAdAAPAAwABQBVAHMAZQByAHMAEgAaL3dpbWwvc3JjL3Bh
cnNlYWxpYXMvYS5vdXQAEwAOL1ZvbHVtZXMvVXNlcnMAFQACABP//wAA


