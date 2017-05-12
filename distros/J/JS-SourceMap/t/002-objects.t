#! perl
##
# 002-objects.t - TEST ALL THE THINGS erm I mean OBJECTS
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
use Test::More tests => 42;
use JS::SourceMap::Token;
use JS::SourceMap::Index qw/token_index/;

use t::lib;

sub T { token_index(ref($_[0]) ? @{$_[0]} : @_) }

our @tokens = (
	JS::SourceMap::Token->new(0,0),
	JS::SourceMap::Token->new(0,5),
	JS::SourceMap::Token->new(1,0),
	JS::SourceMap::Token->new(1,12),
);
our @rows = ([0,5], [0,12]);
our %index = (
	T(0,0) => $tokens[0],
	T(0,5) => $tokens[1],
	T(1,0) => $tokens[2],
	T(1,12) => $tokens[3],
);
our $smi = JS::SourceMap::Index->new({},\@tokens,\@rows,\%index);
our $s = $smi->as_string;

ok($s,"index->as_string");

is($smi->len,scalar(@tokens),"index->len");
for(my $i = 0; $i < scalar(@tokens); ++$i) {
	my $t = $smi->get($i);
	is($t,$tokens[$i],"get($i)");
	ok($t->as_string,"token->as_string");
}

foreach my $i (0..4) {
	is($smi->lookup(0,$i),$tokens[0],"tokens[0]");
}
foreach my $i (5..9) {
	is($smi->lookup(0,$i),$tokens[1],"tokens[1]");
}
foreach my $i (0..11) {
	is($smi->lookup(1,$i),$tokens[2],"tokens[2]");
}
foreach my $i (12..19) {
	is($smi->lookup(1,$i),$tokens[3],"tokens[3]");
}
is($smi->lookup(123,10241),undef,"out of bounds is undef");
is($smi->lookup("123","10241"),undef,"out of bounds w/strings");

##
# Local variables:
# mode: perl
# tab-width: 8
# perl-indent-level: 8
# perl-continued-statement-offset: 4
# indent-tabs-mode: t
# End:
##
