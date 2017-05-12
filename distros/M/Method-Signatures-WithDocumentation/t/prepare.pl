#!/usr/bin/perl -w

use Sub::Documentation qw(get_documentation);
use YAML::Any qw(DumpFile);
use Class::Load qw(load_class);

my $mod = shift @ARGV;

use lib '.';
load_class "t::lib::$mod";

DumpFile("t/$mod.yml", get_documentation());
