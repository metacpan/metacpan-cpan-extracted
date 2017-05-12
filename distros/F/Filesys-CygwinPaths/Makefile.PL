# $Source: /share/SOMIANCVSROOT/platform-specific/Filesys-CygwinPaths/Makefile.PL,v $ : $Author: sorenboss $ $Revision: 1.4 $ $Date: 2003/05/31 21:11:31 $
use ExtUtils::MakeMaker;
BEGIN {
  if( not $^O =~/cygwin/i ) {
	warn "Sorry, you cannot build this module on a non-Cygwin Perl,\n",
	     "but am letting you proceed in case you are trying to build\n",
	     "a release tarball or something.\n";
  }
}


# Subject to change -- but with with present EU::MM don't know WHAT
# this does anyway!
my $funct =  [ qw{
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_win32_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_win32_path
  } ];

# These work well on Cygwin Perl 5.6.1. On later, like 5.8.0, YMMV.
my %stdatt = (
    'NAME'		=> 'Filesys::CygwinPaths',
	'VERSION'   	=> '0.04',
	'XS_VERSION'	=> '0.04',
	'VERSION_FROM'	=> 'lib/Filesys/CygwinPaths.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM 	=> 'lib/Filesys/CygwinPaths.pm',
	'AUTHOR'     	=> 'Soren Andersen <somian@pobox.com>') : ()),
	'INC'       => '-I.',
	'XS'        => { 'path_protocol.xs' => 'path_protocol.c' },
	'TYPEMAPS'  => [ 'Cygwin.typemap' ],
	'H'         => [ 'path_protocol.h'],
	'OBJECT'    => 'path_protocol.o',
	'FUNCLIST'  => $funct,
	'OPTIMIZE'  => '-O2 -Wundef',
	'LD'        => 'gcc -shared',
	'CCDLFLAGS' => '',
#	'CCFLAGS'   => '-DPERL_USE_SAFE_PUTENV -fno-strict-aliasing',
	'dist'      => { COMPRESS => gzip, SUFFIX => '.gz'},
);

WriteMakefile( %stdatt );

# overrides of various canned MakeMaker routines. See EU::MM manpage.
package MY;


