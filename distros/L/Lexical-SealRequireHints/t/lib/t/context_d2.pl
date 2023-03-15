package t::context_d2;

{ use 5.006; }
use warnings;
use strict;

die "t::context_d2 sees array context at file scope" if wantarray;
die "t::context_d2 sees scalar context at file scope"
	if "$]" >= 5.007001 && !wantarray && defined(wantarray);
die "t::context_d2 sees void context at file scope"
	if "$]" < 5.007001 && !defined(wantarray);

"t::context_d2 return";
