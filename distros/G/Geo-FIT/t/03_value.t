# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 318;
use Geo::FIT;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

$o->file( 't/10004793344_ACTIVITY.fit' );

# a few defaults: may change some of these later but picking the same value as in fit2tcx.pl
$o->use_gmtime(1);              # already the default
$o->semicircles_to_degree(1);   # already the default
$o->numeric_date_time(0);
$o->without_unit(1);
$o->mps_to_kph(0);

my @must = ('Time');

# callbacks needed for this test file

my $cb_file_id = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( serial_number time_created manufacturer product number type );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( serial_number time_created manufacturer product type );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    # test switched() and named_type_value() -- field_value() also calls both of these as required, so also tested indirectly
    my ($type_name, $attr, $inval, $id) = (@{$desc}{ qw(t_product a_product I_product) }, $values->[ $desc->{i_product} ]);
    my $t_attr = $obj->switched($desc, $values, $attr->{switch});
    if (ref $t_attr eq 'HASH') {
        $attr      = $t_attr;
        $type_name = $attr->{type_name}
    }
    is( $type_name, 'garmin_product',           "   test switched() -- product in file_id");
    my  $product_ntv_sw = $obj->named_type_value($type_name, $values->[$desc->{i_product}]);
    is( $product_ntv_sw,  'edge_830',           "   test switched() and named_type_value(): product in file_id");

    # compare field_value() and named_type_value() -- should be the same as the former calls the latter
    #  - test that type is 'activity' (4) -- type here for this data message refers to the type of the FIT file
    my  $file_type             = $obj->field_value( 'type', $desc, $values );
    my  $file_type_ntv         = $obj->named_type_value($desc->{t_type}, $values->[$desc->{i_type}]);
    is( $file_type,              'activity',    "   test field_value() -- type in file_id");
    is( $file_type,              $file_type_ntv,"   test field_value() and named_type_value(): should be identical");
    my  $file_type_as_read     = $obj->field_value_as_read( 'type', $desc, $file_type );
    is( $file_type_as_read,      4,             "   test field_value_as_read(): activity in file_id");

    my  $manufacturer          = $obj->field_value( 'manufacturer', $desc, $values );
    is( $manufacturer,           'garmin',      "   test field_value(): manufacturer in file_id");
    my  $manufacturer_as_read  = $obj->field_value_as_read( 'manufacturer', $desc, $manufacturer );
    is( $manufacturer_as_read,   1,             "   test field_value_as_read(): manufacturer in file_id");

    my  $product               = $obj->field_value( 'product', $desc, $values );
    is( $product,                'edge_830',    "   test field_value(): product in file_id");
    my  $product_as_read       = $obj->field_value_as_read( 'product', $desc, $product, $values );
    is( $product_as_read,        3122,          "   test field_value_as_read() with an additional arg: product in file_id");

    my  $time_created          = $obj->field_value( 'time_created', $desc, $values );
    is( $time_created,           '2022-11-19T22:10:20Z', "   test field_value(): time_created in file_id");
    my  $time_created_as_read  = $obj->field_value_as_read( 'time_created', $desc, $time_created );
    is( $time_created_as_read,   1037830220,    "   test field_value_as_read(): time_created in file_id");

    #
    # field_value_as_read() with the type name instead of the values aref as last argument (expect the same result)
    $product_as_read = $obj->field_value_as_read( 'product', $desc, $product, $type_name );
    is( $product_as_read,        3122,          "   test field_value_as_read() with the type name as additional arg: product in file_id");

    # my $product_as_read = $obj->field_value_as_read( 'product', $desc, $product );
    # ... that one should croak

    1
    };

my $cb_file_creator = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( xxx2 software_version hardware_version );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( software_version );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $software_version    = $obj->field_value( 'software_version', $desc, $values );
    is( $software_version,     950,                     "   test field_value(): software_version in file_creator");

    1
    };

my @event_values_expected         = ( [ qw(timer start manual 0) ], [ qw(timer stop_all manual 0) ], [ qw(48 marker 200 1) ] );
my @event_values_expected_as_read = ( [0, 0, 0, 0], [0, 4, 0, 0], [48, 3, 200, 1] );
my $event_i = 0;
my $cb_event = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( timestamp data xxx17 xxx18 event event_type event_group );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( timestamp data event event_type event_group );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    # not testing timestamp here: we could

    my  $event               = $obj->field_value( 'event', $desc, $values );
    is( $event,                $event_values_expected[$event_i][0],             "   test field_value(): event in event");
    my  $event_as_read       = $obj->field_value_as_read( 'event', $desc, $event );
    is( $event_as_read,        $event_values_expected_as_read[$event_i][0],     "   test field_value_as_read(): event in event");

    my  $event_type          = $obj->field_value( 'event_type', $desc, $values );
    is( $event_type,           $event_values_expected[$event_i][1],             "   test field_value(): event_type in event");
    my  $event_type_as_read  = $obj->field_value_as_read( 'event_type', $desc, $event_type );
    is( $event_type_as_read,   $event_values_expected_as_read[$event_i][1],     "   test field_value_as_read(): event_type in event");

    my  $data                = $obj->field_value( 'data', $desc, $values );
    is( $data,                 $event_values_expected[$event_i][2],             "   test field_value(): data in event");
    my  $data_as_read        = $obj->field_value_as_read( 'data', $desc, $data, $values );
    is( $data_as_read,         $event_values_expected_as_read[$event_i][2],     "   test field_value_as_read() with additional arg: data in event");

    my  $event_group         = $obj->field_value( 'event_group', $desc, $values );
    is( $event_group,          $event_values_expected[$event_i][3],             "   test field_value(): event_group in event");
    my  $event_group_as_read = $obj->field_value_as_read( 'event_group', $desc, $event_group );
    is( $event_group_as_read,  $event_values_expected_as_read[$event_i][3],     "   test field_value_as_read(): event_group in event");

    ++$event_i;
    1
    };

