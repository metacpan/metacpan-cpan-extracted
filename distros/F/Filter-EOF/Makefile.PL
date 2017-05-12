#!perl
use warnings;
use strict;

use inc::Module::Install;

name            q{Filter-EOF};
license         q{perl};
author          q{Robert 'phaylon' Sedlacek <rs@474.at>};
all_from        q{lib/Filter/EOF.pm};
version_from    q{lib/Filter/EOF.pm};
no_index        directory => q{examples};

requires        q{Filter::Util::Call},  '1.06';
requires        q{Carp},                0;
build_requires  q{Test::More},          '0.62';

WriteAll;


