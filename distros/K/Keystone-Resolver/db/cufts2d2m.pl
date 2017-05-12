#!/usr/bin/perl -w

# $Id: cufts2d2m.pl,v 1.3 2007-12-01 21:56:17 mike Exp $

# Converts a CUFTS database dump such as the one in
#	../samples/data/cufts/CUFTS-indexdata/
# into the d2m format read by data2mysql.pl
#
# It must generate the following sections:
#	*provider=name,priority,contact
#	*service=service_type_id,provider_id,tag,name,priority,url_recipe,need_auth,auth_recipe,disabled
#	*serial=name,issn
#	*serial_alias=serial_id,alias
#	*service_serial=service_id,serial_id

use strict;
use warnings;
use Getopt::Std;
use IO::File;
use XML::LibXML;
use HTML::Entities;

my %opts;
if (!getopts('x', \%opts) || @ARGV != 1) {
    print STDERR "Usage: $0 [options] <unpacked-CUFTS-directory>
	-x	Render update.xml master-file as XML
";
    exit 1;
}

my($dir) = @ARGV;
my $parser = new XML::LibXML();
my $doc = $parser->parse_file("$dir/update.xml")
    or die "$0: can't parse XML master file '$dir/update.xml': $!";

my @resources;			# Numerically ordered list
#my %resourcesByName;
my %providers;			# Maps provider name to list of resources
my $provider_id = 2;		### Secret knowledge: 1 is KR itself

xprint(0, "xml", [ "open" ]);
foreach my $node ($doc->findnodes("xml/resource")) {
    xprint(1, "resource", [ "open" ]);
    # Each CUFTS "resource" corresponds to a Keystone Resolver "service"
    my $provider = $node->findvalue("provider");
    xprint(2, "provider", $provider);
    my $database_url = $node->findvalue("database_url");
    xprint(2, "database_url", $database_url) if $database_url ne "";
    my $key = $node->findvalue("key");
    xprint(2, "key", $key);
    my $url_base = $node->findvalue("url_base");
    xprint(2, "url_base", $url_base) if $url_base ne "";
    my $module = $node->findvalue("module");
    xprint(2, "module", $module);
    my $name = $node->findvalue("name");
    xprint(2, "name", $name);
    my $notes_for_local = $node->findvalue("notes_for_local");
    xprint(2, "notes_for_local", $notes_for_local) if $notes_for_local ne "";
    my $resource_type = $node->findvalue("resource_type");
    xprint(2, "resource_type", $resource_type);
    xprint(2, "services", [ "open" ]);
    my @services;
    foreach my $node ($node->findnodes("services/service")) {
	# CUFTS "service" is like KR "service_type"
	my $service = $node->findvalue(".");
	xprint(3, "service", $service);
	push @services, $service;
    }
    xprint(2, "services", [ "close" ]);
    xprint(1, "resource", [ "close" ]);

    $providers{$provider} = new Provider($provider_id++, $provider)
	if !exists $providers{$provider};
    my $resource = new Resource($providers{$provider}, $database_url,
				$key, $url_base, $module, $name,
				$notes_for_local, $resource_type,
				\@services);
    $providers{$provider}->add_resource($resource);
    push @resources, $resource;
    #%resourcesByName{$name} = $resource;
}
xprint(0, "xml", [ "close" ]);


print "*provider=id,name,priority,contact\n";
foreach my $provider (sort { $a->id() <=> $b->id() } values %providers) {
    print_csv($provider->id(),
	      $provider->name(),
	      0,		# Give everything priority zero
	      "");		# No contact information available
}

my %serialByISSN;		# Maps normalised ISSN to ID
my $service_id = 1;		### Secret knowledge: no services in base.d2m
my $serial_id = 1;		### Secret knowledge: no serials in base.d2mp

