use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT note plan use_ok ) ];

my @module = qw( Log::Log4perl::Config::YamlConfigurator );

plan tests => 0 + @module;

note "Perl $] at $^X";
note 'Test::More ' . Test::More->VERSION;
note 'Test::Builder ' . Test::Builder->VERSION;
note "\@INC:\n  " . join "\n  ", @INC;

for my $module ( @module ) {
  use_ok $module or BAIL_OUT "Cannot load module '$module'";
  no warnings 'uninitialized'; ## no critic (ProhibitNoWarnings)
  note "Testing $module " . $module->VERSION;
}
