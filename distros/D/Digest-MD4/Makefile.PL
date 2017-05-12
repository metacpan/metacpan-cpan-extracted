#!perl -w

BEGIN { require 5.004 }
use strict;
use ExtUtils::MakeMaker;
use Config qw(%Config);

my @extra;

if ($^O eq 'VMS') {
    if (defined($Config{ccname})) {
        if (grep(/VMS_VAX/, @INC) && ($Config{ccname} eq 'DEC')) {
            # VAX compiler optimizer even as late as v6.4 gets stuck
            push(@extra, OPTIMIZE => "/Optimize=(NODISJOINT)");
        }
    }
}

push(@extra, 'INSTALLDIRS'  => 'perl') if $] >= 5.008;

WriteMakefile(
    'NAME'	   => 'Digest::MD4',
    'VERSION_FROM' => 'MD4.pm',
    'PREREQ_PM'    => { 'File::Spec' => 0 },
    @extra,
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);


