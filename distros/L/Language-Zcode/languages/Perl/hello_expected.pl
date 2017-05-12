#!perl -w

use strict;
use Getopt::Std;

use Language::Zcode::Runtime::Opcodes; # Stuff used by the output Perl program (aka runtime)
use Language::Zcode::Runtime::State; # save/restore/restart, call stack
use Language::Zcode::Runtime::IO; # All IO stuff

# Set constants
use vars qw(%Constants);
%Constants = (
    abbrev_table_address => 66,
    attribute_bytes => 6,
    dictionary_address => 1251,
    encoded_word_length => 9,
    file_checksum => 18604,
    file_length => 1364,
    first_instruction_address => 1261,
    global_variable_address => 768,
    max_objects => 65535,
    max_properties => 63,
    object_bytes => 14,
    object_table_address => 266,
    packed_multiplier => 4,
    paged_memory_address => 1260,
    pointer_size => 2,
    release_number => 1,
    routines_offset => 0,
    serial_code => "040910",
    static_memory_address => 1249,
    strings_offset => 0,
    version => 5,
);


############### 
# Read user input
my %opts;
my $Usage = <<"ENDUSAGE";
    $0 [-r rows] [-c columns] [-t terminal] [-d]

    -r, -c say how big to make the screen
    -t specifies a "dumb" terminal or slightly smarter "win32" terminal
       (hopefully will be adding more terminals soon)
    -d debug. Write information about which sub we're in, set \$DEBUG, etc.
ENDUSAGE
getopts("dr:c:t:", \%opts) or die "$Usage\n";
my $DEBUG = defined $opts{d};

# Build and run the Z-machine
my $Z_Result = Language::Zcode::Runtime::Opcodes::Z_machine(%opts);

# If Z_Result was an error, do a (non-eval'ed) die to really die.
die $Z_Result if $Z_Result;

exit;
#############################################

sub rtn1260 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L1261: &global_var(239, z_call(1268, \@locv, \@stack, 1266, 255));
    L1266: die "Quit\n";
}

sub rtn1268 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L1269: # print "Hello, world!^"
        &write_text(&decode_text(1270));
    L1282: return 1;
}



{
package PlotzMemory;

use vars qw(@Memory);
my @Dynamic_Orig;

sub get_byte_at { $Memory[$_[0]] }
sub set_byte_at { $Memory[$_[0]] = $_[1] & 0xff; }
sub get_word_at { ($Memory[$_[0]] << 8) + $Memory[$_[0] + 1]; }
sub set_word_at {
    $Memory[$_[0]] = $_[1]>>8;
    $Memory[$_[0] + 1] = $_[1] & 0xff;
}

sub read_memory {
# (The map below removes address number and hexifies the other numbers)
    my $c = 0;
# Addr    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    @Memory = map {$c++ % 17 ? hex : ()} qw(
000000   05 00 00 01 04 ec 04 ed 04 e3 01 0a 03 00 04 e1
000010   00 00 30 34 30 39 31 30 00 42 01 55 48 ac 00 50
000020   00 00 00 00 00 00 00 00 00 00 00 00 00 00 04 e0
000030   00 00 00 00 00 00 01 02 00 00 00 00 36 2e 33 30
000040   80 00 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000050   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000060   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000070   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000080   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000090   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000a0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000b0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000c0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000d0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000e0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
0000f0   00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20
000100   00 20 00 03 00 00 00 00 00 00 00 00 00 00 00 00
000110   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000120   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000130   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000140   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000150   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000160   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000170   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000180   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000190   00 00 00 00 01 c0 00 00 00 00 00 00 00 00 00 00
0001a0   00 00 01 d0 00 00 00 00 00 00 00 00 00 00 00 00
0001b0   01 e2 00 00 00 00 00 00 00 00 00 00 00 00 01 f4
0001c0   02 11 11 9b 18 00 00 00 00 00 00 00 42 00 01 00
0001d0   03 12 87 3d 48 e4 a5 00 00 00 00 00 00 00 42 00
0001e0   02 00 03 12 f4 6b 2e cd 45 00 00 00 00 00 00 00
0001f0   42 00 03 00 03 13 19 5d d3 b0 a5 00 00 00 00 00
000200   00 00 42 00 04 00 00 01 00 02 00 03 00 04 00 00
000210   00 48 01 47 00 00 00 00 00 00 00 00 00 00 00 00
000220   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000230   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000240   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000250   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000260   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000270   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000280   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000290   01 48 01 49 01 4b 01 4d 01 4f 01 50 01 51 01 52
0002a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0002b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0002c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0002d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0002e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0002f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000300   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000310   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000320   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000330   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000340   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000350   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000360   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000370   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000380   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000390   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000400   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000410   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000420   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000430   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000440   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000450   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000460   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000470   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000480   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000490   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0004a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0004b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0004c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0004d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0004e0   00 00 00 03 2e 2c 22 09 00 00 00 00 00 e0 3f 01
0004f0   3d ff ba 00 00 b2 11 aa 46 34 16 60 72 97 45 25
000500   d0 a7 b0 00 02 b1 00 00 14 c1 73 53 42 74 72 60
000510   1b 39 5d c7 6b 2a 14 c1 f8 a5 00 00 4c d2 a8 a5
000520   22 ea 9b 2a 5d 48 5d 46 e5 45 00 00 25 58 66 f4
000530   f8 a5 00 00 5d 52 19 d3 ba 6c 00 00 22 95 f8 a5
000540   20 d1 c4 a5 56 ee cf 25 56 ee 4f 25 5b 34 16 c6
000550   5e e6 f8 a5 00 00 00 00 00 00 00 00 00 00 00 00
000560   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000570   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000580   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000590   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0005f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

);
    @Dynamic_Orig = @Memory[0 .. 1248];
}

sub checksum {
    #my $flen = $main::Constants{file_length};
    my $header_size = 0x40; # don't count header bytes.
    my $sum = 0;
    for (@Dynamic_Orig[$header_size .. 1248 -1], 
        @Memory[1248 .. 1536-1]) 
    {
	$sum += $_;
    }
    # 512K * 256 = 128M: definitely less than 2G max integer size for Perl.
    # so we don't need to do mod within the for loop
    $sum = $sum % 0x10000;
    return $sum;
}

sub get_dynamic_memory {
    [@Memory[0 .. 1248]];
}

sub get_orig_dynamic_memory {
    [@Dynamic_Orig];
}

my $restore_mem_ref;
sub store_dynamic_memory {
    $restore_mem_ref = shift;
}

# Reset memory EXCEPT the couple bits that get saved even during a restart.
sub reset_dynamic_memory {
    my $restoring = shift;
    Language::Zcode::Runtime::IO::store_restart_bits();
    @Memory[0 .. 1248] = 
	$restoring ? @$restore_mem_ref : @Dynamic_Orig;
}

} # End package PlotzMemory

