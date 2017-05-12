BEGIN {

    #use strict;
    use ExtUtils::MakeMaker;

    eval  "use File::Spec;";
    my $Is_File_Spec_Loaded = !($@);

#     my $Is_OS2 = $^O eq 'os2';
#     my $Is_Mac = $^O eq 'MacOS';
#     my $Is_Win32 = $^O eq 'MSWin32';
#     my $Is_Dos = $^O eq 'dos';

    # Override helper methods in ExtUtils::MakeMaker to write the test
    # targets.  This is necessary if module user has installed LibWeb's
    # denpendencies in non-standard locations.  The following two
    # subroutines are overrided by puting an extra phrase: -I\$\(LIB\)
#    sub MY::test_via_harness {
#	package MY; # so that ``SUPER'' works right
#	my $inherited = shift->SUPER::test_via_harness(@_);
#	$inherited
#	  =~ s:-I\$\(PERL_ARCHLIB\):-I\$\(INSTALLSITELIB\) -I\$\(PERL_ARCHLIB\):;
#	$inherited;
#    };
#    sub MY::test_via_script {
#	package MY; # so that ``SUPER'' works right
#	my $inherited = shift->SUPER::test_via_script(@_);
#	$inherited
#	  =~ s:-I\$\(PERL_ARCHLIB\):-I\$\(INSTALLSITELIB\) -I\$\(PERL_ARCHLIB\):;
#	$inherited;
#    };
#    sub MY::test {
#	package MY; # so that ``SUPER'' works right
#	my $inherited = shift->SUPER::test(@_);
#	$inherited =~ s/-I$(PERL_ARCHLIB)/-I$Non_Standard_Lib -I$(PERL_ARCHLIB)/;
#	$inherited;
#    };

    # Add this to the end of the Makefile so that user can type ``make Uninstall''
    # to remove installed files if they have used the ``LIB='' switch when making
    # the Makefile such as ``perl Makefile.PL LIB=~/path_to/my_perl_lib''.
    sub MY::postamble {	
	if ($Is_File_Spec_Loaded) { } else { return; }
	my @m;
	push @m, q{
Uninstall :: Uninstall_from_$(INSTALLDIRS)dirs

Uninstall_from_perldirs ::
	}.'@'.
	q{$(UNINSTALL) } . File::Spec->catfile('$(INSTALLARCHLIB)','auto','$(FULLEXT)','.packlist') . q{

Uninstall_from_sitedirs ::
	}.'@'.
	q{$(UNINSTALL) } . File::Spec->catfile('$(INSTALLSITEARCH)','auto','$(FULLEXT)','.packlist') . q{};
	join("", @m);
    }

} # end BEGIN


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
(
 'NAME'	=> 'LibWeb',
 'DISTNAME' => 'LibWeb',
 'VERSION_FROM' => 'LibWeb/Core.pm', # finds $VERSION
 'PMLIBDIRS'    => ['LibWeb'],
 'linkext'   => { LINKTYPE=>'' },    # no link needed
 'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
		 'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'}
);
