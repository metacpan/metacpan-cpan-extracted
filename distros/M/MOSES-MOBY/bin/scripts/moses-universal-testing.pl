#!/usr/bin/perl -w
#
# Generate and call all BioMoby services (without SOAP).
#
# $Id: moses-universal-testing.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_v $opt_d $opt_h /;
getopt;

# usage
if ($opt_h) {
    print STDOUT <<'END_OF_USAGE';
A testing tool for Perl-Moses developers.
Generate and call all BioMoby services (without using SOAP, just locally).
Work in progess...
Usage: [-vd] [authority] [service]

    It also needs to get a location of a local cache (and potentially
    a BioMoby registry endpoint). It takes it from the
    'moby-service.cfg' configuration file.

    authority  ... do it only for services from this authority
                 Default: do it for all authorities
    service    ... do it only for this service

    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
    exit (0);
}

use Carp;
use strict;

use MOSES::MOBY::Base;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Generators::GenServices;
use File::Spec;

$LOG->level ('INFO') if $opt_v;
$LOG->level ('DEBUG') if $opt_d;

sub say { print @_, "\n"; }

my $cache = new MOSES::MOBY::Cache::Central;
my $tmpdir = File::Spec->tmpdir();

# create an empty XML input
my $empty_xml = File::Spec->catfile ($tmpdir, "empty.$$.xml");
open EMPTY, ">$empty_xml" or die "Cannot write to $empty_xml: $!\n";
print EMPTY <<'END_OF_XML';
<?xml version="1.0" encoding="UTF-8"?>
<moby:MOBY xmlns:moby="http://www.biomoby.org/moby">
  <moby:mobyContent>
    <moby:mobyData moby:queryID="job_0">
    </moby:mobyData>
  </moby:mobyContent>
</moby:MOBY>
END_OF_XML
close EMPTY or die "Cannot close $empty_xml: $!\n";

# service generator
my $outdir = File::Spec->catfile ($tmpdir, 'generated-services');
MOSES::MOBY::Config->param ('generators.impl.outdir', $outdir);
MOSES::MOBY::Config->param ('generators.impl.package.prefix', 'Testing');
unshift (@INC, $MOBYCFG::GENERATORS_IMPL_OUTDIR);
my $generator = new MOSES::MOBY::Generators::GenServices;

# outputs
my $outputs = File::Spec->catfile ($tmpdir, 'generated-outputs');
mkdir $outputs;

say "Services will be generated into:   $MOBYCFG::GENERATORS_IMPL_OUTDIR";
say "Services will be in package:       ${MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX}::<service-name>";
say "Services outputs will be saved in: $outputs";
say '----------------------------------';

my $only_athority = $ARGV[0] || '';
my $only_service  = $ARGV[1] || '';

# getting a list of services
my %by_authorities = $cache->get_service_names;
foreach my $authority (sort keys (%by_authorities)) {
    next if $only_athority and $only_athority ne $authority;

    foreach my $service (@{ $by_authorities{$authority} }) {
	next if $only_service and $only_service ne $service;

	# check the black list
	next if &filter ($authority, $service);

	say "Service: $authority\t$service";

	# generate service
	$generator->generate_impl (service_names => [$service],
				   authority     => $authority,
				   force_over    => 1);
        # call service
        my $outfile = File::Spec->catfile ($outputs, $service.'-output.xml');
	my $module = "${MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX}::$service";
	eval "require $module" or croak $@;
	eval {
	    my $target = new $module;
	    my $output = $target->$service ($empty_xml);
	    open OUTPUT, ">$outfile" or die "Cannot open for writing $outfile: $!\n";
	    print OUTPUT $output;
	    close OUTPUT;
	} or croak $@;
    }
}

unlink $empty_xml;

# a black list of "really wrong" services
sub filter {
    my ($authority, $service) = @_;
    my %FILTERED_OUT =
	(
	 'bioserv.rpbs.jussieu.fr/HBonds' => 1,
	 );
    return exists $FILTERED_OUT{"$authority/$service"};
}

__END__

