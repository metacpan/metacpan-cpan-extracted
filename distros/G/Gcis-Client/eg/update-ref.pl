#!/usr/bin/env perl
use v5.14;
use Data::Dumper;
use Gcis::Client;

my $c = Gcis::Client->connect(url => 'http://localhost:3000');

my $reference_identifier = "000b594a-e2da-44c6-8f4e-7c4be7548a68";
my $generic_identifier = "1597a33c-7d29-4daa-8611-3c833aeec755";

my $ref = $c->get("/reference/form/update/$reference_identifier");
$ref->{child_publication_uri} = "/generic/$generic_identifier";
$ref->{publication_uri} = $c->get($ref->{publication_uri})->{uri};
delete $ref->{sub_publication_uris};

$c->post("/reference/$reference_identifier", $ref) or die $c->error;


