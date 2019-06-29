###############################################################################
# Distribution : HiPi Modules for Raspberry Pi
# File         : lib/HiPi/RaspberryPi.pm
# Description  : Information about host Raspberry Pi
# Copyright    : Copyright (c) 2013-2019 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::RaspberryPi;

###############################################################################
use strict;
use warnings;
use Carp;

our $VERSION ='0.78';

my ( $btype1, $btype2, $btype3, $btype4) = ( 1, 2, 3, 4 );

my $israspberry = 0;
my $israspberry2 = 0;
my $israspberry3 = 0;
my $israspberry4 = 0;
my $hasdevicetree = 0;
my $homedir = '/tmp';

my %_revstash = (
    'beta'      => { release => 'Q1 2012', model_name => 'Raspberry Pi Model B Revision beta', revision => 'beta', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0002'      => { release => 'Q1 2012', model_name => 'Raspberry Pi Model B Revision 1.0',  revision => '0002', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0003'      => { release => 'Q3 2012', model_name => 'Raspberry Pi Model B Revision 1.0',  revision => '0003', board_type => $btype1, memory => 256, manufacturer => 'Generic' },
    '0004'      => { release => 'Q3 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0004', board_type => $btype2, memory => 256, manufacturer => 'Sony' },
    '0005'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0005', board_type => $btype2, memory => 256, manufacturer => 'Qisda' },
    '0006'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0',  revision => '0006', board_type => $btype2, memory => 256, manufacturer => 'Egoman' },
    '0007'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0007', board_type => $btype2, memory => 256, manufacturer => 'Egoman' },
    '0008'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0008', board_type => $btype2, memory => 256, manufacturer => 'Sony' },
    '0009'      => { release => 'Q1 2013', model_name => 'Raspberry Pi Model A', revision => '0009', board_type => $btype2, memory => 256, manufacturer => 'Qisda' },
    
    '000d'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000d', board_type => $btype2, memory => 512, manufacturer => 'Egoman' },
    '000e'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000e', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '000f'      => { release => 'Q4 2012', model_name => 'Raspberry Pi Model B Revision 2.0', revision => '000f', board_type => $btype2, memory => 512, manufacturer => 'Qisda' },
    
    '0010'      => { release => 'Q3 2014', model_name => 'Raspberry Pi Model B +', revision => '0010', board_type => $btype3, memory => 512, manufacturer => 'Sony' },
    '0011'      => { release => 'Q2 2013', model_name => 'Compute Module', revision => '0011', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '0012'      => { release => 'Q4 2014', model_name => 'Raspberry Pi Model A +', revision => '0012', board_type => $btype3, memory => 256, manufacturer => 'Sony' },
    
    '0014'      => { release => 'Q2 2015', model_name => 'Compute Module', revision => '0014', board_type => $btype2, memory => 512, manufacturer => 'Sony' },
    '0015'      => { release => 'Q4 2015', model_name => 'Raspberry Pi Model A +', revision => '0015', board_type => $btype3, memory => 512, manufacturer => 'Sony' },
    'unknown'   => { release => 'Q1 2012', model_name => 'Virtual or Unknown Raspberry Pi', revision => 'UNKNOWN', board_type => $btype2, memory => 512,  manufacturer => 'HiPi Virtual' },
    'unknownex' => { release => 'Q1 2012', model_name => 'Virtual or Unknown Raspberry Pi', revision => 'UNKNOWN', board_type => $btype3, memory => 1024, manufacturer => 'HiPi Virtual' },
);

# MAP 24 bits of Revision  NEW:1, MEMSIZE:3, MANUFACTURER:4, PROCESSOR:4, MODEL:8, BOARD REVISION:4

my %_revinfostash = (
    memsize => {
        '0' => 256,
        '1' => 512,
        '2' => 1024,
        '3' => 2048,
        '4' => 4096,
    },
    manufacturer => {
        '0' => 'Sony UK',
        '1' => 'Egoman',
        '2' => 'Embest',
        '3' => 'Sony Japan',
        '4' => 'Embest',
        '5' => 'Stadium',
    },
    
    processor => {
        '0' => 'BCM2835',
        '1' => 'BCM2836',
        '2' => 'BCM2837',
        '3' => 'BCM2711',
    },
    
    type => {
        '0'  => 'Raspberry Pi Model A',                 # 00
        '1'  => 'Raspberry Pi Model B',                 # 01
        '2'  => 'Raspberry Pi Model A Plus',            # 02
        '3'  => 'Raspberry Pi Model B Plus',            # 03
        '4'  => 'Raspberry Pi 2 Model B',               # 04
        '5'  => 'Raspberry Pi Alpha',                   # 05
        '6'  => 'Raspberry Pi Compute Module 1',        # 06
        '7'  => 'Raspberry Pi Unknown Model 07',        # 07
        '8'  => 'Raspberry Pi 3 Model B',               # 08
        '9'  => 'Raspberry Pi Zero',                    # 09
        '10' => 'Raspberry Pi Compute Module 3',        # 0A
        '11' => 'UNKNOWN Rasberry Pi Model 11',         # 0B
        '12' => 'Raspberry Pi Zero W',                  # 0C
        '13' => 'Raspberry Pi 3 Model B Plus',          # 0D
        '14' => 'Raspberry Pi 3 Model A Plus',          # 0E
        '15' => 'UNKNOWN Rasberry Pi Model 15',         # 0F
        '16' => 'Raspberry Pi Compute Module 3 Plus',   # 10
        '17' => 'Raspberry Pi 4 Model B',               # 11
    },
    board_type => {
        '0'  => $btype2,
        '1'  => $btype2,
        '2'  => $btype3,
        '3'  => $btype3,
        '4'  => $btype3,
        '5'  => $btype1,
        '6'  => $btype2,
        '7'  => $btype3,
        '8'  => $btype3,
        '9'  => $btype3,
        '10' => $btype4,
        '11' => $btype3,
        '12' => $btype3,
        '13' => $btype3,
        '14' => $btype3,
        '15' => $btype3,
        '16' => $btype4,
        '17' => $btype3,
    },
    release => {
        '0'  => 'Q1 2013',
        '1'  => 'Q3 2012',
        '2'  => 'Q4 2014',
        '3'  => 'Q3 2014',
        '4'  => 'Q1 2015',
        '5'  => 'Q1 2012',
        '6'  => 'Q2 2013',
        '7'  => 'Q2 2015',
        '8'  => 'Q1 2016',
        '9'  => 'Q4 2015',
        '10' => 'Q1 2017',
        '11' => 'unknown',
        '12' => 'Q1 2017',
        '13' => 'Q1 2018',
        '14' => 'Q4 2018',
        '15' => 'unknown',
        '16' => 'Q1 2019',
        '17' => 'Q2 2019',
        
    },
);

my $_config = $_revstash{unknownex};

sub os_is_windows { return ( $^O =~ /^mswin/i ) ? 1 : 0; }

sub os_is_osx { return ( $^O =~ /^darwen/i ) ? 1 : 0; }

sub os_is_linux { return ( $^O =~ /^linux/i ) ? 1 : 0; }

sub os_is_other { return ( $^O !~ /^mswin|linux|darwen/i ) ? 1 : 0; }

sub os_supported { return ( $^O =~ /^linux/i ) ? 1 : 0; }

sub is_raspberry { return $israspberry; }

sub is_raspberry_2 { return $israspberry2; }

sub is_raspberry_3 { return $israspberry3; }

sub is_raspberry_4 { return $israspberry4; }

sub has_device_tree { return $hasdevicetree; }

sub home_directory { return $homedir; }

sub board_type { return $_config->{board_type}; }

sub gpio_header_type { return $_config->{board_type}; }

sub manufacturer { return $_config->{manufacturer}; }

sub release_date { return $_config->{release}; }

sub processor { return $_config->{processor}; }

sub hardware { return $_config->{hardware}; }

sub model_name { return $_config->{modelname}; }

sub revision { return $_config->{revision}; }

sub memory { return $_config->{memory}; }

sub serial_number { return $_config->{serial}; }

sub board_description {
    my $description = 'Unknown board type';
    if($_config->{board_type} == $btype1 ) {
        $description = 'Type 1 26 pin GPIO header';
    } elsif($_config->{board_type} == $btype2 ) {
        $description = 'Type 2 26 pin GPIO header';
    } elsif($_config->{board_type} == $btype3 ) {
        $description = 'Type 3 40 pin GPIO header';
    } elsif($_config->{board_type} == $btype4 ) {
        $description = 'Type 4 Compute Module';
    }
    return $description;
}

sub _configure {
    
    my %_cpuinfostash = ();
    
    my $device_tree_boardname = '';
    
    if( os_is_linux() ) {
        # clean our path for safety
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        my $output = qx(cat /proc/cpuinfo);
        
        if( $output ) {
            for ( split(/\n/, $output) ) {
                if( $_ =~ /^([^\s]+)\s*:\s(.+)$/ ) {
                    $_cpuinfostash{$1} = $2;
                }
            }
        }
        
        $hasdevicetree = ( -e '/proc/device-tree/soc/ranges' ) ? 1 : 0;
        if( $hasdevicetree ) {
            my $bname = qx(cat /proc/device-tree/model);
            chomp $bname;
            
            $device_tree_boardname = $bname if( $bname );
        }
    }
    
    my $hardware = ($_cpuinfostash{Hardware}) ?  $_cpuinfostash{Hardware} : 'BCM2709';
    my $serial = ($_cpuinfostash{Serial}) ?  $_cpuinfostash{Serial} : 'UNKNOWN';
    my $board_type = ( $hardware eq 'BCM2708' ) ? 2 : 3;
    my $defaultkey = ( $board_type == 3  ) ? 'unknownex' : 'unknown';
    my $rev = ($_cpuinfostash{Revision}) ?  lc( $_cpuinfostash{Revision} ) : $defaultkey;
    $rev =~ s/^\s+//;
    $rev =~ s/\s+$//;
        
    $israspberry = $_cpuinfostash{Hardware} && $_cpuinfostash{Hardware} =~ /^BCM2708|BCM2709|BCM2710|BCM2835$/;
        
    if ( $rev =~ /(beta|unknown|unknownex)$/) {
        my $infokey = exists($_revstash{$rev}) ? $rev : $defaultkey;
        $_config = { %{ $_revstash{$infokey} } };
        $_config->{processor} = 'BCM2835';
        $_config->{revision} = 'UNKNOWN';
    } else {
        # is this a scheme 0 or 1 number
        my $revnum = oct( '0x' . $rev );
        
        my $schemenewt = 0b100000000000000000000000 & $revnum;
        $schemenewt = $schemenewt >> 23;
        
        if ( $schemenewt ) {
            my $schemerev = 0b1111 & $revnum;
            my $schemetype = 0b111111110000 & $revnum;
            $schemetype = $schemetype >> 4;
            my $schemeproc = 0b1111000000000000 & $revnum;
            $schemeproc = $schemeproc >> 12;
            my $schememanu = 0b11110000000000000000 & $revnum;
            $schememanu = $schememanu >> 16;
            my $schemesize = 0b11100000000000000000000 & $revnum;
            $schemesize = $schemesize >> 20;
            
            # base type
            my $binfo = $_revstash{$defaultkey};
                        
            $binfo->{release}  = $_revinfostash{release}->{$schemetype} || 'Q1 2015';
            $binfo->{model_name} = $_revinfostash{type}->{$schemetype} || qq(Unknown Raspberry Pi Type : $schemetype);
            $binfo->{model_name} = $device_tree_boardname if $device_tree_boardname;
            $binfo->{memory}   = $_revinfostash{memsize}->{$schemesize} || 256;
            $binfo->{manufacturer} = $_revinfostash{manufacturer}->{$schememanu} || 'Sony';
            $binfo->{board_type} =  $_revinfostash{board_type}->{$schemetype} || $board_type;
            $binfo->{processor} = $_revinfostash{processor}->{$schemeproc} || 'BCM2835';
            $binfo->{revision} = $rev;
            $binfo->{revisionnumber} = $schemerev;
            
            $israspberry2 = ( $schemetype == 4 ) ? 1 : 0;
            $israspberry3 = ( $schemetype == 8 || $schemetype == 10 || $schemetype == 13 || $schemetype == 14 || $schemetype == 16 ) ? 1 : 0;
            $israspberry4 = ( $schemetype == 17 ) ? 1 : 0;
            
            $_config = { %$binfo };
        } else {
            my $infokey = exists($_revstash{$rev}) ? $rev : $defaultkey;
            $_config = { %{ $_revstash{$infokey} } };
            $_config->{processor} = 'BCM2835';
            $_config->{revisionnumber} = 0;
        }
        
    }    
   
    # Home Dir
    if( os_is_windows ) {
        require Win32;
        $homedir = Win32::GetFolderPath( 0x001C, 1);
        $homedir = Win32::GetShortPathName( $homedir );
        $homedir =~ s/\\/\//g;
    } else {
        $homedir = (getpwuid($<))[7];
    }
    
    $_config->{hardware} = $hardware;
    $_config->{serial}  = $serial; 
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return  $self;
}

sub validpins {
    my $type = board_type();
    if ( $type == 1 ) {
        return ( 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25 );
    } elsif ( $type == 2 ) {    
        return ( 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27, 28, 29, 30, 31 );
    } else {
        # return current latest known pinset
        return ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 );
    }
}

sub dump_board_info {
    my $dump = qq(--------------------------------------------------\n);
    $dump .= qq(Raspberry Pi Board Info\n);
    $dump .= qq(--------------------------------------------------\n);
    $dump .= qq(Model Name       : $_config->{model_name}\n);
    $dump .= qq(Released         : $_config->{release}\n);
    $dump .= qq(Manufacturer     : $_config->{manufacturer}\n);
    $dump .= qq(Memory           : $_config->{memory}\n);
    $dump .= qq(Processor        : $_config->{processor}\n);
    $dump .= qq(Hardware         : $_config->{hardware}\n);
    my $description = board_description();
    $dump .= qq(Description      : $description\n);
    $dump .= qq(Revision         : $_config->{revision}\n);
    $dump .= qq(Serial Number    : $_config->{serial}\n);
    $dump .= qq(GPIO Header Type : $_config->{board_type}\n);
    $dump .= qq(Revision Number  : $_config->{revisionnumber}\n);
    my $devtree = ( has_device_tree() ) ? 'Yes' : 'No';
    
    $dump .= qq(Device Tree      : $devtree\n);
    $dump .= q(Is Raspberry     : ) . (($israspberry) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 2   : ) . (($israspberry2) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 3   : ) . (($israspberry3) ? 'Yes' : 'No' ) . qq(\n);
    $dump .= q(Is Raspberry 4   : ) . (($israspberry4) ? 'Yes' : 'No' ) . qq(\n);
    
    return $dump;
}

_configure();

1;

__END__