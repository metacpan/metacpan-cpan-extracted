use ExtUtils::MakeMaker;
use EV::MakeMaker;

use Canary::Stability EV::ADNS => 1;

print <<EOF;

***
*** This is an interface to the asynchronous dns resolver library, libadns
*** You need to have it installed before using this module.
***
*** This module has only been tested with adns-1.4, earlier versions might
*** work, but are not supported (upgrading is highly recommended due to
*** the many bugs in earlier versions).
***
*** For Debian GNU/Linux and Ubuntu, this would get you there:
*** apt-get install libadns1-dev
***

EOF

my $mm = MM->new({EV::MakeMaker::ev_args (
    dist         => {
       PREOP	=> 'pod2text ADNS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "EV::ADNS",
    VERSION_FROM => "ADNS.pm",
    LIBS         => ["-ladns"],
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
       EV                  => 2,
    },
    CONFIGURE_REQUIRES => {
       EV                    => 2,
       "ExtUtils::MakeMaker" => 6.52,
       "Canary::Stability"   => 0,
    },
)});

$mm->flush;

