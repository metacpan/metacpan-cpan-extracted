package DracPerl::Models::Commands::Collection::SystemInformations;
use XML::Rabbit::Root;

has_xpath_value 'pw_state'       => '/root/pwState';
has_xpath_value 'sys_desc'       => '/root/sysDesc';
has_xpath_value 'sys_rev'        => '/root/sysRev';
has_xpath_value 'hostname'       => '/root/hostName';
has_xpath_value 'os_version'     => '/root/osVersion';
has_xpath_value 'os_name'        => '/root/osName';
has_xpath_value 'svc_tag'        => '/root/svcTag';
has_xpath_value 'bios_version'   => '/root/biosVer';
has_xpath_value 'fw_version'     => '/root/fwVersion';
has_xpath_value 'lcc_fw_version' => '/root/LCCfwVersion';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::Collection::SystemInformations - Return some information about software

=head1 ATTRIBUTES

=head2 pw_state

The current power state of the system

'1' : Main power is on
'0' : Machine is off

=head2 sys_desc

System description

eg : 'PowerEdge R510'

=head2 sys_rev

System revision

eg : 'II'

=head2 hostname

Hostname of the machine 

eg : 'Eudora.home'

=head2 os_name

Name of the OS (if availaible) 

eg : 'VMware ESXi 5.5'

=head2 os_version

Version of the OS (if available)

eg : '5.5'

=head2 svc_tag

Dell's Service Tag of the system

eg : 'BLAHBLAH'

=head2 bios_version

The version of the BIOS

=head2 fw_version

Version of the Firmware of the machine

=head2 lcc_fw_version

Version of the Life Cycle Controller firmware

=cut