foreach my $resource (@resources) {
    print "\n";
    print "*service=id,service_type_id,provider_id,tag,name,priority,url_recipe,need_auth,auth_recipe,disabled\n";
    print_csv($service_id,
	      $resource->service_type_id(),
	      $resource->provider()->id(),
	      $resource->module(),
	      $resource->name(),
	      0,		# Give everything priority zero
	      $resource->url_base(), # Close but not exactly right
	      0,		# We know nothing about authentication
	      "",		# ... so no authentication recipe
	      0);		# Services are not disabled AFAIK
    # Note that we do not currently use the fields "database_url",
    # "notes_for_local" or "services"

    my @kfields = qw(name issn);
    my $key = $resource->key();
    my $f = new IO::File("<$dir/$key")
	or die "can't open serials list '$dir/$key': $!";
    my $line = $f->getline();
    chomp $line;
    my @fields = split(/\t/, $line);
    while ($line = $f->getline()) {
	chomp $line;
	my @data = split(/\t/, $line);
	my %stuff = ( map { $fields[$_], $data[$_] } 0..$#fields );
	my $issn = $stuff{issn};
	if ($issn && $serialByISSN{$issn}) {
	    # Treat this new journal as a new reference to an existing
	    # one, as the KR code expects ISSNs to be unique.
	    print "*service_serial=service_id,serial_id\t# reuse\n";
	    print_csv($service_id, $serialByISSN{$issn});
	} else {
	    $serialByISSN{$issn} = $serial_id if $issn;
	    print "*serial=id,", join(",", @kfields), "\n";
	    my @output = ($serial_id);
	    foreach my $kfield (@kfields) {
		push @output, $stuff{map_serial_field($kfield)} || "";
	    }
	    print_csv(@output);
	    if ($stuff{abbreviation}) {
		print "*serial_alias=serial_id,alias\n";
		print_csv($serial_id, $stuff{abbreviation});
	    }
	    print "*service_serial=service_id,serial_id\n";
	    print_csv($service_id, $serial_id);
	    $serial_id++;
	}
    }
    $f->close();
    $service_id++;
}


sub xprint {
    my($level, $tag, $data) = @_;
    return if !$opts{x};

    print " " x ($level*2), "<";
    if (ref $data) {
	print "/" if $data->[0] eq "close";
	print "$tag>\n";
    } else {
	print "$tag>", encode_entities($data), "</$tag>\n";
    }
}


sub print_csv {
    my(@data) = @_;

    foreach my $i (0 .. $#data) {
	my $s = $data[$i];
	$s =~ s/,//g;		# Should do better!
	print $s, $i == $#data ? "\n" : ",";
    }
}

sub map_serial_field {
    # These are all the fields used in serial-list files of the CUFTS
    # database, from the ubiquitious ("issn" and "title" each occur in
    # in all 337 serial-sets, and "ft_start_date" in all but one,
    # "bioline_int") down to "current_months" (which occurs only once,
    # in "elsevier_sciencedirect"), and "abbreviation" (which occurs
    # twice, in "biomed_central" and "nlm_pubmed_central").
    #
    #    377 issn
    #    377 title
    #    376 ft_start_date
    #    356 ft_end_date
    #    301 cit_end_date
    #    301 cit_start_date
    #    251 embargo_days
    #    170 db_identifier
    #    165 embargo_months
    #    161 journal_url
    #    130 e_issn
    #     90 vol_ft_start
    #     87 vol_ft_end
    #     83 cjdb_note
    #     72 iss_ft_start
    #     71 iss_ft_end
    #     68 publisher
    #     11 iss_cit_end
    #     11 iss_cit_start
    #     11 vol_cit_end
    #     11 vol_cit_start
    #      2 abbreviation
    #      1 current_months

    my($sfield) = @_;
    my %map = (
	name => "title",
	issn => "issn",
	# ### That's all!  In fact we ignore pretty much all the
	# serial data from the CUFTS knowledge base, which shows how
	# weak our data-model is at the level of individual serials.
	# Keystone Resolver needs to add at least the notion of start-
	# and end-dates.
    );

    return $map{$sfield};
}


package Resource;

sub new {
    my $class = shift();
    my($provider, $database_url, $key, $url_base, $module, $name,
       $notes_for_local, $resource_type, $services) = @_;

    return bless {
	provider => $provider,
	database_url => $database_url,
	key => $key,
	url_base => $url_base,
	module => $module,
	name => $name,
	notes_for_local => $notes_for_local,
	resource_type => $resource_type,
	services => $services,
    }, $class;
}

sub provider { shift()->{provider} }
sub key { shift()->{key} }
sub url_base { shift()->{url_base} }
sub module { shift()->{module} }
sub name { shift()->{name} }

### This function uses secret knowledge from base.d2m
sub service_type_id {
    my $this = shift();
    my $rt = $this->{resource_type};

    if ($rt eq "fulltext journals") {
	return 1;
    } else {
	die "unknown resource_type '$rt'";
    }
}

package Provider;

sub new {
    my $class = shift();
    my($id, $name) = @_;

    return bless {
	id => $id,
	name => $name,
	resources => [],
    }, $class;
}

sub id { shift()->{id} }
sub name { shift()->{name} }
sub resources { @{ shift()->{resources} } }

sub add_resource {
    my $this = shift();
    my($resource) = @_;

    push @{ $this->{resources} }, $resource;
}
