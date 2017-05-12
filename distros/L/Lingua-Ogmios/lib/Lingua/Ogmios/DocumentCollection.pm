package Lingua::Ogmios::DocumentCollection;

use strict;
use warnings;

use Lingua::Ogmios::DocumentRecord;
use XML::LibXML;

sub new {
    my ($class, $file, $type, $lingAnalysisLoad) = @_; 

    my $collection = {
	'documents' => {},
	'count' => 0,
	'attributes' => [],
    };

    bless $collection, $class;

    # Parsing the file and loading documents
    if (($type eq "file") && (defined $file)) {
	$collection->_parseDocumentCollectionFromFile($file, $lingAnalysisLoad);
    }

    if (($type eq "data") && (defined $file)) {
	$collection->_parseDocumentCollectionFromData($file, $lingAnalysisLoad);
    }
    
    return($collection);
}



sub setAttributes {
    my ($self, $attributes) = @_;
    my $attr;

    foreach $attr (@$attributes) {
	push @{$self->{'attributes'}}, {'nodeName' => $attr->nodeName,
					'value' => $attr->value,
					};
    }
}

sub getAttributes {
    my ($self) = @_;

    return($self->{'attributes'});
}

sub _parseDocumentCollectionFromFile {
    my ($self, $file, $lingAnalysisLoad) = @_;
    
    # Parsing the file and loading documents
    
    my $Parser=XML::LibXML->new();
    my $document;
    my $document_record;
    my $parsedDocument;
    my $id;
    
    eval {
	$document=$Parser->parse_file($file);
    };
    if ($@){
	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
    } else {
	if ($document) {
	    $self->_parseDocumentCollection($document, $lingAnalysisLoad);
	} else {
	    warn "Parsing the doc failed. Doc: " . ($self->getCount + 1) . "(in $file)\n";
	}
    }
}

sub _parseDocumentCollectionFromData {
    my ($self, $file, $lingAnalysisLoad) = @_;
    
    # Parsing the file and loading documents
    
    my $Parser=XML::LibXML->new();
    my $document;
    my $document_record;
    my $parsedDocument;
    my $id;
    
    eval {
	$document=$Parser->parse_string($file);
    };
    if ($@){
	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
    } else {
	if ($document) {
	    $self->_parseDocumentCollection($document, $lingAnalysisLoad);
	} else {
	    warn "Parsing the doc failed. Doc: " . ($self->getCount + 1) . "(in $file)\n";
	}
    }
}

sub _parseDocumentCollection {
    my ($self, $document, $platformConfig) = @_;
    
    # Parsing the file and loading documents

#     my $Parser=XML::LibXML->new();
#     my $document;
    my $document_record;
    my $parsedDocument;
#     my $id;

#     eval {
# 	$document=$Parser->parse_file($file);
#     };
#     if ($@){
# 	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
#     }
#     else {
# 	if ($document) {
    my $root=$document->documentElement();
    
    my @attr = $root->attributes;
    $self->setAttributes(\@attr);
    
    foreach $document_record ($root->getChildrenByTagName('documentRecord')) {
	$parsedDocument = Lingua::Ogmios::DocumentRecord->new($document_record, $platformConfig);
	$self->addDocument($parsedDocument);
    }
#     }
}

sub addDocument {
    my ($self, $parsedDocument) = @_;

    $self->{'documents'}->{$parsedDocument->getId}->{"document"} = $parsedDocument;
    $self->{'documents'}->{$parsedDocument->getId}->{"order"} = $self->{'count'};
    $self->{'count'}++;
}

sub setCount {
    my ($self, $value)= @_;

    $self->{'count'} = $value;
}


sub resetCount {
    my ($self)= @_;

    $self->setCount(0);

}

sub getCount {
    my ($self)= @_;

    return($self->{'count'});
}


sub incrCount {
    my ($self)= @_;

    $self->setCount($self->getCount + 1);
}

sub decrCount {
    my ($self)= @_;

    $self->setCount($self->getCount - 1);
}

sub getDocuments {
    my ($self) = @_;

    my %documents;
    my $documentId;

    foreach $documentId (keys %{$self->{'documents'}}) {
	$documents{$documentId} = $self->{'documents'}->{$documentId}->{"document"};
    }

    return(\%documents);
}

sub getSortedDocuments {
    my ($self) = @_;

    my @documents;
    my $documentId;

    foreach $documentId (sort { $self->{'documents'}->{$a}->{"order"} <=> $self->{'documents'}->{$b}->{"order"}} keys %{$self->{'documents'}}) {
	push @documents, $self->{'documents'}->{$documentId}->{"document"};
    }

    return(\@documents);
}

sub getDocument {
    my ($self, $id) = @_;

    return($self->getDocuments->{$id});
}

sub existsDocument {
    my ($self, $id) = @_;

    return(exists($self->getDocuments->{$id}));
}

sub tokenisation {
    my ($self) = @_;

    my $document;
    my $record_log = 1;

    foreach $document (values %{$self->getDocuments}) {
	$record_log = $document->tokenisation;
# 	if ($document->getAnnotations->getTokenLevel->getSize == 0) {
# 	    $record_log = 0;
# 	}
	$document->computeSectionFromToken($record_log);
# 	$record_log = 1;
    }
    return(0);
}

sub XMLout {
    my ($self) = @_;

    my $document;

    my $str;
    my $attr;

    $str = '<documentCollection';
    foreach $attr (@{$self->getAttributes}) {
	$str .= " " . $attr->{'nodeName'} . '="' . $attr->{'value'} . '"';
    }
    $str .= ">\n";


#     foreach $document (values %{$self->getDocuments}) {
    foreach $document (@{$self->getSortedDocuments}) {
	$str .= $document->XMLout;
    }
    $str .= "</documentCollection>";

    return($str);
}

sub getDocumentList {
    my ($self) = @_;

    return(keys %{$self->getDocuments});
}

sub printDocumentList {
    my ($self) = @_;
    my $doc_id;

    warn "\n\nDocument Id List \n";
    foreach $doc_id ($self->getDocumentList) {
	warn "\t$doc_id\n";
    }
    warn "\n";
}


1;

__END__

=head1 NAME

Lingua::Ogmios::DocumentCollection - Perl extension for document collection

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $docCollection = Lingua::Ogmios::???::new();


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

