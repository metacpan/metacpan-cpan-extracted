use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'Image::Shoehorn::Gallery',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/Image/Shoehorn/Gallery.pm',
	      'PREREQ_PM'    => {
				 Image::Shoehorn                   => '1.41',
				 Image::Size                       => '2.99',
				 Image::Info                       => '1.11',
				 Image::IPTCInfo                   => '1.6',
				 XML::SAX::Machines                => '0.34',
				 XML::Filter::XML_Directory_2XHTML => '1.3.1',
				 XML::Filter::XSLT                 => '0.03',
				 File::Basename                    => 0,
				 File::Copy                        => 0,
				 File::Path                        => 0,
				 DirHandle                         => 0,
				 IO::File                          => 0,
				 Carp                              => 0,
				 Digest::MD5                       => 0,

				 # for testing
				 Cwd                               => 0,
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
