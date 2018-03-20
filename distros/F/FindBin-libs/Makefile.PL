# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use 5.008;
use version;

use Module::FromPerlVer;
use ExtUtils::MakeMaker;

my $version = '2.17.6'; 
my $mm_v    = ExtUtils::MakeMaker->VERSION;

my @merge_spec
= do
{
    if( $mm_v < 6.46 )
    {
        ()
    }
    else
    {
        META_MERGE => 
        {
            'meta-spec' =>
            {
                version => 2
            },

            dynamic_config => 1,

            configure_requires =>
            {
                qw
                (
                    Module::FromPerlVer 0.002,
                )
            },
        }
    }
};

WriteMakefile
(
    qw
    (
        NAME            FindBin::libs
        LICENSE         perl
    ),
    VERSION         => version->parse( $version )->numify,
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

		qw
        (
            Cwd                 3.73
            Module::FromPerlVer 0.002

            Carp                0
            File::Spec          0
            File::Temp          0
            FindBin             0
            List::Util          0
            Test::More          0
            Symbol              0
            strict              0
        )
    },

    @merge_spec,
);

__END__
