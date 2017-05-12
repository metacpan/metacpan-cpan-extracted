package Hal::Cdroms;

our $VERSION = 0.04;

# Copyright (C) 2008 Mandriva
#
# This program is free software; You can redistribute it and/or modify
# it under the same terms as Perl itself. Either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "COPYING" distributed along with this file provides full
# details of the terms and conditions of the two licenses.

=head1 NAME

Hal::Cdroms - access cdroms through HAL and D-Bus

=head1 SYNOPSIS

  use Hal::Cdroms;

  my $hal_cdroms = Hal::Cdroms->new;

  foreach my $hal_path ($hal_cdroms->list) {
     my $m = $hal_cdroms->get_mount_point($hal_path);
     print "$hal_path ", $m ? "is mounted in $m" : "is not mounted", "\n";
  }

  my $hal_path = $hal_cdroms->wait_for_insert;
  my $m = $hal_cdroms->mount($hal_path);
  print "$hal_path is now mounted in $m\n";

=head1 DESCRIPTION

Access cdroms through HAL and D-Bus.

=cut

# internal constant
my $hal_dn = 'org.freedesktop.UDisks';


=head2 Hal::Cdroms->new

Creates the object

=cut

sub new {
    my ($class) = @_;

    require Net::DBus;
    require Net::DBus::Reactor; # must be done before line below:
    my $dbus = Net::DBus->system;
    my $hal = $dbus->get_service($hal_dn);

    bless { dbus => $dbus, hal => $hal }, $class;
}

=head2 $hal_cdroms->list

Returns the list of C<hal_path> of the cdroms (mounted or not).

=cut

sub list {
    my ($o) = @_;

    my $manager = $o->{hal}->get_object("/org/freedesktop/UDisks",
					$hal_dn);

    
    grep { _GetProperty(_get_device($o, $_), 'DeviceIsOpticalDisc') } @{$manager->EnumerateDevices};
}

=head2 $hal_cdroms->get_mount_point($hal_path)

Return the mount point associated to the C<hal_path>, or undef it is not mounted.

=cut

sub _get_udisks_device {
    my ($o, $hal_path) = @_;
    $o->{hal}->get_object($hal_path, "$hal_dn.Device");
}

sub _get_device {
    my ($o, $hal_path) = @_;
    $o->{hal}->get_object($hal_path, 'org.freedesktop.DBus.Properties');
}

sub _get_volume {
    my ($o, $hal_path) = @_;
    $o->{hal}->get_object($hal_path, "$hal_dn.Device.Volume");
}

sub _GetProperty {
    my ($device, $pname) = @_;
    $device->Get('org.freedesktop.DBus.Properties', $pname);
}

sub get_mount_point {
    my ($o, $hal_path) = @_;

    my $device = _get_device($o, $hal_path);
    eval { _GetProperty($device, 'DeviceIsMounted')
	   && @{_GetProperty($device, 'DeviceMountPaths')}[0] };
}

sub _try {
    my ($o, $f) = @_;

    if (eval { $f->(); 1 }) {
	1;
    } else {
	$o->{error} = $@;
	undef;
    }
}

=head2 $hal_cdroms->ensure_mounted($hal_path)

Mount the C<hal_path> if not already mounted.
Return the mount point associated to the C<hal_path>, or undef it cannot be mounted successfully (see $hal_cdroms->{error}).

=cut

sub ensure_mounted {
    my ($o, $hal_path) = @_;
    
    $o->get_mount_point($hal_path) # check if it is already mounted
      || $o->mount($hal_path) # otherwise try to mount
      || $o->get_mount_point($hal_path); # checking wether a volume manager did it for us
}


=head2 $hal_cdroms->mount_through_hal($hal_path)

Mount the C<hal_path> through HAL
Return the mount point associated to the C<hal_path>, or undef it cannot be mounted successfully (see $hal_cdroms->{error}).
If the cdrom is listed in fstab, HAL will refuse to mount it.

=cut

sub mount_hal {
    my ($o, $hal_path) = @_;

    my $device = _get_device($o, $hal_path);
    my $real_device = _get_udisks_device($o, $hal_path);

    my $mountpoint;
    _try($o, sub { $mountpoint = $real_device->FilesystemMount($fstype, []) }) or return;
    $mountpoint;
}

=head2 $hal_cdroms->mount($hal_path)

Mount the C<hal_path> through HAL or fallback to plain mount(8).
Return the mount point associated to the C<hal_path>, or undef it cannot be mounted successfully (see $hal_cdroms->{error})

=cut

