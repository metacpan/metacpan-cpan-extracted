package t::context_2;

{ use 5.006; }
use warnings;
use strict;

die "t::context_2 sees array context at file scope" if wantarray;
die "t::context_2 sees void context at file scope" unless defined wantarray;

"t::context_2 return";
