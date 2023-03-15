package t::context_d0;

{ use 5.006; }
use warnings;
use strict;

die "t::context_d0 sees array context at file scope" if wantarray;
die "t::context_d0 sees void context at file scope" unless defined wantarray;

"t::context_d0 return";