my $device_info_got = 0;
my $device_info_i   = 0;
my $cb_device_info = sub {
    my ($obj, $desc, $values, $memo) = @_;

    $device_info_got = 1 if ++$device_info_i == 4;
    # there is also a device_info message near the end of the file, looks identical though

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( timestamp serial_number cum_operating_time xxx31 manufacturer product software_version battery_voltage xxx13 device_index device_type hardware_version battery_status ant_network source_type xxx29 xxx30 battery_level);
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    my  $device_index         = $obj->field_value( 'device_index', $desc, $values );
    my  $device_index_as_read = $obj->field_value_as_read( 'device_index', $desc, $device_index );

    if ( $device_index_as_read == 0 ) {
        is( $device_index,          'creator',  "   test field_value(): device_index in device_info");

        # test fields_defined()
        my @fields_defined     = $obj->fields_defined( $desc, $values );
        my @fields_defined_exp = qw( timestamp serial_number manufacturer product software_version device_index source_type );
        is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

        my  $manufacturer         = $obj->field_value( 'manufacturer', $desc, $values );
        is( $manufacturer,          'garmin',   "   test field_value(): manufacturer in device_info");
        my  $manufacturer_as_read = $obj->field_value_as_read( 'manufacturer', $desc, $manufacturer );
        is( $manufacturer_as_read,  1,          "   test field_value_as_read(): manufacturer in device_info");

        my  $product              = $obj->field_value( 'product', $desc, $values );
        is( $product,               'edge_830', "   test field_value(): product in device_info");
        my  $product_as_read      = $obj->field_value_as_read( 'product', $desc, $product, $values );
        is( $product_as_read,       3122,       "   test field_value_as_read() with an additional arg: product in device_info");

        my  $software_version = $obj->field_value( 'software_version', $desc, $values );
        is( $software_version,     '9.50',      "   test field_value(): software_version in device_info");

        my  $source_type          = $obj->field_value( 'source_type', $desc, $values );
        is( $source_type,           'local',    "   test field_value(): source_type in device_info");
        my  $source_type_as_read  = $obj->field_value_as_read( 'source_type', $desc, $source_type );
        is( $source_type_as_read,   5,          "   test field_value_as_read(): source_type in device_info");
    }

    if ( $device_index_as_read == 1 ) {
        is( $device_index,          'device1',  "   test field_value(): device_index in device_info");

        # test fields_defined()
        my @fields_defined     = $obj->fields_defined( $desc, $values );
        my @fields_defined_exp = qw( timestamp manufacturer product software_version device_index device_type source_type );
        is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           'barometer', "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   4,          "   test field_value_as_read() with additional arg: device_type in device_info");
    }

    if ( $device_index_as_read == 2 ) {
        is( $device_index,          'device2',  "   test field_value(): device_index in device_info");

        # test fields_defined()
        my @fields_defined     = $obj->fields_defined( $desc, $values );
        my @fields_defined_exp = qw( timestamp manufacturer product software_version device_index device_type source_type );
        is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           'gps',      "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   0,          "   test field_value_as_read() with additional arg: device_type in device_info");

        my  $product              = $obj->field_value( 'product', $desc, $values );
        is( $product,               3107,       "   test field_value(): product in device_info");
        # ... don't seem to have a name for this one
        my  $product_as_read      = $obj->field_value_as_read( 'product', $desc, $product, $values );
        is( $product_as_read,       3107,       "   test field_value_as_read() with an additional arg: product in device_info");

        my  $software_version = $obj->field_value( 'software_version', $desc, $values );
        is( $software_version,    '4.80',       "   test field_value(): software_version in device_info");
        my  $software_version_as_read  = $obj->field_value_as_read( 'software_version', $desc, $software_version );
        is( $software_version_as_read,   480,   "   test field_value_as_read(): software_version in device_info");

    }

    if ( $device_index_as_read == 3 ) {
        is( $device_index,          'heart_rate',  "   test field_value(): device_index in device_info");

        # test fields_defined()
        my @fields_defined     = $obj->fields_defined( $desc, $values );
        my @fields_defined_exp = qw( timestamp device_index device_type source_type );
        is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           7,          "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   7,          "   test field_value_as_read() with additional arg: device_type in device_info");
    }

    1
    };

my $cb_device_settings = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( utc_offset time_offset autosync_min_time active_time_zone time_mode time_zone_offset backlight_mode date_mode xxx77 lactate_threshold_autodetect_enabled xxx91 number_of_screens xxx106 xxx109 xxx110 xxx111 xxx121 xxx144 xxx170 xxx173 );
    is_deeply( \@fields_list, \@fields_list_exp,  "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( utc_offset time_offset active_time_zone time_mode time_zone_offset backlight_mode date_mode xxx77 lactate_threshold_autodetect_enabled xxx91 xxx106 xxx109 xxx110 xxx111 xxx121 xxx144 xxx170 );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $utc_offset          = $obj->field_value( 'utc_offset', $desc, $values );
    is( $utc_offset,           0,               "   test field_value(): utc_offset in device_settings");
    my  $utc_offset_as_read  = $obj->field_value_as_read( 'utc_offset', $desc, $utc_offset );
    is( $utc_offset_as_read,   0,               "   test field_value_as_read(): utc_offset in device_settings");

    my  $time_offset          = $obj->field_value( 'time_offset', $desc, $values );
    is( $time_offset,           71582488,       "   test field_value(): time_offset in device_settings");
    my  $time_offset_as_read  = $obj->field_value_as_read( 'time_offset', $desc, $time_offset );
    is( $time_offset_as_read,   71582488,       "   test field_value_as_read(): utc_offset in device_settings");

    my  $active_time_zone          = $obj->field_value( 'active_time_zone', $desc, $values );
    is( $active_time_zone,           0,         "   test field_value(): active_time_zone in device_settings");
    my  $active_time_zone_as_read  = $obj->field_value_as_read( 'active_time_zone', $desc, $active_time_zone );
    is( $active_time_zone_as_read,   0,         "   test field_value_as_read(): active_time_zone in device_settings");

    my  $time_mode          = $obj->field_value( 'time_mode', $desc, $values );
    is( $time_mode,           'hour12',         "   test field_value(): time_mode in device_settings");
    my  $time_mode_as_read  = $obj->field_value_as_read( 'time_mode', $desc, $time_mode );
    is( $time_mode_as_read,   0,                "   test field_value_as_read(): time_mode in device_settings");

    my  $time_zone_offset          = $obj->field_value( 'time_zone_offset', $desc, $values );
    is( $time_zone_offset,           '0.0',     "   test field_value(): time_zone_offset in device_settings");
    # when scale > 0, the value gets sprintf with decimal points (is that the propoer value here? Try with other more meaningful fields when scale>0)
    my  $time_zone_offset_as_read  = $obj->field_value_as_read( 'time_zone_offset', $desc, $time_zone_offset );
    is( $time_zone_offset_as_read,   0,         "   test field_value_as_read(): time_zone_offset in device_settings");

    my  $backlight_mode          = $obj->field_value( 'backlight_mode', $desc, $values );
    is( $backlight_mode,           'auto_brightness',       "   test field_value(): backlight_mode in device_settings");
    my  $backlight_mode_as_read  = $obj->field_value_as_read( 'backlight_mode', $desc, $backlight_mode );
    is( $backlight_mode_as_read,   3,           "   test field_value_as_read(): backlight_mode in device_settings");

    my  $date_mode          = $obj->field_value( 'date_mode', $desc, $values );
    is( $date_mode,           'month_day',      "   test field_value(): date_mode in device_settings");
    my  $date_mode_as_read  = $obj->field_value_as_read( 'date_mode', $desc, $date_mode );
    is( $date_mode_as_read,   1,                "   test field_value_as_read(): date_mode in device_settings");

    my  $lactate_threshold_autodetect_enabled          = $obj->field_value( 'lactate_threshold_autodetect_enabled', $desc, $values );
    is( $lactate_threshold_autodetect_enabled,           1,         "   test field_value(): lactate_threshold_autodetect_enabled in device_settings");
    my  $lactate_threshold_autodetect_enabled_as_read  = $obj->field_value_as_read( 'lactate_threshold_autodetect_enabled', $desc, $lactate_threshold_autodetect_enabled );
    is( $lactate_threshold_autodetect_enabled_as_read,   1,         "   test field_value_as_read(): lactate_threshold_autodetect_enabled in device_settings");

    1
    };

