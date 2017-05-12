package MegaDistro::InstallDeps;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(get_modules mod_install);

use lib './MegaDistro';

use MegaDistro::Config;
use MegaDistro::ParseList qw(get_modlist);
use CPANPLUS::Backend;
use Module::CoreList;
use Data::Dumper;

#use lib "$BUILDDIR";


our ( $cb, $conf );
my $init = 0;

#called internally to explicitly init the CPANPLUS stuff
sub init {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: init' . "\n";
	}

	if ( $args{'debug'} ) {
		print "\t" . 'Instantiating CPANPLUS::Backend object' . "\n";
	}

	# This can interfere with the operation of CPANPLUS.
	delete $ENV{MAKEFLAGS};
	
	#instantiate backend obj
	$cb = CPANPLUS::Backend->new;

	if ( $args{'debug'} ) {
		print "\t" . 'Instantiating CPANPLUS::Configure object' . "\n";
	}
	#instantiate configure obj
	$conf = $cb->configure_object;
	$conf->set_conf(
			  fetchdir   =>  $FETCHDIR,
			  extractdir =>  $EXTRACTDIR,
			  verbose    =>  $args{'verbose'},
			  skiptest   =>  0,
			  force      =>  0,
			  no_update  =>  1,
			  flush      =>  1,
			  prereqs    =>  3,
			  allow_build_interactivity => 0,
		       );
	if ( $args{'quiet'} ) {
		$conf->set_conf( makeflags => '--quiet' );
	}
	#FIXME: Change makemakerflags! (e.g. INST_LIB=VENDOR)
#	$conf->set_conf( makemakerflags => "PREFIX=$BUILDDIR" );
	$conf->set_conf( makemakerflags => "DESTDIR=$BUILDDIR/ INSTALLDIRS=vendor" );

	$init = 1;
}


sub get_modules {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: get_modules' . "\n";
	}

	&init if !$init;	  # explicitly init the CPANPLUS::Backend obj here
	my @modlist = &get_modlist;
	my @modobjs;

	if ( $args{'debug'} ) {
		print "\t" . 'Instantiating/Initializing CPANPLUS::Modules' . "\n";
	}
	@modobjs = $cb->module_tree(@modlist);

	return @modobjs;
}

##perform: fetch && extract && make && make test && make install
#sub make_install {	
#	if ( $args{'trace'} ) {
#		print 'MegaDistro::Install : Executing sub-routine: make_install' . "\n";
#	}
#
#	my ( $mod ) = @_;
#
##	if ( $args{'debug'} ) {
#		print "\t" . 'Processing module: ' . $mod->name . "\t";
##	}
#
#	my $bool;
#	if ( !$args{'verbose'} ) {
#		local *STDOUT;
#		local *STDERR;
#		open 'STDOUT', '>/dev/null';
#		open 'STDERR', '>/dev/null';
#		
#		$bool = $mod->install(
#					  target     =>  'install',
#					  skiptest   =>  0,
#				     );
#		close 'STDOUT';
#		close 'STDERR';
#	}
#	else {
#		$bool = $mod->install(
#					  target     =>  'install',
#					  skiptest   =>  0,
#				     );
#	}
#	print '[  ' . ($bool ? "Success!" : "Failure!") . '  ]' . "\n";
#	return $bool;
#}



# Start of new implementation #

our %modules;
our %Modules_Seen =      ();
our %Modules_Installed = ();


sub get_modobj {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: get_modobj' . "\n";
	}
	
	&init if !$init;
	my $modname = shift;
	if ( $args{'debug'} ) {
		print "\t" . 'Instantiating/Initializing CPANPLUS::Module : ' . $modname. "\n";
	}
	my $modobj = $cb->module_tree($modname);
	$modules{$modname} = $modobj;

	return $modobj;
}

sub get_moddeps {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: get_moddeps' . "\n";
	}

	my $mod = shift;
	
	$mod->prepare;
	my %prereqs = %{$mod->status->prereqs};	#TODO: add mod throwback safety -here-
#	foreach my $req (keys %prereqs) {
#		print $req . '=>' . $prereqs{$req} . "\n";
#	}

	my @moddeps;
	foreach my $dep (keys %prereqs) {
		push @moddeps, $dep if !&is_modcore($dep);
	}
	
	return @moddeps;
}

#TODO: perhaps, use an implementation which implies core updates?
sub is_modcore {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: is_modcore' . "\n";
	}
	
	my $module = shift;
#	my $mod = shift;
	my $mod = &get_modobj($module);
#	my $perlversion = sprintf("%vd", $^V);

#	print "Module: " . $mod->name . " is core: "; 
#	print Dumper $Module::CoreList::version{$]}{"Test::Harness"};

	return exists $Module::CoreList::version{$]}{$mod->name};
#	return Module::CoreList->first_release($mod->name);
#	return exists $Module::CoreList::version{$]}{$module};
#	return exists $Module::CoreList::version{$perlversion}{$mod->name};
#	return $mod->module_is_supplied_with_perl_core || $mod->package_is_perl_core;
}

sub mod_install {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: mod_install' . "\n";
	}
	
#	my $module = shift;
#	my $mod = &get_modobj($module);
	my $mod = shift;
#		return 1 if !$mod;
	
		print "\t" . 'Processing module: ' . $mod->name . "\t";
	
	my @moddeps = &get_moddeps($mod);
	$cb->flush('lib');
	use lib "$BUILDDIR";
	foreach my $dep (@moddeps) {
		print "\t\tResolving Dependency: $dep\n"; #if $args{'debug'};
		next if $Modules_Seen{$dep}++;
#		next if $Modules_Seen{$modules{$dep}->name}++;
		mod_install($modules{$dep});
	}

	if ( &mod_test($mod) ) {
		&force_install($mod);
		$Modules_Installed{$mod->name}++;
#		$Modules_Installed{$modules{$dep}->name}++;
		return 1;
	}
	else {
		warn $mod->name . " failed its tests.\n";	#should be debug-info [only] - handle externally ?
		return 0;
	}
}

sub mod_test {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: test' . "\n";
	}

	my $mod = shift;
	my $bool = $mod->test;
	return $bool;
}

sub force_install {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: force_install' . "\n";
	}
	
	my $mod = shift;
	my $bool = $mod->install(
					       target     =>  'install',
					       skiptest   =>  1,
					       force      =>  0,
					     );
	return $bool;
}

1;
