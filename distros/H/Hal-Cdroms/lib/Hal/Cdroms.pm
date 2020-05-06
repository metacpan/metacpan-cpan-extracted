package Hal::Cdroms;

our $VERSION = 0.05;

# Copyright (C) 2008 Mandriva
# Copyright (C) 2020 Mageia
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

Hal::Cdroms - access removable media containing CD filesystems through UDisks2 and D-Bus

=head1 SYNOPSIS

  use Hal::Cdroms;

  my $cdroms = Hal::Cdroms->new;

  foreach my $udisks_path ($cdroms->list) {
     my $m = $cdroms->get_mount_point($udisks_path);
     print "$udisks_path ", $m ? "is mounted in $m" : "is not mounted", "\n";
  }

  my $udisks_path = $cdroms->wait_for_insert;
  my $m = $cdroms->mount($udisks_path);
  print "$udisks_path is now mounted in $m\n";

=head1 DESCRIPTION

Access removable media containing CD filesystems (iso9660 and udf) through
UDisks2 and D-Bus. This includes CD-ROMS, DVD-ROMS, and USB flash drives.

=cut

# internal constant
my $dn = 'org.freedesktop.UDisks2';


=head2 Hal::Cdroms->new

Creates the object

=cut

sub new {
    my ($class) = @_;

    require Net::DBus;
    require Net::DBus::Reactor; # must be done before line below:
    my $dbus = Net::DBus->system;
    my $service = $dbus->get_service($dn);

    bless { dbus => $dbus, service => $service }, $class;
}

=head2 $cdroms->list

Return the list of C<udisks_path> of the removable media (mounted or not).

=cut

sub list {
    my ($o) = @_;

    my $manager = $o->{service}->get_object('/org/freedesktop/UDisks2/Manager');

    grep { _is_cdrom($o, $_); } @{$manager->GetBlockDevices(undef)};
}

=head2 $cdroms->get_mount_point($udisks_path)

Return the mount point associated to the C<udisks_path>, or undef it is not mounted.

=cut

sub _is_cdrom {
    my ($o, $udisks_path) = @_;
    my $device = _get_device($o, $udisks_path);
    my $drive = _get_drive($o, $device);
    return unless $drive && _get_property($drive, 'Drive', 'Removable');
    return unless member(_get_property($device, 'Block', 'IdType'), 'iso9660', 'udf');
    eval { _get_property($device, 'Filesystem', 'MountPoints') };
}

sub _get_device {
    my ($o, $udisks_path, $o_interface_name) = @_;
    $o->{service}->get_object($udisks_path, $o_interface_name);
}

sub _get_drive {
    my ($o, $device) = @_;
    my $drive_path = _get_property($device, 'Block', 'Drive');
    return if $drive_path eq '/';
    $o->{service}->get_object($drive_path);
}

sub _get_property {
    my ($device, $interface_name, $property_name) = @_;
    $device->Get("$dn.$interface_name", $property_name);
}

sub get_mount_point {
    my ($o, $udisks_path) = @_;
    my $mounts = _get_mount_points($o, $udisks_path);
    _int_array_to_string($$mounts[0]) if @{$mounts};
}

sub _get_mount_points {
    my ($o, $udisks_path) = @_;
    my $device = _get_device($o, $udisks_path);
    eval { _get_property($device, 'Filesystem', 'MountPoints') } || [];
}

