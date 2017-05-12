#!/usr/bin/perl -w
#
# Print the current status of configuration and logging files.
#
# $Id: moses-cache-tester.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_d $opt_e $opt_s $opt_m $opt_v /;
getopt;

# usage
if ($opt_h) {
    print STDOUT <<'END_OF_USAGE';
Generate/Update your cache
Usage: [-vdesm] [-u registry_url -n registry_uri]

    It also needs those configuration files it reports on
    (but if they do not exists it will be reported, as well).

    -v ... verbose
    -d ... create/overwrite datatype cache
    -e ... update datatype cache
    -s ... create/overwrite service cache
    -m ... update service cache
    -h ... help
END_OF_USAGE
    exit (0);
}
# -----------------------------------------------------------

use File::HomeDir;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Base; 
use Data::Dumper;
use MOSES::MOBY::Generators::GenTypes;
use strict;
use warnings;

my $cache = MOSES::MOBY::Cache::Central->new (
		cachedir => $MOBYCFG::CACHEDIR,
    	registry => $MOBYCFG::REGISTRY);

print Dumper($cache);
print Dumper(MOSES::MOBY::Generators::GenTypes->new);
#$cache->update_service_cache();
#$cache->create_service_cache();

__END__


