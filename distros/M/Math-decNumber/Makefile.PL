use 5.010000;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Copy;

my $EUMM_VERSION = $ExtUtils::MakeMaker::VERSION;
$EUMM_VERSION =~ s/_//g;

copy "./inc/decContext.c", "_decContext.c" or die $!;
copy "./inc/decNumber.c", "_decNumber.c" or die $!;

my $define;

if ( $Config{byteorder} eq "1234" or $Config{byteorder} eq "12345678" ) {
  $define = '-DDECLITEND=1 ';         #  platform is little-endian
}
else {
  $define = '-DDECLITEND=0 ';         #  platform is big-endian
}

$define .= '-DDECUSE64=1 ';           # 64-bit integers used
$define .= '-DDECSUBSET=0 ';          # always subset enabled
$define .= '-DDECEXTFLAG=1 ';         # extended set of status flags
$define .= '-DDECPRINT=1 ';           # calls to printf are permitted

# $define .= '-DDECCHECK=1 -DDECALLOC=1 -DDECVERB=1 '; # for debugging

WriteMakefile(
    NAME              => 'Math::decNumber',
    VERSION_FROM      => 'lib/Math/decNumber.pm', # finds $VERSION
    ( $EUMM_VERSION >= 6.48 ? ( MIN_PERL_VERSION  => '5.10.0') : () ),
                                # problem with signal with previous version of Perl
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/decNumber.pod', # retrieve abstract from module
       AUTHOR         => 'J-L Morel <jl_morel@bribes.org>') : ()),
    ( $EUMM_VERSION >= 6.31 ? ( LICENSE => 'open_source') : () ),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => $define, # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I./inc', # e.g., '-I. -I/usr/include/other'
    # add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    clean   => { FILES => 'log.txt _dec*' },
);
