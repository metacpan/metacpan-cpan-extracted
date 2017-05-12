#!/usr/bin/perl
#
use strict ;

# Local
use App::Framework '+Sql +Run' ;
use Config::Crontab ;

use Linux::DVB::DVBT ;


## MySQL tables current versions
our %table_versions = (
	'database'		=> '1.00',
	'channels'		=> '1.01',
	'iplay'			=> '1.00',
	'listings'		=> '1.00',
	'multirec'		=> '1.00',
	'record'		=> '1.00',
	'recorded'		=> '1.00',
	'schedule'		=> '1.00',
) ;


# VERSION
our $VERSION = '2.03' ;
our $DEBUG = 0 ;

	# Create application and run it
	App::Framework->new() ;
	go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $args_href) = @_ ;
	
	$DEBUG = $opts_href->{'debug'} ;
	
	my %settings = get_config($app) ;
	foreach my $var (qw/perl_lib perl_scripts pm_version/)
	{
		$settings{$var} = $opts_href->{$var} ;
		$settings{uc $var} = $opts_href->{$var} ;
	}
	
$app->prt_data("Settings", \%settings) if $DEBUG ;

	## Must run this script as root
	if ($>) 
	{
		print STDERR "Error: This script must be run as root\n" ;
		exit 1 ;
	}
	
	my $webowner = "$settings{WEB_USER}:$settings{WEB_GROUP}" ;
	my $pvrowner = "$settings{PVR_USER}:$settings{PVR_GROUP}" ;

	## Create PVR user
	create_pvr_user($app, \%settings) ;

	## Create database
	create_database($app, \%settings) ;
	
	## Create dirs
	create_dirs($app, \%settings) ;
	
	## Copy files
	## Set privileges
	my @dirs = (
		['css',		$webowner, 0644],
		['js',		$webowner, 0644],
		['php',		$webowner, 0644],
		['tpl',		$webowner, 0644],
	) ;
	install_files($app, \%settings, \@dirs) ;
	
	## Amend template files
	template_files($app, \%settings, "install/templates.txt") ;
	
	## Start server
	start_server($app, \%settings) ;
	
	## Do dvb-t scan
	if ( dvbt_scan($app, \%settings) )
	{
		## Set channels
		dvbt_channels($app, \%settings) ;
		
		## Get listings
		dvbt_listings($app, \%settings) ;
		
	}
	else
	{
		print "!! Please re-run after adding a DVB-T adapter, I can then update the channel information and the EPG !!\n" ;
	}	
}

