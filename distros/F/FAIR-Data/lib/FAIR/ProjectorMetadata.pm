package FAIR::ProjectorMetadata;
$FAIR::ProjectorMetadata::VERSION = '1.001';




use strict;
use Moose;
use UUID::Generator::PurePerl;
use RDF::Trine::Store::Memory;
use RDF::Trine::Model;

with 'FAIR::CoreFunctions';

has 'model' => (
    isa => "RDF::Trine::Model",
    is => "rw",
    default => sub {my $store = RDF::Trine::Store::Memory->new(); return RDF::Trine::Model->new($store)}
);

has 'NS' => (
    is => 'rw',
);

sub createProjection {
      my ($self, $formats, $URL, $SOURCE, $subtemplate, $type, $predicate, $objecttemplate, $otype, $availableFormats) = @_;  # 
    my $NS = $self->NS;
    my $model = $self->model;
    
    push @{$formats->{"$availableFormats"}}, $URL;
    my $statement;
    
    #$statement = statement($URL, $NS->dcat('distribution'), $URL);
    #$model->add_statement($statement);
    #
    #$statement = statement($URL, $NS->rdf('type'), $NS->dcat('Distribution'));
    #$model->add_statement($statement);
    #
    #$statement = statement($URL, $NS->rdf('type'), $NS->dctypes('Dataset'));
    #$model->add_statement($statement);

    #$statement = statement($URL, $NS->dc('format'), $format);
    #$model->add_statement($statement);

    $statement = statement($URL, $NS->rdf('type'), $NS->fair('Projector'));
    $model->add_statement($statement);


    #if (($format =~ /turtle/) || ($format =~ /rdf/) || ($format =~ /quads/)) {
    #      $statement = statement($URL, $NS->rdf('type'), $NS->void('Dataset'));
    #      $model->add_statement($statement);
    #}
    
    $statement = statement($URL, $NS->dcat('downloadURL'), $URL);
    $model->add_statement($statement);
    
    $self->ProjectionMap($URL, $SOURCE, $subtemplate, $type, $predicate, $objecttemplate, $otype);
    
    #
    #$statement = statement($TPF, $NS->rdf('subjectClass'), 'phi:PHIBO_00022');
    #$model->add_statement($statement);
    #$statement = statement($TPF, $NS->rdf('predicate'), $predicate);
        #$model->add_statement($statement);

        # return nothing - the value of $model is now different
        return $formats;
        
  }

sub ProjectionMap{
    my ($self, $URL, $SOURCE, $subtemplate, $type, $predicate, $objecttemplate, $otype) = @_;
    my $uuid = UUID::Generator::PurePerl->new();
    $uuid = $uuid->generate_v1();
    my $NS = $self->NS();

    my $model = $self->model;
    
    my $SRC = "http://datafairport.org/local/Source$uuid";
    my $MAP = "http://datafairport.org/local/Mappings$uuid";
    my $SMAP = "http://datafairport.org/local/SubjectMap$uuid";
    my $POMAP = "http://datafairport.org/local/POMap$uuid";
    my $OMAP =  "http://datafairport.org/local/ObjectMap$uuid";
    my $SMAP2 = "http://datafairport.org/local/SubjectMap2$uuid";
    
    
    my $statement;
        # Mapping
        #  <CSV>  rml:isSourceOf  <SRC>
        #  <SRC>  rml:source    <CSV>
    $statement = statement($URL, $NS->rml('source'), $SOURCE);
    $model->add_statement($statement);
        
        #  <MAP>  rml:logicalSource <SRC>
    $statement = statement($MAP, $NS->rml('logicalSource'), $URL);
    $model->add_statement($statement);

    
        #  <SRC>  rml:hasMapping   <MAP>
    $statement = statement($URL, $NS->rml('hasMapping'), $MAP);
    $model->add_statement($statement);
        #  <SRC>  rml:referenceFormulation  ql:CSV
    $statement = statement($URL, $NS->rml('referenceFormulation'), $NS->ql('TriplePatternFragments'));
    $model->add_statement($statement);


        
        # <MAP> rr:subjectMap <SMAP>
    $statement = statement($MAP, $NS->rr('subjectMap'), $SMAP);
    $model->add_statement($statement);
        # <SMAP> rr:template "http://something/{ID}"


   my $templateurl = RDF::Trine::Node::Literal->new($subtemplate);
    $statement = statement($SMAP, $NS->rr('template'), $templateurl);
    $model->add_statement($statement);

    $statement = statement($SMAP, $NS->rr('class'), $type);
    $model->add_statement($statement);

    
    
        # <MAP>  rr:predicateObjectMap <POMAP>
    $statement = statement($MAP, $NS->rr('predicateObjectMap'), $POMAP);
    $model->add_statement($statement);
        #
        # <POMAP>  rr:predicate {$predicate}
    $statement = statement($POMAP, $NS->rr('predicate'), $predicate);
    $model->add_statement($statement);
        # <POMAP>  rr:objectMap <OMAP>
    $statement = statement($POMAP, $NS->rr('objectMap'), $OMAP);
    $model->add_statement($statement);
    
    
    
        #
        # <OMAP> rr:parentTriplesMap <OBJMAP>
    $statement = statement($OMAP, $NS->rr('parentTriplesMap'), $SMAP2);
    $model->add_statement($statement);
        # <OMAP> rr:subjecctMap <SMAP2>
        # <SMAP2>  rr:template "http://somethingelse/{out}
    if ($otype =~ /\#string/){
        $templateurl = RDF::Trine::Node::Literal->new("{value}");
    } else {
        $templateurl = RDF::Trine::Node::Literal->new($objecttemplate);
    }
    $statement = statement($SMAP2, $NS->rr('template'), $templateurl);
    $model->add_statement($statement);

    $statement = statement($SMAP2, $NS->rr('class'), $otype);
    $model->add_statement($statement);

        
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::ProjectorMetadata

=head1 VERSION

version 1.001

=head1 Name  FAIR::ProjectorMetadata

=head1 Description 

Projector Metadata includes things like the RML model, and stuff

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
