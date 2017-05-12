use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'Mail::Transport::Dbx',
    'VERSION_FROM'	=> 'Dbx.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
        (ABSTRACT_FROM => 'Dbx.pm', 
         AUTHOR => 'Tassilo von Parseval <tassilo.parseval@rwth-aachen.de>')
                 :()
    ),
    'LIBS'		    => [''], 
    'DEFINE'		=> '', 
    'INC'		    => '-I.', 
    'MYEXTLIB'      => 'libdbx/libdbx$(LIB_EXT)',
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(DBX_BADFILE DBX_DATA_READ DBX_EMAIL_FLAG_ISSEEN DBX_FLAG_BODY
		 DBX_INDEXCOUNT DBX_INDEX_OVERREAD DBX_INDEX_READ
		 DBX_INDEX_UNDERREAD DBX_ITEMCOUNT DBX_NEWS_ITEM DBX_NOERROR
		 DBX_TYPE_EMAIL DBX_TYPE_FOLDER DBX_TYPE_NEWS DBX_TYPE_VOID));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Mail::Transport::Dbx',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble {
    '
$(MYEXTLIB): libdbx/Makefile
	cd libdbx && $(MAKE) $(PASTHRU)
';
}

sub MY::pasthru {
    return <<'PASTHRU'
PASTHRU = "CCFLAGS=$(CCFLAGS)"\
          "CC=$(CC)"  \
          "OPTIMIZE=$(OPTIMIZE)"
PASTHRU
}
