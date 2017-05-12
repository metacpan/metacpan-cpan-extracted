# Makefile.PL - Device::Blkid::E2fsprogs
#
# Ray Mroz - mroz@cpan.org
# Copyright (C) 2011

use lib qw(inc);
use Devel::CheckLib qw/ :funcs :cflag_defs /
  ;    # See legend below for list of constants imported

use 5.008000;
use ExtUtils::MakeMaker;

# This next section is for Devel::CheckLib. I have hax0r3d this a tad. As well as checking
# for the existance of the blkid library, I am also going to make a call on the lib to get
# version data which is used to set a DEFINE for the C preprocessor. This will provide for
# dynamic version detection of libblkid in target systems. Dynamic version detection is
# optional and can be bypassed during the initial configuration when running this script.

# Version history of e2fsprogs libblkid
#
# Version legend
#
# Versions > 2.xx.x ( > 2000 ) is util-linux-ng (use the Device::Blkid library instead)
# Version 1.40 (140) - 25 API calls
# Version 1.38 (138) - 24 API calls
# Version 1.36 (136) - 21 API calls
# Version 1.34 (134) - 18 API calls - Dynamic version configuration is NOT supported for this version
# Version 1.33 (133) - 17 API calls - Dynamic version configuration is NOT supported for this version

# Note: The blkid_get_library_version() call modifies both its parameters (C strings) and
# returns an 'integerized' version based upon the real, string-based version. We use this
# below to determine and return a version type. All versions above 1.40.1 return a 4 digit
# integer and since the return type is only a single byte in width, we need to drop the
# last digit from versions > 2.00.0. Also note, the get version API calls first appeared
# in version 1.36 of libblkid so dynamic version detection is not supported in versions
# and as such, a baseline version 1.33 compliant target is built which will work with any
# version of the library.

# DEBUGGING and DEBUG builds
# To build a DEBUG build of this module, please refer below to the DEFINE argument to the
# WriteMakefile() function. In that function you will locate two DEFINE arguments, one of
# which is the default argument used in the normal construction of this package, the other
# which is commented out and which has an additional DEBUG related define added to it.
# Refer to the details in that section of the file to produce a DEBUG build if this is
# required.

# Constants imported from Devel::Checklib as 'cflag_defs' representing CFLAG defines which
# are passed as C compiler args when building the module.
# API_DEF_133 => qq/-D__API_1_33/,
# API_DEF_136 => qq/-D__API_1_33 -D__API_1_36/,
# API_DEF_138 => qq/-D__API_1_33 -D__API_1_36 -D__API_1_38/,
# API_DEF_140 => qq/-D__API_1_33 -D__API_1_36 -D__API_1_38 -D__API_1_40/,


my $api_define;

$api_define = check_blkid_version_or_exit(
    function => '
        const char *vers = NULL;
        const char *date = NULL;
        int vernum = 0;
        vernum = blkid_get_library_version(&vers, &date);
        if (vernum >= 2000)
            return(200); /* Childs return value only 1 byte wide */
        if (vernum >= 140)
            return(140);
        if (vernum >= 138)
            return(138);
        if (vernum >= 136)
            return(136); 
        return (-1); /* Default catch, something is borked */
        ',
    incpath => '/usr/include/blkid',
    lib     => 'blkid',
    header  => [ 'blkid.h', 'stdio.h', 'stdlib.h' ],
    blkid   => 1,
);

WriteMakefile(
    NAME         => 'Device::Blkid::E2fsprogs',
    VERSION_FROM => 'lib/Device/Blkid/E2fsprogs.pm',
    PREREQ_PM    => {
        'Exporter'      => '0',
        'Test::More'    => '0',
        'Test::Builder' => '0',
    },
    META_MERGE => {
        resources => {
            repository =>
              'git://github.com/raymroz/Device--Blkid--E2fsprogs.git',
        },
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/Device/Blkid/E2fsprogs.pm',
            AUTHOR        => 'Raymond Mroz <mroz@cpan.org>'
          )
        : ()
    ),
    LIBS          => ['-lblkid'],
    NEEDS_LINKING => 1,
    # NDEBUG is defined, assertion macros in xs file generate no code
    # Uncomment this and comment the following to generate a DEBUG build
    # which uses the assert macro. See assert(3) for more information. 
    # DEFINE    => "$api_define",
    DEFINE    => "-DNDEBUG $api_define",
    INC       => '-I.',
    LICENSE   => 'perl',
    EXE_FILES => [],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Device-Blkid-E2fsprogs-*' },
);
