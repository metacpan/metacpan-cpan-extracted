######################################################################
# Makefile.PL for File::Tail::FAM
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'File::Tail::FAM',
    'VERSION_FROM' => 'lib/File/Tail/FAM.pm', # finds $VERSION
    'PREREQ_PM'    => {
        SGI::FAM        => 1.002,
        Log::Log4perl   => 1.00,
        Sysadm::Install => 0.17,
        File::Temp      => 0.16,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/File/Tail/FAM.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
