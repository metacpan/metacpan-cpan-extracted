#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command need_parts );

use Langertha::Holmgang::Sim::Linux ();

# Platten und Dateisysteme auf dem Linux-Simulator.
# Behauptet wird: lvextend ohne -r vergroessert nur das LV, df sieht es erst nach
# resize2fs; resize2fs auf XFS scheitert, xfs_growfs waechst; pvcreate verweigert
# eingehaengte Platten; vgextend macht eine leere Platte zum PV; umount legt die
# Dateien am Geraet ab, mount holt sie zurueck (auch per UUID aus fstab), ein
# laufender Dienst mit uses haelt den Einhaengepunkt fest; remount aendert die
# Optionen; e2fsck verweigert Eingehaengtes und raeumt Fehler; swapon braucht
# mkswap; tune2fs -m aendert, was df frei zeigt; mdadm entfernt nur Defekte, sfdisk
# kopiert die Tabelle, growpart waechst die letzte Partition.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);
my $T = JSON::MaybeXS::true();

sub world {
    my $s = { srv => {
        type => 'linux', hostname => 'srv',
        interfaces => { eth0 => { addr => ['10.20.0.5/24'], state => 'UP' } },
        storage => {
            disks => {
                '/dev/vda' => { size => '40G' }, '/dev/vda1' => { size => '1G', parent => '/dev/vda', fstype => 'ext4', uuid => 'b001' },
                '/dev/vda2' => { size => '39G', parent => '/dev/vda', fstype => 'LVM2_member' },
                '/dev/vdb' => { size => '100G' },
                '/dev/vdc' => { size => '50G', fstype => 'ext4', uuid => 'c0ffee00-0000-4000-8000-000000000001', label => 'daten' },
                '/dev/vdd' => { size => '20G', fstype => 'xfs', uuid => 'd0d0' },
                '/dev/sda' => { size => '40G' }, '/dev/sda1' => { size => '39G', parent => '/dev/sda', fstype => 'linux_raid_member', ptype => 'fd' },
                '/dev/sdb' => { size => '40G' }, '/dev/sdb1' => { size => '39G', parent => '/dev/sdb', fstype => 'linux_raid_member', ptype => 'fd' },
                '/dev/sdc' => { size => '40G' },
            },
            vgs => { vg0 => { pvs => ['/dev/vda2'], lvs => { root => { size => '15G', fstype => 'ext4', uuid => 'r00t' }, var => { size => '20G', fstype => 'ext4', uuid => 'va12' } } } },
            md => { '/dev/md0' => { level => 'raid1', raid_disks => 2, size => '39G', members => { '/dev/sda1' => 'active', '/dev/sdb1' => 'faulty' } } },
        },
        mounts => {
            '/'     => { dev => '/dev/mapper/vg0-root', size => '15G', used => '5G' },
            '/var'  => { dev => '/dev/mapper/vg0-var', size => '20G', used => '19G' },
            '/data' => { dev => '/dev/vdc', size => '50G', used => '10G', reserved_pct => 5 },
            '/srv/xfs' => { dev => '/dev/vdd', size => '10G', used => '9G' },
        },
        files => {
            '/data/a.txt' => 'A',
            '/etc/fstab' => "/dev/mapper/vg0-root / ext4 errors=remount-ro 0 1\nUUID=c0ffee00-0000-4000-8000-000000000001 /data ext4 defaults 0 2\n",
        },
        dirs => { '/mnt/neu' => {} },
        services => { app => { active => $T, uses => ['/data'] } },
    } };
    Langertha::Holmgang::Sim::Linux->prepare( $s->{srv}, { host => 'srv', state => $s } );
    return $s;
}
sub run { my ( $s, $c ) = @_; my ( $o, $ok ) = run_command( $s, 'srv', $c ); return wantarray ? ( $o, $ok ) : $o }

