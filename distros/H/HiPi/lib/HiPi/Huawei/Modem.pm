#########################################################################################
# Package        HiPi::Huawei::Modem
# Description  : Base class for HiLink Modem
# Copyright    : Copyright (c) 2019 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Huawei::Modem;
use strict;
use warnings;
use HiPi::Huawei::HiLink;
use HiPi::Huawei::Errors;
use Digest::SHA qw( sha256_hex );
use MIME::Base64 qw( encode_base64 );
use Try::Tiny;
use Encode ();

use parent qw( HiPi::Class );

my @_package_accessors = qw(
    debug
    ip_address
    http
    errors
    safety
    force_gsm
);

__PACKAGE__->create_accessors( @_package_accessors );

our $VERSION ='0.81';

sub new {
    my($class, %params) = @_;
    $params{'errors'} = 'HiPi::Huawei::Errors';
    $params{'ip_address'} //= '192.168.8.1';
    $params{'safety'} //= 1;
    my $timeout = $params{'timeout'} || 30;
    $params{'http'} = HiPi::Huawei::HiLink->new( timeout => $timeout, debug => $params{'debug'} || 0 );
    $params{'_config'} = {};
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub _get_address {
    my $self = shift;
    return 'http://' . $self->ip_address;
}

sub generic_get {
    my($self, $route) = @_;
    my $session = $self->_get_session;
    return $session if(exists($session->{'code'}));
    my $ref = $self->http->get($self->_get_url($route));
    return $self->_response_ref($ref);
}

sub generic_post_xml {
    my($self, $route, $xml) = @_;
    my $session = $self->_get_session;
    return $session if(exists($session->{'code'}));
    my $ref = $self->http->post( $self->_get_url($route), $xml );
    return $self->_response_ref($ref);
}

sub _get_url {
    my($self, $route) = @_;
    return $self->_get_address . '/' . $route;
}

sub _get_session {
    my( $self ) = @_;
    my $ref = $self->http->get( $self->_get_url('api/webserver/SesTokInfo') );
    if(exists($ref->{'code'})) {
        $ref->{'message'} = 'unable to get session tokens : ' . $self->errors->get_error_message( $ref->{'code'} );
    } elsif(exists($ref->{'SesInfo'}) && exists($ref->{'TokInfo'})) {
        $self->http->set_security( $ref->{'SesInfo'}, $ref->{'TokInfo'} );
    } else {
        $ref->{'code'} = '101';
        $ref->{'message'} = $self->errors->get_error_message( $ref->{'code'} );
    }
    return $ref;
}

sub _response_ref {
    my ( $self, $ref ) = @_;
    if(ref($ref) eq 'HASH' && $ref->{'code'} && !$ref->{'message'}) {
        $ref->{'message'} = $self->errors->get_error_message( $ref->{'code'} );
    }
    return $ref;
}

sub _unsafe_methods {
    my $self = shift;
    my $rval = 0;
    if( $self->safety ) {
        # check if we can recover
        my $check = $self->hilink_can_modify_password;
        unless( ref($check)
                && exists($check->{'hilink_can_modify_password'})
                && $check->{'hilink_can_modify_password'} eq '1' ) {
            $rval = 1;
        }
    }
    return $rval;
}

sub _get_datestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    my $datestamp = sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $mon + 1, $mday, $hour, $min, $sec );
    return $datestamp;
}

sub _escape_value {
    my($self, $value) = @_;
    return '' unless(defined($value));
    $value =~ s/&/&amp;/sg;
    $value =~ s/</&lt;/sg;
    $value =~ s/>/&gt;/sg;
    $value =~ s/"/&quot;/sg;
    return $value;
}

#-------------------------------------------------

sub filter_characters {
    my($self, $msg) = @_;
    $msg //= '';
    return $msg unless($msg);
    my $filteredchars;
    my $usedencoding;
    my $allencoded;
    
    my @maps = ( $self->force_gsm ) 
        ? ( [ 'gsm0338', 0 ] )
        : ( [ 'gsm0338', 1 ], [ 'UCS-2', 1 ], [ 'UCS-2', 0 ] );
    
    for my $mapping ( @maps ) {
        my ( $encoding, $check ) = @$mapping;
        try {
            my $instring = $msg;
            my $octets = Encode::encode( $encoding, $instring, $check );
            $filteredchars = Encode::decode( $encoding, $octets, 1 );
        } catch {
            $filteredchars = undef;
        };
        if( defined( $filteredchars ) ) {
            $usedencoding = $encoding;
            $allencoded = $check;
            last;
        }
    }
    return ( wantarray ) ? ( $filteredchars, $usedencoding, $allencoded ) : $filteredchars;
}

