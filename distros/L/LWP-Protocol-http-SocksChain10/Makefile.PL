
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::Protocol::http::SocksChain10',
    VERSION_FROM      => 'SocksChain10.pm',
    PREREQ_PM         => { 
							'Net::SC' 				=> 1.11,
							'LWP::Protocol'			=> 0,
							'HTTP::Response'		=> 0,
							'HTTP::Status'			=> 0
						},
	'AUTHOR'		=> 'Igor Okunev <igor@prv.mts-nn.ru>',
);
