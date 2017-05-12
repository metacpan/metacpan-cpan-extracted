package Iodef::Pb::Format::Pcapfilter;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

use Regexp::Common qw/net/;
use Regexp::Common::net::CIDR;

sub write_out {
    my $self    = shift;
    my $args    = shift;
   
    my $config  = $args->{'config'};
    my $array   = $self->SUPER::to_keypair($args);
    
    return '' unless(exists(@{$array}[0]->{'address'}));
    
    my $text = '';
    foreach (@$array){
        my $address = $_->{'address'};
        if($address =~ /^$RE{'net'}{'CIDR'}{'IPv4'}$/){
            $text .= "net $address or ";
        } else {
            $text .= "host $address or ";
        }
    }
    $text =~ s/ or $//;
    return $text;
}
1;
