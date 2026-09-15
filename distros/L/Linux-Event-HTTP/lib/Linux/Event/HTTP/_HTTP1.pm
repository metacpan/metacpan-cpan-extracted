package Linux::Event::HTTP::_HTTP1;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.001';

require XSLoader;
XSLoader::load(__PACKAGE__);

my $NATIVE_PARSE_REQUEST = \&parse_request;

{
    no warnings 'redefine';
    *parse_request = sub ($class, @args) {
        require Linux::Event::HTTP::Request;
        return $NATIVE_PARSE_REQUEST->($class, @args);
    };
}

sub CLONE_SKIP { 1 }

1;
