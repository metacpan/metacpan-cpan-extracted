
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$Verbose = 1;


WriteMakefile (
  'NAME'         => 'Lingua::PT::Conjugate',
  'VERSION_FROM' => 'Conjugate.pm',
  'EXE_FILES'    => ['conjug', 'treinar', 'unconj'],
  'MAN1PODS'     =>{'conjug.pod'=>'$(INST_MAN1DIR)/conjug.1',
		    'treinar.pod'=>'$(INST_MAN1DIR)/treinar.1',},
  'MAN3PODS'=>{'Conjugate.pod'=>'$(INST_MAN3DIR)/Lingua::PT::Conjugate.3',},
  'PM'        => {
		  'Conjugate.pm'=>'$(INST_LIBDIR)/Conjugate.pm',
		  'UnConjugate.pm'=>'$(INST_LIBDIR)/UnConjugate.pm',
		  'Infinitives.pm'=>'$(INST_LIBDIR)/Infinitives.pm',
		  'VerbSuffixes.pm'=>'$(INST_LIBDIR)/VerbSuffixes.pm',
		 },
  'dist'         => { COMPRESS => "gzip -9f",
		      SUFFIX => 'gz',
		    }
);

sub MY::postamble { q(

conjug.pl: conjug conjug.pod Conjugate.pm
	perl -pe 's/perl\s+\-w/perl /' < Conjugate.pm > conjug.pl
	cat conjug.pod >> conjug.pl
	perl -pe 's/use/import/' < conjug >> conjug.pl
	chmod +x conjug.pl

treinar.pl: treinar treinar.pod Conjugate.pm
	perl -pe 's/perl\s+\-w/perl /' < Conjugate.pm > treinar.pl
	cat treinar.pod >> treinar.pl
	perl -pe 's/use/import/ if /PT/' < treinar >> treinar.pl
	chmod +x treinar.pl

Infinitives.pm: all_infinitives
	./mk_str_mod.pl $@ infinitives < $< 

VerbSuffixes.pm: all_output
	./mk_str_mod.pl $@ verb_suffixes < $<

)
}
