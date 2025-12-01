#!/usr/bin/env perl

################################################################################
##                                                                            ##
##  smart_runt_tests.pl - run smart tests for disks                           ##
##                                                                            ##
##  Author:    Matt Martini                                                   ##
##                                                                            ##
################################################################################

########################################
#      Requirements and Packages       #
########################################

use lib '../lib';
use Dev::Util::Syntax;
use Dev::Util::OS    qw(get_hostname is_mac is_linux);
use Dev::Util::Query qw(banner);
use Disk::SmartTools qw(:all);

use Getopt::Long;
use IPC::Cmd qw[can_run run];
use Term::ANSIColor;

use Data::Printer;

Readonly my $PROGRAM => 'smart_run_tests.pl';
Readonly my $VERSION => version->declare("v3.3.12");

########################################
#      Define Global Variables         #
########################################

my $date = sprintf(
                    "%04d%02d%02d",
                    sub { ( $_[5] + 1900, $_[4] + 1, $_[3] ) }
                    ->( localtime() )
                  );

my $disk_day = sprintf(
                        "%d",
                        sub { ( $_[3] ) }
                        ->( localtime() )
                      ) - 10;

# Default config params
my %config = (
               test_type => 'short',    # Test type. Default is short
               debug     => 0,          # debugging
               silent    => 0,          # Do not print report on stdout
               verbose   => 0,          # Generate debugging info on stderr
               dry_run   => 0,          # don't actually do the test
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

########################################
#            Main Program              #
########################################

# if ( $REAL_USER_ID != 0 ) { die "You must be root to run this program.\n" }

process_args();
Readonly my $SLEEP_TIME => $config{ test_type } eq 'long' ? 900 : 180;

my $cmd_path = get_smart_cmd();
get_os_options( \%disk_info );

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

if (     ( $config{ test_type } eq 'long' )
      && ( ( $disk_day > $#disk_list ) || ( $disk_day < 0 ) ) )
{
    exit(0);
}
else {
    banner sprintf "%s - %s - %s - %s", 'S.M.A.R.T. test',
        $config{ test_type },
        get_hostname(), $date;
}

DISK_TO_TEST:
foreach my $disk_to_test (@disk_list) {

    # for long test skip all disks but the one that matches today's day
    next DISK_TO_TEST
        if (    ( $config{ test_type } eq 'long' )
             && ( defined $disk_list[$disk_day] )
             && ( $disk_list[$disk_day] ne $disk_to_test ) );

    if ( $config{ debug } ) {
        print colored ( $disk_to_test . "\n", 'bold magenta' );
    }
    else {
        say $disk_to_test;
    }
    next DISK_TO_TEST if $config{ dry_run };

    if ( smart_on_for( { cmd_path => $cmd_path, disk => $disk_to_test } ) ) {
        warn "SMART enabled for $disk_to_test\n" if $config{ debug };
    }
    else {
        warn "SMART NOT enabled for $disk_to_test\n" if $config{ debug };
        next DISK_TO_TEST;
    }

    if (
          smart_test_for(
                          { cmd_path  => $cmd_path,
                            test_type => $config{ test_type },
                            disk      => $disk_to_test
                          }
                        )
       )
    {
        warn "SMART $config{test_type} test started for $disk_to_test\n"
            if $config{ debug };
    }
    else {
        warn "SMART $config{test_type} test NOT started for $disk_to_test\n"
            if $config{ debug };
        next DISK_TO_TEST;
    }

    sleep $SLEEP_TIME;

    my $selftest_hist_ref
        = selftest_history_for(
                                { cmd_path => $cmd_path, disk => $disk_to_test } );
    if ($selftest_hist_ref) {
        say map { "$_\n" } grep { m/# [12]/i } @{ $selftest_hist_ref };
        print "\n";
    }
    else {
        warn "Could not retreive test result of $disk_to_test\n";
    }
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

sub process_args {

    GetOptions( \%config, "test_type|type|test=s", "dry_run",
                "debug", "silent", "verbose", "help|?",
                "version" => sub { say "version: $VERSION"; exit(0); }, );

    # Sanity checks
    usage() if ( $Getopt::Long::error > 0 || $config{ help } );

    usage("Test type must be 'short' or 'long'.\n")
        if ( $config{ test_type } !~ m{short|long} );

    return;
}    # process_args

sub usage {
    my $msg = shift || '';
    print colored ( $msg, 'red' );

    print <<"END_USAGE";

 Usage: $0 args
 Arguments:
   --test_type  : Length of SMART test, short (default) or long
   --dry_run    : Don't actually perform SMART test
   --debug      : Turn debugging on
   --verbose    : Generate debugging info on stderr
   --silent     : Do not print report on stdout
   --help       : This helpful information.

END_USAGE
    exit(1);
}

=pod

=encoding utf-8

=head1 NAME


smart_run_tests.pl - Runs a SMART test on all disks.

=head1 SYNOPSIS

Runs a SMART test on each physical disk in the system.
Distributed in Disk::SmartTools.

Can run either short or long SMART test on each disk.

=over 4

=item smart_run_tests.pl <args>

=item  --test_type  : Length of SMART test, short (default) or long

=item  --dry_run    : Don't actually perform SMART test

=item  --debug      : Turn debugging on

=item  --verbose    : Generate debugging info on stderr

=item  --silent     : Do not print report on stdout

=item  --help       : This helpful information.

=back

B<Must be run as root.>

=head2 Crontabs

Usually run as a crontab

=over 4

=item 30 5 * * *       : S.M.A.R.T. disk checks - short ; /var/root/bin/smart_run_tests.pl

Z<>

=item 4  6 * * *       : S.M.A.R.T. disk checks - long  ; /var/root/bin/smart_run_tests.pl --test_type=long

=back

=head1 REQUIREMENTS

This program depends on Disk::SmartTools.

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-merm-smarttools at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__
