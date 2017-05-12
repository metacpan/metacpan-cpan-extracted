
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A collocation of homework, classwork and exams",
  "dist_author" => [
    "Dr Bean <drbean at (a) cpan dot (.) org>"
  ],
  "dist_name" => "Grades",
  "dist_version" => "0.16",
  "license" => "perl",
  "module_name" => "Grades",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Encode" => 0,
    "File::Basename" => 0,
    "Getopt::Long" => 0,
    "IO::All" => 0,
    "Lingua::Han::PinYin" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "MooseX::Declare" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "Text::Template" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "script_files/print_grades.pl",
    "script_files/grade_jigsaw.pl",
    "script_files/sum_g1_g2.pl",
    "script_files/create_groups.pl",
    "script_files/school_data.pl",
    "script_files/anterior_data.pl",
    "script_files/grade_name_file.pl",
    "script_files/score_homework.pl",
    "script_files/score_jigsaw.pl",
    "script_files/scantron.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
