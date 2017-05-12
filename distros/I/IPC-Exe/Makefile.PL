use 5.008_008;
use ExtUtils::MakeMaker;

die("OS unsupported\n") if $^O =~ /^(?:VMS|dos|MacOS|riscos|amigaos|vmesa)$/;

WriteMakefile(
    NAME           => "IPC::Exe",
    VERSION_FROM   => "lib/IPC/Exe.pm",
    ABSTRACT_FROM  => "lib/IPC/Exe.pm",
    LICENSE        => "perl",
    AUTHOR         => "Gerald Lai <glai at cpan dot org>",

    ## DEPENDENCIES ##
    PREREQ_PM => {
        "Carp"         => 0,
        "Data::Dumper" => 0,
        "File::Spec"   => 0,
        "Scalar::Util" => 0,
        "Symbol"       => 0,
        "Time::HiRes"  => 0,
    },
);
