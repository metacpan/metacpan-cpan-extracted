use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::LinkExtractor',
    'VERSION_FROM'	=> 'LinkExtractor.pm', # finds $VERSION

    PREREQ_PM   => {
#        'HTML::TokeParser::Simple'	=> '2', # or a minimum workable version
        'HTML::TokeParser'  => 0,
    },

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LinkExtractor.pm', # retrieve abstract from module
       AUTHOR     => 'PodMaster') : ()),
);

__END__
perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake disttest
nmake dist TAR=ptar TARFLAGS=-zcvf COMPRESS=echo
perl -e"my $f=glob q,*.tar,;warn rename $f, qq,$f.gz,"
chmod 7777 *.gz
perl -le" `cpan-upload $_` for( (sort glob q,*.gz,)[-1]) "
