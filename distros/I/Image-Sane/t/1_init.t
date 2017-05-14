use Image::Sane ':all';
use Try::Tiny;
use Test::More tests => 1;

#########################

# the '.' was getting in the way of the argument stack in _init before pushmark
# and putback macros were added.
try {
    my $version = join( '.', Image::Sane->get_version );
    pass 'get_version as init';
}
catch {
    fail 'get_version as init';
};
