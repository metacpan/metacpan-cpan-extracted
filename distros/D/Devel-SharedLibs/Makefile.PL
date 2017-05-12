use v5.20;
use ExtUtils::MakeMaker;

my $VERSION = 'v0.3.3';
$VERSION    = eval "$VERSION";

WriteMakefile
(
    NAME            => 'Devel::SharedLibs',
    VERSION			=> $VERSION,
    ABSTRACT_FROM   => 'lib/Devel/SharedLibs.pm',
    PREREQ_PM =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

        qw
        (
            autodie			0
            IO::File		0

            FindBin::libs	0
            List::MoreUtils	0
        )
    }
);