my $cb_user_profile = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( friendly_name wake_time sleep_time weight user_running_step_length user_walking_step_length gender age height language elev_setting weight_setting resting_heart_rate default_max_biking_heart_rate default_max_heart_rate hr_setting speed_setting dist_setting power_setting activity_class position_setting temperature_setting height_setting xxx44 xxx45 xxx57 );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( friendly_name wake_time sleep_time weight gender age height language elev_setting weight_setting resting_heart_rate default_max_biking_heart_rate default_max_heart_rate hr_setting speed_setting dist_setting power_setting activity_class position_setting temperature_setting height_setting xxx44 xxx45 xxx57 );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $friendly_name           = $obj->field_value( 'friendly_name', $desc, $values );
    is( $friendly_name,            101,         "   test field_value(): friendly_name in user_profile");
    my  $friendly_name_as_read   = $obj->field_value_as_read( 'friendly_name', $desc, $friendly_name );
    is( $friendly_name_as_read,    101,         "   test field_value_as_read(): friendly_name in user_profile");

    my  $wake_time               = $obj->field_value( 'wake_time', $desc, $values );
    is( $wake_time,                21645,       "   test field_value(): wake_time in user_profile");
    my  $wake_time_as_read       = $obj->field_value_as_read( 'wake_time', $desc, $wake_time );
    is( $wake_time_as_read,        21645,       "   test field_value_as_read(): wake_time in user_profile");

    my  $sleep_time              = $obj->field_value( 'sleep_time', $desc, $values );
    is( $sleep_time,               79200,       "   test field_value(): sleep_time in user_profile");
    my  $sleep_time_as_read      = $obj->field_value_as_read( 'sleep_time', $desc, $sleep_time );
    is( $sleep_time_as_read,       79200,       "   test field_value_as_read(): sleep_time in user_profile");

    my  $weight                  = $obj->field_value( 'weight', $desc, $values );
    is( $weight,                   86.2,        "   test field_value(): weight in user_profile");
    my  $weight_as_read          = $obj->field_value_as_read( 'weight', $desc, $weight );
    is( $weight_as_read,           862,         "   test field_value_as_read(): weight in user_profile");

    my  $height                  = $obj->field_value( 'height', $desc, $values );
    is( $height,                   1.78,        "   test field_value(): height in user_profile");
    my  $height_as_read          = $obj->field_value_as_read( 'height', $desc, $height );
    is( $height_as_read,           178,         "   test field_value_as_read(): height in user_profile");

    my  $language                = $obj->field_value( 'language', $desc, $values );
    is( $language,                 'french',    "   test field_value(): language in user_profile");
    my  $language_as_read  =       $obj->field_value_as_read( 'language', $desc, $language );
    is( $language_as_read,         1,           "   test field_value_as_read(): language in user_profile");

    my  $elev_setting            = $obj->field_value( 'elev_setting', $desc, $values );
    is( $elev_setting,             'metric',    "   test field_value(): elev_setting in user_profile");
    my  $elev_setting_as_read    = $obj->field_value_as_read( 'elev_setting', $desc, $elev_setting );
    is( $elev_setting_as_read,     0,           "   test field_value_as_read(): elev_setting in user_profile");

    my  $weight_setting          = $obj->field_value( 'weight_setting', $desc, $values );
    is( $weight_setting,           'statute',   "   test field_value(): weight_setting in user_profile");
    my  $weight_setting_as_read  = $obj->field_value_as_read( 'weight_setting', $desc, $weight_setting );
    is( $weight_setting_as_read,   1,           "   test field_value_as_read(): weight_setting in user_profile");

    my  $resting_heart_rate                     = $obj->field_value( 'resting_heart_rate', $desc, $values );
    is( $resting_heart_rate,                      0,       "   test field_value(): resting_heart_rate in user_profile");
    my  $resting_heart_rate_as_read             = $obj->field_value_as_read( 'resting_heart_rate', $desc, $resting_heart_rate );
    is( $resting_heart_rate_as_read,              0,       "   test field_value_as_read(): resting_heart_rate in user_profile");

    my  $default_max_biking_heart_rate          = $obj->field_value( 'default_max_biking_heart_rate', $desc, $values );
    is( $default_max_biking_heart_rate,           185,     "   test field_value(): default_max_biking_heart_rate in user_profile");
    my  $default_max_biking_heart_rate_as_read  = $obj->field_value_as_read( 'default_max_biking_heart_rate', $desc, $default_max_biking_heart_rate );
    is( $default_max_biking_heart_rate_as_read,   185,     "   test field_value_as_read(): default_max_biking_heart_rate in user_profile");

    my  $default_max_heart_rate                 = $obj->field_value( 'default_max_heart_rate', $desc, $values );
    is( $default_max_heart_rate,                  185,     "   test field_value(): default_max_heart_rate in user_profile");
    my  $default_max_heart_rate_as_read         = $obj->field_value_as_read( 'default_max_heart_rate', $desc, $default_max_heart_rate );
    is( $default_max_heart_rate_as_read,          185,     "   test field_value_as_read(): default_max_heart_rate in user_profile");

    my  $hr_setting                   = $obj->field_value( 'hr_setting', $desc, $values );
    is( $hr_setting,                    'max',  "   test field_value(): hr_setting in user_profile");
    my  $hr_setting_as_read           = $obj->field_value_as_read( 'hr_setting', $desc, $hr_setting );
    is( $hr_setting_as_read,            1,      "   test field_value_as_read(): hr_setting in user_profile");

    my  $speed_setting                = $obj->field_value( 'speed_setting', $desc, $values );
    is( $speed_setting,                 'metric',   "   test field_value(): speed_setting in user_profile");
    my  $speed_setting_as_read        = $obj->field_value_as_read( 'speed_setting', $desc, $speed_setting );
    is( $speed_setting_as_read,         0,          "   test field_value_as_read(): speed_setting in user_profile");

    my  $dist_setting                 = $obj->field_value( 'dist_setting', $desc, $values );
    is( $dist_setting,                  'metric',   "   test field_value(): dist_setting in user_profile");
    my  $dist_setting_as_read         = $obj->field_value_as_read( 'dist_setting', $desc, $dist_setting );
    is( $dist_setting_as_read,          0,          "   test field_value_as_read(): dist_setting in user_profile");

    my  $power_setting                = $obj->field_value( 'power_setting', $desc, $values );
    is( $power_setting,                 'percent_ftp',  "   test field_value(): power_setting in user_profile");
    my  $power_setting_as_read        = $obj->field_value_as_read( 'power_setting', $desc, $power_setting );
    is( $power_setting_as_read,         1,              "   test field_value_as_read(): power_setting in user_profile");

    my  $activity_class               = $obj->field_value( 'activity_class', $desc, $values );
    is( $activity_class,                'athlete=0,level=40,level_max=32',       "   test field_value(): activity_class in user_profile");
    my  $activity_class_as_read       = $obj->field_value_as_read( 'activity_class', $desc, $activity_class );
    is( $activity_class_as_read,        40,     "   test field_value_as_read(): activity_class in user_profile");

    my  $position_setting             = $obj->field_value( 'position_setting', $desc, $values );
    is( $position_setting,              'degree_minute',       "   test field_value(): position_setting in user_profile");
    my  $position_setting_as_read     = $obj->field_value_as_read( 'position_setting', $desc, $position_setting );
    is( $position_setting_as_read,      1,      "   test field_value_as_read(): position_setting in user_profile");

    my  $temperature_setting          = $obj->field_value( 'temperature_setting', $desc, $values );
    is( $temperature_setting,           'metric',   "   test field_value(): temperature_setting in user_profile");
    my  $temperature_setting_as_read  = $obj->field_value_as_read( 'temperature_setting', $desc, $temperature_setting );
    is( $temperature_setting_as_read,   0,          "   test field_value_as_read(): temperature_setting in user_profile");

    my  $height_setting               = $obj->field_value( 'height_setting', $desc, $values );
    is( $height_setting,                'statute',  "   test field_value(): height_setting in user_profile");
    my  $height_setting_as_read       = $obj->field_value_as_read( 'height_setting', $desc, $height_setting );
    is( $height_setting_as_read,        1,          "   test field_value_as_read(): height_setting in user_profile");

    1
    };

