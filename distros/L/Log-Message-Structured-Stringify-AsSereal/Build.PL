
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Sereal-encoded base64'ed log lines",
  "dist_author" => [
    "Damien \"dams\" Krotkine"
  ],
  "dist_name" => "Log-Message-Structured-Stringify-AsSereal",
  "dist_version" => "0.11",
  "license" => "perl",
  "module_name" => "Log::Message::Structured::Stringify::AsSereal",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Log::Message::Structured" => "0.011",
    "MIME::Base64" => 0,
    "Moo" => 0,
    "Sereal::Encoder" => 0,
    "namespace::autoclean" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Capture::Tiny" => 0,
    "Test::More" => "0.88",
    "Test::Most" => 0,
    "blib" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
