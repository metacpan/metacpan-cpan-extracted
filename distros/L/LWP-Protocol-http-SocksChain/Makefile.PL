
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::Protocol::http::SocksChain',
    VERSION_FROM      => 'SocksChain.pm',
    PREREQ_PM         => { 
							'Net::SC' 				=> 1.11,
							'LWP::Protocol::http'	=> 0
						},
	'AUTHOR'		=> 'Igor Okunev <igor@prv.mts-nn.ru>',
);
