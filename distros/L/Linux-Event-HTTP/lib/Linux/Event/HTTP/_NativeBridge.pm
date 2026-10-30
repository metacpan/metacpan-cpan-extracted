package Linux::Event::HTTP::_NativeBridge;
use v5.36;
use Linux::Event::HTTP ();
use Unblock::HTTP1::NativeABI 0.13 ();
require XSLoader;
XSLoader::load(__PACKAGE__, $Linux::Event::HTTP::VERSION);

sub definition {
    return { provider => \&_operations_address,
        abi_version => 1, operations_address => _operations_address() };
}

sub _input_operations_address ($engine) {
    if ($engine->isa('Unblock::HTTP2::_Connection')) {
        require Unblock::HTTP2::NativeABI;
        return (2, Unblock::HTTP2::NativeABI::definition()->{operations_address});
    }
    die 'unsupported HTTP native engine' unless $engine->isa('Unblock::HTTP1::_Engine');
    return (1, Unblock::HTTP1::NativeABI::definition()->{operations_address});
}

1;
