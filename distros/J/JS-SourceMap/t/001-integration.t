#! perl
##
# 001-integration.t - JS::SourceMap integration tests
##
# Copyright (C) 2017 by attila <attila@stalphonsos.com>
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;
use Test::More tests => 14203;
use JS::SourceMap qw/discover loads load/;
use JSON;

use t::lib;

sub test_jquery {
	my($source,$minified,$min_map) = get_fixture("jquery");
	my @source_lines = split(/\n/,$source);
	is(discover($minified),"jquery.min.map");
	my $index = loads($min_map, assertions => 1);
	ok($index,"jquery map loaded");
	is_deeply($index->{'raw'},JSON->new->decode($min_map),"raw JSON");
	my $noname = 0;
	for(my $i = 0; $i < $index->len(); ++$i) {
		my $token = $index->get($i);
		if (!$token->name) {
			++$noname;
			next;
		}
		my $source_line = $source_lines[$token->src_line];
		my $start = $token->src_col;
		my $end = $start + length($token->name);
		my $substring = substr($source_line,$start,$end-$start);

		## This comment lifted verbatim from tests/test_integration.py
		## in the python-sourcemap source code:

		# jQuery's sourcemap has a few tokens that are identified
		# incorrectly.
		# For example, they have a token for 'embed', and
		# it maps to '"embe', which is wrong. This only happened
		# for a few strings, so we ignore
		next if substr($substring,0,1) eq '"';
		is($token->name,$substring,"token->name");
	}
	is($noname,4125,"tokens with no name");
}

sub test_coolstuff {
	my($source,$minified,$min_map) = get_fixture("coolstuff");
	my @source_lines = split(/\n/,$source);
	is(discover($minified),
	   "t/fixtures/coolstuff.min.map","discover coolstuff");
	my $index = loads($min_map, assertions => 1);
	ok($index,"loaded coolstuff map");
	is_deeply($index->{'raw'},JSON->new->decode($min_map),"raw JSON");
	my $noname = 0;
	for (my $i = 0; $i < $index->len(); ++$i) {
		my $token = $index->get($i);
		if (!$token->name) {
			++$noname;
			next;
		}
		my $source_line = $source_lines[$token->src_line];
		my $start = $token->src_col;
		my $end = $start + length($token->name);
		my $substring = substr($source_line,$start,$end-$start);
		is($substring,$token->name,"token->name");
	}
	is($noname,6,"tokens with no name");
}

test_jquery;
test_coolstuff;

our($js,$min,$map) = get_fixture("unicode");
ok(loads($map,assertions => 1),"unicode sourcemap loaded");
ok(load("t/fixtures/unicode.min.map",assertions => 1),"load works w/filename");

##
# Local variables:
# mode: perl
# tab-width: 8
# perl-indent-level: 8
# perl-continued-statement-offset: 4
# indent-tabs-mode: t
# End:
##
