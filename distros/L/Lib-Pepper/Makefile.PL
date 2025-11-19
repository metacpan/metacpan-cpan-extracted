use 5.042000;
use ExtUtils::MakeMaker;
use File::Copy;
use File::Spec;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Determine the installation directory for the shared libraries
# They will be installed to auto/Lib/Pepper/ within the Perl installation
my $installarchlib = $Config{installarchlib};
my $so_install_dir = File::Spec->catdir($installarchlib, 'auto', 'Lib', 'Pepper');

WriteMakefile(
    NAME              => 'Lib::Pepper',
    VERSION_FROM      => 'lib/Lib/Pepper.pm',
    PREREQ_PM         => {
        'English'              => 0,
        'Carp'                 => 0,
        'autodie'              => 0,
        'Array::Contains'      => 0,
        'Data::Dumper'         => 0,
        'Data::Printer'        => 0,
    },
    ABSTRACT_FROM     => 'lib/Lib/Pepper.pm',
    AUTHOR            => 'Rene Schickbauer <cavac@cpan.org>',
    LICENSE           => 'perl',

    # Link against the Pepper libraries
    # -L. tells linker to look in current directory for .so files during build
    # -lpepperc links against libpepperc.so
    # -Wl,-rpath,'$$ORIGIN' sets RPATH so libraries can be found at runtime
    LIBS              => ["-L. -lpepperc -lpepcore -Wl,-rpath,'\$\$ORIGIN' -Wl,-rpath,'$so_install_dir'"],

    DEFINE            => '',

    # Include current directory for header files
    INC               => '-I.',

    # Link all C files
    OBJECT            => '$(O_FILES)',
);

# Custom postamble to install .so files and data files
sub MY::postamble {
    my $postamble = <<'END_POSTAMBLE';

# Install shared libraries and data files to auto/Lib/Pepper/
pure_install ::
	$(NOECHO) $(ECHO) "Installing Pepper shared libraries..."
	$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)/auto/Lib/Pepper
	$(NOECHO) $(CP) libpepperc.so $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/libpepperc.so
	$(NOECHO) $(CP) libpepcore.so $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/libpepcore.so
	$(NOECHO) $(CHMOD) 755 $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/libpepperc.so
	$(NOECHO) $(CHMOD) 755 $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/libpepcore.so
	$(NOECHO) $(ECHO) "Installing Pepper library data files..."
	$(NOECHO) $(CP) share/pepper_cardtypes.xml $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/pepper_cardtypes.xml
	$(NOECHO) $(CHMOD) 644 $(DESTINSTALLARCHLIB)/auto/Lib/Pepper/pepper_cardtypes.xml

END_POSTAMBLE
    return $postamble;
}
