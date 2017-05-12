
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Calculates the maximum Google Maps zoom which fits the minimum bounding rectangle of Google Map points.",
  "dist_author" => [
    "Michael Portnoy <mport\@cpan.org>"
  ],
  "dist_name" => "Geo-GoogleMaps-FitBoundsZoomer",
  "dist_version" => "1.03",
  "license" => "perl",
  "module_name" => "Geo::GoogleMaps::FitBoundsZoomer",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "List::Util" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
