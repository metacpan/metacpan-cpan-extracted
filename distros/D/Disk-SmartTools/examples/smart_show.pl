#!/usr/bin/env perl

################################################################################
##                                                                            ##
##  smart_show.pl - show smart information for disks                          ##
##                                                                            ##
##  Author:    Matt Martini                                                   ##
##                                                                            ##
##  Created:   20201006   v.1.0                                               ##
##                                                                            ##
################################################################################

########################################
#      Requirements and Packages       #
########################################

use Dev::Util::Syntax;
use Dev::Util::OS    qw(:all);
use Dev::Util::Query qw(banner display_menu);
use Dev::Util::File  qw(file_is_block);
use Disk::SmartTools qw(:all);

use Term::ReadKey;
use Term::ANSIColor;
use IPC::Cmd qw[can_run run];

use Data::Dumper::Simple;
use Data::Printer;

Readonly my $PROGRAM => 'smart_show.pl';
Readonly my $VERSION => version->declare("v3.3.26");

########################################
#      Define Global Variables         #
########################################
local $OUTPUT_AUTOFLUSH = 1;
$Data::Dumper::Indent = 3;    # pretty print with array indices

# Default config params
my %config = (
               debug   => 0,    # debugging
               silent  => 0,    # Do not print report on stdout
               verbose => 0,    # Generate debugging info on stderr
               dry_run => 0,    # don't actually do the test
             );

my %disk_info = (
                  has_disks    => 0,
                  disks        => [],
                  disk_prefix  => '',
                  has_raid     => 0,
                  raid_flag    => '',
                  rdisk_prefix => '',
                  rdisks       => [],
                );

my @attributes = (
                   'All SMART Info',        'Info',
                   'Overall-Health',        'SelfTest History',
                   'Error Log',             'Temperature Graph',
                   'Power_On_Hours',        'Power_Cycle_Count',
                   'Temperature_Celsius',   'Reallocated_Sector_Ct',
                   'Offline_Uncorrectable', 'Raw_Read_Error_Rate',
                   'Seek_Error_Rate',       'Reported_Uncorrect',
                   'Command_Timeout',       'Current_Pending_Sector'
                 );

Readonly my $SLEEP_TIME => 0;

########################################
#            Main Program              #
########################################

if ( $REAL_USER_ID != 0 ) { die "You must be root to run this program.\n" }

my $cmd_path = get_smart_cmd();
get_os_options( \%disk_info );

print colored ( "Display SMART information\n" . "-" x 26 . "\n", 'white' );

my $choice = display_menu( "Choose attribute to display: ", \@attributes );
my $cmd_type
    = $choice == 1 ? ' --info '
    : $choice == 2 ? ' --health '
    : $choice == 3 ? ' --log=selftest '
    : $choice == 4 ? ' --log=error '
    : $choice == 5 ? ' --log=scttemp '
    :                ' --all ';
Readonly my $MAX_ALL_CHOICE => 5;

my @disk_list = ();
if ( $disk_info{ has_disks } == 1 ) {
    DISK:
    foreach my $disk ( @{ $disk_info{ disks } } ) {
        my $disk_path = $disk_info{ disk_prefix } . $disk;
        next DISK unless ( file_is_block($disk_path) );
        push @disk_list, $disk_path;
    }
}
if ( $disk_info{ has_raid } == 1 ) {
    RDISK:
    foreach my $rdisk ( @{ $disk_info{ rdisks } } ) {
        my $rdisk_prefix = $disk_info{ rdisk_prefix };
        ## next RDISK unless ( file_is_block($rdisk_prefix) );
        push @disk_list, $rdisk_prefix . $disk_info{ raid_flag } . $rdisk;
    }
}

CURRENT_DISK:
foreach my $current_disk (@disk_list) {
    print colored ( $current_disk . "\n", 'bold magenta' );
    next CURRENT_DISK if $config{ dry_run };

    if ( smart_on_for( { cmd_path => $cmd_path, disk => $current_disk } ) ) {
        warn "SMART enabled for $current_disk\n" if $config{ debug };
    }
    else {
        warn "SMART NOT enabled for $current_disk\n" if $config{ debug };
        next CURRENT_DISK;
    }

    my $buf_ref
        = smart_cmd_for(
                         { cmd_path => $cmd_path,
                           cmd_type => $cmd_type,
                           disk     => $current_disk
                         }
                       );

    if ($buf_ref) {
        foreach my $line ( @{ $buf_ref } ) {
            if (     ( $choice <= $MAX_ALL_CHOICE )
                  || ( $line =~ m{$attributes[$choice]}i ) )
            {
                say $line;
            }
        }
    }
    else {
        warn "Could not get info for $current_disk\n";
        next CURRENT_DISK;
    }

    sleep $SLEEP_TIME;
}

exit(0);

########################################
#           Subroutines                #
########################################

sub get_os_options {
    my ($disk_info_ref) = @_;
    my ( @disks, @smart_disks, $disk_prefix );

    my $OS   = get_os();
    my $host = get_hostname();
    $host =~ s{\A (.*?) [.] .* \z}{$1}xms;    # remove domain part of hostname

    $disk_prefix = get_disk_prefix();

    if (is_mac) {
        @disks = get_physical_disks();
    }
    else {
        @disks = os_disks();
    }

    @smart_disks = get_smart_disks(@disks);
    if ( scalar @smart_disks > 0 ) {
        $disk_info_ref->{ has_disks } = 1;
    }

    foreach my $smart_disk (@smart_disks) {
        $smart_disk =~ s{$disk_prefix(.+)}{$1};
    }

    $disk_info_ref->{ disks }       = \@smart_disks;
    $disk_info_ref->{ disk_prefix } = $disk_prefix;
    $disk_info_ref->{ raid_flag }   = get_raid_flag();

    my $host_local_config_ref = load_local_config($host);

    if ( defined $host_local_config_ref ) {
        foreach my $key ( keys %{ $host_local_config_ref } ) {
            $disk_info_ref->{ $key } = $host_local_config_ref->{ $key };
        }
    }

    p $disk_info_ref if $config{ debug };

    return;
}

=pod

=encoding utf-8

=head1 NAME

smart_show.pl - Display SMART information on disks.

=head1 SYNOPSIS

Display SMART information on disks.
Distributed in Disk::SmartTools.

Asks for the type of SMART information to display then
reports for each physical disk in the system.

=over 4

=item  Display SMART information

=item  -------------------------

=item Choose attribute to display:

=item  a. All SMART Info

=item  b. Info

=item  c. Overall-Health

=item  d. SelfTest History

=item  e. Error Log

=item  f. Temperature Graph

=item  g. Power_On_Hours

=item  h. Power_Cycle_Count

=item  i. Temperature_Celsius

=item  j. Reallocated_Sector_Ct

=item  k. Offline_Uncorrectable

=item  l. Raw_Read_Error_Rate

=item  m. Seek_Error_Rate

=item  n. Reported_Uncorrect

=item  o. Command_Timeout

=item  p. Current_Pending_Sector


=back

B<Must be run as root.>

=head1 REQUIREMENTS

This program depends on Disk::SmartTools.

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-disk-smarttools at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2020-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

