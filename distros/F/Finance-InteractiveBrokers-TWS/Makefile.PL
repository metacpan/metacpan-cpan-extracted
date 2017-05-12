use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::InteractiveBrokers::TWS',
    AUTHOR              => 'Jay Strauss <tws_at_heyjay.com>',
    VERSION_FROM        => 'lib/Finance/InteractiveBrokers/TWS.pm',
    ABSTRACT_FROM       => 'lib/Finance/InteractiveBrokers/TWS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'File::Spec'        => 0,
        'Inline'            => 0,
        'Inline::Java'      => .5092,
        'Class::InsideOut'  => 0,
        'Test::More'        => 0,
        'version'           => 0,
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-InteractiveBrokers-TWS-*' },
);

use Config;
use File::Spec;

#my $comp_dir = $Config{sitelib};

#foreach (qw/Finance InteractiveBrokers TWS _Inline/) {
#
#    $comp_dir = File::Spec->catfile($comp_dir, $_);
#    mkdir $comp_dir;
#}

#   Need to fix this to look for TWS_HOST parm
# 
# Grab the J2SDK argument
#my $jdk_dir = '' ;
#for (my $i = 0 ; $i < scalar(@ARGV) ; $i++){
#    if ($ARGV[$i] =~ /^J2SDK=(.+)$/){
#        $jdk_dir = $1 ;
#        splice(@ARGV, $i, 1) ;
#        $i-- ;
#    }
#}
#if (! $jdk_dir){
#    my $def_pl = File::Spec->catfile('Java', 'default_j2sdk.pl') ;
#    if (-e $def_pl){
#        require File::Spec->catfile('Java', 'default_j2sdk.pl') ;
#        $jdk_dir = Inline::Java::get_default_j2sdk() ;
#    }
#    else{
#        print <<NO_J2SDK;
#A Java 2 SDK is required to install and use Inline::Java. Please 
#specify your Java 2 SDK installation directory using the J2SDK 
#option to Makefile.PL as such:
#
#    perl Makefile.PL J2SDK=/path/to/your/j2sdk/installation
#NO_J2SDK
#        exit(1) ;
#    }
#}
#elsif (! -d $jdk_dir){
#    print <<BAD_J2SDK;
#Java 2 SDK installation directory '$jdk_dir' does not exist.
#BAD_J2SDK
#    exit(1) ;
#}