subtest LVM => sub {
    my $s = world();
    like( run( $s, 'vgs' ), qr/vg0\s+1\s+2\s+0\s+wz--n-\s+39g\s+4g/, 'vgs: frei 4g' );
    my ( $o, $ok ) = run( $s, 'lvextend -L +10G /dev/vg0/var' );
    ok( !$ok, 'zu wenig frei' );
    like( $o, qr/Insufficient free space/, '… Meldung' );
    run( $s, 'vgextend vg0 /dev/vdb' );
    is( $s->{srv}{storage}{disks}{'/dev/vdb'}{fstype}, 'LVM2_member', 'vgextend legt PV an' );
    run( $s, 'lvextend -L +10G /dev/vg0/var' );
    is( $s->{srv}{storage}{vgs}{vg0}{lvs}{var}{size}, '30G', 'LV gewachsen' );
    is( $s->{srv}{mounts}{'/var'}{size}, '20G', '… das Dateisystem nicht' );
    like( run( $s, 'df -h /var' ), qr/20G/, 'df sieht 20G' );
    run( $s, 'resize2fs /dev/mapper/vg0-var' );
    is( $s->{srv}{mounts}{'/var'}{size}, '30G', 'resize2fs online' );
    run( $s, 'lvextend -r -l +100%FREE vg0/root' );
    is( $s->{srv}{mounts}{'/'}{size}, '109G', 'lvextend -r -l +100%FREE' );
    ( $o, $ok ) = run( $s, 'pvcreate /dev/vdc' );
    ok( !$ok, 'pvcreate auf eingehaengter Platte' );
    like( $o, qr/Mounted filesystem/, '… Meldung' );
};

subtest XFS => sub {
    my $s = world();
    $s->{srv}{storage}{disks}{'/dev/vdd'}{size} = '20G';
    my ( $o, $ok ) = run( $s, 'resize2fs /dev/vdd' );
    ok( !$ok, 'resize2fs auf XFS' );
    like( $o, qr/Bad magic number/, '… Meldung' );
    run( $s, 'xfs_growfs /srv/xfs' );
    is( $s->{srv}{mounts}{'/srv/xfs'}{size}, '20G', 'xfs_growfs' );
};

subtest 'mount und fstab' => sub {
    my $s = world();
    my ( $o, $ok ) = run( $s, 'umount /data' );
    ok( !$ok, 'Dienst haelt /data' );
    like( $o, qr/target is busy/, '… busy' );
    run( $s, 'systemctl stop app; umount /data' );
    ok( !$s->{srv}{mounts}{'/data'}, 'ausgehaengt' );
    ok( !$s->{srv}{files}{'/data/a.txt'}, 'Dateien weg' );
    run( $s, 'mount /dev/vdc /mnt/neu' );
    is( $s->{srv}{files}{'/mnt/neu/a.txt'}, 'A', 'unter anderem Punkt wieder da' );
    run( $s, 'umount /mnt/neu && mount -a' );
    is( $s->{srv}{files}{'/data/a.txt'}, 'A', 'mount -a per UUID' );
    run( $s, 'mount -o remount,noexec,nosuid /data' );
    is( $s->{srv}{mounts}{'/data'}{opts}, 'rw,relatime,noexec,nosuid', 'remount' );
    $s->{srv}{files}{'/etc/fstab'} .= "UUID=fehlt /mnt/x ext4 defaults 0 2\n";
    ( $o, $ok ) = run( $s, 'findmnt --verify' );
    ok( !$ok, 'findmnt --verify' );
    like( $o, qr/unreachable source: UUID=fehlt.*\n.*target does not exist/s, '… Fehler' );
    ( $o, $ok ) = run( $s, 'mount -a' );
    like( $o, qr/hint\) your fstab has been modified/, 'Hinweis auf daemon-reload' );
    like( $o, qr/can't find UUID=fehlt/, '… und der Fehler' );
    run( $s, 'systemctl daemon-reload' );
    unlike( run( $s, 'mount -a' ), qr/hint/, 'nach daemon-reload kein Hinweis' );
    like( run( $s, 'lsblk -f' ), qr/vdc\s+ext4\s+daten\s+c0ffee00/, 'lsblk -f' );
    is( run( $s, 'lsblk -no NAME,LABEL,UUID /dev/vdc' ), 'vdc daten c0ffee00-0000-4000-8000-000000000001', 'lsblk -no SPALTEN GERAET' );
    like( run( $s, 'blkid /dev/vdc' ), qr{/dev/vdc: LABEL="daten" UUID="c0ffee00-0000-4000-8000-000000000001" BLOCK_SIZE="4096" TYPE="ext4"}, 'blkid' );
};