my $cb_sport = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( name sport sub_sport xxx15 xxx17 xxx18 );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( name sport sub_sport xxx15 xxx17 xxx18 );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $sport              = $obj->field_value( 'sport', $desc, $values );
    is( $sport,               'cycling',        "   test field_value(): sport in sport");
    my  $sport_as_read      = $obj->field_value_as_read( 'sport', $desc, $sport );
    is( $sport_as_read,       2,                "   test field_value_as_read(): sport in sport");

    my  $sub_sport          = $obj->field_value( 'sub_sport', $desc, $values );
    is( $sub_sport,           'mountain',       "   test field_value(): sub_sport in sport");
    my  $sub_sport_as_read  = $obj->field_value_as_read( 'sub_sport', $desc, $sub_sport );
    is( $sub_sport_as_read,   8,                "   test field_value_as_read(): sub_sport in sport");

    my  $name               = $obj->field_value( 'name', $desc, $values );
    is( $name,                77,               "   test field_value(): name in sport");
    my  $name_as_read       = $obj->field_value_as_read( 'name', $desc, $name );
    is( $name_as_read,        77,               "   test field_value_as_read(): name in sport");

    1
    };

my $cb_zones_target = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( xxx254 functional_threshold_power max_heart_rate threshold_heart_rate hr_calc_type pwr_calc_type );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( xxx254 functional_threshold_power threshold_heart_rate hr_calc_type pwr_calc_type );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $functional_threshold_power          = $obj->field_value( 'functional_threshold_power', $desc, $values );
    is( $functional_threshold_power,           200,     "   test field_value(): functional_threshold_power in zones_target");
    my  $functional_threshold_power_as_read  = $obj->field_value_as_read( 'functional_threshold_power', $desc, $functional_threshold_power );
    is( $functional_threshold_power_as_read,   200,     "   test field_value_as_read(): functional_threshold_power in zones_target");

    my  $threshold_heart_rate                = $obj->field_value( 'threshold_heart_rate', $desc, $values );
    is( $threshold_heart_rate,                 0,       "   test field_value(): threshold_heart_rate in zones_target");
    my  $threshold_heart_rate_as_read        = $obj->field_value_as_read( 'threshold_heart_rate', $desc, $threshold_heart_rate );
    is( $threshold_heart_rate_as_read,         0,       "   test field_value_as_read(): threshold_heart_rate in zones_target");

    my  $hr_calc_type           = $obj->field_value( 'hr_calc_type', $desc, $values );
    is( $hr_calc_type,            'percent_max_hr', "   test field_value(): hr_calc_type in zones_target");
    my  $hr_calc_type_as_read   = $obj->field_value_as_read( 'hr_calc_type', $desc, $hr_calc_type );
    is( $hr_calc_type_as_read,    1,                "   test field_value_as_read(): hr_calc_type in zones_target");

    my  $pwr_calc_type          = $obj->field_value( 'pwr_calc_type', $desc, $values );
    is( $pwr_calc_type,           1,                "   test field_value(): pwr_calc_type in zones_target");
    my  $pwr_calc_type_as_read  = $obj->field_value_as_read( 'pwr_calc_type', $desc, $pwr_calc_type );
    is( $pwr_calc_type_as_read,   1,                "   test field_value_as_read(): pwr_calc_type in zones_target");

    1
    };

