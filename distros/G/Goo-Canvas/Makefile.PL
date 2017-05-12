#! /usr/bin/perl -w
use 5.008;
use strict;
use warnings;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.0',
	'perl-Glib'               => '1.103',
	'perl-Gtk2'               => '1.100',
	'perl-Cairo'              => '1.00',
	'goocanvas'           => '0.9',
);

our %prereqs = (
	'Glib'                => $build_reqs{'perl-Glib'},
	'Gtk2'                => $build_reqs{'perl-Gtk2'},
	'Cairo'               => $build_reqs{'perl-Cairo'},
	'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
	'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (
      eval "use ExtUtils::Depends;"
    . "use ExtUtils::PkgConfig;"
    . "use Gtk2::CodeGen;"
    . "use Cairo;"

    # just seeing if Glib is available isn't enough, make sure
    # it's recent enough, too
    . "use Glib '$build_reqs{'perl-Glib'}';"
    . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
    . "use Glib::MakeHelper;" . "1"
  )
{
    warn "$@\n";
    WriteMakefile(
        PREREQ_FATAL => 1,
        PREREQ_PM    => \%prereqs,
    );
    exit 1;    # not reached
}

mkdir 'build', 0777;

our %pkgcfg = ExtUtils::PkgConfig->find ('goocanvas');

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.

our @xs_files = <xs/*.xs>;
our %pm_files = (
    'lib/Goo/Canvas.pm' => '$(INST_LIBDIR)/Canvas.pm',
);
our %pod_files;
%pod_files = (
    'lib/Goo/Canvas.pm' => '$(INST_MAN3DIR)/Goo::Canvas.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files (@xs_files),
);

ExtUtils::PkgConfig->write_version_macros (
    "build/goocanvas-perl-version.h",
    'goocanvas' => 'GOO_CANVAS'
);

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('goocanvas-perl');
Gtk2::CodeGen->write_boot (ignore => '^Goo::Canvas$');

my $goo = ExtUtils::Depends->new ('Goo::Canvas', 'Gtk2', 'Glib', 'Cairo');
$goo->set_inc ($pkgcfg{cflags} . ' -I./build ');
if ( $^O eq 'MSWin32' ) {
    my @a = split /\s+/,$pkgcfg{libs};
    for (@a) {
        next if /gdi32|imm32|shell32|ole32|\-lm/;
        $_ = '-luser32',next if /user32/;
        $_ = '-luuid',next if /uuid/;
        $_ .= '.dll.a' if /^-l/;
    }
    $goo->set_libs (join(' ',@a) . find_extra_libs());
} else {
    $goo->set_libs ($pkgcfg{libs});
}
$goo->add_xs (@xs_files);
$goo->add_pm (%pm_files);
my $cwd = cwd();
$goo->add_typemaps (
    File::Spec->catfile( $cwd, 'build/goocanvas-perl.typemap'),
    File::Spec->catfile( $cwd, 'goocanvas.typemap'),
);
$goo->install (qw(goocanvas-perl.h
                  build/goocanvas-perl-autogen.h
                  build/goocanvas-perl-version.h));
$goo->save_config ('build/IFiles.pm');
use Data::Dumper qw(Dumper);

WriteMakefile(
    NAME          => 'Goo::Canvas',
    VERSION_FROM  => 'lib/Goo/Canvas.pm', # finds $VERSION
    PREREQ_PM     => \%prereqs,
    ABSTRACT_FROM => 'lib/Goo/Canvas.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    'EXE_FILES' => ['bin/perltetris.pl', 'bin/perlmine.pl'],
    MAN3PODS	  => \%pod_files,
    ( $^O eq 'MSWin32' ?
    (dynamic_lib     => { OTHERLDFLAGS=>"-Wl,-out-implib,blib\\arch\\auto\\Goo\\Canvas\\Canvas.lib.a \$(EXPORT_LIST) " })
      : ()),
    $goo->get_makefile_vars,
);

# this probably needs to go into ExtUtils::Depends.
sub find_extra_libs {
	# right now we need this terrible hack only for windows.
	# unfortunately, this code doesn't work on cygwin.  :-/
	return "" unless $^O eq "MSWin32";

	# win32 does not allow unresolved symbols in libraries, but
	# Gtk2 uses on symbols in the dll created for Glib.
	# so, we have to break all this nice abstraction and encapsulation
	# and find the actual Glib.dll and Glib.lib installed by perl when
	# the Glib module was built, and add it to the list of lib files.
	#
	# when we depend on Cairo, the same applies to Cairo.lib.
	#
	# say it with me: "i hate win32."

	my $retstring = "";

	use File::Find;
	find (sub {
              $retstring .= " ".$File::Find::name
                  if /(Glib\.lib|libGlib|Glib\.dll)/i;
              $retstring .= " ".$File::Find::name
                  if /(Cairo\.lib|libCairo|Cairo\.dll)/i;
              $retstring .= " ".$File::Find::name
                  if /(Gtk2\.lib|libGtk2|Gtk2\.dll)/i;
          }, @INC);

	return $retstring;
}

sub MY::postamble {
my $res = Glib::MakeHelper->postamble_clean ()
        . Glib::MakeHelper->postamble_docs (@main::xs_files)
            . Glib::MakeHelper->postamble_rpms (
                'GOO_CANVAS' => $build_reqs{'goocanvas'},
                'PERL_EXTUTILS_DEPENDS' => 
                    $build_reqs{'perl-ExtUtils-Depends'},
                'PERL_EXTUTILS_PKGCONFIG' => 
                    $build_reqs{'perl-ExtUtils-PkgConfig'},
                'PERL_GLIB' => $build_reqs{'perl-Glib'},
                'PERL_GTK' => $build_reqs{'perl-Gtk2'},
                'PERL_CAIRO' => $build_reqs{'perl-Cairo'},
            );
return $res;
}
