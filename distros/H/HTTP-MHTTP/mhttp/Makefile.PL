use ExtUtils::MakeMaker;
#$Verbose = 1;
my $GOTSSL = "";
if (exists $ENV{'GOTSSL'} && $ENV{'GOTSSL'} eq 'yes'){
  $GOTSSL = ' -DOPENSSL_NO_KRB5 -DGOTSSL ';
}
  
WriteMakefile(
     NAME   => 'libmhttp',
     SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
     clean  => {'FILES' => 'libmhttp$(LIBEEXT)'},
     DEFINE => $GOTSSL.'-D'.(($^O =~ /Solaris/i)? 'DOHERROR' : 'SUMITELSE'),
             );

sub MY::top_targets {
       '
all :: static

pure_all :: static

static ::       libmhttp$(LIB_EXT)

libmhttp$(LIB_EXT): $(O_FILES)
	$(AR) cr libmhttp$(LIB_EXT) $(O_FILES)
	$(RANLIB) libmhttp$(LIB_EXT)

          ';
}
