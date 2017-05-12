#!/bin/perl

BEGIN {print "1..21\n";}
END {print "not ok 1\n" unless $loaded;}
use File::RsyncP;
$loaded = 1;
print "ok 1\n";

my @TestFiles = (
    {
        name  => "xxx/yyy/aaa1",
        mode  => 0100755,
        uid   => 987,
        gid   => 654,
        size  => 654321,
        mtime => time,
    },
    {
        name  => "xxx/yyy/aaa2",
        mode  => 0060755,
        uid   => 987,
        gid   => 654,
        rdev_major  => 0x23,
        rdev_minor  => 0x46,
        size  => 654321,
        mtime => time,
    },
    {
        name  => "xxx/zzz/bbb1",
        mode  => 0060666,
        uid   => 9876,
        gid   => 6543,
        rdev_major  => 0x23,
        rdev_minor  => 0x45,
        size  => 65432,
        mtime => time + 1,
    },
    {
        name  => "xxx/yyy/aaa3",
        dev   => 9123,
        inode => 9123456,
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => 65432,
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb2",
        dev   => 9123,
        inode => 9123458,
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => 65432,
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb3",
        dev   => (1 << 31) * 123 + (5432 << 18),
        inode => (1 << 31) * 12  + (6543 << 17),
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => (1 << 31) * 3 + (1 << 29), 
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb4",
        dev   => (1 << 31) * 123 + (5432 << 18),
        inode => (1 << 31) * 12  + (6543 << 17) + 1,
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => (1 << 31) * 3 + (1 << 29), 
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb5",
        dev   => (1 << 31) * 123 + (5432 << 18),
        inode => (1 << 31) * 12  + (6543 << 17) + 2,
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => (1 << 31) * 3 + (1 << 29), 
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb6",
        dev   => (1 << 31) * 123 + (5432 << 18),
        inode => (1 << 31) * 12  + (6543 << 17) + 3,
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => (1 << 31) * 3 + (1 << 29), 
        mtime => time + 1,
    },
    {
        name  => "xxx/zzz/bbb7",
        mode  => 0100666,
        uid   => 9876,
        gid   => 6543,
        size  => (1 << 31) * 3 + (1 << 29), 
        mtime => time + 1,
    },
);

my $testNum = 2;

for my $protocol ( qw(26 28) ) {
    for my $preserve_hard_links ( qw(0 1) ) {
        $testNum = run_test($testNum, $protocol, $preserve_hard_links);
    }
}

sub run_test
{
    my($testNum, $protocol, $preserve_hard_links) = @_;

    my $args = {
        preserve_uid        => 1,                       # --owner
        preserve_gid        => 1,                       # --group
        preserve_links      => 1,                       # --links
        preserve_devices    => 1,                       # --devices
        preserve_hard_links => $preserve_hard_links,    # --hard-links
        always_checksum     => 0,                       # --checksum
        protocol_version    => $protocol,               # protocol version
    };

    my @testFiles;
    foreach my $f ( @TestFiles ) {
        my $f2 = { %$f };
        if ( !$preserve_hard_links ) {
            delete($f2->{dev});
            delete($f2->{inode});
        }
        push(@testFiles, $f2);
    }

    my $fList = File::RsyncP::FileList->new($args);

    for ( my $i = 0 ; $i < @testFiles ; $i++ ) {
        $fList->encode($testFiles[$i]);
    }
    if ( $fList->count == @testFiles ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;

    my $ok = 1;
    for ( my $i = 0 ; $i < @testFiles ; $i++ ) {
        my $f = $fList->get($i);
        foreach my $k ( keys(%{$testFiles[$i]}) ) {
            if ( !defined($f->{$k}) ) {
                print(STDERR "testFiles[$i]{$k} is $testFiles[$i]{$k}, but result is undef\n");
                $ok = 0;
                next;
            }
            if ( $testFiles[$i]{$k} ne $f->{$k} ) {
                print(STDERR "$i.$k: $testFiles[$i]{$k} vs $f->{$k}\n");
                $ok = 0;
            }
        }
    }
    if ( $ok ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;

    my $data = $fList->encodeData . pack("C", 0);
    #printf(STDERR "Protocol = $protocol, hardlinks = $preserve_hard_links, dataLen = %d\n", length($data));
    #print(STDERR "data = ", unpack("H*", $data), "\n");
    my $fList2 = File::RsyncP::FileList->new($args);

    my $bytesDone = $fList2->decode($data);

    if ( $bytesDone == length($data) ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;

    $ok = 1;
    for ( my $i = 0 ; $i < @testFiles ; $i++ ) {
        my $f = $fList2->get($i);
        foreach my $k ( keys(%{$testFiles[$i]}) ) {
            next if ( $k eq "rdev" );
            if ( !defined($f->{$k}) ) {
                print(STDERR "testFiles[$i]{$k} is $testFiles[$i]{$k}, but result is undef\n");
                $ok = 0;
                next;
            }
            if ( $testFiles[$i]{$k} ne $f->{$k} ) {
                print(STDERR "$i.$k: $testFiles[$i]{$k} vs $f->{$k}\n");
                $ok = 0;
            }
        }
    }
    if ( $ok ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;

    $fList->clean;
    $fList2->clean;
    $ok = 1;
    for ( my $i = 0 ; $i < $fList2->count ; $i++ ) {
        my $f2 = $fList2->get($i);
        my $f = $fList->get($i);
        foreach my $k ( keys(%$f2) ) {
            next if ( $k eq "rdev" );
            if ( !defined($f->{$k}) ) {
                print(STDERR "f2{$k} is $f2->{$k}, but result is undef\n");
                $ok = 0;
                next;
            }
            if ( $f2->{$k} ne $f->{$k} ) {
                print(STDERR "$i.$k: $f2->{$k} vs $f->{$k}\n");
                $ok = 0;
            }
        }
    }
    if ( $ok ) {
        print("ok $testNum\n");
    } else {
        print("not ok $testNum\n");
    }
    $testNum++;

    return $testNum;
}