#----------------------------------------------------------------------
# PVR Linux user
#
sub create_pvr_user
{
	my ($app, $settings_href) = @_ ;
	
	print "Creating user ..\n" ;
	
	my $user = $settings_href->{'PVR_USER'} ;
	my $group = $settings_href->{'PVR_GROUP'} ;
	my $home = $settings_href->{'PVR_HOME'} ;
	my $perl_scripts = $settings_href->{'PERL_SCRIPTS'} ;
	my $logdir = $settings_href->{'PVR_LOGDIR'} ;
	
#	my $uid = getpwnam($user) ; 
	my ($uname, $upasswd, $uid, $ugid, $quota,
		$comment, $gcos, $dir, $shell) = getpwnam($user) ; 
	my ($gname,$gpasswd,$gid,$members) = getgrnam($group) ;
	
print "user=$user : uid=$uid name=$uname gid=$ugid dir=$dir\n" if $DEBUG ;
print "group=$group : name=$gname gid=$gid members='$members'\n" if $DEBUG ;
	
	## Create group if required
	if (!$gid)
	{
		runit($app,
			"groupadd $group",
			"Creating group $group",
		) ;
	}
	
	## Create user if required
	my $system_user = 0 ;
	if (!$uid)
	{
		runit($app,
			"useradd -c 'Quartz PVR' -r -d $home -m -k /dev/null -g $group $user",
			"Creating user $user",
		) ;
		$system_user=1 ;
	}

	($uname, $upasswd, $uid, $ugid, $quota,
		$comment, $gcos, $dir, $shell) = getpwnam($user) ; 
	($gname,$gpasswd,$gid,$members) = getgrnam($group) ;
	
print "NOW user=$user : uid=$uid name=$uname gid=$ugid dir=$dir\n" if $DEBUG ;
print "NOW group=$group : name=$gname gid=$gid members='$members'\n" if $DEBUG ;
	
	## Add user to group if required
	# check user's primary group id matches group id
	# OR user is in the members list of the group
	if ( ($ugid != $gid) && ($members !~ /\b$user\b/) )
	{
		my $stat = try_runit($app,
			"usermod -a -G $group $user"
		) ;
		if ($stat)
		{
			runit($app,
				"usermod -A -G $group $user",
				"Adding user $user to group $group",
			) ;
		}
	}

	## Ensure crontab is initialised
	my $crontag = "@[dvbt-update]" ;
	my %blocks = (
		"# $crontag Update the EPG" => {
				-active		=> 1,
				-minute 	=> 7,
				-hour	 	=> 4,
				-dow	 	=> "*",
				-month	 	=> "*",
				-dom	 	=> "*",
				-command	=> "$perl_scripts/dvbt-epg-sql >> $logdir/dvbt_epg.log 2>&1",
		},
		"# $crontag Update the scheduled programs" => {
				-active		=> 1,
				-minute 	=> 7,
				-hour	 	=> 6,
				-dow	 	=> "*",
				-month	 	=> "*",
				-dom	 	=> "*",
				-command	=> "$perl_scripts/dvbt-record-mgr -dbg-trace all -report 1 >> $logdir/dvb_record_mgr.log 2>&1",
		},
		"# $crontag Clean out trash" => {
				-active		=> 1,
				-minute 	=> 0,
				-hour	 	=> 0,
				-dow	 	=> "*",
				-month	 	=> "*",
				-dom	 	=> "*",
				-command	=> "find $settings_href->{VIDEO_TRASH} -mtime +7|xargs -i rm -rf '{}' 2>&1",
		},
	
	) ;

	my $crontag_re = $crontag ;
	$crontag_re =~ s/([\[\@\-])/\\$1/g ;

	my $ct = new Config::Crontab( -owner => $user );
	$ct->read() ;
	my @dvbt_blocks = $ct->select(
								-type		=> 'comment',
								-data_re	=> $crontag_re, 
								) ;
								
Linux::DVB::DVBT::prt_data("dvbt_blocks=", \@dvbt_blocks) if $DEBUG ;

	if (@dvbt_blocks)
	{
		foreach my $block ($ct->blocks)
		{
			my $tag = "" ;
			foreach my $comment ($block->select(-type => 'comment'))
			{
				$tag = $comment->data() ;
			}
			if ($tag)
			{
				next if $tag !~ /$crontag_re/ ;
				foreach my $event ($block->select(-type => 'event'))
				{
					foreach my $field (qw/minute hour dom month dow/)
					{
						$blocks{$tag} ||= {} ;
						$blocks{$tag}{"-$field"} = $event->$field() ;
					}
				}
		
				## Remove existing block
				$ct->remove($block) ;
			}			
		}
	}

Linux::DVB::DVBT::prt_data("Blocks=", \%blocks) if $DEBUG ;

	foreach my $comment (keys %blocks)
	{
		## Add block to crontab
		my $block = new Config::Crontab::Block ;
		$block->last(new Config::Crontab::Comment($comment)) ;
		$block->last(new Config::Crontab::Event(%{ $blocks{$comment} })) ;

		$ct->first($block) ;

	}
	## Write crontab
	$ct->write()    
	  or do {
        warn "Error: " . $ct->error . "\n";
      };

	print " * Written crontab\n" ;	      



	
	## Clear out any previous logs
	foreach my $log (glob("$home/*.log"))
	{
		if (-f $log)
		{
			unlink $log ;
		}
	}
	
}

#======================================================================
# MYSQL
#======================================================================


#----------------------------------------------------------------------
# MySQL
#
#
sub create_database
{
	my ($app, $settings_href) = @_ ;

	print "Setting up MySQL ..\n" ;
	
	my ($results_aref, $status) ;
	my $sql ;
	my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
	
	## Check for user
	$sql =<<SQL ;
SELECT user from mysql.user where user='$settings_href->{SQL_USER}';
SQL
	$results_aref = mysql_runit($app, $password, $sql, "MySQL error while checking for user") ;

	my $create_user = 1 ;
	if (@$results_aref)
	{
		$create_user = 0 ;
	}
	
	
	## Create user if required
	if ($create_user)
	{
		print " * Create user $settings_href->{SQL_USER}\n" ;
		
		$sql =<<SQL ;
	
CREATE USER '$settings_href->{SQL_USER}'\@'localhost' IDENTIFIED BY  '$settings_href->{SQL_PASSWORD}';
GRANT USAGE ON * . * TO  '$settings_href->{SQL_USER}'\@'localhost' IDENTIFIED BY  '$settings_href->{SQL_PASSWORD}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `$settings_href->{DATABASE}` /*!40100 DEFAULT CHARACTER SET latin1 */;
GRANT ALL PRIVILEGES ON  `$settings_href->{DATABASE}` . * TO  '$settings_href->{SQL_USER}'\@'localhost' WITH GRANT OPTION ;

SQL
	}
	else
	{
		print " * Update user $settings_href->{SQL_USER}\n" ;
		$sql =<<SQL ;
	
SET PASSWORD FOR '$settings_href->{SQL_USER}'\@'localhost' = PASSWORD('$settings_href->{SQL_PASSWORD}') ;
GRANT USAGE ON * . * TO  '$settings_href->{SQL_USER}'\@'localhost' IDENTIFIED BY  '$settings_href->{SQL_PASSWORD}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `$settings_href->{DATABASE}` /*!40100 DEFAULT CHARACTER SET latin1 */;
GRANT ALL PRIVILEGES ON  `$settings_href->{DATABASE}` . * TO  '$settings_href->{SQL_USER}'\@'localhost' WITH GRANT OPTION ;

SQL
	}
	$results_aref = mysql_runit($app, $password, $sql, "MySQL error while creating database") ;


	## Check for versions
	my %versions = (
		'database'		=> '0',
		'channels'		=> '0',
		'iplay'			=> '0',
		'listings'		=> '0',
		'multirec'		=> '0',
		'record'		=> '0',
		'recorded'		=> '0',
		'schedule'		=> '0',
	) ;

	my $got_versions = 0 ;

	$sql =<<SQL ;
SELECT `item`,`version` from $settings_href->{DATABASE}.versions ;
SQL
	($results_aref, $status) = mysql_try_runit($app, $password, $sql) ;
	
	if ($status == 0)
	{
		if (@$results_aref)
		{
			$got_versions = 1 ;
			foreach my $line (@$results_aref)
			{
				if ($line =~ /(\S+)\s+([\d\.]+)/)
				{
					my ($var, $ver) = ($1, $2) ;
					next if $var eq 'item' ;
					$versions{$var} = $ver ;
				}
			}
		}
	}
	

	## Check for listings
	my $got_listings = 0 ;
	$sql =<<SQL ;
SELECT * from $settings_href->{DATABASE}.listings LIMIT 1 ;
SQL
	($results_aref, $status) = mysql_try_runit($app, $password, $sql) ;
	
	if ($status == 0)
	{
		if (@$results_aref)
		{
			$got_listings = 1 ;
		}
	}

	if ($got_listings)
	{
		print "Already got listings table, checking table versions...\n" ;
		
		foreach my $table (qw/channels iplay listings multirec record recorded schedule/)
		{
			my $current_ver = $versions{$table} ;
			my $latest_ver = $table_versions{$table} ;
			if ($current_ver ne $latest_ver)
			{
				no strict 'refs' ;
				print " * Updating table '$table'\n" ;
				
				my $update_fn = "update_table_$table" ;
				&$update_fn($app, $settings_href, $current_ver, $latest_ver) ;
			}
		}
		
		## Ensure versions table exists
		$sql = $app->data("versions.sql") ;
		$sql =~ s/\%DATABASE\%/$settings_href->{'DATABASE'}/g ;
		
		mysql_runit($app, $password, $sql, "MySQL error while creating versions table") ;
	}
	else
	{
		print "Creating new tables ..\n" ;

		## Create tables	
		$sql = $app->data("sql") . $app->data("versions.sql") ;
		$sql =~ s/\%DATABASE\%/$settings_href->{'DATABASE'}/g ;
		
		mysql_runit($app, $password, $sql, "MySQL error while creating tables") ;
	}
	
	update_table_versions($app, $settings_href, \%table_versions)
}

#----------------------------------------------------------------------
sub update_table_versions
{
	my ($app, $settings_href, $latest_versions_href) = @_ ;

	my $table = 'versions' ;
	my $sql = "" ;
	foreach my $item (keys %$latest_versions_href)
	{
		$sql .= "UPDATE $settings_href->{DATABASE}.$table SET `version`='$latest_versions_href->{$item}' where `item` = '$item';\n" ;
	}

	my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
	mysql_runit($app, $password, $sql, "MySQL error while updating table '$table' to set latest versions") ;
}





#----------------------------------------------------------------------
sub update_table_channels
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	my $table = 'channels' ;
	if ($existing_version lt '1.01')
	{
		my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
		my $sql =<<SQL ;
ALTER TABLE  $settings_href->{DATABASE}.$table CHANGE  `chan_type` `chan_type` set('tv','radio','hd-tv') NOT NULL DEFAULT 'tv' COMMENT 'TV or Radio' ;
SQL
		mysql_runit($app, $password, $sql, "MySQL error while updating table '$table' to version $latest_version") ;
		
	}
}

