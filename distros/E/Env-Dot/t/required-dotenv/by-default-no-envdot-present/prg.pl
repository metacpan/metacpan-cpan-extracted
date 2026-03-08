#!perl
## no critic (InputOutput::RequireCheckedSyscalls)
use strict;
use warnings;
use utf8;
use 5.010;
use Env::Dot;
say 'FOO: ' . ( $ENV{FOO} // q{} );
say 'BAR: ' . ( $ENV{BAR} // q{} );
say 'BAZ: ' . ( $ENV{BAZ} // q{} );
