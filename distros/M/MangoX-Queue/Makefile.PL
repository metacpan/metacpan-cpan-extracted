#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2014 Ian Kent                                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   } # Everyone else
    if ($@);
}

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    'NAME'          => 'MangoX::Queue',
    'VERSION_FROM'  => 'lib/MangoX/Queue.pm',
    'ABSTRACT_FROM' => 'lib/MangoX/Queue.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Ian Kent <iankent@cpan.org>',
    'PREREQ_PM'     => {
                           'Mango' => '0.43'
                       },
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
       ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
               ('CAPI'         => 'TRUE') : ()),
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/ian-kent/MangoX-Queue',
                },
                no_index => { directory => [ qw/t/ ] },
            },
        )
    ),
);

__END__
