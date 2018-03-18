package DracPerl::Models::Commands::DellDefault::GetInv;
use XML::Rabbit::Root;

has_xpath_object_list 'controllers' =>
    '/root/HWINVs/DCIM_ControllerViews/DCIM_ControllerView' =>
    'DracPerl::Models::Abstract::Controller';

has_xpath_object_list 'memories' =>
    '/root/HWINVs/DCIM_MemoryViews/DCIM_MemoryView' =>
    'DracPerl::Models::Abstract::Memory';

has_xpath_object_list 'nics' => '/root/HWINVs/DCIM_NICViews/DCIM_NICView' =>
    'DracPerl::Models::Abstract::NIC';

has_xpath_object_list 'video_cards' =>
    '/root/HWINVs/DCIM_VideoViews/DCIM_VideoView' =>
    'DracPerl::Models::Abstract::VideoCard';

has_xpath_object_list 'power_supply_slots' =>
    '/root/HWINVs/DCIM_PowerSupplyViews/DCIM_PowerSupplyView' =>
    'DracPerl::Models::Abstract::PowerSupplySlot';

has_xpath_object_list 'physical_disks' =>
    '/root/HWINVs/DCIM_PhysicalDiskViews/DCIM_PhysicalDiskView' =>
    'DracPerl::Models::Abstract::PhysicalDisk';

has_xpath_object_list 'idrac_cards' =>
    '/root/HWINVs/DCIM_iDRACCardViews/DCIM_iDRACCardView' =>
    'DracPerl::Models::Abstract::iDracCard';

has_xpath_object_list 'vflashs' =>
    '/root/HWINVs/DCIM_VFlashViews/DCIM_VFlashView' =>
    'DracPerl::Models::Abstract::VFlash';

has_xpath_object_list 'cpus' => '/root/HWINVs/DCIM_CPUViews/DCIM_CPUView' =>
    'DracPerl::Models::Abstract::CPU';

has_xpath_value 'bios_version' => '/root/SWINVs/BIOS';
has_xpath_value 'lcc_version'  => '/root/SWINVs/Lifecycle_Controller';
has_xpath_value 'diag'         => '/root/SWINVs/DIAG';
has_xpath_value 'os_drivers'   => '/root/SWINVs/OS_Drivers';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::GetInv - Return the full hardware and software inventory of the system

=head1 ATTRIBUTES

=head2 bios_version

The BIOS Version

eg : '1.4.0'

=head2 lcc_version

The Life Cycle Controller version

eg : '1.4.0.445'

=head2 diag

The version of the Dell 32bits Diagnostics tool

eg : '5144A0'

=head2 os_drivers

The version of the OS Driver pack

eg : '6.3.9.23'

=head2 controllers

List of all RAID controllers
An array of L<DracPerl::Models::Abstract::Controller>

=head2 memories

A list of all memory stick
An array of L<DracPerl::Models::Abstract::Memory>

=head2 nics

A list of all Network Interface Cards (NIC)
An array of L<DracPerl::Models::Abstract::NIC>

=head2 video_cards

A list of all videos cards
An array of L<DracPerl::Models::Abstract::VideoCard>

=head2 power_supply_slots

A list of all power supply slot. (And what is occupying the slot)
An array of L<DracPerl::Models::Abstract::PowerSupplySlot>

=head2 physical_disks

A list of all physical disks plugged in.
An array of L<DracPerl::Models::Abstract::PhysicalDisk>

=head2 idrac_cards

A list of all iDrac cards
An array of L<DracPerl::Models::Abstract::iDracCard>

=head2 vflashs

A list of all vFlash slot and their contents.
An array of L<DracPerl::Models::Abstract::VFlash>

=head2 cpus

A list of all CPUs
An array of L<DracPerl::Models::Abstract::CPU>

=cut