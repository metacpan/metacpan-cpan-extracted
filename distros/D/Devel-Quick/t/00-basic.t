#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Devel::Quick;

# errors get reported properly
throws_ok
	{ Devel::Quick->import('$x - '); }
	qr/Failed to parse code:.*30:\s+\$x -/ms,
	"Bad code detected and reported"
;

# non-strict is default
lives_ok
	{ Devel::Quick->import('$x = 1'); }
	'Strict is disabled by default'
;

# strict is enabled when asked for by long form
throws_ok
	{ Devel::Quick->import('-strict', '$x = 1') }
	qr/Failed to parse code: Global symbol \"\$x\" requires explicit/,
	"Strict is enabled by -strict"
;

# strict is enabled when asked for by short form
throws_ok
	{ Devel::Quick->import('-s', '$x = 1') }
	qr/Failed to parse code: Global symbol \"\$x\" requires explicit/,
	"Strict is enabled by -s"
;

# strict doesn't prevent code from working
lives_ok
	{ Devel::Quick->import('-s', 'my $x = 1'); }
	'Strict code works'
;

# Bad switch
throws_ok
	{ Devel::Quick->import('-r', '$x = 1') }
	qr/Unknown switch '-r'/,
	"Bad switches are detected"
;

# Can still use '-' as first char in code
lives_ok
	{ Devel::Quick->import('; $x = 1') }
	'Switch processing bypassed by \';\' as first character'
;

# -s and -strict are removed...
lives_ok
	{ Devel::Quick->import('-s', 'if (1 == 1) { }') }
	'-s is not injected into final code'
;

# -s and -strict are removed...
lives_ok
	{ Devel::Quick->import('-strict', 'if (1 == 1) { }') }
	'-strict is not injected into final code'
;

# -b and -begin work
lives_ok
	{ Devel::Quick->import('-b', 'if (1 == 1) { }') }
	'-b is allowed'
;

lives_ok
	{ Devel::Quick->import('-begin', 'if (1 == 1) { }') }
	'-begin is allowed'
;

# All options are processed
throws_ok
	{ Devel::Quick->import('-b','-s','-r', '$x = 1') }
	qr/Unknown switch '-r'/,
	"Multiple switches are processed"
;

done_testing;
