use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'GMail::IMAPD',
    'VERSION_FROM' => 'lib/GMail/IMAPD.pm',
    'PREREQ_PM'    => {
                HTTP::Cookies => undef,
                LWP::UserAgent=> undef,
                HTTP::Request => undef,
                Crypt::SSLeay => undef,
    },
    'MAN3PODS'     => { 
          'lib/GMail/IMAPD.pm'=> '$(INST_MAN3DIR)/GMail::IMAPD.3' 
    },

    'dist'         => {
                'SUFFIX'      => ".gz",
                'COMPRESS'    => "gzip -9vf",
    },
);