#----------------------------------------------------------------------
sub update_table_iplay
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	# no op
}

#----------------------------------------------------------------------
sub update_table_listings
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	# no op
}

#----------------------------------------------------------------------
sub update_table_multirec
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	my $table = 'multirec' ;
	if ($existing_version eq '0')
	{
		my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
		my $sql =<<SQL ;
ALTER TABLE  $settings_href->{DATABASE}.$table CHANGE  `adapter`  `adapter` VARCHAR( 16 ) NOT NULL DEFAULT  '0' ;
SQL
		mysql_runit($app, $password, $sql, "MySQL error while updating table '$table' to version $latest_version") ;
		
	}
}

#----------------------------------------------------------------------
sub update_table_record
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	my $table = 'record' ;
	if ($existing_version eq '0')
	{
		my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
		my $sql =<<SQL ;
ALTER TABLE  $settings_href->{DATABASE}.$table DROP `episode`, DROP `num_episodes`, DROP `adapter` ;
SQL
		mysql_try_runit($app, $password, $sql) ;
		
	}
}

#----------------------------------------------------------------------
sub update_table_recorded
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	my $table = 'recorded' ;
	if ($existing_version eq '0')
	{
		my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
		my $sql =<<SQL ;
ALTER TABLE  $settings_href->{DATABASE}.$table CHANGE  `adapter`  `adapter` VARCHAR( 16 ) NOT NULL DEFAULT  '0' ;
SQL
		mysql_runit($app, $password, $sql, "MySQL error while updating table '$table' to version $latest_version") ;
		
	}
}

