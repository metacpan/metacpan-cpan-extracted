#!/usr/bin/env perl

use Test::More tests => 5;

use strict;
use warnings;

use IO::EditPrompt;

is( IO::EditPrompt::_format_prompt( undef ), '', 'undef returns empty' );
is( IO::EditPrompt::_format_prompt( '' ), '', 'empty string returns empty' );
is( IO::EditPrompt::_format_prompt( 'One line' ), "# One line\n", 'One line reformatted' );
is( IO::EditPrompt::_format_prompt( "One line\nanother" ), "# One line\n# another\n", 'Two lines reformatted' );
is( IO::EditPrompt::_format_prompt( "One line\n" ), "# One line\n", 'Trailing newline reformatted' );
