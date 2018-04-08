# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use 5.008;
use version;

use Module::FromPerlVer;
use ExtUtils::MakeMaker;

my $version = version->parse( '2.17.10' )->numify;
my $mm_v    = ExtUtils::MakeMaker->VERSION;

#my @merge_spec
#= do
#{
#    if( $mm_v < 6.46 )
#    {
#        ()
#    }
#    else
#    {
#        META_MERGE => 
#        {
#            'meta-spec' =>
#            {
#                version => 2
#            },
#
#            dynamic_config => 1,
#
#            configure_requires =>
#            {
#                qw
#                (
#                    Module::FromPerlVer 0.004,
#                )
#            },
#        }
#    }
#};

WriteMakefile
(
    qw
    (
        NAME            FindBin::libs
        LICENSE         perl
    ),
    VERSION         => $version,
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

        Cwd                     => version->parse( '3.73'  )->numify,
        Module::FromPerlVer     => version->parse( '0.4.0' )->numify,
		qw
        (

            Carp                    0
            File::Basename          0
            File::Spec::Functions   0
            File::Temp              0
            FindBin                 0
            List::Util              0
            Test::More              0
            Symbol                  0
            strict                  0
            version                 0
        )
    },

    @merge_spec,
);

__END__