#----------------------------------------------------------------------
sub update_table_schedule
{
	my ($app, $settings_href, $existing_version, $latest_version) = @_ ;

	my $table = 'schedule' ;
	if ($existing_version eq '0')
	{
		my $password = $settings_href->{'SQL_ROOT_PASSWORD'} ;
		my $sql =<<SQL ;
ALTER TABLE  $settings_href->{DATABASE}.$table CHANGE  `adapter`  `adapter` VARCHAR( 16 ) NOT NULL DEFAULT  '0' ;
SQL
		mysql_runit($app, $password, $sql, "MySQL error while updating table '$table' to version $latest_version") ;
		
	}
}



#======================================================================
# INSTALL
#======================================================================

#----------------------------------------------------------------------
# Directories
#
sub create_dirs
{
	my ($app, $settings_href) = @_ ;
	
	print "Creating directories:\n" ;

	my $web_uid = getpwnam($settings_href->{'WEB_USER'}) ;
	my $web_gid = getgrnam($settings_href->{'WEB_GROUP'}) ;
	
	my $pvr_uid = getpwnam($settings_href->{'PVR_USER'}) ;
	my $pvr_gid = getgrnam($settings_href->{'PVR_GROUP'}) ;
	
	## Web
	foreach my $d (qw/PVR_ROOT/)
	{
		my $dir = $settings_href->{$d} ;
		if (! -d $dir)
		{
			print " * $dir .. ($settings_href->{'WEB_USER'}:$settings_href->{'WEB_GROUP'})\n" ;
			if (!mkpath([$dir], 0, 0755))
			{
				print "ERROR unable to create dir $dir : $!" ;
				exit 1 ;
			}
			chown $web_uid, $web_gid, $dir ;
		}
	}
	
	## PVR
	foreach my $d (qw/VIDEO_DIR VIDEO_TRASH AUDIO_DIR PVR_LOGDIR PVR_HOME/)
	{
		my $dir = $settings_href->{$d} ;
		if (! -d $dir)
		{
			print " * $dir .. ($settings_href->{'PVR_USER'}:$settings_href->{'PVR_GROUP'})\n" ;
			if (!mkpath([$dir], 0, 0755))
			{
				print "ERROR unable to create dir $dir : $!" ;
				exit 1 ;
			}
			chown $pvr_uid, $pvr_gid, $dir ;
		}
	}

#	## Subdirs
#	my $dir = "VIDEO_DIR" ;
#	foreach my $d (qw/TRASH/)
#	{
#		my $dir = "$settings_href->{$dir}/$d" ;
#		if (! -d $dir)
#		{
#			print " * $dir .. ($settings_href->{'PVR_USER'}:$settings_href->{'PVR_GROUP'})\n" ;
#			if (!mkpath([$dir], 0, 0755))
#			{
#				print "ERROR unable to create dir $dir : $!" ;
#				exit 1 ;
#			}
#			chown $pvr_uid, $pvr_gid, $dir ;
#		}
#		
#	}

	# pvr server
	foreach my $dir (qw%/var/run/quartzpvr%)
	{
		if (! -d $dir)
		{
			print " * $dir .. ($settings_href->{'PVR_USER'}:$settings_href->{'PVR_GROUP'})\n" ;
			if (!mkpath([$dir], 0, 0755))
			{
				print "ERROR unable to create dir $dir : $!" ;
				exit 1 ;
			}
			chown $pvr_uid, $pvr_gid, $dir ;
		}
	}
}

