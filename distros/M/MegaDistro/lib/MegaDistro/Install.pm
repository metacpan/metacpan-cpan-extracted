package MegaDistro::Install;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(get_modules make_install);

use lib './MegaDistro';

use MegaDistro::Config qw(:default push_libs);
use MegaDistro::ParseList qw(get_modlist);
use CPANPLUS::Backend;
use Config;

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
	$conf->set_program( sudo     => '' );
	$conf->set_conf(
			  fetchdir   =>  $Conf{'fetchdir'},
			  extractdir =>  $Conf{'extractdir'},
#			  verbose    =>  $args{'verbose'},  #bugged 0.055, 0.0562 
#			  				    #conflicts with allow_build_interactivity
			  verbose    =>  0,
			  skiptest   =>  0,
			  force      =>  0,
			  no_update  =>  0,
			  prereqs    =>  3,
			  allow_build_interactivity => 0,
			  flush      =>  1,
#			  makeflags  => '--quiet', # only gnu make supports this option, apparently.
			  makemakerflags => "PREFIX=$Conf{'prefixdir'} INSTALLDIRS=vendor",
			  lib        => [
			                   MegaDistro::Config::prop_libs()
			                ]
		       );

	print 'Rebuilding module indicies...' . "\n";
	$cb->flush('all');

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

#perform: fetch && extract && make && make test && make install
sub make_install {

	my $mod = shift;

	#catch exceptions here, for non-init cpan mods that fall-thru
	if ( !$mod ) {
		printf "\n%18s", ' ';
		print '*Module was not found on cpan - skipping...';
		return 0;
	}

	printf "%-45s", $mod->name;	#print module name for process list

	if ( &is_modcore($mod) ) {	#check if the module is core
		printf "\n%18s", ' ';
		print '*Module is part of the perl core - skipping...';
		return 1;
	}

	&push_libs;	# is this necessary, with the CPANPLUS::Configure 'libs' attr set?
	
	my $bool = &make_test($mod);	 #test the module
	my $fool;
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: make_install' . "\n";
	}

	if ( !$bool && $args{'force'} ) {    # if tests failed, but --force is enabled
		printf "\n%18s", ' ';
		print '*Module failed one or more tests - forcing install...';
		$fool = &force_install($mod);
		$bool = $fool;
	}
	elsif ( !$bool ) {     # if tests failed
		print "\n";
		printf "%18s", ' ';
		print '*Module failed one or more tests - force install? (Y/N) ';
		my $force;
		do {
			$force = <>;
			printf "%56s", ' ';
		} while ($force !~ /^[YN]/i);
		if ( $force =~ /^[Y]/i ) {
			$fool = &force_install($mod);
			$bool = $fool;
		}
		else {
			$bool = 0;
		}
	}
	else {  # if tests pass
		$fool = &force_install($mod);
		$bool = $fool;

	}
	
	return $bool;    #return installation status of module, being processed
}

sub make_test {
	if ( $args{'trace'} ) {
		print 'MegaDistro::Install : Executing sub-routine: make_test' . "\n";
	}
	
	my $mod = shift;
	
	my $bool;
	if ( !$args{'verbose'} ) {
		local *STDOUT;
		local *STDERR;
		open 'STDOUT', '>/dev/null';
		open 'STDERR', '>/dev/null';
		$bool = $mod->test;
		close 'STDOUT';
		close 'STDERR';
	}
	else {
		$bool = $mod->test;
	}
	return $bool;
}

sub force_install {

	my $mod = shift;

	my $bool;
	if ( !$args{'verbose'} ) {
		local *STDOUT;
		local *STDERR;
		open 'STDOUT', '>/dev/null';
		open 'STDERR', '>/dev/null';
		
		$bool = $mod->install(
					  target     =>  'install',
					  skiptest   =>  1,
					  force      =>  1,
				     );
		
		close 'STDOUT';
		close 'STDERR';
	}
	else {
		$bool = $mod->install(
					  target     =>  'install',
					  skiptest   =>  1,
					  force      =>  1,
				     );
	
	}

	return $bool;
}

# method will settle compat (between 5.6 -> 5.8, at least)
sub is_modcore {
       my $mod = shift;
       return exists $Module::CoreList::version{$]}{$mod->name};
}

1;
