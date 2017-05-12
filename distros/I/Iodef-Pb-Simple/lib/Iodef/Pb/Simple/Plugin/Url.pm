package Iodef::Pb::Simple::Plugin::Url;
use base 'Iodef::Pb::Simple::Plugin';

use strict;
use warnings;

use URI::Escape;
use Digest::SHA qw/sha1_hex/;
use Digest::MD5 qw/md5_hex/;
use Encode qw(encode_utf8);

sub process {
    my $self = shift;
    my $data = shift;
    my $iodef = shift;
    
    my $addr = $data->{'address'};
    return unless($addr);
    return unless($addr =~ /^(ftp|https?):\/\//);
    
    $addr = lc($addr);
    $addr =~ s/\/$//;
    my $safe = uri_escape($addr,'\x00-\x1f\x7f-\xff');
    $safe = encode_utf8($addr);
    $addr = $safe;
  
    $data->{'address'} = $safe;
    $data->{'md5'} = md5_hex($safe) unless($data->{'md5'});
    $data->{'sha1'} = sha1_hex($safe) unless($data->{'sha1'});
    
    my @additional_data;
    push(@additional_data,(
        ExtensionType->new({
            dtype       => ExtensionType::DtypeType::dtype_type_string(),
            meaning     => 'url hash',
            formatid    => 'md5',
            content     => $data->{'md5'},
        }),
        ExtensionType->new({
            dtype       => ExtensionType::DtypeType::dtype_type_string(),
            meaning     => 'url hash',
            formatid    => 'sha1',
            content     => $data->{'sha1'},
        })
    ));
    
    my $event = EventDataType->new({
        Flow    => FlowType->new({
            System  => SystemType->new({
                Node    => NodeType->new({
                    Address => AddressType->new({
                        category        => AddressType::AddressCategory::Address_category_ext_value(),
                        ext_category    => 'url',
                        content         => $addr,
                    }),
                }),
                AdditionalData  => \@additional_data,
                category        => SystemType::SystemCategory::System_category_target(),
            }),
        }),
    });
    my $incident = @{$iodef->get_Incident()}[0];
    push(@{$incident->{'EventData'}},$event);
}

1;