#----------------------------------------------------------------------
# Install
#
sub install_files
{
	my ($app, $settings_href, $dirs_aref) = @_ ;
	
	my $dest = $settings_href->{'PVR_ROOT'} ;
	
	print "Installing files:\n" ;
	
	foreach my $aref (@$dirs_aref)
	{
		my ($dir, $owner) = @$aref ;
		
		## copy directory
		print " * Installing files from $dir .. " ;
		runit($app,
			"cp -pr $dir $dest",
			"copying files from $dir"
		) ;
		print "done\n" ;
		
#		$app->run("cp -pr $dir $dest") ;
#		print "done\n" ;
#		my $status = $app->run()->status ;
#		if ($status)
#		{
#			print "Error copying files from $dir\n" ;
#			exit 1 ;
#		}
		
		## Set ownership
		runit($app,
			"chown -R $owner $dest/$dir",
			"setting ownership of $dest/$dir to $owner"
		) ;

#		$app->run("chown -R $owner $dest/$dir") ;
#		$status = $app->run()->status ;
#		if ($status)
#		{
#			print "Error setting ownership of $dest/$dir to $owner\n" ;
#			exit 1 ;
#		}
	}
	
	## Copy index file 
	runit($app,
		"cp index.php $dest",
		"copying index.php to $dest"
	) ;
	

}