sub install {
    my($self, %attribs) = @_;
    my(@m);

    push @m, q{
# a 'gmake' user-defined *function*, maps target to dir for perllocal.pod, etc.:
UCme = $(strip \
$(if $(filter perl,$(1)),ARCHLIB) \
$(if $(filter site,$(1)),SITEARCH) \
$(if $(filter vendor,$(1)),VENDORARCH))
_assembl_dir_name = $(INSTALL$(call UCme,$(patsubst doc_%_install,%,$@)))
## --------------
  ifeq "0" "$(DRY_RUN)"
## --------------
SIMULATION   := $(NOOP)
_doc_PRE_NOTICE  = echo -e 'Appending installation info to\n \
     $(_assembl_dir_name)/perllocal.pod'
_perllocal_REDIR = >> $(_assembl_dir_name)/perllocal.pod
## --------------
  else
## --------------
SIMULATION   = echo -e '$$(DRY_RUN) is set, this is an installation \
*simulation*.\n    Here is what would be done:\n'
_doc_PRE_NOTICE  = echo -e '\nDuring a real install, we would be appending this \
installation info to\n     "$(_assembl_dir_name)/perllocal.pod":\n'
_perllocal_REDIR =
## --------------
  endif
## --------------
.PHONY: install_dry_run
install_dry_run :: override DRY_RUN = 1
install_dry_run :: pure_install doc_install

install         :: all pure_install doc_install
install_perl    :: all pure_perl_install doc_perl_install
install_site    :: all pure_site_install doc_site_install
install_vendor  :: all pure_vendor_install doc_vendor_install
pure_install    :: pure_$(INSTALLDIRS)_install
doc_install     :: doc_$(INSTALLDIRS)_install

pure__install : pure_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site
doc__install  : doc_site_install
	@echo INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	}.$self->{NOECHO}.q{$(SIMULATION)
	}.$self->{NOECHO}.q{$(MOD_INSTALL) \
      read }.File::Spec->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist').q{ \
      write }.File::Spec->catfile('$(INSTALLARCHLIB)','auto','$(FULLEXT)','.packlist').q{ \
      $(INST_LIB) $(INSTALLPRIVLIB) \
      $(INST_ARCHLIB) $(INSTALLARCHLIB) \
      $(INST_BIN) $(INSTALLBIN) \
      $(INST_SCRIPT) $(INSTALLSCRIPT) \
      $(INST_MAN1DIR) $(INSTALLMAN1DIR) \
      $(INST_MAN3DIR) $(INSTALLMAN3DIR)
	}.$self->{NOECHO}.q{$(WARN_IF_OLD_PACKLIST) \
      }.File::Spec->catdir('$(SITEARCHEXP)','auto','$(FULLEXT)').q{

pure_site_install ::
	}.$self->{NOECHO}.q{$(SIMULATION)
	}.$self->{NOECHO}.q{$(MOD_INSTALL) \
      read }.File::Spec->catfile('$(SITEARCHEXP)','auto','$(FULLEXT)','.packlist').q{ \
      write }.File::Spec->catfile('$(INSTALLSITEARCH)','auto','$(FULLEXT)','.packlist').q{ \
      $(INST_LIB) $(INSTALLSITELIB) \
      $(INST_ARCHLIB) $(INSTALLSITEARCH) \
      $(INST_BIN) $(INSTALLSITEBIN) \
      $(INST_SCRIPT) $(INSTALLSCRIPT) \
      $(INST_MAN1DIR) $(INSTALLSITEMAN1DIR) \
      $(INST_MAN3DIR) $(INSTALLSITEMAN3DIR)
	}.$self->{NOECHO}.q{$(WARN_IF_OLD_PACKLIST) \
      }.File::Spec->catdir('$(PERL_ARCHLIB)','auto','$(FULLEXT)').q{

pure_vendor_install ::
	}.$self->{NOECHO}.q{$(SIMULATION)
	}.$self->{NOECHO}.q{$(MOD_INSTALL) \
      read }.File::Spec->catfile('$(VENDORARCHEXP)','auto','$(FULLEXT)','.packlist').q{ \
      write }.File::Spec->catfile('$(INSTALLVENDORARCH)','auto','$(FULLEXT)','.packlist').q{ \
      $(INST_LIB) $(INSTALLVENDORLIB) \
      $(INST_ARCHLIB) $(INSTALLVENDORARCH) \
      $(INST_BIN) $(INSTALLVENDORBIN) \
      $(INST_SCRIPT) $(INSTALLSCRIPT) \
      $(INST_MAN1DIR) $(INSTALLVENDORMAN1DIR) \
      $(INST_MAN3DIR) $(INSTALLVENDORMAN3DIR)

doc_perl_install ::
	}.$self->{NOECHO}.q{$(_doc_PRE_NOTICE)
	-}.$self->{NOECHO}.q{$(MKPATH) $(INSTALLARCHLIB)
	-}.$self->{NOECHO}.q{$(DOC_INSTALL) \
          "Module" "$(NAME)" \
          "installed into" "$(INSTALLPRIVLIB)" \
          LINKTYPE "$(LINKTYPE)" \
          VERSION "$(VERSION)" \
          EXE_FILES "$(EXE_FILES)" \
          $(_perllocal_REDIR)

doc_site_install ::
	}.$self->{NOECHO}.q{$(_doc_PRE_NOTICE)
	-}.$self->{NOECHO}.q{$(MKPATH) $(INSTALLSITEARCH)
	-}.$self->{NOECHO}.q{$(DOC_INSTALL) \
          "Module" "$(NAME)" \
          "installed into" "$(INSTALLSITELIB)" \
          LINKTYPE "$(LINKTYPE)" \
          VERSION "$(VERSION)" \
          EXE_FILES "$(EXE_FILES)" \
          $(_perllocal_REDIR)

doc_vendor_install ::
	}.$self->{NOECHO}.q{$(_doc_PRE_NOTICE)
	-}.$self->{NOECHO}.q{$(MKPATH) $(INSTALLVENDORLIB)
	-}.$self->{NOECHO}.q{$(DOC_INSTALL) \
          "Module" "$(NAME)" \
          "installed into" "$(INSTALLVENDORLIB)" \
          LINKTYPE "$(LINKTYPE)" \
          VERSION "$(VERSION)" \
          EXE_FILES "$(EXE_FILES)" \
          $(_perllocal_REDIR)

};

    push @m, q{
uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	}.$self->{NOECHO}.
	q{$(UNINSTALL) }.File::Spec->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist').q{

uninstall_from_sitedirs ::
	}.$self->{NOECHO}.
	q{$(UNINSTALL) }.File::Spec->catfile('$(SITEARCHEXP)','auto','$(FULLEXT)','.packlist').q{

uninstall_from_vendordirs ::
	}.$self->{NOECHO}.
        q{$(UNINSTALL) }.File::Spec->catfile('$(VENDORARCHEXP)','auto','$(FULLEXT)','.packlist').q{
};

    join("",@m);
}

# have to override this because of presence of another .PL file
# ("exoMakefile.PL").
sub processPL {
    my($self) = shift;
    return "" unless $self->{PL_FILES};
    my(@m, $plfile);
    foreach $plfile (sort keys %{$self->{PL_FILES}}) {
        my $list = ref($self->{PL_FILES}->{$plfile})
		? $self->{PL_FILES}->{$plfile}
		: [$self->{PL_FILES}->{$plfile}];
	my $target;
	foreach $target (@$list) {
	  return "" if $target eq 'exoMakefile';
	push @m, "
all :: $target
	$self->{NOECHO}\$(NOOP)

$target :: $plfile
	\$(PERLRUNINST) $plfile $target
";
	}
    }
    join "", @m;
}

# End.
