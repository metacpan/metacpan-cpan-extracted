use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'JPEG::JFIF',
    'VERSION_FROM' => 'JFIF.pm',
    'PREREQ_PM'	=> {},
    ($] >= 5.005 ?
	(AUTHOR	=> 'Marcin Krzyzanowski <krzak\@cpan.org>') : ()),
);