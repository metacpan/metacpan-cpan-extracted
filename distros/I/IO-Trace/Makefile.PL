#!perl
use 5.006000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'IO::Trace',
    VERSION_FROM      => 'lib/IO/Trace.pm',
    PREREQ_PM         => {
        # Please only use stock core modules:
        'Config'        => 0,
        'Test::More'    => 0,
        'Getopt::Long'  => 2.36, # For GetOptionsFromArray
        'IO::File'      => 0,
        'IO::Handle'    => 0,
        'IO::Select'    => 0,
        'IPC::Open3'    => 0,
        'File::Which'   => 0,
    },
    ABSTRACT_FROM     => 'lib/IO/Trace.pm', # retrieve abstract from module
    AUTHOR            => 'Rob Brown <bbb@cpan.org>',
    LICENSE           => 'artistic_2',
    EXE_FILES         => [ 'bin/iotrace' ],
);

package MY;
sub test {
    require Config;
    return "FULLPERLRUN = PATH=\$(INST_SCRIPT)$Config::Config{path_sep}\$(PATH) $_[0]->{FULLPERLRUN}\n".shift->SUPER::test(@_);
}
