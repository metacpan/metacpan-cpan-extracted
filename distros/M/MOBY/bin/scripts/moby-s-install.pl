#!/usr/bin/perl -w
#
# Prepare the stage...
#
# $Id: moby-s-install.pl,v 1.15 2009/04/15 16:38:57 kawas Exp $
# Contact: Edward Kawas <edward.kawas@gmail.com>
# -----------------------------------------------------------

BEGIN {
	use Getopt::Std;
	use vars qw/ $opt_h /;
	getopt;

	# usage
	if ($opt_h) {
		print STDOUT <<'END_OF_USAGE';
Preparing the stage for hosting a BioMOBY registry.
Usage: moby-s-install.pl [-h]

	-h .... shows this message ;-)
	
    Installer script for installing a BioMOBY registry
    
    This script goes through and edits your apache configuration,
    mysql settings, and installs cgi scripts needed to host your
    own registry. It is best to do this as root, because items are
    copied into priviledged locations (apache directory, etc.).
    
    Good luck!
	

END_OF_USAGE
		exit(0);
	}

	my $errors_found = 0;

	sub say { print @_, "\n"; }

	# query is for creating the moby_username and password for local access to dbs
	sub prepare_query { 
		my $s = join "", @_;
		return qq|GRANT ALL ON $s TO ?\@'localhost' IDENTIFIED BY ? WITH GRANT OPTION|;
	}
	sub check_module {
		eval "require $_[0]";
		if ($@) {
			$errors_found = 1;
			say "Module $_[0] not installed.";
		} else {
			say "OK. Module $_[0] is installed.";
		}
	}

	use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

	say
'Welcome, BioMobiers. Preparing stage for installation of your custom registry...';
	say '------------------------------------------------------';

	# check needed modules
	foreach $module (
		qw (
		File::Spec
		SOAP::Lite
		XML::LibXML
		IO::Stringy
		Unicode::String
		File::HomeDir
		File::ShareDir
		Class::Inspector
		RDF::Core
		XML::XPath
		Text::Shellwords
		HTML::Entities
		DBI
		DBD::mysql
		LS
		XML::Simple
		)
	  )
	{
		check_module($module);
	}
	if (MSWIN) {
		check_module('Term::ReadLine');
		{
			local $^W = 0;
			$SimplePrompt::Terminal = Term::ReadLine->new('Installation');
		}
	} else {
		check_module('IO::Prompt');
		require IO::Prompt;
		import IO::Prompt;
		# module required for service_tester.pl
		check_module('IPC::Shareable');
		# check for async libraries if user wants to ....
		do {
			foreach $module (
			qw / WSRF::Lite
				 XML::DOM
				 DateTime::Format::Epoch
				 DateTime::Format::W3CDTF
				 HTTP::Daemon
				 Crypt::OpenSSL::X509
				 MIME::Base64
		         Digest::SHA1
		         Crypt::OpenSSL::RSA
				 Sys::Hostname::Long
				 HTTP::Daemon::SSL
			   / ) {
				check_module($module);
				
			}
		} if prompt( "Shall we check for the moby-async libraries\n\t(do this only if you plan on creating async moby services)? ", -yn );
	}

	if ($errors_found) {
		say "\nSorry, some needed modules were not found.";
		say "Please install them and run 'moby-s-install.pl' again.";
		exit(1);
	}
	say;
}
use File::ShareDir;
use File::Spec;
use English qw( -no_match_vars );
use strict;

# different prompt modules used for different OSs
# ('pprompt' as 'proxy_prompt')
sub pprompt {
	return prompt(@_) unless MSWIN;
	return SimplePrompt::prompt(@_);
}

# $prompt ... a prompt asking for a directory
# $prompted_dir ... suggested directory
sub prompt_for_directory {
	my ( $prompt, $prompted_dir ) = @_;
	while (1) {
		my $dir = pprompt("$prompt [$prompted_dir] ");
		$dir =~ s/^\s*//;
		$dir =~ s/\s*$//;
		$dir = $prompted_dir unless $dir;
		return $dir if -d $dir and -w $dir;    # okay: writable directory
		next
		  if ( not -e $dir )
		  and say "'$dir' does not exist. Try again please.";

		next
		  if ( not -w $dir )
		  and say "'$dir' is not a writable directory. Try again please.";
	}
}

sub prompt_for_directory_expand {
	my ( $prompt, $prompted_dir ) = @_;
	while (1) {
		my $dir = pprompt("$prompt [$prompted_dir] ");
		$dir =~ s/^\s*//;
		$dir =~ s/\s*$//;
		$dir = $prompted_dir unless $dir;
		return $dir if -d $dir and -w $dir;    # okay: writable directory
		$prompted_dir = $dir;
		next
		  if -e $dir
		  and say "'$dir' is not a writable directory. Try again please.";
		next
		  unless pprompt( "Directory '$dir' does not exists. Create? ", -yn );

		# okay, we agreed to create it
		mkdir( $dir, 0755 ) and return $dir;
		say "'$dir' not created: $!";
	}
}

sub prompt_user_input {
	my ( $prompt, $default ) = @_;
	while (1) {
		my $dir = pprompt("$prompt [$default] ");
		$dir =~ s/^\s*//;
		$dir =~ s/\s*$//;
		$dir = $default unless $dir;
		return $dir;
	}
}

# create a file from a template
#  - from $file_template to $file,
#  - $file_desc used in messages,
#  - hashref $filters tells what to change in template
sub file_from_template {
	my ( $file, $file_template, $file_desc, $filters ) = @_;
	eval {
		open FILETEMPL, "<$file_template"
		  or die "Cannot read template file '$file_template': $!\n";
		open FILEOUT, ">$file"
		  or die "Cannot open '$file' for writing: $!\n";
		while (<FILETEMPL>) {
			foreach my $token ( keys %$filters ) {
				if ( $^O eq 'MSWin32' ) {
					$filters->{$token} =~ s|\\|\/|;
				}
				s/\Q$token\E/$filters->{$token}/ge;
			}
			print FILEOUT
			  or die "Cannot write into '$file': $!\n";
		}
		close FILEOUT;
		close FILETEMPL
		  or die "Cannot close '$file': $!\n";
	};
	if ($@) {
		say "ERROR: $file_desc was (probably) not created.\n$@";
	} else {
		say
"\n$file_desc created: '$file'\n\tPlease ensure that the file is executable!\n";
	}

	# try to make file executable
	eval {
		my $mode = 0655;
		chmod $mode, "$file";
	};
}

