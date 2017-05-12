#
#   Finance::InteractiveBrokers::SWIG - Perl makefile maker
#
#   Copyright (c) 2010-2014 Jason McManus
#

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec::Functions qw( catdir catfile );
use Config;
use Cwd;
use Carp qw( carp croak confess );
$|=1;

use vars qw( $VERSION $TRUE $FALSE );
BEGIN {
    $VERSION = '0.13';
}

*TRUE    = \1;
*FALSE   = \0;

my $SWIG_filename = 'swig';
$SWIG_filename .= '.exe' if( $^O eq 'MSWin32' );

my $ALIEN_SWIG = 'Alien::SWIG';
my $min_SWIG_version = '1.3.33';
my( $SWIG_PATH, $SWIG_INCLUDES ) = ( '', '' );

my @broken_compilers = (
	'LLVM build 2335',
);

# Check for F::IB::API >0.04
my $fibapi_outdated = $TRUE;
eval {
    require Finance::InteractiveBrokers::API;
    $fibapi_outdated = ($Finance::InteractiveBrokers::API::VERSION < 0.04);
};
croak( '*' x 76 . "\n" .
       '  Cannot find Finance::InteractiveBrokers::API >= 0.04, required for this' .
       " build.\n  Please install it from CPAN before continuing.\n" .
       '*' x 76 . "\n " )
    if( $@ or $fibapi_outdated );

##########################################################################
### Collect some configuration information from the user
##########################################################################

print <<"EOM";

==========================================================================
      Welcome to the Perl Finance::InteractiveBrokers::SWIG package
==========================================================================

We need to gather some information before continuing the build process.

This module is very complex, and thus you should consult the documentation
before using it.

Press ENTER at any prompt to accept the [default] value.
EOM


###########################
### Find the swig binary
###########################

print <<"EOM";

---------------------------------------
               SWIG:
---------------------------------------

This build requires SWIG (the Simplified Wrapper and Interface Generator)
for building the connection to the IB C++ libraries.

If it is not installed, you can get it at: http://www.swig.org/

EOM

print " * Looking for 'swig' in your PATH... ";
my $ver_ok;
my $swig_bin = find_bin( $SWIG_filename );
if( $swig_bin ) {
    print $swig_bin, "\n\n";
    $ver_ok = check_swig_version( $swig_bin );
} else {
    print "Nope.\n\n";
}

unless( $swig_bin and $ver_ok )
{
    print " * Trying $ALIEN_SWIG... ";
    eval "require $ALIEN_SWIG;";
    if( $@ ) {
        print "Nope.\n\n";
    } else {
        my $aswig = $ALIEN_SWIG->new();
        print "Found it!  $ALIEN_SWIG ", $ALIEN_SWIG->VERSION, "\n\n";
        $swig_bin = $aswig->executable();
        $ver_ok = check_swig_version( $swig_bin );
        $SWIG_INCLUDES = $aswig->includes()
            if( $ver_ok );
    }
}

# Find and verify if location of SWIG binary
$swig_bin  = '' unless( defined( $swig_bin ) );
$SWIG_PATH = prompt( "Enter/change the full path to your 'swig' program:\n>",
                        $ver_ok ? $swig_bin : undef );

print "\n";
unless( ( ( $SWIG_PATH ) and ( $SWIG_PATH eq $swig_bin ) ) or
        ( $ver_ok = check_swig_version( $SWIG_PATH ) ) )
{
    print "No good I'm afraid.  ";
    print "We can try to get $ALIEN_SWIG from CPAN.\n\n";
    my $get_it = prompt( "Download $ALIEN_SWIG from CPAN?", 'yes' );
    ( $SWIG_PATH, $SWIG_INCLUDES ) = get_aswig_from_cpan()
        if( $get_it =~ /y/ );

    die "A working SWIG >= $min_SWIG_version is needed.  Cannot continue.\n "
        unless( $SWIG_PATH );

    print "\n*********************************************************************\n";
    print "  Welcome back to the Finance::InteraactiveBrokers::SWIG installer.\n";
    print "SWIG ", _get_swig_ver( $SWIG_PATH ),
          " is now installed and working properly.\n";
    print "*********************************************************************\n";
}

