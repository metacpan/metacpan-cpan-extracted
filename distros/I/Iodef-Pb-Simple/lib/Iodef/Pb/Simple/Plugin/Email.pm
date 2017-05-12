package Iodef::Pb::Simple::Plugin::Email;
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
    return unless($addr =~ /^[a-z0-9_.-]+\@[a-z0-9.-]+\.[a-z0-9.-]{2,5}$/);
    
    my $category = AddressType::AddressCategory::Address_category_ext_value();
    
    my $event = EventDataType->new({
        Flow    => FlowType->new({
            System  => SystemType->new({
                Node    => NodeType->new({
                    Address => AddressType->new({
                        category        => $category,
                        ext_category    => 'email',
                        content         => $addr,
                    }),
                }),
                category        => SystemType::SystemCategory::System_category_source(),
            }),
        }),
    });
    
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'EventData'}},$event);
}

1;