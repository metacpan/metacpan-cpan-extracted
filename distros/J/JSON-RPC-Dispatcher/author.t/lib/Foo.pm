package Foo;

use lib '../lib';

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use utf8;

sub sum {
    my ($self, @params) = @_;
    my $sum = 0;
    $sum += $_ for @params;
    return $sum;
}

sub ip_address {
    my ($self, $plack_request) = @_;
    return $plack_request->address;
}

sub utf8_string {
    my $string = "déjà vu";
    utf8::decode($string);
    return $string;
}


__PACKAGE__->register_rpc_method_names( 'utf8_string', 'sum', { name => 'ip_address', options => { with_plack_request => 1 }} );

1;
