
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "MediaWiki::Bot" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A plugin to MediaWiki::Bot providing admin functions",
  "dist_author" => [
    "Dan Collins <en.wp.2t47\@gmail.com>",
    "Mike.lifeguard <mike.lifeguard\@gmail.com>",
    "patch and bug report contributors"
  ],
  "dist_name" => "MediaWiki-Bot-Plugin-Admin",
  "dist_version" => "3.004000",
  "license" => "gpl",
  "module_name" => "MediaWiki::Bot::Plugin::Admin",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Exporter" => 0,
    "List::Compare" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
