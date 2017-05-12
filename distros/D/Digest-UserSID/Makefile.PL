use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Digest::UserSID',
    'VERSION_FROM' => 'UserSID.pm', # finds $VERSION
);
