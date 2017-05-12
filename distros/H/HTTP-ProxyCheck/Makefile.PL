use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'HTTP::ProxyCheck',
    'VERSION_FROM'	=> 'lib/HTTP/ProxyCheck.pm',
    'PREREQ_PM'		=> {
            'Validate::Net'	=> 0.4
    },
    ($] >= 5.005 ? (
            'ABSTRACT'		=> 'Checks HTTP proxy servers.',
            'AUTHOR'		=> 'Thomas Weibel (thomas@beeblebrox.net)'
    ) : ()),
);
