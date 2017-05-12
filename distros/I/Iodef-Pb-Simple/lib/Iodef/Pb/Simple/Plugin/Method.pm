package Iodef::Pb::Simple::Plugin::Method;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $method = $data->{'method'} || $data->{'Method'};
    return unless($method);
    
    unless(ref($method) eq 'ARRAY' || ref($method) eq 'MethodType'){
        $method =~ /([a-zA-Z0-9-]+\.[a-zA-Z0-9]{2,6})\//;
        my $name = $1 || 'unknown';
        $method = MethodType->new({
            restriction => RestrictionType::restriction_type_need_to_know(),
            Reference   => ReferenceType->new({
                ReferenceName   => MLStringType->new({
                    lang    => 'EN',
                    content => $name,
                }),
                URL         => UrlType->new({
                    content => $method,
                }),
                Description     => MLStringType->new({
                    lang    => 'EN',
                    content => 'unknown',
                }),
            }),
        });
    }
    my $incident = @{$iodef->get_Incident()}[0];  
    $incident->set_Method($method);
}

1;
