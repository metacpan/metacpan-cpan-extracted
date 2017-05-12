use 5.010001;
use ExtUtils::MakeMaker;

# minimum required version of dependencies we need to build
our %build_reqs = (
    'keybinder' => '0.2.0',
);
our %PREREQ_PM = (
    'ExtUtils::Depends'   => '0.300',
    'ExtUtils::PkgConfig' => '1.000',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends '$PREREQ_PM{'ExtUtils::Depends'}';"
           . "use ExtUtils::PkgConfig '$PREREQ_PM{'ExtUtils::PkgConfig'}';"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%PREREQ_PM,
   );
   exit 1; # not reached
}

my %pkgcfg_kb;
eval {
    %pkgcfg_kb = ExtUtils::PkgConfig->find("keybinder >= $build_reqs{keybinder}"); 1;
} or do {
    warn $@;
    exit 0;
};

WriteMakefile(
    NAME              => 'Keybinder',
    VERSION_FROM      => 'lib/Keybinder.pm',
    LICENSE           => 'artistic_2',
    PREREQ_PM         => {
        "Gtk2" => "1.247",
    },
    ABSTRACT_FROM  => 'lib/Keybinder.pm',
    AUTHOR         => 'Ivan Baidakou <dmol@cpan.org>',
    META_MERGE   => {
        requires  => {perl => '5.010001'},
        resources => {
            homepage    => 'http://github.com/basiliscos/p5-Keybinder',
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository  => 'http://github.com/basiliscos/p5-Keybinder',
            bugtracker  => 'http://github.com/basiliscos/p5-Keybinder/issues'
        },
        no_index => {directory => ['t']}
    },

    CCFLAGS           => $pkgcfg_kb{cflags},
    LIBS              => $pkgcfg_kb{libs},
    # DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    # INC               => '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    test => {TESTS => 't/*.t t/*/*.t'},
);
