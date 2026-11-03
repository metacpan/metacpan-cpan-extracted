#!/usr/bin/env perl

# On a platform whose POSIX has no LC_MESSAGES (Windows), l_lang() sets the
# environment and leaves setlocale alone. Locale::gettext_pp answers its own
# LC_MESSAGES there with a stand-in number, so the guard asks POSIX.
#
# POSIX::LC_MESSAGES() is a constant that perl inlines at compile time, so
# the test removes it before POSIX's users compile, and records every
# setlocale call l_lang() makes.

use strict;
use warnings;

BEGIN {
	require POSIX;
	delete $POSIX::{LC_MESSAGES};
}

use Test::More;

use Locale::Simple;

my @setlocale;
{
	no warnings 'redefine';
	*Locale::Simple::setlocale = sub { push @setlocale, [ @_ ]; return };
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

local %ENV = %ENV;
l_lang('de_DE');

is_deeply( \@setlocale, [], 'l_lang calls no setlocale without POSIX LC_MESSAGES' );
is_deeply( \@warnings, [], 'l_lang warns about nothing' );
is( $ENV{$_}, 'de_DE', 'l_lang sets $ENV{'.$_.'}' )
  for qw( LANGUAGE LANG LC_ALL LC_MESSAGES );

done_testing;
