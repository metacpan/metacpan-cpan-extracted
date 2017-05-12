package Iodef::Pb::Simple::Plugin::Domain;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use Regexp::Common qw/URI/;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $addr = $data->{'address'};
    return unless($addr);
    
    # Regexp::Common qw/URI/ chokes on large urls
    return if($addr =~ /^(ftp|https?):\/\//);
    return unless($addr =~ /^[a-zA-Z0-9.\-_]+\.[a-z]{2,6}$/);
    
    my $category = AddressType::AddressCategory::Address_category_ext_value();
    
    my @additional_data ;
    
    # in the event that we wanna track this and pass it along
    my $service;
    if($data->{'service'} && ref($data->{'service'}) eq 'ServiceType'){
        $service = $data->{'service'};
    } elsif($data->{'protocol'} || $data->{'portlist'}) {
        if($data->{'service'}){
            my $app = SoftwareType->new({
                name    => $data->{'service'},
            });
            $service = ServiceType->new({
                Application => $app,
            });
        } else {
            $service = ServiceType->new();
        }
        my $proto = $data->{'protocol'} || $data->{'ip_protocol'};
        if($data->{'portlist'}){
            # normalize peoples wierd port habbits
            $data->{'portlist'} =~ m/(\d+(-\d+)?)$/;
            $data->{'portlist'} = $1;
            $service->set_Portlist($data->{'portlist'});
            # IODEF requires a default
            $proto = 'tcp' unless($proto);
        }
        if($proto){
            $proto = $self->normalize_protocol($proto);
            $service->set_ip_protocol($proto);
        }
    }
    
    my $system = SystemType->new({
        Node    => NodeType->new({
            Address => AddressType->new({
                category        => $category,
                ext_category    => 'fqdn',
                content         => $addr,
            }),
        }),
        category        => SystemType::SystemCategory::System_category_infrastructure(),
    });
    
    if($data->{'rdata'}){
        $system->set_AdditionalData(
            ExtensionType->new({
                dtype       => ExtensionType::DtypeType::dtype_type_string(),
                meaning     => 'rdata',
                formatid    => $data->{'rdata_type'} || 'A',
                content     => $data->{'rdata'},
            })
        );
    }
    
    if($service){
        $system->set_Service($service);
    }
    
    my $event = EventDataType->new({
        Flow    => FlowType->new({
            System  => $system,
        }),
    });
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'EventData'}},$event);
}

1;