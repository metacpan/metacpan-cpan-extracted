#!/usr/local/cpanel/3rdparty/bin/perl
# cpanel - t/rename.t                             Copyright(c) 2016 cPanel, Inc.
#                                                           All rights Reserved.
# copyright@cpanel.net                                         http://cpanel.net
# This code is subject to the cPanel license. Unauthorized copying is prohibited

use strict;
use warnings;

use Test::More ( 'tests' => 2 );
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;

use File::Temp;

use Filesys::POSIX                ();
use Filesys::POSIX::IO::Handle    ();
use Filesys::POSIX::Mem           ();
use Filesys::POSIX::Real          ();
use Filesys::POSIX::Userland::Tar ();
use Filesys::POSIX::Extensions    ();

my $tempdir1 = File::Temp->newdir;
my $tempdir2 = File::Temp->newdir;

open my $fh, '>', "$tempdir1/item1.txt";
close $fh;

my $fs = Filesys::POSIX->new( Filesys::POSIX::Real->new, path => $tempdir1 );

$fs->map( $tempdir1, "/dir" );

my $do_tar = sub {
    open my $tar_fh, ">", "$tempdir2/test.tar";
    my $handle = Filesys::POSIX::IO::Handle->new($tar_fh);
    $fs->tar( $handle, "/dir/" );
    chomp( my @tar = `tar tf $tempdir2/test.tar 2>/dev/null` );
    return @tar;
};

# Case 57600
{
    my @expected = qw(dir dir/item2.txt);
    my %found;

    $fs->rename( 'dir/item1.txt' => 'dir/item2.txt' );

    my @items = $do_tar->();

    foreach my $item (@items) {
        foreach my $expected_item (@expected) {
            $found{$item} = 1 if $item =~ /\Q$expected_item\E(?:|\/)$/;
        }
    }

    is( scalar @expected => scalar keys %found, 'Found the correct number of items archived' );
}