my $lap_i   = 0;
my $cb_lap = sub {
    my ($obj, $desc, $values, $memo) = @_;

    return 1 if ++$lap_i > 1;                    # might test all laps in the future

    # the *.csv seems to indicate there is also enhanced_avg_speed, enhanced_max_speed
    # look into the python profile to see if I am missing some fields

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( timestamp start_time start_position_lat start_position_long end_position_lat end_position_long total_elapsed_time total_timer_time total_distance total_cycles nec_lat nec_long swc_lat swc_long total_work time_standing avg_left_power_phase avg_left_power_phase_peak avg_right_power_phase avg_right_power_phase_peak avg_power_position max_power_position total_grit avg_flow message_index total_calories total_fat_calories avg_speed max_speed avg_power max_power total_ascent total_descent normalized_power left_right_balance wkt_step_index stand_count avg_vam enhanced_avg_respiration_rate enhanced_max_respiration_rate xxx143 xxx145 jump_count xxx155 event event_type avg_heart_rate max_heart_rate avg_cadence max_cadence intensity lap_trigger sport event_group sub_sport avg_temperature max_temperature avg_fractional_cadence max_fractional_cadence total_fractional_cycles avg_left_torque_effectiveness avg_right_torque_effectiveness avg_left_pedal_smoothness avg_right_pedal_smoothness avg_combined_pedal_smoothness avg_left_pco avg_right_pco avg_cadence_position max_cadence_position min_temperature xxx152 );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( timestamp start_time start_position_lat start_position_long end_position_lat end_position_long total_elapsed_time total_timer_time total_distance nec_lat nec_long swc_lat swc_long total_grit avg_flow message_index total_calories avg_speed max_speed total_ascent total_descent avg_vam xxx145 jump_count xxx155 event event_type lap_trigger sport sub_sport avg_temperature max_temperature min_temperature );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $timestamp          = $obj->field_value( 'timestamp', $desc, $values );
    is( $timestamp,           '2022-11-19T22:12:47Z',       "   test field_value(): timestamp in lap");
    my  $timestamp_as_read  = $obj->field_value_as_read( 'timestamp', $desc, $timestamp );
    is( $timestamp_as_read,   1037830367,                   "   test field_value_as_read(): timestamp in lap");

    my  $start_position_lat           = $obj->field_value( 'start_position_lat', $desc, $values );
    is( $start_position_lat,            45.3913221,         "   test field_value(): start_position_lat in lap");

    my  $start_position_long          = $obj->field_value( 'start_position_long', $desc, $values );
    is( $start_position_long,           -75.7397311,        "   test field_value(): start_position_long in lap");

    my  $end_position_lat             = $obj->field_value( 'end_position_lat', $desc, $values );
    is( $end_position_lat,              45.3889448,         "   test field_value(): end_position_lat in lap");

    my  $end_position_long            = $obj->field_value( 'end_position_long', $desc, $values );
    is( $end_position_long,             -75.7396831,        "   test field_value(): end_position_long in lap");

    TODO: {
        local $TODO = "field_value_as_read() will fail for *lat/long* fields because the scale in the unit table to convert from semicircles to degrees has 6-decimal points, the value put back as it was (i.e. to semicircles as recorded in FIT files) will still have 6-decimal points whereas the original was an signed integer: will simply have to round the value somewhere based on a proper condition that applies only to these cases";

        my  $start_position_lat_as_read   = $obj->field_value_as_read( 'start_position_lat', $desc, $start_position_lat );
        is( $start_position_lat_as_read,    541539567,          "   test field_value_as_read(): start_position_lat in lap");
        my  $start_position_long_as_read  = $obj->field_value_as_read( 'start_position_long', $desc, $start_position_long );
        is( $start_position_long_as_read,   -903610189,         "   test field_value_as_read(): start_position_long in lap");
        my  $end_position_lat_as_read     = $obj->field_value_as_read( 'end_position_lat', $desc, $end_position_lat );
        is( $end_position_lat_as_read,      541511204,          "   test field_value_as_read(): end_position_lat in lap");
        my  $end_position_long_as_read    = $obj->field_value_as_read( 'end_position_long', $desc, $end_position_long );
        is( $end_position_long_as_read,     -903609617,         "   test field_value_as_read(): end_position_long in lap");
    }

    my  $total_elapsed_time           = $obj->field_value( 'total_elapsed_time', $desc, $values );
    is( $total_elapsed_time,            145.744,            "   test field_value(): total_elapsed_time in lap");
    my  $total_elapsed_time_as_read   = $obj->field_value_as_read( 'total_elapsed_time', $desc, $total_elapsed_time );
    is( $total_elapsed_time_as_read,    145744,             "   test field_value_as_read(): total_elapsed_time in lap");

    my  $total_timer_time          = $obj->field_value( 'total_timer_time', $desc, $values );
    is( $total_timer_time,           145.744,           "   test field_value(): total_timer_time in lap");
    my  $total_timer_time_as_read  = $obj->field_value_as_read( 'total_timer_time', $desc, $total_timer_time );
    is( $total_timer_time_as_read,   145744,            "   test field_value_as_read(): total_timer_time in lap");

    my  $total_distance          = $obj->field_value( 'total_distance', $desc, $values );
    is( $total_distance,           '393.60',            "   test field_value(): total_distance in lap");
    my  $total_distance_as_read  = $obj->field_value_as_read( 'total_distance', $desc, $total_distance );
    is( $total_distance_as_read,   39360,               "   test field_value_as_read(): total_distance in lap");

    TODO: {
        local $TODO = "Looks like systems that have nvtype='__float128' and nvsize=16 will return values with about 8 more decimal points: will simply have to round the value somehow or figure another approach, no sense having that much precision";

        my  $total_grit              = $obj->field_value( 'total_grit', $desc, $values );
        is( $total_grit,               1.08749997615814,    "   test field_value(): total_grit in lap");
        my  $total_grit_as_read      = $obj->field_value_as_read( 'total_grit', $desc, $total_grit );
        is( $total_grit_as_read,       1.08749997615814,    "   test field_value_as_read(): total_grit in lap");

        my  $avg_flow                = $obj->field_value( 'avg_flow', $desc, $values );
        is( $avg_flow,                 3.50719285011292,    "   test field_value(): avg_flow in lap");
        my  $avg_flow_as_read        = $obj->field_value_as_read( 'avg_flow', $desc, $avg_flow );
        is( $avg_flow_as_read,         3.50719285011292,    "   test field_value_as_read(): avg_flow in lap");
    }

    my  $message_index           = $obj->field_value( 'message_index', $desc, $values );
    is( $message_index,            'selected=0,reserved=0,mask=0',     "   test field_value(): message_index in lap");
    my  $message_index_as_read   = $obj->field_value_as_read( 'message_index', $desc, $message_index );
    is( $message_index_as_read,    0,                   "   test field_value_as_read(): message_index in lap");

    my  $total_calories          = $obj->field_value( 'total_calories', $desc, $values );
    is( $total_calories,           15,                  "   test field_value(): total_calories in lap");
    my  $total_calories_as_read  = $obj->field_value_as_read( 'total_calories', $desc, $total_calories );
    is( $total_calories_as_read,   15,                  "   test field_value_as_read(): total_calories in lap");

    my  $avg_speed               = $obj->field_value( 'avg_speed', $desc, $values );
    is( $avg_speed,                2.701,               "   test field_value(): avg_speed in lap");
    my  $avg_speed_as_read       = $obj->field_value_as_read( 'avg_speed', $desc, $avg_speed );
    is( $avg_speed_as_read,        2701,                "   test field_value_as_read(): avg_speed in lap");

    my  $max_speed               = $obj->field_value( 'max_speed', $desc, $values );
    is( $max_speed,                3.686,               "   test field_value(): max_speed in lap");
    my  $max_speed_as_read       = $obj->field_value_as_read( 'max_speed', $desc, $max_speed );
    is( $max_speed_as_read,        3686,                "   test field_value_as_read(): max_speed in lap");

    my  $total_ascent            = $obj->field_value( 'total_ascent', $desc, $values );
    is( $total_ascent,             8,                   "   test field_value(): total_ascent in lap");
    my  $total_ascent_as_read    = $obj->field_value_as_read( 'total_ascent', $desc, $total_ascent );
    is( $total_ascent_as_read,     8,                   "   test field_value_as_read(): total_ascent in lap");

    my  $total_descent           = $obj->field_value( 'total_descent', $desc, $values );
    is( $total_descent,            3,                   "   test field_value(): total_descent in lap");
    my  $total_descent_as_read   = $obj->field_value_as_read( 'total_descent', $desc, $total_descent );
    is( $total_descent_as_read,    3,                   "   test field_value_as_read(): total_descent in lap");

    my  $avg_vam                 = $obj->field_value( 'avg_vam', $desc, $values );
    is( $avg_vam,                  0.129,               "   test field_value(): avg_vam in lap");
    my  $avg_vam_as_read         = $obj->field_value_as_read( 'avg_vam', $desc, $avg_vam );
    is( $avg_vam_as_read,          129,                 "   test field_value_as_read(): avg_vam in lap");

    my  $jump_count              = $obj->field_value( 'jump_count', $desc, $values );
    is( $jump_count,               0,                   "   test field_value(): jump_count in lap");
    my  $jump_count_as_read      = $obj->field_value_as_read( 'jump_count', $desc, $jump_count );
    is( $jump_count_as_read,       0,                   "   test field_value_as_read(): jump_count in lap");

    my  $event                   = $obj->field_value( 'event', $desc, $values );
    is( $event,                    'lap',               "   test field_value(): event in lap");
    my  $event_as_read           = $obj->field_value_as_read( 'event', $desc, $event );
    is( $event_as_read,            9,                   "   test field_value_as_read(): event in lap");

    my  $event_type              = $obj->field_value( 'event_type', $desc, $values );
    is( $event_type,               'stop',              "   test field_value(): event_type in lap");
    my  $event_type_as_read      = $obj->field_value_as_read( 'event_type', $desc, $event_type );
    is( $event_type_as_read,       1,                   "   test field_value_as_read(): event_type in lap");

    my  $lap_trigger             = $obj->field_value( 'lap_trigger', $desc, $values );
    is( $lap_trigger,              'manual',            "   test field_value(): lap_trigger in lap");
    my  $lap_trigger_as_read     = $obj->field_value_as_read( 'lap_trigger', $desc, $lap_trigger );
    is( $lap_trigger_as_read,      0,                   "   test field_value_as_read(): lap_trigger in lap");

    my  $sport                   = $obj->field_value( 'sport', $desc, $values );
    is( $sport,                   'cycling',            "   test field_value(): sport in lap");
    my  $sport_as_read           = $obj->field_value_as_read( 'sport', $desc, $sport );
    is( $sport_as_read,            2,                   "   test field_value_as_read(): sport in lap");

    my  $sub_sport               = $obj->field_value( 'sub_sport', $desc, $values );
    is( $sub_sport,                'mountain',          "   test field_value(): sub_sport in lap");
    my  $sub_sport_as_read       = $obj->field_value_as_read( 'sub_sport', $desc, $sub_sport );
    is( $sub_sport_as_read,        8,                   "   test field_value_as_read(): sub_sport in lap");

    my  $avg_temperature          = $obj->field_value( 'avg_temperature', $desc, $values );
    is( $avg_temperature,           3,                  "   test field_value(): avg_temperature in lap");
    my  $avg_temperature_as_read  = $obj->field_value_as_read( 'avg_temperature', $desc, $avg_temperature );
    is( $avg_temperature_as_read,   3,                  "   test field_value_as_read(): avg_temperature in lap");

    my  $max_temperature          = $obj->field_value( 'max_temperature', $desc, $values );
    is( $max_temperature,           5,                  "   test field_value(): max_temperature in lap");
    my  $max_temperature_as_read  = $obj->field_value_as_read( 'max_temperature', $desc, $max_temperature );
    is( $max_temperature_as_read,   5,                  "   test field_value_as_read(): max_temperature in lap");

    my  $min_temperature          = $obj->field_value( 'min_temperature', $desc, $values );
    is( $min_temperature,           2,                  "   test field_value(): min_temperature in lap");
    my  $min_temperature_as_read  = $obj->field_value_as_read( 'min_temperature', $desc, $min_temperature );
    is( $min_temperature_as_read,   2,                  "   test field_value_as_read(): min_temperature in lap");

    1
    };

