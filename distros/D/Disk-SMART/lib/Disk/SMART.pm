package Disk::SMART;

use warnings;
use strict;
use 5.010;
use Carp;
use Math::Round;
use File::Which;

{
    $Disk::SMART::VERSION = '0.18'
}

our $smartctl = which('smartctl');

=head1 NAME

Disk::SMART - Provides an interface to smartctl to return disk stats and to run tests.

=head1 SYNOPSIS

Disk::SMART is an object oriented module that provides an interface to get SMART disk info from a device as well as initiate testing. An exmple script using this module can be found at https://github.com/paultrost/linux-geek/blob/master/sysinfo.pl

    use Disk::SMART;

    my $smart = Disk::SMART->new('/dev/sda', '/dev/sdb');

    my $disk_health = $smart->get_disk_health('/dev/sda');

=cut


=head1 CONSTRUCTOR

=head2 B<new(DEVICE)>

Instantiates the Disk::SMART object

C<DEVICE> - Device identifier of a single SSD / Hard Drive, or a list. If no devices are supplied then it runs get_disk_list() which will return an array of detected sdX and hdX devices.

    my $smart = Disk::SMART->new();
    my $smart = Disk::SMART->new( '/dev/sda', '/dev/sdb' );
    my @disks = $smart->get_disk_list();

Returns C<Disk::SMART> object if smartctl is available and can poll the given device(s).

=cut

sub new {
    my ( $class, @devices ) = @_;
    my $self = bless {}, $class;
    die "$class must be called as root, please run $0 as root or with sudo\n" if $>;
    @devices = @devices ? @devices : $self->get_disk_list();
    confess "Valid device identifier not supplied to constructor, or no disks detected.\n"
        if !@devices;

    $self->update_data(@devices);

    return $self;
}


=head1 USER METHODS

=head2 B<get_disk_attributes(DEVICE)>

Returns hash of the SMART disk attributes and values

C<DEVICE> - Device identifier of a single SSD / Hard Drive

    my %disk_attributes = $smart->get_disk_attributes('/dev/sda');

=cut

sub get_disk_attributes {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    return %{ $self->{'devices'}->{$device}->{'attributes'} };
}


=head2 B<get_disk_errors(DEVICE)>

Returns scalar of any listed errors

C<DEVICE> - Device identifier of a single SSD/ Hard Drive

    my $disk_errors = $smart->get_disk_errors('/dev/sda');

=cut

sub get_disk_errors {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    return $self->{'devices'}->{$device}->{'errors'};
}


=head2 B<get_disk_health(DEVICE)>

Returns the health of the disk. Output is "PASSED", "FAILED", or "N/A". If the device has positive values for the attributes listed below then the status will output that information.

Eg. "FAILED - Reported_Uncorrectable_Errors = 1"

The attributes are:

5 - Reallocated_Sector_Count

187 - Reported_Uncorrectable_Errors

188 - Command_Timeout

197 - Current_Pending_Sector_Count

198 - Offline_Uncorrectable

If Reported_Uncorrectable_Errors is greater than 0 then the drive should be replaced immediately. This list is taken from a study shown at https://www.backblaze.com/blog/hard-drive-smart-stats/


C<DEVICE> - Device identifier of a single SSD / Hard Drive

    my $disk_health = $smart->get_disk_health('/dev/sda');

=cut

sub get_disk_health {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $status = $self->{'devices'}->{$device}->{'health'};

    my %failure_attribute_hash;
    while ( my ($key, $value) = each %{ $self->{'devices'}->{$device}->{'attributes'} } ) {
        if ( $key =~ /\A5\Z|\A187\Z|\A188\Z|\A197\Z|\A198\Z/ ) {
            $failure_attribute_hash{$key} = $value;
            $status .= ": $key - $value->[0] = $value->[1]" if ( $value->[1] > 0 );
        }
    }

    return $status;
}


=head2 B<get_disk_list>

Returns list of detected hda and sda devices. This method can be called manually if unsure what devices are present. 

    $smart->get_disk_list;

=cut
    
sub get_disk_list {
    open my $fh, '-|', 'parted -l' or confess "Can't run parted binary\n";
    local $/ = undef;
    my @disks = map { /Disk (\/.*\/[h|s]d[a-z]):/ } split /\n/, <$fh>;
    close $fh or confess "Can't close file handle reading parted output\n";
    return @disks;
}

=head2 B<get_disk_model(DEVICE)>

Returns the model of the device. eg. "ST3250410AS".

C<DEVICE> - Device identifier of a single SSD / Hard Drive

    my $disk_model = $smart->get_disk_model('/dev/sda');

=cut

sub get_disk_model {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    return $self->{'devices'}->{$device}->{'model'};
}

=head2 B<get_disk_temp(DEVICE)>

Returns an array with the temperature of the device in Celsius and Farenheit, or N/A.

C<DEVICE> - Device identifier of a single SSD / Hard Drive

    my ($temp_c, $temp_f) = $smart->get_disk_temp('/dev/sda');

=cut

sub get_disk_temp {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    return @{ $self->{'devices'}->{$device}->{'temp'} };
}

=head2 B<run_short_test(DEVICE)>

Runs the SMART short self test and returns the result.

C<DEVICE> - Device identifier of SSD/ Hard Drive

    $smart->run_short_test('/dev/sda');

=cut