sub mount {
    my ($o, $hal_path) = @_;

    my $mntpoint = mount_hal($o, $hal_path);
    if (!$mntpoint) {
	# this usually means HAL refused to mount a cdrom listed in fstab
	my $dev = _GetProperty(_get_device($o, $hal_path), 'NativePath');
	# try to get real path:
	$dev =~ s!.*/!/dev/!;
	if (my $wanted = $dev && _rdev($dev)) {
	    my ($fstab_dev) = grep { $wanted == _rdev($_) } _fstab_devices();
	    system("mount", $fstab_dev) == 0
	      and $mntpoint = get_mount_point($o, $hal_path);
	}
    }
    $mntpoint;
}

sub _rdev {
    my ($dev) = @_;
    (stat($dev))[6];
}
sub _fstab_devices() {
    open(my $F, '<', '/etc/fstab') or return;
    map { /(\S+)/ } <$F>;
}

=head2 $hal_cdroms->unmount($hal_path)

Unmount the C<hal_path>. Return true on success (see $hal_cdroms->{error} on failure)
If the cdrom is listed in not mounted by HAL, HAL will refuse to unmount it.

=cut

sub unmount_hal {
    my ($o, $hal_path) = @_;

    my $volume = _get_udisks_device($o, $hal_path);
    _try($o, sub { $volume->FilesystemUnmount([]) });
}

=head2 $hal_cdroms->unmount($hal_path)

Unmount the C<hal_path> through HAL or fallback on umount(8).
Return true on success (see $hal_cdroms->{error} on failure)

=cut

sub unmount {
    my ($o, $hal_path) = @_;

    unmount_hal($o, $hal_path) and return 1;

    system('umount', get_mount_point($o, $hal_path)) == 0;
}

=head2 $hal_cdroms->eject($hal_path)

Ejects the C<hal_path>. Return true on success (see $hal_cdroms->{error} on failure)

=cut

sub eject {
    my ($o, $hal_path) = @_;

    my $volume = _get_udisks_device($o, $hal_path);
    _try($o, sub { $volume->FilesystemUnmount([]); $volume->DriveEject([]) });
}

=head2 $hal_cdroms->wait_for_insert([$timeout])

Waits until a cdrom is inserted.
Returns the inserted C<hal_path> on success. Otherwise returns undef.

You can give an optional timeout in milliseconds.

=cut

sub wait_for_insert {
    my ($o, $o_timeout) = @_;

    return if $o->list;

    _reactor_wait($o->{dbus}, $hal_dn, $o_timeout, sub {
	my ($msg) = @_;
	my $path;
	return unless member($msg->get_member, 'DeviceChanged', 'DeviceAdded') && ($path = ($msg->get_args_list)[0]);
	_GetProperty(_get_device($o, $path), 'DeviceIsOpticalDisc');
    });
}

=head2 $hal_cdroms->wait_for_mounted([$timeout])

Waits until a cdrom is inserted and mounted by a volume manager (eg: gnome-volume-manager).
Returns the mounted C<hal_path> on success. Otherwise returns undef.

You can give an optional timeout in milliseconds.

=cut

sub wait_for_mounted {
    my ($o, $o_timeout) = @_;

    _reactor_wait($o->{dbus}, $hal_dn, $o_timeout, sub {
	my ($msg) = @_;
	$msg->get_member eq 'PropertyModified' or return;

	my (undef, $modified_properties) = $msg->get_args_list;
	grep { $_->[0] eq 'volume.is_mounted' } @$modified_properties or return;

	my $hal_path = $msg->get_path;
	my $device = _get_device($o, $hal_path);

	eval { _GetProperty(_get_device($o, $hal_path), 'DeviceIsMounted') } && $hal_path;
    });
}

sub _reactor_wait {
    my ($dbus, $interface, $timeout, $check_found) = @_;

    my $val;
    my $reactor = Net::DBus::Reactor->main;

    my $con = $dbus->get_connection;
    $con->add_match("type='signal',interface='$interface'");
    $con->add_filter(sub {
	my ($_con, $msg) = @_;

	if ($val = $check_found->($msg)) {
	    _reactor_shutdown($reactor);
	}
    });
    if ($timeout) {
	$reactor->add_timeout($timeout, Net::DBus::Callback->new(method => sub { 
	    _reactor_shutdown($reactor);
	}));
    }
    $reactor->run;

    $val;
}

sub _reactor_shutdown {
    my ($reactor) = @_;

    $reactor->shutdown;

    # ugly, but needed for shutdown to work...
    $reactor->add_timeout(1, Net::DBus::Callback->new(method => sub {}));
}

sub member { my $e = shift; foreach (@_) { $e eq $_ and return 1 } 0 }

=head1 AUTHOR

Pascal Rigaux <pixel@mandriva.com>

=cut 
