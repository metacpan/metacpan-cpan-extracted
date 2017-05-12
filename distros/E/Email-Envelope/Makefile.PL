use 5.00503;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Email::Envelope',
    VERSION_FROM      => 'lib/Email/Envelope.pm', # finds $VERSION
    PREREQ_PM         => {
	'Test::More'     => 0,
	'Email::Simple'  => 0,
	'Email::Address' => 0,
	'Regexp::Common' => 0
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Email/Envelope.pm', # retrieve abstract from module
       AUTHOR         => 'Scott McWhirter <kungfuftr@cpan.org>') : ()),
);