sub run_short_test {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $test_out = get_smart_output( $device, '-t short' );
    my ($short_test_time) = $test_out =~ /Please wait (.*) minutes/s;
    sleep( $short_test_time * 60 );

    my $smart_output = _get_smart_output( $device, '-a' );
    ($smart_output) = $smart_output =~ /(SMART Self-test log.*)\nSMART Selective self-test/s;
    my @device_tests      = split /\n/, $smart_output;
    my $short_test_number = $device_tests[2];
    my $short_test_status = substr $short_test_number, 25, +30;
    $short_test_status = _trim($short_test_status);

    return $short_test_status;
}

=head2 B<update_data(DEVICE)>

Updates the SMART output and attributes for each device. Returns undef.

C<DEVICE> - Device identifier of a single SSD / Hard Drive or a list of devices. If none are specified then get_disk_list() is called to detect devices.

    $smart->update_data('/dev/sda');

=cut

sub update_data {
    my ( $self, @p_devices ) = @_;
    my @devices = @p_devices ? @p_devices : $self->get_disk_list();

    foreach my $device (@devices) {
        my $out;
        $out = _get_smart_output( $device, '-a' );
        confess "Smartctl couldn't poll device $device\nSmartctl Output:\n$out\n"
          if ( !$out || $out !~ /START OF INFORMATION SECTION/ );

        chomp($out);
        $self->{'devices'}->{$device}->{'SMART_OUTPUT'} = $out;

        $self->_process_disk_attributes($device);
        $self->_process_disk_errors($device);
        $self->_process_disk_health($device);
        $self->_process_disk_model($device);
        $self->_process_disk_temp($device);
    }

    return;
}

sub _get_smart_output {
    my ( $device, $options ) = @_;
    $options = $options // '';

    die "smartctl binary was not found on your system, are you running as root?\n"
        if ( !defined $smartctl || !-f $smartctl );

    open my $fh, '-|', "$smartctl $device $options" or confess "Can't run smartctl binary\n";
    local $/ = undef;
    my $smart_output = <$fh>;

    if ( $smart_output =~ /Unknown USB bridge/ ) {
        open $fh, '-|', "$smartctl $device $options -d sat" or confess "Can't run smartctl binary\n";
        $smart_output = <$fh>;
    }
    return $smart_output;
}

sub _process_disk_attributes {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($smart_attributes) = $smart_output =~ /(ID# ATTRIBUTE_NAME.*)\nSMART Error/s;
    my @attributes = split /\n/, $smart_attributes;
    shift @attributes; #remove table header

    foreach my $attribute (@attributes) {
        my $id    = substr $attribute, 0,  +3;
        my $name  = substr $attribute, 4,  +24;
        my $value = substr $attribute, 83, +50;
        $id    = _trim($id);
        $name  = _trim($name);
        $value = _trim($value);
        $self->{'devices'}->{$device}->{'attributes'}->{$id} = [ $name, $value ];
    }

    return;
}

sub _process_disk_errors {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($errors)     = $smart_output =~ /SMART Error Log Version: [1-9](.*)SMART Self-test log/s;
    $errors = _trim($errors);
    $errors = 'N/A' if !$errors;

    return $self->{'devices'}->{$device}->{'errors'} = $errors;
}

sub _process_disk_health {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($health)     = $smart_output =~ /SMART overall-health self-assessment test result:(.*)\n/;
    $health = _trim($health);
    $health = 'N/A' if !$health || $health !~ /PASSED|FAILED/x;

    return $self->{'devices'}->{$device}->{'health'} = $health;
}

sub _process_disk_model {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    
    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    my ($model)      = $smart_output =~ /Device\ Model:(.*)\n/;
    $model = _trim($model);
    $model = 'N/A' if !$model;

    return $self->{'devices'}->{$device}->{'model'} = $model;
}

sub _process_disk_temp {
    my ( $self, $device ) = @_;
    $self->_validate_param($device);
    my ( $temp_c, $temp_f );

    my $smart_output = $self->{'devices'}->{$device}->{'SMART_OUTPUT'};
    ($temp_c) = $smart_output =~ /(Temperature_Celsius.*\n|Airflow_Temperature_Cel.*\n)/;

    if ($temp_c) {
        $temp_c = substr $temp_c, 83, +3;
        $temp_c = _trim($temp_c);
        $temp_f = round( ( $temp_c * 9 ) / 5 + 32 );
        $temp_c = int $temp_c;
        $temp_f = int $temp_f;
    }
    else {
        $temp_c = 'N/A';
        $temp_f = 'N/A';
    }

    return $self->{'devices'}->{$device}->{'temp'} = [ ( $temp_c, $temp_f ) ];
}

sub _trim {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;    #trim beginning and ending whitepace
    return $string;
}

sub _validate_param {
    my ( $self, $device ) = @_;
    croak "$device not found in object. Verify you specified the right device identifier.\n"
        if ( !exists $self->{'devices'}->{$device} );

    return;
}

1;


__END__

=head1 COMPATIBILITY

  This module should run on any UNIX like OS with Perl 5.10+ and the smartctl progam installed from the smartmontools package.

=head1 AUTHOR

 Paul Trost <ptrost@cpan.org>

=head1 LICENSE AND COPYRIGHT

 Copyright 2015 by Paul Trost
 This script is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License v2, or at your option any later version.
 <http://gnu.org/licenses/gpl.html>

=cut