# create a config file from a template
#  - from $file_template to $file,
#  - $file_desc used in messages,
#  - hashref $filters tells what to change in template
#  - hashref $dbnames maps db sections to user specified names
sub config_file_from_template {
	my ( $file, $file_template, $file_desc, $filters, $dbnames, $resourceURLs,
		 $LSIDS )
	  = @_;
	my $current_section = "";
	eval {

		#check if FILETEMPL and FILEOUT are the same if so, create a temp file
		my $same_resource = $file eq $file_template;
		my ( $fh, $filename ) = tempfile( UNLINK => 1 ) if $same_resource;

		open FILETEMPL, "<$file_template"
		  or die "Cannot read template file '$file_template': $!\n";

		(
		   open FILEOUT, ">$file"
			 or die "Cannot open '$file' for writing: $!\n"
		  )
		  unless $same_resource;

		while (<FILETEMPL>) {
			if (/^\[(.*)\]\s*$/) {
				$current_section = $1;
				chomp($current_section);
			}
			foreach my $token ( keys %$filters ) {
				if ( $^O eq 'MSWin32' ) {
					$filters->{$token} =~ s|\\|\/|;
				}
				if (/\Q$token\E\s*\=/) {
					s/^(\Q$token\E\s*\=\s*)(.*)$/$1 . $filters->{$token}/eg;
				}
			}
			if (/dbname\s*\=/) {
				s/^(dbname\s*\=\s*)(.*)$/$1 . $dbnames->{$current_section}/eg
				  if exists $dbnames->{$current_section}
				  and defined $dbnames->{$current_section};
			}
			if (/resourceURL\s*\=/) {
s/^(resourceURL\s*\=\s*)(.*)$/$1 . $resourceURLs->{$current_section}/eg
				  if exists $resourceURLs->{$current_section}
				  and defined $resourceURLs->{$current_section};
			}
			if (/allResources\s*\=/) {
				s/^(allResources\s*\=\s*)(.*)$/$1 . $resourceURLs->{'ALL'}/eg
				  if exists $resourceURLs->{'ALL'}
				  and defined $resourceURLs->{'ALL'};
			}
			if (/lsid_authority\s*\=/) {
s/^(lsid_authority\s*\=\s*)(.*)$/$1 . $LSIDS->{$current_section}->{'AUTHORITY'}/eg
				  if exists $LSIDS->{$current_section}->{'AUTHORITY'}
				  and defined $LSIDS->{$current_section}->{'AUTHORITY'};
			}
			if (/lsid_namespace\s*\=/) {
s/^(lsid_namespace\s*\=\s*)(.*)$/$1 . $LSIDS->{$current_section}->{'NAMESPACE'}/eg
				  if exists $LSIDS->{$current_section}->{'NAMESPACE'}
				  and defined $LSIDS->{$current_section}->{'NAMESPACE'};
			}
			( print FILEOUT $_ or die "Cannot write into '$file': $!\n" )
			  unless $same_resource;
			( print $fh $_ or die "Cannot write into '$filename': $!\n" )
			  if $same_resource;

		}
		close FILETEMPL or die "Cannot close '$file_template': $!\n";
		close FILEOUT unless $same_resource;
		close $fh if defined $fh;

		do {
			open FILEOUT, ">$file"
			  or die "Cannot open '$file' for writing: $!\n";
			open $fh, "<$filename"
			  or die "Cannot read temp file '$filename':$!\n";
			while (<$fh>) {
				print FILEOUT or die "Cannot write into '$file': $!\n";
			}
			close FILEOUT;
		} if $same_resource;

	};
	if ($@) {
		say "ERROR: $file_desc was (probably) not created.\n$@";
	} else {
		say "\n$file_desc created: '$file'\n";
	}
}

sub search_config_file {
	my ( $file, $filters ) = @_;
	my $current_section = "";
	eval {
		open FILETEMPL, "<$file"
		  or die "Cannot read file '$file': $!\n";

		while (<FILETEMPL>) {
			if (/^\[(.*)\]\s*$/) {
				$current_section = $1;
				chomp($current_section);
				next;
			}
			next unless defined $filters->{$current_section};
			for my $key ( keys %{ $filters->{$current_section} } ) {
				if (/\Q$key\E\s*\=/) {
					$filters->{$current_section}->{$key} = 1;
				}
			}
		}
		close FILETEMPL or die "Cannot close '$file': $!\n";
	};
	return $filters;
}

sub add_missing_keys_to_config_file {
	my ( $file, $filters ) = @_;
	my $current_section = "";
	eval {
		open FILETEMPL, "<$file"
		  or die "Cannot read file '$file': $!\n";
		my ( $fh, $filename ) = tempfile( UNLINK => 1 );

		while (<FILETEMPL>) {
			if (/^\[(.*)\]\s*$/) {
				$current_section = $1;
				chomp($current_section);
				print $fh $_;
				next;
			}
			( print $fh $_ and next )
			  unless defined $filters->{$current_section};
			for my $key ( keys %{ $filters->{$current_section} } ) {
				if ( $filters->{$current_section}->{$key} == 0 ) {
					print $fh "$key = some_fake_value\n";
					delete $filters->{$current_section}->{$key};
				}
			}
			print $fh $_;
		}
		close FILETEMPL or die "Cannot close '$file': $!\n";
		close $fh;

		#now copy temp file to existing one
		open FILEOUT, ">$file"
		  or die "Cannot open '$file' for writing: $!\n";
		open $fh, "<$filename" or die "Cannot read temp file '$filename':$!\n";
		while (<$fh>) {
			print FILEOUT or die "Cannot write into '$file': $!\n";
		}
		close FILEOUT;
		close $fh;
	};
}

