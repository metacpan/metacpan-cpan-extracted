use 5.008;
use ExtUtils::MakeMaker;
use Cwd;
use File::Spec;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.140',
	'perl-Gtk2'               => '1.140',
	'GtkImageView'            => '1.6.0',
);

# minimum required version of dependancies we need to run
our %runtime_reqs = (
	'GtkImageView' => undef,
);

our %PREREQ_PM = (
  'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
  'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
  'Glib'                => $build_reqs{'perl-Glib'},
  'Gtk2'                => $build_reqs{'perl-Gtk2'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Glib::MakeHelper;"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Gtk2::CodeGen;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%PREREQ_PM,
   );
   exit 1; # not reached
}

%pkgcfg = ExtUtils::PkgConfig->find ('gtkimageview >= '
                                                    . $build_reqs{GtkImageView});

$runtime_reqs{GtkImageView} = $pkgcfg{modversion};

mkdir 'build', 0777;

chomp(my $includes = `pkg-config --variable includedir gtkimageview`);
my @headers = glob($includes . "/gtkimageview/*.h");

#
# autogeneration
#
Gtk2::CodeGen->parse_maps('gtkimageviewperl');
Gtk2::CodeGen->write_boot(glob => '*.xs', ignore => '^Gtk2::ImageView$');

our @xs_files = <*.xs>;
our %pm_files = ('ImageView.pm' => '$(INST_LIBDIR)/ImageView.pm',);
our %pod_files = Glib::MakeHelper->do_pod_files (@xs_files);
our @typemaps = qw(build/gtkimageviewperl.typemap);
our @headers = qw(gtkimageviewperl.h
                   build/gtkimageviewperl-autogen.h);

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

my $depends = ExtUtils::Depends->new ('Gtk2::ImageView', 'Gtk2', 'Glib');
$depends->set_inc ($pkgcfg{cflags});
$depends->set_libs ($pkgcfg{libs});
$depends->add_xs (@xs_files);
$depends->add_pm (%pm_files);
my $cwd = cwd();
$depends->add_typemaps (map {File::Spec->catfile($cwd,$_)} @typemaps);

$depends->install (@headers);

$depends->save_config ('build/IFiles.pm');

# As soon as a stable release with Glib::MakeHelper->get_configure_requires_yaml
# hits Sid, change use it, and take out the sub below.
#   my $configure_requires =
#                      Glib::MakeHelper->get_configure_requires_yaml(%PREREQ_PM);
my $configure_requires = get_configure_requires_yaml(%PREREQ_PM);

WriteMakefile(
    NAME            => 'Gtk2::ImageView',
    VERSION_FROM    => 'ImageView.pm', # finds $VERSION
    ABSTRACT        => 'Perl bindings for the GtkImageView widget',
    AUTHOR          => 'Jeffrey Ratcliffe',
    LICENSE         => 'lgpl',
    PREREQ_PM       => \%PREREQ_PM,
    XSPROTOARG      => '-noprototypes',
    MAN3PODS        => \%pod_files,
    $depends->get_makefile_vars,
    EXTRA_META      => qq/
$configure_requires
/,
);


# Stolen from Glib-Perl HEAD
# Generates YAML code that lists every module found in I<%module_to_version>
# under the C<configure_requires> key.  This can be used with
# I<ExtUtils::MakeMaker>'s C<EXTRA_META> parameter to specify which modules are
# needed at I<Makefile.PL> time.

sub get_configure_requires_yaml {
#  shift; # package name
  my %prereqs = @_;

  my $yaml = "configure_requires:\n";
  while (my ($module, $version) = each %prereqs) {
    $yaml .= "   $module: $version\n";
  }

  return $yaml;
}


package MY;

sub postamble {
 my $postamble = <<'END';

realclean ::
	-rm -Rf build

html : blib/lib/Gtk2/
	mpod2html blib/lib/Gtk2/                   \
            -nowarnings -noverbose                              \
            -dir "html" -nobanner                               \
            -idxname "idx" -tocname "index"                     \
            -toctitle "Gtk2-ImageView Table of Contents"        \
            -idxtitle "Gtk2-ImageView Index"                    \
            -stylesheet "style.css" 
	perl -ni -e'print unless m/^(Cannot find page|Warning:)/;' \
           `find html -name "*.html"`    
	find html -type d -exec cp style.css {} \;
END
	return Glib::MakeHelper->postamble_clean ()
             . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $depends,
		COPYRIGHT => "Copyright (C) 2007 by Jeffrey Ratcliffe.\n\nThis software is licensed under the GPL-3; see L<Gtk2::ImageView> for a full notice.",
               )
             . Glib::MakeHelper->postamble_rpms (
                'GTK_IMAGE_VIEW' => $build_reqs{'GtkImageView'},
                'PERL_EXTUTILS_DEPENDS' =>
 			$build_reqs{'perl-ExtUtils-Depends'},
 		'PERL_EXTUTILS_PKGCONFIG' =>
 			$build_reqs{'perl-ExtUtils-PkgConfig'},
 		'PERL_GLIB' => $build_reqs{'perl-Glib'},
 		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
 	       )
 	     .$postamble;
}
package MAIN;
