use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Jabber::Connection',
    'VERSION_FROM' => 'lib/Jabber/Connection.pm', # finds $VERSION
    'PREREQ_PM'    => {
                        XML::Parser      => '2.29',
                        Digest::SHA1     => '1.03',
                        Scalar::Util     => '1.07',
                       },
);
