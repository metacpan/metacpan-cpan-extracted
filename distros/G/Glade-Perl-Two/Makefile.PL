#
#   Makefile.PL for Glade-Perl-Two
#
require 5.000;
use ExtUtils::MakeMaker;
use strict;

my $prereq_pm = {
    'Gtk2'              => 0.01,
    'XML::Parser'       => 2.19,
    'Unicode::String'   => 2.04,
    };
    
#--------------------------------------
# Last of all generate the Makefile
WriteMakefile(
    'DISTNAME'      => 'Glade-Perl-Two',
    'NAME'          => 'Glade',
    'AUTHOR'        => 'Dermot Musgrove <dermot.musgrove@virgin.net>',
    'VERSION_FROM'  => 'Glade/Two/Run.pm',
    'EXE_FILES'     => [ 'bin/glade2perl-2' ],
    'clean'         => { FILES => '$(EXE_FILES)' },
    'dist'          => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'PREREQ_PM'     => $prereq_pm,
);

# Make it return 0 for shell
0;

# End of Makefile.PL
