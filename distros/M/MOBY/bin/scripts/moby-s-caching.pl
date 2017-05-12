#!/usr/bin/perl -w
#
# Prepare the stage...
#
# $Id: moby-s-caching.pl,v 1.2 2008/07/07 17:59:41 kawas Exp $
# Contact: Edward Kawas <edward.kawas@gmail.com>
# -----------------------------------------------------------

BEGIN {
	use Getopt::Std;
	use vars qw/ $opt_h $opt_d /;
	getopts('hd:');

	use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

	# usage
	if ($opt_h or @ARGV == 0) {
		print STDOUT <<'END_OF_USAGE';
Help on creating your registry RDF cache.
Usage: moby-s-caching.pl [-h] [-d cache-dir] cache-owner

	-d          ..... the directory that you would like 
					  to write the cache. 

					  This value is extracted from 
					  MOBY_CENTRAL_CONFIG when it is
					  not specified.

	cache-owner ..... the owner of the cache; once the
	                  cache is created, ownership of the 
	                  cache dir and all its contained 
	                  files are given to this cache-owner.
	                  
	                  NOTE: If running this to update the
	                  cache for your registry, make sure
	                  to put here the value of the username
	                  for your web server!

	-h          ..... shows this message

	If you are running this as root and the user environment is not being set
	appropriately (for one reason or another), try running the script like the
	following:
		sudo -E moby-s-caching.pl [rest of arguments]

    Good luck!


END_OF_USAGE
		exit(0);
	}

	sub say { print @_; }

}

use English qw( -no_match_vars );
use strict;

# performs a chown on a list of files and then returns the number of changed files
sub chown_by_name {
	return 0 if (MSWIN);
	my ( $uid, $guid, @files ) = @_;
	return chown($uid, $guid, @files );
}

# performs a chmod on a list of files and returns the number of changed files
# UGO == UG{rw}, O{r}
sub chmod_by_name {
	my (@files) = @_;
	my $mode = 0664;
	return chmod $mode, @files;
}

sub check_root {

	# assume that windows has no security preventing the copying of files
	return if (MSWIN);

	unless ( getpwuid($<) eq 'root' ) {
		print STDOUT <<EOT;

Hmmm - you are not running this as root. If you indicate any
system directories for the installation, such as '/usr/local/apache/', then
you may not have permission to install files there. If so, you should
cancel now with ^C, su to root, and restart.

EOT

		print STDOUT "Should I proceed? [n] ";
		my $tmp = <STDIN>;
		$tmp =~ s/\s//g;
		exit() unless $tmp =~ /y/i;
	} else {
		print STDOUT <<EOT;

Take care! you are running this as ** root **. Please take the normal 
precautions that you would ordinarily take when running software as root. 
In particular, be careful with ownership, paths, and environment variables.

EOT

	}
}

# --- main ---
use MOBY::Config;
use MOBY::Client::Central;
use MOBY::RDF::Ontologies::Cache::NamespaceCache;
use MOBY::RDF::Ontologies::Cache::ObjectCache;
use MOBY::RDF::Ontologies::Cache::ServiceCache;
use MOBY::RDF::Ontologies::Cache::ServiceTypeCache;

no warnings 'once';

# give a waring if we are not running with su privelege
check_root();

say "Preparing for cache creation ...\n\n";

my $cache_dir    = undef;
my $cache_owner  = shift; #ARGV checked in BEGIN
my ($login,$pass,$uid,$gid) = getpwnam($cache_owner) or die "User '$cache_owner' doesn't seem to exist!\n\tPlease check the username and try again.\n\n$!";
my $registry_url = undef;
$registry_url = $ENV{MOBY_SERVER} if $ENV{MOBY_SERVER};

if ($opt_d) {
	$cache_dir = $opt_d;
	$cache_dir =~ s/^ //;
	$cache_dir =~ s/ $//;

	# dont check for existence
} else {
	my $c = MOBY::Config->new();
	$cache_dir = $c->{mobycentral}->{rdf_cache}
	  || die
"Unfortunately, I could not determine where it is that you store your RDF cache ...\n"
	  . "Please run this script again using the -d option!\n";

	$cache_dir = $cache_dir . "/" unless $cache_dir =~ m/.*\/$/;
}

# set up registry_url
do {
	my $c = MOBY::Client::Central->new();
	$registry_url = $c->{default_MOBY_server};
} unless $registry_url;

say "Creating cache ...\n";

say "\tCreating datatype cache ... ";
my $x = MOBY::RDF::Ontologies::Cache::ObjectCache->new(
			endpoint  => $registry_url,
			cache     => $cache_dir,
);
$x->create_object_cache();
say"Done!\n";
say "\tCreating service type cache ... ";
$x = MOBY::RDF::Ontologies::Cache::ServiceTypeCache->new(
			endpoint  => $registry_url,
			cache     => $cache_dir,
);
$x->create_service_type_cache();
say"Done!\n";
say "\tCreating namespace cache ... ";
$x = MOBY::RDF::Ontologies::Cache::NamespaceCache->new(
			endpoint  => $registry_url,
			cache     => $cache_dir,
);
$x->create_namespace_cache();
say"Done!\n";
say "\tCreating services cache ... ";
$x = MOBY::RDF::Ontologies::Cache::ServiceCache->new(
			endpoint  => $registry_url,
			cache     => $cache_dir,
);
$x->create_service_cache();
say"done!\n\n";
say "Setting permissions for the cache ...\n";
my $dirs = $x->{utils}->get_cache_dirs();
while ( my ( $key, $value ) = each( %{$dirs} ) ) {    
	say "\tUpdating permissions for '$value' ...\n";
	say "\t\tchown of $value: " . chown_by_name($uid, $gid, $value) . " files updated.\n";
	say "\t\tchown of all files in $value: " . chown_by_name($uid, $gid, <$value/*>) . " files updated.\n";
} 

say "Done!\n";

__END__
