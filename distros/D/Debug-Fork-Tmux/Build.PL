use lib 'inc';
use Devel::AssertOS qw[Unix];

use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Sort::Versions" => 0,
    "Sub::Name" => 0,
    "Test::Exception" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::Strict" => 0,
    "Test::Version" => "1.002",
    "autodie" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Makes fork() in debugger to open a new Tmux window",
  "dist_author" => [
    "L<Peter Vereshagin|http://vereshagin.org> <peter\@vereshagin.org>"
  ],
  "dist_name" => "Debug-Fork-Tmux",
  "dist_version" => "1.000012",
  "license" => "bsd",
  "module_name" => "Debug::Fork::Tmux",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Config" => 0,
    "Const::Fast" => 0,
    "Cwd" => 0,
    "Env::Path" => 0,
    "File::Basename" => 0,
    "File::Spec" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
