package Linux::Event::HTTP::_HTTP1;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.003';

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

sub _raw_consumer_definition ($class) {
    return {
        provider           => \&_raw_consumer_operations_address,
        abi_version        => 1,
        operations_address => _raw_consumer_operations_address(),
    };
}

sub _raw_client_consumer_definition ($class) {
    return {
        provider           => \&_raw_client_consumer_operations_address,
        abi_version        => 1,
        operations_address => _raw_client_consumer_operations_address(),
    };
}

sub CLONE_SKIP { 1 }

1;
