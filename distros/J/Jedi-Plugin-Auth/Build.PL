
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
  "dist_abstract" => "Auth for Jedi",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "Jedi-Plugin-Auth",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Jedi::Plugin::Auth",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "B::Hooks::EndOfScope" => 0,
    "Carp" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Migration" => 0,
    "DBIx::Class::Schema" => 0,
    "Data::UUID" => 0,
    "Digest::SHA1" => 0,
    "Import::Into" => 0,
    "JSON" => 0,
    "Jedi" => "1.002",
    "Jedi::Plugin::Session" => "0.04",
    "Module::Runtime" => 0,
    "Moo::Role" => 0,
    "Path::Class" => 0,
    "base" => 0,
    "feature" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "File::Spec" => 0,
    "HTTP::Request::Common" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Jedi" => "1.002",
    "Jedi::App" => 0,
    "Jedi::Plugin::Session" => "0.04",
    "Plack::Test" => 0,
    "Scalar::Util" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "perl" => "5.010"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "HTTP::Request::Common" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Jedi" => "1.002",
  "Jedi::App" => 0,
  "Jedi::Plugin::Session" => "0.04",
  "Module::Build" => "0.3601",
  "Plack::Test" => 0,
  "Scalar::Util" => 0,
  "Test::File::ShareDir" => 0,
  "Test::More" => "0.94",
  "Test::Most" => 0,
  "perl" => "5.010"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
