use 5.006;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use Config;
use strict;

use lib './plib' ;
use Makeutils ;

#use Data::Dumper ;

	my $clib = "./clib" ;

	# Set up info for this module
	my $modinfo_href = init('Linux-DVB-DVBT-Apps-QuartzPVR') ;

	# See if newer version is available
	check_new_version() ;

	## Options
	get_makeopts() ;

	## Programs to install
	add_install_progs("scripts/", [
		qw/dvbt-chans-sql dvbt-epg-sql dvbt-iplay dvbt-multirecord dvbt-record-mgr dvbt-qpvr-scan/
	]);


	## get distribution
	my $dist = distribution_info() ;

	## get webserver info
	my ($webuser, $webgroup, $webroot) = webserver_info($dist) ;
print "Dist=$dist, web=$webuser:$webgroup root=$webroot\n" if $makeutils::DEBUG ;	
	my %settings = (
	
		'WEB_USER'		=> $webuser,
		'WEB_GROUP'		=> $webgroup,
		'WEB_ROOT'		=> $webroot,
	) ;

	## read in existing install script settings
	my $install_script = "install/quartzpvr-install.pl" ;
	read_install_script($install_script, \%settings) ;

	## get settings from user
	get_settings(\%settings) ;
	
#print "Dist=$dist, web=$webuser:$webgroup root=$webroot\n" ;	
#print Data::Dumper->Dump(["Settings", \%settings]) ;

	## Update install
	update_install_script("install/tpl/quartzpvr-install.pl", $install_script, \%settings) ;

	## Do any cleanup
	process_makeopts() ;
	
	
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
	    NAME              => $modinfo_href->{'mod'},
	    VERSION_FROM      => "lib/$modinfo_href->{'modpath'}.pm", # finds $VERSION
	    PREREQ_PM         => {
			'File::Basename'	=> 0,
			'File::Path' 		=> 0,
			'File::Spec' 		=> 0,
			'POSIX'			=> 0,
			'Test::Pod::Coverage'	=> 1.08,
			'Pod::Coverage' => 0.18,
			'Test::Pod' => 1.22,
			'Data::Dumper' => 0,
			
			'Linux::DVB::DVBT' => 2.11,
			'Linux::DVB::DVBT::TS' => 0,
			'Linux::DVB::DVBT::Advert' => 0,
			'App::Framework' => 0,
			
			'Config::Crontab' => 0,
			'Date::Manip' => 0,
			
			'MP3::Tag' => 0,
			'DBI' => 0,
			'DBD::mysql' => 0,
			'Net::Server::Fork' => 0,
			
			
	    }, # e.g., Module::Name => 1.1
	    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	      (ABSTRACT_FROM  => "lib/$modinfo_href->{'modpath'}.pm", # retrieve abstract from module
	       AUTHOR         => 'Steve Price <cpan@quartz-net.co.uk>') : ()),
	    LIBS              => [], # e.g., '-lm'
	    INC               => $modinfo_href->{'includes'},
	    EXE_FILES         => $modinfo_href->{'programs'},
	);


	exit 0 ;


#-----------------------------------------------------------------------------------------------------------------------
sub MY::force
{
"
# Phony target to force checking subdirectories.
FORCE :
	\$(NOECHO) \$(NOOP)

## Call to QuartzPVR installation script
pure_perl_install :: 
	$^X $install_script -perl_lib \$(DESTINSTALLPRIVLIB) -perl_scripts \$(DESTINSTALLSCRIPT) -pm_version \$(VERSION)

pure_site_install :: 
	$^X $install_script -perl_lib \$(DESTINSTALLSITELIB) -perl_scripts \$(DESTINSTALLSITESCRIPT) -pm_version \$(VERSION)

pure_vendor_install :: 
	$^X $install_script -perl_lib \$(DESTINSTALLVENDORLIB) -perl_scripts \$(DESTINSTALLVENDORSCRIPT) -pm_version \$(VERSION)

" ;
}


#-----------------------------------------------------------------------------------------------------------------------
sub MY::makemakerdflt 
{
	my $makemakerdflt = get_makemakerdflt() ;
	return $makemakerdflt ;
}

