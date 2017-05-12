use strict;
use warnings;
use Module::Build;
use Module::Load;
use File::Basename;
use File::Spec::Functions;

my $rh_requires;

BEGIN {

    $rh_requires = {
        'perl'                           => '5.010',
        'Geo::Distance::XS'              => '0.08',
        'HTTP::Request'                  => '5.827',
        'List::MoreUtils'                => '0.22',
        'List::Util::WeightedRoundRobin' => '0.4',
        'List::Util'                     => '1.23',
        'Net::Ping'                      => '2.33',
        'Time::HiRes'                    => '1.9711',
        'Sort::Versions'                 => '1.5',
    };

    my @geocoder_many_plugins = (
        'Bing',
        'Google',
        'Googlev3',
        'Mapquest',
        'OpenCage',
        'OSM',
        'Ovi',
        'PlaceFinder',
    );

    # Hack for conditional dependencies.  The geocoder plugins are optional,
    # but if they are installed, we do care that they are a recent version.
    # This detects the modules, and adds version dependencies for any that are
    # present.

    for my $geocoder (@geocoder_many_plugins) {
        my $module_name = 'Geo::Coder::' . $geocoder;
        my $plugin_name = 'Geo::Coder::Many::' . $geocoder;

        eval ( "use $module_name" );

        # If it's installed
        unless ($@) {
            # Load the plugin
            local @INC = (@INC, catdir(dirname(__FILE__), 'lib'));
            load($plugin_name);

            # If it requires a minimum version, add a dependency
            if ($plugin_name->can("_MIN_MODULE_VERSION")) {
                $rh_requires->{$module_name} = $plugin_name->_MIN_MODULE_VERSION;
            }
        }
    }
}

my $builder = Module::Build->new(
    module_name         => 'Geo::Coder::Many',
    license             => 'perl',
    dist_author         => q{Ed Freyfogle <cpan@lokku.com>},
    dist_version_from   => 'lib/Geo/Coder/Many.pm',
    requires            => $rh_requires,
    build_requires => {
        'Test::Exception'     => 0,
        'Test::MockObject'    => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Simple'        => 0,
    },
    add_to_cleanup      => [ 'Geo-Coder-Many-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/lokku/Geo-Coder-Many'
        },
    },
);

$builder->create_build_script();

