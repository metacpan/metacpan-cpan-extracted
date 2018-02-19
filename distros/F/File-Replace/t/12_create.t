#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace.

=head1 Author, Copyright, and License

Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use File_Replace_Testlib;

use Test::More;

## no critic (RequireCarping)

BEGIN { use_ok 'File::Replace' }

my @testcases = (
	# default behavior                           NOTE: "warn" now means "fatal"
	{                                  expect=>'later', warn=>0 },
	# new behavior (as of 0.06)
	{                 create=>'no'   , expect=>'off'  , warn=>0 },
	{                 create=>'off'  , expect=>'off'  , warn=>0 },
	{                 create=>'now'  , expect=>'now'  , warn=>0 },
	{                 create=>'later', expect=>'later', warn=>0 },
	# compatibility behavior in 0.06, removed as of 0.08
	# except that the "undef" case is now equivalent to the default behavior!
	{                 create=>0      , expect=>'later', warn=>1 },
	{                 create=>undef  , expect=>'later', warn=>0 },
	{                 create=>1      , expect=>'now'  , warn=>1 },
	{                 create=>'true' , expect=>'now'  , warn=>1 },
	# old behavior, deprecated in 0.06, removed as of 0.08
	{ devnull=>0,                    , expect=>'off'  , warn=>2 },
	{ devnull=>0,     create=>0      , expect=>'off'  , warn=>2 },
	{ devnull=>0,     create=>undef  , expect=>'off'  , warn=>2 },
	{ devnull=>0,     create=>1      , expect=>'now'  , warn=>2 },
	{ devnull=>undef,                , expect=>'off'  , warn=>2 },
	{ devnull=>undef, create=>0      , expect=>'off'  , warn=>2 },
	{ devnull=>undef, create=>undef  , expect=>'off'  , warn=>2 },
	{ devnull=>undef, create=>1      , expect=>'now'  , warn=>2 },
	{ devnull=>1,                    , expect=>'later', warn=>2 },
	{ devnull=>1,     create=>0      , expect=>'later', warn=>2 },
	{ devnull=>1,     create=>undef  , expect=>'later', warn=>2 },
	{ devnull=>1,     create=>1      , expect=>'now'  , warn=>2 },
	{ devnull=>0,     create=>'no'   , expect=>'now'  , warn=>2 },
	{ devnull=>0,     create=>'now'  , expect=>'now'  , warn=>2 },
	{ devnull=>0,     create=>'later', expect=>'now'  , warn=>2 },
	{ devnull=>undef, create=>'no'   , expect=>'now'  , warn=>2 },
	{ devnull=>undef, create=>'now'  , expect=>'now'  , warn=>2 },
	{ devnull=>undef, create=>'later', expect=>'now'  , warn=>2 },
	{ devnull=>1,     create=>'off'  , expect=>'now'  , warn=>2 },
	{ devnull=>1,     create=>'now'  , expect=>'now'  , warn=>2 },
	{ devnull=>1,     create=>'later', expect=>'now'  , warn=>2 },
);

for my $t (@testcases) {
	my %opts;
	exists $$t{$_} and $opts{$_} = delete $$t{$_} for qw/devnull create/;
	my $name = ( join( ', ',
		map {"$_=".(defined($opts{$_})?"'$opts{$_}'":"undef")}
		sort keys %opts ) || "defaults" ) . " => $$t{expect}";
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my $sub;
	if ($$t{expect} eq 'off') { $sub = sub {
		my $fn = newtempfn;
		if ($$t{warn})
			# in this case we want the handler below to see the exception
			{ my $r = File::Replace->new($fn, %opts) }
		else {
			ok exception {
					my $r = File::Replace->new($fn, %opts);
				}, 'fails ok';
		}
		ok $!{ENOENT}, 'ENOENT';
		ok !-e $fn, "file doesn't exist";
	} }
	elsif ($$t{expect} eq 'now') { $sub = sub {
		my $fn = newtempfn;
		ok !-e $fn, "file doesn't exist";
		my $r = File::Replace->new($fn, %opts);
		ok -e $fn, 'file now exists';
		print {$r->out_fh} "Some\nthing\n";
		is slurp($fn), "", 'file is empty at first';
		$r->finish;
		is slurp($fn), "Some\nthing\n", 'file now has content';
	} }
	elsif ($$t{expect} eq 'later') { $sub = sub {
		my $fn = newtempfn;
		ok !-e $fn, "file doesn't exist";
		my $r = File::Replace->new($fn, %opts);
		ok eof($r->in_fh), 'eof';
		print {$r->out_fh} "Foo\n", "Bar\n";
		ok !-e $fn, "doesn't exist before finish";
		$r->finish;
		is slurp($fn), "Foo\nBar\n", 'file exists with content';
	} }
	else { die $$t{expect} }
	subtest $name => sub {
		my $ex = &exception($sub);
		if ($$t{warn}) {
			   if ($$t{warn}==1) { like $ex, qr/\bbad\s+value\b.+\bcreate\b/i, "create failure" }
			elsif ($$t{warn}==2) { like $ex, qr/\bunknown\s+option\b.+\bdevnull\b/i, "devnull failure" }
			else { die $$t{warn} }
		}
		else { ok !defined($ex), 'no exception' }
	};
}

# for code coverage, check this combination too
subtest "create='now' w/ layers" => sub {
	# copied from the "now" test above
	my $fn = newtempfn;
	ok !-e $fn, "file doesn't exist";
	my $r = File::Replace->new($fn, ':utf8', create=>'now');
	ok -e $fn, 'file now exists';
	print {$r->out_fh} "\x{20AC}";
	is slurp($fn), "", 'file is empty at first';
	$r->finish;
	is slurp($fn,':utf8'), "\x{20AC}", 'file now has content';
};

done_testing;

