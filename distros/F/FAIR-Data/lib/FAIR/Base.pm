package FAIR::Base;
$FAIR::Base::VERSION = '1.001';


# ABSTRACT: libraries for creating and parsing FAIR Data Profiles (see http://datafairport.org for more details)

use RDF::NS '20131205';
use strict;
use RDF::Trine::Store::Memory;
use RDF::Trine::Model;
use RDF::Trine::Namespace;
use RDF::Trine::Statement;
use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Literal;


use Exporter qw(import);
our @ISA =   qw(Exporter);
our @EXPORT = qw(statement);

use FAIR::NAMESPACES; 

our %predicate_namespaces = qw{
    type RDF
    title DC
    description DC
    issued DC
    modified DC
    identifier DC
    keyword DC
    language DC
    contactPoint DC
    temporal DC
    spatial DC
    accrualPeriodicity DC
    landingPage DCAT
    license DC
    rights DC
    accessURL DCAT
    downloadURL DCAT
    mediaType DCAT
    format DC
    byteSize DCAT
    homepage FOAF
    publisher DC
    theme DCAT
    inScheme SKOS
    themeTaxonomy DCAT
    dataset DCAT
    record DCAT
    distribution DCAT
    primaryTopic FOAF
    provenance DC
    ProvenanceStatement DC
    
    label RDFS
    organization DC
    hasClass FAIR
    hasProperty FAIR
    onClassType FAIR
    onPropertyType FAIR
    allowedValues FAIR
    maxCount FAIR
    minCount FAIR
    FAIRClass FAIR
    FAIRProperty FAIR
    FAIRProfile FAIR
    
    schemardfs_URL FAIR
    
};


sub _toTriples {
	my ($self, $model) = @_;
        unless ($model){  # this is a recursive sub, so sometimes the preexisting model is passed in to be filled
            my $store = RDF::Trine::Store::Memory->new();
            $model = RDF::Trine::Model->new($store);
        }
        my %namespaces;
	my $dct = RDF::Trine::Namespace->new( DC);  # from shared exported constants in NAMESPACES.pm
        $namespaces{DC} = $dct;
        
	my $dcat = RDF::Trine::Namespace->new( DCAT);
        $namespaces{DCAT} = $dcat;
        
	my $skos = RDF::Trine::Namespace->new( SKOS);
        $namespaces{SKOS} = $skos;

	my $foaf = RDF::Trine::Namespace->new( FOAF);
        $namespaces{FOAF} = $foaf;

	my $rdfs = RDF::Trine::Namespace->new( RDFS);
        $namespaces{RDFS} = $rdfs;

	my $rdf = RDF::Trine::Namespace->new( RDF);
        $namespaces{RDF} = $rdf;

	my $fair = RDF::Trine::Namespace->new( FAIR);
        $namespaces{FAIR} = $fair;


	# now go through all of the properties of that subject to begin constructing the triples
	my %attributes;
	map {$attributes{$_} = 1} $self->meta->get_attribute_list;
	my $sub = $self->URI;  # the subject of the triples 
	delete $attributes{'URI'};  # this attribute we have taken care of
	
	my $types = $self->type;	
	foreach my $type(@$types){
	    my $stm = statement($sub, RDF."type", $type);
	    $model->add_statement($stm);                    
	}
	delete $attributes{'type'}; # now we've taken care of that one!

		
	# now process the rest - serialize the property if it is marked as "serializable";
        foreach my $attributename(keys %attributes){
		my $attribute = $self->meta->get_attribute($attributename);
		next unless $attribute->does('Serializable');  # if this isn't a serializable property, skip it
		my $predicate = $attribute->name;  # the FAIR Moose object predicate names are identical to the OWL/Schema predicate names, 
		my $reader = $attribute->get_read_method;  # in case there is a specific reader subroutine associated with the property
		my $values = $self->$reader;  # call the subroutine.  All return a list-ref; sometimes its a list of DCAT objects, sometimes a listref of strings
		
		unless (ref($values) ~~ /ARRAY/){  # some properties return listrefs, others return just a string or an object
			$values = [$values]  # so force it to be a listref before we iterate over the return value
		}
		foreach my $object(@$values){
		    #print STDERR $object, "\n";
		    next unless ($object);  # might be undef
		    if ((ref($object) ~~ /FAIR/) && $object->can('_toTriples')) {  # is it a FAIR object?  if so, unpack it  
			my $toConnect = $object->URI;  # get that objects URI
			my $namespace = $namespaces{$predicate_namespaces{$predicate}};   # look up the namespace of that predicate
			die "no namespace found for $predicate\n" unless $namespace;
			my $stm = statement($sub, $namespace.$predicate, $toConnect);  # and create the triple joining that object to the current model
			$model->add_statement($stm);
			next if ($object->isa('FAIR::Profile')); # if the sub-object refers back to the main profile object, then skip at this point to prevent infinite loops
			$object->_toTriples($model);  # recursive call... unpack that FAIR object to its triples
		    } else {  # if it isn't a FAIR object, then it's just a listref of strings
			my $namespace = $namespaces{$predicate_namespaces{$predicate}};
			my $stm = statement($sub, $namespace.$predicate, $object);
			$model->add_statement($stm);                    
		    }
		}
            #    next;
            #} else {
            #    # print STDERR $key, "\n";
            #    my $namespace = $namespaces{$predicate_namespaces{$key}};
            #    my $value = $self->$key;
            #    next unless defined $value;
            #    my $stm = statement($sub, $namespace.$key, $value);
            #    $model->add_statement($stm);
            #}
        }
	return $model;
}

sub toTriples {
    my ($self) = @_;
    my $model = $self->_toTriples;
    my $iter = $model->get_statements();
    my @statements;
    while (my $st = $iter->next) {
            push @statements, $st;    
    }
    return @statements;
}


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
		if (($o =~ m'^http://') || ($o =~ m'^https://')){
			$o =~ s/[\<\>]//g;
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /\D/) {
			$o = RDF::Trine::Node::Literal->new($o);
		} else {
			$o = RDF::Trine::Node::Literal->new($o);				
		}
	}
	my $statement = RDF::Trine::Statement->new($s, $p, $o);
	return $statement;
}












1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::Base - libraries for creating and parsing FAIR Data Profiles (see http://datafairport.org for more details)

=head1 VERSION

version 1.001

=head1 FAIR Base - the root of the FAIR modules

The FAIR modules come from the Data FAIRport project (http://datafairport.org).  

There are three main sections to this code:  FAIR::Profiles, FAIR Accessors, and FAIR Projectors.  (Projectors haven't been invented yet)

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