#-----------------------------------------------------------------------------------------------------------------------
sub MY::postamble {
'

## Optional doxygen documentation 
doxygen: FORCE
	cd doxygen && doxygen

## Author target: preview CPAN documentation
cpandoc: FORCE
	$(MAKEPATH) pod/batch
	perl -MPod::Simple::HTMLBatch -e Pod::Simple::HTMLBatch::go . pod/batch
	$(ABSPERLRUN) -MExtUtils::Command -e "cp" -- pod/html_files/style.css pod/batch/_black_with_blue_on_white.css

phpdoc: FORCE
	perl -MPod::Simple::HTMLBatch -e Pod::Simple::HTMLBatch::go php/doc/src php/doc/pod

MANIFEST: FORCE
	$(ABSPERLRUN) -MExtUtils::Command -e "mv" -- MANIFEST MANIFEST.bak
	$(ECHO) "MANIFEST" >>MANIFEST
	$(ECHO) "README" >>MANIFEST
	$(ECHO) "COPYING" >>MANIFEST
	$(ECHO) "Changes" >>MANIFEST
	$(ECHO) "Makefile.PL" >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "plib/Makeutils.pm" >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "index.php" >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "tpl/grid.tpl" >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## JS" >>MANIFEST
	find js -type f -name "*.js" | grep -v .svn >>MANIFEST
	find js -type f -name "*.txt" | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## Tests" >>MANIFEST
	find t -type f -name "*.t" | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## CSS" >>MANIFEST
	find css -type f -name "*.css" | grep -v .svn >>MANIFEST
	find css -type f -name "*.png" | grep -v src | grep -v .svn >>MANIFEST
	find css -type f -name "*.gif" | grep -v src | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## PHP" >>MANIFEST
	find php -type f -name "*.inc" | grep -v .svn >>MANIFEST
	find php -type f -name "*.php" | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## Install" >>MANIFEST
	find install -type f | grep -v install/quartzpvr-install | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## lib" >>MANIFEST
	find lib -type f -name "*.pm" | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## Scripts" >>MANIFEST
	find scripts -type f -name "dvbt-*" | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST
	$(ECHO) "## Doc" >>MANIFEST
	find php -type f -name "*.html" | grep -v pod | grep -v .svn >>MANIFEST
	find php -type f -name "*.png" | grep -v src | grep -v .svn >>MANIFEST
	$(ECHO) "" >>MANIFEST

';
}


#----------------------------------------------------------------------
# Work out/guess distribution
#
sub distribution_info
{
#print "distribution_info\n" ;		
	my $dist ;
	my $reldir = '/etc' ;
	foreach my $rel (glob("$reldir/*-release"))
	{
#print "Dist dir: $rel\n" ;		
		if ($rel =~ m%^$reldir/(\w+)\-release%)
		{
			my $this_dist = $1 ;
#print " + dist file $this_dist\n" ;		
			if ($this_dist eq 'lsb')
			{
			    if (open my $fh, "<$rel")
			    {
				    my $info = '';
				    while (defined($info=<$fh>))
				    {
				        chomp $info;
				        if ($info =~ m/DISTRIB_ID\s*=\s*(.*)/)
				        {
				        	$dist = lc $1 ;
#print " + + dist = $dist\n" ;		
				        	last ;
				        }
				    }
			    }
			}
			else
			{
				$dist = lc $this_dist ;
				last ;
			}
		}
	}
	return $dist ;
}

#----------------------------------------------------------------------
# Work out webserver user
#
sub webserver_info
{
	my ($dist) = @_ ;
#print "web_info($dist)\n" ;		
	
	## user
	my ($webuser, $webgroup) ;
	foreach my $server (qw/apache http/)
	{ 
#print " + server $server\n" ;		
		my @results = `ps -ef | grep -i $server | grep -v grep` ;
		foreach my $line (@results)
		{
			chomp $line ;
#print " + + $line\n" ;		
			if ($line =~ /^(\S+)\s+/)
			{
				my $user = $1 ;
#print " + + + user=$user\n" ;		
				if ($user ne 'root')
				{
					## Check valid user and get group if so
					# account:password:UID:GID:GECOS:directory:shell
					my @ufields = getpwnam($user) ;
					if (@ufields >= 7)
					{
						my $gid = $ufields[3] ;
						
						# group_name:passwd:GID:user_list
						my $grp = getgrgid($gid);
						if ($grp)
						{
							## got user & group
							$webuser = $user ;
							$webgroup = $grp ;

#print " + + + webuser=$webuser webgroup=$webgroup\n" ;

							last ;
						}
					}
				}
			}
			last if $webuser ;
			
		} # each line
		
		last if $webuser ;
		
	} # each server
	
	## server root
	my $webroot = "/var/www" ;
	if ($dist eq 'suse')
	{
		$webroot = "/srv/www/htdocs" ;
	}
	
	
	return ($webuser, $webgroup, $webroot) ;
}

