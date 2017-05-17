#!/usr/bin/env perl

use JSON::XS;
use Template;
use Data::Dumper;
use feature qw(say);

open(FI,"data/models.json");
my $data = JSON::XS::decode_json(join("",<FI>));
my $tt = Template->new();
foreach my $model (keys %$data) {
	say $model;
	my $stash = {model=>$data->{$model}->[0]};
	process_template("templates/model_pod_template.tt","lib/Imgur/API/Model/$data->{$model}->[0]->{pname}.pod",$stash);
}

sub process_template {
	my ($template,$output,$stash) = @_;

	my $out = '';
	$tt->process($template,$stash,\$out);

    open(FO,">",$output);
    print FO $out;
    close(FO);
}

	
	
