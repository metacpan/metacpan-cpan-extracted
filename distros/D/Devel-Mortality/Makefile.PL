use 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Devel::Mortality',
    VERSION_FROM        => 'lib/Devel/Mortality.pm', # finds $VERSION
    PREREQ_PM           => {
        File::Spec          => 0,
        File::Basename      => 0,
        Test::More          => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'lib/Devel/Mortality.pm', # retrieve abstract from module
       AUTHOR           => 'Claes Jakobsson <claesjac@cpan.org>') : ()),
    LICENSE             => "mit",
    INC                 => '-I.', # e.g., '-I. -I/usr/include/other'
);

package MY;

use File::Spec;

sub post_initialize {
    my($self) = shift;

    for (qw(Devel_Mortality.h)) {
        $self->{PM}->{$_} = File::Spec->catfile($self->{INST_ARCHAUTODIR}, $_);
    }

    return '';
}
