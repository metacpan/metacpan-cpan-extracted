package Iodef::Pb::Format::Iptables;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

use Regexp::Common qw/net/;

sub write_out {
    my $self    = shift;
    my $args    = shift;
   
    my $config  = $args->{'config'};
    my $array   = $self->SUPER::to_keypair($args);
    
    return '' unless(exists(@{$array}[0]->{'address'}));
    
     my $text = "iptables -N CIF_IN\n";
    $text .= "iptables -F CIF_IN\n";
    $text .= "iptables -N CIF_OUT\n";
    $text .= "iptables -F CIF_OUT\n";

    my $isWhitelist = 0;

    foreach (@$array){
        my $address = $_->{'address'};
        unless($_->{'address'} =~ /^$RE{'net'}{'IPv4'}/){
            warn 'WARNING: Currently this plugin only supports IPv4 addresses'."\n";
            return '';
        }
        $_->{'address'} = normalize_address($_->{'address'});
        if($_->{'assessment'} eq 'whitelist'){
            $isWhitelist = 1;
            $text .= "iptables -A CIF_IN -s $_->{'address'} -j ACCEPT\n";
            $text .= "iptables -A CIF_OUT -d $_->{'address'} -j ACCEPT\n";
        } else {
            $text .= "iptables -A CIF_IN -s $_->{'address'} -j DROP\n";
            $text .= "iptables -A CIF_OUT -d $_->{'address'} -j DROP\n";
        }
    }
    $text .= "iptables -A INPUT -j CIF_IN\n";
    
    if($isWhitelist){
        $text .= "iptables -A CIF_IN -j LOG --log-level 6 --log-prefix '[IPTABLES] cif accepted'\n";
    } else {
        $text .= "iptables -A CIF_IN -j LOG --log-level 6 --log-prefix '[IPTABLES] cif dropped'\n";
    }
    
    $text .= "iptables -A OUTPUT -j CIF_OUT\n";
    if($isWhitelist){
        $text .= "iptables -A CIF_OUT -j LOG --log-level 6 --log-prefix '[IPTABLES] cif accepted'\n";
    } else {
        $text .= "iptables -A CIF_OUT -j LOG --log-level 6 --log-prefix '[IPTABLES] cif dropped'\n";
    }
    return $text;
}

sub normalize_address {
    my $addr = shift;

    my @bits = split(/\./,$addr);
    foreach(@bits){
        next unless(/^0{1,2}[1-9]{1,2}/);
        $_ =~ s/^0{1,2}//;
    }
    return join('.',@bits);
}
1;
