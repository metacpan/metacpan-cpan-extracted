use Config;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $moduledir = $Config{'siteprefixexp'} . "/lib/IPTables-IPv4";
my $incpath = $Config{'archlibexp'} . "/CORE/perl.h";

{
	package MY;

	sub test_via_harness {
		my($self, $perl, $tests) = @_;
		return $self->SUPER::test_via_harness("IPT_MODPATH=\$(CURDIR)/modules $perl", $tests);
	}

	sub test_via_script {
		my($self, $perl, $tests) = @_;
		return $self->SUPER::test_via_script("IPT_MODPATH=\$(CURDIR)/modules $perl", $tests);
	}

	sub postamble {
"
libiptc/libiptc.a: libiptc/*.c
	make -C libiptc/ all

\%_v6.o: \%.c
	\$(CCCMD) \$(CCCDLFLAGS) \"-I\$(PERL_INC)\" \$(PASTHRU_DEFINE) \$(DEFINE) -DINET6 -o \$@ \$<

pure_all:: modules
	make -C modules/ all INSTALL_DIR=$moduledir

install::
	make -C modules/ install INSTALL_DIR=$moduledir

clean::
	make -C modules/ clean
	make -C libiptc/ clean

V6_INST_ARCHAUTODIR = \$(INST_ARCHLIB)/auto/IPTables/IPv6
V6_OBJECTS = IPv6\$(OBJ_EXT) loader_v6\$(OBJ_EXT) packer_v6\$(OBJ_EXT) unpacker_v6\$(OBJ_EXT) maskgen_v6\$(OBJ_EXT) libiptc/libiptc.a

config :: \$(V6_INST_ARCHAUTODIR)/.exists
	\@\$(NOOP)

\$(V6_OBJECTS) : \$(PERL_HDRS)

\$(V6_OBJECTS) : \$(FIRST_MAKEFILE)

\$(V6_INST_ARCHAUTODIR)/.exists :: $incpath
	\@\$(MKPATH) \$(V6_INST_ARCHAUTODIR)
	\@\$(EQUALIZE_TIMESTAMP) $incpath \$\@

\$(V6_INST_ARCHAUTODIR)/IPv6.\$(DLEXT): \$(V6_OBJECTS)
	\$(RM_F) \$\@
	LD_RUN_PATH=\"\$(LD_RUN_PATH)\" \$(LD)  \$(LDDLFLAGS) \$^ \$(OTHERLDFLAGS) -o \$\@ \$(MYEXTLIB) \$(PERL_ARCHIVE) \$(LDLOADLIBS) \$(PERL_ARCHIVE_AFTER) \$(EXPORT_LIST)
	\$(CHMOD) \$(PERM_RWX) \$\@

IPv6.bs: Makefile \$(V6_INST_ARCHAUTODIR)/.exists
	\@echo \"Running Mkbootstrap for IPTables::IPv6 ()\"
	\@\$(PERLRUN) \\
		\"-MExtUtils::Mkbootstrap\" \\
		-e \"Mkbootstrap('IPv6','');\"
	\@\$(TOUCH) \$\@
	\$(CHMOD) \$(PERM_RW) \$\@

\$(V6_INST_ARCHAUTODIR)/IPv6.bs: IPv6.bs \$(V6_INST_ARCHAUTODIR)/.exists
	\@rm -rf \$\@
	-cp IPv6.bs \$\@
	\$(CHMOD) \$(PERM_RW) \$\@

dynamic:: \$(V6_INST_ARCHAUTODIR)/IPv6.\$(DLEXT) \$(V6_INST_ARCHAUTODIR)/IPv6.bs

";
	}
}

WriteMakefile(
    'NAME'	=> 'IPTables::IPv4',
    'VERSION_FROM' => 'IPv4.pm', # finds $VERSION
    'OBJECT'	=> 'IPv4.o loader.o packer.o unpacker.o maskgen.o libiptc/libiptc.a',
    'INC'	=> '-Iinclude -I/usr/src/linux/include',
    'CCFLAGS'	=> "-Wall -DMODULE_PATH=\\\"$moduledir\\\"" . (defined $Config{'use64bitint'} ? " -DPERL_USES_64BIT_INT" : ""),
    'TYPEMAPS'	=> ['IPTables.typemap'],
    'XSPROTOARG' => '-noprototypes',
);
