
# test to check actual results
use strict;
use warnings;

my %geocoders = (
    'Bing'        => 'Geo::Coder::Bing',
    'Googlev3'    => 'Geo::Coder::Googlev3',
    'Mapquest'    => 'Geo::Coder::Mapquest',
    'OpenCage'    => 'Geo::Coder::OpenCage',
    'OSM'         => 'Geo::Coder::OSM',
);

# currently we skip geocoders that require a key
# would of course be much better to allow tester to supply key
my %requires_key = (
    'Bing'        => 1,
    'Googlev3'    => 0,
    'Mapquest'    => 1,
    'OpenCage'    => 1,
    'OSM'         => 1,
);

my $num_tests = 2;   # Net::Ping and Geo::Coder::Many
use Test::More; 

##
## require internet connection
##
use_ok('Net::Ping');
my $P = Net::Ping->new('tcp',5);
my $ping_success = $P->ping('www.wikipedia.org');
$P->close();
if (!$ping_success){  # get out if no internet
    diag('bailing out - test requires internet connection');
    done_testing( 1 );
    exit 0;
} 
note('we have an internet connection, can continue with test!');

use lib "lib";
use_ok('Geo::Coder::Many');

my @testable_providers;
foreach my $provider (sort keys %geocoders){
    my $geocoder_module = $geocoders{$provider};
    note("checking if we can test using $geocoder_module");
    $num_tests++;

    SKIP: {
        eval "use $geocoder_module";
        skip "skipping $provider because not installed", 
             1 if $@;

        # we have the geocoder, can do the test
        use_ok($geocoder_module);
        push (@testable_providers, $provider);
    }
}

if (scalar(@testable_providers)){

    $num_tests++;
    use_ok('Geo::Distance::XS');
    my $GDXS = new Geo::Distance;
   
    my %test_addresses = (	
        'EC1M 5RF, United Kingdom' => {
            'latitude'  => 51.52262302479371, 
            'longitude' => -0.10244965553283691,
            'threshold' => 0.5, # km  # TODO: make provider specific
        },
    );

    my $GCM = new Geo::Coder::Many; # no cache, etc

    foreach my $provider (@testable_providers){
        $num_tests++;
        SKIP : {
            skip "skipping $provider because requires key", 
                1 if $requires_key{$provider};
            note("testing $provider");
            my $geocoder_module = $geocoders{$provider};
            my $GC = $geocoder_module->new;
            $GCM->add_geocoder({ geocoder => $GC });

            foreach my $address (sort keys %test_addresses){

                my $result = $GCM->geocode({
                             'location' => $address,
                             });
                ok(defined($result), "got a result for $address");
                 
                $num_tests++;
                my $distance = $GDXS->distance(
                                   'kilometer',
                                   $result->{longitude},
                                   $result->{latitude}
                                       => 
				   $test_addresses{$address}->{longitude},
				   $test_addresses{$address}->{latitude}
                               );
                my $threshold = $test_addresses{$address}->{threshold};
                ok($distance < $threshold, 
                   "geocoding $address with $provider correct to within " . 
                   "$threshold km");
            }
        }
    }
}

done_testing($num_tests);
