#!/usr/bin/perl -w
#
# Prepare the stage...
#
# $Id: moses-install.pl,v 1.7 2009/04/08 22:42:51 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

BEGIN {
    use Getopt::Std;
    use vars qw/ $opt_h $opt_F /;
    getopt;

    # usage
    if ($opt_h) {
	print STDOUT <<'END_OF_USAGE';
Preparing stage for generating and running BioMoby services.
Usage: [-F]

    It creates necessary files (some of them by copying from
    their templates):
       moby-services.cfg
       log4perl.properties
       services.log
       parser.log
       MobyServer.cgi
       AsyncMobyServer.cgi
    The existing files are not overwritten - unless an option -F
    has been used.

    It also creates and/or updates local cache of BioMoby
    registries (after your confirmation).
END_OF_USAGE
    exit (0);
    }

    my $errors_found = 0;

    sub say { print @_, "\n"; }

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

    say 'Welcome, BioMobiers. Preparing stage for Perl MoSeS...';
    say '------------------------------------------------------';

    # check needed modules
    foreach $module ( qw (
			  FindBin
			  SOAP::Lite
			  XML::LibXML
			  Log::Log4perl
			  Template
			  Config::Simple
			  IO::Scalar
			  Unicode::String
			  ) ) {
		check_module ($module);
    }
    # check for async libraries if user wants to ....
    print STDOUT "Shall we check for the moby-async libraries\n\t(do this only if you plan on creating soap based\n\t async moby services)? y/n [n]";
    my $tmp = <STDIN>;
    $tmp =~ s/\s//g; 
    if ($tmp =~ /y/i) {
    	check_module('MOBY::Client::Central');
		check_module('WSRF::Lite'); 
    }

    if (MSWIN) {
		check_module ('Term::ReadLine');
	{
	    local $^W = 0;
	    $SimplePrompt::Terminal = Term::ReadLine->new ('Installation');
	}
    } else {
	check_module ('IO::Prompt');
	require IO::Prompt; import IO::Prompt;
    }
    if ($errors_found) {
	say "\nSorry, some needed modules were not found.";
	say "Please install them and run 'install.pl' again.";
	exit (1);
    }
    say;
}
use File::HomeDir;
use File::ShareDir;
use File::Spec;
use MOSES::MOBY::Base;
use File::HomeDir;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Cache::Registries;
use English qw( -no_match_vars ) ;
use strict;

# different prompt modules used for different OSs
# ('pprompt' as 'proxy_prompt')
sub pprompt {
    return prompt (@_) unless MSWIN;
    return SimplePrompt::prompt (@_);
}

# $prompt ... a prompt asking for a directory
# $prompted_dir ... suggested directory
sub prompt_for_directory {
    my ($prompt, $prompted_dir) = @_;
    while (1) {
	my $dir = pprompt ("$prompt [$prompted_dir] ");
	$dir =~ s/^\s*//; $dir =~ s/\s*$//;
	$dir = $prompted_dir unless $dir;
	return $dir if -d $dir and -w $dir;  # okay: writable directory
	$prompted_dir = $dir;
	next if -e $dir and say "'$dir' is not a writable directory. Try again please.";
	next unless pprompt ("Directory '$dir' does not exists. Create? ", -yn);

	# okay, we agreed to create it
	mkdir $dir and return $dir;
	say "'$dir' not created: $!";
    }
}

# what registry to use
sub prompt_for_registry {
    my $cache = new MOSES::MOBY::Cache::Central;
    my @regs = MOSES::MOBY::Cache::Registries->list;
    my $registry = pprompt ("What registry to use? [default] ",
			   -m => [@regs]);
    return $registry ||= 'default';
}

