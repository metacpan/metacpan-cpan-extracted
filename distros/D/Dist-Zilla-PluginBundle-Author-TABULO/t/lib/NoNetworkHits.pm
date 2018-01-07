use strict;
use warnings;

# patch modules that hit the network, to be sure we don't do this during
# testing.
if (eval { +require HTTP::Tiny; 1 })
{
    no warnings 'redefine';
    *HTTP::Tiny::get = sub { die "HTTP::Tiny::get called for $_[1]" };
    *HTTP::Tiny::mirror = sub { die "HTTP::Tiny::mirror called for $_[1]" };
}

if (eval { +require LWP::UserAgent; 1 })
{
    no warnings 'redefine';
    *LWP::UserAgent::new = sub { die "LWP::UserAgent::new called for $_[1]" };
}

1;
