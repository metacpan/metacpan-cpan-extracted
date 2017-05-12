use Test::Fatal;
use Test::More tests => 17;
use Test::MockModule;
use Disk::SMART;

my $smart_output = "smartctl 6.2 2013-07-26 r3841 [x86_64-linux-3.10.0-229.4.2.el7.x86_64] (local build)
Copyright (C) 2002-13, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Family:     Seagate Barracuda 7200.10
Device Model:     ST3250410AS
Serial Number:    6RYBDDDQ
Firmware Version: 3.AAF
User Capacity:    250,059,350,016 bytes [250 GB]
Sector Size:      512 bytes logical/physical
Device is:        In smartctl database [for details use: -P show]
ATA Version is:   ATA/ATAPI-7 (minor revision not indicated)
Local Time is:    Thu May 28 10:38:55 2015 CDT
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x82) Offline data collection activity
                    was completed without error.
                    Auto Offline Data Collection: Enabled.
Self-test execution status:      (   0) The previous self-test routine completed
                    without error or no self-test has ever
                    been run.
Total time to complete Offline
data collection:        (  430) seconds.
Offline data collection
capabilities:            (0x5b) SMART execute Offline immediate.
                    Auto Offline data collection on/off support.
                    Suspend Offline collection upon new
                    command.
                    Offline surface scan supported.
                    Self-test supported.
                    No Conveyance Self-test supported.
                    Selective Self-test supported.
SMART capabilities:            (0x0003) Saves SMART data before entering
                    power-saving mode.
                    Supports SMART auto save timer.
Error logging capability:        (0x01) Error logging supported.
                    General Purpose Logging supported.
Short self-test routine
recommended polling time:    (   1) minutes.
Extended self-test routine
recommended polling time:    (  64) minutes.
SCT capabilities:          (0x0001) SCT Status supported.

SMART Attributes Data Structure revision number: 10
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate     0x000f   100   253   006    Pre-fail  Always       -       0
  3 Spin_Up_Time            0x0003   097   097   000    Pre-fail  Always       -       0
  4 Start_Stop_Count        0x0032   100   100   020    Old_age   Always       -       33
  5 Reallocated_Sector_Ct   0x0033   100   100   036    Pre-fail  Always       -       0
  7 Seek_Error_Rate         0x000f   075   060   030    Pre-fail  Always       -       40666623
  9 Power_On_Hours          0x0032   093   093   000    Old_age   Always       -       6356
 10 Spin_Retry_Count        0x0013   100   100   097    Pre-fail  Always       -       0
 12 Power_Cycle_Count       0x0032   100   100   020    Old_age   Always       -       33
187 Reported_Uncorrect      0x0032   100   100   000    Old_age   Always       -       0
189 High_Fly_Writes         0x003a   100   100   000    Old_age   Always       -       0
190 Airflow_Temperature_Cel 0x0022   064   050   045    Old_age   Always       -       36 (Min/Max 13/50)
194 Temperature_Celsius     0x0022   036   050   000    Old_age   Always       -       36 (0 13 0 0 0)
195 Hardware_ECC_Recovered  0x001a   069   060   000    Old_age   Always       -       121831984
197 Current_Pending_Sector  0x0012   100   100   000    Old_age   Always       -       0
198 Offline_Uncorrectable   0x0010   100   100   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count    0x003e   200   200   000    Old_age   Always       -       0
200 Multi_Zone_Error_Rate   0x0000   100   253   000    Old_age   Offline      -       0
202 Data_Address_Mark_Errs  0x0032   100   253   000    Old_age   Always       -       0

SMART Error Log Version: 1
No Errors Logged

SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%      1100         -
# 2  Short offline       Completed without error       00%      1100         -
# 3  Extended offline    Aborted by host               90%      1100         -
# 4  Short offline       Completed without error       00%      1100         -
# 5  Short offline       Completed without error       00%      1100         -
# 6  Short offline       Completed without error       00%      1099         -

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.";

my $mock  = Test::MockModule->new('Disk::SMART');
$mock->mock(
    'new' => sub {
        my ( $class, @devices ) = @_;
        my $self = bless {}, $class;
        $self->update_data(@devices);
        return $self;
    },
    '_get_smart_output' => sub { return $smart_output; },
    'run_short_test'    => 'Completed without error'
);
my $disk = '/dev/sda';    # this is being mocked
my $smart = Disk::SMART->new($disk);
            
# Verify functions return correctly with SMART data present
my %disk_attribs = $smart->get_disk_attributes($disk);
is( keys %disk_attribs, 18, 'get_disk_attributes() returns hash of device attributes' );
is( $smart->get_disk_errors($disk), 'No Errors Logged', 'get_disk_errors() returns no errors logged' );
is( $smart->get_disk_health($disk), 'PASSED', 'get_disk_health() returns health status' );
is( $smart->get_disk_model($disk), 'ST3250410AS', 'get_disk_model() returns device model' );
is( scalar($smart->get_disk_temp($disk)), 2, 'get_disk_temp() returns device temperature' );
is( $smart->run_short_test($disk), 'Completed without error', 'run_short_test() returns test status' );

# Change some SMART data around and see if the functions return correctly
$smart_output =~ s/ST3250410AS//;
$smart_output =~ s/187 Reported_Uncorrect      0x0032   100   100   000    Old_age   Always       -       0/187 Reported_Uncorrect      0x0032   100   100   000    Old_age   Always       -       1/;
$smart_output =~ s/190 Airflow_Temperature_Cel.*\n//;
$smart_output =~ s/194 Temperature_Celsius.*\n//;
is( $smart->update_data($disk), undef, 'update_data() updated object with changed device data' );
is( $smart->get_disk_health($disk), 'PASSED: 187 - Reported_Uncorrect = 1', 'get_disk_health() returns failed attribute status when SMART attribute 187 > 0' );
is( $smart->get_disk_model($disk), 'N/A', 'get_disk_model() returns N/A when no model was found' );
my @disk_temps = $smart->get_disk_temp($disk);
is( $disk_temps[0], 'N/A', "get_disk_temp() returns 'N/A' when smartctl doesn't report temperaure" );

#Exception testing
$disk = '/dev/test_bad';
$mock->mock( 
    'update_data' => "Smartctl couldn't poll device",
);
$mock->unmock('run_short_test');

like( exception { $smart->get_disk_attributes($disk); }, qr/$disk not found in object/, 'get_disk_attributes() returns failure when passed invalid device' );
like( exception { $smart->get_disk_errors($disk); },     qr/$disk not found in object/, 'get_disk_model() returns failure when passed invalid device' );
like( exception { $smart->get_disk_health($disk); },     qr/$disk not found in object/, 'get_disk_health() returns failure when passed invalid device' );
like( exception { $smart->get_disk_model($disk); },      qr/$disk not found in object/, 'get_disk_model() returns failure when passed invalid device' );
like( exception { $smart->get_disk_temp($disk); },       qr/$disk not found in object/, 'get_disk_temp() returns failure when passed invalid device' );
like( exception { $smart->run_short_test($disk); },      qr/$disk not found in object/, 'run_short_test() returns failure when passed invalid device' );
like( $smart->update_data($disk),                        qr/couldn't poll/, 'update_data() returns falure when passed invalid device' );
