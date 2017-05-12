package FAIR::Accessor::Container;
$FAIR::Accessor::Container::VERSION = '1.001';




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

has 'MetaData' => (
    isa => "HashRef",
    is => "rw",
    default => sub {my $h = {}; return $h}
);

has 'NS' => (
    is => 'rw',
);

has 'FreeFormRDF' => (
    is => 'rw',
    isa => "RDF::Trine::Model"
);

has Records => (
    isa => "ArrayRef",
    is => "rw"
);


sub addRecords {
    my ($self, $records) = @_;
    
    $self->addMetadata({'void:entities' => scalar(@$records)});;  #  THE TOTAL *NUMBER* OF RECORDS THAT CAN BE SERVED
    $self->Records($records);

}


sub addMetadata {
    my ($self, $metadata) = @_;
    my %datahash = %$metadata;
    my %existing = %{$self->MetaData};
    foreach my $key(keys %datahash){
        $existing{$key} = $datahash{$key};
    }
    $self->MetaData(\%existing);
    
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::Accessor::Container

=head1 VERSION

version 1.001

=head1 Name  FAIR::Accessor::Container

=head1 Description 

This generates the behaviors for the LDP Container-like functions of the FAIR Accessor

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
