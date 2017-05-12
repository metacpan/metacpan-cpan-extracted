
=head1 NAME

geo-coder-many.t

=head2 DESCRIPTION

General tests of Geo::Coder::Many

=cut

use strict;
use warnings;

# Set this to zero if you don't want to test third-party geocoders
my $enable_testing_of_remote_services = 1;

use Test::More;
use Test::MockObject;
use Test::Exception;

use Geo::Coder::Many;
use Geo::Coder::Many::Response;
use Geo::Coder::Many::Util qw( min_precision_filter max_precision_picker
  consensus_picker country_filter );

use HTTP::Response;
use Net::Ping;

# Trials to use for general test
my $trials = 10;

# Example picker callback for testing - only accepts a result if there are no
# more available, always asks for more
sub _fussy_picker {
    my ($ra_results, $more_available) = @_;
    if ($more_available) {
        return;
    }
    else {
        return $ra_results->[0];
    }
}

# Geocodes the same location several times, and displays the results (for
# debugging, mainly)
sub general_test {
    my ($geo_multiple, $location) = @_;

    my $freqs = {};
    my $i = 0;
    while ($i < $trials) {
        my $result = $geo_multiple->geocode(
            {
                location => $location, 
                wait_for_retries => 1 
            }
        );
        if (!defined $result) {
            $result->{geocoder} = "Could not geocode.";
        }
        else {
            if (defined $freqs->{$result->{geocoder}}) {
                $freqs->{$result->{geocoder}}++;
            }
            else {
                $freqs->{$result->{geocoder}} = 1;
            }
        }
        ++$i;
        print "$i: "
              .$result->{geocoder}
              ." | "
              .($result->{address}||'[ No address found ]')
              ."\n\n";
    }

    while (my ($geocoder, $freq) = each %$freqs) {
        print "$geocoder: $freq\n";
    }
}

# Use Test::MockObject to create a fake geocoder
sub fake_geocoder {
    my ($mock_number, $geocode_sub) = @_;

    my $geo_multi_mock = Test::MockObject->new;
    $geo_multi_mock->mock('get_daily_limit', sub { return 5000; });
    $geo_multi_mock->mock('geocode',
        sub {
            my ($self, $location) = @_;
            my $response = Geo::Coder::Many::Response->new(
                {
                    location => $location
                }
            );
            my $use_results = &$geocode_sub;
            my $http_response = HTTP::Response->new($use_results->{code});
            $response->add_response( 
                $use_results->{result}, 
                $self->get_name() 
            );
            $response->set_response_code($http_response->code());
            return $response;
        });
    $geo_multi_mock->mock('get_name', sub { return "mock$mock_number"; });

    my $ref_name_multi = "Geo::Coder::Many::Mock$mock_number";

    $geo_multi_mock->fake_module( $ref_name_multi );
    $geo_multi_mock->fake_new( $ref_name_multi );

    my $ref_name = "Geo::Coder::Mock$mock_number";

    my $geo_mock = Test::MockObject->new;
    $geo_mock->fake_module( $ref_name );

    # Bless the mock so that it has the correct ref...
    $geo_mock = bless {}, $ref_name;
    return $geo_mock;
}

# Produces a geocode result that is either successful or a failure at random.
sub random_fail {
    my $result = {
        address     => 'Address line1, line2, line3, etc',
        country     => 'United Kingdom',
        precision   => 0.6,
    };
    my $code;
    if ( rand() < 0.5 ) {
        $result->{longitude} = 0.0;
        $result->{latitude}  = 0.0;
        $code                = 400;
    }
    else {
        $result->{longitude} = -1.0;
        $result->{latitude}  = -1.0;
        $code                = 200;
    }
    return { result => $result, code => $code };
}

# Create a Geo::Coder::Many with the geocoders given by $args->{geocoders}
sub setup_geocoder {
    my $args = shift;

    my $geo_many = Geo::Coder::Many->new(
        {
            scheduler_type => $args->{scheduler_type},
            use_timeouts => $args->{use_timeouts}
        }
    );

    for my $gc (@{$args->{geocoders}}) {
        if ($args->{quiet}) {
            $geo_many->add_geocoder($gc) 
        } 
        else {
            lives_ok ( 
                sub { 
                    $geo_many->add_geocoder($gc) 
                },
                "Add ". ref($gc->{geocoder}) 
            );
        }
    }

    $geo_many->set_filter_callback($args->{filter});
    $geo_many->set_picker_callback($args->{picker});

    return $geo_many;
}

