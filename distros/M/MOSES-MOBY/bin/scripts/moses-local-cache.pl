#!/usr/bin/perl -w
#
# Accessing local cache of BioMoby registries.
#
# $Id: moses-local-cache.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_d $opt_v $opt_x $opt_s $opt_t $opt_a $opt_l $opt_r $opt_c $opt_i /;
getopt;

# usage
if ($opt_h) {
    print STDOUT <<'END_OF_USAGE';
Accessing local cache of BioMoby registries.
Usage: # for data types
       [-vd] -lt
       [-vd] -[x]t data-type-name
       [-vd] -r data-type-name [data-type-name...]
       [-vd] -c data-type-name

       # for services
       [-vd] -a
       [-vd] -ls [authority]
       [-vd] -[x]s authority [service-name...]

       # for info
       [-vd] -i

    It also needs to get a location of a local cache (and potentially
    a BioMoby registry endpoint). It takes it from the
    'moby-service.cfg' configuration file.

    -t ... show given data type definition
    -r ... list names of all related data types
    -c ... list all children of a given data type
    -s ... show given service definitions, or all services from
           given authority
    -a ... list service authority names

    -l ... list names of all entities (must be accompanied by
           -t or -s, depending on what you want to print)

    -x ... print an XML representation of the obtained object
           (data type or service) - the output is equivalent to
           the XML used to register this object

    -i ... information about cached registries

    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
    exit (0);
}
# -----------------------------------------------------------

use strict;

use File::HomeDir;
use MOSES::MOBY::Base;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Cache::Registries;

$LOG->level ('INFO') if $opt_v;
$LOG->level ('DEBUG') if $opt_d;

sub say { print @_, "\n"; }

my $cache = new MOSES::MOBY::Cache::Central;

# --- get info
if ($opt_i) {
    say 'Currently used registry: ' . $cache->registry;
    say "(it can be changed in $MOSES::MOBY::Config::DEFAULT_CONFIG_FILE)\n";
    my $details =
	MOSES::MOBY::Cache::Registries->get ($cache->registry) ||
	MOSES::MOBY::Cache::Registries->get ('default');
    foreach my $key (sort keys %{ $details }) {
	printf "   %-12s: %-s\n", $key, $details->{$key};
    }
    say;

    say "Statictics for all locally cached registries:\n";
    printf
	"%-13s %+13s %+13s %+10s\n",
	'Registry', 'Data types', 'Authorities', 'Services';
    foreach my $reg (MOSES::MOBY::Cache::Registries->list) {
	next unless $cache->cache_exists ($reg);
	my $new_cache = new MOSES::MOBY::Cache::Central ( registry => $reg );
	my $datatypes_count = $new_cache->get_datatype_names;
	my %authorities = $new_cache->get_service_names;
	my $services_count = 0;
	foreach my $service_chunk (values %authorities) {
	    $services_count += @{$service_chunk};
	}
	printf
	    "%-13s %+13u %+13u %+10u\n",
	    $reg, $datatypes_count, (0 + keys %authorities), $services_count;
    }
}

# --- get data types
if ($opt_t) {
    if ($opt_l) {
	# getting a list of names
	say join ("\n", sort $cache->get_datatype_names);
    } else {
	# getting data type[s]
	my $result = $cache->get_datatype (@ARGV);
	# ...and printing them
	if ($opt_x) {
	    say $result->toXML->toString(1);
	} else {
	    say $result;
	}
    }
}

# --- get related data types
if ($opt_r and @ARGV) {
    my @wanted_objs = map { $cache->get_datatype ($_) } @ARGV;
    say join ("\n",
	      sort map { $_->name } @{ $cache->get_related_types (@wanted_objs) });
}

# --- get children
if ($opt_c and @ARGV) {
    say "All children of '$ARGV[0]':";
    print $_ foreach $cache->get_all_children ($ARGV[0]);
}

# --- get authorities
if ($opt_a) {
    say join ("\n", sort keys %{ { $cache->get_service_names } } );
}

# --- get services
if ($opt_s) {
    if ($opt_l) {
	# getting a list of services
	my %by_authorities = $cache->get_service_names;
	if (@ARGV) {
	    say join ("\n", @{ $by_authorities{$ARGV[0]} });
	} else {
	    foreach my $authority (sort keys (%by_authorities)) {
		say "\nAuthority: $authority";
		say join ("\n", @{ $by_authorities{$authority} });
	    }
	}
    } else {
	# getting service[s]
	my @result = $cache->get_services (@ARGV);
	# ...and printing them
	if ($opt_x) {
	    say $_->toXML->toString(1) foreach @result;
	} else {
	    say $_ foreach @result;
	}
    }
}

__END__