my $cb_session = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # the *.csv seems to indicate there is also enhanced_avg_speed, enhanced_max_speed
    # look into the python profile to see if I am missing some fields

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( timestamp start_time start_position_lat start_position_long total_elapsed_time total_timer_time total_distance total_cycles nec_lat nec_long swc_lat swc_long end_position_lat end_position_long total_work sport_profile_name time_standing avg_left_power_phase avg_left_power_phase_peak avg_right_power_phase avg_right_power_phase_peak avg_power_position max_power_position training_load_peak total_grit avg_flow message_index total_calories total_fat_calories avg_speed max_speed avg_power max_power total_ascent total_descent first_lap_index num_laps normalized_power training_stress_score intensity_factor left_right_balance threshold_power stand_count avg_vam xxx151 enhanced_avg_respiration_rate enhanced_max_respiration_rate xxx177 xxx178 xxx179 enhanced_min_respiration_rate jump_count xxx196 event event_type sport sub_sport avg_heart_rate max_heart_rate avg_cadence max_cadence total_training_effect event_group trigger avg_temperature max_temperature avg_fractional_cadence max_fractional_cadence total_fractional_cycles avg_left_torque_effectiveness avg_right_torque_effectiveness avg_left_pedal_smoothness avg_right_pedal_smoothness avg_combined_pedal_smoothness sport_index avg_left_pco avg_right_pco avg_cadence_position max_cadence_position total_anaerobic_training_effect xxx138 min_temperature xxx184 xxx185 xxx188 xxx202 );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( timestamp start_time start_position_lat start_position_long total_elapsed_time total_timer_time total_distance nec_lat nec_long swc_lat swc_long end_position_lat end_position_long sport_profile_name training_load_peak total_grit avg_flow message_index total_calories avg_speed max_speed total_ascent total_descent first_lap_index num_laps avg_vam xxx178 jump_count xxx196 event event_type sport sub_sport total_training_effect trigger avg_temperature max_temperature total_anaerobic_training_effect xxx138 min_temperature xxx184 xxx188 );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $timestamp          = $obj->field_value( 'timestamp', $desc, $values );
    is( $timestamp,           '2022-11-19T22:16:52Z',       "   test field_value(): timestamp in session");
    my  $timestamp_as_read  = $obj->field_value_as_read( 'timestamp', $desc, $timestamp );
    is( $timestamp_as_read,   1037830612,                   "   test field_value_as_read(): timestamp in session");

    my  $start_position_lat           = $obj->field_value( 'start_position_lat', $desc, $values );
    is( $start_position_lat,            45.3913221,         "   test field_value(): start_position_lat in session");

    my  $start_position_long          = $obj->field_value( 'start_position_long', $desc, $values );
    is( $start_position_long,           -75.7397311,        "   test field_value(): start_position_long in session");

    TODO: {
        local $TODO = "field_value_as_read() will fail for *lat/long* fields because the scale in the unit table to convert from semicircles to degrees has 6-decimal points, the value put back as it was (i.e. to semicircles as recorded in FIT files) will still have 6-decimal points whereas the original was an signed integer: will simply have to round the value somewhere based on a proper condition that applies only to these cases";

        my  $start_position_lat_as_read   = $obj->field_value_as_read( 'start_position_lat', $desc, $start_position_lat );
        is( $start_position_lat_as_read,    541539567,          "   test field_value_as_read(): start_position_lat in session");
        my  $start_position_long_as_read  = $obj->field_value_as_read( 'start_position_long', $desc, $start_position_long );
        is( $start_position_long_as_read,   -903610189,         "   test field_value_as_read(): start_position_long in session");
    }

    my  $total_elapsed_time           = $obj->field_value( 'total_elapsed_time', $desc, $values );
    is( $total_elapsed_time,            383.372,            "   test field_value(): total_elapsed_time in session");
    my  $total_elapsed_time_as_read   = $obj->field_value_as_read( 'total_elapsed_time', $desc, $total_elapsed_time );
    is( $total_elapsed_time_as_read,    383372,             "   test field_value_as_read(): total_elapsed_time in session");

    my  $total_timer_time          = $obj->field_value( 'total_timer_time', $desc, $values );
    is( $total_timer_time,           383.372,           "   test field_value(): total_timer_time in session");
    my  $total_timer_time_as_read  = $obj->field_value_as_read( 'total_timer_time', $desc, $total_timer_time );
    is( $total_timer_time_as_read,   383372,            "   test field_value_as_read(): total_timer_time in session");

    my  $total_distance          = $obj->field_value( 'total_distance', $desc, $values );
    is( $total_distance,           '1016.96',            "   test field_value(): total_distance in session");
    my  $total_distance_as_read  = $obj->field_value_as_read( 'total_distance', $desc, $total_distance );
    is( $total_distance_as_read,   101696,               "   test field_value_as_read(): total_distance in session");

    my  $nec_lat           = $obj->field_value( 'nec_lat', $desc, $values );
    is( $nec_lat,            45.3915843,        "   test field_value(): nec_lat in session");

    my  $nec_long           = $obj->field_value( 'nec_long', $desc, $values );
    is( $nec_long,            -75.7368912,      "   test field_value(): nec_long in session");

    my  $swc_lat           = $obj->field_value( 'swc_lat', $desc, $values );
    is( $swc_lat,            45.3889408,        "   test field_value(): swc_lat in session");

    my  $swc_long           = $obj->field_value( 'swc_long', $desc, $values );
    is( $swc_long,            -75.7408328,      "   test field_value(): swc_long in session");

    TODO: {
        local $TODO = "field_value_as_read() will fail for *lat/long* fields because the scale in the unit table to convert from semicircles to degrees has 6-decimal points, the value put back as it was (i.e. to semicircles as recorded in FIT files) will still have 6-decimal points whereas the original was an signed integer: will simply have to round the value somewhere based on a proper condition that applies only to these cases";

        my  $nec_lat_as_read   = $obj->field_value_as_read( 'nec_lat', $desc, $nec_lat );
        is( $nec_lat_as_read,    541542695,          "   test field_value_as_read(): nec_lat in session");
        my  $nec_long_as_read  = $obj->field_value_as_read( 'nec_long', $desc, $nec_long );
        is( $nec_long_as_read,   -903576308,         "   test field_value_as_read(): nec_long in session");

        my  $swc_lat_as_read   = $obj->field_value_as_read( 'swc_lat', $desc, $swc_lat );
        is( $swc_lat_as_read,    541511157,          "   test field_value_as_read(): swc_lat in session");
        my  $swc_long_as_read  = $obj->field_value_as_read( 'swc_long', $desc, $swc_long );
        is( $swc_long_as_read,   -903623333,         "   test field_value_as_read(): swc_long in session");
    }

    my  $training_load_peak           = $obj->field_value( 'training_load_peak', $desc, $values );
    # is( $training_load_peak,            0.83119201660156,            "   test field_value(): training_load_peak in session");
    # the scale in $attr is weird for this one it's 65536
    my  $training_load_peak_as_read   = $obj->field_value_as_read( 'training_load_peak', $desc, $training_load_peak );
    # is( $training_load_peak_as_read,    54473,             "   test field_value_as_read(): training_load_peak in session");
    # this one fails we get: 54473.5232, probably another scale with decimal values thing, look into it

    TODO: {
        local $TODO = "Looks like systems that have nvtype='__float128' and nvsize=16 will return values with about 8 more decimal points: will simply have to round the value somehow or figure another approach, no sense having that much precision";

        my  $total_grit              = $obj->field_value( 'total_grit', $desc, $values );
        is( $total_grit,               1.37812495231628,    "   test field_value(): total_grit in session");
        my  $total_grit_as_read      = $obj->field_value_as_read( 'total_grit', $desc, $total_grit );
        is( $total_grit_as_read,       1.37812495231628,    "   test field_value_as_read(): total_grit in session");

        my  $avg_flow                = $obj->field_value( 'avg_flow', $desc, $values );
        is( $avg_flow,                 3.37704300880432,    "   test field_value(): avg_flow in session");
        my  $avg_flow_as_read        = $obj->field_value_as_read( 'avg_flow', $desc, $avg_flow );
        is( $avg_flow_as_read,         3.37704300880432,    "   test field_value_as_read(): avg_flow in session");
    }

    my  $message_index           = $obj->field_value( 'message_index', $desc, $values );
    is( $message_index,            'selected=0,reserved=0,mask=0',     "   test field_value(): message_index in session");
    my  $message_index_as_read   = $obj->field_value_as_read( 'message_index', $desc, $message_index );
    is( $message_index_as_read,    0,                   "   test field_value_as_read(): message_index in session");

    my  $total_calories          = $obj->field_value( 'total_calories', $desc, $values );
    is( $total_calories,           27,                  "   test field_value(): total_calories in session");
    my  $total_calories_as_read  = $obj->field_value_as_read( 'total_calories', $desc, $total_calories );
    is( $total_calories_as_read,   27,                  "   test field_value_as_read(): total_calories in session");

    my  $avg_speed               = $obj->field_value( 'avg_speed', $desc, $values );
    is( $avg_speed,                2.653,               "   test field_value(): avg_speed in session");
    my  $avg_speed_as_read       = $obj->field_value_as_read( 'avg_speed', $desc, $avg_speed );
    is( $avg_speed_as_read,        2653,                "   test field_value_as_read(): avg_speed in session");

    my  $max_speed               = $obj->field_value( 'max_speed', $desc, $values );
    is( $max_speed,                4.581,               "   test field_value(): max_speed in session");
    my  $max_speed_as_read       = $obj->field_value_as_read( 'max_speed', $desc, $max_speed );
    is( $max_speed_as_read,        4581,                "   test field_value_as_read(): max_speed in session");

    my  $total_ascent            = $obj->field_value( 'total_ascent', $desc, $values );
    is( $total_ascent,             10,                   "   test field_value(): total_ascent in session");
    my  $total_ascent_as_read    = $obj->field_value_as_read( 'total_ascent', $desc, $total_ascent );
    is( $total_ascent_as_read,     10,                   "   test field_value_as_read(): total_ascent in session");

    my  $total_descent           = $obj->field_value( 'total_descent', $desc, $values );
    is( $total_descent,            10,                   "   test field_value(): total_descent in session");
    my  $total_descent_as_read   = $obj->field_value_as_read( 'total_descent', $desc, $total_descent );
    is( $total_descent_as_read,    10,                   "   test field_value_as_read(): total_descent in session");

    my  $first_lap_index                 = $obj->field_value( 'first_lap_index', $desc, $values );
    is( $first_lap_index,                  0,               "   test field_value(): first_lap_index in session");
    my  $first_lap_index_as_read         = $obj->field_value_as_read( 'first_lap_index', $desc, $first_lap_index );
    is( $first_lap_index_as_read,          0,                 "   test field_value_as_read(): first_lap_index in session");

    my  $num_laps                = $obj->field_value( 'num_laps', $desc, $values );
    is( $num_laps,                 3,               "   test field_value(): num_laps in session");
    my  $num_laps_as_read        = $obj->field_value_as_read( 'num_laps', $desc, $num_laps );
    is( $num_laps_as_read,         3,                 "   test field_value_as_read(): num_laps in session");

    my  $avg_vam                 = $obj->field_value( 'avg_vam', $desc, $values );
    is( $avg_vam,                  0.094,               "   test field_value(): avg_vam in session");
    my  $avg_vam_as_read         = $obj->field_value_as_read( 'avg_vam', $desc, $avg_vam );
    is( $avg_vam_as_read,          94,                 "   test field_value_as_read(): avg_vam in session");

    my  $jump_count              = $obj->field_value( 'jump_count', $desc, $values );
    is( $jump_count,               0,                   "   test field_value(): jump_count in session");
    my  $jump_count_as_read      = $obj->field_value_as_read( 'jump_count', $desc, $jump_count );
    is( $jump_count_as_read,       0,                   "   test field_value_as_read(): jump_count in session");

    my  $event                   = $obj->field_value( 'event', $desc, $values );
    is( $event,                    'lap',               "   test field_value(): event in session");
    my  $event_as_read           = $obj->field_value_as_read( 'event', $desc, $event );
    is( $event_as_read,            9,                   "   test field_value_as_read(): event in session");

    my  $event_type              = $obj->field_value( 'event_type', $desc, $values );
    is( $event_type,               'stop',              "   test field_value(): event_type in session");
    my  $event_type_as_read      = $obj->field_value_as_read( 'event_type', $desc, $event_type );
    is( $event_type_as_read,       1,                   "   test field_value_as_read(): event_type in session");

    my  $sport                   = $obj->field_value( 'sport', $desc, $values );
    is( $sport,                   'cycling',            "   test field_value(): sport in session");
    my  $sport_as_read           = $obj->field_value_as_read( 'sport', $desc, $sport );
    is( $sport_as_read,            2,                   "   test field_value_as_read(): sport in session");

    my  $sub_sport               = $obj->field_value( 'sub_sport', $desc, $values );
    is( $sub_sport,                'mountain',          "   test field_value(): sub_sport in session");
    my  $sub_sport_as_read       = $obj->field_value_as_read( 'sub_sport', $desc, $sub_sport );
    is( $sub_sport_as_read,        8,                   "   test field_value_as_read(): sub_sport in session");

    my  $trigger                  = $obj->field_value( 'trigger', $desc, $values );
    is( $trigger,                  'activity_end',          "   test field_value(): trigger in session");
    my  $trigger_as_read          = $obj->field_value_as_read( 'trigger', $desc, $trigger );
    is( $trigger_as_read,           0,                       "   test field_value_as_read(): trigger in session");

    my  $avg_temperature          = $obj->field_value( 'avg_temperature', $desc, $values );
    is( $avg_temperature,           2,                  "   test field_value(): avg_temperature in session");
    my  $avg_temperature_as_read  = $obj->field_value_as_read( 'avg_temperature', $desc, $avg_temperature );
    is( $avg_temperature_as_read,   2,                  "   test field_value_as_read(): avg_temperature in session");

    my  $max_temperature          = $obj->field_value( 'max_temperature', $desc, $values );
    is( $max_temperature,           5,                  "   test field_value(): max_temperature in session");
    my  $max_temperature_as_read  = $obj->field_value_as_read( 'max_temperature', $desc, $max_temperature );
    is( $max_temperature_as_read,   5,                  "   test field_value_as_read(): max_temperature in session");

    my  $min_temperature          = $obj->field_value( 'min_temperature', $desc, $values );
    is( $min_temperature,           0,                  "   test field_value(): min_temperature in session");
    my  $min_temperature_as_read  = $obj->field_value_as_read( 'min_temperature', $desc, $min_temperature );
    is( $min_temperature_as_read,   0,                  "   test field_value_as_read(): min_temperature in session");

    my  $total_training_effect                    = $obj->field_value( 'total_training_effect', $desc, $values );
    is( $total_training_effect,                     '0.0',        "   test field_value(): total_training_effect in session");
    my  $total_training_effect_as_read            = $obj->field_value_as_read( 'total_training_effect', $desc, $total_training_effect );
    is( $total_training_effect_as_read,             0,            "   test field_value_as_read(): total_training_effect in session");

    my  $total_anaerobic_training_effect          = $obj->field_value( 'total_anaerobic_training_effect', $desc, $values );
    is( $total_anaerobic_training_effect,           '0.0',        "   test field_value(): total_anaerobic_training_effect in session");
    my  $total_anaerobic_training_effect_as_read  = $obj->field_value_as_read( 'total_anaerobic_training_effect', $desc, $total_anaerobic_training_effect );
    is( $total_anaerobic_training_effect_as_read,   0,            "   test field_value_as_read(): total_anaerobic_training_effect in session");

    1
    };

