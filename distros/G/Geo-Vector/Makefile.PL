use 5.008;
use Config;
use ExtUtils::MakeMaker;

my %missing_modules;

$missing_modules{chk_module('ExtUtils::Depends')} = 1;
$missing_modules{chk_module('ExtUtils::PkgConfig')} = 1;
$missing_modules{chk_module('File::Basename')} = 1;
$missing_modules{chk_module('JSON::XS')} = 1;
$missing_modules{chk_module('Geo::GDAL', 1.81)} = 1;
$missing_modules{chk_module('Geo::Raster', 0.62)} = 1;
$missing_modules{chk_module('Geo::OGC::Geometry', 0.04)} = 1;
$missing_modules{chk_module('Gtk2::GladeXML')} = 1;
$missing_modules{chk_module('Gtk2::Ex::Geo', 0.62)} = 1;

$missing_modules{chk_module('Win32::OLE')} = 1 if $^O eq 'MSWin32';

delete $missing_modules{''};

my @missing_modules = keys %missing_modules;
warn "Following required modules are missing: @missing_modules\n" if @missing_modules;

require ExtUtils::Depends; 
require ExtUtils::PkgConfig;

my($inc,$libs,$cflags) = ('','','');

for $package ('gdal','gdk-pixbuf-2.0','libral') {
    print "Checking for $package: ";
    my($c,$l);
    if ($package eq 'gdal') {
	if ($^O ne 'MSWin32') {
	    $c = `gdal-config --cflags`;
	    chomp $c;
	    $l = `gdal-config --libs`;
	    chomp $l;
	} else {
	    ($l, $c) = gdal_config("c:/msys/1.0/local/bin/gdal-config");
	}
    } else {
	%pkg_info = ExtUtils::PkgConfig->find ($package);
	$c = $pkg_info{cflags};
	$l = $pkg_info{libs};
    }
    $cflags .= " $c";
    $libs .= " $l";
    print "ok\n";
}

our $deps = ExtUtils::Depends->new('Geo::Vector', 'Gtk2::Ex::Geo', 'Gtk2');

$deps->set_inc($inc);
$deps->set_libs($libs);

our %pm_files = 
    (
     'lib/Geo/Vector.pm'               => '$(INST_LIBDIR)/Vector.pm',
     'lib/Geo/Vector/Layer.pm'         => '$(INST_LIBDIR)/Vector/Layer.pm',
     'lib/Geo/Vector/Feature.pm'       => '$(INST_LIBDIR)/Vector/Feature.pm',
     'lib/Geo/Vector/Layer/Dialogs.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs.pm',
     'lib/Geo/Vector/Layer/Dialogs/New.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/New.pm',
     'lib/Geo/Vector/Layer/Dialogs/Copy.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Copy.pm',
     'lib/Geo/Vector/Layer/Dialogs/Open.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Open.pm',
     'lib/Geo/Vector/Layer/Dialogs/Rasterize.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Rasterize.pm',
     'lib/Geo/Vector/Layer/Dialogs/Vertices.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Vertices.pm',
     'lib/Geo/Vector/Layer/Dialogs/Features.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Features.pm',
     'lib/Geo/Vector/Layer/Dialogs/FeatureCollection.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/FeatureCollection.pm',
     'lib/Geo/Vector/Layer/Dialogs/Properties.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Properties.pm',
     'lib/Geo/Vector/Layer/Dialogs/Feature.pm' => '$(INST_LIBDIR)/Vector/Layer/Dialogs/Feature.pm',
     );

$deps->add_pm (%pm_files);
$deps->add_xs('lib/Geo/Vector.xs');

@for_windows = ();
if ($^O eq 'MSWin32') {
    $lddlflags = $Config{lddlflags};
    $lddlflags =~ s/-mdll/-shared/;
    @for_windows = 
	(
	 LDDLFLAGS => $lddlflags,
	 dynamic_lib=>
	 {OTHERLDFLAGS=>"-Wl,--out-implib=blib\\arch\\auto\\Geo\\Vector\\Vector.dll.a "});
}

$deps->save_config("Files.pm");

WriteMakefile(
	      NAME              => 'Geo::Vector',
	      VERSION_FROM      => 'lib/Geo/Vector.pm',
	      $deps->get_makefile_vars(),
	      ( $] >= 5.005 ?
		(ABSTRACT_FROM  => 'lib/Geo/Vector.pm',
		 AUTHOR         => 'Ari Jolma <ajolma at tkk.fi>') : () ),
	      CCFLAGS => "-O2 -fno-builtin $cflags $inc",
	      $deps->get_makefile_vars,
	      @for_windows
	      );
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(CONCAVE CONVEX));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Geo::Vector',
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

sub chk_module {
    my($pkg, $version) = @_;
    print "Checking for $pkg ($version):";
    eval { 
	my $p; 
	($p = $pkg . ".pm") =~ s#::#/#g; 
	require $p;
    };
    if ($@) {
	print " failed)\n";
	return $pkg;
    } else {
	my $v = '$v=$'.$pkg.'::VERSION';
	eval($v);
	if ($v < $version) {
	    print " failed\n";
	    return "$pkg is old version $v";
	}
	print " ok\n";
	return '';
    }
}

sub gdal_config {
    my $fh = shift;
    open $fh, $fh or die "$fh not found!";
    my $LIB = '';
    my $INC = '';
    if ($fh) {
	my @config = <$fh>;
	close $fh;
	for (@config) {
	    if (/^CONFIG_DEP_LIBS/) {
		s/^CONFIG_DEP_LIBS="//;
		s/"\s*$//;
		$LIB .= $_;
	    }
	    if (/^CONFIG_CFLAGS/) {
		s/^CONFIG_CFLAGS="//;
		s/"\s*$//;
		$INC .= $_;
	    }
	}
    }
    $usr_local = "/usr/local";
    $msys_local = "c:/msys/1.0/local";
    $LIB =~ s/$usr_local/$msys_local/;
    $INC =~ s/$usr_local/$msys_local/;
    return ("$LIB -lgdal", $INC);
}

# -o on the compiler command line...
package MY;
use Cwd;
sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    $inherited .= ' -o $@';
    $inherited;
}

sub postamble {
    my $ret = '';
    my $lib = 'lib/Geo/Vector/Layer/';
    for ('Dialogs') {
	$ret .= "\n$lib$_.pm: $lib$_.pm.in $lib$_.glade\n";
	if ($^O eq 'MSWin32') {
	} else {
	    $ret .= "\tif [ -f $lib$_.pm ]; then chmod u+w $lib$_.pm; fi\n\n";
	}
	my $l = $lib;
	if ($^O eq 'MSWin32') {
	    $l =~ s/\//\\/g;
	    $ret .= "\tcopy $l$_.pm.in+$l$_.glade $l$_.pm\n";
	} else {
	    $ret .= "\tcat $l$_.pm.in $l$_.glade >$l$_.pm\n";
	    $ret .= "\tchmod a-w $lib$_.pm\n\n"; # to remember to edit .pm.in :)
	}
    }
    return $ret;
}
