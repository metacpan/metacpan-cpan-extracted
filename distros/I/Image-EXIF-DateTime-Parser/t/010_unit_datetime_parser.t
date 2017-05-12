#!/usr/bin/perl
# Image::EXIF::DateTime::Parser - parser for EXIF date/time strings
# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use POSIX 'strftime';
use ok 'Image::EXIF::DateTime::Parser';

my $p = Image::EXIF::DateTime::Parser->new;
ok($p);

sub parses_ok($$)
{
	my $s = shift;
	my $d = shift;
	is(strftime('%Y-%m-%d %H:%M:%S', localtime($p->parse($s))), $d);
}

sub parses_as_unknown($)
{
	my $s = shift;
	is($p->parse($s), undef);
}

sub dies_parsing($)
{
	my $s = shift;
	throws_ok(sub { $p->parse($s) }, qr{Unrecognized invalid string \[\Q$s\E\]});
}

# EXIF standard:
# Exchangeable image file format for digital still cameras: Exif Version 2.2
# Section 4.6.4 "TIFF Revision 6.0 Attribute information"
# Subsection D. "Other Tags", DateTime
parses_ok '2009:04:04 09:49:08', '2009-04-04 09:49:08';
parses_as_unknown '    :  :     :  :  ';

# We do our best to also read the following non-standard variations:

# Nikon camera, unknown model
parses_ok '2009.04.04 09.49.08', '2009-04-04 09:49:08';

# Adobe Photoshop CS2 Windows
# Let's ignore the timezone for now
parses_ok '2006:11:16 10:42:24-02:00', '2006-11-16 10:42:24';

# Unknown manufacturer's camera, model "Cam 3200"
# The characters separating fields seem to be semi-random binary garbage.
parses_ok '2009J04U04N09K49A08B', '2009-04-04 09:49:08';
parses_ok '2009J04U04N09K49Y08', '2009-04-04 09:49:08';

# Camera make  : NIKON CORPORATION
# Camera model : NIKON D40
parses_ok '2009:12:01 13:10:33.80Z', '2009-12-01 13:10:33';

# OLYMPUS OPTICAL CO.,LTD, model "C720UZ" or "D4034"
parses_as_unknown '0000:00:00 00:00:00';

# As a side-effect of POSIX::mktime "normalizing" fields, we also accept data
# such as this. Please do not rely on this behaviour.
parses_ok '2009:02:31 09:79:08', '2009-03-03 10:19:08';

# We do not accept garbage in place of numbers
dies_parsing '2009:0c:04 09:49:08';

1;
