use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Digest::CMAC',
    VERSION_FROM      => 'lib/Digest/CMAC.pm',
    PREREQ_PM         => {
        'MIME::Base64' => 0,
        'Crypt::Rijndael' => 0,
		'Test::More' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Digest/CMAC.pm',
       AUTHOR         => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
);