###########################
### Find the API files
###########################

print <<"EOM";

---------------------------------------
  InteractiveBrokers API Source Code:
---------------------------------------

To build this module, you must have the InteractiveBrokers API source code
somewhere on your system.

We're going to try to locate it.

EOM

my( $LIBPATH, $IB_BUILD_PATH );

print " * Checking the IB_LIBRARY_PATH and IB_BUILD_PATH envvars... ";

if( ( $LIBPATH = found_api( $ENV{IB_BUILD_PATH} ) ) or
    ( $LIBPATH = found_api( $ENV{IB_LIBRARY_PATH} ) ) )
{
    print "Found it!\n";
}
else
{
    # Next, try to find it via ibapi-config
    print "Nope.\n\n * Trying 'ibapi-config --path'... ";
    undef $LIBPATH;
    if( my $ibapiconfig = find_bin( 'ibapi-config' ) )
    {
        $LIBPATH = `$ibapiconfig --path`;
        chomp $LIBPATH;
    }
    if( found_api( $LIBPATH ) )
    {
        print "Found it!\n";
    }
    else
    {
        # Next, try to find it via Alien::InteractiveBrokers
        print "Nope.\n\n * Checking if we can use Alien::InteractiveBrokers... ";
        undef $LIBPATH;
        eval {
            require Alien::InteractiveBrokers;
            $LIBPATH = Alien::InteractiveBrokers::path();
        };
        if( found_api( $LIBPATH ) )
        {
            print "Yep!\n";
        }
        else
        {
            print "Nope.\n";
            undef $LIBPATH;
        }
    }
}

if( $LIBPATH )
{
    my $api_ver_num = get_api_version( $LIBPATH );
    print <<"EOM";

We have found the IB API source (version $api_ver_num) in:
  $LIBPATH

You may change locations now if you need to (otherwise just press ENTER).

EOM
} else { print "\n" }

my $NEWLIBPATH = prompt( "Enter or confirm the path to the IB source code:\n", 
                         $LIBPATH );

# http://www.cpantesters.org/cpan/report/9130b39c-2c49-11e0-b43e-04429eb006f9
# FIXME $LIBPATH can be undef here.
if( ( $NEWLIBPATH ne $LIBPATH ) and
    ( ! found_api( $NEWLIBPATH ) ) )
{
    print <<"EOM";

Could not find the IB source code in $NEWLIBPATH !
This package requires the header files provided by InteractiveBrokers.
Please read this module's documentation for more information.

EOM
    die "Cannot continue without IB source code..";
}
else
{
    # Check if we can use that API version
    can_use_api_version( get_api_version( $NEWLIBPATH ) );

    print <<"EOM";

IB_BUILD_PATH has been set to '$NEWLIBPATH'.

EOM
    # Now set the env to whatever they entered
    $IB_BUILD_PATH = $NEWLIBPATH
}


##########################################################################
### Build the Makefile
##########################################################################

#$Verbose = 1;
WriteMakefile(
    NAME                => 'Finance::InteractiveBrokers::SWIG',
    AUTHOR              => q{Jason McManus <infidel AT cpan.org>},
    VERSION_FROM        => 'lib/Finance/InteractiveBrokers/SWIG.pm',
    ABSTRACT_FROM       => 'lib/Finance/InteractiveBrokers/SWIG.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
		# For done_testing()
        'Test::More'                        => '0.88',
        'Finance::InteractiveBrokers::API'  => '0.04',
    },
    BUILD_REQUIRES => {
        'Finance::InteractiveBrokers::API'  => '0.02_03',
        # Catch CPANTesters and install the IB libs
        # XXX: Nah, this won't work, already too late for 'make dist'
        #$ENV{AUTOMATED_TESTING} ? (
        #   'Alien::InteractiveBrokers'     => 0,
        #) : (),
        'Alien::InteractiveBrokers'         => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'               => 0,
        'Finance::InteractiveBrokers::API'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES =>
      'Finance-InteractiveBrokers-SWIG-* *.old IBAPI.pm IBAPI.so IBAPI.bundle IBAPI_wrap.cxx'
    },
    test => {
		TESTS => 't/*.t t/regression/*.t'
	},
);

