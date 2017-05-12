use ExtUtils::MakeMaker;

#use File::Spec;
#my $DicomPack_pm = File::Spec->catfile('lib', 'DicomPack', 'IO', 'DicomReader.pm');

WriteMakefile(
	NAME => "DicomPack",
	VERSION => '0.95',
	ABSTRACT => 'Read/Write/Create Dicom files',
	AUTHOR => 'Baoshe Zhang <bzhang@vcu.edu>',
	LICENSE => 'perl',
);

