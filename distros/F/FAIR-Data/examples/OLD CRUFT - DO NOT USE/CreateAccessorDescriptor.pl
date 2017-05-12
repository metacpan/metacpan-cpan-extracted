#!/usr/bin/perl -w

use RDF::Trine;
use RDF::Trine::Statement;
use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Literal;
use RDF::NS;
use RDF::Trine::Serializer;

my $ns = RDF::NS->new('20131205');   # check at runtime
die "can't set namespace $!\n" unless ($ns->SET(fair => 'https://raw.githubusercontent.com/FAIRDataInitiative/DataFairPort/master/Schema/FAIR-schema.owl#'));

my $URL = "http://biordf.org/DataFairPort/DragonDB_Allele_Accessor.rdf";

my $model = createFreshTrineModel();

my $stm = statement($URL, $ns->rdf('type'), $ns->fair('dataAccessorDescriptor'));
$model->add_statement($stm);

$stm = statement($URL, $ns->fair('describesAccessorOf'), "http://antirrhinum.net");
$model->add_statement($stm);

$stm = statement("http://antirrhinum.net", $ns->rdfs('label'), "The Antirrhinum majus Genetic Database");
$model->add_statement($stm);

$stm = statement($URL, $ns->fair('accessorURL'), "http://antirrhinum.net/cgi-bin/LDP/Alleles");
$model->add_statement($stm);

$stm = statement($URL, $ns->fair('isLDPServer'), "true");
$model->add_statement($stm);

open(OUT, ">DragonDB_Allele_Accessor.rdf") || die "canm't open output file $!\n";
print OUT serializeThis($model);
close OUT;

exit 1;


sub statement {
	my ($s, $p, $o) = @_;
	unless (ref($s) =~ /Trine/){
		$s =~ s/[\<\>]//g;
		$s = RDF::Trine::Node::Resource->new($s);
	}
	unless (ref($p) =~ /Trine/){
		$p =~ s/[\<\>]//g;
		$p = RDF::Trine::Node::Resource->new($p);
	}
	unless (ref($o) =~ /Trine/){

		if ($o =~ /^http\:\/\//){
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /^<http\:\/\//){
			$o =~ s/[\<\>]//g;
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /"(.*?)"\^\^\<http\:/) {
			$o = RDF::Trine::Node::Literal->new($1);
		} else {
			$o = RDF::Trine::Node::Literal->new($o);				
		}
	}
	my $statement = RDF::Trine::Statement->new($s, $p, $o);
	return $statement;
}

sub serializeThis{
    my $model = shift;
    my $serializer = RDF::Trine::Serializer->new('turtle');
    return $serializer->serialize_model_to_string($model);
}

sub createFreshTrineModel {
    my $store = RDF::Trine::Store::Memory->new();
    my $model = RDF::Trine::Model->new($store);
    return $model;
}