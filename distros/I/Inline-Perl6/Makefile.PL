use 5.018000;
use Config;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $install_cmd = q{perl6-m -e 'say $*EXECUTABLE.dirname.Str.subst(rx{\/<-[\/]>+$}, "")'};
my $install = qx{$install_cmd};
chomp $install;
say $install;

my $inc = join(' ',
    map { "-I$install/include/$_" }
    qw(moar dynasm dyncall libatomic_ops libtommath libuv linenoise sha1 tinymt)
);

WriteMakefile(
    NAME              => 'Inline::Perl6',
    VERSION_FROM      => 'lib/Inline/Perl6.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Inline/Perl6.pm', # retrieve abstract from module
    AUTHOR            => 'Stefan Seifert <nine@(none)>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => ["-L$install/lib -lmoar"], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $inc, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

open my $header, '>', 'Perl6.h';
print { $header } qq{#define PERL6_INSTALL_PATH "$install"};
close $header;
