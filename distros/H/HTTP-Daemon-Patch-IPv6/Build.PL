
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Avoid error when IO::Socket::INET6 is around",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "HTTP-Daemon-Patch-IPv6",
  "dist_version" => "0.06",
  "license" => "perl",
  "module_name" => "HTTP::Daemon::Patch::IPv6",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "HTTP::Daemon" => "6.01",
    "Module::Patch" => "0.12",
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
