package FAIR::AccessorConfig;
$FAIR::AccessorConfig::VERSION = '1.001';


# ABSTRACT: The key/value of the current configuration of the Accessor


use strict;
use warnings;
use Moose;
use RDF::NS '20131205';              # check at compile time

# define common metadata elements here, and their namespaces


has 'title' => (
    isa => 'Str',
    is  => 'rw',
);

has 'serviceTextualDescription' => (
    isa => 'Str',
    is => 'rw'
);

has 'textualAccessibilityInfo' => (
    isa => 'Str',
    is => 'rw',
);

has 'mechanizedAccessibilityInfo' => (
    isa => 'Str',
    is => 'rw',
);

has 'textualLicenseInfo' => (
    isa => 'Str',
    is => 'rw',
);

has 'mechanizedLicenseInfo' => (
    isa => 'Str',
    is => 'rw',
);

has 'basePATH' => (
    isa => 'Str',  # string representing a regular expression to be applied against $ENV{PATH_INFO}
    is => 'rw',
);

has 'localNamespaces' => (
    isa => 'HashRef',
    is => 'rw',
);


has 'Namespaces' => (
    isa => "RDF::NS",
    is => "rw",
    default => sub {return RDF::NS->new('20131205')}
);

has 'ETAG_Base' => (
    isa => "Str",
    is => "rw",
);

	

sub BUILD {
    my ($self) = @_;
    my $NS = $self->Namespaces; 
    die "can't set namespace $!\n" unless ($NS->SET(ldp => 'http://www.w3.org/ns/ldp#'));
    die "can't set namespace $!\n" unless ($NS->SET(daml => "http://www.ksl.stanford.edu/projects/DAML/ksl-daml-desc.daml#"));
    die "can't set namespace $!\n" unless ($NS->SET(edam => "http://edamontology.org/"));
    die "can't set namespace $!\n" unless ($NS->SET(sio => "http://semanticscience.org/resource/"));
    die "can't set namespace $!\n" unless ($NS->SET(example => 'http://example.org/ns#'));
    die "can't set namespace $!\n" unless ($NS->SET(prov => 'http://www.w3.org/ns/prov#'));
    die "can't set namespace $!\n" unless ($NS->SET(dctypes => 'http://purl.org/dc/dcmitype/'));
    die "can't set namespace $!\n" unless ($NS->SET(pav => 	'http://purl.org/pav/'));
    die "can't set namespace $!\n" unless ($NS->SET(schemaorg => 'http://schema.org/'));
    die "can't set namespace $!\n" unless ($NS->SET(void => 'http://rdfs.org/ns/void#'));
    die "can't set namespace $!\n" unless ($NS->SET(fair => 'http://datafairport.org/ontology/FAIR-schema.owl#'));
    die "can't set namespace $!\n" unless ($NS->SET(rr => 'http://www.w3.org/ns/r2rml#'));
    die "can't set namespace $!\n" unless ($NS->SET(rml => 'http://semweb.mmlab.be/ns/rml#'));
    die "can't set namespace $!\n" unless ($NS->SET(ql => 'http://semweb.mmlab.be/ns/ql#'));

    foreach my $abbreviation(keys %{$self->localNamespaces()}){
	my $namespace = $self->localNamespaces()->{$abbreviation};
        unless ($NS->SET($abbreviation => $namespace)){
	    print STDERR  "Failed to set namespace $abbreviation  ==  $namespace   Make sure your abbreviation has no capital letters (Perl library quirk!)";
	}
    }

    
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::AccessorConfig - The key/value of the current configuration of the Accessor

=head1 VERSION

version 1.001

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
