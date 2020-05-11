package helper;

use strict;
use base 'Exporter';
our @EXPORT = qw(can_create_fake_media create_fake_media find_mount_point get_at_command remove_fake_media );

sub can_create_fake_media() {
    system("modprobe -n scsi_debug") == 0;
}

sub create_fake_media {
    my ($o_delay) = @_;

    system("modprobe scsi_debug ptype=0 removable=1 num_tgts=1 add_host=1") == 0
      or die "Failed to load scsi_debug kernel module\n";
    my @paths = glob("/sys/bus/pseudo/drivers/scsi_debug/adapter0/host*/target*/*:*/block/*");
    @paths == 1
      or die "Unexpected number of scsi_debug devices\n";
    my ($_prefix, $device) = split("block/", $paths[0]);
    if ($o_delay) {
        system("(sleep $o_delay; dd if=t/cdroms-test.iso of=/dev/$device conv=nocreat >& /dev/null)&") == 0
          or die "Failed to schedule copy of ISO to fake SCSI device\n";
    } else {
        system("dd if=t/cdroms-test.iso of=/dev/$device conv=nocreat >& /dev/null") == 0
          or die "Failed to copy ISO to fake SCSI device\n";
    }
    $device;
}

sub remove_fake_media() {
    my $tries = 0;
    while (system("modprobe -r -q scsi_debug") != 0) {
        ++$tries < 5 or die "Failed to remove scsi_debug kernel module\n";
        sleep(1);
    }
}

sub find_mount_point {
    my ($device) = @_;
    open(my $fh, '<', '/proc/mounts') or die "Couldn't read /proc/mounts\n";
    local $_;
    while (<$fh>) {
        my ($device_path, $mount_point) = split(' ', $_);
        return $mount_point if $device_path eq "/dev/$device";
    }
    return undef;
}

1;
