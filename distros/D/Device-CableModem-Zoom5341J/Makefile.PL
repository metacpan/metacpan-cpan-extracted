use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Device::CableModem::Zoom5341J',
    AUTHOR            => q{Matthew Fuller <fullermd@over-yonder.net>},
    VERSION_FROM      => 'lib/Device/CableModem/Zoom5341J.pm',
    ABSTRACT_FROM     => 'lib/Device/CableModem/Zoom5341J.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PREREQ_PM         => {
        'LWP::UserAgent' => 0,
    },
);