my $cb_activity = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test fields_list()
    my @fields_list     = $obj->fields_list( $desc );
    my @fields_list_exp = qw( timestamp total_timer_time local_timestamp num_sessions type event event_type event_group );
    is_deeply( \@fields_list, \@fields_list_exp,        "   test fields_list()");

    # test fields_defined()
    my @fields_defined     = $obj->fields_defined( $desc, $values );
    my @fields_defined_exp = qw( timestamp total_timer_time local_timestamp num_sessions type event event_type );
    is_deeply( \@fields_defined, \@fields_defined_exp,  "   test fields_defined()");

    my  $timestamp                 = $obj->field_value( 'timestamp', $desc, $values );
    is( $timestamp,                  '2022-11-19T22:16:52Z',    "   test field_value(): timestamp in activity");
    my  $timestamp_as_read         = $obj->field_value_as_read( 'timestamp', $desc, $timestamp );
    is( $timestamp_as_read,          1037830612,                "   test field_value_as_read(): timestamp in activity");

    my  $total_timer_time          = $obj->field_value( 'total_timer_time', $desc, $values );
    is( $total_timer_time,           383.372,                   "   test field_value(): total_timer_time in activity");
    my  $total_timer_time_as_read  = $obj->field_value_as_read( 'total_timer_time', $desc, $total_timer_time );
    is( $total_timer_time_as_read,   383372,                    "   test field_value_as_read(): total_timer_time in activity");

    my  $local_timestamp           = $obj->field_value( 'local_timestamp', $desc, $values );
    is( $local_timestamp,            1037812612,                "   test field_value(): local_timestamp in activity");
    my  $local_timestamp_as_read   = $obj->field_value_as_read( 'local_timestamp', $desc, $local_timestamp );
    is( $local_timestamp_as_read,    1037812612,                "   test field_value_as_read(): local_timestamp in activity");

    my  $num_sessions              = $obj->field_value( 'num_sessions', $desc, $values );
    is( $num_sessions,               1,                         "   test field_value(): num_sessions in activity");
    my  $num_sessions_as_read      = $obj->field_value_as_read( 'num_sessions', $desc, $num_sessions );
    is( $num_sessions_as_read,       1,                         "   test field_value_as_read(): num_sessions in activity");

    my  $type                      = $obj->field_value( 'type', $desc, $values );
    is( $type,                       'manual',                  "   test field_value(): type in activity");
    my  $type_as_read              = $obj->field_value_as_read( 'type', $desc, $type );
    is( $type_as_read,               0,                         "   test field_value_as_read(): type in activity");

    my  $event                     = $obj->field_value( 'event', $desc, $values );
    is( $event,                     'activity',                 "   test field_value(): event in activity");
    my  $event_as_read             = $obj->field_value_as_read( 'event', $desc, $event );
    is( $event_as_read,              26,                        "   test field_value_as_read(): event in activity");

    my  $event_type                = $obj->field_value( 'event_type', $desc, $values );
    is( $event_type,                'stop',                     "   test field_value(): event_type in activity");
    my  $event_type_as_read        = $obj->field_value_as_read( 'event_type', $desc, $event_type );
    is( $event_type_as_read,         1,                         "   test field_value_as_read(): event_type in activity");

    1
    };

