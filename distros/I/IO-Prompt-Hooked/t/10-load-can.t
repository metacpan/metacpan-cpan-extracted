#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
  use_ok( 'Exporter'           ) || BAIL_OUT();
  use_ok( 'parent'             ) || BAIL_OUT();
  use_ok( 'Params::Smart'      ) || BAIL_OUT();
  use_ok( 'IO::Prompt::Tiny'   ) || BAIL_OUT();
  use_ok( 'IO::Prompt::Hooked' ) || BAIL_OUT();
}

diag( "Testing IO::Prompt::Hooked $IO::Prompt::Hooked::VERSION, Perl $], $^X" );

can_ok( 'IO::Prompt::Hooked', qw( prompt terminate_input ) );
can_ok( 'IO::Prompt::Hooked', qw( _unpack_prompt_params _hooked_prompt ) );

done_testing();
