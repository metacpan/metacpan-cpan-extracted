use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $have_p5_Palm = eval { require Palm::Raw; 1 };

if( !$have_p5_Palm ) {
    die     qq[You do not have p5-Palm installed.  You must install p5-Palm\n] .
            qq[from CPAN before you can install this module.  Unfortunately\n] .
            qq[the way that p5-Palm is distributed will not allow you to\n] .
            qq[automatically install it.  Please use search.cpan.org to\n] .
            qq[locate the module.\n]
}

WriteMakefile(
    'NAME'		=> 'Palm::Memo32',
    'VERSION_FROM'	=> 'Memo32.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Palm::Raw' => '1.10'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Memo32.pm', # retrieve abstract from module
       AUTHOR     => 'Wayne A. Arthurton <warthurt@cpan.org>') : ()),
);
