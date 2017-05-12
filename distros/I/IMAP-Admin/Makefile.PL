use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IMAP::Admin',
    'VERSION_FROM' => 'Admin.pm', # finds $VERSION
);
