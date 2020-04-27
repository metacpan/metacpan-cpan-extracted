use strict;
use warnings FATAL => 'all';

use 5.008001;
use ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

use ExtUtils::Depends;
my $pkg = ExtUtils::Depends->new('Devel::Declare', 'B::Hooks::OP::Check');

my %TEST_DEPS = (
    'B::Hooks::OP::Check' => '0.19',
    'Test::More' => '0.88',
    'Test::Requires' => '0',
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };

WriteMakefile(
    NAME => 'Devel::Declare',
    AUTHOR => 'Matt S Trout - <mst@shadowcat.co.uk> - original author',
    VERSION_FROM => 'lib/Devel/Declare.pm',
    MIN_PERL_VERSION => '5.008001',

    CONFIGURE_REQUIRES => {
        # minimum version that works on Win32+gcc
        'ExtUtils::Depends' => 0.302,

        # minimum version that depends on ExtUtils::Depends 0.302
        'B::Hooks::OP::Check' => '0.19',
    },

    PREREQ_PM => {
        'Scalar::Util' => 1.11, # set_prototype appeared in this version
        'B::Hooks::OP::Check' => '0.19',
        'B::Hooks::EndOfScope' => '0.05',
        'Sub::Name' => 0,
        ($mymeta_works ? () : (%TEST_DEPS)),
    },

    $mymeta_works ? (BUILD_REQUIRES => \%TEST_DEPS) : (),

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            # GitHub mirrors from Shadowcat. We list it so we can get pull requests.
            # The canonical repo is:
            # r/o: git://git.shadowcat.co.uk/p5sagit/Devel-Declare.git
            # r/w: p5sagit@git.shadowcat.co.uk:Devel-Declare.git
            # web: http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Devel-Declare.git
            repository => {
                url => 'https://github.com/p5sagit/Devel-Declare.git',
                web => 'https://github.com/p5sagit/Devel-Declare',
                type => 'git',
            },
            bugtracker => {
                mailto => 'bug-Devel-Declare@rt.cpan.org',
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Declare',
            },
        },
        x_contributors => [ # manually added, from git shortlog -e -s -n
            'Florian Ragwitz <rafl@debian.org>',
            'Matt S Trout <mst@shadowcat.co.uk>',
            'Karen Etheridge <ether@cpan.org>',
            'Zefram <zefram@fysh.org>',
            'Rhesa Rozendaal <rhesa@cpan.org>',
            'Ash Berlin <ash@cpan.org>',
            'Chia-liang Kao <clkao@clkao.org>',
            'Marcus Ramberg <marcus@nordaaker.com>',
            'Christopher Nehren <apeiron@cpan.org>',
            'Yuval Kogman <nothingmuch@woobling.org>',
            'Cory Watson <gphat@cpan.org>',
            'Alexandr Ciornii <alexchorny@gmail.com>',
            'Father Chrysostomos <sprout@cpan.org>',
            'Graham Knop <haarg@haarg.org>',
            'Matthew Horsfall <WolfSage@cpan.org>',
            'Nick Perez <nperez@cpan.org>',
            'Yanick Champoux <yanick@babyl.dyndns.org>',
        ],
        x_deprecated => 1,
    },

    C => [ 'Declare.c' ],
    XS => { 'Declare.xs' => 'Declare.c' },
    depend => { '$(OBJECT)' => 'stolen_chunk_of_toke.c' },

    $pkg->get_makefile_vars,
);

