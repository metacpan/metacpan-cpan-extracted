package Iodef::Pb::Simple::Plugin::Ipv4;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use Regexp::Common qw/net/;
use Regexp::Common::net::CIDR;

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $addr = $data->{'address'};
    my $mask = $data->{'address_mask'} || 32; # 32 seems easier than 0 or undef
    $addr = $addr.'/'.$mask if($mask < 32);
    
    return unless($addr && ($addr =~ /^$RE{'net'}{'IPv4'}$/ || $addr =~ /^$RE{'net'}{'CIDR'}{'IPv4'}$/));
    
    my $category = ($addr =~ /^$RE{'net'}{'IPv4'}$/) ? AddressType::AddressCategory::Address_category_ipv4_addr() : AddressType::AddressCategory::Address_category_ipv4_net();
    
    $addr = normalize_address($addr);
    
    my @additional_data;
    if($data->{'prefix'} && $data->{'prefix'} =~ /^$RE{'net'}{'CIDR'}{'IPv4'}$/){
        push(@additional_data,ExtensionType->new({
            dtype   => ExtensionType::DtypeType::dtype_type_string(),
            meaning => 'prefix',
            content => $data->{'prefix'},
        }));
    }
    
    if($data->{'asn'}){
        $data->{'asn'} =~ s/^(AS|as)//;
        push(@additional_data,ExtensionType->new({
            dtype   => ExtensionType::DtypeType::dtype_type_string(),
            meaning => 'asn',
            content => $data->{'asn'},
        }));
    }
    
    if($data->{'asn_desc'}){
        push(@additional_data,ExtensionType->new({
            dtype   => ExtensionType::DtypeType::dtype_type_string(),
            meaning => 'asn_desc',
            content => $data->{'asn_desc'},
        }));
    }
    
    if($data->{'cc'}){
        push(@additional_data,
            ExtensionType->new({
                dtype   => ExtensionType::DtypeType::dtype_type_string(),
                meaning => 'cc',
                content => uc($data->{'cc'}),
            })
        );
    }
    
    if($data->{'rir'}){
        push(@additional_data,
            ExtensionType->new({
                dtype   => ExtensionType::DtypeType::dtype_type_string(),
                meaning => 'rir',
                content => uc($data->{'rir'}),
            })
        );
    }
    
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
    
    my $system = $data->{'system'};
    unless(ref($system) eq 'SystemType'){
        $system = SystemType->new({
            Node => NodeType->new({
                Address =>  AddressType->new({
                    category    => $category,
                    content     => $addr,
                }),
            }),
            category        => SystemType::SystemCategory::System_category_infrastructure(),
        });
    }

    if($#additional_data > -1){
        $system->set_AdditionalData(\@additional_data);
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

sub normalize_address {
    my $addr = shift;

    my @bits = split(/\./,$addr);
    foreach(@bits){
        if(/^0+\/(\d+)$/){
            $_ = '0/'.$1;
        } else {
            next if(/^0$/);
            next unless(/^0{1,2}/);
            $_ =~ s/^0{1,2}//;
        }
    }
    return join('.',@bits);
}

1;