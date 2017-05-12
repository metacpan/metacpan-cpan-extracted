use strict;
use 5.006;
use File::Copy;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

# Exe
my @exe_links = qw(isfdmotd isfdoggenc isfdquery isfdrip isfdsites);
my @exe = ( @exe_links, qw(isfdcdi isfdlscat) );
my @exe_links_PL = @exe_links;
foreach my $exe ( @exe_links_PL ) {
    $exe = $exe . '.PL';
}

# Exe links
foreach my $exe ( @exe_links ) {
    my $exe_PL = $exe . '.PL';
    -f $exe_PL || copy('isfdlscat.PL', $exe_PL);
}

WriteMakefile(
    
    NAME     => 'InfoSys::FreeDB',
    VERSION  => $VERSION,
    PREREQ_PM => {
        'Error' => 0,
        'File::Compare' => 0,
        'File::Copy' => 0,
        'File::Spec' => 0,
        'IO::File' => 0,
        'IO::Socket::INET' => 0,
        'LWP::UserAgent' => 0,
        'Sys::Hostname' => 0,
        'Test::More' => 0,
    },
    EXE_FILES => [
        qw (
            isfdcdi
            isfdlscat
            isfdmotd
            isfdoggenc
            isfdquery
            isfdrip
            isfdsites
        )
    ],
    (
        $] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (
            ABSTRACT => 'FreeDB API',
            AUTHOR   => 'Vincenzo Zocca <Vincenzo@zocca.do.not.sPam.com>'
        ) : ()
    ),
    clean => {
        FILES => "gen/tmp gen/diff-all gen/pod-all gen/sdiff-all " .
            "diff-all pod-all sdiff-all t/tmp @exe @exe_links_PL",
    },
);