sub prompt_moby_config_info {
	my $username =
	  prompt_user_input( "What is your root mysql username?", "root" );
	my $password =
	  prompt_user_input( "What is your root mysql users' password?", "" );
	$password = "" unless $password;
	my $url  = prompt_user_input( "What is the mysql url?",    "localhost" );
	my $port = prompt_user_input( "What is the mysql port #?", "3306" );

	# prompt for a new user/password combo so that people cant determine the root password from MOBY::Config
	my $moby_username = prompt_user_input( "What username (I will create it if it doesn't exist)\n  would you like to access your local db?", "moby_user" );
	my $moby_password = prompt_user_input( "Please provide a password for '$moby_username': ", "" ); 
	$moby_password = "" unless $moby_password;
	#db names
	say
"\nPrompting for mysql table names. Use default names unless you know what you are doing!";
	my $m_object =
	  prompt_user_input( "Table name for object ontology: ", "mobyobject" );
	my $m_relationship =
	  prompt_user_input( "Table name for the relationship ontology: ",
						 "mobyrelationship" );
	my $m_service =
	  prompt_user_input( "Table name for the service type ontology: ",
						 "mobyservice" );
	my $m_namespace =
	  prompt_user_input( "Table name for the namespace ontology: ",
						 "mobynamespace" );
	my $m_central = prompt_user_input( "Table name for the service ontology: ",
									   "mobycentral" );

	my $msg = <<EOF;
	
You have provided the following values: 

mySQL Details
   username             :   $username
   password             :   $password
   URL                  :   $url
   port                 :   $port
   registry db username :   $moby_username
   registry db password :   $moby_password
	
Tables:
   Object ontology         :   $m_object
   Relationshipt ontology  :   $m_relationship
   Service ontology        :   $m_central
   Namespace ontology      :   $m_namespace
   Service type ontology   :   $m_service

EOF
	say($msg);

	return (
			 $username,      $password,    $url,
			 $port,          $m_object,    $m_relationship,
			 $m_service,     $m_namespace, $m_central,
			 $moby_username, $moby_password
	);
}

sub fill_out_moby_conf {
	my (
		 $file,        $username, $password,       $url,
		 $port,        $m_object, $m_relationship, $m_service,
		 $m_namespace, $m_central
	  )
	  = @_;

	# load & fill the template file

	config_file_from_template(
		$file,
		File::ShareDir::dist_file(
								   'MOBY', 'config/mobycentral.config.template'
		),
		'MOBY/SQL Configuration file',

		# mysql settings
		{
		   'username' => $username,
		   'password' => $password,
		   'url'      => $url,
		   'port'     => $port,
		},

		# db section mappings
		{
		   'mobycentral'      => $m_central,
		   'mobyobject'       => $m_object,
		   'mobynamespace'    => $m_namespace,
		   'mobyservice'      => $m_service,
		   'mobyrelationship' => $m_relationship,
		},
		{},
		{}
	);

	# since the file contains the root DB password
	# make it only readable by root
	chmod 0644, $file;
	die "Couldn't make MOBY config file readable only by root: $!"
	    if $?;

	# finished!
	return;
}

sub check_root {
	# assume that windows has no security preventing the copying of files
	return if MSWIN;
    unless (getpwuid($<) eq 'root') { 
	print STDOUT <<EOT;

Hmmm - you are not installing this as root. If you indicate any
system directories for the installation, such as '/usr/local', then
you do not have permission to install files there. If so, you should
cancel now with ^C, su to root, and restart.

If you will not specify any system directories, you can proceed.

EOT

        print STDOUT "Should I proceed? [n] ";
        my $tmp = <STDIN>;  $tmp =~ s/\s//g; 
        exit() unless $tmp =~ /y/i;
    } else {
        print STDOUT <<EOT;

Take care! you are installing this as ** root **. Please take the normal 
precautions that you would ordinarily take when installing software as root. 
In particular, be careful with ownership, paths, and environment variables.

EOT

    }
}

# --- main ---
no warnings 'once';

use Tie::File;
use MOBY::dbConfig;
use MOBY::Client::Central;
use File::Temp qw/ tempfile /;
use DBI;

# give a waring if we are not running with su privelege
check_root();

say "Installing a mobycentral registry ...\n";

my $answer;

my $apache_base = "";
my $apache_conf = "";
my $apache_cgi  = "";
my $perl_exec   = "/usr/bin/perl";

# make sure perl exists
if (not -x $perl_exec) {
    $perl_exec = '';
}

# check for debian
if (-e "/etc/debian_version") {
    $apache_base = "/var/lib";
    $apache_conf = "/etc/apache2";
    $apache_cgi  = "/usr/lib/cgi-bin";
}

my (
	 $username,  $password,    $url,
	 $port,      $m_object,    $m_relationship,
	 $m_service, $m_namespace, $m_central,
	 $moby_username, $moby_password
);

say "We are going to be placing files into your apache setup, in the cgi-bin/ directory and conf/ directory";

unless ($apache_base) {
    say <<EOT;

I am not able to determing defaults for your apache setup, perhaps you have a
custom install. Custom installs of have a base directory,
e.g. '/usr/local/apache' under which all the other directories are placed.

EOT

    $apache_base = prompt_for_directory(
	"What is the base installation path of apache?",
	$apache_base );

}

$apache_conf ||= "$apache_base/conf";
$apache_conf = prompt_for_directory(
    "What is the path of the apache 'conf' directory?",
    $apache_conf );

$apache_cgi ||= "$apache_base/cgi-bin";
$apache_cgi = prompt_for_directory(
    "What is the path of the apache 'cgi-bin' directory?",
    $apache_cgi );

$perl_exec = prompt_user_input(
    "What is the path to your perl executable?",
    $perl_exec );
$perl_exec = "$perl_exec -w";

say <<EOT;

using $apache_base as base directory ...
using $apache_conf as conf directory ...
using $apache_cgi as cgi directory ...
using '#!$perl_exec' as header for perl cgi scripts ...

EOT

my $apache_info = <<EOT;
To run MOBY Central we will need to configure your MySQL DB, and install three
default variables into your apache webserver. If you are using Apache2 we will
place a config file in your conf.d/ directory, otherwise if you are still using
Apache1.3 we will need to modify your httpd.conf file.

You will be prompted before any changes are made.

EOT

$answer = pprompt( "$apache_info\nShall we begin setting up apache? [n] ",
		   -ynd => 'n' );

