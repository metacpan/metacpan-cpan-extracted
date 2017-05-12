use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Fax::Hylafax::Client',
	'VERSION_FROM'	=> 'Client.pm',
	'PREREQ_PM'	=> { 'Net::FTP' => 2.65 },
	($] >= 5.005 ? (ABSTRACT_FROM => 'Client.pm', AUTHOR => 'Alex Rak <arak@cpan.org>') : ()),
);