sub _int_array_to_string {
    my ($array) = @_;
    join('', map { $_ ? chr($_) : '' } @{$array});
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

=head2 $cdroms->ensure_mounted($udisks_path)

Mount the C<udisks_path> if not already mounted.
Return the mount point associated to the C<udisks_path>, or undef it cannot be mounted successfully (see $cdroms->{error}).

=cut

sub ensure_mounted {
    my ($o, $udisks_path) = @_;
    
    $o->get_mount_point($udisks_path) # check if it is already mounted
      || $o->mount($udisks_path) # otherwise try to mount
      || $o->get_mount_point($udisks_path); # checking wether a volume manager did it for us
}


=head2 $cdroms->mount($udisks_path)

Mount the C<udisks_path> through UDisks2.
Return the mount point associated to the C<udisks_path>, or undef it cannot be mounted successfully (see $cdroms->{error}).

=cut

sub mount {
    my ($o, $udisks_path) = @_;

    my $device = _get_device($o, $udisks_path, "$dn.Filesystem");

    my $mountpoint;
    _try($o, sub { $mountpoint = $device->Mount(undef) }) or return;
    $mountpoint;
}

=head2 $cdroms->unmount($udisks_path)

Unmount the C<udisks_path> through UDisks2.
Return true on success (see $cdroms->{error} on failure)

=cut

sub unmount {
    my ($o, $udisks_path) = @_;

    my $device = _get_device($o, $udisks_path, "$dn.Filesystem");
    _try($o, sub { $device->Unmount(undef) });
}

=head2 $cdroms->eject($udisks_path)

Eject the C<udisks_path>. Return true on success (see $cdroms->{error} on failure).

=cut

sub eject {
    my ($o, $udisks_path) = @_;

    my $device = _get_device($o, $udisks_path);
    my $drive = _get_drive($o, $device);
    _try($o, sub { $device->as_interface("$dn.Filesystem")->Unmount(undef); $drive->Eject(undef) });
}

=head2 $cdroms->wait_for_insert([$timeout])

Wait until media containing a CD filesystem is inserted.
Return the inserted C<udisks_path> on success. Otherwise return undef.

You can give an optional timeout in milliseconds.

=cut

sub wait_for_insert {
    my ($o, $o_timeout) = @_;

    return if $o->list;

    _reactor_wait($o->{dbus}, $o_timeout, sub {
	my ($msg) = @_;
	return unless $msg->get_member eq 'InterfacesAdded';
	my $udisks_path = ($msg->get_args_list)[0];
	return unless $udisks_path =~ /block_devices/;
	return unless _is_cdrom($o, $udisks_path);
	$udisks_path;
    });
}

=head2 $cdroms->wait_for_mounted([$timeout])

Wait until media containing a CD filesystem is inserted and mounted by a volume manager (eg: gnome-volume-manager).
Return the mounted C<udisks_path> on success. Otherwise return undef.

You can give an optional timeout in milliseconds.

=cut

sub wait_for_mounted {
    my ($o, $o_timeout) = @_;

    _reactor_wait($o->{dbus}, $o_timeout, sub {
	my ($msg) = @_;
	return unless member($msg->get_member, 'InterfacesAdded', 'PropertiesChanged');
	my $udisks_path = $msg->get_member eq 'InterfacesAdded' ? ($msg->get_args_list)[0] : $msg->get_path;
	return unless $udisks_path =~ /block_devices/;
	return unless _is_cdrom($o, $udisks_path);
	return unless @{_get_mount_points($o, $udisks_path)} > 0;
	$udisks_path;
    });
}

sub _reactor_wait {
    my ($dbus, $timeout, $check_found) = @_;

    my $found_val;
    my $reactor = Net::DBus::Reactor->main;

    my $con = $dbus->get_connection;
    $con->add_match("type='signal',sender='$dn'");
    $con->add_filter(sub {
	my ($_con, $msg) = @_;

	if (my $val = $check_found->($msg)) {
	    $found_val = $val;
	    $reactor->shutdown;
	}
	1;
    });
    if ($timeout) {
	$reactor->add_timeout($timeout, Net::DBus::Callback->new(method => sub { 
	    $reactor->shutdown;
	}));
    }
    $reactor->run;

    $found_val;
}

=head2 member(SCALAR, LIST)

is the value in the list?

=cut

# From MDK::Common::DataStructure :
sub member { my $e = shift; foreach (@_) { $e eq $_ and return 1 } 0 }

=head1 AUTHOR

Pascal Rigaux <pixel@mandriva.com>
Martin Whitaker <martinw@mageia.org>

=cut 