#----------------------------------------------------------------------
# Templates
#
sub template_files
{
	my ($app, $settings_href, $template_file) = @_ ;
	
	my %vars = (%$settings_href) ;
	
	$vars{'uid'} = $< ;
	$vars{'gid'} = $( ;
	
	$vars{'web_uid'} = getpwnam($settings_href->{'WEB_USER'}) ; 
	$vars{'web_gid'} = getgrnam($settings_href->{'WEB_GROUP'}) ;
	$vars{'pvr_uid'} = getpwnam($settings_href->{'PVR_USER'}) ; 
	$vars{'pvr_gid'} = getgrnam($settings_href->{'PVR_GROUP'}) ;
	$vars{'pvrdir'} = $settings_href->{'PVR_ROOT'} ;
	foreach my $field (keys %$settings_href)
	{
		$vars{lc $field} = $settings_href->{$field} ;
	}

$app->prt_data("template_files() : vars=", \%vars) if $DEBUG >= 2 ;

	## read in control file
	my @templates ;
	my $line ;
	open my $fh, "<$template_file" or die "Error: Unable to read template control file $template_file : $!" ;
	while (defined($line=<$fh>))
	{
		chomp $line ;
		next if $line =~ m/^\s*#/ ;
		
		# "php/Config/Constants.inc", "$pvrdir/php/Config/Constants.inc", $web_uid, $web_gid, 0666
		my @fields = split(/,/, $line) ;
		if (@fields >= 5)
		{
			my $aref = [] ;
			foreach my $field (@fields)
			{
				$field =~ s/^\s+// ;
				$field =~ s/\s+// ;
				$field =~ s/^['"](.*)['"]$/$1/ ;
				
#				$field =~ s/\$(\w+)/$vars{$1}/ge ;
				$field =~ s/\$(\w+)/$vars{$1}/g ;
				
				push @$aref, $field ;
			}
			push @templates, $aref ;
		}
	}
	close $fh ;

$app->prt_data("templates=", \@templates) if $DEBUG >= 2 ;
	
	## Process template files	
	print "Installing template files:\n" ;
	foreach my $aref (@templates)
	{
		my ($src, $dest, $uid, $gid, $mode) = @$aref ;
		
		$mode = oct($mode) ;

		print " * Installing template $src .. " ;
		
		# read
		local $/ ;
		open my $fh, "<$src" or die "Error: unable to read template $src : $!" ;
		my $data = <$fh> ;
		close $fh ;
		
		# translate
#		$data =~ s/\%([\w_]+)\%/$settings_href->{$1}/ge ;
		$data =~ s/\%([\w_]+)\%/$settings_href->{$1}/g ;
		
		# check destination directory
		my $dir = dirname($dest) ;
		if (! -d $dir)
		{
			mkpath([$dir], 0, 0755) ;
			chown $uid, $gid, $dir ;
		}
		
		# write
		open my $fh, ">$dest" or die "Error: unable to write template $dest : $!" ;
		print $fh $data ;
		close $fh ;
		
		# set perms
		chown $uid, $gid, $dest ;
		chmod $mode, $dest ;
		
print "\nSet $dest owner $uid:$gid  mode $mode\n" if $DEBUG ;
		print "done\n" ;
		
	}	
	
}


#----------------------------------------------------------------------
sub start_server
{
	my ($app, $settings_href) = @_ ;

	print "Starting QuartzPVR server ..\n" ;
	system("/etc/init.d/quartzpvr-server restart") ;
	
	print "Setting QuartzPVR server service runlevels ..\n" ;
	my $rc ;
	$rc = try_runit($app, "chkconfig quartzpvr-server on") ;
	print " * Success (chkconfig)\n" if ($rc == 0) ;
	$rc = try_runit($app, "update-rc.d quartzpvr-server defaults") ;
	print " * Success (update-rc.d)\n" if ($rc == 0) ;
}

#----------------------------------------------------------------------
sub dvbt_scan
{
	my ($app, $settings_href) = @_ ;

	print "Initialising DVB-T ..\n" ;
	
	## Create dvb 
	my $dvb = Linux::DVB::DVBT->new('errmode' => 'return') ;
	my @devices = $dvb->devices() ;
	if (@devices < 1) 
	{
		print " ** No DVB adapters found, skipping **\n" ;
		return 0 ;
	}
	else
	{
		my $tuning_href = $dvb->get_tuning_info() ;
	#Linux::DVB::DVBT::prt_data("Current tuning info=", $tuning_href) ;
		$dvb = undef ;
		
		if ($tuning_href)
		{
			print " * DVB-T already initialised, skipping\n" ;
		}
		else
		{
			print " * Tuning DVB-T, this may take some time - please wait ..\n" ;
			system("dvbt-scan $settings_href->{'DVBT_FREQFILE'}") ;
		}
	
	}
	
	return 1 ;
}

#----------------------------------------------------------------------
sub dvbt_channels
{
	my ($app, $settings_href) = @_ ;

	print "Updating DVB-T channels ..\n" ;
#	$app->run("dvbt-chans-sql ")
	runit($app,
		"dvbt-chans-sql",
		"failed to set up channels table"
	) ;
	
}

#----------------------------------------------------------------------
sub dvbt_listings
{
	my ($app, $settings_href) = @_ ;


	## Check for listings
	my $temp0 = "tmp0-$$.sql" ;
	open my $fh, ">$temp0" or die "Error: Unable to create temp file : $!" ;
	print $fh <<SQL ;
SELECT * from $settings_href->{DATABASE}.listings LIMIT 1 ;
SQL
	close $fh ;

	my $results_aref = runit($app,
		"mysql -uroot -p$settings_href->{SQL_ROOT_PASSWORD} < $temp0",
		"MySQL error while checking for listings"
	) ;
#	$app->run("mysql -uroot -p$settings_href->{SQL_ROOT_PASSWORD} < $temp0") ;
#	my $results_aref = $app->run()->results ;
#	my $status = $app->run()->status ;
#	if ($status)
#	{
#		print "Error: MySQL error while loading $temp0\n" ;
#		foreach (@$results_aref)
#		{
#			print "$_\n" ;
#		}
#		exit 1 ;
#	}
	
	my $got_listings = 0 ;
	if (@$results_aref)
	{
		$got_listings = 1 ;
	}

	if ($got_listings)
	{
		print "Already got DVB-T listings, skipping\n" ;
	}
	else
	{
		print "Gathering DVB-T listings (please wait, this can take 30 minutes or so) ..\n" ;
		system("dvbt-epg-sql") ;
	}

	unlink $temp0 ;
}




#=================================================================================
# FUNCTIONS
#=================================================================================

#----------------------------------------------------------------------
sub get_config
{
	my ($app) = @_ ;

	my @config = $app->data('config') ;
	my %settings ;
	foreach my $line (@config)
	{
		if ($line =~ m/^\s*([\w_]+)\s*=\s*(.*)/)
		{
			my ($var, $val) = ($1, $2) ;
			$val =~ s/\s+$// ;
			
			# replace % place-holder with $
			$val =~ s/%/\$/g ;
			
			$settings{$var} = $val ;
		}
	}
	return %settings ;
}


#----------------------------------------------------------------------
# run command
#
sub try_runit
{
	my ($app, $cmd) = @_ ;

print STDERR "Run cmd: $cmd\n" if $DEBUG ;

	$app->run(
		'cmd'		=> $cmd,
		'on_error'	=> 'status',
	) ;
	my $results_aref = $app->run()->results ;
	my $status = $app->run()->status ;

if ($DEBUG)
{
	print STDERR "Status: $status\n" ;
	if ($status)
	{
		print STDERR "Output:\n" ;
		foreach (@$results_aref)
		{
			print STDERR " * $_\n" ;
		}
	}	
}

	return wantarray ? ($results_aref, $status) : $status ;
}



#----------------------------------------------------------------------
# run command
#
sub runit
{
	my ($app, $cmd, $errmsg) = @_ ;

	my ($results_aref, $status) = try_runit($app, $cmd) ;
	
	if ($status)
	{
		print "Error: $errmsg\n" ;
		foreach (@$results_aref)
		{
			print STDERR "$_\n" ;
		}
		exit 1 ;
	}
	
	return $results_aref ;
}

#----------------------------------------------------------------------
# run mysql command
#
sub mysql_try_runit
{
	my ($app, $password, $sql) = @_ ;

print STDERR "Mysql try run cmd: sql=$sql\n" if $DEBUG ;

	my $temp0 = "tmp0-$$.sql" ;
	open my $fh, ">$temp0" or die "Error: Unable to create temp file : $!" ;
	print $fh "$sql\n" ;
	close $fh ;

	my ($results_aref, $status) = try_runit($app,
		"mysql -uroot -p$password < $temp0"
	) ;
	
	unlink $temp0 ;
	
	return wantarray ? ($results_aref, $status) : $status ;
}

#----------------------------------------------------------------------
# run mysql command
#
sub mysql_runit
{
	my ($app, $password, $sql, $errmsg) = @_ ;

print STDERR "Mysql run cmd: sql=$sql\n" if $DEBUG ;

	my $temp0 = "tmp0-$$.sql" ;
	open my $fh, ">$temp0" or die "Error: Unable to create temp file : $!" ;
	print $fh "$sql\n" ;
	close $fh ;

	my $results_aref = runit($app,
		"mysql -uroot -p$password < $temp0",
		$errmsg
	) ;
	
	unlink $temp0 ;
	
	return $results_aref ;
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Installs the Quartz PVR 

[OPTIONS]

-perl_lib=s			Perl library path

Set to the Perl library path where the pure perl modules will be installed

-perl_scripts=s		Perl script path

Set to the Perl script path where the perl scripts will be installed

-pm_version=s		Perl module version

Set to the current version of the Perl module 

__DATA__ sql

USE `%DATABASE%`;

--
-- Table structure for table `channels`
--

DROP TABLE IF EXISTS `channels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `channels` (
  `channel` varchar(256) NOT NULL COMMENT 'Channel name used by DVB-T',
  `display_name` varchar(256) NOT NULL COMMENT 'Displayed channel name',
  `chan_num` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Channel number',
  `chan_type` set('tv','radio','hd-tv') NOT NULL DEFAULT 'tv' COMMENT 'TV or Radio',
  `show` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Whether to show this channel or not',
  `iplay` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Can the channel be recorded using get_iplayer',
  PRIMARY KEY (`chan_num`),
  KEY `type_show_num` (`chan_type`,`show`,`chan_num`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `iplay`
--

DROP TABLE IF EXISTS `iplay`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `iplay` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rid` int(11) NOT NULL,
  `pid` varchar(128) NOT NULL COMMENT 'This is a pseduo PID (it''s got the correct date but may not relate to a real program)',
  `prog_pid` varchar(128) NOT NULL COMMENT 'This is a real (valid) program pid',
  `channel` varchar(128) NOT NULL,
  `record` int(11) NOT NULL,
  `date` date DEFAULT NULL,
  `start` time DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `listings`
--

DROP TABLE IF EXISTS `listings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `listings` (
  `pid` varchar(128) NOT NULL,
  `event` int(32) NOT NULL DEFAULT '-1',
  `title` varchar(128) NOT NULL,
  `date` date NOT NULL,
  `start` time NOT NULL,
  `duration` time NOT NULL,
  `episode` int(11) NOT NULL DEFAULT '0',
  `num_episodes` int(11) NOT NULL DEFAULT '0',
  `text` longtext NOT NULL,
  `channel` varchar(128) NOT NULL,
  `genre` varchar(256) DEFAULT '',
  `tva_prog` varchar(255) NOT NULL DEFAULT '-' COMMENT 'TV Anytime program id',
  `tva_series` varchar(255) NOT NULL DEFAULT '-' COMMENT 'TV Anytime series id',
  `audio` enum('unknown','mono','stereo','dual-mono','multi','surround') NOT NULL DEFAULT 'unknown' COMMENT 'audio channels',
  `video` enum('unknown','4:3','16:9','HDTV') NOT NULL DEFAULT 'unknown' COMMENT 'video screen size',
  `subtitles` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'subtitles available?',
  KEY `pid` (`pid`),
  KEY `chan_date_start_duration` (`channel`,`date`,`start`,`duration`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `multirec`
--

DROP TABLE IF EXISTS `multirec`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `multirec` (
  `multid` int(16) NOT NULL DEFAULT '0' COMMENT 'ID of multiplex recording group ; 0 = no group',
  `date` date DEFAULT '2001-01-00',
  `start` time DEFAULT '00:00:00',
  `duration` time NOT NULL DEFAULT '00:01:00',
  `adapter` VARCHAR(16) NOT NULL DEFAULT '0',
  KEY `multid` (`multid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `record`
--

DROP TABLE IF EXISTS `record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `record` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` varchar(128) NOT NULL,
  `title` varchar(128) NOT NULL,
  `date` date NOT NULL,
  `start` time NOT NULL,
  `duration` time NOT NULL,
  `channel` varchar(128) NOT NULL,
  `chan_type` varchar(256) DEFAULT 'tv',
  `record` int(11) NOT NULL COMMENT '[0=no record; 1=once; 2=weekly; 3=daily; 4=all(this channel); 5=all, 6=series] + [DVBT=0, FUZZY=0x20 (32), DVBT+IPLAY=0xC0 (192), IPLAY=0xE0 (224)] ',
  `priority` int(11) NOT NULL DEFAULT '50' COMMENT 'Set priority of recording: 1 is highest; 100 is lowest',
  `tva_series` varchar(255) NOT NULL DEFAULT '-',
  `tva_prog` varchar(255) NOT NULL DEFAULT '-' COMMENT 'TV Anytime program id',
  `pathspec` varchar(255) NOT NULL DEFAULT '' COMMENT 'Path specification: varoables are replaced for each recording',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `recorded`
--

DROP TABLE IF EXISTS `recorded`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `recorded` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` varchar(128) NOT NULL,
  `rid` int(11) NOT NULL COMMENT 'Record ID',
  `ipid` varchar(128) NOT NULL DEFAULT '-' COMMENT 'IPLAY: The IPLAYER id (e.g. b00r4wrl)',
  `rectype` enum('dvbt','iplay') NOT NULL COMMENT 'Recording type',
  `title` varchar(128) NOT NULL,
  `text` varchar(255) NOT NULL DEFAULT '',
  `date` date NOT NULL,
  `start` time NOT NULL,
  `duration` time NOT NULL,
  `channel` varchar(128) NOT NULL,
  `adapter` VARCHAR(16) NOT NULL DEFAULT '0' COMMENT 'DVB adapter number',
  `type` enum('tv','radio') NOT NULL DEFAULT 'tv' COMMENT 'Type of recording',
  `record` int(11) NOT NULL COMMENT '[0=no record; 1=once; 2=weekly; 3=daily; 4=all(this channel); 5=all, 6=series] + [DVBT=0, FUZZY=0x20 (32), DVBT+IPLAY=0xC0 (192), IPLAY=0xE0 (224)] ',
  `priority` int(11) NOT NULL COMMENT 'Set priority of recording: 1 is highest; 100 is lowest',
  `genre` varchar(255) NOT NULL DEFAULT '',
  `tva_prog` varchar(255) NOT NULL DEFAULT '' COMMENT 'TV Anytime program id',
  `tva_series` varchar(255) NOT NULL DEFAULT '' COMMENT 'TV Anytime series id',
  `file` varchar(255) NOT NULL COMMENT 'Recorded filename',
  `changed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Last modification date/time',
  `status` set('started','recorded','error','repaired','mp3tag','split','complete') NOT NULL DEFAULT '' COMMENT 'State of recording',
  `statErrors` int(11) NOT NULL DEFAULT '0' COMMENT 'Recording error count',
  `statOverflows` int(11) NOT NULL DEFAULT '0' COMMENT 'Recording overflow count',
  `statTimeslipStart` int(11) NOT NULL DEFAULT '0' COMMENT 'Seconds timeslipped start of recording',
  `statTimeslipEnd` int(11) NOT NULL DEFAULT '0' COMMENT 'Seconds timeslipped recordign end',
  `errorText` varchar(255) NOT NULL DEFAULT '' COMMENT 'Summary of any errors',
  PRIMARY KEY (`id`),
  KEY `pid` (`pid`),
  KEY `pid_rectype` (`pid`,`rectype`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schedule`
--

DROP TABLE IF EXISTS `schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schedule` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rid` int(11) NOT NULL,
  `pid` varchar(128) NOT NULL,
  `channel` varchar(128) NOT NULL,
  `record` int(11) NOT NULL,
  `date` date DEFAULT NULL COMMENT 'DEBUG ONLY!',
  `start` time DEFAULT NULL COMMENT 'DEBUG ONLY!',
  `priority` int(11) NOT NULL DEFAULT '10' COMMENT 'Lower numbers are higher priority',
  `adapter` VARCHAR(16) NOT NULL DEFAULT '0',
  `multid` varchar(128) NOT NULL DEFAULT '0' COMMENT 'ID of multiplex recording group ; 0 = no group',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


__DATA__ versions.sql

USE `%DATABASE%`;

DROP TABLE IF EXISTS `versions`;
CREATE TABLE  `versions` (
`id` INT( 8 ) NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`item` VARCHAR( 255 ) NOT NULL ,
`version` VARCHAR( 16 ) NOT NULL
) ENGINE = MYISAM ;


__DATA__ config
