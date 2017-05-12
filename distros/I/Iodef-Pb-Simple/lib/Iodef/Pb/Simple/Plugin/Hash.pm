package Iodef::Pb::Simple::Plugin::Hash;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    return unless($data->{'hash'});    
    my $hash = ExtensionType->new({
        meaning     => 'hash',
        content     => $data->{'hash'},
        dtype       => ExtensionType::DtypeType::dtype_type_string(),
    });
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'AdditionalData'}},$hash);  
}

1;