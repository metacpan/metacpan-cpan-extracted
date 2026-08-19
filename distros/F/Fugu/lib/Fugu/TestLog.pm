# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::TestLog;
our $VERSION = '0.1.2';

use Fugu::Log;

# Fugu::TestLog - a quiet process default logger for a test file.
#
# Library code reports a recoverable failure through
# Fugu::Log->default, which writes to standard error. A test that
# proves an error path would otherwise fill the TAP stream with the
# diagnostics it asked for.
#
#	use Fugu::TestLog;
#
# The import sets the quiet default. A test that wants to read what a
# module logged captures standard error around the call instead, and
# calls Fugu::TestLog->stderr to put the noisy default back.

sub import ($class)
{
	return $class->quiet;
}

# Fugu::TestLog->quiet:
#	Make the process default drop every message.
sub quiet ($class)
{
	return Fugu::Log->set_default(
		Fugu::Log->new( mode => Fugu::Log::MODE_QUIET ) );
}

# Fugu::TestLog->stderr:
#	Make the process default write to standard error again, for the
#	one test that reads what a module reported.
sub stderr ( $class, $level = 'debug' )
{
	return Fugu::Log->set_default(
		Fugu::Log->new(
			mode  => Fugu::Log::MODE_STDERR,
			level => $level,
		) );
}

1;
