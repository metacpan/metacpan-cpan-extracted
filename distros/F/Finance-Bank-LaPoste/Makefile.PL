use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Finance::Bank::LaPoste',
	VERSION_FROM  => 'lib/Finance/Bank/LaPoste.pm',
	ABSTRACT_FROM => 'lib/Finance/Bank/LaPoste.pm',
	AUTHOR        => 'Pascal Pixel Rigaux <pixel@rigaux.org>',
	PREREQ_PM     => { 'HTTP::Cookies' => 0, 'LWP::UserAgent' => 0, 
			   'HTML::Parser' => 0, 'HTML::Form' => 0,
			   'Digest::MD5' => 0, 'Graphics::Magick' => 0 },
);
