use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finnigan',
    VERSION_FROM      => 'lib/Finnigan.pm', # finds $VERSION
    PREREQ_PM         => {
                          Carp => '1.08',
                          Data::Hexdumper => '2.01',
                          Data::UUID => '1.06',
                          Digest::SHA1 => '2.13',
                          Encode => '2.23',
                          File::Basename => '2.77',
                          Getopt::Declare => '1.13',
                          Getopt::Long => '2.37',
                          MIME::Base64 => '3.07',
                          Module::Find => '0.06',
                          Scalar::Util => '1.21',
                          XML::Generator => '1.04',
                          Tie::IxHash => '1.21',
                         },
    EXE_FILES         => [
                          'bin/uf-header',
                          'bin/uf-seqrow',
                          'bin/uf-casinfo',
                          'bin/uf-rfi',
                          'bin/uf-meth',
                          'bin/uf-scan',
                          'bin/uf-scan-light',
                          'bin/uf-runheader',
                          'bin/uf-instrument',
                          'bin/uf-log',
                          'bin/uf-error',
                          'bin/uf-segments',
                          'bin/uf-params',
                          'bin/uf-tune',
                          'bin/uf-index',
                          'bin/uf-trailer',
                          'bin/uf-mzxml',
                          'bin/uf-mzml',
                          'bin/mzxml-unpack',
                          'bin/mzxml-scan',
                         ],
    'LICENSE'         => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finnigan.pm', # retrieve abstract from module
       AUTHOR         => 'Gene Selkov <selkovjr@gmail.com>') : ()),
);
