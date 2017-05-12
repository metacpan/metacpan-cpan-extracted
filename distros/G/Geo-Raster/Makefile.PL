use 5.005;
use Carp;
use Config;
use ExtUtils::MakeMaker;

my %missing_modules;

my @configure_requires = qw/ExtUtils::Depends ExtUtils::PkgConfig Gtk2/;
foreach my $m (@configure_requires) {
    $missing_modules{chk_module($m)} = 1;
}

delete $missing_modules{''};

my @missing_modules = keys %missing_modules;
print "Following required modules are missing: @missing_modules\n" if @missing_modules;
exit 0 if @missing_modules;

require ExtUtils::Depends;
require ExtUtils::PkgConfig;

$missing_modules{chk_module('Statistics::Descriptive')} = 1;
$missing_modules{chk_module('Geo::GDAL')} = 1; # should this be optional?
$missing_modules{chk_module('Gtk2::Ex::Geo', 0.62)} = 1;
delete $missing_modules{''};
my @missing_modules = keys %missing_modules;
warn "Problems with required modules: @missing_modules\n" if @missing_modules;

my($inc,$libs,$cflags) = ('','',$Config{ccflags});

for $package ('gdal','gdk-pixbuf-2.0','libral') {
    print "Checking for $package: ";
    my($c, $l);
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

our $deps = ExtUtils::Depends->new('Geo::Raster', 'Gtk2::Ex::Geo');

$deps->set_inc($inc);
$deps->set_libs($libs);

@for_windows = ();
if ($^O eq 'MSWin32') {
    $lddlflags = $Config{lddlflags};
    $lddlflags =~ s/-mdll/-shared/;
    @for_windows = 
	(
	 LDDLFLAGS => $lddlflags,
	 dynamic_lib=>
	 {OTHERLDFLAGS=>"-Wl,--out-implib=blib\\arch\\auto\\Geo\\Raster\\Raster.dll.a "});
}

our $root = 'lib/Geo/Raster';
our $i = '$(INST_LIBDIR)/Raster';

our %pm_files = 
    (
     $root.'.pm'                  => $i.'.pm',
     $root.'/Operations.pm'       => $i.'/Operations.pm',
     $root.'/Focal.pm'            => $i.'/Focal.pm',
     $root.'/Zonal.pm'            => $i.'/Zonal.pm',
     $root.'/Global.pm'            => $i.'/Global.pm',
     $root.'/IO.pm'               => $i.'/IO.pm',
     $root.'/Image.pm'            => $i.'/Image.pm',
     $root.'/Algorithms.pm'       => $i.'/Algorithms.pm',
     $root.'/TerrainAnalysis.pm'  => $i.'/TerrainAnalysis.pm',
     $root.'/Geostatistics.pm'    => $i.'/Geostatistics.pm',
     $root.'/Layer.pm'            => $i.'/Layer.pm',
     $root.'/Layer/Dialogs.pm'    => $i.'/Layer/Dialogs.pm',
     $root.'/Layer/Dialogs/Copy.pm' => $i.'/Layer/Dialogs/Copy.pm',
     $root.'/Layer/Dialogs/Polygonize.pm' => $i.'/Layer/Dialogs/Polygonize.pm',
     $root.'/Layer/Dialogs/Properties/GDAL.pm' => $i.'/Layer/Dialogs/Properties/GDAL.pm',
     $root.'/Layer/Dialogs/Properties/libral.pm' => $i.'/Layer/Dialogs/Properties/libral.pm'
     );

$deps->add_pm(%pm_files);
$deps->add_xs('lib/Geo/Raster.xs');

$deps->save_config("Files.pm");

WriteMakefile1(NAME                        => 'Geo::Raster',
               VERSION_FROM                => 'lib/Geo/Raster.pm',
               ABSTRACT_FROM               => 'lib/Geo/Raster.pm',
               AUTHOR                      => 'Ari Jolma <ari.jolma @ aalto.fi>',
               LICENSE                     => 'perl',
               $deps->get_makefile_vars(),
               #'EXE_FILES'                => [ 'rash' ],
               PREREQ_PM         => {
                   'Gtk2::Ex::Geo' => 0,
                   'Geo::GDAL'     => 0
               },
               CONFIGURE_REQUIRES          => { map {$_ => 0} @configure_requires },
               CCFLAGS                     => "-O2 -fno-builtin $cflags $inc",
               $deps->get_makefile_vars,
               @for_windows,
               META_MERGE => {
                   resources => {
                       repository => 'https://github.com/ajolma/geoinformatica.git/trunk/Geo-Raster',
                   },
               },
               TEST_REQUIRES => {
                   'Test::More' => 0,
               },
    );

sub chk_module {
    my($pkg, $version) = @_;
    print "Checking for $pkg ($version):";
    eval { 
	my $p; 
	($p = $pkg . ".pm") =~ s#::#/#g; 
	require $p;
    };
    if ($@) {
	print " failed: $@\n";
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

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
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
    my $lib = 'lib/Geo/Raster/Layer/';
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
