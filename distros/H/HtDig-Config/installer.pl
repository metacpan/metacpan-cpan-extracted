use File::Copy "cp";

print qq|ConfigDig CGI Installation and Initialization

Please provide the full path to your base ht://Dig installation directory
(usually something like /opt/www/).  This is where your ht://Dig conf,
share, bin, and cgi-bin directories are located.
|;

#Get the path to the ht://Dig base directory
do {
	print "Enter path:";
	chomp($base_path = <STDIN>);
	print "$base_path is not a directory.\n" if !-d $base_path;
} until -d $base_path;

print qq|
ConfigDig uses a small registry file that is usually placed in your
ht://Dig configuration files directory (although you can technically place
it anywhere you wish).

Please enter the full path to your ht://Dig configuration files
directory (the default ht://Dig conf file is "htdig.conf").
The path is usually something like /opt/www/conf/ by default.  The
ConfigDig registry file, will be created here.
|;

#Get the path to the ht://Dig conf directory
do {
	print "Enter path:";
	chomp($conf_path = <STDIN>);
	print "$conf_path is not a directory.\n" if !-d $conf_path;
} until -d $conf_path;

print qq|
ConfigDig also creates log files that can be useful for reviewing the
outcome of index creation and dig processes.  Please provide a directory
where ConfigDig can place these log files.  A good choice is to create a
"logs" directory in your ht://Dig base directory and use it (such as
/opt/www/logs/" 
|;

#Get the path to the ht://Dig log directory
do {
	print "Enter path:";
	chomp($log_path = <STDIN>);
	print "$log_path is not a directory.\n" if !-d $log_path;
} until -d $log_path;



#Create the registry file
open(SITES,">$conf_path/configdig_sites.pl") or die "Couldn't create file
at $conf_path.  Must have write capability.\n";
print SITES qq|\$configdig_log_path = '$log_path';\n|;
print SITES qq|\$htdig_base_path = '$base_path';\n|;
print SITES "1;\n";
close(SITES);

print "Successfully created registry file.\n";

print qq|
Now we need to know where you'd like the CGI files to go.
Please provide a valid directory where the CGI files can be
placed.  It should be marked cgi executible in your web server's
configuration.  Preferably, it should be empty, as the files will be
placed directly in this location, so please be
careful not to overwrite files that may already exist!

|;

#Get the path to the CGI directory
do {
	print "Enter path:";
	chomp($cgi_path = <STDIN>);
	print "$cgi_path is not a directory.\n" if !-d $cgi_path;
} until -d $cgi_path;

#Copy in the cgi files
install_file("cd.css");
install_file("index.cgi");
install_file("autodetect.cgi");
install_file("edit_conf.cgi");
install_file("edit_site.cgi");
install_file("local_inc.pl");
install_file("new_site.cgi");
install_file("proc_tpl.pl");
install_file("view_site.cgi");
mkdir("$cgi_path/tpl",0755);
if ($! and $! ne "File exists") {
	die "Couldn't create $cgi_path/tpl directory: $!\n
Must have write capability.\n";
}
install_file("tpl/autodetect.cgi.html");
install_file("tpl/index.cgi.html");
install_file("tpl/edit_conf.cgi.html");
install_file("tpl/new_site.cgi.html");
install_file("tpl/view_site.cgi.html");
install_file("tpl/edit_site.cgi.html");

open(STG, ">$cgi_path/cgi_settings.pl") or die "Couldn't create
cgi_settings.pl file in $cgi_path: $!\nMust have write capability.\n";

print STG qq|
\$conf_path = '$conf_path/configdig_sites.pl';
\$T::style_sheet_link = 
	'<LINK REL="stylesheet" HREF="cd.css" TYPE="text/css">';
1;
|;
close STG;
print "CGI installation successful.\n";

print qq|
If you installed the ConfigDig perl modules in a custom directory, your
CGI scripts must know about it.  If you wish, the local_inc.pl file that
is in your ConfigDig CGI directory can be updated to add this directory to
the module search path for the CGI scripts.  Either enter the directory
now, or hit [enter] to skip this part.
|;

#Get the custom module install path
do {
	print "Enter path (or hit [enter] to skip):";
	chomp($mod_path = <STDIN>);
	print "$mod_path is not a directory.\n" if (!-d $mod_path &&
$mod_path ne "");
} until (-d $mod_path or $mod_path eq "");

if ($mod_path) {
	open(LI, ">$cgi_path/local_inc.pl") or die "Couldn't open
$cgi_path/local_inc.pl for writing.  Must have write capability.\n";
	print LI "push(\@INC,'$mod_path');\n1;";
	close(LI);
	print "local_inc.pl was updated successfully.\n";
}

print qq|
Configuration is now complete.  Problems in installation or usage can be
logged on the ConfigDig bug tracking system found at
http://configdig.sourceforge.net

We hope you find ConfigDig useful!
|;

#Helper copy routine
sub install_file {
	cp("./cgi/$_[0]", "$cgi_path/$_[0]") or warn "Couldn't copy $_[0]
to $cgi_path\n";
}