if ($answer eq 'y') {

    say "Configuring your MOBY/SQL config file ...";

    # mobycentral.config exists
    if ( -e "$apache_conf/mobycentral.config" ) {
	do {

	    # copy mobycentral.config to conf directory
	    (
	     $username,      $password,    $url,
	     $port,          $m_object,    $m_relationship,
	     $m_service,     $m_namespace, $m_central,
	     $moby_username, $moby_password
	    )
		= prompt_moby_config_info;

	    # TODO - collect the values and do this at the end
	    # fill out mobycentral.config
	    fill_out_moby_conf("$apache_conf/mobycentral.config",
			       $moby_username, $moby_password, $url,
			       $port,          $m_object,      $m_relationship,
			       $m_service,     $m_namespace,   $m_central
		);

	}
	if pprompt(
	    "Would you like to overwrite the file '$apache_conf/mobycentral.config'? [n] ",
	    -ynd => 'n'
	    ) eq 'y';
    } else {
	say "  Installing the file '$apache_conf/mobycentral.config' ...";

	# fill out mobycentral.config
	(  $username,      $password,    $url,
	   $port,          $m_object,    $m_relationship,
	   $m_service,     $m_namespace, $m_central,
	   $moby_username, $moby_password
	) = prompt_moby_config_info;

	# TODO - collect the values and do this at the end
	fill_out_moby_conf("$apache_conf/mobycentral.config",
			   $moby_username, $moby_password, $url,
			   $port,          $m_object,      $m_relationship,
			   $m_service,     $m_namespace,   $m_central
	    );
    }

    #install MOBY-Central.pl and OntologyServer.cgi
    say "  Installing the MOBY-Central.pl & OntologyServer.cgi ...";
    file_from_template(
	"$apache_cgi/MOBY-Central.pl",
	File::ShareDir::dist_file('MOBY', 'cgi/MOBY-Central.pl'),
	'MOBY-Central Dispatch file',
	{ '#!/usr/bin/perl -w' => "#!$perl_exec", }
	);
    file_from_template(
	"$apache_cgi/OntologyServer.cgi",
	File::ShareDir::dist_file('MOBY', 'cgi/OntologyServer.cgi'),
	'MOBY-Central Ontology Server file',
	{ '#!/usr/bin/perl -w' => "#!$perl_exec", }
	);

    #install the moby-admin module
    file_from_template(
	"$apache_cgi/MOBY-Admin.pl",
	File::ShareDir::dist_file('MOBY', 'cgi/MOBY-Admin.pl'),
	'MOBY-Admin Dispatch file',
	{ '#!/usr/bin/perl -w' => "#!$perl_exec", }
	);

	#
	# Configure Apache - check for Apache2 first
	#

    say <<EOT;
I would like to add the following lines to your httpd.conf file:

    SetEnv MOBY_CENTRAL_CONFIG "$apache_conf/mobycentral.config"
    
    SetEnv MOBY_URI "http://localhost/MOBY/Central"
    
    SetEnv MOBY_SERVER "http://localhost/cgi-bin/MOBY-Central.pl"
    
    SetEnv MOBY_ONTOLOGYSERVER "http://localhost/cgi-bin/OntologyServer.cgi"

Of course, those lines may not be exactly right, so I will give you a chance to modify them!

EOT

    # pass in the value w/o the SETENV part ... we will add that ourselves
    my $env1 = "$apache_conf/mobycentral.config";
    my $env2 = "http://localhost/MOBY/Central";
    my $env3 = "http://localhost/cgi-bin/MOBY-Central.pl";
    my $env4 = "http://localhost/cgi-bin/OntologyServer.cgi";

    say <<EOT;
Please review the following ensuring that [at least!] the domain name is correct!
EOT

    $env2 = prompt_user_input( "Enter a value for MOBY_URI: ", $env2 );
    $env3 = prompt_user_input( "Enter a value for MOBY_SERVER: ", $env3 );
    $env4 = prompt_user_input( "Enter a value for MOBY_ONTOLOGYSERVER: ", 
			       $env4 );


    if ( -d "$apache_conf/conf.d" ) {
	say "Found Apache2 setup...";

	my $conf_file = "$apache_conf/conf.d/moby.conf";

	$answer = prompt("Going to create your Apache2 MOBY configuration at: $conf_file. Shall I proceed? [y] ", -ynd => 'y');

	if ($answer eq 'y') {
	    open( DAT, ">$conf_file" )
		or die("Could not open $conf_file for reading!");

	    print DAT <<EOT;
# Values added by moby-s-install.pl
SetEnv MOBY_CENTRAL_CONFIG "$env1"
SetEnv MOBY_URI "$env2"
SetEnv MOBY_SERVER "$env3"
SetEnv MOBY_ONTOLOGYSERVER "$env4"
EOT

	}
    } elsif (not -e "$apache_conf/httpd.conf" ) {
	die "Could not detect Apache2 setup ($apache_conf/conf.d/) or Apache1.3 ($apache_conf/httpd.conf). Please restart and enter the correct info";
    } else {

	# configure httpd.conf create backup of httpd.conf and append the values
	# to the begining of the file

	$answer = pprompt( "May I edit your httpd.conf file? [y] ",
			   -ynd => 'y' );
	if ($answer eq 'y') {
	    open( DAT, "< $apache_conf/httpd.conf" )
		|| die("Could not open file for reading!");
	    my @raw_data = <DAT>;
	    close(DAT);

	    open( DAT, "> $apache_conf/httpd.conf_backup" . time() )
		|| die("Trouble creating a backup of httpd.conf!\n$@");
	    print DAT @raw_data;
	    close(DAT);

	    my %added = (
		'DIRTY'               => 0,
		'MOBY_CENTRAL_CONFIG' => 0,
		'MOBY_URI'            => 0,
		'MOBY_SERVER'         => 0,
		'MOBY_ONTOLOGYSERVER' => 0,
		);
	    tie @raw_data, 'Tie::File', "$apache_conf/httpd.conf" or die "$@";

	    for (@raw_data) {

		if (
		    /SETENV\s*(MOBY_CENTRAL_CONFIG|MOBY_URI|MOBY_SERVER|MOBY_ONTOLOGYSERVER)\s*.*/gi
		    )
		{
		    $added{'DIRTY'}++;
		    if ( $1 eq "MOBY_CENTRAL_CONFIG" ) {
			$_ = "SetEnv MOBY_CENTRAL_CONFIG \"$env1\"";
			$added{$1} = 1;
		    } elsif ( $1 eq "MOBY_URI" ) {
			$_ = "SetEnv MOBY_URI \"$env2\"";
			$added{$1} = 1;
		    } elsif ( $1 eq "MOBY_SERVER" ) {
			$_ = "SetEnv MOBY_SERVER \"$env3\"";
			$added{$1} = 1;
		    } else {
			$_ = "SetEnv MOBY_ONTOLOGYSERVER \"$env4\"";
			$added{$1} = 1;
		    }
		}
	    }
	    untie @raw_data;

	    do {
		open( DAT, ">> $apache_conf/httpd.conf" )
		    || die("Trouble updating httpd.conf!\n$@");
		print DAT "\n# Values added by moby-s-install.pl\n"
		    if $added{'DIRTY'} == 0;
		print DAT "SetEnv MOBY_CENTRAL_CONFIG \"$env1\"\n"
		    if $added{'MOBY_CENTRAL_CONFIG'} == 0;
		print DAT "SetEnv MOBY_URI \"$env2\"\n"
		    if $added{'MOBY_URI'} == 0;
		print DAT "SetEnv MOBY_SERVER \"$env3\"\n"
		    if $added{'MOBY_SERVER'} == 0;
		print DAT "SetEnv MOBY_ONTOLOGYSERVER \"$env4\"\n"
		    if $added{'MOBY_ONTOLOGYSERVER'} == 0;
		close(DAT);
	    } unless $added{'DIRTY'} == 4;

	    say <<EOT;
Please do not forget to add the following ENV variables to your profile
so that they are always available when calling client BioMOBY API methods
from scripts!
    MOBY_CENTRAL_CONFIG = "$env1"
    MOBY_URI = "$env2"
    MOBY_SERVER = "$env3"
    MOBY_ONTOLOGYSERVER = "$env4"

EOT
	}
    }
}

