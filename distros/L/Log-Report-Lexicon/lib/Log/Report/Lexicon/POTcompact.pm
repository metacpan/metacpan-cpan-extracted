# This code is part of Perl distribution Log-Report-Lexicon version 1.14.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Lexicon::POTcompact;{
our $VERSION = '1.14';
}

use base 'Log::Report::Lexicon::Table';

use warnings;
use strict;

use Log::Report        'log-report-lexicon';
use Log::Report::Util  qw/escape_chars unescape_chars/;

use Encode             qw/find_encoding/;

sub _unescape($$);
sub _escape($$);

#--------------------

sub read($@)
{	my ($class, $fn, %args) = @_;
	my $charset = $args{charset};

	my $self    = bless +{}, $class;

	# Try to pick-up charset from the filename (which may contain a modifier)
	$charset    = $1
		if !$charset && $fn =~ m!\.([\w-]+)(?:\@[^/\\]+)?\.po$!i;

	my $fh;
	if($charset)
	{	open $fh, "<:encoding($charset):crlf", $fn
			or fault __x"cannot read in {charset} from file {fn}", charset => $charset, fn => $fn;
	}
	else
	{	open $fh, '<:raw:crlf', $fn
			or fault __x"cannot read from file {fn} (unknown charset)", fn=>$fn;
	}

	# Speed!
	my $msgctxt = '';
	my ($last, $msgid, @msgstr);
	my $index   = $self->{index} ||= {};

	my $add = sub {
		unless($charset)
		{	$msgid eq ''
				or error __x"header not found for charset in {fn}", fn => $fn;

			$charset = $msgstr[0] =~ m/^content-type:.*?charset=["']?([\w-]+)/mi ? $1
			  : error __x"cannot detect charset in {fn}", fn => $fn;

			my $enc = find_encoding($charset)
				or error __x"unsupported charset {charset} in {fn}", charset => $charset, fn => $fn;

			trace "auto-detected charset $charset for $fn";
			binmode $fh, ":encoding($charset):crlf";

			$_ = $enc->decode($_) for @msgstr, $msgctxt;
		}

		$index->{"$msgid#$msgctxt"} = @msgstr > 1 ? [@msgstr] : $msgstr[0];
		($msgctxt, $msgid, @msgstr) = ('');
	};

  LINE:
	while(my $line = $fh->getline)
	{	next if substr($line, 0, 1) eq '#';

		if($line =~ m/^\s*$/)  # blank line starts new
		{	$add->() if @msgstr;
			next LINE;
		}

		if($line =~ s/^msgctxt\s+//)
		{	$msgctxt = _unescape $line, $fn;
			$last   = \$msgctxt;
		}
		elsif($line =~ s/^msgid\s+//)
		{	$msgid  = _unescape $line, $fn;
			$last   = \$msgid;
		}
		elsif($line =~ s/^msgstr\[(\d+)\]\s*//)
		{	$last   = \($msgstr[$1] = _unescape $line, $fn);
		}
		elsif($line =~ s/^msgstr\s+//)
		{	$msgstr[0] = _unescape $line, $fn;
			$last   = \$msgstr[0];
		}
		elsif($last && $line =~ m/^\s*\"/)
		{	$$last .= _unescape $line, $fn;
		}
	}
	$add->() if @msgstr;   # don't forget the last

	close $fh
		or failure __x"failed reading from file {fn}", fn => $fn;

	$self->{origcharset} = $charset;
	$self->{filename}    = $fn;
	$self->setupPluralAlgorithm;
	$self;
}

#--------------------

sub filename() { $_[0]->{filename} }
sub originalCharset() { $_[0]->{origcharset} }

#--------------------

sub index()     { $_[0]->{index} }
# The index is a HASH with "$msg#$msgctxt" keys.  If there is no
# $msgctxt, then there still is the #


sub msgid($) { $_[0]->{index}{$_[1].'#'.($_[2]//'')} }



# speed!!!
sub msgstr($;$$)
{	my ($self, $msgid, $count, $ctxt) = @_;

	$ctxt //= '';
	my $po  = $self->{index}{"$msgid#$ctxt"}
		or return undef;

	ref $po   # no plurals defined
		or return $po;

	$po->[$self->{algo}->($count // 1)] || $po->[$self->{algo}->(1)];
}

#
### internal helper routines, shared with ::PO.pm and ::POT.pm
#

sub _unescape($$)
{	unless( $_[0] =~ m/^\s*\"(.*)\"\s*$/ )
	{	warning __x"string '{text}' not between quotes at {location}", text => $_[0], location => $_[1];
		return $_[0];
	}
	unescape_chars $1;
}

sub _escape($$)
{	my @escaped = map { '"' . escape_chars($_) . '"' }
		defined $_[0] && length $_[0] ? split(/(?<=\n)/, $_[0]) : '';

	unshift @escaped, '""' if @escaped > 1;
	join $_[1], @escaped;
}

1;
