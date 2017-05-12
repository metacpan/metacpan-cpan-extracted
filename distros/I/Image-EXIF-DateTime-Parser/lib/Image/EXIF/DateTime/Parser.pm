# Copyright 2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
package Image::EXIF::DateTime::Parser;
use strict;
use warnings;
use Carp;
use POSIX;
use vars '$VERSION';
$VERSION = '1.2';

=head1 NAME

Image::EXIF::DateTime::Parser - parser for EXIF date/time strings

=head1 SYNOPSIS

  use Image::EXIF::DateTime::Parser;

  my $parser = Image::EXIF::DateTime::Parser->new;
  printf "%d\n", $p->parse("2009:05:05 09:17:37");

    produces "1241540257", if you are in America/Los_Angeles timezone.

=head1 DESCRIPTION

While parsing standards-compliant EXIF Date/Time string is easy, allowing for
the various ways different non-standards-compliant implementations mangle these
strings is neither easy nor pleasant. This module encapsulates this complexity
for you. It provides a parser which takes an EXIF Date/Time string and returns
time in "calendar time" format, aka. time_t.

=head2 EXPORTS

Nothing.

=head2 METHODS

=over

=item $p = Image::EXIF::DateTime::Parser->new

Returns a new parser object.

Introduced in version 1.1.

=cut

sub new
{
	my $that = shift;
	my $class = ref $that || $that;
	my $self = {};
	bless $self, $class;
}

=item $time_t = $p->parse( '2009:05:05 09:17:37' )

Takes a single argument: an EXIF Date/Time string, and returns a time_t value
by interpreting the string as local time.

Returns undef when the string represents an unknown date/time (zeros or blanks).

Throws an exception if the string is not parseable.

Introduced in version 1.1.

=cut

sub parse
{
	my $self = shift;
	my $string = shift;
	if ($string =~ /^([\d\x20]{4})(.)([\d\x20]{2})(.)([\d\x20]{2})(.)([\d\x20]{2})(.)([\d\x20]{2})(.)([\d\x20]{2})([-+]\d{2}:\d{2}|[.]\d{2}Z|.)?$/)
	{
		my ($y, $m, $d, $H, $M, $S) = ($1, $3, $5, $7, $9, $11);
		my @colons = ($2, $4, $8, $10);
		my @space = $6;
		# if all fields were whitespace-only or zeroes, it means that time is unknown
		return undef unless grep { ! /^( |0)+$/ } ($y, $m, $d, $H, $M, $S);
		my $time = POSIX::mktime($S, $M, $H, $d, $m-1, $y-1900, 0, 0, -1);
		return $time if defined $time;
		# falls through on mktime() error
	}
	croak "Unrecognized invalid string [$string].\n";
}

=head1 SECURITY

The module untaints the input string and passes the numbers (and spaces in some
cases) as arguments to POSIX::mktime. Thus as long as mktime can deal with
numbers and/or spaces on its input, the worst that can happen is that an
invalid date/time string will produce a surprising calendar time value or an
undef.

=head1 CAVEATS

=head2 Non-canonical time strings

Because it uses POSIX::mktime, this module can accept theoretically invalid
field values (such as 32nd day of month) and canonicalize them by appropriately
changing other field values.

=head2 Timezones

The parser currently ignores the timezone information and treats the string as
date/time in the timezone it currently runs in. Please note that the EXIF
standard actually forbids including timezone information the Date/Time string.

=head2 Invalid formats

This module tries to understand some common non-standards-compliant EXIF
Date/Time strings, but naturally it is not possible to allow for all present
and future ways that implementations can choose to mangle them. If you
encounter a string that is not recognized, but could be, please report it and I
will try to add it in the next version.

=head1 AUTHOR

Marcin Owsiany <marcin@owsiany.pl>

=head1 SEE ALSO

Image::Info(3), Image::ExifTool(3)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

=cut

1;