#----------------------------------------------------------------------
sub _get_settings
{
	my ($settings_href, $settings_def, $get_val) = @_ ;

	foreach my $aref (@$settings_def)
	{
		my ($var, $null_valid, $default, $desc) = @$aref ;
#		print "Default=$default\n" ;

		## Amend defaults with existing settings
		if ($settings_href->{$var})
		{
			$default = $settings_href->{$var} ;
		}
		my $val = "$default" ;
		
		my $prefix = "" ;
		if ($desc =~ s/^\s*Debug:\s*//i)
		{
			$prefix = " [DEBUG]" ;
		}
		
		if ($get_val)
		{
			do
			{
				print "$var:$prefix Please enter the $desc [$val]: " ;
				my $ans = <STDIN> ;
				chomp $ans ;
				if ($ans)
				{
					$val = $ans ;
				}
			
			} while (!length($val) && !$null_valid) ;
		}
		
		# ensure settings are set to either user-supplied value or default
		$settings_href->{$var} = $val ;
	}
}


#----------------------------------------------------------------------
sub get_settings
{
	my ($settings_href) = @_ ;
	
	## List of settings that either require user input or may need checking by the user
	my @settings = (
# var					can be null?	default										description
[ "SQL_ROOT_PASSWORD",	0,				"e.g. password",							"MySQL root user password so I can create the pvr database"],
[ "DVBT_FREQFILE",		0,				"e.g. /usr/share/dvb/dvb-t/uk-Oxford",		"full path to DVB-T tuning frequency file OR a country code (GB)"],
[ "MAIL_TO", 			1,				$ENV{'user'} || 'e.g. root@somewhere',		"email account to mail PVR errors to"],
[ "WEB_USER", 			0,				$settings_href->{'WEB_USER'},				"user name of the web server"],
[ "WEB_GROUP", 			0,				$settings_href->{'WEB_GROUP'},				"group name of the web server"],
	) ;

	my $pvr_top = "/var/lib/quartzpvr" ;
	
	## List of settings that can be left to their default values
	my @extra_settings = (
# var					can be null?	default										description
[ "SERVER_PORT", 		0,				"21328",									"TCP port of the new PVR server that I will install"],
[ "SQL_USER", 			0,				"quartzpvr",								"username of the MySQL pvr database owner"],
[ "SQL_PASSWORD",		0,				"qp".$$,									"password of the MySQL pvr database owner"],
[ "PVR_USER", 			0,				"quartzpvr",								"Linux user name created for recording"],
[ "PVR_GROUP", 			0,				"video",									"Linux group name for PVR_USER"],
[ "PVR_LOGDIR", 		0,				"/var/log/quartzpvr",						"location of PVR logs"],
[ "DATABASE", 			0,				"quartzpvr",								"PVR database name"],
[ "VIDEO_DIR", 			0,				"$pvr_top/video",							"Video recording top-level directory"],
[ "AUDIO_DIR", 			0,				"$pvr_top/audio",							"Audio recording top-level directory"],
[ "VIDEO_TRASH",		0,				"$pvr_top/video/.TRASH",					"Video temporary files directory"],
[ "VIDEO_PATH",			0,				"\$video_dir/\$title/\$tva_series/\$YmdHMS-\$name.ts",	"Video recording filename specification"],
[ "AUDIO_PATH",			0,				"\$audio_dir/\$title/\$series/\$YmdHMS-\$name.mp3",	"Audio recording filename specification"],
[ "PVR_ROOT", 			0,				"$settings_href->{'WEB_ROOT'}/quartzpvr", 	"Installation directory. This is where all of the PVR software is installed."],
[ "ADAPTERS", 			1,				"", 										"Space separated list of the adapter numbers to use (leave blank for default)"],
[ "ADSKIP", 			0,				"1", 										"Advert removal (1=remove adverts, 0=do not remove adverts)"],
[ "DATE_TZ", 			0,				"Europe/London",							"Your timezone (as defined for the PHP Date object)"],
[ "PHP_SEARCH",			0,				"0",										"Allow use of other installed PHP (may cause name clashes)"],
[ "PHP_LOG", 			1,				"", 										"Debug: Log file to use for PHP application"],
[ "SERVER_DEBUG",		0,				"1", 										"Debug: Level of server debug logging"],
	) ;
	
	
	$settings_href->{'PERL_BIN'} = $^X ;
	$settings_href->{'PVR_HOME'} = "/var/lib/$settings_href->{'PVR_USER'}" ;
	
#print Data::Dumper->Dump(["Settings", \%settings]) ;	
	
	 
	## get any new settings
	_get_settings($settings_href, \@settings, 1) ;
	
	## Ask if user wants to amend the extra settings
	my $get_extra = 0 ;
	print "\nWould you like to use defaults for the next set of settings [yes]: " ;
	my $ans = <STDIN> ;
	if ($ans =~ /no/i)
	{
		$get_extra = 1 ;
	}

	## get any default settings
	_get_settings($settings_href, \@extra_settings, $get_extra) ;
	
	## Get the list of all variables
	my $vars_list = "" ;
	foreach my $aref (@settings)
	{
		my ($var, $null_valid, $default, $desc) = @$aref ;
		$vars_list .= "$var " ;
	}
	foreach my $aref (@extra_settings)
	{
		my ($var, $null_valid, $default, $desc) = @$aref ;
		$vars_list .= "$var " ;
	}
	
	# list of fixed settings
	$vars_list .= "   " ;
	foreach my $var (qw/
		RECPROG IPLAYPROG 
		PERL_SCRIPTS PERL_LIB PERL_BIN
		TBL_LISTINGS TBL_RECORD TBL_CHANNELS TBL_RECORDING TBL_RECORDED TBL_SCHEDULE TBL_MULTIREC TBL_IPLAY
		PVR_HOME
	/)
	{
		$vars_list .= "$var " ;
	}
	
	$settings_href->{'_VARS_LIST_'} = $vars_list ;
	
}


#----------------------------------------------------------------------
sub update_install_script
{
	my ($tpl_install_script, $install_script, $settings_href) = @_ ;

	## Read in file
	my @lines ;
	{
	    local( $/ ) ;
    	open( my $fh, $tpl_install_script ) or die "Error: reading install script file $tpl_install_script : $!" ;
		my $lines = <$fh> ;
		close $fh ;

		@lines = split(/\n/, $lines) ;
	}

	## Amend config data section
	my $config_line = 0 ;
	for ($config_line = 0 ; $config_line < @lines; ++$config_line)
	{
#		print "$config_line :: $lines[$config_line]\n" ;
		if ($lines[$config_line] =~ /^\s*__DATA__\s+config/)
		{
#			print " >>>> Found config!\n" ;
			last ;
		}
	}
	$#lines = ++$config_line ;
	
	foreach my $var (sort keys %$settings_href)
	{
		my $val = $settings_href->{$var} ;
		
		# use % instead of $ to ensure App does not attempt to expand variables
		$val =~ s/\$/%/g ; 
		
		push @lines, "$var = $val" ;
	}
	
	
	## Write file
   	open( my $fh, ">$install_script" ) or die "Error: writing install script file $install_script : $!" ;
	foreach (@lines)
	{
		print $fh "$_\n" ;
	}
	close $fh ;

	## Protect file
	chmod 0700, $install_script ;

}


#----------------------------------------------------------------------
sub read_install_script
{
	my ($install_script, $settings_href) = @_ ;

	return if (! -f $install_script) ;

	## Read in file
	my @lines ;
	{
	    local( $/ ) ;
    	open( my $fh, $install_script ) or die "Error: reading install script file $install_script : $!" ;
		my $lines = <$fh> ;
		close $fh ;

		@lines = split(/\n/, $lines) ;
	}

	## Amend config data section
	my $config_line = 0 ;
	for ($config_line = 0 ; $config_line < @lines; ++$config_line)
	{
		if ($lines[$config_line] =~ /^\s*__DATA__\s+config/)
		{
			last ;
		}
	}
	

	for (++$config_line ; $config_line < @lines; ++$config_line)
	{
		if ($lines[$config_line] =~ /^\s*(\w+)\s*=\s*(.*)/)
		{
			my ($var, $val) = ($1, $2) ;
			$val =~ s/\s+$// ;
			$val =~ s/%/\$/g ;
			$settings_href->{$var} = $val ;
		}
	}


}