# Attempts to use a geocoder plugin module - if successful, add it to the array
# of geocoders to use. If a module is not provided, we just ignore that
# geocoder.
sub try_geocoder {
    my ($shortname, $ra_geocoders, %options) = @_;
    my $ref = 'Geo::Coder::' . $shortname;

    eval ( "use $ref" );

    if ($@) {
        warn ("$ref was not available - not testing it.\n");
        return;
    }

    my $geo = $ref->new(%options);
    ok (defined $geo, "Create $shortname geocoder");
    unshift @$ra_geocoders, { geocoder => $geo, daily_limit => 500 };
    return;
}

# Create the actual geocoders
sub create_geocoders {

    my @geocoders = ();

    my $geo_mock0 = fake_geocoder( 0, \&random_fail );
    my $geo_mock1 = fake_geocoder( 1, \&random_fail );
    ok (defined $geo_mock0 && defined $geo_mock1, 'Create mock geocoders');

    unshift @geocoders, map {
        {
            geocoder    => $_,
            daily_limit => 10000
        }
    } ($geo_mock0, $geo_mock1);

    try_geocoder( 'Bing',        \@geocoders, key    => 'YOUR_API_KEY' );
    try_geocoder( 'Google',      \@geocoders, apikey => 'YOUR_API_KEY' );
    try_geocoder( 'Mapquest',    \@geocoders, apikey => 'YOUR_API_KEY' );
    try_geocoder( 'OSM',         \@geocoders );
    try_geocoder( 'PlaceFinder', \@geocoders, appid  => 'YOUR_API_KEY' );

    return @geocoders;
}

# Thorough test of all combinations of options
{
    my $location = '82, Clerkenwell Road, London';

    sub to_hash {
        return { callback => shift, description => shift };
    }

    my @filter_callbacks = (
        to_hash( ''    => '\'\'' ),
        to_hash( 'all' => '\'all\'' ),
        to_hash( sub { return 0; }            => 'never [sub]' ),
        to_hash( sub { return 1; }            => 'always [sub]' ),
        to_hash( sub { return rand() < 0.5; } => '50/50 [sub]' ),
        to_hash( country_filter('United Kingdom') => 'UK only' ),
        to_hash( min_precision_filter(0.3)        => 'min_precision' ),
    );

    my @picker_callbacks = (
        to_hash( ''              => '\'\'' ),
        to_hash( 'max_precision' => '\'max_precision\'' ),
        to_hash( \&_fussy_picker => 'fussy [coderef]' ),
        to_hash( sub { return; } => 'undef [coderef]' ),
        to_hash(
            consensus_picker(
                {
                    required_consensus => 2,
                    nearness           => 0.1
                }
              ) => 'consensus [Util]'
        ),
    );

    my @schedulers = (
        'WRR',
        'OrderedList',
        'WeightedRandom',
    );


    my @geocoders = create_geocoders();

    my @mock_geocoders = grep { ref($_->{geocoder}) =~ /Mock/ } @geocoders;

    for my $filter (@filter_callbacks) {
        for my $picker (@picker_callbacks) {
            for my $scheduler (@schedulers) {
                for my $timeouts ((0, 1)) {
                    my $geo;
                    lives_and { 
                        $geo = &setup_geocoder({
                                filter => $filter->{callback},
                                picker => $picker->{callback},
                                scheduler_type => $scheduler,
                                use_timeouts => $timeouts,
                                geocoders => \@mock_geocoders,
                                quiet => 1,
                            });
                        ok (defined $geo);
                        for (1 .. 10) {
                            my $result = $geo->geocode({location => $location});
                        }
                    } 
                    "Geo::Coder::Many [["
                    ." Filter: " . $filter->{description} 
                    ." | Picker: " .$picker->{description}
                    ." | Scheduler: $scheduler"
                    ." | Timeouts: $timeouts ]]";
                }
            }
        }
    }

    my $p = Net::Ping->new;
    if ($enable_testing_of_remote_services && $p->ping('example.com')) {
        lives_ok {
            my $geo_many = &setup_geocoder({
                    filter => 'all',
                    picker => '', 
                    scheduler_type => 'WRR', 
                    use_timeouts => 1, 
                    geocoders => \@geocoders
                });
            &general_test($geo_many, $location);
        } "Test with actual geocoders";
    }
    $p->close();

    done_testing();
}

1;
__END__