$answer = pprompt( "Would you like to set up mySQL? [n] ", -ynd => 'n' );
if ($answer eq 'y') {

	my $ready_to_go = 0;
	my $sql_error   = 0;

	#check to see if we can call mysql ... if not, then die!
	my $mysql_installed = (`mysql --version 2>&1` =~ m/^mysql\s+Ver\s+.*$/);
	my $mysql_started   = (`mysql -e "SHOW VARIABLES LIKE 'version'" 2>&1` !~ m/^ERROR 200.*Can't connect to .*$/);
	print "mysql is installed ...\n"
	    if $mysql_installed;
	print "mysql is started ...\n"
	    if $mysql_started;

	unless ($mysql_installed and $mysql_started) {
	    die <<ERROR;
MySQL does not seem to be accessible ... 
Please ensure that the 'mysql' client program is in your path,
and that the msqyl-server is started and try again.

ERROR
	}

	# have the values been set already?
	$ready_to_go = 1
	    if $username
	    and $url
	    and $port
	    and $m_object
	    and $m_relationship
	    and $m_service
	    and $m_namespace
	    and $m_central,
	    and $moby_username,
	    and ($moby_password || $moby_password eq "");

	# check to see if mobycentral.config has been created in the conf
	# directory first -> if so, parse it

	if (    -e "$apache_conf/mobycentral.config"
		&& !( -d "$apache_conf/mobycentral.config" )
		&& !$ready_to_go )
	{
	    open IN, "$apache_conf/mobycentral.config"
		or die
		"can't open MOBY Configuration file '$apache_conf/mobycentral.config' for unknown reasons: $!\n";

	    my @sections = split /(\[\s*\S+\s*\][^\[]*)/s, join "", <IN>;
	    my %db_sections = ();
	    foreach my $section (@sections) {
			my $dbConfig = MOBY::dbConfig->new( section => $section );
			next unless $dbConfig;
			my $dbname = $dbConfig->section_title;
			next unless $dbname;
			$db_sections{$dbname} = $dbConfig;
	    }

	    $moby_username  = $db_sections{mobycentral}->{username};
	    $moby_password  = $db_sections{mobycentral}->{password} || "";
	    $url            = $db_sections{mobycentral}->{url};
	    $port           = $db_sections{mobycentral}->{port};
	    $m_object       = $db_sections{mobyobject}->{dbname};
	    $m_relationship = $db_sections{mobyrelationship}->{dbname};
	    $m_service      = $db_sections{mobyservice}->{dbname};
	    $m_namespace    = $db_sections{mobynamespace}->{dbname};
	    $m_central      = $db_sections{mobycentral}->{dbname};

	    $ready_to_go = 1;
	}

	# if the values havent been set, then prompt for them
	unless ($ready_to_go) {

	    say "  Installing the file '$apache_conf/mobycentral.config' ...";

	    # fill out mobycentral.config
	    ($username,      $password,    $url,
	     $port,          $m_object,    $m_relationship,
	     $m_service,     $m_namespace, $m_central,
	     $moby_username, $moby_password
	    ) = prompt_moby_config_info;

	    fill_out_moby_conf(
		"$apache_conf/mobycentral.config",
		$moby_username, $moby_password, $url,
		$port,          $m_object,          $m_relationship,
		$m_service,     $m_namespace,       $m_central
		);
	}

	# make sure that we have a root password/username
	unless ($username and $password) {
		$username = 
			prompt_user_input( "What is your root mysql username?", "root" );
		$password =
			prompt_user_input( "What is your root mysql users' password?", "" );
	}
	# now start creating the tables
	say "   creating the tables to use for the registry ...";
	my %dbsections = (
	    'mobycentral'      => $m_central,
	    'mobyobject'       => $m_object,
	    'mobyservice'      => $m_service,
	    'mobynamespace'    => $m_namespace,
	    'mobyrelationship' => $m_relationship
	    );

	my $clone = 0;
	my $central;
	$answer = pprompt( "Would you like to clone a mobycentral registry? [n] ",
			   -ynd => 'n' );
	if ($answer eq 'y') {
	    $clone = 1;
	    my %registries = (
		default => {
		    url => "http://moby.ucalgary.ca/moby/MOBY-Central.pl",
		    uri => "http://moby.ucalgary.ca/MOBY/Central"
		},
		testing => {
		    url => "http://bioinfo.icapture.ubc.ca/cgi-bin/mobycentral/MOBY-Central.pl",
		    uri => "http://bioinfo.icapture.ubc.ca/MOBY/Central"
		},
		IRRI => {
		    url => "http://cropwiki.irri.org/cgi-bin/MOBY-Central.pl",
		    uri => "http://cropwiki.irri.org/MOBY/Central"
		},

		#			localhost => {
		#					url=>"http://localhost/cgi-bin/MOBY-Central.pl",
		#					uri=>"http://localhost/MOBY/Central"
		#			},
		);
	    my $registry = pprompt( "What registry to use? [b] ",
				    -d => 'b',
				    -m => [ sort keys %registries ],
		);

	    $central = MOBY::Client::Central->new(
		Registries => {
		    mobycentral => {
			URL => $registries{$registry}{url},
			URI => $registries{$registry}{uri}
		    }
		}
		);
	}
	my $error = 0;
	if ($clone) {
	    say "Getting db dumps ...";
	    my ($mobycentral,   $mobyobject, $mobyservice,
		$mobynamespace, $mobyrelationship
		) = $central->MOBY::Client::Central::DUMP();
	    my $drh = DBI->install_driver("mysql");
	    # used for creating the user/pass for the registry
	    my $dbh = DBI->connect("DBI:mysql:mysql:localhost:3306", "$username", "$password", { RaiseError => 1, AutoCommit => 1 });
	    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
	    say "Processing dump for service instances ...";
	    print $fh $mobycentral;
	    eval {
		$drh->func( 'dropdb', $dbsections{mobycentral},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
		$drh->func( 'createdb', $dbsections{mobycentral},
			    $url, $username, $password, 'admin' );
	    };
		eval {
			my $db = $dbsections{mobycentral} . ".*";
			$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
			  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
		};
		die $! if $!;
	    system( "mysql -h $url -P $port -u $username --password=$password "
		    . $dbsections{mobycentral}
		    . "<$filename" ) == 0
			or ( say "Error populating service instance ontology ...\n$!"
			     and $error++ );

	    ( $fh, $filename ) = tempfile( UNLINK => 1 );
	    say "Processing dump for the objects ontology ...";
	    print $fh $mobyobject;
	    eval {
		$drh->func( 'dropdb', $dbsections{mobyobject}, $url, $username,
			    $password, 'admin' );
	    };
	    eval {
		$drh->func( 'createdb', $dbsections{mobyobject}, $url,
			    $username, $password, 'admin' );
	    };
	    eval {
			my $db = $dbsections{mobyobject} . ".*"; 
			$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
			  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
		};
	    system( "mysql -h $url -P $port -u $username --password=$password "
		    . $dbsections{mobyobject}
		    . "<$filename" ) == 0
			or
			( say "Error populating objects ontology ...\n$!" and $error++ );

	    ( $fh, $filename ) = tempfile( UNLINK => 1 );
	    say "Processing dump for service types ...";
	    print $fh $mobyservice;
	    eval {
		$drh->func( 'dropdb', $dbsections{mobyservice},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
		$drh->func( 'createdb', $dbsections{mobyservice},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
			my $db = $dbsections{mobyservice} . ".*"; 
			$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
			  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
		};
	    system( "mysql -h $url -P $port -u $username --password=$password "
		    . $dbsections{mobyservice}
		    . "<$filename" ) == 0
			or ( say "Error populating service types ontology ...\n$!"
			     and $error++ );

	    ( $fh, $filename ) = tempfile( UNLINK => 1 );
	    say "Processing dump for the namespace ontology ...";
	    print $fh $mobynamespace;
	    eval {
		$drh->func( 'dropdb', $dbsections{mobynamespace},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
		$drh->func( 'createdb', $dbsections{mobynamespace},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
			my $db = $dbsections{mobynamespace} . ".*";  
			$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
			  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
		};
	    system( "mysql -h $url -P $port -u $username --password=$password "
		    . $dbsections{mobynamespace}
		    . "<$filename" ) == 0
			or ( say "Error populating namespace ontology ...\n$!"
			     and $error++ );

	    ( $fh, $filename ) = tempfile( UNLINK => 1 );
	    say "Processing dump for the relationships ontology ...";
	    print $fh $mobyrelationship;
	    eval {
		$drh->func( 'dropdb', $dbsections{mobyrelationship},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
		$drh->func( 'createdb', $dbsections{mobyrelationship},
			    $url, $username, $password, 'admin' );
	    };
	    eval {
			my $db = $dbsections{mobyrelationship} . ".*";  
			$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
			  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
		};
	    system( "mysql -h $url -P $port -u $username --password=$password "
		    . $dbsections{mobyrelationship}
		    . "<$filename" ) == 0
			or ( say "Error populating relationships ontology ...\n$!"
			     and $error++ );

	} else {

	    # no clone, so create minimalist databases
	    my $drop_db = 0;

	    #ask for permission on dropping data from db ...
	    $answer = pprompt(
		"Shall I drop all pre-existing databases used by BioMOBY? [n] ",
		-ynd => 'n'
		);
	    if ($answer eq 'y') {
		$drop_db = 1;
	    }

	    #process each db
	    foreach my $section ( keys %dbsections ) {
			my $sqlfilepath = File::ShareDir::dist_file( 'MOBY',
								     "db/schema/$section.mysql" );
			my $drh = DBI->install_driver("mysql");
			# used for creating the user/pass for the registry
	    	my $dbh = DBI->connect("DBI:mysql:mysql:localhost:3306", "root", "root", { RaiseError => 1, AutoCommit => 1 });
			# drop the db
			eval {
			    $drh->func( 'dropdb', $dbsections{$section}, $url,
					$username, $password, 'admin' );
			} if $drop_db;
	
			# create the db
			eval {
			    $drh->func( 'createdb', $dbsections{$section}, $url,
					$username, $password, 'admin' );
			};

			# give moby_username permission to access it
			eval {
				my $db = $dbsections{$section} . ".*";  
				$dbh->do(prepare_query($db),undef,$moby_username,$moby_password)
				  || say ("Could not give '$moby_username' access to $db - Error:\n$DBI::errstr");
			};
			#create the tables in the db
			do {
			    say "\n\tProblem creating tables in the db: $section: $!";
			}
			unless system(
			    "mysql -h $url -P $port -u $username --password=$password "
			    . $dbsections{$section}
			    . "<$sqlfilepath" ) == 0;
			say "\tProcessing of $section completed ... ";
	    }
	    say "populating the tables with basic data ...";
	    %dbsections = (
		'mobyobject'       => $m_object,
		'mobyservice'      => $m_service,
		'mobyrelationship' => $m_relationship
		);
	    foreach my $section ( keys %dbsections ) {
			my $sqlfilepath =
			    File::ShareDir::dist_file( 'MOBY', "db/data/$section.data" );
			system(
			    "mysql -h $url -P $port -u $username --password=$password "
			    . $dbsections{$section}
			    . "<$sqlfilepath" ) == 0
				or (say "\n\tProblem populating the db: $section: $!" and $error++);
			say "\tPopulation processing for db $section completed ...";
	    }
	}

	say "Set up of mySQL complete!" if $error == 0;
	say
	    "There were some problems encountered. Please correct the errors and re-run this script!"
	    if $error > 0;
} 

$answer = pprompt( "Would you like to install the RESOURCES script? [y] ",
		   -ynd => 'y' );
if ($answer eq 'y') {
	my $exists = 0;

	# install the script, confirm if it exists
	if (-e "$apache_cgi/RESOURCES") {
	    $exists = 1;
	    $answer = pprompt( "The RESOURCES script already exists, overwrite? [n] ",
			       -ynd => 'n' );
	    if ($answer eq 'y') {
		$exists = 0;
	    }
	} 

	my $rdf_cache_location =
	  prompt_for_directory_expand(
	      "Where would you like to store the RDF cache?",
	      "$apache_base/moby_cache" );

	say
"Please make sure that you make that directory read/writable by your web server!\n";

	# copy the file
	if ($exists == 0) {
	    file_from_template(
		"$apache_cgi/RESOURCES",
		File::ShareDir::dist_file( 'MOBY', 'cgi/RESOURCES' ),
		'RESOURCES script',
		{ '#!/usr/bin/perl -w' => "#!$perl_exec", }
		)
	}

	# update mobycentral.config file to reflect the location of the script
	$answer = pprompt(
"Shall we update mobycentral.config to reflect the installation of this script? [y] ",
	    -ynd => 'y');
	if ($answer eq 'y') {

	    # confirm server name, etc then change the values
	    my $url = "http://localhost/cgi-bin";
	    $url = prompt_user_input(
		"Please enter the correct url to your cgi-bin directory: ",
		"$url" );

	    # make sure that the key resourceURL exists ...
	    my $search = search_config_file(
		"$apache_conf/mobycentral.config",
		{
		    'mobycentral' => {
			'resourceURL'  => 0,
			'allResources' => 0,
			'rdf_cache'    => 0,
		    },
		    'mobyobject'    => { 'resourceURL' => 0 },
		    'mobyservice'   => { 'resourceURL' => 0 },
		    'mobynamespace' => { 'resourceURL' => 0 },
		}
		);
	    add_missing_keys_to_config_file( "$apache_conf/mobycentral.config",
					     $search );

	    # copy the information
	    config_file_from_template(
		"$apache_conf/mobycentral.config",
		"$apache_conf/mobycentral.config",
		'MOBY/SQL Configuration file',

		# mysql settings
		{ 'rdf_cache' => "$rdf_cache_location" },

		# db section mappings
		{},

		# resource urls
		{
		    'ALL'           => "$url/RESOURCES/MOBY-S/FULL",
		    'mobycentral'   => "$url/RESOURCES/MOBY-S/ServiceInstances",
		    'mobyobject'    => "$url/RESOURCES/MOBY-S/Objects",
		    'mobynamespace' => "$url/RESOURCES/MOBY-S/Namespaces",
		    'mobyservice'   => "$url/RESOURCES/MOBY-S/Services",
		},

		# lsid info
		{}
		);
	  }
}

$answer = pprompt( "Would you like to install the LSID authority script? [y] ",
		   -ynd => 'y' );
if ($answer eq 'y') {

	# install the script, confirm if it exists
	my $exists = 0;
	if (-e "$apache_cgi/authority.pl") {
	    $exists = 1;
	    $answer = pprompt( "The authority script already exists, overwrite? [n] ",
			       -ynd => 'n' );
	    if ($answer eq 'y') {
		$exists = 0;
	    }
	} 

	file_from_template(
		"$apache_cgi/authority.pl",    
		File::ShareDir::dist_file( 'MOBY', 'cgi/authority.pl' ),
		'MOBY-Central LSID authority server file',
		{ '#!/usr/bin/perl -w' => "#!$perl_exec", }
	  )
	  if $exists == 0;

	# update mobycentral.config file to reflect the particulars of the script
	$answer = pprompt(
"Shall we update mobycentral.config to reflect the installation of this script? [y] ",
	    -ynd => 'y');
	if ($answer eq 'y') {

	    #ask for namespace/authority information

	    # make sure that the key lsid_namespace & lsid_authority exists ...
	    my $search = search_config_file(
		"$apache_conf/mobycentral.config",
		{
		    'mobycentral' => {
			'lsid_namespace' => 0,
			'lsid_authority' => 0,
		    },
		    'mobyobject' => {
			'lsid_namespace' => 0,
			'lsid_authority' => 0,
		    },
		    'mobyservice' => {
			'lsid_namespace' => 0,
			'lsid_authority' => 0,
		    },
		    'mobynamespace' => {
			'lsid_namespace' => 0,
			'lsid_authority' => 0,
		    },
		    'mobyrelationship' => {
			'lsid_namespace' => 0,
			'lsid_authority' => 0,
		    },
		}
		);
		add_missing_keys_to_config_file( "$apache_conf/mobycentral.config",
						 $search );

		# copy the information
		config_file_from_template(
			"$apache_conf/mobycentral.config",
			"$apache_conf/mobycentral.config",
			'MOBY/SQL Configuration file',

			# mysql settings
			{},

			# db section mappings
			{},

			# resource urls
			{},

			# lsid info
			{
			   'mobycentral' => {
			       'NAMESPACE' => prompt_user_input(
"Please enter an LSID namespace for the services ontology: ",
				   "serviceinstance"
				   ),
				   'AUTHORITY' => prompt_user_input(
				       "Please enter the LSID authority for services: ",
				       "biomoby.org"
				   ),
			   },
			   'mobyobject' => {
				   'NAMESPACE' => prompt_user_input(
"Please enter an LSID namespace for the datatype ontology: ",
				       "objectclass"
				   ),
				   'AUTHORITY' => prompt_user_input(
"Please enter the LSID authority for datatypes: ",
				       "biomoby.org"
				   ),
			   },
			   'mobyservice' => {
				   'NAMESPACE' => prompt_user_input(
"Please enter an LSID namespace for the service types ontology: ",
				       "servicetype"
				   ),
				   'AUTHORITY' => prompt_user_input(
"Please enter the LSID authority for service types: ",
				       "biomoby.org"
				   ),
			   },
			   'mobynamespace' => {
				   'NAMESPACE' => prompt_user_input(
"Please enter an LSID namespace for the namespaces ontology: ",
				       "namespacetype"
				   ),
				   'AUTHORITY' => prompt_user_input(
"Please enter the LSID authority for namespaces: ",
				       "biomoby.org"
				   ),
			   },
			   'mobyrelationship' => {
				   'NAMESPACE' => prompt_user_input(
"Please enter an LSID namespace for the relationship ontology: ",
				       "relationshiptype"
				   ),
				   'AUTHORITY' => prompt_user_input(
"Please enter the LSID authority for relationships: ",
				       "biomoby.org"
				   ),
			   },
			}
		    );
	}
	
	# tell the user to make sure that apache serves the script from
	# http://domain.com/authority

	say <<EOT;
Please ensure that you set up apache to serve the script from:

    'http://your.domain/authority'

so that the script will work properly!
EOT
}

$answer = pprompt(
"Would you like to auxillary scripts? These include the service pinger, unit tester, a test page for the rdf agent, an RDF generator page, etc? [y] ",
	-ynd => 'y'
    );
if ($answer eq 'y') {

	# prompt for a location for the service_tester_path
	my $service_tester_path =
	  prompt_for_directory_expand(
	      "Where would you like to place the service pinger script?",
	      "$apache_base/moby_tester" );
	say
'Please make sure that you make that directory read/writable by your web server!\n';

	# make sure that the key service_tester_path exists for the config file
	my $search = search_config_file(
	    "$apache_conf/mobycentral.config",
	    { 'mobycentral' => { 'service_tester_path' => 0, } } 
	    );
	add_missing_keys_to_config_file( "$apache_conf/mobycentral.config",
					 $search );

	# copy the information
	config_file_from_template(
		"$apache_conf/mobycentral.config",
		"$apache_conf/mobycentral.config",
		'MOBY/SQL Configuration file',

		# mysql settings
		{ 'service_tester_path' => "$service_tester_path" },

		# db section mappings
		{},

		# resource urls
		{},

		# lsid info
		{}
	);

	file_from_template(
	    "$service_tester_path/service_tester.pl",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/service_tester.pl'
	    ),
	    'MOBY-Central service tester script',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	);
	say
'Please don\'t forget to place the service pinger on a cron!';

	# copy the service unit tester script
    file_from_template(
	    "$service_tester_path/service_unit_tester.pl",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/service_unit_tester.pl'
	    ),
	    'MOBY-Central service unit tester script',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	);
	say
'Please don\'t forget to place the service unit tester on a cron!';

	#copy the other scripts now
	file_from_template(
	    "$apache_cgi/AgentRDFValidator",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/AgentRDFValidator'
	    ),
	    'The RDF agent validator page',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
	file_from_template(
	    "$apache_cgi/GenerateRDF.cgi",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/GenerateRDF.cgi'
	    ),
	    'MOBY-Central service instance RDF generating form',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
	file_from_template(
	    "$apache_cgi/Moby",
	    File::ShareDir::dist_file( 'MOBY', 'cgi/Moby' ),
	    'MOBY-Central test page for auxillary scripts',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
	file_from_template(
	    "$apache_cgi/BioMobyWSDL",
	    File::ShareDir::dist_file( 'MOBY', 'cgi/BioMobyWSDL' ),
	    'MOBY-Central RESTful WSDL generator',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
	file_from_template(
	    "$apache_cgi/ServicePingerValidator",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/ServicePingerValidator'
	    ),
	    'MOBY-Central service invocation test form',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
	file_from_template(
	    "$apache_cgi/ValidateService",
	    File::ShareDir::dist_file(
		'MOBY', 'cgi/ValidateService'
	    ),
	    'MOBY-Central service tester information page',
	    { '#!/usr/bin/perl -w' => "#!$perl_exec", }
	    );
}
#

say
"Please remember to set up the RDF agent! Just restart apache and your registry has been set up!\n\nDone.";

package SimplePrompt;

use vars qw/ $Terminal /;

sub prompt {
	my ( $msg, $flags, $others ) = @_;

	# simple prompt
	return get_input($msg)
	  unless $flags;

	$flags =~ s/^-//o;    # ignore leading dash

	# 'waiting for yes/no' prompt, possibly with a default value
	if ( $flags =~ /^yn(d)?/i ) {
		return yes_no( $msg, $others );
	}

	# prompt with a menu of possible answers
	if ( $flags =~ /^m/i ) {
		return menu( $msg, $others );
	}

	# default: again a simple prompt
	return get_input($msg);
}

sub yes_no {
	my ( $msg, $default_answer ) = @_;
	while (1) {
		my $answer = get_input($msg);
		return $default_answer if $default_answer and $answer =~ /^\s*$/o;
		return 'y' if $answer =~ /^(1|y|yes|ano)$/;
		return 'n' if $answer =~ /^(0|n|no|ne)$/;
	}
}

sub get_input {
	my ($msg) = @_;
	local $^W = 0;
	my $line = $Terminal->readline($msg);
	chomp $line;    # remove newline
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;    # trim whitespaces
	$Terminal->addhistory($line) if $line;
	return $line;
}

sub menu {
	my ( $msg, $ra_menu ) = @_;
	my @data = @$ra_menu;

	my $count = @data;

	#    die "Too many -menu items" if $count > 26;
	#    die "Too few -menu items"  if $count < 1;

	my $max_char = chr( ord('a') + $count - 1 );
	my $menu     = '';

	my $next = 'a';
	foreach my $item (@data) {
		$menu .= '     ' . $next++ . '.' . $item . "\n";
	}
	while (1) {
		print STDOUT $msg . "\n$menu";
		my $answer = get_input(">");

		# blank and escape answer accepted as undef
		return undef if $answer =~ /^\s*$/o;
		return undef
		  if length $answer == 1 && $answer eq "\e";

		# invalid answer not accepted
		if ( length $answer > 1 || ( $answer lt 'a' || $answer gt $max_char ) )
		{
			print STDOUT "(Please enter a-$max_char)\n";
			next;
		}

		# valid answer
		return $data[ ord($answer) - ord('a') ];
	}
}

__END__
