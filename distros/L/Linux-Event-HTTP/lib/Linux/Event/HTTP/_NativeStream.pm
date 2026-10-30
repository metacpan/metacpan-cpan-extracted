package Linux::Event::HTTP::_NativeStream;
use v5.36;
use parent 'Linux::Event::HTTP::_Transport';
use Linux::Event::Framer ();
use Linux::Event::HTTP::_NativeBridge ();
Linux::Event::Framer->declare_native_consumer(
    __PACKAGE__, Linux::Event::HTTP::_NativeBridge::definition(),
);
1;
