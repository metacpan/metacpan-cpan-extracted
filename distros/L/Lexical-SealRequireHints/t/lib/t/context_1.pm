package t::context_1;

{ use 5.006; }
use warnings;
use strict;

die "t::context_1 sees array context at file scope" if wantarray;
die "t::context_1 sees void context at file scope" unless defined wantarray;

"t::context_1 return";