print <<"EOM";

You may now continue the build by typing:

    make
    make test
    make install

Please consult the documentation via:

    perldoc Finance::InteractiveBrokers::SWIG

EOM

##########################################################################
### Utility subs
##########################################################################

# Retrieve a var from the ginormous %Config hash
sub get_config_var
{
    my $var = shift;

    return exists( $Config{$var} )
             ? $Config{$var}
             : undef;
}

# Find the specified $fname in all dirs in $ENV{PATH}
sub find_bin
{
    my( $fname ) = @_;

    my $path_sep = get_config_var( 'path_sep' ) || ':';

    my @bindirs = split( $path_sep, $ENV{PATH} );

    my $binpath = '';
    for my $dir ( @bindirs )
    {
        my $testpath = catfile( $dir, $fname );
        $binpath = $testpath, last
            if( -f $testpath );
    }

    return( $binpath );
}

# Get the SWIG version number from the executable
sub check_swig_version
{
    my( $swig ) = @_;

    return( $FALSE )
        unless( -x $swig );

    print "Checking SWIG version... ";

    my $ver = _get_swig_ver( $swig );

    unless( defined( $ver ) ) {
        print "I don't think that '$swig' is actually SWIG.\n\n";
		return( $FALSE );
    }

    print $ver, "\n\n";

    my $ok = $ver ge $min_SWIG_version;
    printf "SWIG $ver is %srecent enough.%s\n\n",
           $ok ? '' : 'NOT ',
           $ok ? '  Great!' : '  You need a newer version.';

    return( $ver ge $min_SWIG_version ? $TRUE : $FALSE );
}

# Low-level, just execute and grab the ver.
sub _get_swig_ver
{
    my( $path ) = @_;

    my $output = eval { qx( $path -version ) };
    return if( $@ or ! defined( $output ) );
    my( $ver ) = ( $output =~ m/SWIG Version (.*)/m );
    chomp $ver if( defined( $ver ) );

    return( $ver );
}

# Check a few needed files in the IBJts path to see if it's sane
sub found_api
{
    my( $path ) = @_;
    return unless( $path );

    my $result = undef;
    if( -e $path )
    {
        # Check some files to make sure we're kinda complete
        for my $file (
            'cpp',
            catdir(  'cpp', 'Shared' ),
            catfile( 'cpp', 'Shared', 'EWrapper.h' ),
            catdir(  'cpp', 'PosixSocketClient' ),
            catfile( 'cpp', 'PosixSocketClient', 'EClientSocketBase.cpp' ),
            catfile( 'cpp', 'PosixSocketClient', 'EPosixClientSocket.cpp' ) )
        {
            return unless( -e catfile( $path, $file ) );
        }
        $result = $path;
    }

    return $result;
}

# Get the IB API version number from the source code distribution
sub get_api_version
{
    my( $path ) = @_;
    return unless( $path );

    my $verfile = catfile( $path, 'API_VersionNum.txt' );
    open my $fd, '<', $verfile or
        return;
    my $contents = do { local $/; <$fd> };
    close( $fd );

    my( $vernum ) = ( $contents =~ m/API_Version=([\d.]*)/mi );

    return( $vernum );
}

# Check with F::IB::API to see if we can work with $VERSION
sub can_use_api_version
{
    my( $api_version ) = @_;

    require Finance::InteractiveBrokers::API;
    my @ok_vers = Finance::InteractiveBrokers::API->api_versions();

    die "\nSorry, this module cannot use found API version $api_version\n" .
        "Usable vers are: @ok_vers\n "
        unless( grep { $api_version } @ok_vers );

    print "\nGood, API version $api_version is usable with this module.\n";

    return;
}