sub login {
    my ($self, $username, $password ) = @_;
    
    unless( $username && $password ) {
        return $self->_response_ref( { code => 105 } );
    }
    
    # what's our login status
    my $status = $self->get_login_status();
    return $status if $status->{'code'};
    
    my $loginstatus = $status->{'State'};
    my $password_type = $status->{'password_type'};
    
    return { success => 'OK' } if $loginstatus eq '0'; # don't need login
    
    my $route = 'api/user/login';
    
    my $tokenised_password = '';
        
    if( $password_type eq '4' ) {
        $tokenised_password = encode_base64(
            sha256_hex( $username . encode_base64( sha256_hex( $password ), '' ) . $self->http->request_token ),
            ''
            );
    } else {
        $tokenised_password = encode_base64( $password, '' );
    }
            
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Username>) . $username . q(</Username>
        <Password>) . $tokenised_password . q(</Password>
        <password_type>) . $password_type . q(</password_type>
    </request>);
        
    # post direct - no new session info
    my $ref = $self->http->post( $self->_get_url($route), $xml );
    return $self->_response_ref( $ref );
}

sub logout {
    my $self = shift;
    my $route = 'api/user/logout';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Logout>1</Logout>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    $self->http->clear_security;
    return $ref;
}

sub get_status {
    my $self = shift;
    my $ref = $self->generic_get('api/monitoring/status');
    return $ref;
}

sub get_traffic_stats {
    my $self = shift;
    my $ref = $self->generic_get('api/monitoring/traffic-statistics');
    return $ref;
}

sub get_month_stats {
    my $self = shift;
    my $ref = $self->generic_get('api/monitoring/month_statistics');
    return $ref;
}

sub get_global_module_switch {
    my $self = shift;
    my $ref = $self->generic_get('api/global/module-switch');
    return $ref;
}

sub get_profiles {
    my $self = shift;
    my $ref = $self->generic_get('api/dialup/profiles');
    return $ref;
}

sub get_login_status {
    my $self = shift;
    my $ref = $self->generic_get('api/user/state-login');
    return $ref;
}

sub get_login_required {
    my $self = shift;
    my $ref = $self->generic_get('api/user/hilink_login');
    return $ref;
}

sub set_login_required {
    my ($self, $required) = @_;
    $required = ( $required ) ? 1 : 0;
    
    if( $required ) {
        return $self->_response_ref( { 'code' => 110 } ) if $self->_unsafe_methods;
    }
    
    my $route = 'api/user/hilink_login';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <hilink_login>) . $required . q(</hilink_login>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub get_encryption_mode {
    my $self = shift;
    my $ref = $self->generic_get('api/user/password');
    if($ref->{'encryption_enable'}) {
        return $ref;
    } else {
        return $self->_response_ref( { 'encryption_enable' => 0 } );
    }
}

sub change_password {
    my( $self, $username, $oldpassword, $newpassword ) = @_;

    return $self->_response_ref( { 'code' => 110 } ) if $self->_unsafe_methods; 

    unless( $username && $oldpassword && $newpassword ) {
        return $self->_response_ref( { code => 102 } );
    }
    
    my $lrequired = $self->get_login_required;
    
    unless( $lrequired->{'hilink_login'} ) {
        return $self->_response_ref( { code => 103 } );
    }
    
    my $route = 'api/user/password';
    
    my $hashmode = $self->get_encryption_mode()->{'encryption_enable'};
    
    my $tokenised_oldpassword;
    
    my $tokenised_newpassword = encode_base64( $newpassword, '' );
        
    if( $hashmode ) {
        $tokenised_oldpassword = encode_base64(
            sha256_hex( $username . encode_base64( sha256_hex( $oldpassword ), '' ) . $self->http->request_token ),
            ''
            );
    } else {
        $tokenised_oldpassword = encode_base64( $oldpassword, '' );
    }
           
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Username>) . $username . q(</Username>
        <CurrentPassword>) . $tokenised_oldpassword . q(</CurrentPassword>
        <NewPassword>) . $tokenised_newpassword . q(</NewPassword>
        <encryption_enable>) . $hashmode . q(</encryption_enable>
    </request>);
        
    # post direct - no new session info
    my $ref = $self->http->post( $self->_get_url($route), $xml );
    
    if( $ref->{'success'} ) {
        $self->http->clear_security;
        $ref = $self->login( $username, $newpassword );
    } else {
        $ref = $self->_response_ref( $ref );
    }
    
    return $ref;
    
}

