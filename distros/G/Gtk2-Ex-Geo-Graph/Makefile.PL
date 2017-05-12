use 5.008003; # support use Exporter 'import';
use Config;
use ExtUtils::MakeMaker;

my %missing_modules;

$missing_modules{chk_module('Gtk2::Ex::Geo', 0.62)} = 1;
$missing_modules{chk_module('Graph')} = 1;

delete $missing_modules{''};

my @missing_modules = keys %missing_modules;
print "Following required/optional modules are missing: @missing_modules\n" if @missing_modules;
exit 0 if @missing_modules;

require ExtUtils::Depends;
#require ExtUtils::PkgConfig;

our $deps = ExtUtils::Depends->new('Gtk2::Ex::Geo::Graph', 'Gtk2::Ex::Geo');

our %pm_files = (
		 'lib/Gtk2/Ex/Geo/Graph.pm'  => '$(INST_LIBDIR)/Geo/Graph.pm',
);

$deps->add_pm (%pm_files);

$deps->save_config ('Files.pm');

WriteMakefile(
	      NAME              => 'Gtk2::Ex::Geo::Graph',
	      VERSION_FROM      => 'lib/Gtk2/Ex/Geo/Graph.pm',
	      ABSTRACT_FROM   => 'lib/Gtk2/Ex/Geo/Graph.pm', # retrieve abstract from module
	      AUTHOR          => 'Ari Jolma <ari.jolma @ tkk.fi>',
	      PREREQ_PM         => {
		  'Gtk2::Ex::Geo' => 0,
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
