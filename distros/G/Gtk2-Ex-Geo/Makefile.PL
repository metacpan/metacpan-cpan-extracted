use 5.008;
use Config;
use ExtUtils::MakeMaker;

my %missing_modules;

my @configure_requires=qw/ExtUtils::Depends ExtUtils::PkgConfig Gtk2/;
foreach my $m (@configure_requires) {
    $missing_modules{chk_module($m)} = 1;
}

delete $missing_modules{''};

my @missing_modules = keys %missing_modules;
print "Following required modules are missing: @missing_modules\n".
"Please upgrade your CPAN client or install them manually" if @missing_modules;
exit 0 if @missing_modules;

require ExtUtils::Depends;
require ExtUtils::PkgConfig;

my($inc,$libs,$cflags) = ('','',$Config{ccflags});

my @packages = ('gdk-pixbuf-2.0');

for $package (@packages) {
    print "Checking for $package: ";
    my($c,$l);
    if ($package eq 'gdal' and $^O ne 'MSWin32') {
	$c = `gdal-config --cflags`;
	chomp $c;
	$l = `gdal-config --libs`;
	chomp $l;
    } else {
	%pkg_info = ExtUtils::PkgConfig->find ($package);
	$c = $pkg_info{cflags};
	$l = $pkg_info{libs};
    }
    $cflags .= " $c";
    # hack to circumwent the fact that ExtUtils::MakeMaker does not find .dll.a libraries
    if ($^O eq "MSWin32") {
	my @a = split /\s+/,$l;
	for (@a) {
	    if (/^-l/ and !(/.dll/) and !(/-lm/) and !(/^-lws2/) and !(/^-lgdi/)) {
		$_ .= '.dll';
	    }
	}
	$l = join(' ',@a);
    }
    $libs .= " $l";
    print "ok\n";
}

our $deps = ExtUtils::Depends->new('Gtk2::Ex::Geo', 'Gtk2');

our %pm_files = (
		 'lib/Gtk2/Ex/Geo/Dialogs/Colors.pm'  => '$(INST_LIBDIR)/Geo/Dialogs/Colors.pm',
		 'lib/Gtk2/Ex/Geo/Dialogs/Labeling.pm'=> '$(INST_LIBDIR)/Geo/Dialogs/Labeling.pm',
		 'lib/Gtk2/Ex/Geo/Dialogs/Symbols.pm' => '$(INST_LIBDIR)/Geo/Dialogs/Symbols.pm',
		 'lib/Gtk2/Ex/Geo/Overlay.pm'      => '$(INST_LIBDIR)/Geo/Overlay.pm',
		 'lib/Gtk2/Ex/Geo/Glue.pm'         => '$(INST_LIBDIR)/Geo/Glue.pm',
		 'lib/Gtk2/Ex/Geo/TreeDumper.pm'   => '$(INST_LIBDIR)/Geo/TreeDumper.pm',
		 'lib/Gtk2/Ex/Geo/DialogMaster.pm' => '$(INST_LIBDIR)/Geo/DialogMaster.pm',
		 'lib/Gtk2/Ex/Geo/Layer.pm'        => '$(INST_LIBDIR)/Geo/Layer.pm',
		 'lib/Gtk2/Ex/Geo/Dialogs.pm'      => '$(INST_LIBDIR)/Geo/Dialogs.pm',
		 'lib/Gtk2/Ex/Geo.pm'              => '$(INST_LIBDIR)/Geo.pm',
);

$deps->add_pm (%pm_files);
$deps->add_xs('lib/Gtk2/Ex/Geo.xs');
$deps->set_libs($libs);

@for_windows = ();
if ($^O eq 'MSWin32') {
    $lddlflags = $Config{lddlflags};
    $lddlflags =~ s/-mdll/-shared/;
    @for_windows = (LDDLFLAGS => $lddlflags,
		    dynamic_lib=>{OTHERLDFLAGS=>"-Wl,--out-implib=blib\\arch\\auto\\Gtk2\\Ex\\Geo.dll.a "});
}

$deps->install (qw(lib/Gtk2/Ex/gtk2-ex-geo.h));
$deps->save_config ('Files.pm');

WriteMakefile1(
	      NAME              => 'Gtk2::Ex::Geo',
	      VERSION_FROM      => 'lib/Gtk2/Ex/Geo.pm',
	      ABSTRACT_FROM   => 'lib/Gtk2/Ex/Geo.pm', # retrieve abstract from module
	      AUTHOR          => 'Ari Jolma <ari.jolma @ aalto.fi>',
	      LICENSE => 'perl',
	      PREREQ_PM         => {
		  'Gtk2::GladeXML' => 0,
		  'Graphics::ColorUtils' => 0,
		  'Geo::OGC::Geometry' => 0,
		  'Glib' => 0,
		  'Gtk2' => 0,
		  'Exporter' => 5.57, # support use Exporter 'import';
		  'Scalar::Util' => 0,
		  },
              CONFIGURE_REQUIRES => { map {$_ => 0} @configure_requires },
	      CCFLAGS => $cflags,
	      $deps->get_makefile_vars,
	      @for_windows,
	      META_MERGE => {
	          resources => {
	              repository => 'https://github.com/ajolma/geoinformatica.git/trunk/Gtk2-Ex-Geo',
	          },
	      },
	      TEST_REQUIRES => {
	          'Test::More' => 0,
	      },
	      );

sub chk_module {
    my $pkg = shift;
    print "Checking for $pkg:";
    eval { 
	my $p; 
	($p = $pkg . ".pm") =~ s#::#/#g; 
	require $p; 
    };
    if ($@) {
	print " failed\n";
	return $pkg;
    } else {
	print " ok\n";
	return '';
    }
}

# -o on the compiler command line...


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


package MY;
use Cwd;
sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    $inherited .= ' -o $@';
    $inherited;
}

sub postamble {
    my $ret = '';
    my $lib = 'lib/Gtk2/Ex/Geo/';
    $lib = "lib/Gtk2/Ex/Geo/";
    for ('Glue', 'Dialogs') {
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
