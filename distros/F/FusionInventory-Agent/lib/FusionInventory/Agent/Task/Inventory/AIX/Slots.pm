package FusionInventory::Agent::Task::Inventory::AIX::Slots;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::AIX;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{slot};
    return canRun('lsdev');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # index VPD infos by AX field
    my %infos =
        map  { $_->{AX} => $_ }
        grep { $_->{AX} }
        getLsvpdInfos(logger => $logger);

    foreach my $slot (_getSlots(
        command => 'lsdev -Cc bus -F "name:description"',
        logger  => $logger
    )) {

        $slot->{DESCRIPTION} = $infos{$slot->{NAME}}->{YL}
            if $infos{$slot->{NAME}};

        $inventory->addEntry(
            section => 'SLOTS',
            entry   => $slot
        );
    }
}

sub _getSlots {
    my $handle = getFileHandle(@_);

    return unless $handle;

    my @slots;
    while (my $line = <$handle>) {
        next unless $line =~ /^(.+):(.+)/;

        push @slots, {
            NAME        => $1,
            DESIGNATION => $2,
        };
    }
    close $handle;

    return @slots;
}

1;
