package t::context_d1;

{ use 5.006; }
use warnings;
no warnings "void";
use strict;

die "t::context_d1 sees array context at file scope"
	if "$]" < 5.007001 && wantarray;
die "t::context_d1 sees scalar context at file scope"
	if "$]" >= 5.007001 && !wantarray && defined(wantarray);
die "t::context_d1 sees void context at file scope" unless defined wantarray;

("t::context_d1 return", "in three", "parts");
