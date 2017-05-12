use ExtUtils::MakeMaker;

# 5.6.0 required at the moment, might backport further later
use 5.006;

# check that dprofpp is available - we need it for "make test"
`dprofpp -V` or die <<END;

**************************************************************************
*                                                                        *
* Unable to run "dprofpp", the profiler frontend for Devel::DProf and    *
* Devel::Profiler.  This program is usually installed with Perl.  Please *
* ensure that "dprofpp" is in your PATH before building this module.     *
*                                                                        *
**************************************************************************

END

# write the makefile
WriteMakefile(
    NAME		=> 'Devel::Profiler',
    VERSION_FROM	=> 'lib/Devel/Profiler.pm',
    PREREQ_PM		=> { B            => 0, 
                             Time::HiRes  => 0, 
                             File::Path   => 0,
                             Test::More   => 0,
                           },
    ABSTRACT_FROM       => 'lib/Devel/Profiler.pm',
    AUTHOR              => 'Sam Tregar <sam@tregar.com>',
);