sub get_serial_number {
    my $self = shift;
    my $ref = $self->get_device_info;
    return $ref if $ref->{'code'};
    return { 'SerialNumber' => $ref->{'SerialNumber'} };
}

sub get_device_feature_switch {
    my $self = shift;
    my $ref = $self->generic_get('api/device/device-feature-switch');
    return $ref;
}

sub get_global_config {
    my $self = shift;
    my $ref = $self->generic_get('config/global/config.xml');
    return $ref;
}

sub get_deviceinfo_config {
    my $self = shift;
    my $ref = $self->generic_get('config/deviceinformation/config.xml');
    return $ref;
}

sub hilink_can_modify_password {
    my $self = shift;
    my $gcfg = $self->get_global_config;
    return $gcfg if $gcfg->{'code'};
    my $can = 0;
    my $checkval = $gcfg->{'menu'}->{'settings'}->{'system'}->{'modifypassword'};
    $can = 1 if( $checkval && $checkval eq 'modifypassword' );
    return { 'hilink_can_modify_password' => $can };
}

sub get_test_func {
    my $self = shift;
    my $ref = $self->generic_get('api/device/device-feature-switch');
    return $ref;
}

sub get_sms_send_status {
    my $self = shift;
    my $ref = $self->generic_get('api/sms/send-status');
    return $ref;
}

sub get_signal_info {
    my $self = shift;
    my $ref = $self->generic_get('api/device/signal');
    return $ref;
}

sub get_basic_info {
    my $self = shift;
    my $ref = $self->generic_get('api/device/basic_information');
    return $ref;
}

sub get_network {
    my $self = shift;
    my $ref = $self->generic_get('api/net/current-plmn');
    return $ref;
}

sub get_network_mode_info {
    my $self = shift;
    my $ref = $self->generic_get('api/net/network');
    return $ref;
}

sub get_network_mode {
    my $self = shift;
    my $ref = $self->generic_get('api/net/net-mode');
    return $ref;
}

sub get_network_mode_list {
    my $self = shift;
    my $ref = $self->generic_get('api/net/net-mode-list');
    return $ref;
}

sub get_device_info {
    my $self = shift;
    my $ref = $self->generic_get('api/device/information');
    return $ref;
}

sub get_connection_info {
    my $self = shift;
    my $ref = $self->generic_get('api/dialup/connection');
    return $ref;
}

sub get_data_plan {
    my $self = shift;
    my $ref = $self->generic_get('api/monitoring/start_date');
    return $ref;
}

