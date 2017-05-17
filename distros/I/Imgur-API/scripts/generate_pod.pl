#!/usr/bin/env perl

use JSON::XS;
use Template;
use Data::Dumper;
use feature qw(say);

open(FI,"data/endpoints.json");
my $data = JSON::XS::decode_json(join("",<FI>));
my $tt = Template->new();
foreach my $endpoint (keys %$data) {
	say $endpoint;
	my $stash = {name=>$endpoint,methods=>$data->{$endpoint}};

	process_template("templates/pod_template.tt","lib/Imgur/API/Endpoint/$endpoint.pod",$stash);
}

sub process_template {
	my ($template,$output,$stash) = @_;

	my $out = '';
	$tt->process($template,$stash,\$out);


    open(FO,">",$output) || die;
    print FO $out;
    close(FO);
}

	
	
