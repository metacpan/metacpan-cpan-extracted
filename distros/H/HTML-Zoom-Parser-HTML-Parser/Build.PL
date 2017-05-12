
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTML::Zoom" => 0,
    "HTML::Zoom::CodeStream" => 0,
    "HTML::Zoom::FilterBuilder" => 0,
    "HTML::Zoom::FilterStream" => 0,
    "HTML::Zoom::Producer::BuiltIn" => 0,
    "HTML::Zoom::SelectorParser" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Glue to power HTML::Zoom with HTML::Parser",
  "dist_author" => [
    "Matthew Phillips <mattp\@cpan.org>"
  ],
  "dist_name" => "HTML-Zoom-Parser-HTML-Parser",
  "dist_version" => "1.130810",
  "license" => "perl",
  "module_name" => "HTML::Zoom::Parser::HTML::Parser",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "HTML::Entities" => 0,
    "HTML::TokeParser" => 0,
    "HTML::Zoom::SubObject" => 0,
    "base" => 0,
    "strictures" => 1
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
