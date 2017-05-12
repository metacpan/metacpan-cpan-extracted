use strict;
package DigitalOcean::Droplet;
use Mouse;
use DigitalOcean::Types;
use DigitalOcean::Snapshot;

#ABSTRACT: Represents a Droplet object in the DigitalOcean API

our $VERSION = '0.06';

has DigitalOcean => ( 
    is => 'rw',
    isa => 'DigitalOcean',
);

has id => ( 
    is => 'ro',
    isa => 'Num',
);

has name => (
    is => 'rw',
    isa => 'Str',
);

has memory => ( 
    is => 'rw',
    isa => 'Num',
);

has vcpus => ( 
    is => 'rw',
    isa => 'Num',
);

has disk => ( 
    is => 'rw',
    isa => 'Num',
);

has locked => ( 
    is => 'rw',
    isa => 'Bool',
);

has created_at => ( 
    is => 'rw',
    isa => 'Str',
);

has status => ( 
    is => 'rw',
    isa => 'Str',
);

has backup_ids => ( 
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has snapshot_ids => ( 
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has features => ( 
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has region => ( 
    is => 'rw',
    isa => 'Coerced::DigitalOcean::Region',
    coerce => 1,
);

has image => ( 
    is => 'rw',
    isa => 'Coerced::DigitalOcean::Image',
    coerce => 1,
);

has size => ( 
    is => 'rw',
    isa => 'Coerced::DigitalOcean::Size',
    coerce => 1,
);

has size_slug => ( 
    is => 'rw',
    isa => 'Str',
);

has networks => ( 
    is => 'rw',
    isa => 'Coerced::DigitalOcean::Networks',
    coerce => 1,
);

has kernel => ( 
    is => 'rw',
    isa => 'Undef|Coerced::DigitalOcean::Kernel',
    coerce => 1,
);

has next_backup_window => ( 
    is => 'rw',
    isa => 'Undef|Coerced::DigitalOcean::NextBackupWindow',
    coerce => 1,
);

sub _action { 
    my $self = shift;
    my (%req_body_hash) = @_;

    my %new_args;
    $new_args{path} = $self->path . 'actions';
    $new_args{req_body_hash} = \%req_body_hash;

    $self->DigitalOcean->_action(%new_args);
}


sub path { 
    'droplets/' . shift->id . '/';
}


sub kernels { 
    my ($self, $per_page) = @_;
    return $self->DigitalOcean->_get_collection($self->path . 'kernels', 'DigitalOcean::Kernel', 'kernels', {per_page => $per_page});
}


sub snapshots { 
    my ($self, $per_page) = @_;
    return $self->DigitalOcean->_get_collection($self->path . 'snapshots', 'DigitalOcean::Snapshot', 'snapshots', {per_page => $per_page});
}


sub backups { 
    my ($self, $per_page) = @_;
    return $self->DigitalOcean->_get_collection($self->path . 'backups', 'DigitalOcean::Backup', 'backups', {per_page => $per_page});
}


sub actions { 
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->DigitalOcean->_get_collection($self->path . 'actions', 'DigitalOcean::Action', 'actions', {per_page => $per_page}, $init_arr);
}


sub delete { 
    my ($self) = @_;
    return $self->DigitalOcean->_delete(path => $self->path);
}


sub neighbors { 
    my ($self) = @_;

    return $self->DigitalOcean->_get_array($self->path . 'neighbors', 'DigitalOcean::Droplet', 'droplets');

}


sub action { 
    my ($self, $id) = @_;

    return $self->DigitalOcean->_get_object($self->path . "actions/$id", 'DigitalOcean::Action', 'action');
}


sub disable_backups { shift->_action(@_, type => 'disable_backups') }


sub reboot { shift->_action(@_, type => 'reboot') }


sub power_cycle { shift->_action(@_, type => 'power_cycle') }


sub shutdown { shift->_action(@_, type => 'shutdown') }


sub power_off { shift->_action(@_, type => 'power_off') }


sub power_on { shift->_action(@_, type => 'power_on') }


sub restore { shift->_action(@_, type => 'restore') }


sub password_reset { shift->_action(@_, type => 'password_reset') }


sub resize { shift->_action(@_, type => 'resize') }

 
sub resize_reboot { 
    my $self = shift;
    my @arr;

    push(@arr, $self->power_off(wait_on_action => 1));
    push(@arr, $self->resize(@_, wait_on_action => 1));
    push(@arr, $self->power_on(wait_on_action => 1));

    return \@arr;
}


sub rebuild { shift->_action(@_, type => 'rebuild') }


sub rename { 
    my $self = shift;
    my (%params) = @_;

    my $action = $self->_action(@_, type => 'rename');
    $self->name($params{name});
    return $action;
}


sub change_kernel { shift->_action(@_, type => 'change_kernel') }


sub change_kernel_reboot { 
    my $self = shift;
    my @arr;

    push(@arr, $self->change_kernel(@_, wait_on_action => 1));
    push(@arr, $self->power_off(wait_on_action => 1));
    push(@arr, $self->power_on(wait_on_action => 1));

    return \@arr;
}


sub enable_ipv6 { shift->_action(@_, type => 'enable_ipv6') }


sub enable_private_networking { shift->_action(@_, type => 'enable_private_networking') }

 
sub enable_private_networking_reboot { 
    my $self = shift;
    my @arr;

    push(@arr, $self->power_off(wait_on_action => 1));
    push(@arr, $self->enable_private_networking(@_, wait_on_action => 1));
    push(@arr, $self->power_on(wait_on_action => 1));

    return \@arr;
}


sub snapshot { 
    my $self = shift;

    my $action = $self->_action(@_, type => 'snapshot');
    my $temp_droplet = $self->DigitalOcean->droplet($self->id);
    $self->snapshot_ids($temp_droplet->snapshot_ids);

    return $action;
}

 
sub snapshot_reboot { 
    my $self = shift;

    my @arr;

    push(@arr, $self->power_off(wait_on_action => 1));
    push(@arr, $self->snapshot(@_, wait_on_action => 1));

    return \@arr;
}


sub upgrade { shift->_action(@_, type => 'upgrade') }


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Droplet - Represents a Droplet object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 path

Returns the api path for this droplet.

=head2 kernels

This will retrieve a list of all kernels available to a Dropet
by returning a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Kernels> objects of the kernels collection. 

    my $kernels_collection = $droplet->kernels;
    my $obj;

    while($obj = $kernels_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page|DigitalOcean/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $kernels_collection = $droplet->kernels(2);
    my $obj;

    while($obj = $kernels_collection->next) { 
        print $obj->name . "\n";
    }

=head2 snapshots

This will retrieve the snapshots that have been created from a Droplet
by returning a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Snapshot> objects of the snapshots collection. 

    my $snapshots_collection = $droplet->snapshots;
    my $obj;

    while($obj = $snapshots_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page|DigitalOcean/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $snapshots_collection = $droplet->snapshots(2);
    my $obj;

    while($obj = $snapshots_collection->next) { 
        print $obj->name . "\n";
    }

=head2 backups

This will retrieve the backups that have been created from a Droplet
by returning a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Backup> objects of the backups collection. 

    my $backups_collection = $droplet->backups;
    my $obj;

    while($obj = $backups_collection->next) { 
        print $obj->name . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page|DigitalOcean/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $backups_collection = $droplet->backups(2);
    my $obj;

    while($obj = $backups_collection->next) { 
        print $obj->name . "\n";
    }

=head2 actions

This will retrieve all actions that have been executed on a Droplet
by returning a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Action> objects of the actions collection. 

    my $actions_collection = $droplet->actions;
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page|DigitalOcean/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $actions_collection = $droplet->actions(2);
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

=head2 delete

This deletes the droplet. This will return 1 on success and undef on failure.

    $droplet->delete;
    #droplet now gone

=head2 neighbors

This method returns all of the droplets that are running on the same physical server as the L<DigitalOcean::Droplet> object this method is called with.
It returns an array reference.

    my $neighbors = $droplet->neighbors;

    for my $neighbor (@$neighbors) { 
        print $neighbor->name . "\n";
    }

=head2 action

This will retrieve an action associated with the L<DigitalOcean::Droplet> object by id and return a L<DigitalOcean::Action> object.

    my $action = $droplet->action(56789);

=head2 disable_backups

This method disables backups on your droplet. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->disable_backups;

=head2 reboot

This method allows you to reboot a droplet. This is the preferred method to use if a server is not responding. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->reboot;

A reboot action is an attempt to reboot the Droplet in a graceful way, similar to using the reboot command from the console.

=head2 power_cycle

This method allows you to power cycle a droplet. This will turn off the droplet and then turn it back on. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->power_cycle;

A powercycle action is similar to pushing the reset button on a physical machine, it's similar to booting from scratch.

=head2 shutdown

This method allows you to shutdown a running droplet. The droplet will remain in your account. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->shutdown;

A shutdown action is an attempt to shutdown the Droplet in a graceful way, similar to using the shutdown command from the console. Since a shutdown command can fail, this action guarantees that the command is issued, not that it succeeds. The preferred way to turn off a Droplet is to attempt a shutdown, with a reasonable timeout, followed by a power off action to ensure the Droplet is off.

=head2 power_off

This method allows you to poweroff a running droplet. The droplet will remain in your account. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->power_off;

A power_off event is a hard shutdown and should only be used if the shutdown action is not successful. It is similar to cutting the power on a server and could lead to complications.

=head2 power_on

This method allows you to poweron a powered off droplet. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->power_on;

=head2 restore

This method allows you to restore a droplet with a previous image or snapshot. This will be a mirror copy of the image or snapshot to your droplet. Be sure you have backed up any necessary information prior to restore.
It returns a L<DigitalOcean::Action> object.

=over 4

=item

B<image> Required, string if an image slug. number if an image ID., An image slug or ID. This represents the image that the Droplet will use as a base.

=back

    my $action = $droplet->restore(image => 56789);

A Droplet restoration will rebuild an image using a backup image. The image ID that is passed in must be a backup of the current Droplet instance. The operation will leave any embedded SSH keys intact.

=head2 password_reset

This method will reset the root password for a droplet. Please be aware that this will reboot the droplet to allow resetting the password. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->password_reset;

=head2 resize

This method allows you to resize a specific droplet to a different size. It returns a L<DigitalOcean::Action> object.

=over 4

=item

B<disk> Optional, Boolean (1 or undef), Whether to increase disk size

=item

B<size> Required, String, The size slug that you want to resize to.

=back

    my $action = $droplet->resize(
        disk => 1,
        size => '1gb', 
    );

In order to resize your droplet, it must first be powered off, and you must wait for the droplet
to be powered off before you can call resize on the droplet. Making the call accurately would look something like this:

    $droplet->power_off(wait_on_action => 1);

    my $action = $droplet->resize(
        disk => 1,
        size => '1gb', 
        wait_on_action => 1,
    );

    $droplet->power_on(wait_on_action => 1);

If your droplet is already on and you want to resize it and boot your droplet
back up, you can call L</resize_reboot> to do the above code for you.

=head2 resize_reboot

In order to call L</resize_reboot>, your droplet must be powered off.
If your droplet is already running, this method makes a call to L<resize|/"resize">
for you and powers off your droplet, and then powers it on after it is done resizing
and handles L<waiting on each event|DigitalOcean/"WAITING ON EVENTS"> to finish so you do not have to write this code.
This is essentially the code that L</resize_reboot> performs for you:

    $droplet->power_off(wait_on_action => 1);

    $droplet->resize(
        disk => $disk,
        size => $size,
        wait_on_action => 1,
    );

    $droplet->power_on(wait_on_event => 1);

So a call to L</resize_reboot> would look like:

    my $actions = $droplet->resize_reboot(
        disk => 1,
        size => '1gb', 
    );

    for my $action (@$actions) { 
        print $action->id . ' ' . $action->status . "\n";
    }

It returns an array reference of all three actions returned by L</power_off>, L</resize>, and L</power_on>.

=head2 rebuild

This method allows you to rebuild a Droplet. It returns a L<DigitalOcean::Action> object.
A rebuild action functions just like a new create. This is useful if you want to start again but retain the same IP address for your droplet.

=over 4

=item

B<image> Required, string if an image slug. number if an image ID., An image slug or ID. This represents the image that the Droplet will use as a base.

=back

    my $action = $droplet->rebuild(
        image => 'ubuntu-14-04-x64',
    );

=head2 rename

This method renames the droplet to the specified name. The new name is reflected in the L<DigitalOcean::Droplet> object.
It returns a L<DigitalOcean::Action> object.

=over 4

=item

B<name> Required, String, The new name for the Droplet.

=back

    $droplet->rename(name => $new_name);

=head2 change_kernel

This method allows you to change the kernel of a Droplet. It returns a L<DigitalOcean::Action> object.

=over 4

=item

B<kernel> Required, Number, A unique number used to identify and reference a specific kernel.

=back

    my $action = $droplet->change_kernel(kernel => 991);

=head2 change_kernel_reboot

In order for a new kernel to be active, the machine must be powered off and then powered on. This function changes the kernel
for you and powers off your droplet, and then powers it on. It also handles
L<waiting on each event|DigitalOcean/"WAITING ON EVENTS"> so you do not have to write this code.
This is essentially the code that L</change_kernel_reboot> performs for you:

    $droplet->change_kernel(kernel => $kernel);
    $droplet->power_off(wait_on_action => 1);
    $droplet->power_on(wait_on_event => 1);

So a call to L</change_kernel_reboot> would look like:

    my $actions = $droplet->change_kernel_reboot(kernel => 991);

    for my $action (@$actions) { 
        print $action->id . ' ' . $action->status . "\n";
    }

It returns an array reference of all three actions returned by L</change_kernel>, L</power_off>, and L</power_on>.

=head2 enable_ipv6

This method allows you to enable IPv6 networking on an existing Droplet (within a region that has IPv6 available). It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->enable_ipv6;

=head2 enable_private_networking

This method allows you to enable private networking on an existing Droplet (within a region that has private networking available). It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->enable_private_networking;

In order to enable private networking for your droplet, it must first be powered off, and you must wait for the droplet
to be powered off before you can call snapshot on the droplet. Making the call accurately would look something like this:

    $droplet->power_off(wait_on_event => 1);
    $droplet->enable_private_networking(wait_on_event => 1);
    $droplet->power_on(wait_on_event => 1);

If your droplet is already on and you want to enable private networking and boot your droplet
back up, you can call L</enable_private_networking_reboot> to do the above code for you.

=head2 enable_private_networking_reboot

In order to call L</enable_private_networking>, your droplet must be powered off.
If your droplet is already running, this method makes a call to L</enable_private_networking>
for you and powers off your droplet, and then powers it on after it is done 
and handles L<waiting on each event|DigitalOcean/"WAITING ON EVENTS"> to finish so you do not have to write this code.
This is essentially the code that L</enable_private_networking> performs for you:

    $droplet->power_off(wait_on_action => 1);

    $droplet->enable_private_networking(wait_on_action => 1);

    $droplet->power_on(wait_on_event => 1);

So a call to L</enable_private_networking_reboot> would look like:

    my $actions = $droplet->enable_private_networking_reboot;

    for my $action (@$actions) { 
        print $action->id . ' ' . $action->status . "\n";
    }

It returns an array reference of all three actions returned by L</power_off>, L</enable_private_networking>, and L</power_on>.

=head2 snapshot

This method allows you to take a snapshot of the droplet once it has been powered off, which can later be restored or used to create a new droplet from the same image.

=over 4

=item

B<name> Optional, String, this is the name of the new snapshot you want to create. If not set, the snapshot name will default to date/time

=back

In order to take a snapshot of your droplet, it must first be powered off, and you must wait for the droplet
to be powered off before you can call snapshot on the droplet. Making the call accurately would look something like this:

    $droplet->power_off(wait_on_event => 1);
    $droplet->snapshot;

If your droplet is already on and you essentially want to take a snapshot and boot your droplet
back up, you can call L/snapshot_reboot> to do the above code for you. (The L</snapshot> method turns the droplet back on for you).

=head2 upgrade

This method allows you to upgrade a droplet. It returns a L<DigitalOcean::Action> object.

    my $action = $droplet->upgrade;

=head2 id

=head2 Actions

=head2 snapshot_reboot

If your droplet is already running, this method makes a call to L</snapshot>
for you and powers off your droplet, and then powers it on after it is done taking a snapshot
and handles L<waiting on each event|DigitalOcean/"WAITING ON EVENTS"> to finish so you do not have to write this code.
This is essentially the code that L</snapshot_reboot> performs for you:

    $droplet->power_off(wait_on_event => 1);
    $droplet->snapshot(wait_on_event => 1); #snapshot powers your droplet back on for you

So a call to L</snapshot_reboot> would look like:

    my $actions = $droplet->snapshot_reboot;

    for my $action (@$actions) { 
        print $action->id . ' ' . $action->status . "\n";
    }

It returns an array reference of both actions returned by L</power_off>, L</snapshot_reboot>.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