subtest 'mkfs, fsck, tune2fs' => sub {
    my $s = world();
    my ( $o, $ok ) = run( $s, 'mkfs.ext4 /dev/vdc' );
    ok( !$ok, 'mkfs auf eingehaengt' );
    ( $o, $ok ) = run( $s, 'mkfs.ext4 /dev/vdd' );
    ok( !$ok, 'mkfs auf eingehaengtem XFS' );
    ( $o, $ok ) = run( $s, 'mkfs.ext4 -L neu /dev/vdb' );
    ok( $ok, 'mkfs auf leer' );
    like( run( $s, 'df -h /data' ), qr/50G\s+10G\s+38G/, 'df mit 5% reserviert' );
    run( $s, 'tune2fs -m 1 /dev/vdc' );
    like( run( $s, 'df -h /data' ), qr/50G\s+10G\s+40G/, 'nach tune2fs -m 1' );
    $s->{srv}{storage}{disks}{'/dev/vdc'}{errors} = $T;
    ( $o, $ok ) = run( $s, 'e2fsck -fy /dev/vdc' );
    ok( !$ok, 'e2fsck auf eingehaengt' );
    run( $s, 'systemctl stop app; umount /data; e2fsck -fy /dev/vdc' );
    ok( !$s->{srv}{storage}{disks}{'/dev/vdc'}{errors}, 'Fehler beseitigt' );
};

subtest swap => sub {
    my $s = world();
    run( $s, 'fallocate -l 4G /swapfile' );
    my ( $o, $ok ) = run( $s, 'swapon /swapfile' );
    like( $o, qr/read swap header failed/, 'ohne mkswap' );
    run( $s, 'chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile' );
    is_deeply( $s->{srv}{storage}{swaps}, [ { name => '/swapfile', size => '4.0G' } ], 'aktiv' );
    like( run( $s, 'swapon --show' ), qr{/swapfile\s+file\s+4.0G}, 'swapon --show' );
};

subtest 'mdadm und Partitionen' => sub {
    my $s = world();
    my ( $o, $ok ) = run( $s, 'mdadm /dev/md0 --remove /dev/sda1' );
    ok( !$ok, 'aktives Mitglied nicht entfernbar' );
    run( $s, 'mdadm --manage /dev/md0 --remove /dev/sdb1' );
    ok( !exists $s->{srv}{storage}{md}{'/dev/md0'}{members}{'/dev/sdb1'}, 'defektes entfernt' );
    ( $o, $ok ) = run( $s, 'mdadm /dev/md0 --add /dev/sdc1' );
    ok( !$ok, 'Partition gibt es noch nicht' );
    run( $s, 'sfdisk -d /dev/sda | sfdisk /dev/sdc' );
    is( $s->{srv}{storage}{disks}{'/dev/sdc1'}{size}, '39G', 'sfdisk kopiert die Tabelle' );
    run( $s, 'mdadm /dev/md0 --add /dev/sdc1' );
    is( $s->{srv}{storage}{md}{'/dev/md0'}{members}{'/dev/sdc1'}, 'rebuilding', 'baut neu auf' );
    like( run( $s, 'cat /proc/mdstat' ), qr/md0 : active raid1 sda1\[0\] sdc1\[1\]\n.*\[2\/1\] \[U_\]\n.*recovery/, '/proc/mdstat' );
    $s->{srv}{storage}{disks}{'/dev/vda'}{size} = '80G';
    run( $s, 'growpart /dev/vda 2' );
    is( $s->{srv}{storage}{disks}{'/dev/vda2'}{size}, '79G', 'growpart' );
    ( $o, $ok ) = run( $s, 'growpart /dev/vda 1' );
    ok( !$ok, 'nicht die letzte Partition' );
};

subtest 'ohne storage: mount listet, einhaengen bleibt Luecke' => sub {
    my ( $o, $ok, $gap ) = run_command( { h => { type => 'linux' } }, 'h', 'mount /dev/sdb1 /mnt' );
    ok( $gap, 'Luecke der Simulation' );
    ( $o, $ok ) = run_command( { h => { type => 'linux' } }, 'h', 'mount' );
    ok( $ok && $o =~ m{ on / type }, 'mount ohne Argumente: Einhaengepunkte wie im Grundsimulator' );
};

done_testing;
