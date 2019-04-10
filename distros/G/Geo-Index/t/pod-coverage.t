use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;


my $_internal_functions = [
                            'AddValue', 
                            'BuildPoints', 
                            'ComputeAreaExtrema', 
                            'ComputeAreaExtrema_double', 
                            'ComputeAreaExtrema_float', 
                            'DeletePointIndex', 
                            'GetCCodeVersion', 
                            'GetDistanceFunctionType', 
                            'GetIndices', 
                            'GetIntLat', 
                            'GetIntLatLon', 
                            'GetIntLon', 
                            'GetLowLevelCodeType', 
                            'GetSupportedLowLevelCodeTypes', 
                            'GetValue', 
                            'HaversineDistance', 
                            'HaversineDistance_double', 
                            'HaversineDistance_float', 
                            'LongitudeCircumference', 
                            'OneDegreeInMeters', 
                            'OneMeterInDegrees', 
                            'SetDistanceFunctionType', 
                            'SetUpDistance_double', 
                            'SetUpDistance_float', 
                            'dl_load_flags', 
                            'fast_log2', 
                            'fast_log2_double', 
                            'fast_log2_float', 
                            'log2', 
                            
                            # Method aliases:
                            'add_value', 
                            'all_points', 
                            'build_points', 
                            'closest', 
                            'distance_from', 
                            'distance_to', 
                            'farthest', 
                            'get_configuration', 
                            'get_statistics', 
                            'get_value', 
                            'index_points', 
                            'one_degree_in_meters', 
                            'one_meter_in_degrees', 
                            'point_count', 
                            'search_by_bounds', 
                            'sweep', 
                            'unindex', 
                            'vacuum', 
                            
                            # Aliases for internally-used methods:
                            'get_indices', 
                            'get_int_lat', 
                            'get_int_lat_lon', 
                            'get_int_lon', 
                            'get_low_level_code_type', 
                            'get_supported_low_level_code_types', 
                            'haversine_distance', 
                            'longitude_circumference', 
                            'set_distance_function_type', 
                            'set_up_distance' 
                            
                            # Experimental methods:
                          ];

all_pod_coverage_ok( { trustme=>$_internal_functions } );

