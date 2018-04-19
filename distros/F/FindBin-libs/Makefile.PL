# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use 5.008;
use version;

#use Module::FromPerlVer;
use ExtUtils::MakeMaker;

use Cwd             qw( getcwd      );
use File::Basename  qw( basename    );
use List::Util      qw( first       );

use File::Copy::Recursive::Reduced  qw( dircopy );

my $version = version->parse( '2.17.12' )->numify;
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

my $perl_v
= eval
{
    ref $^V
    ? version->parse( $^V )->numify
    : sprintf '%vd' => $^V
}
or die "Un-parsable perl version: '$^V'";

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
        print "Ignoring Un-parsable version: '$base'";
        ()
    }
}
glob "version/*"
or
die "Unable to install with Perl version '$perl_v'";

my $src_d   = $found->[1];

print "# Version directory: $src_d ($perl_v).";

# don't validate the count, just give up
# if it fails entirely. not that the behavior
# is returning undef on failure, but in this
# case we know there should be files copied so
# any false value is fatal.

dircopy  $src_d => '.'
or die "Failed copy from $src_d.\n";

# at this point there is a module, and whatever else, in place
# for the perl version.

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
#        Module::FromPerlVer     => version->parse( '0.9.5' )->numify,
        File::Copy::Recursive::Reduced
        => version->parse( '0.002' )->numify,

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
