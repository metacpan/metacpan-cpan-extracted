use 5.014000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# use Alien::Keystone to install Keystone safely just for Perl usage
my ($cflags, $ldflags, $define) = ();
if (eval { require Alien::Keystone; 1 }) {
    my $capstone = Alien::Keystone->new;
    $cflags = $capstone->cflags;
    $ldflags = $capstone->libs;
    $define = '-DCAPSTONE_FROM_PKGCONFIG';
} else {
    $cflags = `pkg-config --cflags keystone`;
    chomp $cflags if $cflags;
    $define = '-DKEYSTONE_FROM_PKGCONFIG' if $cflags;
    $ldflags = `pkg-config --libs keystone` || '-lkeystone';
    chomp $ldflags if $ldflags;
}

WriteMakefile(
    NAME              => 'Keystone',
    VERSION_FROM      => 'lib/Keystone.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Keystone.pm',
    AUTHOR            => 'Tosh <tosh@t0x0sh.org>',
    LICENSE           => 'GPL_3',
    LIBS              => [$ldflags],
    DEFINE            => $define || '',
    INC               => ($cflags || '') . ' -I.',
);
