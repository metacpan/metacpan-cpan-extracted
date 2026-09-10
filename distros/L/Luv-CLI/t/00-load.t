use v5.38;
use Test::More;

my @modules = qw(
    Luv::CLI
    Luv::CLI::Manifest
    Luv::CLI::Git
    Luv::CLI::Package
    Luv::CLI::Registry
    Luv::CLI::Command::Init
    Luv::CLI::Command::Add
    Luv::CLI::Command::Remove
    Luv::CLI::Command::Build
    Luv::CLI::Command::List
    Luv::CLI::Command::Search
    Luv::CLI::Command::Update
);

use_ok($_) for @modules;

done_testing;
