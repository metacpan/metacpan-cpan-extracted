package FAIR::Accessor::MetaRecord;
$FAIR::Accessor::MetaRecord::VERSION = '1.001';



use strict;
use Moose;
use UUID::Generator::PurePerl;
use RDF::Trine::Store::Memory;
use RDF::Trine::Model;
use FAIR::Accessor::Distribution;

with 'FAIR::CoreFunctions';


has 'MetaData' => (
    isa => "HashRef",
    is => "rw",
    default => sub {my $h = {}; return $h}
);


has 'FreeFormRDF' => (
    is => 'rw',
    isa => "RDF::Trine::Model"
);

has 'NS' => (
    is => 'rw',
    required => 'true',
);

has 'ID' => (
      is => 'rw',
      isa => 'Str',
      required => 'true',
);

has 'Distributions' => (
      is => 'rw',
      isa => 'ArrayRef[FAIR::Accessor::Distribution]',
);



sub addMetadata {
    my ($self, $metadata) = @_;
    my %datahash = %$metadata;
    my %existing = %{$self->MetaData};
    foreach my $key(keys %datahash){
        $existing{$key} = $datahash{$key};
    }
    $self->MetaData(\%existing);
    
}

sub addDistribution {
      my ($self, %ARGS) = @_;  #
      my $currentDistributions = $self->Distributions;
      my @currentDistributions;
      if ($currentDistributions) {
         @currentDistributions = @$currentDistributions;   
      }
      
      my $Distribution = FAIR::Accessor::Distribution->new();
      $Distribution->NS($self->NS);
      $Distribution->downloadURL($ARGS{downloadURL});
      $Distribution->availableformats($ARGS{availableformats});

      if ($ARGS{source}) {  # this is very dangerous... we assume that the user sends all parameters... if not, we don't check and Moose constraints will be violated
            # these are only for TPF
            $Distribution->source($ARGS{source});
            $Distribution->subjecttemplate($ARGS{subjecttemplate});
            $Distribution->subjecttype($ARGS{subjecttype});
            $Distribution->predicate($ARGS{predicate});
            $Distribution->objecttemplate($ARGS{objecttemplate});
            $Distribution->objecttype($ARGS{objecttype});
      }
      
      push @currentDistributions, $Distribution;
      $self->Distributions(\@currentDistributions);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::Accessor::MetaRecord

=head1 VERSION

version 1.001

=head1 Name  FAIR::Accessor::MetaRecord

=head1 Description 

This generates the behaviors for the LDP MetaRecord functions of the FAIR Accessor

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