# actually, not using this href for now but may use it in the future
my $memo = { 'tpv' => [], 'trackv' => [], 'lapv' => [], 'av' => [] };

$o->data_message_callback_by_name('file_id',            $cb_file_id,            $memo) or die $o->error;
$o->data_message_callback_by_name('file_creator',       $cb_file_creator,       $memo) or die $o->error;
$o->data_message_callback_by_name('event',              $cb_event,              $memo) or die $o->error;
$o->data_message_callback_by_name('device_info',        $cb_device_info,        $memo) or die $o->error;
$o->data_message_callback_by_name('device_settings',    $cb_device_settings,    $memo) or die $o->error;
$o->data_message_callback_by_name('user_profile',       $cb_user_profile,       $memo) or die $o->error;
$o->data_message_callback_by_name('sport',              $cb_sport,              $memo) or die $o->error;
$o->data_message_callback_by_name('zones_target',       $cb_zones_target,       $memo) or die $o->error;
$o->data_message_callback_by_name('lap',                $cb_lap,                $memo) or die $o->error;
$o->data_message_callback_by_name('session',            $cb_session,            $memo) or die $o->error;
$o->data_message_callback_by_name('activity',           $cb_activity,           $memo) or die $o->error;
# my @f = $obj->fields_list( $desc );

#
# A - test field_value(), field_value_as_read(), named_type_value() and switched() with the above callbacks

my (@header_things, $ret_val);

$o->open or die $o->error;
@header_things = $o->fetch_header;

$ret_val = undef;

my $temp_max_i = 300;                   # temporary number of iterations (ensure we don't end up in endless loop if anything goes wrong)
my $i;
while ( my $ret = $o->fetch ) {
    # we are testing with callbacks, so not much to do here
    # as we add more tests, set the last to be when we have the latest one to test, i.e. will probably zones_target
    # last if $device_info_got;
    last if ++$i == $temp_max_i;
}
$o->close();

print "so debugger doesn't exit\n";

