package main;

require 5.006001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pfft = 0;

$SIG{PIPE} = sub {}; 
open POPEN_SVN, "svn help|" or $pfft ++; 1 while <POPEN_SVN>;
close POPEN_SVN             or $pfft ++;

open POPEN_GIT, "git help|" or $pfft ++; 1 while <POPEN_GIT>;
close POPEN_GIT             or $pfft ++;

if( $pfft ) {
    warn "skipping most tests because you either don't have svn, git, or don't have permission to use them\n";
    sleep 1;

    open SKIP, ">SKIP_MOST_TESTS"; close SKIP;
}

$pfft = 0;
if( not -d "makefile_test" ) {
    # ideally, we'd remove the makefile_test dir, but that's a lotta work, and this is close enough
    open POPEN_SVNADMIN, "svnadmin create makefile_test|" or $pfft ++; 1 while <POPEN_SVNADMIN>;
    close POPEN_SVNADMIN or $pfft ++;
}

if( $pfft or not -d "makefile_test" ) {
    warn "skipping most tests because you either you don't have svnadmin, or don't have permission to use it\n";
    sleep 1;

    open SKIP, ">SKIP_MOST_TESTS"; close SKIP;
}

WriteMakefile(
    NAME          => 'Git::SVNReplay',
    VERSION_FROM  => 'SVNReplay.pm',
    AUTHOR        => 'Paul Miller <jettero@cpan.org>',
    EXE_FILES     => [ 'git-svn-replay' ],

    PREREQ_PM => {
        'File::Slurp'           => 0,
        'File::Path'            => 0,
        'Date::Parse'           => 0,
        'Getopt::Long'          => 0,
        'Term::GentooFunctions' => 0,
        'IPC::System::Simple'   => 0,
        'Pod::Usage'            => 0,
        'DBM::Deep'             => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['git', 'svn'],
                resources=> {
                    repository => 'http://github.com/jettero/git-svn-replay',
                },
            },

        LICENSE	=> 'GPL',
    ) : ()),

    clean => { FILES => 'SKIP_MOST_TESTS *.repo *.co *.rdb dist makefile_test' },
);

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';

README: git-svn-replay
	perl -MPod::Text -e '$$p = Pod::Text->new (sentence => 0, width => 65); $$p->select("DESCRIPTION"); $$p->parse_from_file( "git-svn-replay" => "README");'

MAKE_FRAG

    return $postamble;
}

1;