# create a file from a template
#  - from $file_template to $file,
#  - $file_desc used in messages,
#  - hashref $filters tells what to change in template
sub file_from_template {
    my ($file, $file_template, $file_desc, $filters) = @_;
    eval {
	open FILETEMPL, "<$file_template"
	    or die "Cannot read template file '$file_template': $!\n";
	open FILEOUT, ">$file"
	    or die "Cannot open '$file' for writing: $!\n";
	while (<FILETEMPL>) {
	    foreach my $token (keys %$filters) {
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
	say "\n$file_desc created: '$file'\n";
    }
}


# --- main ---
no warnings 'once';

my $pmoses_home = File::Spec->catdir(File::HomeDir->my_home, "Perl-MoSeS");
my $jmoby_home = File::Spec->catdir(File::HomeDir->my_home, "Perl-MoSeS");
my $samples_home = File::Spec->catdir(File::HomeDir->my_home, "Perl-MoSeS", "sample-resources");
say "Installing in $pmoses_home\n";

# create install directory if necessary
eval {
	my ($v, $d, $f) = File::Spec->splitpath( $pmoses_home );
	my $dir = File::Spec->catdir($v);
	foreach my $part ( File::Spec->splitdir( ($d.$f ) ) ) {
	   	$dir = File::Spec->catdir($dir, $part);
   		next if -d $dir or -e $dir;
	    mkdir( $dir ) || die("Error creating installation directory directory '".$dir."':\n$!");
	}
};
say $@ ? $@ : "Created install directory '$pmoses_home'.";

# create install directory if necessary
eval {
	my ($v, $d, $f) = File::Spec->splitpath( $pmoses_home . "/cgi" );
	my $dir = File::Spec->catdir($v);
	foreach my $part ( File::Spec->splitdir( ($d.$f ) ) ) {
	   	$dir = File::Spec->catdir($dir, $part);
   		next if -d $dir or -e $dir;
	    mkdir( $dir ) || die("Error creating installation directory directory '".$dir."':\n$!");
	}
};
say $@ ? $@ : "Created install directory '$pmoses_home/cgi'.";

# create install directory if necessary
eval {
	my ($v, $d, $f) = File::Spec->splitpath( $samples_home );
	my $dir = File::Spec->catdir($v);
	foreach my $part ( File::Spec->splitdir( ($d.$f ) ) ) {
	   	$dir = File::Spec->catdir($dir, $part);
   		next if -d $dir or -e $dir;
	    mkdir( $dir ) || die("Error creating installation directory directory '".$dir."':\n$!");
	}
};
say $@ ? $@ : "Created sample-resources directory '$samples_home'.";


# log files (create, or just change their write permissions)
my $log_file1 = $MOBYCFG::LOG_FILE || File::Spec->catfile("$pmoses_home","services.log");
my $log_file2 = File::Spec->catfile("$pmoses_home","parser.log");
foreach my $file ($log_file1, $log_file2) {
    unless (-e $file) {
	eval {
	    open LOGFILE, ">$file" or die "Cannot create file '$file': $!\n";
	    close LOGFILE or die "Cannot create file '$file': $!\n";
	};
	say $@ ? $@ : "Created log file '$file'.";
    }
    chmod 0666, $file;   # just in case a web server will be writing here
}

# log4perl property file (will be found and used, or created)
my $log4perl_file = $MOBYCFG::LOG_CONFIG || File::Spec->catfile("$pmoses_home" ,"log4perl.properties");
if (-e $log4perl_file and ! $opt_F) {
    say "\nLogging property file '$log4perl_file' exists.";
    say "It will not be overwritten unless you start 'install.pl -F'.\n";
} else {
    file_from_template
	($log4perl_file,
	 File::ShareDir::dist_file('MOSES-MOBY', 'log4perl.properties.template'),
	 'Log properties file',
	 { '@LOGFILE@'  => $log_file1,
	   '@LOGFILE2@' => $log_file2,
       } );
}

# MobyServer.cgi file
my $generated_dir = $MOBYCFG::GENERATORS_OUTDIR ||
    "$pmoses_home/generated";
my $services_dir = $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
    "$pmoses_home/services";
my $services_table = $MOBYCFG::GENERATORS_IMPL_SERVICES_TABLE ||
    'SERVICES_TABLE';
my $async_services_table = $MOBYCFG::GENERATORS_IMPL_SERVICES_TABLE ||
    'ASYNC_SERVICES_TABLE';

my $cgibin_file = "$pmoses_home/MobyServer.cgi";
if (-e $cgibin_file and ! $opt_F) {
    say "\nWeb Server file '$cgibin_file' exists.";
    say "It will not be overwritten unless you start 'install.pl -F'.\n";
} else {
    file_from_template
	($cgibin_file,
	 File::ShareDir::dist_file('MOSES-MOBY','MobyServer.cgi.template'),
	 'Web Server file',
	 { '@PMOSES_HOME@'    => $pmoses_home,
	   '@GENERATED_DIR@'  => $generated_dir,
	   '@SERVICES_DIR@'   => $services_dir,
	   '@SERVICES_TABLE@' => $services_table,
       } );
    chmod 0755, $cgibin_file;   # everybody can execute
}

# AsyncMobyServer.cgi file

my $async_cgibin_file = "$pmoses_home/AsyncMobyServer.cgi";
if (-e $async_cgibin_file and ! $opt_F) {
    say "\nWeb Server file '$async_cgibin_file' exists.";
    say "It will not be overwritten unless you start 'install.pl -F'.\n";
} else {
    file_from_template
	($async_cgibin_file,
	 File::ShareDir::dist_file('MOSES-MOBY','AsyncMobyServer.cgi.template'),
	 'Web Server file',
	 { '@PMOSES_HOME@'    => $pmoses_home,
	   '@GENERATED_DIR@'  => $generated_dir,
	   '@SERVICES_DIR@'   => $services_dir,
	   '@ASYNC_SERVICE_TABLE@' => $async_services_table,
       } );
    chmod 0755, $async_cgibin_file;   # everybody can execute
}

# directory for local cache
my $cachedir = $MOBYCFG::CACHEDIR ||
    prompt_for_directory ( 'Directory for local cache',
			   File::Spec->catdir("$jmoby_home","myCache"));
say "Local cache in '$cachedir'.\n";

# filling/updating local cache
my $registry = 'default';
if ('y' eq pprompt ('Should I try to fill or update the local cache [y]? ', -ynd=>'y')) {
    $registry = prompt_for_registry;
    my $details =
	MOSES::MOBY::Cache::Registries->get ($registry);
    if ($details) {
		my $endpoint = $details->{endpoint};
		my $uri = $details->{namespace};
		say 'Using registry: ' . $registry;
		say "(at $endpoint)\n";
	
		my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $cachedir, registry=>$registry);
		say "Getting the BioMOBY datatypes ...\n";
		eval {
			$cache->update_datatype_cache();
		};
		eval {
				$cache->create_datatype_cache();
		} if $@;
		
		say "Getting the BioMOBY services ...\n";
		eval {
			$cache->update_service_cache();
		};
		eval {
				$cache->create_service_cache();
		} if $@;
		
		say "ERROR: There was a problem updating the cache." if $@;
    }
	
}
    
# configuration file (will be found and used, or created)
my $config_file = File::Spec->catfile
    ($ENV{$MOSES::MOBY::Config::ENV_CONFIG_DIR} || $pmoses_home,
     $MOSES::MOBY::Config::DEFAULT_CONFIG_FILE);
if (-e $config_file and ! $opt_F) {
    say "Configuration file $config_file exists.";
    say "It will be used and not overwritten unless you start 'install.pl -F'.\n";
} else {
    file_from_template
	($config_file,
	 File::ShareDir::dist_file('MOSES-MOBY','moby-services.cfg.template'),
	 'Configuration file',
	 { '@CACHE_DIR@'        		=> $cachedir,
	   '@REGISTRY@'         		=> $registry,
	   '@GENERATED_DIR@'    		=> $generated_dir,
	   '@SERVICES_DIR@'     		=> $services_dir,
	   '@SERVICES_TABLE@'   		=> $services_table,
	   '@ASYNC_SERVICES_TABLE@'   	=> $async_services_table,
	   '@LOG4PERL_FILE@'    		=> $log4perl_file,
	   '@LOGFILE@'          		=> $log_file1,
	   '@USER_REGISTRIES_FILE_DIR@'	=> $pmoses_home,
	   '@MABUHAY_RESOURCE@' =>
	       "$samples_home/mabuhay.file",
	   } );
}

# install the mabuhay_file 
my $mabuhay_file =  $MOBYCFG::MABUHAY_RESOURCE || File::Spec->catfile("$samples_home","mabuhay.file"); #"$pmoses_home/samples-resources/mabuhay.file";
if (-e $mabuhay_file and ! $opt_F) {
    say "Mabuhay file $mabuhay_file exists.";
    say "It will be used and not overwritten unless you start 'install.pl -F'.\n";
} else {
file_from_template
	($mabuhay_file,
	 File::ShareDir::dist_file('MOSES-MOBY', 'mabuhay.file'),
	 'Mabuhay Resource File',
	 {} );
}

# install the user_registries file 
my $registries_file =  "$MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR/$MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME" 
	if $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR and $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME;
$registries_file = File::Spec->catfile("$pmoses_home","USER_REGISTRIES") if not $registries_file or $registries_file eq "";
if (-e $registries_file and ! $opt_F) {
    say "User Registrie file $registries_file exists.";
    say "It will be used and not overwritten unless you start 'install.pl -F'.\n";
} else {
file_from_template
	($registries_file,
	 File::ShareDir::dist_file('MOSES-MOBY', "USER_REGISTRIES"),
	 'User Registries File',
	 {} );
}

say 'Done.';

package SimplePrompt;

use vars qw/ $Terminal /;

sub prompt {
    my ($msg, $flags, $others) = @_;

    # simple prompt
    return get_input ($msg)
	unless $flags;

    $flags =~ s/^-//o;    # ignore leading dash

    # 'waiting for yes/no' prompt, possibly with a default value
    if ($flags =~ /^yn(d)?/i) {
	return yes_no ($msg, $others);
    }

    # prompt with a menu of possible answers
    if ($flags =~ /^m/i) {
	return menu ($msg, $others);
    }

    # default: again a simple prompt
    return get_input ($msg);
}

sub yes_no {
    my ($msg, $default_answer) = @_;
    while (1) {
	my $answer = get_input ($msg);
	return $default_answer if $default_answer and $answer =~ /^\s*$/o;
	return 'y' if $answer =~ /^(1|y|yes|ano)$/;
	return 'n' if $answer =~ /^(0|n|no|ne)$/;
    }
}

sub get_input {
    my ($msg) = @_;
    local $^W = 0;
    my $line = $Terminal->readline ($msg);
    chomp $line;                 # remove newline
    $line =~ s/^\s*//;  $line =~ s/\s*$//;   # trim whitespaces
    $Terminal->addhistory ($line) if $line;
    return $line;
}

sub menu {
    my ($msg, $ra_menu) = @_;
    my @data = @$ra_menu;

    my $count = @data;
#    die "Too many -menu items" if $count > 26;
#    die "Too few -menu items"  if $count < 1;

    my $max_char = chr(ord('a') + $count - 1);
    my $menu = '';

    my $next = 'a';
    foreach my $item (@data) {
        $menu .= '     ' . $next++ . '.' . $item . "\n";
    }
    while (1) {
	print STDOUT $msg . "\n$menu";
        my $answer = get_input (">");

	# blank and escape answer accepted as undef
	return undef if $answer =~ /^\s*$/o;
	return undef
	    if length $answer == 1 && $answer eq "\e";

	# invalid answer not accepted
	if (length $answer > 1 || ($answer lt 'a' || $answer gt $max_char) ) {
	    print STDOUT "(Please enter a-$max_char)\n";
	    next;
	}

	# valid answer
        return $data[ord($answer)-ord('a')];
    }
}


__END__
