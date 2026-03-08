use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is note require_ok ) ], tests => 3;

use Config qw( %Config );

my $main_module;
my $main_module_version;
{
  local @INC  = @INC;
  local @ARGV = qw( NAME VERSION );
  ( $main_module, $main_module_version ) = @{ require './Makefile.PL' }; ## no critic ( RequireBarewordIncludes )
  is $main_module, 'Getopt::Guided', 'Check main module'
}

require_ok $main_module or BAIL_OUT "Cannot load module '$main_module'";
is $main_module_version, $main_module->VERSION, 'Check main module version';
note "Testing $main_module $main_module_version";

note "Perl $] at $^X";
note 'Harness is ',      $ENV{ HARNESS_ACTIVE } ? 'on' : 'off';
note 'Harness ',         $ENV{ HARNESS_VERSION } if $ENV{ HARNESS_VERSION };
note 'Verbose mode is ', exists $ENV{ TEST_VERBOSE } ? 'on' : 'off';
note 'Test::More ',      Test::More->VERSION;
note 'Test::Builder ',   Test::Builder->VERSION;
note join "\n  ",        'PERL5LIB:', split( /$Config{ path_sep }/, $ENV{ PERL5LIB } ) if exists $ENV{ PERL5LIB };
note join "\n  ",        '@INC:',     @INC;
note join "\n  ", 'PATH:', split( /$Config{ path_sep }/, $ENV{ PATH } )
