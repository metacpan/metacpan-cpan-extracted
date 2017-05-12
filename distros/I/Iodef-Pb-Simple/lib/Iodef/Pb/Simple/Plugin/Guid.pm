package Iodef::Pb::Simple::Plugin::Guid;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use Iodef::Pb::Simple qw/is_uuid uuid_ns/;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    return unless($data->{'guid'});
    
    $data->{'guid'} = uuid_ns($data->{'guid'}) unless(is_uuid($data->{'guid'}));
    
    my $ad = ExtensionType->new({
        dtype       => ExtensionType::DtypeType::dtype_type_string(),
        content     => $data->{'guid'},
        formatid    => 'uuid',
        meaning     => 'guid hash'
    });
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'AdditionalData'}},$ad);  
}

1;