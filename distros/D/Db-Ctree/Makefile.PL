use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless (-e '/usr/faircom/lib.cli/tcp.libctclient.a') {
    warn("Ctree library not found.  See README\n");
    exit 0;
}

WriteMakefile(
    'NAME'	=> 'Db::Ctree',
    'VERSION_FROM' => 'Ctree.pm', 
    'INC'	=> '-I/usr/faircom/ctree/include -I/usr/faircom/ctree/custom ',
    'LDFROM'	=> '$(OBJECT) /usr/faircom/lib.cli/tcp.libctclient.a',
    'PM'        =>  {'Ctree.pm'  => '$(INST_LIBDIR)/Ctree.pm',
                     'Ctport.ph' => '$(INST_LIB)/Ctport.ph',
                     'Cterrc.ph' => '$(INST_LIB)/Cterrc.ph'}
);
# 'LIBS'	=> ['/faircom/lib.fpg/ctreestd.lib'],
# 'INC'	=> '-I/faircom/ctree/include -I/faircom/ctree/custom',

