use ExtUtils::MakeMaker ;
 
WriteMakefile(
    'NAME'		=> 'File::FDkeeper',
    'VERSION_FROM'	=> 'FDkeeper.pm', 
    'PREREQ_PM'		=> {
		'File::FDpasser' => 0.09,
		'Digest::MD5' => 0,
	}, 
	'clean' => {FILES => "t/STDERR t/fdkeeper.sock"},
) ;
