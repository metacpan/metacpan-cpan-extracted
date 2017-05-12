use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::BitStamp::Socket',
    VERSION_FROM      => 'lib/Finance/BitStamp/Socket.pm', # finds $VERSION
    PREREQ_PM         => {
        'AnyEvent::Socket'                       => 0,
        'AnyEvent::Handle'                       => 0,
        'Protocol::WebSocket::Handshake::Client' => 0,
        'Protocol::WebSocket::Frame'             => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/BitStamp/Socket.pm', # retrieve abstract from module
       AUTHOR         => 'Jeff Anderson <peawormsworth@gmail.com>') : ()),
);