# Get and install Alien::SWIG from CPAN, returning the executable and includes
sub get_aswig_from_cpan
{
	my $origpath = getcwd();
    eval "use CPAN;";
    carp "Cannot 'use CPAN': $@" and return
        if( $@ );

    CPAN->import;
    CPAN::HandleConfig->load();
    CPAN::Shell::setup_output();
    CPAN::Index->reload;

    my $mod = CPAN::Shell->expand( 'Module', $ALIEN_SWIG );
    carp "Couldn't find $ALIEN_SWIG on CPAN." and return
        unless( defined( $mod ) );

    if( ! $mod->uptodate )
    {
        $mod->install();
        carp "Couldn't install/update $ALIEN_SWIG from CPAN." and return
            unless( $mod->uptodate );
    }

	eval "require $ALIEN_SWIG;";
    carp "Couldn't require $ALIEN_SWIG after CPAN install." and return
		if( $@ );

    my $aswig = $ALIEN_SWIG->new();

	# I think something funky goes on with paths with the above.
	chdir( $origpath );

    return( $aswig->executable(), scalar $aswig->includes() );
}

sub get_cxx_fix
{
	my $quiet = shift;
	return unless $^O eq 'darwin';
	my $cxx_verstring = `g++ --version`;
	my( $cxx_version ) = $cxx_verstring =~ m#^(\S+)#;

	return unless( grep { /\Q$cxx_version\E/ } @broken_compilers );
	unless( $quiet )
	{
		print <<"EOWHINE";

*************************************************************************

	!!! BROKEN COMPILER !!!

	Your C++ compiler ($cxx_version) is BROKEN.

	The g++ on Darwin with LLVM build 2335 produces invalid output.

	You should upgrade to the latest OS-X developer tools.

EOWHINE
	}

	my $gpp = find_bin( 'g++-4.2' );

	if( -x $gpp ) {
		print <<"EOWHINE";

	Found a possible replacement: $gpp

	Will try to continue using that.

*************************************************************************
EOWHINE
		return "CC=$gpp";
	} else {
		print <<"EOWHINE";
	No suitable replacement was found.  Aborting.

*************************************************************************
EOWHINE
		die "BROKEN COMPILER; cannot continue.";
	}

	return;
}


##########################################################################
### Tweak the Makefile output
##########################################################################

package MY;

use File::Spec::Functions qw( catdir catfile );

sub top_targets {
    my $postamble;

    # I don't think we can get around much of this with File::Spec->catfile
    my $S        = $^O eq 'MSWin32' ? '\\' : '/';
    my $base_dir = catdir( 'Finance', 'InteractiveBrokers', 'SWIG');
    my $lib_dir  = "\$(INST_LIB)${S}$base_dir";
    my $auto_dir = "\$(INST_ARCHLIB)${S}" . catdir( 'auto', $base_dir, 'IBAPI');
    my $perm_dir = $ExtUtils::MakeMaker::VERSION >= 6.52 ? '$(PERM_DIR)' :'755';
    my $api_ver  = main::get_api_version( $IB_BUILD_PATH );
	my $CXX_FIX  = main::get_cxx_fix() || '';
	my $api_int  = $api_ver;
	$api_int =~ s/\.//;
    my $build_time = time();

    # Build the Makefile postamble
    $postamble = <<"POSTAMBLE";
all :: pure_all manifypods
\t\$(NOECHO) \$(NOOP)

pure_all :: config pm_to_blib swig
\t\$(NOECHO) \$(NOOP)

subdirs :: \$(MYEXTLIB)
\t\$(NOECHO) \$(NOOP)

config :: \$(FIRST_MAKEFILE) blibdirs
\t\$(NOECHO) \$(NOOP)

help :
\tperldoc ExtUtils::MakeMaker

swig :: IBAPI.\$(DLEXT)

IBAPI.\$(DLEXT) :: IBAPI.i IBAPI.cxx IBAPI.h
\t$CXX_FIX\$(MAKE) -ef Makefile.swig "SWIG=$SWIG_PATH" "SWIG_INCL=$SWIG_INCLUDES" "IB_BUILD_PATH=$IB_BUILD_PATH" "IB_API_VERSION=$api_ver" "BUILD_TIME=$build_time" "IB_PI_INTVER=$api_int"
\t\$(MKPATH) "$lib_dir" "$auto_dir"
\t\$(CHMOD) $perm_dir "$auto_dir"
\t\$(CP) IBAPI.pm "$lib_dir"${S}
\t\$(CP) IBAPI.\$(DLEXT) "$auto_dir"${S}

clean ::
\t\$(MAKE) -ef Makefile.swig clean

POSTAMBLE

    return $postamble;
}

# END
