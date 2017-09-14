#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use HTTP::Response;


use Device::PaloAlto::Firewall;

plan tests => 12;

my $fw = Device::PaloAlto::Firewall->new(uri => 'http://localhost.localdomain', username => 'test', password => 'test', debug => 1);
my $test = $fw->tester();

# This test file has a number of methods in scope. It tests thre return values for:
#       * software_check()
#       * content_check()
#       * antivirus_check()
#       * gp_client_check()


# No software check comms 
$fw->meta->add_method('_send_http_request', sub { return software_check_no_comms() } );

my $res = $fw->software_check();
isa_ok( $res, 'ARRAY' );
is_deeply( $res , [] , "No software check comms returns an empty ARRAYREF" );

$fw->meta->add_method('_send_http_request', sub { return software_check_success() } );

isa_ok( $fw->software_check(), 'ARRAY' );

sub software_check_success {
   return HTTP::Response->new(
       200,
       "Software Check Success",
       undef,
       q{<response status="success"><result><sw-updates last-updated-at="2017/09/05 18:47:51"><msg/><versions><entry><version>8.0.4</version><filename>PanOS_vm-8.0.4</filename><size>378</size><size-kb>387602</size-kb><released-on>2017/07/26  14:29:20</released-on><release-notes>https://downloads.paloaltonetworks.com/software/PAN-OS-8.0.4-RN.pdf?__gda__=1505267677_b81722ef094994c11935dcee2d384b57</release-notes><downloaded>no</downloaded><current>no</current><latest>yes</latest><uploaded>no</uploaded></entry><entry><version>8.0.3</version><filename>PanOS_vm-8.0.3</filename><size>381</size><size-kb>390427</size-kb><released-on>2017/06/18  14:55:45</released-on><release-notes>https://downloads.paloaltonetworks.com/software/PAN-OS-8.0-RN.pdf?__gda__=1505267677_0b0bb9c1a2ce56dea012f148af98ea68</release-notes><downloaded>yes</downloaded><current>yes</current><latest>no</latest><uploaded>no</uploaded></entry></versions></sw-updates></result></response>}
   );
}

sub software_check_no_comms {
    return HTTP::Response->new(
       200,
      "No update comms",
      undef,
     q{<response status="error"><msg><line>Failed to check upgrade info due to generic communication error. Please check network connectivity and try again.</line></msg></response>}
 );
}





# No content check comms 
$fw->meta->add_method('_send_http_request', sub { return content_check_no_comms() } );

$res = $fw->content_check();
isa_ok( $res, 'ARRAY' );
is_deeply( $res , [] , "No content check comms returns an empty ARRAYREF" );

$fw->meta->add_method('_send_http_request', sub { return content_check_success() } );

isa_ok( $fw->content_check(), 'ARRAY' );


sub content_check_no_comms {
    return HTTP::Response->new(
       200,
      "No update comms",
      undef,
     q{<response status="error"><msg><line>Failed to check content upgrade info due to generic communication error. Please check network connectivity and try again.</line></msg></response>}
 );
}

sub content_check_success {
   return HTTP::Response->new(
       200,
       "Content Check Success",
       undef,
       q{<response status="success"><result><content-updates last-updated-at="2017/09/05 20:23:49 PDT"><entry><version>730-4195</version><app-version>730-4195</app-version><filename>panupv2-all-contents-730-4195</filename><size>32</size><size-kb>32940</size-kb><released-on>2017/08/30 16:54:52 PDT</released-on><release-notes>https://downloads.paloaltonetworks.com/content/content-730-4195.html?__gda__=1505273435_ecd6b4c3b9d6c54668a9b95068e4f784</release-notes><downloaded>no</downloaded><current>no</current><previous>no</previous><installing>no</installing><features>Apps, Threats</features><update-type>Full</update-type><feature-desc>Unknown</feature-desc></entry><entry><version>712-4114</version><app-version>712-4114</app-version><filename>panupv2-all-contents-712-4114</filename><size>32</size><size-kb>32785</size-kb><released-on>2017/07/04 13:18:35 PDT</released-on><release-notes>https://downloads.paloaltonetworks.com/content/content-712-4114.html?__gda__=1500001516_76df2e5e9a36007836190f854f18f4ac</release-notes><downloaded>no</downloaded><current>yes</current><previous>no</previous><installing>no</installing><features>Apps, Threats</features><update-type>Full</update-type><feature-desc>Unknown</feature-desc></entry></content-updates></result></response>}
   );
}




# No AV check comms 
$fw->meta->add_method('_send_http_request', sub { return av_check_no_comms() } );

$res = $fw->antivirus_check();
isa_ok( $res, 'ARRAY' );
is_deeply( $res , [] , "No AV check comms returns an empty ARRAYREF" );

$fw->meta->add_method('_send_http_request', sub { return av_check_success() } );

isa_ok( $fw->antivirus_check(), 'ARRAY' );


sub av_check_no_comms {
    return HTTP::Response->new(
       200,
      "No update comms",
      undef,
     q{<response status="error"><msg><line>Failed to check content upgrade info due to generic communication error. Please check network connectivity and try again.</line></msg></response>}
 );
}

sub av_check_success {
   return HTTP::Response->new(
       200,
       "AV Check Success",
       undef,
       q{<response status="success"><result><content-updates last-updated-at="2017/09/05 20:29:15 PDT"><entry><version>2358-2850</version><app-version>2358-2850</app-version><filename>panup-all-antivirus-2358-2850</filename><size>77</size><size-kb>79446</size-kb><released-on>2017/09/05 04:00:27 PDT</released-on><release-notes>https://downloads.paloaltonetworks.com/virus/AntiVirusExternal-2358.html?__gda__=1505273762_3944e78159856dce2da43763787e2990</release-notes><downloaded>no</downloaded><current>no</current><previous>no</previous><installing>no</installing><features>Virus</features><update-type>Full</update-type><feature-desc>Unknown</feature-desc></entry></content-updates></result></response>}
   );
}





# No GP client check comms 
$fw->meta->add_method('_send_http_request', sub { return gp_check_no_comms() } );

$res = $fw->gp_client_check();
isa_ok( $res, 'ARRAY' );
is_deeply( $res , [] , "No GP check comms returns an empty ARRAYREF" );

$fw->meta->add_method('_send_http_request', sub { return gp_check_success() } );

isa_ok( $fw->gp_client_check(), 'ARRAY' );


sub gp_check_no_comms {
    return HTTP::Response->new(
       200,
      "No update comms",
      undef,
     q{<response status="error"><msg><line>Failed to check upgrade info due to generic communication error. Please check network connectivity and try again.</line></msg></response>}
 );
}

sub gp_check_success {
   return HTTP::Response->new(
       200,
       "AV Check Success",
       undef,
       q{<response status="success"><result><sw-updates last-updated-at="2017/09/05 20:43:06"><msg/><versions><entry><version>4.0.3</version><filename>PanGP-4.0.3</filename><size>39</size><size-kb>40823</size-kb><released-on>2017/09/01  15:47:38</released-on><release-notes>https://downloads.paloaltonetworks.com/software/GlobalProtect-Agent-4.0.3-RNs.pdf?__gda__=1505274591_7e7939d39fdfc160f96acf3ed6e81b68</release-notes><downloaded>no</downloaded><current>no</current><latest>no</latest><uploaded>no</uploaded></entry><entry><version>4.0.2</version><filename>PanGP-4.0.2</filename><size>39</size><size-kb>40746</size-kb><released-on>2017/05/24  23:16:08</released-on><release-notes>https://downloads.paloaltonetworks.com/software/GlobalProtect-Agent-4.0.2-RNs.pdf?__gda__=1505274591_8143605070728ba648d784608ae5dde6</release-notes><downloaded>no</downloaded><current>no</current><latest>no</latest><uploaded>no</uploaded></entry></versions></sw-updates></result></response>}
   );
}
