package FusionInventory::Agent::Task::Inventory::Virtualization::Vserver;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun('vserver');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getMachines(
        command => 'vserver-info', logger => $logger
    )) {
        $inventory->addEntry(section => 'VIRTUALMACHINES', entry => $machine);
    }
}

sub _getMachines {
    my (%params) = @_;

    my $handle = getFileHandle(%params);
    return unless $handle;

    my $utilVserver;
    my $cfgDir;
    while (my $line = <$handle>) {
        $cfgDir = $1 if $line =~ /^\s+cfg-Directory:\s+(.*)$/;
        $utilVserver = $1 if $line =~ /^\s+util-vserver:\s+(.*)$/;
    }
    close $handle;

    return unless -d $cfgDir;

    $handle = getDirectoryHandle(directory => $cfgDir, logger => $params{logger});
    return unless $handle;

    my @machines;
    while (my $name = readdir($handle)) {
        next if $name =~ /^\./;
        next unless $name =~ /\S/;

        my $line = getFirstLine(command => "vserver $name status");
        my $status =
            $line =~ /is stopped/ ? STATUS_OFF     :
            $line =~ /is running/ ? STATUS_RUNNING :
                                    undef ;

        my $machine = {
            NAME      => $name,
            STATUS    => $status,
            SUBSYSTEM => $utilVserver,
            VMTYPE    => "vserver",
        };

        push @machines, $machine;
    }
    close $handle;

    return @machines;
}

1;
