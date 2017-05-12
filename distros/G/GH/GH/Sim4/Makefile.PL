use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME' => 'GH::Sim4',
	      'VERSION_FROM' => 'Sim4.pm', # finds $VERSION
	      'PREREQ_PM' => {}, # e.g., Module::Name => 1.1
	      'LIBS' => [''], # e.g., '-lm'
	      'DEFINE' => '', # e.g., '-DHAVE_SOMETHING'
	      'INC' => '-I.. -Isim4.2002-03-03', # e.g., '-I/usr/include/other'
	      'CCFLAGS' => '-DPERL_SIM4',
	      'OPTIMIZE' => '-g -O0',	# don't optimize for now...
	      'OBJECT' => 'Sim4.o
                           sim4_helpers.o
                           Xtend1.o
                           align.o
                           args.o
                           charvec.o
                           discrim.o
                           dna.o
                           encoding.o
                           misc.o
                           poly.o
                           prnt.o
                           seq.o
                           seq_read.o
                           sim4b1.o
                           splice.o',
	     );

# rewrite the rule for converting c-ish source code to object modules
# so that the thing that is compiled is the thing that triggered the
# dependency.  The only reason I care is that it lets make's vpath support
# figure out and do The Right Thing.
sub MY::c_o {
            package MY; # so that "SUPER" works right
            my $inherited = "# use \$< so that vpath works right.\n";
	    $inherited .= shift->SUPER::c_o(@_);
            $inherited =~ s/\$\*\..*/\$</g;
            $inherited;
        }


# set the VPATH so that 
sub MY::postamble {
'
    VPATH=sim4.2002-03-03

    etags:
	etags *.[ch] sim4-2002-03-03/*.[ch]
    ';
    } 
