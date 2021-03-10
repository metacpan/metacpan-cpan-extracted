# even the old version is guaranteed not to work
# with anything earlier than 5.008.

use 5.008;
use strict;
use version;

use ExtUtils::MakeMaker;

use Cwd             qw( getcwd      );
use File::Basename  qw( basename    );
use List::Util      qw( first       );

########################################################################
# deal with MakeMaker version.

my $mm_v    = ExtUtils::MakeMaker->VERSION;

my @config_requires
= $mm_v < 6.52
? ()
:   (
        CONFIGURE_REQUIRES =>
        {
            (
                map
                {
                    (
                        $_->[0],
                        version->parse( $_->[1] )->numify
                    )
                }
                (
                    [ qw( Cwd                             v3.73 ) ],
                    [ qw( File::Copy::Recursive::Reduced  v0.6  ) ],
                    [ qw( List::Util                      v1.46 ) ],
                )
            ),
            (
                map
                {
                    ( $_ => 0 )
                }
                qw
                (
                    strict
                    version
                    ExtUtils::MakeMaker
                    File::Basename
                    List::Util
                )
            ),
        }
    )
;

########################################################################
# install the correct version of libs.pm based on the running perl
# version. after that take the version from whatever's on the disk.
########################################################################

my $perl_v
= eval
{
    my $text    = sprintf '%vd' => $^V;

    print "\n# Parsing perl version: '$text'\n";

    version->parse( $text )->numify
}
or die "Un-parsable perl version: '$^V'";

print "\n# Running perl version: '$perl_v'\n";

my @v_dirz = glob "./version/*"
or die "Unable to locate version dirs: './version/*'";

my $found
= first
{
    $_->[0] <= $perl_v
}
sort
{
    # desc sort allows first dir <= $^V.

    $b->[0] <=> $a->[0]
}
map
{
    my $base    = basename $_;
    my $ver
    = eval
    {
        version->parse( $base )->numify
    };

    if( $ver )
    {
        [ $ver => $_ ]
    }
    else
    {
        print "Ignoring Un-parsable version: '$base' ($_), $@";
        ()
    }
}
@v_dirz
or
die "Unable to install with Perl version '$perl_v'";

my $src_d   = $found->[ -1 ];

print "\n# Version directory: $src_d <= $perl_v.\n";

# don't validate the count, just give up
# if it fails entirely.
#
# note that the behavior is returning undef on failure, 
# but in this case we know there should be files copied 
# so any false value is fatal.

require File::Copy::Recursive::Reduced;

File::Copy::Recursive::Reduced::dircopy( $src_d => '.' )
or die "Failed copy from $src_d.\n";

########################################################################
# reasonable question as to whether all of the version/* files represent
# the same version of code: the older ones have minimal bug maintainence
# only and it doesn't seem reasonable to up their version number if they
# don't change.
########################################################################

WriteMakefile
(
    qw
    (
        NAME            FindBin::libs
        LICENSE         perl
    ),
    VERSION         => 'v2.21.0',
    AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        'Cwd'
        => version->parse( 'v3.73'  )->numify,

        'File::Copy::Recursive::Reduced'
        => version->parse( 'v0.002' )->numify,

        # standard distro, particular versions
        # are unlikely to cause pain.

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

    @config_requires,
);

__END__
