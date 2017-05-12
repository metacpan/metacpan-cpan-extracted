package Iodef::Pb::Simple::Plugin::AdditionalData;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    return unless(($data->{'AdditionalData'} && ref($data->{'AdditionalData'}) eq 'ExtensionType') || $data->{'additional_data1'});
    my $incident = @{$iodef->get_Incident()}[0];
    
    if($data->{'additional_data1'}){
        foreach my $k (keys %$data){
            next unless($k =~ /^additional_data(\d+)$/);
            my $meaning = $data->{"additional_data$1_meaning"};
            my $x = ExtensionType->new({
                dtype       => ExtensionType::DtypeType::dtype_type_string(),
                content     => $data->{$k},
                formatid    => 'string',
                meaning     => $meaning,
            });
            push(@{$incident->{'AdditionalData'}},$x);
        }   
    } else {
        push(@{$incident->{'AdditionalData'}},$data->{'AdditionalData'});
    }
}

1;