sub set_data_plan {
    my($self, $startdate, $limit, $threshold ) = @_;
    
    # check start date
    unless( $startdate && $startdate =~ /^[1-9][0-9]*$/ && $startdate > 0 && $startdate < 32 ) {
        return $self->_response_ref( { code => 111 } );
    }
    
    # check limit
    unless( $limit && $limit =~ /^[1-9][0-9]*(MB|GB|)$/ ) {
        return $self->_response_ref( { code => 112 } );
    }
    
    # check threshhold
    unless( $threshold && $threshold =~ /^[1-9][0-9]*$/ && $threshold > 0 && $threshold < 101 ) {
        return $self->_response_ref( { code => 113 } );
    }
    
    my $route = 'api/monitoring/start_date';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <StartDay>) . $startdate . q(</StartDay>
        <DataLimit>) . $limit . q(</DataLimit>
        <MonthThreshold>) . $threshold . q(</MonthThreshold>
        <SetMonthData>1</SetMonthData>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub set_data_plan_off {
    my($self) = @_;
    my $route = 'api/monitoring/start_date';
    
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <StartDay>1</StartDay>
        <DataLimit>0MB</DataLimit>
        <MonthThreshold>90</MonthThreshold>
        <SetMonthData>0</SetMonthData>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub clear_traffic {
    my($self) = @_;
    my $route = 'api/monitoring/clear-traffic';
    
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <ClearTraffic>1</ClearTraffic>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub check_notifications {
    my $self = shift;
    my $ref = $self->generic_get('api/monitoring/check-notifications');
    return $ref;
}

sub get_data_status {
    my $self = shift;
    my $ref = $self->generic_get('api/dialup/mobile-dataswitch');
    return $ref;
}

sub set_data {
    my($self, $onoff) = @_;
    if($onoff) {
        return $self->set_data_on;
    } else {
        return $self->set_data_off;
    }
}

sub set_data_off {
    my $self = shift;
    my $route = 'api/dialup/mobile-dataswitch';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <dataswitch>0</dataswitch>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub set_data_on {
    my $self = shift;
    my $route = 'api/dialup/mobile-dataswitch';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <dataswitch>1</dataswitch>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub device_reboot {
    my $self = shift;
    my $route = 'api/device/control';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Control>1</Control>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub device_restore {
    my $self = shift;
    my $route = 'api/device/control';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Control>2</Control>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

#sub device_backup {
#    my $self = shift;
#    my $route = 'api/device/control';
#    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
#    <request>
#        <Control>3</Control>
#    </request>);
#    my $ref = $self->generic_post_xml( $route, $xml );
#    return $ref;
#}

sub device_serial_restore {
    my ($self, $sn ) = @_;
    return $self->_response_ref( { code => '104' } ) unless ($sn);
    $sn = uc($sn);
    my $route = 'api/device/restore-default';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <SN>) . $sn . q(</SN>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub device_shutdown {
    my $self = shift;
    my $route = 'api/device/control';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Control>4</Control>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub send_sms {
    my($self, $numbers, $message) = @_;
    my $date = _get_datestamp();
    $message = $self->_escape_value( $message );
    $message = $self->filter_characters($message);
    my $len = length($message);
    my @numbers = ( $numbers && ref($numbers) eq 'ARRAY' ) ? @$numbers : ( $numbers );
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Index>-1</Index>
        <Phones>) . qq(\n);
    for my $number ( @numbers ) {
        $xml .= q(            <Phone>) . $number . qq(</Phone>\n);
    }
    $xml .= q(        </Phones>
        <Sca></Sca>
        <Content>) . $message . q(</Content>
        <Length>) . $len . q(</Length>
        <Reserved>1</Reserved>
        <Date>) . $date . q(</Date>
    </request>  
    );
    
    my $ref = $self->generic_post_xml( 'api/sms/send-sms', $xml );
    
    return $ref;
}

sub get_sms_count {
    my $self = shift;
    my $route = 'api/sms/sms-count';
    my $ref = $self->generic_get($route);
    return $ref;
}

sub get_inbox {
    my $self = shift;
    return $self->get_sms(50,1);
}

sub get_outbox {
    my $self = shift;
    return $self->get_sms(50,2);
}

sub get_drafts {
    my $self = shift;
    return $self->get_sms(50,3);
}

sub delete_sms {
    my($self, $index) = @_;
    my $route = 'api/sms/delete-sms';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Index>) . $index . q(</Index>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub set_sms_read {
    my($self, $index) = @_;
    my $route = 'api/sms/set-read';
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <Index>) . $index . q(</Index>
    </request>);
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub get_sms {
    my($self, $count, $boxtype ) = @_;
    my $route = 'api/sms/sms-list';
    $count ||= 1;
    $boxtype ||= 1;
    if($boxtype =~ /^in/i ) {
        $boxtype = 1;
    } elsif($boxtype =~ /^out/i ) {
        $boxtype = 2;
    } elsif($boxtype =~ /^dra/i ) {
        $boxtype = 3;
    }
    
    unless($boxtype =~ /^(1|2|3)$/ ) {
        $boxtype = 1;
    }
    
    my $xml = q(<?xml version="1.0" encoding="UTF-8"?>
    <request>
        <PageIndex>1</PageIndex>
        <ReadCount>) . $count . q(</ReadCount>
        <BoxType>) . $boxtype . q(</BoxType>
        <SortType>0</SortType>
        <Ascending>0</Ascending>
        <UnreadPreferred>1</UnreadPreferred>
    </request>);
    
    my $ref = $self->generic_post_xml( $route, $xml );
    $ref = $self->_response_ref( $ref );
    if(exists($ref->{'Count'})) {
        $ref->{'BoxType'} = $boxtype;
    }
    return $ref;
}

sub connect_modem {
    my $self = shift;
    my $route = 'api/dialup/dial';
    my $xml = '<?xml version="1.0" encoding="UTF-8"?><request><Action>1</Action></request>';
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

sub disconnect_modem {
    my $self = shift;
    my $route = 'api/dialup/dial';
    my $xml = '<?xml version="1.0" encoding="UTF-8"?><request><Action>0</Action></request>';
    my $ref = $self->generic_post_xml( $route, $xml );
    return $ref;
}

1;

__END__


