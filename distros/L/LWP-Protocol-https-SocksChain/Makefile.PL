
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::Protocol::https::SocksChain',
    VERSION_FROM      => 'SocksChain.pm',
    PREREQ_PM         => {	Net::SC => 1.11,
							IO::Socket::SSL => undef,
							LWP => undef
						},
	'AUTHOR'		=> 'Igor Okunev <igor@prv.mts-nn.ru>',
);
