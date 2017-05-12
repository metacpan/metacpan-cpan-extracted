#!perl -w

use strict;
use Getopt::Std;

use Language::Zcode::Runtime::Opcodes; # Perl translation of complex opcodes
use Language::Zcode::Runtime::State; # save/restore game state
use Language::Zcode::Runtime::IO; # All IO stuff

# Set constants
use vars qw(%Constants);
%Constants = (
    abbrev_table_address => 500,
    attribute_bytes => 4,
    dictionary_address => 10330,
    encoded_word_length => 6,
    file_checksum => 55408,
    file_length => 52216,
    first_instruction_address => 14297,
    global_variable_address => 692,
    max_objects => 255,
    max_properties => 31,
    object_bytes => 9,
    object_table_address => 966,
    packed_multiplier => 2,
    paged_memory_address => 14089,
    pointer_size => 1,
    release_number => 34,
    routines_offset => 0,
    serial_code => "871124",
    static_memory_address => 8583,
    strings_offset => 0,
    version => 3,
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

sub rtn14192 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14195: goto L14207 if &global_var(23) == 0;
    L14198: $stack[@stack] = &z_random(100);
    L14202: return 1 if unpack('s', pack('s', $locv[0])) > unpack('s', pack('s', pop(@stack)));
    L14206: return 0;
    L14207: $stack[@stack] = &z_random(300);
    L14212: return 1 if unpack('s', pack('s', $locv[0])) > unpack('s', pack('s', pop(@stack)));
    L14216: return 0;
}

sub rtn14218 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14231: $locv[1] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14235: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14239: ($locv[1] = ($locv[1] - 1) & 0xffff);
    L14241: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L14245: $stack[@stack] = unpack('s', pack('s', $locv[2])) * 2;
    L14249: $locv[5] = unpack('s', pack('s', $locv[0])) + unpack('s', pack('s', pop(@stack)));
    L14253: $stack[@stack] = unpack('s', pack('s', $locv[1])) - unpack('s', pack('s', $locv[2]));
    L14257: $locv[3] = &z_random(unpack('s', pack('s', pop(@stack))));
    L14261: $locv[4] = 256*$PlotzMemory::Memory[$t1=($locv[5] + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14265: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[5] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14269: $PlotzMemory::Memory[$t1 = ($locv[5] + 2*$locv[3]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14274: $PlotzMemory::Memory[$t1 = ($locv[5] + 2*1) & 0xffff] =
        ($t2 = $locv[4])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14279: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L14281: goto L14288 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L14285: $locv[2] = 0;
    L14288: $PlotzMemory::Memory[$t1 = ($locv[0] + 2*0) & 0xffff] =
        ($t2 = $locv[2])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14293: return $locv[4];
}

sub rtn14296 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14297: $stack[@stack] = z_call(15158, \@locv, \@stack, 14306, 0, 16008, 65535);
    L14306: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14311: $stack[@stack] = z_call(15158, \@locv, \@stack, 14319, 0, 20048, 40);
    L14319: $stack[@stack] = z_call(15158, \@locv, \@stack, 14327, 0, 18322, 150);
    L14327: &global_var(0, 46);
    L14330: &global_var(122, 167);
    L14333: &global_var(38, 1);
    L14336: &global_var(115, 30);
    L14339: &insert_obj(&global_var(115), &global_var(0));
    L14342: $stack[@stack] = z_call(22626, \@locv, \@stack, 14347, 0);
    L14347: &newline();
    L14348: $stack[@stack] = z_call(25076, \@locv, \@stack, 14353, 0);
    L14353: $stack[@stack] = z_call(14362, \@locv, \@stack, 14358, 0);
    L14358: goto L14297;
}

sub rtn14362 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14365: $locv[0] = z_call(14374, \@locv, \@stack, 14370, 1);
    L14370: goto L14365;
}

sub rtn14374 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14399: $locv[3] = 0;
    L14402: $locv[4] = 0;
    L14405: $locv[7] = 1;
    L14408: &global_var(94, z_call(15332, \@locv, \@stack, 14413, 110));
    L14413: goto L14922 if &global_var(94) == 0;
    L14417: $locv[0] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14421: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14425: goto L14489 if &global_var(122) == 0;
    L14429: $stack[@stack] = z_call(31344, \@locv, \@stack, 14435, 0, &global_var(122));
    L14435: goto L14489 if pop(@stack) == 0;
    L14438: $locv[9] = 0;
    L14441: goto L14462 if unpack('s', pack('s', ($locv[3] = ($locv[3] + 1) & 0xffff))) > unpack('s', pack('s', $locv[0]));
    L14445: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14449: goto L14441 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L14454: $PlotzMemory::Memory[$t1 = (&global_var(30) + 2*$locv[3]) & 0xffff] =
        ($t2 = &global_var(122))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14459: $locv[9] = 1;
    L14462: goto L14486 unless $locv[9] == 0;
    L14465: $locv[3] = 0;
    L14468: goto L14486 if unpack('s', pack('s', ($locv[3] = ($locv[3] + 1) & 0xffff))) > unpack('s', pack('s', $locv[1]));
    L14472: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14476: goto L14468 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L14481: $PlotzMemory::Memory[$t1 = (&global_var(78) + 2*$locv[3]) & 0xffff] =
        ($t2 = &global_var(122))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L14486: $locv[3] = 0;
    L14489: goto L14498 unless $locv[1] == 0;
    L14492: $locv[2] = $locv[1];
    L14495: goto L14547;
    L14498: goto L14524 unless unpack('s', pack('s', $locv[1])) > 1;
    L14502: $locv[5] = &global_var(78);
    L14505: goto L14514 unless $locv[0] == 0;
    L14508: $locv[4] = 0;
    L14511: goto L14518;
    L14514: $locv[4] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14518: $locv[2] = $locv[1];
    L14521: goto L14547;
    L14524: goto L14544 unless unpack('s', pack('s', $locv[0])) > 1;
    L14528: $locv[7] = 0;
    L14531: $locv[5] = &global_var(30);
    L14534: $locv[4] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14538: $locv[2] = $locv[0];
    L14541: goto L14547;
    L14544: $locv[2] = 1;
    L14547: goto L14558 unless $locv[4] == 0;
    L14550: goto L14558 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L14554: $locv[4] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14558: goto L14575 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (102);
    L14562: goto L14575 if &global_var(27) == 0;
    L14565: $locv[6] = z_call(14964, \@locv, \@stack, 14572, 7, &global_var(75), &global_var(59));
    L14572: goto L14896;
    L14575: goto L14617 unless $locv[2] == 0;
    L14578: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 0) & 0xffff];
    L14582: $stack[@stack] = int(unpack('s', pack('s', pop(@stack))) / 64);
    L14586: goto L14601 unless pop(@stack) == 0;
    L14589: $locv[6] = z_call(14964, \@locv, \@stack, 14595, 7, &global_var(75));
    L14595: &global_var(59, 0);
    L14598: goto L14896;
    L14601: goto L14609 unless &global_var(38) == 0;
    L14604: &write_text(&decode_text(&global_var(57) * 2));
    L14606: goto L14896;
    L14609: &write_text(&decode_text(&global_var(34) * 2));
    L14611: $locv[6] = 0;
    L14614: goto L14896;
    L14617: &global_var(128, 0);
    L14620: &global_var(17, 0);
    L14623: goto L14630 unless unpack('s', pack('s', $locv[2])) > 1;
    L14627: &global_var(17, 1);
    L14630: $locv[9] = 0;
    L14633: goto L14723 unless unpack('s', pack('s', ($locv[3] = ($locv[3] + 1) & 0xffff))) > unpack('s', pack('s', $locv[2]));
    L14638: goto L14702 unless unpack('s', pack('s', &global_var(128))) > 0;
    L14643: # print "[abbrev 1]"
        &write_text(&decode_text(14644));
    L14646: goto L14655 if $t1 = &global_var(128), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[2]);
    L14650: # print "other "
        &write_text(&decode_text(14651));
    L14655: # print "object"
        &write_text(&decode_text(14656));
    L14660: goto L14667 if $t1 = &global_var(128), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L14664: &write_zchar(115);
    L14667: # print " [abbrev 17][abbrev 8]mentioned "
        &write_text(&decode_text(14668));
    L14678: goto L14688 if $t1 = &global_var(128), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L14682: # print "are"
        &write_text(&decode_text(14683));
    L14685: goto L14691;
    L14688: # print "is"
        &write_text(&decode_text(14689));
    L14691: # print "n't [abbrev 21]."
        &write_text(&decode_text(14692));
    L14698: &newline();
    L14699: goto L14896;
    L14702: goto L14896 unless $locv[9] == 0;
    L14706: &write_text(&decode_text(&global_var(83) * 2));
    L14708: # print "[abbrev 21] [abbrev 8][abbrev 68]take."
        &write_text(&decode_text(14709));
    L14719: &newline();
    L14720: goto L14896;
    L14723: goto L14733 if $locv[7] == 0;
    L14726: $locv[8] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14730: goto L14737;
    L14733: $locv[8] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14737: goto L14746 if $locv[7] == 0;
    L14740: $locv[10] = $locv[8];
    L14743: goto L14749;
    L14746: $locv[10] = $locv[4];
    L14749: goto L14758 if $locv[7] == 0;
    L14752: $locv[11] = $locv[4];
    L14755: goto L14761;
    L14758: $locv[11] = $locv[8];
    L14761: goto L14780 if unpack('s', pack('s', $locv[2])) > 1;
    L14765: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14769: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(pop(@stack) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14773: goto L14874 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449);
    L14780: $locv[6] = get_parent(&global_var(115));
    L14783: goto L14792 unless $t1 = $locv[10], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (130);
    L14787: &global_var(128, "++");
    L14789: goto L14633;
    L14792: goto L14818 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L14796: goto L14818 if $locv[11] == 0;
    L14799: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14803: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(pop(@stack) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L14807: goto L14818 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449);
    L14813: goto L14633 unless $locv[11] == &get_object(&thing_location($locv[10], 'parent'));
    L14818: goto L14860 unless $t1 = &global_var(104), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L14822: goto L14860 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L14826: $stack[@stack] = get_parent($locv[10]);
    L14829: goto L14851 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115), &global_var(0), $locv[6]);
    L14836: $stack[@stack] = get_parent($locv[10]);
    L14839: goto L14851 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[11]);
    L14843: $stack[@stack] = get_parent($locv[10]);
    L14846: goto L14633 unless &test_attr(pop(@stack), 12);
    L14851: goto L14860 if &test_attr($locv[10], 17);
    L14855: goto L14633 unless &test_attr($locv[10], 11);
    L14860: goto L14869 unless $t1 = $locv[8], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L14864: &write_text(&decode_text(&thing_location(&global_var(122), 'name')));
    L14866: goto L14871;
    L14869: &write_text(&decode_text(&thing_location($locv[8], 'name')));
    L14871: # print ": "
        &write_text(&decode_text(14872));
    L14874: &global_var(59, $locv[10]);
    L14877: &global_var(126, $locv[11]);
    L14880: $locv[9] = 1;
    L14883: $locv[6] = z_call(14964, \@locv, \@stack, 14891, 7, &global_var(75), &global_var(59), &global_var(126));
    L14891: goto L14633 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L14896: goto L14912 if $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L14900: $stack[@stack] = get_parent(&global_var(115));
    L14903: $stack[@stack] = &get_prop(pop(@stack), 18);
    L14907: $locv[6] = z_call(pop(@stack) * 2, \@locv, \@stack, 14912, 7, 6);
    L14912: goto L14925 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L14916: &global_var(29, 0);
    L14919: goto L14925;
    L14922: &global_var(29, 0);
    L14925: return 0 if &global_var(94) == 0;
    L14928: return 1 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2, 1, 84);
    L14935: return 1 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12, 8, 0);
    L14942: return 1 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (9, 6, 5);
    L14949: return 1 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (7, 11, 10);
    L14956: $locv[6] = z_call(15240, \@locv, \@stack, 14961, 7);
    L14961: return $locv[6];
}

sub rtn14964 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L14979: $locv[4] = &global_var(75);
    L14982: $locv[5] = &global_var(59);
    L14985: $locv[6] = &global_var(126);
    L14988: goto L15007 unless $t1 = 48, grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[2], $locv[1]);
    L14994: $stack[@stack] = z_call(31344, \@locv, \@stack, 15000, 0, &global_var(122));
    L15000: goto L15007 unless pop(@stack) == 0;
    L15003: &write_text(&decode_text(&global_var(34) * 2));
    L15005: return 2;
    L15007: goto L15014 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L15011: $locv[1] = &global_var(122);
    L15014: goto L15021 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L15018: $locv[2] = &global_var(122);
    L15021: &global_var(75, $locv[0]);
    L15024: &global_var(59, $locv[1]);
    L15027: goto L15041 if &global_var(59) == 0;
    L15030: goto L15041 if $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L15034: goto L15041 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (102);
    L15038: &global_var(122, &global_var(59));
    L15041: &global_var(126, $locv[2]);
    L15044: goto L15059 unless $t1 = 130, grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(59), &global_var(126));
    L15050: $locv[3] = z_call(30164, \@locv, \@stack, 15055, 4);
    L15055: goto L15147 unless $locv[3] == 0;
    L15059: $locv[1] = &global_var(59);
    L15062: $locv[2] = &global_var(126);
    L15065: $stack[@stack] = &get_prop(&global_var(115), 18);
    L15069: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15073, 4);
    L15073: goto L15147 unless $locv[3] == 0;
    L15077: $stack[@stack] = get_parent(&global_var(115));
    L15080: $stack[@stack] = &get_prop(pop(@stack), 18);
    L15084: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15089, 4, 1);
    L15089: goto L15147 unless $locv[3] == 0;
    L15093: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(135) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15097: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15101, 4);
    L15101: goto L15147 unless $locv[3] == 0;
    L15104: goto L15118 if $locv[2] == 0;
    L15107: $stack[@stack] = &get_prop($locv[2], 18);
    L15111: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15115, 4);
    L15115: goto L15147 unless $locv[3] == 0;
    L15118: goto L15136 if $locv[1] == 0;
    L15121: goto L15136 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (102);
    L15125: $stack[@stack] = &get_prop($locv[1], 18);
    L15129: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15133, 4);
    L15133: goto L15147 unless $locv[3] == 0;
    L15136: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(134) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15140: $locv[3] = z_call(pop(@stack) * 2, \@locv, \@stack, 15144, 4);
    L15144: goto L15147 if $locv[3] == 0;
    L15147: &global_var(75, $locv[4]);
    L15150: &global_var(59, $locv[5]);
    L15153: &global_var(126, $locv[6]);
    L15156: return $locv[3];
}

sub rtn15158 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L15165: $locv[2] = z_call(15178, \@locv, \@stack, 15171, 3, $locv[0]);
    L15171: $PlotzMemory::Memory[$t1 = ($locv[2] + 2*1) & 0xffff] =
        ($t2 = $locv[1])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15176: return $locv[2];
}

sub rtn15178 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L15189: $locv[2] = unpack('s', pack('s', &global_var(22))) + 180;
    L15193: $locv[3] = unpack('s', pack('s', &global_var(22))) + unpack('s', pack('s', &global_var(53)));
    L15197: goto L15223 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[2]);
    L15201: &global_var(53, unpack('s', pack('s', &global_var(53))) - 6);
    L15205: goto L15212 if $locv[1] == 0;
    L15208: &global_var(63, unpack('s', pack('s', &global_var(63))) - 6);
    L15212: $locv[4] = unpack('s', pack('s', &global_var(22))) + unpack('s', pack('s', &global_var(53)));
    L15216: $PlotzMemory::Memory[$t1 = ($locv[4] + 2*2) & 0xffff] =
        ($t2 = $locv[0])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15221: return $locv[4];
    L15223: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[3] + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15227: goto L15233 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L15231: return $locv[3];
    L15233: $locv[3] = unpack('s', pack('s', $locv[3])) + 6;
    L15237: goto L15197;
}

sub rtn15240 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L15249: goto L15256 if &global_var(18) == 0;
    L15252: &global_var(18, 0);
    L15255: return 0;
    L15256: goto L15265 if &global_var(94) == 0;
    L15259: push @stack, &global_var(53);
    L15262: goto L15268;
    L15265: push @stack, &global_var(63);
    L15268: $locv[0] = unpack('s', pack('s', &global_var(22))) + unpack('s', pack('s', pop(@stack)));
    L15272: $locv[1] = unpack('s', pack('s', &global_var(22))) + 180;
    L15276: goto L15284 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L15280: &global_var(2, "++");
    L15282: return $locv[3];
    L15284: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15288: goto L15325 if pop(@stack) == 0;
    L15291: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15295: goto L15325 if $locv[2] == 0;
    L15298: $stack[@stack] = unpack('s', pack('s', $locv[2])) - 1;
    L15302: $PlotzMemory::Memory[$t1 = ($locv[0] + 2*1) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15307: goto L15325 if unpack('s', pack('s', $locv[2])) > 1;
    L15311: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15315: $stack[@stack] = z_call(pop(@stack) * 2, \@locv, \@stack, 15319, 0);
    L15319: goto L15325 if pop(@stack) == 0;
    L15322: $locv[3] = 1;
    L15325: $locv[0] = unpack('s', pack('s', $locv[0])) + 6;
    L15329: goto L15276;
}

sub rtn15332 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65535, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L15361: goto L15385 if unpack('s', pack('s', ($locv[11] = ($locv[11] + 1) & 0xffff))) > 9;
    L15365: goto L15377 unless &global_var(114) == 0;
    L15368: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*$locv[11]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15372: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*$locv[11]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15377: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[11]) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15382: goto L15361;
    L15385: $locv[5] = &global_var(115);
    L15388: $locv[6] = &global_var(61);
    L15391: &global_var(15, 0);
    L15394: &global_var(61, 0);
    L15397: &global_var(3, 0);
    L15400: $PlotzMemory::Memory[$t1 = (&global_var(78) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15405: $PlotzMemory::Memory[$t1 = (&global_var(30) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15410: $PlotzMemory::Memory[$t1 = (&global_var(4) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15415: goto L15437 unless &global_var(102) == 0;
    L15418: goto L15437 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L15422: &global_var(115, 30);
    L15425: &global_var(0, z_call(31418, \@locv, \@stack, 15431, 16, 30));
    L15431: &global_var(38, z_call(21626, \@locv, \@stack, 15437, 54, &global_var(0)));
    L15437: goto L15468 if &global_var(127) == 0;
    L15440: $locv[0] = &global_var(127);
    L15443: $stack[@stack] = z_call(16838, \@locv, \@stack, 15450, 0, &global_var(43), &global_var(55));
    L15450: goto L15459 unless unpack('s', pack('s', &global_var(32))) > 0;
    L15454: goto L15459 unless $t1 = 30, grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L15458: &newline();
    L15459: &global_var(127, 0);
    L15462: &global_var(29, 0);
    L15465: goto L15524;
    L15468: goto L15493 if &global_var(29) == 0;
    L15471: $locv[0] = &global_var(29);
    L15474: goto L15487 unless unpack('s', pack('s', &global_var(32))) > 0;
    L15478: goto L15487 unless $t1 = 30, grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L15482: goto L15487 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (85);
    L15486: &newline();
    L15487: &global_var(29, 0);
    L15490: goto L15524;
    L15493: &global_var(115, 30);
    L15496: &global_var(102, 0);
    L15499: goto L15506 if 143 == &get_object(&thing_location(30, 'parent'));
    L15503: &global_var(0, get_parent(&global_var(115)));
    L15506: &global_var(38, z_call(21626, \@locv, \@stack, 15512, 54, &global_var(0)));
    L15512: goto L15517 unless unpack('s', pack('s', &global_var(32))) > 0;
    L15516: &newline();
    L15517: &write_zchar(62);
    L15520: &z_read(&global_var(87), &global_var(55), undef);
    L15524: &global_var(48, $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff]);
    L15528: goto L15534 unless &global_var(48) == 0;
    L15531: &write_text(&decode_text(&global_var(86) * 2));
    L15533: return 0;
    L15534: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15538: goto L15820 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12563);
    L15545: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L15549: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15553: goto L15567 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10344, 10351);
    L15561: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L15565: &global_var(48, "--");
    L15567: goto L15596 if unpack('s', pack('s', &global_var(48))) > 1;
    L15571: # print "[I [abbrev 29]help [abbrev 4]clumsiness.]"
        &write_text(&decode_text(15572));
    L15594: &newline();
    L15595: return 0;
    L15596: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15600: goto L15790 if pop(@stack) == 0;
    L15604: goto L15655 unless unpack('s', pack('s', &global_var(48))) > 2;
    L15608: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L15612: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15616: goto L15655 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10386);
    L15622: # print "[[abbrev 2][abbrev 29]correct mistakes [abbrev 22]quoted text.]"
        &write_text(&decode_text(15623));
    L15653: &newline();
    L15654: return 0;
    L15655: goto L15701 unless unpack('s', pack('s', &global_var(48))) > 2;
    L15659: # print "[Warning: only [abbrev 0]first word after OOPS [abbrev 5]used.]"
        &write_text(&decode_text(15660));
    L15700: &newline();
    L15701: $locv[13] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15705: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L15709: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15713: $PlotzMemory::Memory[$t1 = (&global_var(31) + 2*$locv[13]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15718: &global_var(115, $locv[5]);
    L15721: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L15725: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 6;
    L15729: $locv[12] = $PlotzMemory::Memory[(&global_var(55) + pop(@stack)) & 0xffff];
    L15733: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L15737: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 7;
    L15741: $locv[13] = $PlotzMemory::Memory[(&global_var(55) + pop(@stack)) & 0xffff];
    L15745: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15749: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 2;
    L15753: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 3;
    L15757: $stack[@stack] = z_call(16952, \@locv, \@stack, 15765, 0, $locv[12], $locv[13], pop(@stack));
    L15765: $stack[@stack] = z_call(16838, \@locv, \@stack, 15772, 0, &global_var(31), &global_var(55));
    L15772: &global_var(48, $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff]);
    L15776: $locv[0] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15780: $stack[@stack] = z_call(16922, \@locv, \@stack, 15787, 0, &global_var(110), &global_var(87));
    L15787: goto L15836;
    L15790: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*3) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15795: # print "[[abbrev 7]was no word [abbrev 12]replace!]"
        &write_text(&decode_text(15796));
    L15818: &newline();
    L15819: return 0;
    L15820: goto L15831 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10428, 11597);
    L15828: &global_var(112, 0);
    L15831: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*3) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L15836: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15840: goto L16089 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10428, 11597);
    L15849: $stack[@stack] = $PlotzMemory::Memory[(&global_var(110) + 1) & 0xffff];
    L15853: goto L15859 unless pop(@stack) == 0;
    L15856: &write_text(&decode_text(&global_var(86) * 2));
    L15858: return 0;
    L15859: goto L15893 if &global_var(114) == 0;
    L15862: # print "[[abbrev 23]difficult [abbrev 12]repeat fragments.]"
        &write_text(&decode_text(15863));
    L15891: &newline();
    L15892: return 0;
    L15893: goto L15923 unless &global_var(94) == 0;
    L15896: # print "[[abbrev 70][abbrev 81]just repeat a mistake.]"
        &write_text(&decode_text(15897));
    L15921: &newline();
    L15922: return 0;
    L15923: goto L16003 unless unpack('s', pack('s', &global_var(48))) > 1;
    L15928: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L15932: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15936: goto L15960 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10344, 10351, 13578);
    L15946: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L15950: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L15954: goto L15980 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477);
    L15960: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L15964: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff];
    L15968: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 2;
    L15972: $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff] = pop(@stack) & 0xff;
    L15977: goto L16020;
    L15980: # print "[I [abbrev 57]underst[abbrev 6][abbrev 17][abbrev 83].]"
        &write_text(&decode_text(15981));
    L16001: &newline();
    L16002: return 0;
    L16003: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L16007: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff];
    L16011: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 1;
    L16015: $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff] = pop(@stack) & 0xff;
    L16020: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff];
    L16024: goto L16041 unless unpack('s', pack('s', pop(@stack))) > 0;
    L16028: $stack[@stack] = z_call(16838, \@locv, \@stack, 16035, 0, &global_var(55), &global_var(43));
    L16035: &global_var(127, $locv[0]);
    L16038: goto L16044;
    L16041: &global_var(127, 0);
    L16044: &global_var(115, $locv[5]);
    L16047: &global_var(61, $locv[6]);
    L16050: $stack[@stack] = z_call(16922, \@locv, \@stack, 16057, 0, &global_var(110), &global_var(87));
    L16057: $stack[@stack] = z_call(16838, \@locv, \@stack, 16064, 0, &global_var(31), &global_var(55));
    L16064: $locv[11] = 65535;
    L16069: $locv[8] = &global_var(118);
    L16072: goto L16649 if unpack('s', pack('s', ($locv[11] = ($locv[11] + 1) & 0xffff))) > 9;
    L16077: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*$locv[11]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16081: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[11]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16086: goto L16072;
    L16089: $stack[@stack] = z_call(16838, \@locv, \@stack, 16096, 0, &global_var(55), &global_var(31));
    L16096: $stack[@stack] = z_call(16922, \@locv, \@stack, 16103, 0, &global_var(87), &global_var(110));
    L16103: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*1) & 0xffff] =
        ($t2 = $locv[0])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16108: $stack[@stack] = 4 * unpack('s', pack('s', &global_var(48)));
    L16112: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*2) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16117: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff];
    L16121: $stack[@stack] = 2 * unpack('s', pack('s', pop(@stack)));
    L16125: $stack[@stack] = unpack('s', pack('s', $locv[0])) + unpack('s', pack('s', pop(@stack)));
    L16129: $locv[7] = 2 * unpack('s', pack('s', pop(@stack)));
    L16133: $stack[@stack] = unpack('s', pack('s', $locv[7])) - 1;
    L16137: $locv[13] = $PlotzMemory::Memory[(&global_var(55) + pop(@stack)) & 0xffff];
    L16141: $stack[@stack] = unpack('s', pack('s', $locv[7])) - 2;
    L16145: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + pop(@stack)) & 0xffff];
    L16149: $stack[@stack] = unpack('s', pack('s', $locv[13])) + unpack('s', pack('s', pop(@stack)));
    L16153: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*3) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16158: &global_var(127, 0);
    L16161: $locv[7] = &global_var(48);
    L16164: &global_var(9, 0);
    L16167: &global_var(132, 0);
    L16170: &global_var(104, 0);
    L16173: goto L16183 unless unpack('s', pack('s', &global_var(48, "--"))) < 0;
    L16177: &global_var(102, 0);
    L16180: goto L16649;
    L16183: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16187: goto L16200 unless $locv[1] == 0;
    L16190: $locv[1] = z_call(17560, \@locv, \@stack, 16196, 2, $locv[0]);
    L16196: goto L16784 if $locv[1] == 0;
    L16200: goto L16209 unless &global_var(48) == 0;
    L16203: $locv[9] = 0;
    L16206: goto L16217;
    L16209: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L16213: $locv[9] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16217: goto L16235 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13634);
    L16223: goto L16235 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (218);
    L16227: $locv[1] = 10386;
    L16232: goto L16281;
    L16235: goto L16281 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13578);
    L16241: goto L16281 unless unpack('s', pack('s', &global_var(48))) > 0;
    L16245: goto L16281 unless $locv[3] == 0;
    L16248: goto L16281 unless &global_var(102) == 0;
    L16251: goto L16266 unless $t1 = $locv[10], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (0, 10344);
    L16258: $locv[1] = 13564;
    L16263: goto L16281;
    L16266: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*0) & 0xffff] =
        ($t2 = 218)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16271: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*1) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16276: $locv[1] = 10386;
    L16281: goto L16324 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13578, 10344, 10386);
    L16291: goto L16309 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10386);
    L16297: goto L16306 if &global_var(102) == 0;
    L16300: &global_var(102, 0);
    L16303: goto L16309;
    L16306: &global_var(102, 1);
    L16309: goto L16316 if &global_var(48) == 0;
    L16312: &global_var(29, unpack('s', pack('s', $locv[0])) + 2);
    L16316: $PlotzMemory::Memory[(&global_var(55) + 1) & 0xffff] = &global_var(48) & 0xff;
    L16321: goto L16649;
    L16324: $locv[2] = z_call(17048, \@locv, \@stack, 16332, 3, $locv[1], 16, 3);
    L16332: goto L16426 if $locv[2] == 0;
    L16336: goto L16426 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (0, 249);
    L16343: goto L16394 if $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L16347: goto L16355 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L16351: goto L16394 if $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (249);
    L16355: goto L16369 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13578, 10344, 10386);
    L16365: goto L16394 unless unpack('s', pack('s', $locv[7])) < 2;
    L16369: goto L16382 if &global_var(102) == 0;
    L16372: goto L16382 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L16376: goto L16394 if $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10386);
    L16382: goto L16426 unless unpack('s', pack('s', $locv[7])) > 2;
    L16386: goto L16426 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10351, 10477);
    L16394: $locv[8] = $locv[2];
    L16397: goto L16415 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10351, 10477);
    L16405: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L16409: $PlotzMemory::Memory[$t1 = (&global_var(55) + 2*pop(@stack)) & 0xffff] =
        ($t2 = 13578)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16415: goto L16702 if unpack('s', pack('s', $locv[7])) > 2;
    L16420: &global_var(102, 0);
    L16423: goto L16649;
    L16426: $locv[2] = z_call(17048, \@locv, \@stack, 16434, 3, $locv[1], 64, 1);
    L16434: goto L16491 if $locv[2] == 0;
    L16437: goto L16491 unless $locv[3] == 0;
    L16440: $locv[3] = $locv[2];
    L16443: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*0) & 0xffff] =
        ($t2 = $locv[2])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16448: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*1) & 0xffff] =
        ($t2 = &global_var(41))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16453: $PlotzMemory::Memory[$t1 = (&global_var(41) + 2*0) & 0xffff] =
        ($t2 = $locv[1])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16458: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L16462: $locv[11] = unpack('s', pack('s', pop(@stack))) + 2;
    L16466: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + $locv[11]) & 0xffff];
    L16470: $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff] = pop(@stack) & 0xff;
    L16475: $stack[@stack] = unpack('s', pack('s', $locv[11])) + 1;
    L16479: $stack[@stack] = $PlotzMemory::Memory[(&global_var(55) + pop(@stack)) & 0xffff];
    L16483: $PlotzMemory::Memory[(&global_var(41) + 3) & 0xffff] = pop(@stack) & 0xff;
    L16488: goto L16702;
    L16491: $locv[2] = z_call(17048, \@locv, \@stack, 16499, 3, $locv[1], 8, 0);
    L16499: goto L16531 unless $locv[2] == 0;
    L16502: goto L16531 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449, 12549);
    L16510: $stack[@stack] = z_call(17048, \@locv, \@stack, 16517, 0, $locv[1], 32);
    L16517: goto L16531 unless pop(@stack) == 0;
    L16520: $stack[@stack] = z_call(17048, \@locv, \@stack, 16527, 0, $locv[1], 128);
    L16527: goto L16675 if pop(@stack) == 0;
    L16531: goto L16560 unless unpack('s', pack('s', &global_var(48))) > 1;
    L16535: goto L16560 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L16541: goto L16560 unless $locv[2] == 0;
    L16544: goto L16560 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449, 12549, 10393);
    L16554: $locv[4] = 1;
    L16557: goto L16702;
    L16560: goto L16595 if $locv[2] == 0;
    L16563: goto L16574 if &global_var(48) == 0;
    L16566: goto L16595 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13578, 10344);
    L16574: &global_var(3, 1);
    L16577: goto L16702 unless unpack('s', pack('s', &global_var(132))) < 2;
    L16582: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*2) & 0xffff] =
        ($t2 = $locv[2])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16587: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*3) & 0xffff] =
        ($t2 = $locv[1])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16592: goto L16702;
    L16595: goto L16626 unless $t1 = &global_var(132), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L16599: # print "[[abbrev 7]were [abbrev 74]many nouns [abbrev 22][abbrev 17][abbrev 83].]"
        &write_text(&decode_text(16600));
    L16624: &newline();
    L16625: return 0;
    L16626: &global_var(132, "++");
    L16628: &global_var(46, $locv[3]);
    L16631: $locv[0] = z_call(17086, \@locv, \@stack, 16639, 1, $locv[0], $locv[2], $locv[1]);
    L16639: return 0 if $locv[0] == 0;
    L16642: goto L16702 unless unpack('s', pack('s', $locv[0])) < 0;
    L16646: &global_var(102, 0);
    L16649: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16654: goto L16791 if $locv[8] == 0;
    L16658: &global_var(75, 102);
    L16661: &global_var(59, $locv[8]);
    L16664: &global_var(114, 0);
    L16667: &global_var(27, $locv[8]);
    L16670: &global_var(118, $locv[8]);
    L16673: return &global_var(118);
    L16675: goto L16712 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L16681: goto L16692 if $locv[4] == 0;
    L16684: goto L16699 unless $t1 = $locv[9], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10344, 13578);
    L16692: $stack[@stack] = z_call(18398, \@locv, \@stack, 16698, 0, $locv[0]);
    L16698: return 0;
    L16699: $locv[4] = 0;
    L16702: $locv[10] = $locv[1];
    L16705: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L16709: goto L16173;
    L16712: $stack[@stack] = z_call(17048, \@locv, \@stack, 16719, 0, $locv[1], 4);
    L16719: goto L16702 unless pop(@stack) == 0;
    L16723: goto L16777 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (218);
    L16727: $stack[@stack] = z_call(17048, \@locv, \@stack, 16735, 0, $locv[1], 64, 1);
    L16735: goto L16777 if pop(@stack) == 0;
    L16738: goto L16777 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L16742: # print "[Read [abbrev 0]manual [abbrev 54]talking [abbrev 12]characters.]"
        &write_text(&decode_text(16743));
    L16775: &newline();
    L16776: return 0;
    L16777: $stack[@stack] = z_call(18398, \@locv, \@stack, 16783, 0, $locv[0]);
    L16783: return 0;
    L16784: $stack[@stack] = z_call(18320, \@locv, \@stack, 16790, 0, $locv[0]);
    L16790: return 0;
    L16791: goto L16799 if &global_var(114) == 0;
    L16794: $stack[@stack] = z_call(17696, \@locv, \@stack, 16799, 0);
    L16799: &global_var(27, 0);
    L16802: &global_var(118, 0);
    L16805: $stack[@stack] = z_call(18522, \@locv, \@stack, 16810, 0);
    L16810: return 0 if pop(@stack) == 0;
    L16813: $stack[@stack] = z_call(19754, \@locv, \@stack, 16818, 0);
    L16818: return 0 if pop(@stack) == 0;
    L16821: $stack[@stack] = z_call(21408, \@locv, \@stack, 16826, 0);
    L16826: return 0 if pop(@stack) == 0;
    L16829: $stack[@stack] = z_call(21180, \@locv, \@stack, 16834, 0);
    L16834: return 1 unless pop(@stack) == 0;
    L16837: return 0;
}

sub rtn16838 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 29, 1, 1, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L16851: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L16855: $PlotzMemory::Memory[($locv[1] + 0) & 0xffff] = pop(@stack) & 0xff;
    L16860: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 1) & 0xffff];
    L16864: $PlotzMemory::Memory[($locv[1] + 1) & 0xffff] = pop(@stack) & 0xff;
    L16869: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16873: $PlotzMemory::Memory[$t1 = ($locv[1] + 2*$locv[3]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L16878: $stack[@stack] = unpack('s', pack('s', $locv[3])) * 2;
    L16882: $locv[5] = unpack('s', pack('s', pop(@stack))) + 2;
    L16886: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + $locv[5]) & 0xffff];
    L16890: $PlotzMemory::Memory[($locv[1] + $locv[5]) & 0xffff] = pop(@stack) & 0xff;
    L16895: $stack[@stack] = unpack('s', pack('s', $locv[3])) * 2;
    L16899: $locv[5] = unpack('s', pack('s', pop(@stack))) + 3;
    L16903: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + $locv[5]) & 0xffff];
    L16907: $PlotzMemory::Memory[($locv[1] + $locv[5]) & 0xffff] = pop(@stack) & 0xff;
    L16912: $locv[3] = unpack('s', pack('s', $locv[3])) + 2;
    L16916: goto L16869 unless unpack('s', pack('s', ($locv[4] = ($locv[4] + 1) & 0xffff))) > unpack('s', pack('s', $locv[2]));
    L16921: return 1;
}

sub rtn16922 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L16929: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L16933: $locv[2] = unpack('s', pack('s', pop(@stack))) - 1;
    L16937: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + $locv[2]) & 0xffff];
    L16941: $PlotzMemory::Memory[($locv[1] + $locv[2]) & 0xffff] = pop(@stack) & 0xff;
    L16946: goto L16937 unless unpack('s', pack('s', ($locv[2] = ($locv[2] - 1) & 0xffff))) < 0;
    L16951: return 1;
}

sub rtn16952 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L16967: $locv[5] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*3) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16971: goto L16980 if $locv[5] == 0;
    L16974: $locv[3] = $locv[5];
    L16977: goto L17000;
    L16980: $locv[5] = 256*$PlotzMemory::Memory[$t1=(&global_var(26) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L16984: $locv[6] = $PlotzMemory::Memory[(&global_var(31) + $locv[5]) & 0xffff];
    L16988: $stack[@stack] = unpack('s', pack('s', $locv[5])) + 1;
    L16992: $stack[@stack] = $PlotzMemory::Memory[(&global_var(31) + pop(@stack)) & 0xffff];
    L16996: $locv[3] = unpack('s', pack('s', $locv[6])) + unpack('s', pack('s', pop(@stack)));
    L17000: $stack[@stack] = unpack('s', pack('s', $locv[3])) + unpack('s', pack('s', $locv[0]));
    L17004: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*3) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17009: $locv[6] = unpack('s', pack('s', $locv[3])) + unpack('s', pack('s', $locv[4]));
    L17013: $stack[@stack] = unpack('s', pack('s', $locv[1])) + unpack('s', pack('s', $locv[4]));
    L17017: $stack[@stack] = $PlotzMemory::Memory[(&global_var(87) + pop(@stack)) & 0xffff];
    L17021: $PlotzMemory::Memory[(&global_var(110) + $locv[6]) & 0xffff] = pop(@stack) & 0xff;
    L17026: ($locv[4] = ($locv[4] + 1) & 0xffff);
    L17028: goto L17009 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L17033: $PlotzMemory::Memory[(&global_var(31) + $locv[2]) & 0xffff] = $locv[3] & 0xff;
    L17038: $stack[@stack] = unpack('s', pack('s', $locv[2])) - 1;
    L17042: $PlotzMemory::Memory[(&global_var(31) + pop(@stack)) & 0xffff] = $locv[0] & 0xff;
    L17047: return 1;
}

sub rtn17048 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 5, 5, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L17059: $locv[4] = $PlotzMemory::Memory[($locv[0] + 4) & 0xffff];
    L17063: return 0 unless ($locv[4] & ($t1 = $locv[1])) == $t1;
    L17067: return 1 if unpack('s', pack('s', $locv[2])) > 4;
    L17071: $locv[4] = $locv[4] & 3;
    L17075: goto L17081 if $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[2]);
    L17079: ($locv[3] = ($locv[3] + 1) & 0xffff);
    L17081: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + $locv[3]) & 0xffff];
    L17085: return (pop @stack);
}

sub rtn17086 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 1, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L17107: $stack[@stack] = unpack('s', pack('s', &global_var(132))) - 1;
    L17111: $locv[3] = unpack('s', pack('s', pop(@stack))) * 2;
    L17115: goto L17143 if $locv[1] == 0;
    L17118: $locv[4] = 2 + unpack('s', pack('s', $locv[3]));
    L17122: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[4]) & 0xffff] =
        ($t2 = $locv[1])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17127: $stack[@stack] = unpack('s', pack('s', $locv[4])) + 1;
    L17131: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*pop(@stack)) & 0xffff] =
        ($t2 = $locv[2])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17136: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L17140: goto L17145;
    L17143: &global_var(48, "++");
    L17145: goto L17153 unless &global_var(48) == 0;
    L17148: &global_var(132, "--");
    L17150: return 65535;
    L17153: $locv[4] = 6 + unpack('s', pack('s', $locv[3]));
    L17157: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L17161: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17165: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[4]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17170: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17174: goto L17197 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13564, 10393, 10463);
    L17184: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*$locv[4]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17188: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 4;
    L17192: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[4]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17197: goto L17221 unless unpack('s', pack('s', &global_var(48, "--"))) < 0;
    L17201: $locv[9] = unpack('s', pack('s', $locv[4])) + 1;
    L17205: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L17209: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17213: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[9]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17218: return 65535;
    L17221: $locv[2] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17225: goto L17238 unless $locv[2] == 0;
    L17228: $locv[2] = z_call(17560, \@locv, \@stack, 17234, 3, $locv[0]);
    L17234: goto L17553 if $locv[2] == 0;
    L17238: goto L17247 unless &global_var(48) == 0;
    L17241: $locv[7] = 0;
    L17244: goto L17255;
    L17247: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L17251: $locv[7] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17255: goto L17269 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477, 10351);
    L17263: $locv[5] = 1;
    L17266: goto L17522;
    L17269: goto L17293 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449, 12549);
    L17277: goto L17522 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L17284: &global_var(48, "--");
    L17286: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L17290: goto L17522;
    L17293: goto L17321 if $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13578, 10344);
    L17301: $stack[@stack] = z_call(17048, \@locv, \@stack, 17308, 0, $locv[2], 8);
    L17308: goto L17345 if pop(@stack) == 0;
    L17311: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17315: goto L17345 if pop(@stack) == 0;
    L17318: goto L17345 unless $locv[6] == 0;
    L17321: &global_var(48, "++");
    L17323: $locv[9] = unpack('s', pack('s', $locv[4])) + 1;
    L17327: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L17331: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17335: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[9]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17340: $stack[@stack] = unpack('s', pack('s', $locv[0])) - 2;
    L17344: return (pop @stack);
    L17345: $stack[@stack] = z_call(17048, \@locv, \@stack, 17352, 0, $locv[2], 128);
    L17352: goto L17448 if pop(@stack) == 0;
    L17356: goto L17375 unless unpack('s', pack('s', &global_var(48))) > 0;
    L17360: goto L17375 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L17366: goto L17522 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449, 12549);
    L17375: $stack[@stack] = z_call(17048, \@locv, \@stack, 17383, 0, $locv[2], 32, 2);
    L17383: goto L17400 if pop(@stack) == 0;
    L17386: goto L17400 if $locv[7] == 0;
    L17389: $stack[@stack] = z_call(17048, \@locv, \@stack, 17396, 0, $locv[7], 128);
    L17396: goto L17522 unless pop(@stack) == 0;
    L17400: goto L17442 unless $locv[5] == 0;
    L17403: goto L17442 if $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10890, 11394);
    L17411: goto L17442 if $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477, 10351);
    L17419: $locv[9] = unpack('s', pack('s', $locv[4])) + 1;
    L17423: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L17427: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 2;
    L17431: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17435: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[9]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17440: return $locv[0];
    L17442: $locv[5] = 0;
    L17445: goto L17522;
    L17448: goto L17461 unless &global_var(61) == 0;
    L17451: goto L17461 unless &global_var(114) == 0;
    L17454: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17458: goto L17481 if pop(@stack) == 0;
    L17461: $stack[@stack] = z_call(17048, \@locv, \@stack, 17468, 0, $locv[2], 32);
    L17468: goto L17522 unless pop(@stack) == 0;
    L17471: $stack[@stack] = z_call(17048, \@locv, \@stack, 17478, 0, $locv[2], 4);
    L17478: goto L17522 unless pop(@stack) == 0;
    L17481: goto L17535 if $locv[5] == 0;
    L17484: $stack[@stack] = z_call(17048, \@locv, \@stack, 17491, 0, $locv[2], 16);
    L17491: goto L17504 unless pop(@stack) == 0;
    L17494: $stack[@stack] = z_call(17048, \@locv, \@stack, 17501, 0, $locv[2], 64);
    L17501: goto L17535 if pop(@stack) == 0;
    L17504: $locv[0] = unpack('s', pack('s', $locv[0])) - 4;
    L17508: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 2;
    L17512: $PlotzMemory::Memory[$t1 = (&global_var(55) + 2*pop(@stack)) & 0xffff] =
        ($t2 = 13578)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17518: &global_var(48, unpack('s', pack('s', &global_var(48))) + 2);
    L17522: $locv[8] = $locv[2];
    L17525: $locv[6] = 0;
    L17528: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L17532: goto L17197;
    L17535: $stack[@stack] = z_call(17048, \@locv, \@stack, 17542, 0, $locv[2], 8);
    L17542: goto L17522 unless pop(@stack) == 0;
    L17546: $stack[@stack] = z_call(18398, \@locv, \@stack, 17552, 0, $locv[0]);
    L17552: return 0;
    L17553: $stack[@stack] = z_call(18320, \@locv, \@stack, 17559, 0, $locv[0]);
    L17559: return 0;
}

sub rtn17560 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L17575: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L17579: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17583: $locv[1] = $PlotzMemory::Memory[(pop(@stack) + 2) & 0xffff];
    L17587: $stack[@stack] = unpack('s', pack('s', $locv[0])) * 2;
    L17591: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', pop(@stack)));
    L17595: $locv[2] = $PlotzMemory::Memory[(pop(@stack) + 3) & 0xffff];
    L17599: goto L17651 if unpack('s', pack('s', ($locv[1] = ($locv[1] - 1) & 0xffff))) < 0;
    L17603: $locv[3] = $PlotzMemory::Memory[(&global_var(87) + $locv[2]) & 0xffff];
    L17607: goto L17620 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (58);
    L17611: $locv[5] = $locv[4];
    L17614: $locv[4] = 0;
    L17617: goto L17646;
    L17620: return 0 if unpack('s', pack('s', $locv[4])) > 10000;
    L17626: return 0 unless unpack('s', pack('s', $locv[3])) < 58;
    L17630: return 0 unless unpack('s', pack('s', $locv[3])) > 47;
    L17634: $locv[6] = unpack('s', pack('s', $locv[4])) * 10;
    L17638: $stack[@stack] = unpack('s', pack('s', $locv[3])) - 48;
    L17642: $locv[4] = unpack('s', pack('s', $locv[6])) + unpack('s', pack('s', pop(@stack)));
    L17646: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L17648: goto L17599;
    L17651: $PlotzMemory::Memory[$t1 = (&global_var(55) + 2*$locv[0]) & 0xffff] =
        ($t2 = 11954)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17657: return 0 if unpack('s', pack('s', $locv[4])) > 1000;
    L17663: goto L17689 if $locv[5] == 0;
    L17666: goto L17677 unless unpack('s', pack('s', $locv[5])) < 8;
    L17670: $locv[5] = unpack('s', pack('s', $locv[5])) + 12;
    L17674: goto L17681;
    L17677: return 0 if unpack('s', pack('s', $locv[5])) > 23;
    L17681: $stack[@stack] = unpack('s', pack('s', $locv[5])) * 60;
    L17685: $locv[4] = unpack('s', pack('s', $locv[4])) + unpack('s', pack('s', pop(@stack)));
    L17689: &global_var(112, $locv[4]);
    L17692: return 11954;
}

sub rtn17696 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (65535, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L17713: &global_var(114, 0);
    L17716: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17720: $locv[6] = 256*$PlotzMemory::Memory[$t1=(pop(@stack) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17724: $locv[7] = z_call(17048, \@locv, \@stack, 17732, 8, $locv[6], 64, 1);
    L17732: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17736: goto L17750 if $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L17740: $stack[@stack] = z_call(17048, \@locv, \@stack, 17747, 0, $locv[6], 32);
    L17747: goto L17756 if pop(@stack) == 0;
    L17750: $locv[5] = 1;
    L17753: goto L17801;
    L17756: $stack[@stack] = z_call(17048, \@locv, \@stack, 17764, 0, $locv[6], 128, 0);
    L17764: goto L17801 if pop(@stack) == 0;
    L17767: goto L17801 unless &global_var(132) == 0;
    L17770: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17775: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*1) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17780: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 2;
    L17784: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*6) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17789: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 6;
    L17793: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*7) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17798: &global_var(132, 1);
    L17801: $locv[2] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17805: goto L17819 if $locv[2] == 0;
    L17808: goto L17819 unless $locv[5] == 0;
    L17811: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17815: return 0 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L17819: return 0 if $t1 = &global_var(132), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L17823: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17827: goto L17905 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L17832: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17836: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17840: goto L17847 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L17844: return 0 unless $locv[1] == 0;
    L17847: goto L17884 if $locv[5] == 0;
    L17850: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 2;
    L17854: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*6) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17859: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17863: goto L17875 unless pop(@stack) == 0;
    L17866: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 6;
    L17870: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*7) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17875: goto L17893 unless &global_var(132) == 0;
    L17878: &global_var(132, 1);
    L17881: goto L17893;
    L17884: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17888: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*6) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17893: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17897: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*7) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17902: goto L18133;
    L17905: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17909: goto L17981 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L17914: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17918: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*4) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17922: goto L17929 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L17926: return 0 unless $locv[1] == 0;
    L17929: goto L17957 if $locv[5] == 0;
    L17932: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 2;
    L17936: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*6) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17941: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17945: goto L17957 unless pop(@stack) == 0;
    L17948: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + 6;
    L17952: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*7) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17957: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17961: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*8) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17966: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L17970: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*9) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L17975: &global_var(132, 2);
    L17978: goto L18133;
    L17981: goto L18133 if &global_var(10) == 0;
    L17985: goto L17996 if $t1 = &global_var(132), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L17989: goto L17996 unless $locv[5] == 0;
    L17992: &global_var(10, 0);
    L17995: return 0;
    L17996: $locv[3] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18000: goto L18010 if $locv[5] == 0;
    L18003: $locv[3] = unpack('s', pack('s', &global_var(55))) + 2;
    L18007: $locv[5] = 0;
    L18010: $locv[4] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18014: $locv[6] = 256*$PlotzMemory::Memory[$t1=($locv[3] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18018: goto L18038 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[4]);
    L18022: goto L18034 if $locv[5] == 0;
    L18025: $stack[@stack] = z_call(18190, \@locv, \@stack, 18031, 0, $locv[5]);
    L18031: goto L18133;
    L18034: &global_var(10, 0);
    L18037: return 0;
    L18038: goto L18091 unless $locv[5] == 0;
    L18041: $stack[@stack] = $PlotzMemory::Memory[($locv[6] + 4) & 0xffff];
    L18045: goto L18057 if (pop(@stack) & ($t1 = 32)) == $t1;
    L18049: goto L18091 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449, 12549);
    L18057: $locv[5] = $locv[6];
    L18060: $locv[3] = unpack('s', pack('s', $locv[3])) + 4;
    L18064: goto L18014 unless $locv[4] == 0;
    L18068: $locv[4] = $locv[3];
    L18071: &global_var(132, 1);
    L18074: $stack[@stack] = unpack('s', pack('s', $locv[3])) - 4;
    L18078: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*6) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18083: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*7) & 0xffff] =
        ($t2 = $locv[3])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18088: goto L18014;
    L18091: goto L18106 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12549);
    L18097: $stack[@stack] = z_call(18190, \@locv, \@stack, 18103, 0, $locv[5]);
    L18103: goto L18133;
    L18106: $stack[@stack] = $PlotzMemory::Memory[($locv[6] + 4) & 0xffff];
    L18110: goto L18060 unless (pop(@stack) & ($t1 = 128)) == $t1;
    L18115: goto L18128 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(28));
    L18119: $stack[@stack] = z_call(18190, \@locv, \@stack, 18125, 0, $locv[5]);
    L18125: goto L18133;
    L18128: $stack[@stack] = z_call(18252, \@locv, \@stack, 18133, 0);
    L18133: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(96) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18137: $PlotzMemory::Memory[$t1 = (&global_var(41) + 2*0) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18142: $stack[@stack] = $PlotzMemory::Memory[(&global_var(96) + 2) & 0xffff];
    L18146: $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff] = pop(@stack) & 0xff;
    L18151: $stack[@stack] = $PlotzMemory::Memory[(&global_var(96) + 3) & 0xffff];
    L18155: $PlotzMemory::Memory[(&global_var(41) + 3) & 0xffff] = pop(@stack) & 0xff;
    L18160: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*1) & 0xffff] =
        ($t2 = &global_var(41))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18165: $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff] = 0 & 0xff;
    L18170: goto L18178 unless unpack('s', pack('s', ($locv[0] = ($locv[0] + 1) & 0xffff))) > 9;
    L18174: &global_var(61, 1);
    L18177: return 1;
    L18178: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18182: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*$locv[0]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18187: goto L18170;
}

sub rtn18190 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18193: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18197: $PlotzMemory::Memory[$t1 = (&global_var(100) + 2*0) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18202: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*0) & 0xffff] =
        ($t2 = &global_var(10))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18207: $stack[@stack] = unpack('s', pack('s', &global_var(10))) + 1;
    L18211: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*1) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18216: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*2) & 0xffff] =
        ($t2 = &global_var(10))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18221: $stack[@stack] = unpack('s', pack('s', &global_var(10))) + 1;
    L18225: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*3) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18230: $stack[@stack] = z_call(19434, \@locv, \@stack, 18238, 0, &global_var(20), &global_var(20), $locv[0]);
    L18238: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18242: goto L18248 if pop(@stack) == 0;
    L18245: &global_var(132, 2);
    L18248: &global_var(10, 0);
    L18251: return 1;
}

sub rtn18252 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18253: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*0) & 0xffff] =
        ($t2 = 6)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18258: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*1) & 0xffff] =
        ($t2 = 7)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18263: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*2) & 0xffff] =
        ($t2 = &global_var(10))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18268: $stack[@stack] = unpack('s', pack('s', &global_var(10))) + 1;
    L18272: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*3) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18277: $stack[@stack] = z_call(19434, \@locv, \@stack, 18284, 0, &global_var(100), &global_var(20));
    L18284: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18288: goto L18294 if pop(@stack) == 0;
    L18291: &global_var(132, 2);
    L18294: &global_var(10, 0);
    L18297: return 1;
}

sub rtn18298 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18303: return 1 if unpack('s', pack('s', ($locv[0] = ($locv[0] - 1) & 0xffff))) < 0;
    L18307: $stack[@stack] = $PlotzMemory::Memory[(&global_var(87) + $locv[1]) & 0xffff];
    L18311: &write_zchar(pop(@stack));
    L18314: ($locv[1] = ($locv[1] + 1) & 0xffff);
    L18316: goto L18303;
}

sub rtn18320 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18327: $PlotzMemory::Memory[$t1 = (&global_var(26) + 2*0) & 0xffff] =
        ($t2 = $locv[0])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18332: goto L18339 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (85);
    L18336: &write_text(&decode_text(&global_var(119) * 2));
    L18338: return 0;
    L18339: # print "[I [abbrev 57]k[abbrev 95][abbrev 0]word ""
        &write_text(&decode_text(18340));
    L18354: $locv[1] = unpack('s', pack('s', $locv[0])) * 2;
    L18358: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', $locv[1]));
    L18362: $locv[2] = $PlotzMemory::Memory[(pop(@stack) + 2) & 0xffff];
    L18366: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', $locv[1]));
    L18370: $stack[@stack] = $PlotzMemory::Memory[(pop(@stack) + 3) & 0xffff];
    L18374: $stack[@stack] = z_call(18298, \@locv, \@stack, 18381, 0, $locv[2], pop(@stack));
    L18381: # print "".]"
        &write_text(&decode_text(18382));
    L18388: &newline();
    L18389: &global_var(102, 0);
    L18392: &global_var(114, 0);
    L18395: return &global_var(114);
}

sub rtn18398 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18405: goto L18412 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (85);
    L18409: &write_text(&decode_text(&global_var(119) * 2));
    L18411: return 0;
    L18412: # print "[[abbrev 2]used [abbrev 0]word ""
        &write_text(&decode_text(18413));
    L18427: $locv[1] = unpack('s', pack('s', $locv[0])) * 2;
    L18431: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', $locv[1]));
    L18435: $locv[2] = $PlotzMemory::Memory[(pop(@stack) + 2) & 0xffff];
    L18439: $stack[@stack] = unpack('s', pack('s', &global_var(55))) + unpack('s', pack('s', $locv[1]));
    L18443: $stack[@stack] = $PlotzMemory::Memory[(pop(@stack) + 3) & 0xffff];
    L18447: $stack[@stack] = z_call(18298, \@locv, \@stack, 18454, 0, $locv[2], pop(@stack));
    L18454: # print "" [abbrev 22]a way [abbrev 17]I [abbrev 57]understand.]"
        &write_text(&decode_text(18455));
    L18479: &newline();
    L18480: &global_var(102, 0);
    L18483: &global_var(114, 0);
    L18486: return &global_var(114);
}

sub rtn18488 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18495: goto L18506 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L18499: $locv[2] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L18503: goto L18510;
    L18506: $locv[2] = $PlotzMemory::Memory[($locv[0] + 4) & 0xffff];
    L18510: $locv[2] = $locv[2] & 63;
    L18514: return 0 if $locv[2] == 0;
    L18517: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 192;
    L18521: return (pop @stack);
}

sub rtn18522 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L18545: $locv[7] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18549: goto L18575 unless $locv[7] == 0;
    L18552: # print "[[abbrev 7]was no verb [abbrev 22][abbrev 17][abbrev 83]!]"
        &write_text(&decode_text(18553));
    L18573: &newline();
    L18574: return 0;
    L18575: $stack[@stack] = 255 - unpack('s', pack('s', $locv[7]));
    L18579: $locv[0] = 256*$PlotzMemory::Memory[$t1=(&global_var(136) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18583: $locv[1] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L18587: ($locv[0] = ($locv[0] + 1) & 0xffff);
    L18589: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L18593: $locv[2] = int(unpack('s', pack('s', pop(@stack))) / 64);
    L18597: goto L18659 if unpack('s', pack('s', &global_var(132))) > unpack('s', pack('s', $locv[2]));
    L18602: goto L18633 if unpack('s', pack('s', $locv[2])) < 1;
    L18606: goto L18633 unless &global_var(132) == 0;
    L18609: $locv[6] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18613: goto L18627 if $locv[6] == 0;
    L18616: $stack[@stack] = z_call(18488, \@locv, \@stack, 18623, 0, $locv[0], 1);
    L18623: goto L18633 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L18627: $locv[4] = $locv[0];
    L18630: goto L18659;
    L18633: $locv[10] = z_call(18488, \@locv, \@stack, 18640, 11, $locv[0], 1);
    L18640: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18644: goto L18659 unless $t1 = $locv[10], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L18648: goto L18697 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L18652: goto L18697 unless $t1 = &global_var(132), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L18656: $locv[5] = $locv[0];
    L18659: goto L18724 unless unpack('s', pack('s', ($locv[1] = ($locv[1] - 1) & 0xffff))) < 1;
    L18664: goto L18752 unless $locv[4] == 0;
    L18668: goto L18752 unless $locv[5] == 0;
    L18672: # print "[[abbrev 70][abbrev 83] [abbrev 37][abbrev 94]I recognize.]"
        &write_text(&decode_text(18673));
    L18695: &newline();
    L18696: return 0;
    L18697: goto L18717 unless unpack('s', pack('s', $locv[2])) > 1;
    L18701: $locv[10] = z_call(18488, \@locv, \@stack, 18708, 11, $locv[0], 2);
    L18708: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*4) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18712: goto L18659 unless $t1 = $locv[10], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L18717: $stack[@stack] = z_call(19624, \@locv, \@stack, 18723, 0, $locv[0]);
    L18723: return 1;
    L18724: goto L18734 unless $locv[2] == 0;
    L18727: $locv[0] = unpack('s', pack('s', $locv[0])) + 2;
    L18731: goto L18589;
    L18734: goto L18745 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L18738: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L18742: goto L18589;
    L18745: $locv[0] = unpack('s', pack('s', $locv[0])) + 7;
    L18749: goto L18589;
    L18752: goto L18798 if $locv[4] == 0;
    L18755: $locv[9] = $PlotzMemory::Memory[($locv[4] + 2) & 0xffff];
    L18759: $locv[10] = $PlotzMemory::Memory[($locv[4] + 3) & 0xffff];
    L18763: $stack[@stack] = z_call(18488, \@locv, \@stack, 18770, 0, $locv[4], 1);
    L18770: $locv[3] = z_call(19636, \@locv, \@stack, 18778, 4, $locv[9], $locv[10], pop(@stack));
    L18778: goto L18798 if $locv[3] == 0;
    L18781: $PlotzMemory::Memory[$t1 = (&global_var(78) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18786: $PlotzMemory::Memory[$t1 = (&global_var(78) + 2*1) & 0xffff] =
        ($t2 = $locv[3])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18791: $stack[@stack] = z_call(19624, \@locv, \@stack, 18797, 0, $locv[4]);
    L18797: return (pop @stack);
    L18798: goto L18844 if $locv[5] == 0;
    L18801: $locv[9] = $PlotzMemory::Memory[($locv[5] + 5) & 0xffff];
    L18805: $locv[10] = $PlotzMemory::Memory[($locv[5] + 6) & 0xffff];
    L18809: $stack[@stack] = z_call(18488, \@locv, \@stack, 18816, 0, $locv[5], 2);
    L18816: $locv[3] = z_call(19636, \@locv, \@stack, 18824, 4, $locv[9], $locv[10], pop(@stack));
    L18824: goto L18844 if $locv[3] == 0;
    L18827: $PlotzMemory::Memory[$t1 = (&global_var(30) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18832: $PlotzMemory::Memory[$t1 = (&global_var(30) + 2*1) & 0xffff] =
        ($t2 = $locv[3])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L18837: $stack[@stack] = z_call(19624, \@locv, \@stack, 18843, 0, $locv[5]);
    L18843: return (pop @stack);
    L18844: goto L18873 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (247);
    L18848: # print "[[abbrev 70]questi[abbrev 59][abbrev 29][abbrev 40]answered.]"
        &write_text(&decode_text(18849));
    L18871: &newline();
    L18872: return 0;
    L18873: goto L18883 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L18877: $stack[@stack] = z_call(19008, \@locv, \@stack, 18882, 0);
    L18882: return (pop @stack);
    L18883: $stack[@stack] = z_call(19044, \@locv, \@stack, 18890, 0, $locv[4], $locv[5]);
    L18890: # print "[What do [abbrev 8]want [abbrev 12]"
        &write_text(&decode_text(18891));
    L18907: $locv[8] = 256*$PlotzMemory::Memory[$t1=(&global_var(20) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18911: goto L18922 unless $locv[8] == 0;
    L18914: # print "tell"
        &write_text(&decode_text(18915));
    L18919: goto L18958;
    L18922: $stack[@stack] = $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff];
    L18926: goto L18938 unless pop(@stack) == 0;
    L18929: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[8] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L18933: &write_text(&decode_text(pop(@stack)));
    L18935: goto L18958;
    L18938: $locv[10] = $PlotzMemory::Memory[($locv[8] + 2) & 0xffff];
    L18942: $stack[@stack] = $PlotzMemory::Memory[($locv[8] + 3) & 0xffff];
    L18946: $stack[@stack] = z_call(18298, \@locv, \@stack, 18953, 0, $locv[10], pop(@stack));
    L18953: $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff] = 0 & 0xff;
    L18958: goto L18971 if $locv[5] == 0;
    L18961: &write_zchar(32);
    L18964: $stack[@stack] = z_call(19206, \@locv, \@stack, 18971, 0, 1, 1);
    L18971: &global_var(114, 1);
    L18974: goto L18987 if $locv[4] == 0;
    L18977: $stack[@stack] = z_call(18488, \@locv, \@stack, 18984, 0, $locv[4], 1);
    L18984: goto L18994;
    L18987: $stack[@stack] = z_call(18488, \@locv, \@stack, 18994, 0, $locv[5], 2);
    L18994: $stack[@stack] = z_call(19414, \@locv, \@stack, 19000, 0, pop(@stack));
    L19000: # print "?]"
        &write_text(&decode_text(19001));
    L19005: &newline();
    L19006: return 0;
}

sub rtn19008 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19009: # print ""I [abbrev 57]understand! What [abbrev 13][abbrev 8]referring to?""
        &write_text(&decode_text(19010));
    L19042: &newline();
    L19043: return 0;
}

sub rtn19044 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 65535);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19051: goto L19059 unless &global_var(61) == 0;
    L19054: $PlotzMemory::Memory[$t1 = (&global_var(67) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19059: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(41) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19063: $PlotzMemory::Memory[$t1 = (&global_var(96) + 2*0) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19068: $stack[@stack] = $PlotzMemory::Memory[(&global_var(41) + 2) & 0xffff];
    L19072: $PlotzMemory::Memory[(&global_var(96) + 2) & 0xffff] = pop(@stack) & 0xff;
    L19077: $stack[@stack] = $PlotzMemory::Memory[(&global_var(41) + 3) & 0xffff];
    L19081: $PlotzMemory::Memory[(&global_var(96) + 3) & 0xffff] = pop(@stack) & 0xff;
    L19086: goto L19102 if unpack('s', pack('s', ($locv[2] = ($locv[2] + 1) & 0xffff))) > 9;
    L19090: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*$locv[2]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19094: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*$locv[2]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19099: goto L19086;
    L19102: goto L19133 unless $t1 = &global_var(132), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L19106: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*0) & 0xffff] =
        ($t2 = 8)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19111: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*1) & 0xffff] =
        ($t2 = 9)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19116: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*2) & 0xffff] =
        ($t2 = 8)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19121: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*3) & 0xffff] =
        ($t2 = 9)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19126: $stack[@stack] = z_call(19434, \@locv, \@stack, 19133, 0, &global_var(100), &global_var(20));
    L19133: goto L19164 if unpack('s', pack('s', &global_var(132))) < 1;
    L19137: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*0) & 0xffff] =
        ($t2 = 6)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19142: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*1) & 0xffff] =
        ($t2 = 7)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19147: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*2) & 0xffff] =
        ($t2 = 6)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19152: $PlotzMemory::Memory[$t1 = (&global_var(54) + 2*3) & 0xffff] =
        ($t2 = 7)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19157: $stack[@stack] = z_call(19434, \@locv, \@stack, 19164, 0, &global_var(100), &global_var(20));
    L19164: goto L19185 if $locv[0] == 0;
    L19167: $stack[@stack] = z_call(18488, \@locv, \@stack, 19174, 0, $locv[0], 1);
    L19174: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*2) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19179: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*6) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19184: return 1;
    L19185: return 0 if $locv[1] == 0;
    L19188: $stack[@stack] = z_call(18488, \@locv, \@stack, 19195, 0, $locv[1], 2);
    L19195: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*4) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19200: $PlotzMemory::Memory[$t1 = (&global_var(20) + 2*8) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19205: return 1;
}

sub rtn19206 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19215: goto L19229 if $locv[0] == 0;
    L19218: $locv[2] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19222: $locv[3] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19226: goto L19237;
    L19229: $locv[2] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19233: $locv[3] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*9) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19237: $stack[@stack] = z_call(19246, \@locv, \@stack, 19245, 0, $locv[2], $locv[3], $locv[1]);
    L19245: return (pop @stack);
}

sub rtn19246 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 1, 0, 1, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19265: return 1 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L19269: $locv[4] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19273: goto L19285 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10351);
    L19279: # print "[abbrev 3]"
        &write_text(&decode_text(19280));
    L19282: goto L19297;
    L19285: goto L19294 if $locv[3] == 0;
    L19288: $locv[3] = 0;
    L19291: goto L19297;
    L19294: &write_zchar(32);
    L19297: goto L19311 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10344, 10351);
    L19305: $locv[3] = 1;
    L19308: goto L19406;
    L19311: goto L19330 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12360);
    L19317: # print "yourself"
        &write_text(&decode_text(19318));
    L19324: $locv[6] = 1;
    L19327: goto L19406;
    L19330: goto L19345 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (11954);
    L19336: &write_text(unpack('s', pack('s', &global_var(112))));
    L19339: $locv[6] = 1;
    L19342: goto L19406;
    L19345: goto L19357 if $locv[5] == 0;
    L19348: goto L19357 unless $locv[6] == 0;
    L19351: goto L19357 if $locv[2] == 0;
    L19354: # print "[abbrev 0]"
        &write_text(&decode_text(19355));
    L19357: goto L19363 unless &global_var(114) == 0;
    L19360: goto L19368 if &global_var(61) == 0;
    L19363: &write_text(&decode_text($locv[4]));
    L19365: goto L19403;
    L19368: goto L19388 unless $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (11996);
    L19374: $stack[@stack] = z_call(31344, \@locv, \@stack, 19380, 0, &global_var(122));
    L19380: goto L19388 if pop(@stack) == 0;
    L19383: &write_text(&decode_text(&thing_location(&global_var(122), 'name')));
    L19385: goto L19403;
    L19388: $locv[8] = $PlotzMemory::Memory[($locv[0] + 2) & 0xffff];
    L19392: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 3) & 0xffff];
    L19396: $stack[@stack] = z_call(18298, \@locv, \@stack, 19403, 0, $locv[8], pop(@stack));
    L19403: $locv[5] = 0;
    L19406: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L19410: goto L19265;
}

sub rtn19414 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19419: return 0 if $locv[0] == 0;
    L19422: &write_zchar(32);
    L19425: $locv[1] = z_call(19586, \@locv, \@stack, 19431, 2, $locv[0]);
    L19431: &write_text(&decode_text($locv[1]));
    L19433: return 1;
}

sub rtn19434 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19447: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(54) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19451: $locv[3] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19455: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(54) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19459: $locv[4] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19463: $locv[5] = 256*$PlotzMemory::Memory[$t1=(&global_var(54) + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19467: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(67) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19471: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 2;
    L19475: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 2;
    L19479: $stack[@stack] = unpack('s', pack('s', &global_var(67))) + unpack('s', pack('s', pop(@stack)));
    L19483: $PlotzMemory::Memory[$t1 = ($locv[1] + 2*$locv[5]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19488: goto L19518 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[4]);
    L19492: $locv[5] = 256*$PlotzMemory::Memory[$t1=(&global_var(54) + 2*3) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19496: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(67) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19500: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 2;
    L19504: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 2;
    L19508: $stack[@stack] = unpack('s', pack('s', &global_var(67))) + unpack('s', pack('s', pop(@stack)));
    L19512: $PlotzMemory::Memory[$t1 = ($locv[1] + 2*$locv[5]) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19517: return 1;
    L19518: goto L19535 if $locv[2] == 0;
    L19521: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[3] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19525: goto L19535 unless $t1 = &global_var(28), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L19529: $stack[@stack] = z_call(19552, \@locv, \@stack, 19535, 0, $locv[2]);
    L19535: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[3] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19539: $stack[@stack] = z_call(19552, \@locv, \@stack, 19545, 0, pop(@stack));
    L19545: $locv[3] = unpack('s', pack('s', $locv[3])) + 4;
    L19549: goto L19488;
}

sub rtn19552 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19557: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(67) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19561: $locv[1] = unpack('s', pack('s', pop(@stack))) + 2;
    L19565: $stack[@stack] = unpack('s', pack('s', $locv[1])) - 1;
    L19569: $PlotzMemory::Memory[$t1 = (&global_var(67) + 2*pop(@stack)) & 0xffff] =
        ($t2 = $locv[0])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19574: $PlotzMemory::Memory[$t1 = (&global_var(67) + 2*$locv[1]) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19579: $PlotzMemory::Memory[$t1 = (&global_var(67) + 2*&global_var(13)) & 0xffff] =
        ($t2 = $locv[1])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19584: return 1;
}

sub rtn19586 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19593: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(133) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19597: $locv[2] = unpack('s', pack('s', pop(@stack))) * 2;
    L19601: return 0 if unpack('s', pack('s', ($locv[1] = ($locv[1] + 1) & 0xffff))) > unpack('s', pack('s', $locv[2]));
    L19605: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(133) + 2*$locv[1]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19609: goto L19601 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L19614: $stack[@stack] = unpack('s', pack('s', $locv[1])) - 1;
    L19618: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(133) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19622: return (pop @stack);
}

sub rtn19624 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19627: &global_var(69, $locv[0]);
    L19630: &global_var(75, $PlotzMemory::Memory[($locv[0] + 1) & 0xffff]);
    L19634: return &global_var(75);
}

sub rtn19636 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19645: goto L19651 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (24);
    L19649: return 27;
    L19651: &global_var(62, $locv[0]);
    L19654: &global_var(12, $locv[1]);
    L19657: $PlotzMemory::Memory[$t1 = (&global_var(89) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19662: $stack[@stack] = z_call(20274, \@locv, \@stack, 19669, 0, &global_var(89), 0);
    L19669: goto L19750 if pop(@stack) == 0;
    L19673: &global_var(62, 0);
    L19676: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(89) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19680: return 0 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L19684: $locv[3] = 256*$PlotzMemory::Memory[$t1=(&global_var(89) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19688: &write_zchar(91);
    L19691: goto L19742 if $locv[2] == 0;
    L19694: goto L19742 unless &global_var(3) == 0;
    L19697: $locv[2] = z_call(19586, \@locv, \@stack, 19703, 3, $locv[2]);
    L19703: &write_text(&decode_text($locv[2]));
    L19705: goto L19714 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12584);
    L19711: # print " of"
        &write_text(&decode_text(19712));
    L19714: &write_zchar(32);
    L19717: goto L19731 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4);
    L19721: # print "[abbrev 4]hands"
        &write_text(&decode_text(19722));
    L19728: goto L19736;
    L19731: # print "[abbrev 0]"
        &write_text(&decode_text(19732));
    L19734: &write_text(&decode_text(&thing_location($locv[3], 'name')));
    L19736: &write_zchar(93);
    L19739: &newline();
    L19740: return $locv[3];
    L19742: &write_text(&decode_text(&thing_location($locv[3], 'name')));
    L19744: &write_zchar(93);
    L19747: &newline();
    L19748: return $locv[3];
    L19750: &global_var(62, 0);
    L19753: return 0;
}

sub rtn19754 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19761: $PlotzMemory::Memory[$t1 = (&global_var(4) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19766: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19770: goto L19792 if $locv[1] == 0;
    L19773: &global_var(12, $PlotzMemory::Memory[(&global_var(69) + 6) & 0xffff]);
    L19777: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*9) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19781: $stack[@stack] = z_call(19932, \@locv, \@stack, 19789, 0, $locv[1], pop(@stack), &global_var(30));
    L19789: return 0 if pop(@stack) == 0;
    L19792: $locv[0] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19796: goto L19818 if $locv[0] == 0;
    L19799: &global_var(12, $PlotzMemory::Memory[(&global_var(69) + 3) & 0xffff]);
    L19803: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19807: $stack[@stack] = z_call(19932, \@locv, \@stack, 19815, 0, $locv[0], pop(@stack), &global_var(78));
    L19815: return 0 if pop(@stack) == 0;
    L19818: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(4) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19822: return 1 if pop(@stack) == 0;
    L19825: $locv[2] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19829: goto L19838 if $locv[0] == 0;
    L19832: &global_var(78, z_call(19860, \@locv, \@stack, 19838, 94, &global_var(78)));
    L19838: return 1 if $locv[1] == 0;
    L19841: goto L19852 if $locv[0] == 0;
    L19844: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19848: return 1 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L19852: &global_var(30, z_call(19860, \@locv, \@stack, 19858, 46, &global_var(30)));
    L19858: return 1;
}

sub rtn19860 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 1, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19875: $locv[1] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19879: $PlotzMemory::Memory[$t1 = (&global_var(89) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19884: goto L19918 if unpack('s', pack('s', ($locv[1] = ($locv[1] - 1) & 0xffff))) < 0;
    L19888: $locv[5] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19892: $stack[@stack] = z_call(21552, \@locv, \@stack, 19899, 0, $locv[5], &global_var(4));
    L19899: goto L19913 unless pop(@stack) == 0;
    L19902: $stack[@stack] = unpack('s', pack('s', $locv[4])) + 1;
    L19906: $PlotzMemory::Memory[$t1 = (&global_var(89) + 2*pop(@stack)) & 0xffff] =
        ($t2 = $locv[5])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19911: ($locv[4] = ($locv[4] + 1) & 0xffff);
    L19913: ($locv[3] = ($locv[3] + 1) & 0xffff);
    L19915: goto L19884;
    L19918: $PlotzMemory::Memory[$t1 = (&global_var(89) + 2*&global_var(13)) & 0xffff] =
        ($t2 = $locv[4])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19923: $locv[6] = &global_var(89);
    L19926: &global_var(89, $locv[0]);
    L19929: return $locv[6];
}

sub rtn19932 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L19951: &global_var(81, 0);
    L19954: goto L19961 unless $t1 = &global_var(104), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L19958: $locv[8] = 1;
    L19961: &global_var(104, 0);
    L19964: $PlotzMemory::Memory[$t1 = ($locv[2] + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L19969: $locv[6] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L19973: goto L20005 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L19977: goto L19986 if $locv[3] == 0;
    L19980: push @stack, $locv[3];
    L19983: goto L19989;
    L19986: push @stack, $locv[2];
    L19989: $locv[5] = z_call(20274, \@locv, \@stack, 19995, 6, pop(@stack));
    L19995: goto L20000 unless $locv[8] == 0;
    L19998: return $locv[5];
    L20000: &global_var(104, 1);
    L20003: return $locv[5];
    L20005: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 4;
    L20009: goto L20019 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L20013: $locv[7] = 0;
    L20016: goto L20023;
    L20019: $locv[7] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20023: goto L20046 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10449);
    L20029: &global_var(104, 1);
    L20032: goto L20259 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L20039: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L20043: goto L20259;
    L20046: goto L20086 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10890, 11394);
    L20054: goto L20063 if $locv[3] == 0;
    L20057: push @stack, $locv[3];
    L20060: goto L20066;
    L20063: push @stack, $locv[2];
    L20066: $stack[@stack] = z_call(20274, \@locv, \@stack, 20072, 0, pop(@stack));
    L20072: return 0 if pop(@stack) == 0;
    L20075: $locv[3] = &global_var(4);
    L20078: $PlotzMemory::Memory[$t1 = ($locv[3] + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20083: goto L20259;
    L20086: goto L20143 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10393, 12549);
    L20094: goto L20114 unless &global_var(47) == 0;
    L20097: &global_var(104, 2);
    L20100: goto L20259 unless $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L20107: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L20111: goto L20259;
    L20114: &global_var(21, &global_var(82));
    L20117: goto L20126 if $locv[3] == 0;
    L20120: push @stack, $locv[3];
    L20123: goto L20129;
    L20126: push @stack, $locv[2];
    L20129: $stack[@stack] = z_call(20274, \@locv, \@stack, 20135, 0, pop(@stack));
    L20135: return 0 if pop(@stack) == 0;
    L20138: goto L20259 unless $locv[7] == 0;
    L20142: return 1;
    L20143: goto L20185 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477, 10351);
    L20151: goto L20185 if $t1 = $locv[7], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477, 10351);
    L20159: &global_var(81, 1);
    L20162: goto L20171 if $locv[3] == 0;
    L20165: push @stack, $locv[3];
    L20168: goto L20174;
    L20171: push @stack, $locv[2];
    L20174: $stack[@stack] = z_call(20274, \@locv, \@stack, 20180, 0, pop(@stack));
    L20180: goto L20259 unless pop(@stack) == 0;
    L20184: return 0;
    L20185: $stack[@stack] = z_call(17048, \@locv, \@stack, 20192, 0, $locv[6], 4);
    L20192: goto L20259 unless pop(@stack) == 0;
    L20196: goto L20259 if $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10477, 10351);
    L20204: goto L20219 unless $t1 = $locv[6], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12514);
    L20210: goto L20259 unless &global_var(104) == 0;
    L20213: &global_var(104, 4);
    L20216: goto L20259;
    L20219: $locv[5] = z_call(17048, \@locv, \@stack, 20227, 6, $locv[6], 32, 2);
    L20227: goto L20242 if $locv[5] == 0;
    L20230: goto L20242 unless &global_var(47) == 0;
    L20233: &global_var(47, $locv[5]);
    L20236: &global_var(117, $locv[6]);
    L20239: goto L20259;
    L20242: $stack[@stack] = z_call(17048, \@locv, \@stack, 20250, 0, $locv[6], 128, 0);
    L20250: goto L20259 if pop(@stack) == 0;
    L20253: &global_var(21, $locv[6]);
    L20256: &global_var(82, $locv[6]);
    L20259: goto L19973 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L20264: $locv[0] = unpack('s', pack('s', $locv[0])) + 4;
    L20268: $locv[6] = $locv[7];
    L20271: goto L19973;
}

sub rtn20274 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 1, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L20293: $locv[4] = &global_var(12);
    L20296: $locv[5] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20300: return 1 if (&global_var(104) & ($t1 = 4)) == $t1;
    L20304: goto L20327 unless &global_var(21) == 0;
    L20307: goto L20327 if &global_var(47) == 0;
    L20310: $stack[@stack] = z_call(17048, \@locv, \@stack, 20318, 0, &global_var(117), 128, 0);
    L20318: goto L20327 if pop(@stack) == 0;
    L20321: &global_var(21, &global_var(117));
    L20324: &global_var(47, 0);
    L20327: goto L20346 unless &global_var(21) == 0;
    L20330: goto L20346 unless &global_var(47) == 0;
    L20333: goto L20346 if $t1 = &global_var(104), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L20337: goto L20346 unless &global_var(62) == 0;
    L20340: return 0 if $locv[1] == 0;
    L20343: &write_text(&decode_text(&global_var(39) * 2));
    L20345: return 0;
    L20346: goto L20353 unless $t1 = &global_var(104), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L20350: goto L20358 unless &global_var(12) == 0;
    L20353: &global_var(12, 65535);
    L20358: &global_var(103, $locv[0]);
    L20361: goto L20373 if $locv[6] == 0;
    L20364: $stack[@stack] = z_call(20788, \@locv, \@stack, 20370, 0, $locv[0]);
    L20370: goto L20398;
    L20373: goto L20390 if &global_var(38) == 0;
    L20376: &clear_attr(30, 8);
    L20379: $stack[@stack] = z_call(20994, \@locv, \@stack, 20387, 0, &global_var(0), 16, 32);
    L20387: &set_attr(30, 8);
    L20390: $stack[@stack] = z_call(20994, \@locv, \@stack, 20398, 0, 30, 128, 64);
    L20398: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20402: $locv[3] = unpack('s', pack('s', pop(@stack))) - unpack('s', pack('s', $locv[5]));
    L20406: goto L20581 if (&global_var(104) & ($t1 = 1)) == $t1;
    L20411: goto L20464 unless (&global_var(104) & ($t1 = 2)) == $t1;
    L20415: goto L20464 if $locv[3] == 0;
    L20418: goto L20456 if $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L20422: $stack[@stack] = &z_random(unpack('s', pack('s', $locv[3])));
    L20426: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20430: $PlotzMemory::Memory[$t1 = ($locv[0] + 2*1) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20435: # print "[[abbrev 80][abbrev 54][abbrev 0]"
        &write_text(&decode_text(20436));
    L20444: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20448: &write_text(&decode_text(&thing_location(pop(@stack), 'name')));
    L20450: # print "?]"
        &write_text(&decode_text(20451));
    L20455: &newline();
    L20456: $PlotzMemory::Memory[$t1 = ($locv[0] + 2*&global_var(13)) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20461: goto L20581;
    L20464: goto L20479 if unpack('s', pack('s', $locv[3])) > 1;
    L20468: goto L20581 unless $locv[3] == 0;
    L20472: goto L20581 if $t1 = &global_var(12), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65535);
    L20479: goto L20507 unless $t1 = &global_var(12), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65535);
    L20485: &global_var(12, $locv[4]);
    L20488: $locv[7] = $locv[3];
    L20491: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20495: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - unpack('s', pack('s', $locv[3]));
    L20499: $PlotzMemory::Memory[$t1 = ($locv[0] + 2*&global_var(13)) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20504: goto L20361;
    L20507: goto L20513 unless $locv[3] == 0;
    L20510: $locv[3] = $locv[7];
    L20513: goto L20523 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L20517: $stack[@stack] = z_call(19008, \@locv, \@stack, 20522, 0);
    L20522: return 0;
    L20523: goto L20569 if $locv[1] == 0;
    L20526: goto L20569 if &global_var(21) == 0;
    L20529: $stack[@stack] = z_call(20654, \@locv, \@stack, 20537, 0, $locv[5], $locv[3], $locv[0]);
    L20537: goto L20547 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(78));
    L20541: &global_var(10, 6);
    L20544: goto L20550;
    L20547: &global_var(10, 8);
    L20550: &global_var(73, &global_var(47));
    L20553: &global_var(28, &global_var(21));
    L20556: $stack[@stack] = z_call(19044, \@locv, \@stack, 20563, 0, 0, 0);
    L20563: &global_var(114, 1);
    L20566: goto L20574;
    L20569: goto L20574 if $locv[1] == 0;
    L20572: &write_text(&decode_text(&global_var(39) * 2));
    L20574: &global_var(21, 0);
    L20577: &global_var(47, 0);
    L20580: return 0;
    L20581: goto L20635 unless $locv[3] == 0;
    L20584: goto L20635 if $locv[6] == 0;
    L20587: goto L20628 if $locv[1] == 0;
    L20590: &global_var(12, $locv[4]);
    L20593: goto L20600 unless &global_var(38) == 0;
    L20596: goto L20626 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L20600: $stack[@stack] = z_call(21150, \@locv, \@stack, 20607, 0, 130, $locv[0]);
    L20607: &global_var(24, &global_var(21));
    L20610: &global_var(70, &global_var(47));
    L20613: &global_var(42, &global_var(117));
    L20616: &global_var(21, 0);
    L20619: &global_var(47, 0);
    L20622: &global_var(117, 0);
    L20625: return 1;
    L20626: &write_text(&decode_text(&global_var(57) * 2));
    L20628: &global_var(21, 0);
    L20631: &global_var(47, 0);
    L20634: return 0;
    L20635: goto L20644 unless $locv[3] == 0;
    L20638: $locv[6] = 1;
    L20641: goto L20361;
    L20644: &global_var(12, $locv[4]);
    L20647: &global_var(21, 0);
    L20650: &global_var(47, 0);
    L20653: return 1;
}

sub rtn20654 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L20665: $locv[4] = $locv[1];
    L20668: # print "[Which "
        &write_text(&decode_text(20669));
    L20677: goto L20686 unless &global_var(114) == 0;
    L20680: goto L20686 unless &global_var(61) == 0;
    L20683: goto L20713 if &global_var(81) == 0;
    L20686: goto L20695 if &global_var(21) == 0;
    L20689: push @stack, &global_var(21);
    L20692: goto L20708;
    L20695: goto L20704 if &global_var(47) == 0;
    L20698: push @stack, &global_var(117);
    L20701: goto L20708;
    L20704: push @stack, 12549;
    L20708: &write_text(&decode_text(pop(@stack)));
    L20710: goto L20732;
    L20713: goto L20723 if $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(78));
    L20717: push @stack, 0;
    L20720: goto L20726;
    L20723: push @stack, 1;
    L20726: $stack[@stack] = z_call(19206, \@locv, \@stack, 20732, 0, pop(@stack));
    L20732: # print " do [abbrev 8]mean[abbrev 3]"
        &write_text(&decode_text(20733));
    L20741: ($locv[0] = ($locv[0] + 1) & 0xffff);
    L20743: $locv[3] = 256*$PlotzMemory::Memory[$t1=($locv[2] + 2*$locv[0]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20747: # print "[abbrev 0]"
        &write_text(&decode_text(20748));
    L20750: &write_text(&decode_text(&thing_location($locv[3], 'name')));
    L20752: goto L20771 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L20756: goto L20763 if $t1 = $locv[4], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L20760: &write_zchar(44);
    L20763: # print " or "
        &write_text(&decode_text(20764));
    L20768: goto L20778;
    L20771: goto L20778 unless unpack('s', pack('s', $locv[1])) > 2;
    L20775: # print "[abbrev 3]"
        &write_text(&decode_text(20776));
    L20778: goto L20741 unless unpack('s', pack('s', ($locv[1] = ($locv[1] - 1) & 0xffff))) < 1;
    L20783: # print "?]"
        &write_text(&decode_text(20784));
	&newline();
	return(1);
}

sub rtn20788 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L20805: $locv[1] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20809: $locv[6] = &global_var(12);
    L20812: $locv[2] = &get_prop_addr(&global_var(0), 12);
    L20816: goto L20852 if $locv[2] == 0;
    L20819: $stack[@stack] = &get_prop_len($locv[2]);
    L20822: $locv[3] = unpack('s', pack('s', pop(@stack))) - 1;
    L20826: $locv[5] = $PlotzMemory::Memory[($locv[2] + $locv[4]) & 0xffff];
    L20830: $stack[@stack] = z_call(21732, \@locv, \@stack, 20837, 0, $locv[5], $locv[0]);
    L20837: goto L20847 if pop(@stack) == 0;
    L20840: $stack[@stack] = z_call(21150, \@locv, \@stack, 20847, 0, $locv[5], $locv[0]);
    L20847: goto L20826 unless unpack('s', pack('s', ($locv[4] = ($locv[4] + 1) & 0xffff))) > unpack('s', pack('s', $locv[3]));
    L20852: $locv[2] = &get_prop_addr(&global_var(0), 8);
    L20856: goto L20944 if $locv[2] == 0;
    L20860: $stack[@stack] = &get_prop_len($locv[2]);
    L20863: $stack[@stack] = int(unpack('s', pack('s', pop(@stack))) / 4);
    L20867: $locv[3] = unpack('s', pack('s', pop(@stack))) - 1;
    L20871: $locv[4] = 0;
    L20874: $stack[@stack] = unpack('s', pack('s', $locv[4])) * 2;
    L20878: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[2] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20882: goto L20939 unless $t1 = &global_var(21), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L20886: $stack[@stack] = unpack('s', pack('s', $locv[4])) * 2;
    L20890: $stack[@stack] = unpack('s', pack('s', pop(@stack))) + 1;
    L20894: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[2] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20898: &put_prop(179, 18, pop(@stack));
    L20903: $stack[@stack] = &get_prop_addr(179, 18);
    L20907: $locv[7] = unpack('s', pack('s', pop(@stack))) - 5;
    L20911: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(21) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20915: $PlotzMemory::Memory[$t1 = ($locv[7] + 2*0) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20920: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(21) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20924: $PlotzMemory::Memory[$t1 = ($locv[7] + 2*1) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L20929: $stack[@stack] = z_call(21150, \@locv, \@stack, 20936, 0, 179, $locv[0]);
    L20936: goto L20944;
    L20939: goto L20874 unless unpack('s', pack('s', ($locv[4] = ($locv[4] + 1) & 0xffff))) > unpack('s', pack('s', $locv[3]));
    L20944: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20948: return 0 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[1]);
    L20952: &global_var(12, 65535);
    L20957: &global_var(103, $locv[0]);
    L20960: $stack[@stack] = z_call(20994, \@locv, \@stack, 20968, 0, 45, 1, 1);
    L20968: &global_var(12, $locv[6]);
    L20971: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L20975: return 0 unless pop(@stack) == 0;
    L20978: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (47, 86, 46);
    L20985: $stack[@stack] = z_call(20994, \@locv, \@stack, 20993, 0, 27, 1, 1);
    L20993: return (pop @stack);
}

sub rtn20994 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21003: $stack[@stack] = unpack('s', pack('s', $locv[1])) + unpack('s', pack('s', $locv[2]));
    L21007: goto L21020 unless (&global_var(12) & ($t1 = pop(@stack))) == $t1;
    L21011: $stack[@stack] = z_call(21046, \@locv, \@stack, 21019, 0, $locv[0], &global_var(103), 1);
    L21019: return (pop @stack);
    L21020: goto L21033 unless (&global_var(12) & ($t1 = $locv[1])) == $t1;
    L21024: $stack[@stack] = z_call(21046, \@locv, \@stack, 21032, 0, $locv[0], &global_var(103), 0);
    L21032: return (pop @stack);
    L21033: return 1 unless (&global_var(12) & ($t1 = $locv[2])) == $t1;
    L21037: $stack[@stack] = z_call(21046, \@locv, \@stack, 21045, 0, $locv[0], &global_var(103), 2);
    L21045: return (pop @stack);
}

sub rtn21046 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21057: return 0 unless $locv[0] = get_child($locv[0]);
    L21061: goto L21089 if $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L21065: $stack[@stack] = &get_prop_addr($locv[0], 17);
    L21069: goto L21089 if pop(@stack) == 0;
    L21072: $stack[@stack] = z_call(21732, \@locv, \@stack, 21079, 0, $locv[0], $locv[1]);
    L21079: goto L21089 if pop(@stack) == 0;
    L21082: $stack[@stack] = z_call(21150, \@locv, \@stack, 21089, 0, $locv[0], $locv[1]);
    L21089: goto L21100 unless $locv[2] == 0;
    L21092: goto L21100 if &test_attr($locv[0], 9);
    L21096: goto L21143 unless &test_attr($locv[0], 12);
    L21100: goto L21143 unless $locv[4] = get_child($locv[0]);
    L21104: goto L21112 if &test_attr($locv[0], 10);
    L21108: goto L21143 unless &test_attr($locv[0], 8);
    L21112: goto L21122 unless &test_attr($locv[0], 12);
    L21116: push @stack, 1;
    L21119: goto L21135;
    L21122: goto L21132 unless &test_attr($locv[0], 9);
    L21126: push @stack, 1;
    L21129: goto L21135;
    L21132: push @stack, 0;
    L21135: $locv[3] = z_call(21046, \@locv, \@stack, 21143, 4, $locv[0], $locv[1], pop(@stack));
    L21143: goto L21061 if $locv[0] = get_sibling($locv[0]);
    L21148: return 1;
}

sub rtn21150 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21157: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21161: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 1;
    L21165: $PlotzMemory::Memory[$t1 = ($locv[1] + 2*pop(@stack)) & 0xffff] =
        ($t2 = $locv[0])>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L21170: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 1;
    L21174: $PlotzMemory::Memory[$t1 = ($locv[1] + 2*&global_var(13)) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L21179: return 1;
}

sub rtn21180 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21183: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 0) & 0xffff];
    L21187: $locv[0] = int(unpack('s', pack('s', pop(@stack))) / 64);
    L21191: return 1 unless unpack('s', pack('s', $locv[0])) > 0;
    L21195: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 3) & 0xffff];
    L21199: $stack[@stack] = z_call(21226, \@locv, \@stack, 21206, 0, &global_var(78), pop(@stack));
    L21206: return 0 if pop(@stack) == 0;
    L21209: return 1 unless unpack('s', pack('s', $locv[0])) > 1;
    L21213: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 6) & 0xffff];
    L21217: $stack[@stack] = z_call(21226, \@locv, \@stack, 21224, 0, &global_var(30), pop(@stack));
    L21224: return (pop @stack);
}

sub rtn21226 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21237: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21241: return 1 if $locv[2] == 0;
    L21244: goto L21252 if ($locv[1] & ($t1 = 2)) == $t1;
    L21248: return 1 unless ($locv[1] & ($t1 = 8)) == $t1;
    L21252: return 1 if unpack('s', pack('s', ($locv[2] = ($locv[2] - 1) & 0xffff))) < 0;
    L21256: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 1;
    L21260: $locv[3] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21264: goto L21283 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L21268: $stack[@stack] = z_call(31344, \@locv, \@stack, 21274, 0, &global_var(122));
    L21274: goto L21280 unless pop(@stack) == 0;
    L21277: &write_text(&decode_text(&global_var(34) * 2));
    L21279: return 0;
    L21280: $locv[3] = &global_var(122);
    L21283: $stack[@stack] = z_call(31442, \@locv, \@stack, 21289, 0, $locv[3]);
    L21289: goto L21252 unless pop(@stack) == 0;
    L21293: goto L21252 if $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4, 13);
    L21300: &global_var(59, $locv[3]);
    L21303: goto L21313 unless &test_attr($locv[3], 11);
    L21307: $locv[4] = 1;
    L21310: goto L21346;
    L21313: goto L21323 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L21317: $locv[4] = 0;
    L21320: goto L21346;
    L21323: goto L21343 unless ($locv[1] & ($t1 = 8)) == $t1;
    L21327: $stack[@stack] = z_call(29480, \@locv, \@stack, 21333, 0, 0);
    L21333: goto L21343 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L21337: $locv[4] = 0;
    L21340: goto L21346;
    L21343: $locv[4] = 1;
    L21346: goto L21383 if $locv[4] == 0;
    L21349: goto L21383 unless ($locv[1] & ($t1 = 2)) == $t1;
    L21353: goto L21383 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L21357: goto L21370 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (130);
    L21361: &write_text(&decode_text(&global_var(80) * 2));
    L21363: # print "[abbrev 41]!"
        &write_text(&decode_text(21364));
    L21368: &newline();
    L21369: return 0;
    L21370: &global_var(122, $locv[3]);
    L21373: &write_text(&decode_text(&global_var(80) * 2));
    L21375: # print "[abbrev 0]"
        &write_text(&decode_text(21376));
    L21378: &write_text(&decode_text(&thing_location($locv[3], 'name')));
    L21380: &write_text(&decode_text(&global_var(7) * 2));
    L21382: return 0;
    L21383: goto L21252 unless $locv[4] == 0;
    L21387: goto L21252 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L21392: # print "[Taken]"
        &write_text(&decode_text(21393));
    L21403: &newline();
    L21404: goto L21252;
}

sub rtn21408 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21415: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(78) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21419: goto L21437 unless unpack('s', pack('s', pop(@stack))) > 1;
    L21423: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 3) & 0xffff];
    L21427: goto L21437 if (pop(@stack) & ($t1 = 4)) == $t1;
    L21431: $locv[0] = 1;
    L21434: goto L21456;
    L21437: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(30) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21441: goto L21456 unless unpack('s', pack('s', pop(@stack))) > 1;
    L21445: $stack[@stack] = $PlotzMemory::Memory[(&global_var(69) + 6) & 0xffff];
    L21449: goto L21456 if (pop(@stack) & ($t1 = 4)) == $t1;
    L21453: $locv[0] = 2;
    L21456: return 1 if $locv[0] == 0;
    L21459: &write_zchar(91);
    L21462: &write_text(&decode_text(&global_var(64) * 2));
    L21464: # print "use multiple "
        &write_text(&decode_text(21465));
    L21475: goto L21482 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L21479: # print "in"
        &write_text(&decode_text(21480));
    L21482: # print "direct objects [abbrev 11]""
        &write_text(&decode_text(21483));
    L21497: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21501: goto L21512 unless $locv[1] == 0;
    L21504: # print "tell"
        &write_text(&decode_text(21505));
    L21509: goto L21542;
    L21512: goto L21518 unless &global_var(114) == 0;
    L21515: goto L21527 if &global_var(61) == 0;
    L21518: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21522: &write_text(&decode_text(pop(@stack)));
    L21524: goto L21542;
    L21527: $locv[2] = $PlotzMemory::Memory[($locv[1] + 2) & 0xffff];
    L21531: $stack[@stack] = $PlotzMemory::Memory[($locv[1] + 3) & 0xffff];
    L21535: $stack[@stack] = z_call(18298, \@locv, \@stack, 21542, 0, $locv[2], pop(@stack));
    L21542: # print "".]"
        &write_text(&decode_text(21543));
    L21549: &newline();
    L21550: return 0;
}

sub rtn21552 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 65535, 1);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21561: return 0 if $locv[1] == 0;
    L21564: goto L21574 if unpack('s', pack('s', $locv[2])) < 0;
    L21568: $locv[3] = 0;
    L21571: goto L21578;
    L21574: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21578: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*$locv[3]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21582: goto L21595 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L21586: $stack[@stack] = unpack('s', pack('s', $locv[3])) * 2;
    L21590: $stack[@stack] = unpack('s', pack('s', $locv[1])) + unpack('s', pack('s', pop(@stack)));
    L21594: return (pop @stack);
    L21595: goto L21578 unless unpack('s', pack('s', ($locv[3] = ($locv[3] + 1) & 0xffff))) > unpack('s', pack('s', $locv[2]));
    L21600: return 0;
}

sub rtn21602 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21611: $stack[@stack] = $PlotzMemory::Memory[($locv[1] + $locv[3]) & 0xffff];
    L21615: return 1 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L21619: goto L21611 unless unpack('s', pack('s', ($locv[3] = ($locv[3] + 1) & 0xffff))) > unpack('s', pack('s', $locv[2]));
    L21624: return 0;
}

sub rtn21626 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 1, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21635: goto L21642 if &global_var(88) == 0;
    L21638: return 1 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L21642: &global_var(62, 19);
    L21645: $locv[2] = &global_var(0);
    L21648: &global_var(0, $locv[0]);
    L21651: goto L21664 if $locv[1] == 0;
    L21654: goto L21664 unless &test_attr($locv[0], 19);
    L21658: $locv[3] = 1;
    L21661: goto L21724;
    L21664: $PlotzMemory::Memory[$t1 = (&global_var(89) + 2*&global_var(13)) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L21669: &global_var(103, &global_var(89));
    L21672: &global_var(12, 65535);
    L21677: goto L21705 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L21681: $stack[@stack] = z_call(20994, \@locv, \@stack, 21689, 0, &global_var(115), 1, 1);
    L21689: goto L21705 if $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L21693: goto L21705 unless $locv[0] == &get_object(&thing_location(30, 'parent'));
    L21697: $stack[@stack] = z_call(20994, \@locv, \@stack, 21705, 0, 30, 1, 1);
    L21705: $stack[@stack] = z_call(20994, \@locv, \@stack, 21713, 0, $locv[0], 1, 1);
    L21713: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(103) + 2*&global_var(13)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L21717: goto L21724 unless unpack('s', pack('s', pop(@stack))) > 0;
    L21721: $locv[3] = 1;
    L21724: &global_var(0, $locv[2]);
    L21727: &global_var(62, 0);
    L21730: return $locv[3];
}

sub rtn21732 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21741: return 0 if &test_attr($locv[0], 14);
    L21745: goto L21774 if &global_var(21) == 0;
    L21748: $locv[2] = &get_prop_addr($locv[0], 17);
    L21752: $stack[@stack] = &get_prop_len($locv[2]);
    L21755: $stack[@stack] = int(unpack('s', pack('s', pop(@stack))) / 2);
    L21759: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 1;
    L21763: $stack[@stack] = z_call(21552, \@locv, \@stack, 21771, 0, &global_var(21), $locv[2], pop(@stack));
    L21771: return 0 if pop(@stack) == 0;
    L21774: goto L21802 if &global_var(47) == 0;
    L21777: $locv[2] = &get_prop_addr($locv[0], 16);
    L21781: return 0 if $locv[2] == 0;
    L21784: $stack[@stack] = &get_prop_len($locv[2]);
    L21787: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 1;
    L21791: $stack[@stack] = z_call(21602, \@locv, \@stack, 21799, 0, &global_var(47), $locv[2], pop(@stack));
    L21799: return 0 if pop(@stack) == 0;
    L21802: return 1 if &global_var(62) == 0;
    L21805: return 1 if &test_attr($locv[0], &global_var(62));
    L21809: return 0;
}

sub rtn21810 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21811: &global_var(32, 2);
    L21814: # print "Maximum verbosity."
        &write_text(&decode_text(21815));
	&newline();
	return(1);
}

sub rtn21830 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21831: &global_var(32, 1);
    L21834: # print "Brief descriptions."
        &write_text(&decode_text(21835));
	&newline();
	return(1);
}

sub rtn21850 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21851: &global_var(32, 0);
    L21854: # print "Superbrief descriptions."
        &write_text(&decode_text(21855));
	&newline();
	return(1);
}

sub rtn21874 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L21879: $locv[0] = &get_prop(30, 15);
    L21883: # print "[abbrev 2][abbrev 13]"
        &write_text(&decode_text(21884));
    L21888: goto L21908 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L21892: # print "[abbrev 22]perfect health"
        &write_text(&decode_text(21893));
    L21905: goto L21963;
    L21908: goto L21928 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (5);
    L21912: # print "slightly wounded"
        &write_text(&decode_text(21913));
    L21925: goto L21963;
    L21928: goto L21950 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 4);
    L21934: # print "somewhat wounded"
        &write_text(&decode_text(21935));
    L21947: goto L21963;
    L21950: # print "seriously wounded"
        &write_text(&decode_text(21951));
    L21963: goto L22011 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L21967: # print "[abbrev 3][abbrev 48]will [abbrev 40]cured after "
        &write_text(&decode_text(21968));
    L21984: $stack[@stack] = 5 - unpack('s', pack('s', $locv[0]));
    L21988: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 10;
    L21992: $locv[1] = unpack('s', pack('s', pop(@stack))) + unpack('s', pack('s', &global_var(93)));
    L21996: &write_text(unpack('s', pack('s', $locv[1])));
    L21999: # print " move"
        &write_text(&decode_text(22000));
    L22004: goto L22011 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L22008: &write_zchar(115);
    L22011: goto L22044 if &global_var(91) == 0;
    L22014: # print "[abbrev 10][abbrev 2][abbrev 19]been killed "
        &write_text(&decode_text(22015));
    L22027: goto L22039 unless $t1 = &global_var(91), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L22031: # print "once"
        &write_text(&decode_text(22032));
    L22036: goto L22044;
    L22039: # print "twice"
        &write_text(&decode_text(22040));
    L22044: &write_text(&decode_text(&global_var(7) * 2));
    L22046: return 1;
}

sub rtn22048 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22049: goto L22060 unless $stack[@stack] = get_child(&global_var(115));
    L22053: $stack[@stack] = z_call(27926, \@locv, \@stack, 22059, 0, &global_var(115));
    L22059: return (pop @stack);
    L22060: # print "[abbrev 2][abbrev 13]empty-handed."
        &write_text(&decode_text(22061));
	&newline();
	return(1);
}

sub rtn22076 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22079: $stack[@stack] = z_call(22378, \@locv, \@stack, 22084, 0);
    L22084: # print "^Would [abbrev 8]like [abbrev 12]restart [abbrev 18][abbrev 0]beginning[abbrev 3]restore a saved position[abbrev 3]or end [abbrev 50]sessi[abbrev 59][abbrev 9][abbrev 0]game?^(Type RESTART[abbrev 3]RESTORE[abbrev 3]or QUIT):^ >"
        &write_text(&decode_text(22085));
    L22191: &z_read(&global_var(87), &global_var(55), undef);
    L22195: $locv[0] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L22199: goto L22211 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12948);
    L22205: die "Restart\n";
    L22206: &write_text(&decode_text(&global_var(68) * 2));
    L22208: goto L22084;
    L22211: goto L22233 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12955);
    L22217: goto L22228 unless &restore_state;
    L22219: # print "Ok."
        &write_text(&decode_text(22220));
    L22224: &newline();
    L22225: goto L22084;
    L22228: &write_text(&decode_text(&global_var(68) * 2));
    L22230: goto L22084;
    L22233: goto L22084 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12836, 12822);
    L22242: die "Quit\n";
    L22243: goto L22084;
}

sub rtn22246 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22247: $stack[@stack] = z_call(22276, \@locv, \@stack, 22254, 0, 24852);
    L22254: return 0 if pop(@stack) == 0;
    L22257: die "Quit\n";
    L22258: return 1;
}

sub rtn22260 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22261: $stack[@stack] = z_call(22276, \@locv, \@stack, 22268, 0, 25758);
    L22268: return 0 if pop(@stack) == 0;
    L22271: die "Restart\n";
    L22272: &write_text(&decode_text(&global_var(68) * 2));
    L22274: return 1;
}

sub rtn22276 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22279: $stack[@stack] = z_call(22378, \@locv, \@stack, 22284, 0);
    L22284: &newline();
    L22285: # print "Do [abbrev 8]wish [abbrev 12]"
        &write_text(&decode_text(22286));
    L22296: &write_text(&decode_text($locv[0] * 2));
    L22298: # print "? (Y [abbrev 5]affirmative): "
        &write_text(&decode_text(22299));
    L22317: $stack[@stack] = z_call(22332, \@locv, \@stack, 22322, 0);
    L22322: return 1 unless pop(@stack) == 0;
    L22325: # print "Ok."
        &write_text(&decode_text(22326));
    L22330: &newline();
    L22331: return 0;
}

sub rtn22332 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22333: &write_zchar(62);
    L22336: &z_read(&global_var(87), &global_var(55), undef);
    L22340: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L22344: return 1 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (14068, 14040);
    L22352: return 0;
}

sub rtn22354 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22355: goto L22362 unless &restore_state;
    L22357: # print "Ok."
        &write_text(&decode_text(22358));
	&newline();
	return(1);
    L22362: &write_text(&decode_text(&global_var(68) * 2));
    L22364: return 1;
}

sub rtn22366 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22367: 1; L22368: goto L22374 unless &save_state(22368, \@locv, \@stack);
    L22369: # print "Ok."
        &write_text(&decode_text(22370));
	&newline();
	return(1);
    L22374: &write_text(&decode_text(&global_var(68) * 2));
    L22376: return 1;
}

sub rtn22378 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22379: # print "[abbrev 33]score [abbrev 5]"
        &write_text(&decode_text(22380));
    L22388: &write_text(unpack('s', pack('s', &global_var(1))));
    L22391: # print " ([abbrev 9]350 points)[abbrev 3][abbrev 22]"
        &write_text(&decode_text(22392));
    L22408: &write_text(unpack('s', pack('s', &global_var(2))));
    L22411: # print " move"
        &write_text(&decode_text(22412));
    L22416: goto L22423 if $t1 = &global_var(2), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L22420: &write_zchar(115);
    L22423: # print "[abbrev 10][abbrev 15]gives [abbrev 8][abbrev 0]rank [abbrev 9]"
        &write_text(&decode_text(22424));
    L22438: goto L22454 unless $t1 = &global_var(1), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (350);
    L22444: # print "Master"
        &write_text(&decode_text(22445));
    L22451: goto L22505;
    L22454: goto L22468 unless unpack('s', pack('s', &global_var(1))) > 250;
    L22458: # print "Senior"
        &write_text(&decode_text(22459));
    L22465: goto L22505;
    L22468: goto L22482 unless unpack('s', pack('s', &global_var(1))) > 150;
    L22472: # print "Junior"
        &write_text(&decode_text(22473));
    L22479: goto L22505;
    L22482: goto L22496 unless unpack('s', pack('s', &global_var(1))) > 75;
    L22486: # print "Novice"
        &write_text(&decode_text(22487));
    L22493: goto L22505;
    L22496: # print "Beginning"
        &write_text(&decode_text(22497));
    L22505: # print " Adventurer."
        &write_text(&decode_text(22506));
	&newline();
	return(1);
}

sub rtn22516 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22521: $locv[1] = &get_prop($locv[0], 9);
    L22525: return 0 unless unpack('s', pack('s', $locv[1])) > 0;
    L22529: &global_var(1, unpack('s', pack('s', &global_var(1))) + unpack('s', pack('s', $locv[1])));
    L22533: &put_prop($locv[0], 9, 0);
    L22538: return 1;
}

sub rtn22540 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22541: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(0 + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L22545: $stack[@stack] = pop(@stack) | 1;
    L22549: $PlotzMemory::Memory[$t1 = (0 + 2*8) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L22554: $stack[@stack] = z_call(22586, \@locv, \@stack, 22561, 0, 23090);
    L22561: return (pop @stack);
}

sub rtn22562 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22563: $stack[@stack] = z_call(22586, \@locv, \@stack, 22570, 0, 25738);
    L22570: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(0 + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L22574: $stack[@stack] = pop(@stack) & 65534;
    L22580: $PlotzMemory::Memory[$t1 = (0 + 2*8) & 0xffff] =
        ($t2 = pop(@stack))>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L22585: return 1;
}

sub rtn22586 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22589: # print "Here "
        &write_text(&decode_text(22590));
    L22594: &write_text(&decode_text($locv[0] * 2));
    L22596: # print "s a transcript [abbrev 9]interati[abbrev 59]with"
        &write_text(&decode_text(22597));
    L22619: &newline();
    L22620: $stack[@stack] = z_call(22626, \@locv, \@stack, 22625, 0);
    L22625: return (pop @stack);
}

sub rtn22626 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (17);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22629: # print "MINI-ZORK I: "
        &write_text(&decode_text(22630));
    L22646: &write_text(&decode_text(&global_var(60) * 2));
    L22648: &newline();
    L22649: # print "Copyright (c) 1988 Infocom[abbrev 3]Inc[abbrev 10]All rights reserved.^ZORK [abbrev 5]a registered trademark [abbrev 9]Infocom[abbrev 3]Inc.^Release "
        &write_text(&decode_text(22650));
    L22736: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(0 + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L22740: $stack[@stack] = pop(@stack) & 2047;
    L22746: &write_text(unpack('s', pack('s', pop(@stack))));
    L22749: # print " / Serial number "
        &write_text(&decode_text(22750));
    L22764: goto L22778 if unpack('s', pack('s', ($locv[0] = ($locv[0] + 1) & 0xffff))) > 23;
    L22768: $stack[@stack] = $PlotzMemory::Memory[(0 + $locv[0]) & 0xffff];
    L22772: &write_zchar(pop(@stack));
    L22775: goto L22764;
    L22778: &newline();
    L22779: return 1;
}

sub rtn22780 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22781: # print "Verifying..."
        &write_text(&decode_text(22782));
    L22794: &newline();
    L22795: goto L22806 unless &z_verify();
    L22797: # print "Correct."
        &write_text(&decode_text(22798));
	&newline();
	return(1);
    L22806: &newline();
    L22807: # print "***"
        &write_text(&decode_text(22808));
    L22816: &write_text(&decode_text(&global_var(68) * 2));
    L22818: return 1;
}

sub rtn22820 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22821: &input_stream(1);
    L22824: return 1;
}

sub rtn22826 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22827: goto L22848 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (135);
    L22831: # print "Bad call [abbrev 12]#RND."
        &write_text(&decode_text(22832));
	&newline();
	return(1);
    L22848: $stack[@stack] = 0 - unpack('s', pack('s', &global_var(112)));
    L22852: $stack[@stack] = &z_random(unpack('s', pack('s', pop(@stack))));
    L22856: return 1;
}

sub rtn22858 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22859: &output_stream(4);
    L22862: return 1;
}

sub rtn22864 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22865: &output_stream(-4);
    L22869: return 1;
}

sub rtn22870 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22871: # print "[abbrev 1]"
        &write_text(&decode_text(22872));
    L22874: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L22876: # print " [abbrev 37]sleeping."
        &write_text(&decode_text(22877));
	&newline();
	return(1);
}

sub rtn22888 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22889: goto L22909 if &test_attr(&global_var(59), 30);
    L22893: # print "Fighting a "
        &write_text(&decode_text(22894));
    L22902: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L22904: # print "!?!"
        &write_text(&decode_text(22905));
	&newline();
	return(1);
    L22909: goto L22916 if &global_var(126) == 0;
    L22912: goto L22924 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4);
    L22916: $stack[@stack] = z_call(22954, \@locv, \@stack, 22923, 0, 24716);
    L22923: return (pop @stack);
    L22924: goto L22938 if &global_var(115) == &get_object(&thing_location(&global_var(126), 'parent'));
    L22928: &write_text(&decode_text(&global_var(80) * 2));
    L22930: # print "[abbrev 0]"
        &write_text(&decode_text(22931));
    L22933: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L22935: &write_text(&decode_text(&global_var(7) * 2));
    L22937: return 1;
    L22938: goto L22948 if &test_attr(&global_var(126), 29);
    L22942: $stack[@stack] = z_call(22954, \@locv, \@stack, 22947, 0);
    L22947: return (pop @stack);
    L22948: $stack[@stack] = z_call(33212, \@locv, \@stack, 22953, 0);
    L22953: return (pop @stack);
}

sub rtn22954 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L22957: # print "Trying [abbrev 12]attack a "
        &write_text(&decode_text(22958));
    L22972: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L22974: # print " [abbrev 11]"
        &write_text(&decode_text(22975));
    L22977: goto L22985 if $locv[0] == 0;
    L22980: &write_text(&decode_text($locv[0] * 2));
    L22982: goto L22990;
    L22985: # print "a "
        &write_text(&decode_text(22986));
    L22988: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L22990: # print " [abbrev 5]suicidal."
        &write_text(&decode_text(22991));
	&newline();
	return(1);
}

sub rtn23002 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23003: goto L23036 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (143);
    L23007: goto L23028 if &global_var(0) == &get_object(&thing_location(&global_var(59), 'parent'));
    L23011: # print "[abbrev 1]"
        &write_text(&decode_text(23012));
    L23014: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23016: # print " [abbrev 37][abbrev 59][abbrev 0][abbrev 53]!"
        &write_text(&decode_text(23017));
    L23025: &newline();
    L23026: return 2;
    L23028: return 0 unless 143 == &get_object(&thing_location(30, 'parent'));
    L23032: &write_text(&decode_text(&global_var(99) * 2));
    L23034: return 2;
    L23036: goto L23050 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L23042: $stack[@stack] = z_call(14964, \@locv, \@stack, 23049, 0, 91, &global_var(59));
    L23049: return 1;
    L23050: # print "[abbrev 2][abbrev 19]a theory [abbrev 59]how [abbrev 12]board a "
        &write_text(&decode_text(23051));
    L23071: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23073: # print "[abbrev 3]perhaps?"
        &write_text(&decode_text(23074));
    L23082: &newline();
    L23083: return 2;
}

sub rtn23086 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23089: # print "[abbrev 2][abbrev 13][abbrev 95][abbrev 22][abbrev 0]"
        &write_text(&decode_text(23090));
    L23098: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23100: &write_text(&decode_text(&global_var(7) * 2));
    L23102: &insert_obj(&global_var(115), &global_var(59));
    L23105: $stack[@stack] = &get_prop(&global_var(59), 18);
    L23109: $stack[@stack] = z_call(pop(@stack) * 2, \@locv, \@stack, 23114, 0, 2);
    L23114: return 1;
}

sub rtn23116 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23117: $stack[@stack] = z_call(14964, \@locv, \@stack, 23125, 0, 22, &global_var(59), 109);
    L23125: return (pop @stack);
}

sub rtn23126 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23127: goto L23147 unless &global_var(126) == 0;
    L23130: # print "[abbrev 2]didn't say [abbrev 11]what!"
        &write_text(&decode_text(23131));
	&newline();
	return(1);
    L23147: goto L23155 unless &test_attr(&global_var(126), 25);
    L23151: return 0 if &test_attr(&global_var(126), 19);
    L23155: # print "[abbrev 82]a "
        &write_text(&decode_text(23156));
    L23160: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L23162: # print "??!?"
        &write_text(&decode_text(23163));
	&newline();
	return(1);
}

sub rtn23170 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23171: goto L23271 unless &test_attr(&global_var(59), 26);
    L23176: goto L23184 if &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L23180: goto L23243 unless &global_var(59) == &get_object(&thing_location(&global_var(115), 'parent'));
    L23184: # print "[abbrev 1]"
        &write_text(&decode_text(23185));
    L23187: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23189: # print " catches fire[abbrev 10]Unfortunately[abbrev 3][abbrev 8]were "
        &write_text(&decode_text(23190));
    L23216: goto L23226 unless &global_var(59) == &get_object(&thing_location(&global_var(115), 'parent'));
    L23220: # print "in"
        &write_text(&decode_text(23221));
    L23223: goto L23233;
    L23226: # print "holding"
        &write_text(&decode_text(23227));
    L23233: $stack[@stack] = z_call(28324, \@locv, \@stack, 23240, 0, 25844);
    L23240: goto L23264;
    L23243: # print "[abbrev 1]"
        &write_text(&decode_text(23244));
    L23246: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23248: # print " [abbrev 5]consumed by fire."
        &write_text(&decode_text(23249));
    L23263: &newline();
    L23264: $stack[@stack] = z_call(31496, \@locv, \@stack, 23270, 0, &global_var(59));
    L23270: return (pop @stack);
    L23271: &write_text(&decode_text(&global_var(64) * 2));
    L23273: # print "burn a "
        &write_text(&decode_text(23274));
    L23280: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23282: &write_text(&decode_text(&global_var(7) * 2));
    L23284: return 1;
}

sub rtn23286 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23287: goto L23314 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (173);
    L23291: # print "Climbing [abbrev 0]walls [abbrev 5][abbrev 12]no avail."
        &write_text(&decode_text(23292));
	&newline();
	return(1);
    L23314: goto L23325 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (76, 0, 27);
    L23321: goto L23332 unless &test_attr(&global_var(59), 23);
    L23325: $stack[@stack] = z_call(30150, \@locv, \@stack, 23331, 0, 23);
    L23331: return (pop @stack);
    L23332: &write_text(&decode_text(&global_var(64) * 2));
    L23334: # print "do [abbrev 41]."
        &write_text(&decode_text(23335));
	&newline();
	return(1);
}

sub rtn23342 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23343: goto L23354 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (76, 0, 27);
    L23350: goto L23361 unless &test_attr(&global_var(59), 23);
    L23354: $stack[@stack] = z_call(30150, \@locv, \@stack, 23360, 0, 22);
    L23360: return (pop @stack);
    L23361: &write_text(&decode_text(&global_var(64) * 2));
    L23363: # print "do [abbrev 41]."
        &write_text(&decode_text(23364));
	&newline();
	return(1);
}

sub rtn23370 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23371: &write_text(&decode_text(&global_var(64) * 2));
    L23373: # print "climb on[abbrev 12][abbrev 0]"
        &write_text(&decode_text(23374));
    L23382: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23384: &write_text(&decode_text(&global_var(7) * 2));
    L23386: return 1;
}

sub rtn23388 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23389: goto L23423 if &test_attr(&global_var(59), 18);
    L23393: goto L23423 if &test_attr(&global_var(59), 22);
    L23397: # print "[abbrev 2]must tell me how [abbrev 12]do [abbrev 17][abbrev 12]a "
        &write_text(&decode_text(23398));
    L23418: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23420: &write_text(&decode_text(&global_var(7) * 2));
    L23422: return 1;
    L23423: goto L23458 if &test_attr(&global_var(59), 12);
    L23427: $stack[@stack] = &get_prop(&global_var(59), 11);
    L23431: goto L23458 if pop(@stack) == 0;
    L23434: goto L23455 unless &test_attr(&global_var(59), 10);
    L23438: &clear_attr(&global_var(59), 10);
    L23441: # print "Closed."
        &write_text(&decode_text(23442));
    L23448: &newline();
    L23449: $stack[@stack] = z_call(31514, \@locv, \@stack, 23454, 0);
    L23454: return (pop @stack);
    L23455: &write_text(&decode_text(&global_var(99) * 2));
    L23457: return 1;
    L23458: goto L23484 unless &test_attr(&global_var(59), 22);
    L23462: goto L23481 unless &test_attr(&global_var(59), 10);
    L23466: &clear_attr(&global_var(59), 10);
    L23469: # print "[abbrev 1]"
        &write_text(&decode_text(23470));
    L23472: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23474: # print " [abbrev 5][abbrev 95][abbrev 27]."
        &write_text(&decode_text(23475));
	&newline();
	return(1);
    L23481: &write_text(&decode_text(&global_var(99) * 2));
    L23483: return 1;
    L23484: # print "[abbrev 2][abbrev 47]close [abbrev 41]."
        &write_text(&decode_text(23485));
	&newline();
	return(1);
}

sub rtn23496 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23497: # print "[abbrev 2][abbrev 19]lost [abbrev 4]mind."
        &write_text(&decode_text(23498));
	&newline();
	return(1);
}

sub rtn23510 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23511: &write_text(&decode_text(&global_var(64) * 2));
    L23513: # print "cross [abbrev 41]!"
        &write_text(&decode_text(23514));
	&newline();
	return(1);
}

sub rtn23522 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23523: # print "Such language [abbrev 22]a high-class establishment like this!"
        &write_text(&decode_text(23524));
	&newline();
	return(1);
}

sub rtn23562 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23563: goto L23576 unless &test_attr(&global_var(59), 30);
    L23567: $stack[@stack] = z_call(14964, \@locv, \@stack, 23575, 0, 20, &global_var(59), &global_var(126));
    L23575: return (pop @stack);
    L23576: goto L23678 unless &test_attr(&global_var(59), 26);
    L23581: goto L23678 unless &test_attr(&global_var(126), 29);
    L23586: goto L23619 unless &global_var(59) == &get_object(&thing_location(&global_var(115), 'parent'));
    L23590: # print "Not a bright idea[abbrev 3]since you're [abbrev 22]it."
        &write_text(&decode_text(23591));
	&newline();
	return(1);
    L23619: # print "[abbrev 33]skillful "
        &write_text(&decode_text(23620));
    L23628: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L23630: # print "smanship slices [abbrev 0]"
        &write_text(&decode_text(23631));
    L23643: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23645: # print " [abbrev 31]innumerable slivers [abbrev 24]blow away."
        &write_text(&decode_text(23646));
    L23670: &newline();
    L23671: $stack[@stack] = z_call(31496, \@locv, \@stack, 23677, 0, &global_var(59));
    L23677: return (pop @stack);
    L23678: goto L23716 if &test_attr(&global_var(126), 29);
    L23682: # print "[abbrev 1]"cutting edge" [abbrev 9]a "
        &write_text(&decode_text(23683));
    L23699: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L23701: # print " [abbrev 5]hardly adequate."
        &write_text(&decode_text(23702));
	&newline();
	return(1);
    L23716: # print "Strange concept[abbrev 3]cutting [abbrev 0]"
        &write_text(&decode_text(23717));
    L23737: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L23739: # print "..."
        &write_text(&decode_text(23740));
	&newline();
	return(1);
}

sub rtn23744 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23745: # print "Come on[abbrev 3]now!"
        &write_text(&decode_text(23746));
	&newline();
	return(1);
}

sub rtn23756 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23757: goto L23763 unless &global_var(126) == 0;
    L23760: &global_var(126, 4);
    L23763: goto L23786 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (91);
    L23767: # print "[abbrev 62]no reas[abbrev 59][abbrev 12][abbrev 40]digging [abbrev 21]."
        &write_text(&decode_text(23768));
	&newline();
	return(1);
    L23786: goto L23818 unless &test_attr(&global_var(126), 28);
    L23790: # print "Digging [abbrev 11][abbrev 0]"
        &write_text(&decode_text(23791));
    L23801: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L23803: # print " [abbrev 5]slow [abbrev 6]tedious."
        &write_text(&decode_text(23804));
	&newline();
	return(1);
    L23818: # print "Digging [abbrev 11]a "
        &write_text(&decode_text(23819));
    L23829: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L23831: # print " [abbrev 5]silly."
        &write_text(&decode_text(23832));
	&newline();
	return(1);
}

sub rtn23840 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23841: $stack[@stack] = z_call(23890, \@locv, \@stack, 23846, 0);
    L23846: return (pop @stack);
}

sub rtn23848 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23849: # print "[abbrev 80]peculiar!"
        &write_text(&decode_text(23850));
	&newline();
	return(1);
}

sub rtn23858 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23859: return 0 unless &global_var(59) == &get_object(&thing_location(30, 'parent'));
    L23863: $stack[@stack] = z_call(14964, \@locv, \@stack, 23870, 0, 45, &global_var(59));
    L23870: return 1;
}

sub rtn23872 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23873: $stack[@stack] = z_call(29740, \@locv, \@stack, 23878, 0);
    L23878: return 0 if pop(@stack) == 0;
    L23881: # print "Dropped."
        &write_text(&decode_text(23882));
	&newline();
	return(1);
}

sub rtn23890 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L23893: goto L23936 unless &test_attr(&global_var(59), 20);
    L23897: $stack[@stack] = z_call(31442, \@locv, \@stack, 23903, 0, &global_var(59));
    L23903: goto L23913 unless pop(@stack) == 0;
    L23906: &write_text(&decode_text(&global_var(80) * 2));
    L23908: # print "[abbrev 41]."
        &write_text(&decode_text(23909));
	&newline();
	return(1);
    L23913: goto L23930 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (39);
    L23917: # print "[abbrev 80][abbrev 68][abbrev 8]drink [abbrev 41]?"
        &write_text(&decode_text(23918));
	&newline();
	return(1);
    L23930: $stack[@stack] = z_call(24050, \@locv, \@stack, 23935, 0);
    L23935: return (pop @stack);
    L23936: goto L24024 unless &test_attr(&global_var(59), 21);
    L23941: $locv[0] = get_parent(&global_var(59));
    L23944: goto L23961 if 45 == &get_object(&thing_location(&global_var(59), 'parent'));
    L23948: $stack[@stack] = z_call(31286, \@locv, \@stack, 23954, 0, 3);
    L23954: goto L23961 unless pop(@stack) == 0;
    L23957: goto L23967 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (179);
    L23961: $stack[@stack] = z_call(24050, \@locv, \@stack, 23966, 0);
    L23966: return (pop @stack);
    L23967: $stack[@stack] = z_call(31344, \@locv, \@stack, 23973, 0, $locv[0]);
    L23973: goto L23990 if pop(@stack) == 0;
    L23976: goto L23990 if &global_var(115) == &get_object(&thing_location($locv[0], 'parent'));
    L23980: &write_text(&decode_text(&global_var(80) * 2));
    L23982: # print "[abbrev 0]"
        &write_text(&decode_text(23983));
    L23985: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L23987: &write_text(&decode_text(&global_var(7) * 2));
    L23989: return 1;
    L23990: goto L24018 if &test_attr($locv[0], 10);
    L23994: # print "You'll [abbrev 19][abbrev 12]open [abbrev 0]"
        &write_text(&decode_text(23995));
    L24009: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L24011: # print " first."
        &write_text(&decode_text(24012));
	&newline();
	return(1);
    L24018: $stack[@stack] = z_call(24050, \@locv, \@stack, 24023, 0);
    L24023: return (pop @stack);
    L24024: # print "[abbrev 23]unlikely [abbrev 17][abbrev 0]"
        &write_text(&decode_text(24025));
    L24035: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24037: # print " [abbrev 81]agree [abbrev 11]you."
        &write_text(&decode_text(24038));
	&newline();
	return(1);
}

sub rtn24050 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24051: goto L24070 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L24055: $stack[@stack] = z_call(31286, \@locv, \@stack, 24061, 0, 3);
    L24061: goto L24070 unless pop(@stack) == 0;
    L24064: $stack[@stack] = z_call(31496, \@locv, \@stack, 24070, 0, &global_var(59));
    L24070: # print "[abbrev 70]really hit [abbrev 0]spot."
        &write_text(&decode_text(24071));
	&newline();
	return(1);
}

sub rtn24086 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24087: $stack[@stack] = z_call(30150, \@locv, \@stack, 24093, 0, 21);
    L24093: return (pop @stack);
}

sub rtn24094 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24095: $stack[@stack] = &get_prop(&global_var(59), 7);
    L24099: goto L24110 if pop(@stack) == 0;
    L24102: $stack[@stack] = &get_prop(&global_var(59), 7);
    L24106: &write_text(&decode_text(pop(@stack) * 2));
    L24108: &newline();
    L24109: return 1;
    L24110: goto L24118 if &test_attr(&global_var(59), 18);
    L24114: goto L24128 unless &test_attr(&global_var(59), 22);
    L24118: goto L24128 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (175);
    L24122: $stack[@stack] = z_call(25110, \@locv, \@stack, 24127, 0);
    L24127: return (pop @stack);
    L24128: &write_text(&decode_text(&global_var(83) * 2));
    L24130: # print "special [abbrev 54][abbrev 0]"
        &write_text(&decode_text(24131));
    L24139: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24141: &write_text(&decode_text(&global_var(7) * 2));
    L24143: return 1;
}

sub rtn24144 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24145: goto L24158 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (27, 0);
    L24151: goto L24158 unless 143 == &get_object(&thing_location(30, 'parent'));
    L24155: &global_var(59, 143);
    L24158: goto L24168 unless &global_var(59) == 0;
    L24161: $stack[@stack] = z_call(30150, \@locv, \@stack, 24167, 0, 20);
    L24167: return (pop @stack);
    L24168: goto L24175 if &global_var(59) == &get_object(&thing_location(30, 'parent'));
    L24172: &write_text(&decode_text(&global_var(99) * 2));
    L24174: return 1;
    L24175: goto L24197 unless &test_attr(&global_var(0), 7);
    L24179: &insert_obj(&global_var(115), &global_var(0));
    L24182: # print "[abbrev 2][abbrev 13][abbrev 59][abbrev 4]own [abbrev 64]again."
        &write_text(&decode_text(24183));
	&newline();
	return(1);
    L24197: # print "Getting out [abbrev 21] [abbrev 81][abbrev 40]fatal."
        &write_text(&decode_text(24198));
    L24216: &newline();
    L24217: return 2;
}

sub rtn24220 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24221: # print "What a bizarre concept!"
        &write_text(&decode_text(24222));
	&newline();
	return(1);
}

sub rtn24240 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24241: goto L24281 unless &global_var(126) == 0;
    L24244: $stack[@stack] = z_call(31286, \@locv, \@stack, 24250, 0, 3);
    L24250: goto L24262 if pop(@stack) == 0;
    L24253: $stack[@stack] = z_call(14964, \@locv, \@stack, 24261, 0, 49, &global_var(59), 3);
    L24261: return 1;
    L24262: $stack[@stack] = get_parent(&global_var(115));
    L24265: goto L24278 unless pop(@stack) == &get_object(&thing_location(124, 'parent'));
    L24269: $stack[@stack] = z_call(14964, \@locv, \@stack, 24277, 0, 49, &global_var(59), 124);
    L24277: return 1;
    L24278: &write_text(&decode_text(&global_var(125) * 2));
    L24280: return 1;
    L24281: return 0 if $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L24287: $stack[@stack] = z_call(14964, \@locv, \@stack, 24295, 0, 19, &global_var(126), &global_var(59));
    L24295: return 1;
}

sub rtn24296 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24297: # print "[abbrev 2]may k[abbrev 95]how [abbrev 12]do [abbrev 41][abbrev 3][abbrev 48]I don't."
        &write_text(&decode_text(24298));
	&newline();
	return(1);
}

sub rtn24322 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24325: $locv[0] = get_parent(&global_var(59));
    L24328: goto L24359 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (109, 4);
    L24334: # print "With[abbrev 22]six [abbrev 64][abbrev 9][abbrev 4]head[abbrev 3]hopefully."
        &write_text(&decode_text(24335));
	&newline();
	return(1);
    L24359: goto L24382 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L24363: # print "[abbrev 30]around [abbrev 21] somew[abbrev 21]..."
        &write_text(&decode_text(24364));
	&newline();
	return(1);
    L24382: goto L24395 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (45);
    L24386: # print "[abbrev 2]find it."
        &write_text(&decode_text(24387));
	&newline();
	return(1);
    L24395: goto L24406 unless &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L24399: # print "[abbrev 2][abbrev 19]it."
        &write_text(&decode_text(24400));
	&newline();
	return(1);
    L24406: goto L24423 if &global_var(0) == &get_object(&thing_location(&global_var(59), 'parent'));
    L24410: $stack[@stack] = z_call(31286, \@locv, \@stack, 24416, 0, &global_var(59));
    L24416: goto L24423 unless pop(@stack) == 0;
    L24419: goto L24432 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (179);
    L24423: # print "[abbrev 23]right [abbrev 21]."
        &write_text(&decode_text(24424));
	&newline();
	return(1);
    L24432: goto L24448 unless &test_attr($locv[0], 30);
    L24436: # print "[abbrev 1]"
        &write_text(&decode_text(24437));
    L24439: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L24441: # print " [abbrev 75]it."
        &write_text(&decode_text(24442));
	&newline();
	return(1);
    L24448: goto L24462 unless &test_attr($locv[0], 12);
    L24452: # print "[abbrev 23][abbrev 59][abbrev 0]"
        &write_text(&decode_text(24453));
    L24457: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L24459: &write_text(&decode_text(&global_var(7) * 2));
    L24461: return 1;
    L24462: goto L24476 unless &test_attr($locv[0], 18);
    L24466: # print "[abbrev 23][abbrev 22][abbrev 0]"
        &write_text(&decode_text(24467));
    L24471: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L24473: &write_text(&decode_text(&global_var(7) * 2));
    L24475: return 1;
    L24476: # print "Beats me."
        &write_text(&decode_text(24477));
	&newline();
	return(1);
}

sub rtn24486 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24487: # print "[abbrev 30]nuts!"
        &write_text(&decode_text(24488));
	&newline();
	return(1);
}

sub rtn24494 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24495: $stack[@stack] = z_call(31442, \@locv, \@stack, 24501, 0, &global_var(59));
    L24501: return 0 unless pop(@stack) == 0;
    L24504: # print "That's easy [abbrev 42][abbrev 8][abbrev 12]say since [abbrev 8][abbrev 57]even [abbrev 19][abbrev 0]"
        &write_text(&decode_text(24505));
    L24535: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24537: &write_text(&decode_text(&global_var(7) * 2));
    L24539: return 1;
}

sub rtn24540 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24541: goto L24566 if &test_attr(&global_var(126), 30);
    L24545: &write_text(&decode_text(&global_var(64) * 2));
    L24547: # print "give a "
        &write_text(&decode_text(24548));
    L24554: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24556: # print " [abbrev 12]a "
        &write_text(&decode_text(24557));
    L24561: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L24563: # print "!"
        &write_text(&decode_text(24564));
	&newline();
	return(1);
    L24566: # print "[abbrev 1]"
        &write_text(&decode_text(24567));
    L24569: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L24571: # print " refuses it politely."
        &write_text(&decode_text(24572));
	&newline();
	return(1);
}

sub rtn24588 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24589: # print "Bizarre!"
        &write_text(&decode_text(24590));
	&newline();
	return(1);
}

sub rtn24598 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24599: goto L24665 if &global_var(59) == 0;
    L24603: goto L24631 unless &test_attr(&global_var(59), 30);
    L24607: # print "[abbrev 1]"
        &write_text(&decode_text(24608));
    L24610: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24612: # print " bows [abbrev 63]head [abbrev 22]greeting."
        &write_text(&decode_text(24613));
	&newline();
	return(1);
    L24631: # print "Only schizophrenics say "Hello" [abbrev 12]a "
        &write_text(&decode_text(24632));
    L24660: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24662: &write_text(&decode_text(&global_var(7) * 2));
    L24664: return 1;
    L24665: # print "Good day."
        &write_text(&decode_text(24666));
	&newline();
	return(1);
}

sub rtn24674 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24675: # print "[abbrev 80][abbrev 68][abbrev 8]inflate [abbrev 41]?"
        &write_text(&decode_text(24676));
	&newline();
	return(1);
}

sub rtn24688 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24689: $stack[@stack] = z_call(31764, \@locv, \@stack, 24696, 0, 24226);
    L24696: return (pop @stack);
}

sub rtn24698 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24699: # print "I'd sooner kiss a pig."
        &write_text(&decode_text(24700));
	&newline();
	return(1);
}

sub rtn24718 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24719: goto L24736 unless &test_attr(&global_var(59), 22);
    L24723: # print "Nobody's home."
        &write_text(&decode_text(24724));
	&newline();
	return(1);
    L24736: # print "Why knock [abbrev 59]a "
        &write_text(&decode_text(24737));
    L24747: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24749: # print "?"
        &write_text(&decode_text(24750));
	&newline();
	return(1);
}

sub rtn24752 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24753: goto L24792 unless &test_attr(&global_var(59), 31);
    L24757: goto L24768 if &test_attr(&global_var(59), 19);
    L24761: # print "[abbrev 23][abbrev 35]off."
        &write_text(&decode_text(24762));
	&newline();
	return(1);
    L24768: &clear_attr(&global_var(59), 19);
    L24771: # print "[abbrev 1]"
        &write_text(&decode_text(24772));
    L24774: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24776: # print " [abbrev 5][abbrev 95]off."
        &write_text(&decode_text(24777));
    L24785: &newline();
    L24786: $stack[@stack] = z_call(31514, \@locv, \@stack, 24791, 0);
    L24791: return (pop @stack);
    L24792: &write_text(&decode_text(&global_var(64) * 2));
    L24794: # print "turn [abbrev 17]off."
        &write_text(&decode_text(24795));
	&newline();
	return(1);
}

sub rtn24804 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24805: goto L24854 unless &test_attr(&global_var(59), 31);
    L24809: goto L24822 unless &test_attr(&global_var(59), 19);
    L24813: # print "[abbrev 38][abbrev 5][abbrev 35]on."
        &write_text(&decode_text(24814));
	&newline();
	return(1);
    L24822: &set_attr(&global_var(59), 19);
    L24825: # print "[abbrev 1]"
        &write_text(&decode_text(24826));
    L24828: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24830: # print " [abbrev 5][abbrev 95]on."
        &write_text(&decode_text(24831));
    L24837: &newline();
    L24838: return 0 unless &global_var(38) == 0;
    L24841: &global_var(38, z_call(21626, \@locv, \@stack, 24847, 54, &global_var(0)));
    L24847: &newline();
    L24848: $stack[@stack] = z_call(25076, \@locv, \@stack, 24853, 0);
    L24853: return (pop @stack);
    L24854: goto L24884 unless &test_attr(&global_var(59), 26);
    L24858: # print "If [abbrev 8]wish [abbrev 12]burn [abbrev 0]"
        &write_text(&decode_text(24859));
    L24873: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24875: # print "[abbrev 3]say so."
        &write_text(&decode_text(24876));
	&newline();
	return(1);
    L24884: &write_text(&decode_text(&global_var(64) * 2));
    L24886: # print "turn [abbrev 17]on."
        &write_text(&decode_text(24887));
	&newline();
	return(1);
}

sub rtn24896 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24897: # print "That's pretty weird."
        &write_text(&decode_text(24898));
	&newline();
	return(1);
}

sub rtn24914 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L24919: goto L24961 if &global_var(59) == 0;
    L24922: goto L24948 unless &test_attr(&global_var(59), 30);
    L24926: # print "[abbrev 1]"
        &write_text(&decode_text(24927));
    L24929: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L24931: # print " [abbrev 5][abbrev 74]big [abbrev 12]jump over."
        &write_text(&decode_text(24932));
	&newline();
	return(1);
    L24948: goto L24958 unless &global_var(0) == &get_object(&thing_location(&global_var(59), 'parent'));
    L24952: $stack[@stack] = z_call(26376, \@locv, \@stack, 24957, 0);
    L24957: return (pop @stack);
    L24958: &write_text(&decode_text(&global_var(121) * 2));
    L24960: return 1;
    L24961: $locv[0] = &get_prop_addr(&global_var(0), 22);
    L24965: goto L25033 if $locv[0] == 0;
    L24969: $locv[1] = &get_prop_len($locv[0]);
    L24972: goto L24990 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L24976: goto L25027 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4);
    L24980: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 1) & 0xffff];
    L24984: $stack[@stack] = bracket_var(pop(@stack), \@locv, \@stack);
    L24987: goto L25027 unless pop(@stack) == 0;
    L24990: # print "[abbrev 15]was [abbrev 49]a very safe place [abbrev 12]try jumping[abbrev 10]"
        &write_text(&decode_text(24991));
    L25019: $stack[@stack] = z_call(28324, \@locv, \@stack, 25026, 0, 23730);
    L25026: return (pop @stack);
    L25027: $stack[@stack] = z_call(26376, \@locv, \@stack, 25032, 0);
    L25032: return (pop @stack);
    L25033: $stack[@stack] = z_call(26376, \@locv, \@stack, 25038, 0);
    L25038: return (pop @stack);
}

sub rtn25040 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25041: # print "[abbrev 1]"
        &write_text(&decode_text(25042));
    L25044: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25046: # print " makes no sound."
        &write_text(&decode_text(25047));
	&newline();
	return(1);
}

sub rtn25060 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25061: # print "It"
        &write_text(&decode_text(25062));
    L25064: $stack[@stack] = z_call(14218, \@locv, \@stack, 25070, 0, &global_var(123));
    L25070: &write_text(&decode_text(pop(@stack) * 2));
    L25072: &write_text(&decode_text(&global_var(7) * 2));
    L25074: return 1;
}

sub rtn25076 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25077: $stack[@stack] = z_call(27534, \@locv, \@stack, 25083, 0, 1);
    L25083: return 0 if pop(@stack) == 0;
    L25086: $stack[@stack] = z_call(27652, \@locv, \@stack, 25092, 0, 1);
    L25092: return (pop @stack);
}

sub rtn25094 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25095: &write_text(&decode_text(&global_var(83) * 2));
    L25097: # print "behind [abbrev 0]"
        &write_text(&decode_text(25098));
    L25104: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25106: &write_text(&decode_text(&global_var(7) * 2));
    L25108: return 1;
}

sub rtn25110 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25111: goto L25156 unless &test_attr(&global_var(59), 22);
    L25115: goto L25144 unless &test_attr(&global_var(59), 10);
    L25119: # print "[abbrev 23]open[abbrev 3][abbrev 48][abbrev 8][abbrev 29]see what's beyond."
        &write_text(&decode_text(25120));
	&newline();
	return(1);
    L25144: # print "[abbrev 1]"
        &write_text(&decode_text(25145));
    L25147: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25149: # print " [abbrev 5][abbrev 27]."
        &write_text(&decode_text(25150));
	&newline();
	return(1);
    L25156: goto L25228 unless &test_attr(&global_var(59), 18);
    L25161: goto L25180 unless &test_attr(&global_var(59), 30);
    L25165: &write_text(&decode_text(&global_var(83) * 2));
    L25167: # print "special [abbrev 12][abbrev 40]seen."
        &write_text(&decode_text(25168));
	&newline();
	return(1);
    L25180: $stack[@stack] = z_call(28308, \@locv, \@stack, 25186, 0, &global_var(59));
    L25186: goto L25216 if pop(@stack) == 0;
    L25189: goto L25202 unless $stack[@stack] = get_child(&global_var(59));
    L25193: $stack[@stack] = z_call(27926, \@locv, \@stack, 25199, 0, &global_var(59));
    L25199: return 1 unless pop(@stack) == 0;
    L25202: # print "[abbrev 1]"
        &write_text(&decode_text(25203));
    L25205: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25207: # print " [abbrev 5]empty."
        &write_text(&decode_text(25208));
	&newline();
	return(1);
    L25216: # print "[abbrev 1]"
        &write_text(&decode_text(25217));
    L25219: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25221: # print " [abbrev 5][abbrev 27]."
        &write_text(&decode_text(25222));
	&newline();
	return(1);
    L25228: &write_text(&decode_text(&global_var(64) * 2));
    L25230: # print "look inside a "
        &write_text(&decode_text(25231));
    L25241: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25243: &write_text(&decode_text(&global_var(7) * 2));
    L25245: return 1;
}

sub rtn25246 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25247: &write_text(&decode_text(&global_var(83) * 2));
    L25249: # print "[abbrev 48]dust t[abbrev 21]."
        &write_text(&decode_text(25250));
	&newline();
	return(1);
}

sub rtn25258 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25259: $stack[@stack] = z_call(31764, \@locv, \@stack, 25266, 0, 24775);
    L25266: return (pop @stack);
}

sub rtn25268 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25269: &write_text(&decode_text(&global_var(64) * 2));
    L25271: # print "do [abbrev 41]."
        &write_text(&decode_text(25272));
	&newline();
	return(1);
}

sub rtn25278 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25279: $stack[@stack] = z_call(31442, \@locv, \@stack, 25285, 0, &global_var(59));
    L25285: return 0 if pop(@stack) == 0;
    L25288: # print "Moved."
        &write_text(&decode_text(25289));
	&newline();
	return(1);
}

sub rtn25296 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25297: goto L25325 unless &test_attr(&global_var(59), 17);
    L25301: # print "Moving [abbrev 0]"
        &write_text(&decode_text(25302));
    L25310: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25312: # print " reveals nothing."
        &write_text(&decode_text(25313));
	&newline();
	return(1);
    L25325: &write_text(&decode_text(&global_var(64) * 2));
    L25327: # print "move [abbrev 0]"
        &write_text(&decode_text(25328));
    L25334: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25336: &write_text(&decode_text(&global_var(7) * 2));
    L25338: return 1;
}

sub rtn25340 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25341: goto L25348 if &global_var(126) == 0;
    L25344: return 0 if &test_attr(&global_var(126), 29);
    L25348: # print "Trying [abbrev 12]destroy [abbrev 0]"
        &write_text(&decode_text(25349));
    L25363: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25365: # print " [abbrev 11]"
        &write_text(&decode_text(25366));
    L25368: goto L25383 unless &global_var(126) == 0;
    L25371: # print "[abbrev 4]b[abbrev 13]hands"
        &write_text(&decode_text(25372));
    L25380: goto L25388;
    L25383: # print "a "
        &write_text(&decode_text(25384));
    L25386: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L25388: # print " [abbrev 5]futile."
        &write_text(&decode_text(25389));
	&newline();
	return(1);
}

sub rtn25398 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25399: goto L25411 unless &test_attr(&global_var(59), 30);
    L25403: $stack[@stack] = z_call(14964, \@locv, \@stack, 25410, 0, 20, &global_var(59));
    L25410: return 1;
    L25411: # print "Nice try."
        &write_text(&decode_text(25412));
	&newline();
	return(1);
}

sub rtn25420 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25421: goto L25510 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L25426: goto L25510 unless &global_var(0) == &get_object(&thing_location(137, 'parent'));
    L25431: goto L25510 unless &global_var(6) == 0;
    L25435: $stack[@stack] = z_call(15178, \@locv, \@stack, 25442, 0, 22284);
    L25442: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L25447: &global_var(6, 1);
    L25450: &global_var(76, 1);
    L25453: &remove_obj(137);
    L25455: # print "[abbrev 1][abbrev 67][abbrev 3]hearing [abbrev 0]name [abbrev 9][abbrev 63]father's deadly nemesis[abbrev 3]flees by crashing [abbrev 20][abbrev 0][abbrev 65]wall."
        &write_text(&decode_text(25456));
	&newline();
	return(1);
    L25510: # print "Wasn't he a sailor?"
        &write_text(&decode_text(25511));
	&newline();
	return(1);
}

sub rtn25528 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25533: goto L25648 unless &test_attr(&global_var(59), 18);
    L25538: goto L25648 if &test_attr(&global_var(59), 12);
    L25543: $stack[@stack] = &get_prop(&global_var(59), 11);
    L25547: goto L25648 if pop(@stack) == 0;
    L25551: goto L25564 unless &test_attr(&global_var(59), 10);
    L25555: # print "[abbrev 38][abbrev 5][abbrev 35]open."
        &write_text(&decode_text(25556));
	&newline();
	return(1);
    L25564: &set_attr(&global_var(59), 10);
    L25567: &set_attr(&global_var(59), 13);
    L25570: goto L25578 unless $stack[@stack] = get_child(&global_var(59));
    L25574: goto L25585 unless &test_attr(&global_var(59), 8);
    L25578: # print "Opened."
        &write_text(&decode_text(25579));
	&newline();
	return(1);
    L25585: goto L25621 unless $locv[0] = get_child(&global_var(59));
    L25589: goto L25621 if $stack[@stack] = get_sibling($locv[0]);
    L25593: goto L25621 if &test_attr($locv[0], 13);
    L25597: $locv[1] = &get_prop($locv[0], 10);
    L25601: goto L25621 if $locv[1] == 0;
    L25604: # print "[abbrev 1]"
        &write_text(&decode_text(25605));
    L25607: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25609: # print " opens."
        &write_text(&decode_text(25610));
    L25616: &newline();
    L25617: &write_text(&decode_text($locv[1] * 2));
    L25619: &newline();
    L25620: return 1;
    L25621: # print "Opening [abbrev 0]"
        &write_text(&decode_text(25622));
    L25630: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25632: # print " reveals "
        &write_text(&decode_text(25633));
    L25639: $stack[@stack] = z_call(27846, \@locv, \@stack, 25645, 0, &global_var(59));
    L25645: &write_text(&decode_text(&global_var(7) * 2));
    L25647: return 1;
    L25648: goto L25682 unless &test_attr(&global_var(59), 22);
    L25652: goto L25665 unless &test_attr(&global_var(59), 10);
    L25656: # print "[abbrev 38][abbrev 5][abbrev 35]open."
        &write_text(&decode_text(25657));
	&newline();
	return(1);
    L25665: # print "[abbrev 1]"
        &write_text(&decode_text(25666));
    L25668: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25670: # print " opens."
        &write_text(&decode_text(25671));
    L25677: &newline();
    L25678: &set_attr(&global_var(59), 10);
    L25681: return 1;
    L25682: # print "[abbrev 2]must tell me how [abbrev 12]do [abbrev 17][abbrev 12]a "
        &write_text(&decode_text(25683));
    L25703: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L25705: &write_text(&decode_text(&global_var(7) * 2));
    L25707: return 1;
}

sub rtn25708 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25709: &write_text(&decode_text(&global_var(64) * 2));
    L25711: # print "pick [abbrev 41]."
        &write_text(&decode_text(25712));
	&newline();
	return(1);
}

sub rtn25718 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25719: goto L25807 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L25724: goto L25760 unless &test_attr(&global_var(126), 25);
    L25728: goto L25760 unless &test_attr(&global_var(126), 19);
    L25732: # print "[abbrev 1]"
        &write_text(&decode_text(25733));
    L25735: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L25737: # print " [abbrev 5]extinguished."
        &write_text(&decode_text(25738));
    L25750: &newline();
    L25751: &clear_attr(&global_var(126), 19);
    L25754: &clear_attr(&global_var(126), 25);
    L25757: goto L25795;
    L25760: # print "[abbrev 1][abbrev 43]spills over [abbrev 0]"
        &write_text(&decode_text(25761));
    L25773: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L25775: # print "[abbrev 3][abbrev 12][abbrev 0]floor[abbrev 3][abbrev 6]evaporates."
        &write_text(&decode_text(25776));
    L25794: &newline();
    L25795: $stack[@stack] = z_call(31496, \@locv, \@stack, 25801, 0, &global_var(59));
    L25801: $stack[@stack] = z_call(31514, \@locv, \@stack, 25806, 0);
    L25806: return (pop @stack);
    L25807: &write_text(&decode_text(&global_var(64) * 2));
    L25809: # print "pour [abbrev 41]."
        &write_text(&decode_text(25810));
	&newline();
	return(1);
}

sub rtn25816 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25817: goto L25835 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (24);
    L25821: &global_var(1, unpack('s', pack('s', &global_var(1))) + unpack('s', pack('s', &global_var(44))));
    L25825: &global_var(44, 0);
    L25828: $stack[@stack] = z_call(29852, \@locv, \@stack, 25834, 0, 114);
    L25834: return (pop @stack);
    L25835: # print "If [abbrev 8]pray enough[abbrev 3][abbrev 4]prayers may [abbrev 40]answered."
        &write_text(&decode_text(25836));
	&newline();
	return(1);
}

sub rtn25866 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25867: goto L25886 if &global_var(126) == 0;
    L25870: goto L25886 if $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (77);
    L25874: # print "[abbrev 82]a "
        &write_text(&decode_text(25875));
    L25879: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L25881: # print "!?!"
        &write_text(&decode_text(25882));
	&newline();
	return(1);
    L25886: goto L25899 unless &global_var(115) == &get_object(&thing_location(77, 'parent'));
    L25890: $stack[@stack] = z_call(14964, \@locv, \@stack, 25898, 0, 22, &global_var(59), 77);
    L25898: return (pop @stack);
    L25899: # print "[abbrev 23][abbrev 49]clear how."
        &write_text(&decode_text(25900));
	&newline();
	return(1);
}

sub rtn25910 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25911: $stack[@stack] = z_call(31764, \@locv, \@stack, 25918, 0, 23854);
    L25918: return (pop @stack);
}

sub rtn25920 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25921: return 0 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L25927: $stack[@stack] = z_call(24494, \@locv, \@stack, 25932, 0);
    L25932: return (pop @stack);
}

sub rtn25934 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L25941: goto L25966 if &test_attr(&global_var(126), 10);
    L25945: goto L25966 if &test_attr(&global_var(126), 22);
    L25949: goto L25966 if &test_attr(&global_var(126), 18);
    L25953: goto L25966 if &test_attr(&global_var(126), 27);
    L25957: &write_text(&decode_text(&global_var(64) * 2));
    L25959: # print "do [abbrev 41]."
        &write_text(&decode_text(25960));
	&newline();
	return(1);
    L25966: goto L25985 if &test_attr(&global_var(126), 10);
    L25970: &global_var(122, &global_var(126));
    L25973: # print "[abbrev 1]"
        &write_text(&decode_text(25974));
    L25976: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L25978: # print " [abbrev 37]open."
        &write_text(&decode_text(25979));
	&newline();
	return(1);
    L25985: goto L26000 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(59));
    L25989: # print "[abbrev 80][abbrev 68][abbrev 8]do [abbrev 41]?"
        &write_text(&decode_text(25990));
	&newline();
	return(1);
    L26000: goto L26007 unless &global_var(126) == &get_object(&thing_location(&global_var(59), 'parent'));
    L26004: &write_text(&decode_text(&global_var(99) * 2));
    L26006: return 1;
    L26007: $locv[2] = z_call(29816, \@locv, \@stack, 26013, 3, &global_var(126));
    L26013: $stack[@stack] = z_call(29816, \@locv, \@stack, 26019, 0, &global_var(59));
    L26019: $locv[1] = unpack('s', pack('s', $locv[2])) + unpack('s', pack('s', pop(@stack)));
    L26023: $stack[@stack] = &get_prop(&global_var(126), 13);
    L26027: $locv[0] = unpack('s', pack('s', $locv[1])) - unpack('s', pack('s', pop(@stack)));
    L26031: $stack[@stack] = &get_prop(&global_var(126), 11);
    L26035: goto L26048 unless unpack('s', pack('s', $locv[0])) > unpack('s', pack('s', pop(@stack)));
    L26039: # print "[abbrev 62]no room."
        &write_text(&decode_text(26040));
	&newline();
	return(1);
    L26048: $stack[@stack] = z_call(31442, \@locv, \@stack, 26054, 0, &global_var(59));
    L26054: goto L26071 unless pop(@stack) == 0;
    L26057: goto L26071 unless &test_attr(&global_var(59), 11);
    L26061: &write_text(&decode_text(&global_var(80) * 2));
    L26063: # print "[abbrev 0]"
        &write_text(&decode_text(26064));
    L26066: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26068: &write_text(&decode_text(&global_var(7) * 2));
    L26070: return 1;
    L26071: $stack[@stack] = z_call(31442, \@locv, \@stack, 26077, 0, &global_var(59));
    L26077: goto L26088 unless pop(@stack) == 0;
    L26080: $stack[@stack] = z_call(29480, \@locv, \@stack, 26085, 0);
    L26085: return 1 if pop(@stack) == 0;
    L26088: &insert_obj(&global_var(59), &global_var(126));
    L26091: &set_attr(&global_var(59), 13);
    L26094: $stack[@stack] = z_call(22516, \@locv, \@stack, 26100, 0, &global_var(59));
    L26100: # print "Done."
        &write_text(&decode_text(26101));
	&newline();
	return(1);
}

sub rtn26108 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26109: goto L26121 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (129);
    L26113: $stack[@stack] = z_call(14964, \@locv, \@stack, 26120, 0, 41, &global_var(59));
    L26120: return 1;
    L26121: goto L26131 unless &test_attr(&global_var(126), 12);
    L26125: $stack[@stack] = z_call(25934, \@locv, \@stack, 26130, 0);
    L26130: return (pop @stack);
    L26131: # print "[abbrev 62]no good surface [abbrev 59][abbrev 0]"
        &write_text(&decode_text(26132));
    L26148: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L26150: &write_text(&decode_text(&global_var(7) * 2));
    L26152: return 1;
}

sub rtn26154 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26155: $stack[@stack] = z_call(25258, \@locv, \@stack, 26160, 0);
    L26160: return (pop @stack);
}

sub rtn26162 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26163: return 0 unless &global_var(38) == 0;
    L26166: &write_text(&decode_text(&global_var(57) * 2));
    L26168: return 1;
}

sub rtn26170 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26171: goto L26183 unless &test_attr(&global_var(59), 16);
    L26175: $stack[@stack] = &get_prop(&global_var(59), 7);
    L26179: &write_text(&decode_text(pop(@stack) * 2));
    L26181: &newline();
    L26182: return 1;
    L26183: # print "[abbrev 80]does [abbrev 94]read a "
        &write_text(&decode_text(26184));
    L26196: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26198: # print "?"
        &write_text(&decode_text(26199));
	&newline();
	return(1);
}

sub rtn26202 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26203: $stack[@stack] = z_call(14964, \@locv, \@stack, 26210, 0, 79, &global_var(59));
    L26210: return 1;
}

sub rtn26212 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26213: # print "[abbrev 38]could very well [abbrev 40][abbrev 74]late!"
        &write_text(&decode_text(26214));
	&newline();
	return(1);
}

sub rtn26234 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26235: # print "How[abbrev 3]exactly[abbrev 3][abbrev 68][abbrev 8]ring [abbrev 41]?"
        &write_text(&decode_text(26236));
	&newline();
	return(1);
}

sub rtn26256 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26257: $stack[@stack] = z_call(31764, \@locv, \@stack, 26264, 0, 25038);
    L26264: return (pop @stack);
}

sub rtn26266 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26269: goto L26281 unless &global_var(29) == 0;
    L26272: # print "Say what?"
        &write_text(&decode_text(26273));
	&newline();
	return(1);
    L26281: &global_var(102, 0);
    L26284: $locv[0] = z_call(31314, \@locv, \@stack, 26291, 1, &global_var(0), 30);
    L26291: goto L26323 if $locv[0] == 0;
    L26294: # print "[abbrev 2]must address [abbrev 0]"
        &write_text(&decode_text(26295));
    L26307: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L26309: # print " directly."
        &write_text(&decode_text(26310));
    L26318: &newline();
    L26319: &global_var(29, 0);
    L26322: return 1;
    L26323: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(55) + 2*&global_var(29)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L26327: return 1 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (11779);
    L26333: &global_var(29, 0);
    L26336: &write_text(&decode_text(&global_var(131) * 2));
    L26338: return 1;
}

sub rtn26340 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26341: # print "[abbrev 2]find nothing unusual."
        &write_text(&decode_text(26342));
	&newline();
	return(1);
}

sub rtn26358 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26359: $stack[@stack] = z_call(14964, \@locv, \@stack, 26367, 0, 52, &global_var(126), &global_var(59));
    L26367: return 1;
}

sub rtn26368 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26369: # print "Shaken."
        &write_text(&decode_text(26370));
	&newline();
	return(1);
}

sub rtn26376 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26377: # print "Wheeeeeeeeee!!!!!"
        &write_text(&decode_text(26378));
	&newline();
	return(1);
}

sub rtn26394 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26395: # print "[abbrev 38]smells like a "
        &write_text(&decode_text(26396));
    L26408: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26410: &write_text(&decode_text(&global_var(7) * 2));
    L26412: return 1;
}

sub rtn26414 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26417: $locv[0] = z_call(31314, \@locv, \@stack, 26424, 1, 30, 29);
    L26424: goto L26436 if $locv[0] == 0;
    L26427: $stack[@stack] = z_call(14964, \@locv, \@stack, 26435, 0, 20, &global_var(59), $locv[0]);
    L26435: return 1;
    L26436: # print "Do [abbrev 8]propose [abbrev 12]stab [abbrev 0]"
        &write_text(&decode_text(26437));
    L26453: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26455: # print " [abbrev 11][abbrev 4]pinky?"
        &write_text(&decode_text(26456));
	&newline();
	return(1);
}

sub rtn26464 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26465: goto L26518 unless &test_attr(&global_var(59), 30);
    L26469: # print "[abbrev 2]aren't versed [abbrev 22]hand-to-h[abbrev 6]combat; you'd better use a weapon."
        &write_text(&decode_text(26470));
	&newline();
	return(1);
    L26518: $stack[@stack] = z_call(14964, \@locv, \@stack, 26525, 0, 18, &global_var(59));
    L26525: return 1;
}

sub rtn26526 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26527: # print "Swimming [abbrev 37]allowed [abbrev 22][abbrev 0]"
        &write_text(&decode_text(26528));
    L26544: goto L26558 if &global_var(59) == 0;
    L26547: goto L26558 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L26553: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26555: # print "."
        &write_text(&decode_text(26556));
	&newline();
	return(1);
    L26558: # print "dungeon."
        &write_text(&decode_text(26559));
	&newline();
	return(1);
}

sub rtn26566 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26567: goto L26577 unless &global_var(126) == 0;
    L26570: # print "Whoosh!"
        &write_text(&decode_text(26571));
	&newline();
	return(1);
    L26577: $stack[@stack] = z_call(14964, \@locv, \@stack, 26585, 0, 20, &global_var(126), &global_var(59));
    L26585: return (pop @stack);
}

sub rtn26586 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26587: goto L26594 unless &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L26591: &write_text(&decode_text(&global_var(105) * 2));
    L26593: return 1;
    L26594: $stack[@stack] = get_parent(&global_var(59));
    L26597: goto L26631 unless &test_attr(pop(@stack), 18);
    L26601: $stack[@stack] = get_parent(&global_var(59));
    L26604: goto L26631 if &test_attr(pop(@stack), 10);
    L26608: &write_text(&decode_text(&global_var(64) * 2));
    L26610: # print "reach inside a [abbrev 27] container."
        &write_text(&decode_text(26611));
	&newline();
	return(1);
    L26631: goto L26670 if &global_var(126) == 0;
    L26634: goto L26642 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (129);
    L26638: &global_var(126, 0);
    L26641: return 0;
    L26642: $stack[@stack] = get_parent(&global_var(59));
    L26645: goto L26666 if $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (pop(@stack));
    L26649: # print "[abbrev 1]"
        &write_text(&decode_text(26650));
    L26652: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26654: # print " [abbrev 37][abbrev 22][abbrev 0]"
        &write_text(&decode_text(26655));
    L26661: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L26663: &write_text(&decode_text(&global_var(7) * 2));
    L26665: return 1;
    L26666: &global_var(126, 0);
    L26669: return 0;
    L26670: return 0 unless &global_var(59) == &get_object(&thing_location(30, 'parent'));
    L26674: # print "[abbrev 30][abbrev 22]it!"
        &write_text(&decode_text(26675));
	&newline();
	return(1);
}

sub rtn26682 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26683: $stack[@stack] = z_call(29480, \@locv, \@stack, 26688, 0);
    L26688: return 0 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L26692: # print "Taken."
        &write_text(&decode_text(26693));
	&newline();
	return(1);
}

sub rtn26700 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26701: goto L26744 unless &test_attr(&global_var(59), 30);
    L26705: goto L26716 if &global_var(29) == 0;
    L26708: &global_var(115, &global_var(59));
    L26711: &global_var(0, get_parent(&global_var(115)));
    L26714: return &global_var(0);
    L26716: # print "[abbrev 1]"
        &write_text(&decode_text(26717));
    L26719: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26721: # print " suggests [abbrev 17][abbrev 8]reread [abbrev 4]manual."
        &write_text(&decode_text(26722));
	&newline();
	return(1);
    L26744: &write_text(&decode_text(&global_var(64) * 2));
    L26746: # print "talk [abbrev 12][abbrev 0]"
        &write_text(&decode_text(26747));
    L26753: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26755: &write_zchar(33);
    L26758: &newline();
    L26759: &global_var(102, 0);
    L26762: &global_var(29, 0);
    L26765: return 2;
}

sub rtn26768 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26771: goto L26791 unless &test_attr(&global_var(59), 22);
    L26775: $locv[0] = z_call(31458, \@locv, \@stack, 26781, 1, &global_var(59));
    L26781: goto L26791 if $locv[0] == 0;
    L26784: $stack[@stack] = z_call(30150, \@locv, \@stack, 26790, 0, $locv[0]);
    L26790: return (pop @stack);
    L26791: goto L26803 unless &test_attr(&global_var(59), 27);
    L26795: $stack[@stack] = z_call(14964, \@locv, \@stack, 26802, 0, 24, &global_var(59));
    L26802: return 1;
    L26803: goto L26839 if &test_attr(&global_var(59), 17);
    L26807: # print "[abbrev 2]hit [abbrev 4]head [abbrev 90][abbrev 0]"
        &write_text(&decode_text(26808));
    L26820: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26822: # print " as [abbrev 8]attempt [abbrev 50]feat."
        &write_text(&decode_text(26823));
	&newline();
	return(1);
    L26839: goto L26866 unless &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L26843: # print "[abbrev 70][abbrev 81]involve quite a contortion!"
        &write_text(&decode_text(26844));
	&newline();
	return(1);
    L26866: $stack[@stack] = z_call(14218, \@locv, \@stack, 26872, 0, &global_var(107));
    L26872: &write_text(&decode_text(pop(@stack) * 2));
    L26874: &newline();
    L26875: return 1;
}

sub rtn26876 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L26877: $stack[@stack] = z_call(29740, \@locv, \@stack, 26882, 0);
    L26882: goto L27056 if pop(@stack) == 0;
    L26886: goto L27005 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L26891: # print "[abbrev 1]"
        &write_text(&decode_text(26892));
    L26894: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L26896: # print " conks [abbrev 8][abbrev 22][abbrev 0]head[abbrev 10]Normally[abbrev 3][abbrev 50]wouldn't do much damage[abbrev 3][abbrev 48][abbrev 8]fall over backwards trying [abbrev 12]duck [abbrev 6]break [abbrev 4]neck[abbrev 3]justice being swift [abbrev 6]merciful [abbrev 22]"
        &write_text(&decode_text(26897));
    L26995: &write_text(&decode_text(&global_var(60) * 2));
    L26997: $stack[@stack] = z_call(28324, \@locv, \@stack, 27004, 0, 25987);
    L27004: return (pop @stack);
    L27005: goto L27049 if &global_var(126) == 0;
    L27008: goto L27049 unless &test_attr(&global_var(126), 30);
    L27012: # print "[abbrev 1]"
        &write_text(&decode_text(27013));
    L27015: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L27017: # print " ducks as [abbrev 0]"
        &write_text(&decode_text(27018));
    L27026: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L27028: # print " flies by [abbrev 6]crashes [abbrev 12][abbrev 0][abbrev 53]."
        &write_text(&decode_text(27029));
	&newline();
	return(1);
    L27049: # print "Thrown."
        &write_text(&decode_text(27050));
	&newline();
	return(1);
    L27056: # print "Huh?"
        &write_text(&decode_text(27057));
	&newline();
	return(1);
}

sub rtn27062 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27063: &write_text(&decode_text(&global_var(64) * 2));
    L27065: # print "throw anything off [abbrev 9][abbrev 41]!"
        &write_text(&decode_text(27066));
	&newline();
	return(1);
}

sub rtn27084 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27085: goto L27110 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L27089: &write_text(&decode_text(&global_var(64) * 2));
    L27091: # print "tie anything [abbrev 12]yourself."
        &write_text(&decode_text(27092));
	&newline();
	return(1);
    L27110: &write_text(&decode_text(&global_var(64) * 2));
    L27112: # print "tie [abbrev 0]"
        &write_text(&decode_text(27113));
    L27117: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L27119: # print " [abbrev 12][abbrev 41]."
        &write_text(&decode_text(27120));
	&newline();
	return(1);
}

sub rtn27126 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27127: # print "[abbrev 82]a "
        &write_text(&decode_text(27128));
    L27132: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L27134: # print "!?!"
        &write_text(&decode_text(27135));
	&newline();
	return(1);
}

sub rtn27140 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27141: goto L27174 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (27, 0);
    L27147: goto L27174 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (75);
    L27151: # print "[abbrev 33]b[abbrev 13]hands [abbrev 57]appear [abbrev 12][abbrev 40]enough."
        &write_text(&decode_text(27152));
	&newline();
	return(1);
    L27174: return 0 if &test_attr(&global_var(59), 15);
    L27178: &write_text(&decode_text(&global_var(64) * 2));
    L27180: # print "turn [abbrev 41]!"
        &write_text(&decode_text(27181));
	&newline();
	return(1);
}

sub rtn27188 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27189: # print "[abbrev 15][abbrev 75]no effect."
        &write_text(&decode_text(27190));
	&newline();
	return(1);
}

sub rtn27200 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27201: $stack[@stack] = z_call(25060, \@locv, \@stack, 27206, 0);
    L27206: return (pop @stack);
}

sub rtn27208 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27209: # print "[abbrev 15][abbrev 47][abbrev 40]tied[abbrev 3]so it [abbrev 47][abbrev 40]untied!"
        &write_text(&decode_text(27210));
	&newline();
	return(1);
}

sub rtn27230 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (3);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27233: # print "Time passes..."
        &write_text(&decode_text(27234));
    L27246: &newline();
    L27247: goto L27260 if unpack('s', pack('s', ($locv[0] = ($locv[0] - 1) & 0xffff))) < 0;
    L27251: $stack[@stack] = z_call(15240, \@locv, \@stack, 27256, 0);
    L27256: goto L27247 if pop(@stack) == 0;
    L27260: &global_var(18, 1);
    L27263: return &global_var(18);
}

sub rtn27266 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27277: goto L27286 unless &global_var(27) == 0;
    L27280: $stack[@stack] = z_call(27474, \@locv, \@stack, 27285, 0);
    L27285: return (pop @stack);
    L27286: $locv[0] = &get_prop_addr(&global_var(0), &global_var(59));
    L27290: goto L27443 if $locv[0] == 0;
    L27294: $locv[1] = &get_prop_len($locv[0]);
    L27297: goto L27312 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L27301: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L27305: $stack[@stack] = z_call(29852, \@locv, \@stack, 27311, 0, pop(@stack));
    L27311: return (pop @stack);
    L27312: goto L27325 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L27316: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L27320: &write_text(&decode_text(pop(@stack) * 2));
    L27322: &newline();
    L27323: return 2;
    L27325: goto L27349 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L27329: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L27333: $locv[4] = z_call(pop(@stack) * 2, \@locv, \@stack, 27337, 5);
    L27337: goto L27347 if $locv[4] == 0;
    L27340: $stack[@stack] = z_call(29852, \@locv, \@stack, 27346, 0, $locv[4]);
    L27346: return (pop @stack);
    L27347: return 2;
    L27349: goto L27390 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4);
    L27353: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 1) & 0xffff];
    L27357: $stack[@stack] = bracket_var(pop(@stack), \@locv, \@stack);
    L27360: goto L27374 if pop(@stack) == 0;
    L27363: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L27367: $stack[@stack] = z_call(29852, \@locv, \@stack, 27373, 0, pop(@stack));
    L27373: return (pop @stack);
    L27374: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L27378: goto L27386 if $locv[2] == 0;
    L27381: &write_text(&decode_text($locv[2] * 2));
    L27383: &newline();
    L27384: return 2;
    L27386: &write_text(&decode_text(&global_var(36) * 2));
    L27388: return 2;
    L27390: return 0 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (5);
    L27394: $locv[3] = $PlotzMemory::Memory[($locv[0] + 1) & 0xffff];
    L27398: goto L27413 unless &test_attr($locv[3], 10);
    L27402: $stack[@stack] = $PlotzMemory::Memory[($locv[0] + 0) & 0xffff];
    L27406: $stack[@stack] = z_call(29852, \@locv, \@stack, 27412, 0, pop(@stack));
    L27412: return (pop @stack);
    L27413: $locv[2] = 256*$PlotzMemory::Memory[$t1=($locv[0] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L27417: goto L27425 if $locv[2] == 0;
    L27420: &write_text(&decode_text($locv[2] * 2));
    L27422: &newline();
    L27423: return 2;
    L27425: # print "[abbrev 1]"
        &write_text(&decode_text(27426));
    L27428: &write_text(&decode_text(&thing_location($locv[3], 'name')));
    L27430: # print " [abbrev 5][abbrev 27]."
        &write_text(&decode_text(27431));
    L27437: &newline();
    L27438: &global_var(122, $locv[3]);
    L27441: return 2;
    L27443: goto L27470 unless &global_var(38) == 0;
    L27446: $stack[@stack] = &z_random(100);
    L27450: goto L27470 unless 80 > unpack('s', pack('s', pop(@stack)));
    L27454: goto L27470 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L27458: goto L27470 if &test_attr(&global_var(0), 3);
    L27462: $stack[@stack] = z_call(28324, \@locv, \@stack, 27469, 0, 22837);
    L27469: return (pop @stack);
    L27470: &write_text(&decode_text(&global_var(36) * 2));
    L27472: return 2;
}

sub rtn27474 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27475: # print "Use compass directions [abbrev 42]movement."
        &write_text(&decode_text(27476));
	&newline();
	return(1);
}

sub rtn27500 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27501: $stack[@stack] = z_call(31764, \@locv, \@stack, 27508, 0, 24782);
    L27508: return (pop @stack);
}

sub rtn27510 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27511: # print "Aaarrrggghhh!"
        &write_text(&decode_text(27512));
	&newline();
	return(1);
}

sub rtn27522 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27523: # print "At [abbrev 4]service!"
        &write_text(&decode_text(27524));
	&newline();
	return(1);
}

sub rtn27534 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27541: goto L27548 unless $locv[0] == 0;
    L27544: goto L27551 unless $t1 = &global_var(32), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L27548: $locv[1] = 1;
    L27551: goto L27591 unless &global_var(38) == 0;
    L27554: # print "[abbrev 38][abbrev 5]pitch black[abbrev 10][abbrev 2][abbrev 13]likely [abbrev 12][abbrev 40]eaten by a grue."
        &write_text(&decode_text(27555));
    L27589: &newline();
    L27590: return 0;
    L27591: goto L27604 if &test_attr(&global_var(0), 13);
    L27595: &set_attr(&global_var(0), 13);
    L27598: $locv[1] = 1;
    L27601: goto L27611;
    L27604: goto L27611 unless &test_attr(&global_var(0), 2);
    L27608: $locv[1] = 1;
    L27611: &write_text(&decode_text(&thing_location(&global_var(0), 'name')));
    L27613: goto L27624 unless 143 == &get_object(&thing_location(30, 'parent'));
    L27617: # print "[abbrev 3][abbrev 22][abbrev 0]"
        &write_text(&decode_text(27618));
    L27622: &write_text(&decode_text(&thing_location(143, 'name')));
    L27624: &newline();
    L27625: return 1 if $locv[1] == 0;
    L27628: $locv[2] = &get_prop(&global_var(0), 14);
    L27632: goto L27640 if $locv[2] == 0;
    L27635: &write_text(&decode_text($locv[2] * 2));
    L27637: goto L27649;
    L27640: $stack[@stack] = &get_prop(&global_var(0), 18);
    L27644: $stack[@stack] = z_call(pop(@stack) * 2, \@locv, \@stack, 27649, 0, 3);
    L27649: &newline();
    L27650: return 1;
}

sub rtn27652 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27655: goto L27697 if &global_var(38) == 0;
    L27658: return 0 unless $stack[@stack] = get_child(&global_var(0));
    L27662: goto L27671 if $locv[0] == 0;
    L27665: $locv[0] = $locv[0];
    L27668: goto L27687;
    L27671: goto L27681 if $t1 = &global_var(32), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L27675: push @stack, 0;
    L27678: goto L27684;
    L27681: push @stack, 1;
    L27684: $locv[0] = pop(@stack);
    L27687: $stack[@stack] = z_call(27926, \@locv, \@stack, 27696, 0, &global_var(0), $locv[0], 65535);
    L27696: return (pop @stack);
    L27697: &write_text(&decode_text(&global_var(57) * 2));
    L27699: return 1;
}

sub rtn27700 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27711: &global_var(37, $locv[0]);
    L27714: goto L27729 unless $locv[2] == 0;
    L27717: $stack[@stack] = &get_prop($locv[0], 6);
    L27721: $stack[@stack] = z_call(pop(@stack) * 2, \@locv, \@stack, 27726, 0, 5);
    L27726: return 1 unless pop(@stack) == 0;
    L27729: goto L27755 unless $locv[2] == 0;
    L27732: goto L27743 if &test_attr($locv[0], 13);
    L27736: $locv[3] = &get_prop($locv[0], 10);
    L27740: goto L27750 unless $locv[3] == 0;
    L27743: $locv[3] = &get_prop($locv[0], 14);
    L27747: goto L27755 if $locv[3] == 0;
    L27750: &write_text(&decode_text($locv[3] * 2));
    L27752: goto L27823;
    L27755: goto L27793 unless $locv[2] == 0;
    L27758: # print "[abbrev 7][abbrev 5]a "
        &write_text(&decode_text(27759));
    L27763: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L27765: # print " [abbrev 21]"
        &write_text(&decode_text(27766));
    L27768: goto L27787 unless &test_attr($locv[0], 19);
    L27772: # print " (providing light)"
        &write_text(&decode_text(27773));
    L27787: &write_zchar(46);
    L27790: goto L27823;
    L27793: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(111) + 2*$locv[2]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L27797: &write_text(&decode_text(pop(@stack) * 2));
    L27799: # print "[abbrev 28]"
        &write_text(&decode_text(27800));
    L27802: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L27804: goto L27823 unless &test_attr($locv[0], 19);
    L27808: # print " (providing light)"
        &write_text(&decode_text(27809));
    L27823: &newline();
    L27824: $stack[@stack] = z_call(28308, \@locv, \@stack, 27830, 0, $locv[0]);
    L27830: return 0 if pop(@stack) == 0;
    L27833: return 0 unless $stack[@stack] = get_child($locv[0]);
    L27837: $stack[@stack] = z_call(27926, \@locv, \@stack, 27845, 0, $locv[0], $locv[1], $locv[2]);
    L27845: return (pop @stack);
}

sub rtn27846 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 1, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27859: return 0 unless $locv[1] = get_child($locv[0]);
    L27863: goto L27867 if $locv[2] = get_sibling($locv[1]);
    L27867: goto L27876 if $locv[3] == 0;
    L27870: $locv[3] = 0;
    L27873: goto L27885;
    L27876: # print "[abbrev 3]"
        &write_text(&decode_text(27877));
    L27879: goto L27885 unless $locv[2] == 0;
    L27882: # print "[abbrev 6]"
        &write_text(&decode_text(27883));
    L27885: # print "a "
        &write_text(&decode_text(27886));
    L27888: &write_text(&decode_text(&thing_location($locv[1], 'name')));
    L27890: goto L27902 unless $locv[4] == 0;
    L27893: goto L27902 unless $locv[5] == 0;
    L27896: $locv[4] = $locv[1];
    L27899: goto L27908;
    L27902: $locv[5] = 1;
    L27905: $locv[4] = 0;
    L27908: $locv[1] = $locv[2];
    L27911: goto L27863 unless $locv[1] == 0;
    L27915: return 1 if $locv[4] == 0;
    L27918: return 1 unless $locv[5] == 0;
    L27921: &global_var(122, $locv[4]);
    L27924: return 1;
}

sub rtn27926 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L27947: return 1 unless $locv[3] = get_child($locv[0]);
    L27951: goto L27958 unless 143 == &get_object(&thing_location(30, 'parent'));
    L27955: $locv[6] = get_parent(&global_var(115));
    L27958: $locv[4] = 1;
    L27961: $locv[5] = 1;
    L27964: $stack[@stack] = get_parent($locv[0]);
    L27967: goto L28011 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0], pop(@stack));
    L27973: $locv[9] = 1;
    L27976: goto L27980 if $locv[3] = get_child($locv[0]);
    L27980: goto L28101 unless $locv[3] == 0;
    L27984: goto L28004 if $locv[8] == 0;
    L27987: goto L28004 if $locv[6] == 0;
    L27990: goto L28004 unless $stack[@stack] = get_child($locv[6]);
    L27994: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L27996: $stack[@stack] = z_call(27926, \@locv, \@stack, 28004, 0, $locv[6], $locv[1], $locv[2]);
    L28004: return 1 if $locv[4] == 0;
    L28007: return 0 unless $locv[5] == 0;
    L28010: return 1;
    L28011: goto L27976 if $locv[3] == 0;
    L28015: goto L28025 unless $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[6]);
    L28019: $locv[8] = 1;
    L28022: goto L28093;
    L28025: goto L28093 if $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L28030: goto L28093 if &test_attr($locv[3], 14);
    L28035: goto L28093 if &test_attr($locv[3], 13);
    L28039: $locv[7] = &get_prop($locv[3], 10);
    L28043: goto L28093 if $locv[7] == 0;
    L28046: goto L28056 if &test_attr($locv[3], 6);
    L28050: &write_text(&decode_text($locv[7] * 2));
    L28052: &newline();
    L28053: $locv[5] = 0;
    L28056: $stack[@stack] = z_call(28308, \@locv, \@stack, 28062, 0, $locv[3]);
    L28062: goto L28093 if pop(@stack) == 0;
    L28065: $stack[@stack] = get_parent($locv[3]);
    L28068: $stack[@stack] = &get_prop(pop(@stack), 6);
    L28072: goto L28093 unless pop(@stack) == 0;
    L28075: goto L28093 unless $stack[@stack] = get_child($locv[3]);
    L28079: $stack[@stack] = z_call(27926, \@locv, \@stack, 28087, 0, $locv[3], $locv[1], 0);
    L28087: goto L28093 if pop(@stack) == 0;
    L28090: $locv[4] = 0;
    L28093: goto L28011 if $locv[3] = get_sibling($locv[3]);
    L28098: goto L28011;
    L28101: goto L28200 if $t1 = $locv[3], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[6], 30);
    L28108: goto L28200 if &test_attr($locv[3], 14);
    L28113: goto L28128 unless $locv[9] == 0;
    L28116: goto L28128 if &test_attr($locv[3], 13);
    L28120: $stack[@stack] = &get_prop($locv[3], 10);
    L28124: goto L28200 unless pop(@stack) == 0;
    L28128: goto L28175 if &test_attr($locv[3], 6);
    L28132: goto L28157 if $locv[4] == 0;
    L28135: $stack[@stack] = z_call(28208, \@locv, \@stack, 28142, 0, $locv[0], $locv[2]);
    L28142: goto L28152 if pop(@stack) == 0;
    L28145: goto L28152 unless unpack('s', pack('s', $locv[2])) < 0;
    L28149: $locv[2] = 0;
    L28152: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L28154: $locv[4] = 0;
    L28157: goto L28164 unless unpack('s', pack('s', $locv[2])) < 0;
    L28161: $locv[2] = 0;
    L28164: $stack[@stack] = z_call(27700, \@locv, \@stack, 28172, 0, $locv[3], $locv[1], $locv[2]);
    L28172: goto L28200;
    L28175: goto L28200 unless $stack[@stack] = get_child($locv[3]);
    L28179: $stack[@stack] = z_call(28308, \@locv, \@stack, 28185, 0, $locv[3]);
    L28185: goto L28200 if pop(@stack) == 0;
    L28188: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L28190: $stack[@stack] = z_call(27926, \@locv, \@stack, 28198, 0, $locv[3], $locv[1], $locv[2]);
    L28198: ($locv[2] = ($locv[2] - 1) & 0xffff);
    L28200: goto L27980 if $locv[3] = get_sibling($locv[3]);
    L28205: goto L27980;
}

sub rtn28208 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28213: goto L28228 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (136);
    L28217: # print "[abbrev 33][abbrev 91]include:"
        &write_text(&decode_text(28218));
	&newline();
	return(1);
    L28228: goto L28239 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L28232: # print "[abbrev 2]have:"
        &write_text(&decode_text(28233));
	&newline();
	return(1);
    L28239: return 0 if 27 == &get_object(&thing_location($locv[0], 'parent'));
    L28243: goto L28253 unless unpack('s', pack('s', $locv[1])) > 0;
    L28247: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(111) + 2*$locv[1]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L28251: &write_text(&decode_text(pop(@stack) * 2));
    L28253: goto L28275 unless &test_attr($locv[0], 12);
    L28257: # print "Sitting [abbrev 59][abbrev 0]"
        &write_text(&decode_text(28258));
    L28268: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L28270: # print " is:"
        &write_text(&decode_text(28271));
	&newline();
	return(1);
    L28275: goto L28293 unless &test_attr($locv[0], 30);
    L28279: # print "[abbrev 1]"
        &write_text(&decode_text(28280));
    L28282: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L28284: # print " [abbrev 5]holding:"
        &write_text(&decode_text(28285));
	&newline();
	return(1);
    L28293: # print "[abbrev 1]"
        &write_text(&decode_text(28294));
    L28296: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L28298: # print " contains:"
        &write_text(&decode_text(28299));
	&newline();
	return(1);
}

sub rtn28308 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28311: return 0 if &test_attr($locv[0], 14);
    L28315: return 1 if &test_attr($locv[0], 8);
    L28319: return 1 if &test_attr($locv[0], 10);
    L28323: return 0;
}

sub rtn28324 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28327: &global_var(115, 30);
    L28330: &write_text(&decode_text($locv[0] * 2));
    L28332: goto L28348 unless &global_var(23) == 0;
    L28335: # print " Bad luck[abbrev 3]huh?"
        &write_text(&decode_text(28336));
    L28348: &newline();
    L28349: goto L28395 if &global_var(88) == 0;
    L28352: # print "^Congratulations[abbrev 10][abbrev 23][abbrev 49]easy [abbrev 12][abbrev 40]killed while [abbrev 35]dead."
        &write_text(&decode_text(28353));
    L28389: &newline();
    L28390: $stack[@stack] = z_call(22076, \@locv, \@stack, 28395, 0);
    L28395: &global_var(1, unpack('s', pack('s', &global_var(1))) - 10);
    L28399: # print " ^    ****  [abbrev 2][abbrev 19]died  **** ^^"
        &write_text(&decode_text(28400));
    L28438: &insert_obj(&global_var(115), &global_var(0));
    L28441: goto L28520 if unpack('s', pack('s', &global_var(91))) < 2;
    L28446: # print "[abbrev 2]clearly [abbrev 13]a suicidal maniac[abbrev 10][abbrev 33]remains will [abbrev 40]put [abbrev 22]Hades [abbrev 42][abbrev 4]fellow adventurers [abbrev 12]gloat over."
        &write_text(&decode_text(28447));
    L28513: &newline();
    L28514: $stack[@stack] = z_call(22076, \@locv, \@stack, 28519, 0);
    L28519: return (pop @stack);
    L28520: &global_var(91, "++");
    L28522: &insert_obj(&global_var(115), &global_var(0));
    L28525: goto L28689 unless &test_attr(24, 13);
    L28530: # print "[abbrev 2]feel relieved [abbrev 9][abbrev 4]burdens [abbrev 6]find yourself before [abbrev 0]gates [abbrev 9]Hell"
        &write_text(&decode_text(28531));
    L28575: goto L28603 unless &global_var(129) == 0;
    L28578: # print "[abbrev 3]w[abbrev 21] [abbrev 0]spirits jeer [abbrev 6]deny [abbrev 8]entry"
        &write_text(&decode_text(28579));
    L28603: # print "[abbrev 10][abbrev 33]senses [abbrev 13]disturbed[abbrev 10]Objects around [abbrev 8]appear indistinct[abbrev 3]bleached [abbrev 9]color[abbrev 3]even unreal."
        &write_text(&decode_text(28604));
    L28666: &newline();
    L28667: &newline();
    L28668: &global_var(88, 1);
    L28671: &global_var(16, 1);
    L28674: &put_prop(&global_var(115), 18, 14470);
    L28680: $stack[@stack] = z_call(29852, \@locv, \@stack, 28686, 0, 29);
    L28686: goto L28759;
    L28689: # print "Well[abbrev 3][abbrev 8][abbrev 71]deserve another chance[abbrev 10]I [abbrev 29]quite fix [abbrev 8]up completely[abbrev 3][abbrev 48][abbrev 8][abbrev 29][abbrev 19]everything."
        &write_text(&decode_text(28690));
    L28748: &newline();
    L28749: &newline();
    L28750: &clear_attr(174, 13);
    L28753: $stack[@stack] = z_call(29852, \@locv, \@stack, 28759, 0, 114);
    L28759: &global_var(29, 0);
    L28762: $stack[@stack] = z_call(28774, \@locv, \@stack, 28767, 0);
    L28767: $stack[@stack] = z_call(28862, \@locv, \@stack, 28772, 0);
    L28772: return 2;
}

sub rtn28774 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28781: goto L28785 if $locv[0] = get_child(27);
    L28785: goto L28792 unless &global_var(115) == &get_object(&thing_location(102, 'parent'));
    L28789: &insert_obj(102, 53);
    L28792: goto L28799 unless &global_var(115) == &get_object(&thing_location(120, 'parent'));
    L28796: &insert_obj(120, 107);
    L28799: goto L28803 if $locv[2] = get_child(&global_var(115));
    L28803: $locv[1] = $locv[2];
    L28806: return 1 if $locv[1] == 0;
    L28809: goto L28813 if $locv[2] = get_sibling($locv[1]);
    L28813: goto L28847 unless &test_attr($locv[1], 4);
    L28817: goto L28839 unless &test_attr($locv[0], 7);
    L28821: goto L28839 if &test_attr($locv[0], 19);
    L28825: $stack[@stack] = &z_random(100);
    L28829: goto L28839 unless 50 > unpack('s', pack('s', pop(@stack)));
    L28833: &insert_obj($locv[1], $locv[0]);
    L28836: goto L28803;
    L28839: goto L28817 if $locv[0] = get_sibling($locv[0]);
    L28844: goto L28817;
    L28847: $stack[@stack] = &z_random(7);
    L28851: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(74) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L28855: &insert_obj($locv[1], pop(@stack));
    L28858: goto L28803;
}

sub rtn28862 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28863: $stack[@stack] = z_call(15178, \@locv, \@stack, 28870, 0, 20494);
    L28870: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28875: $stack[@stack] = z_call(15178, \@locv, \@stack, 28882, 0, 20541);
    L28882: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28887: $stack[@stack] = z_call(15178, \@locv, \@stack, 28894, 0, 22284);
    L28894: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28899: $stack[@stack] = z_call(15178, \@locv, \@stack, 28906, 0, 18322);
    L28906: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28911: $stack[@stack] = z_call(15178, \@locv, \@stack, 28918, 0, 20048);
    L28918: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28923: $stack[@stack] = z_call(15178, \@locv, \@stack, 28930, 0, 19066);
    L28930: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L28935: &clear_attr(12, 19);
    L28938: return 1;
}

sub rtn28940 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L28945: goto L28974 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (102);
    L28949: return 0 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (139);
    L28953: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29);
    L28957: # print "[abbrev 1]draft blows [abbrev 8]back."
        &write_text(&decode_text(28958));
	&newline();
	return(1);
    L28974: return 0 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2, 0, 1);
    L28981: return 0 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (7, 8, 12);
    L28988: return 0 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6, 5);
    L28994: goto L29005 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (100, 36, 20);
    L29001: goto L29026 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (92);
    L29005: # print "Attacks [abbrev 13]va[abbrev 22][abbrev 22][abbrev 4]condition."
        &write_text(&decode_text(29006));
	&newline();
	return(1);
    L29026: goto L29053 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (43, 30, 37);
    L29033: goto L29053 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (35, 22, 39);
    L29040: goto L29053 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (95, 25, 70);
    L29047: goto L29080 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (83, 98);
    L29053: # print "Such acti[abbrev 59][abbrev 5]beyond [abbrev 4]capabilities."
        &write_text(&decode_text(29054));
	&newline();
	return(1);
    L29080: goto L29113 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (99);
    L29084: # print "Might as well[abbrev 10]You've got [abbrev 73]eternity."
        &write_text(&decode_text(29085));
	&newline();
	return(1);
    L29113: goto L29138 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L29117: # print "[abbrev 2]need no light [abbrev 12]guide you."
        &write_text(&decode_text(29118));
	&newline();
	return(1);
    L29138: goto L29165 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (9);
    L29142: # print "[abbrev 30]dead! [abbrev 80][abbrev 68][abbrev 8]think [abbrev 9][abbrev 4]score?"
        &write_text(&decode_text(29143));
	&newline();
	return(1);
    L29165: goto L29184 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (83, 73);
    L29171: # print "[abbrev 33]h[abbrev 6]passes [abbrev 20]it."
        &write_text(&decode_text(29172));
	&newline();
	return(1);
    L29184: goto L29206 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4, 93, 41);
    L29191: # print "[abbrev 2][abbrev 19]no possessions."
        &write_text(&decode_text(29192));
	&newline();
	return(1);
    L29206: goto L29219 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L29210: # print "[abbrev 2][abbrev 13]dead."
        &write_text(&decode_text(29211));
	&newline();
	return(1);
    L29219: goto L29314 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (64);
    L29224: # print "[abbrev 1][abbrev 26]looks unearthly"
        &write_text(&decode_text(29225));
    L29239: goto L29249 if $stack[@stack] = get_child(&global_var(0));
    L29243: &write_zchar(46);
    L29246: goto L29270;
    L29249: # print " [abbrev 6]objects appear indistinct."
        &write_text(&decode_text(29250));
    L29270: goto L29311 if &test_attr(&global_var(0), 19);
    L29274: # print " Although t[abbrev 21] [abbrev 5]no light[abbrev 3][abbrev 0][abbrev 26][abbrev 52]dimly illuminated."
        &write_text(&decode_text(29275));
    L29311: &newline();
    L29312: &newline();
    L29313: return 0;
    L29314: goto L29463 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (75);
    L29319: goto L29448 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (24);
    L29324: &clear_attr(102, 14);
    L29327: &put_prop(&global_var(115), 18, 0);
    L29332: &global_var(88, 0);
    L29335: goto L29342 unless 87 == &get_object(&thing_location(103, 'parent'));
    L29339: &global_var(16, 0);
    L29342: # print "[abbrev 1]sound [abbrev 9]a distant trumpet [abbrev 5]heard[abbrev 10][abbrev 2]find yourself [abbrev 22][abbrev 0]woods[abbrev 3]rising as if [abbrev 18]a long sleep[abbrev 10][abbrev 28]breeze rustles [abbrev 0]treetops; then[abbrev 3]all [abbrev 5]still."
        &write_text(&decode_text(29343));
    L29439: &newline();
    L29440: &newline();
    L29441: $stack[@stack] = z_call(29852, \@locv, \@stack, 29447, 0, 114);
    L29447: return (pop @stack);
    L29448: # print "[abbrev 33]prayers [abbrev 13][abbrev 49]heard."
        &write_text(&decode_text(29449));
	&newline();
	return(1);
    L29463: &write_text(&decode_text(&global_var(64) * 2));
    L29465: # print "even do [abbrev 41]."
        &write_text(&decode_text(29466));
    L29474: &newline();
    L29475: &global_var(29, 0);
    L29478: return 2;
}

sub rtn29480 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (1, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L29491: $stack[@stack] = &get_prop(30, 15);
    L29495: $stack[@stack] = 6 - unpack('s', pack('s', pop(@stack)));
    L29499: $stack[@stack] = unpack('s', pack('s', pop(@stack))) * 10;
    L29503: $locv[3] = 100 - unpack('s', pack('s', pop(@stack)));
    L29507: goto L29528 if &global_var(88) == 0;
    L29510: return 0 if $locv[0] == 0;
    L29513: # print "[abbrev 33]h[abbrev 6]passes [abbrev 20]it."
        &write_text(&decode_text(29514));
    L29526: &newline();
    L29527: return 0;
    L29528: goto L29545 if &test_attr(&global_var(59), 17);
    L29532: return 0 if $locv[0] == 0;
    L29535: $stack[@stack] = z_call(14218, \@locv, \@stack, 29541, 0, &global_var(107));
    L29541: &write_text(&decode_text(pop(@stack) * 2));
    L29543: &newline();
    L29544: return 0;
    L29545: goto L29581 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (170);
    L29549: goto L29581 unless &global_var(0) == &get_object(&thing_location(112, 'parent'));
    L29553: goto L29581 unless &test_attr(&global_var(59), 4);
    L29557: return 0 if $locv[0] == 0;
    L29560: # print "[abbrev 1][abbrev 39]doesn't let [abbrev 8]near."
        &write_text(&decode_text(29561));
    L29579: &newline();
    L29580: return 0;
    L29581: $stack[@stack] = get_parent(&global_var(59));
    L29584: goto L29595 unless &test_attr(pop(@stack), 18);
    L29588: $stack[@stack] = get_parent(&global_var(59));
    L29591: return 0 unless &test_attr(pop(@stack), 10);
    L29595: $stack[@stack] = get_parent(&global_var(59));
    L29598: goto L29672 if &global_var(115) == &get_object(&thing_location(pop(@stack), 'parent'));
    L29603: $locv[4] = z_call(29816, \@locv, \@stack, 29609, 5, &global_var(59));
    L29609: $stack[@stack] = z_call(29816, \@locv, \@stack, 29615, 0, &global_var(115));
    L29615: $stack[@stack] = unpack('s', pack('s', $locv[4])) + unpack('s', pack('s', pop(@stack)));
    L29619: goto L29672 unless unpack('s', pack('s', pop(@stack))) > unpack('s', pack('s', $locv[3]));
    L29623: goto L29670 if $locv[0] == 0;
    L29626: # print "[abbrev 33]load [abbrev 5][abbrev 74]heavy"
        &write_text(&decode_text(29627));
    L29639: goto L29668 unless unpack('s', pack('s', $locv[3])) < 100;
    L29643: # print "[abbrev 3]especially [abbrev 22]light [abbrev 9][abbrev 4]condition"
        &write_text(&decode_text(29644));
    L29668: &write_text(&decode_text(&global_var(7) * 2));
    L29670: return 2;
    L29672: goto L29723 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L29676: $locv[1] = z_call(29794, \@locv, \@stack, 29682, 2, &global_var(115));
    L29682: goto L29723 unless unpack('s', pack('s', $locv[1])) > 7;
    L29686: $locv[4] = unpack('s', pack('s', $locv[1])) * 8;
    L29690: $stack[@stack] = &z_random(100);
    L29694: goto L29723 unless unpack('s', pack('s', $locv[4])) > unpack('s', pack('s', pop(@stack)));
    L29698: # print "[abbrev 30]holding [abbrev 74]many things already!"
        &write_text(&decode_text(29699));
    L29721: &newline();
    L29722: return 0;
    L29723: &insert_obj(&global_var(59), &global_var(115));
    L29726: &clear_attr(&global_var(59), 6);
    L29729: &set_attr(&global_var(59), 13);
    L29732: $stack[@stack] = z_call(22516, \@locv, \@stack, 29738, 0, &global_var(59));
    L29738: return 1;
}

sub rtn29740 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L29741: goto L29762 if &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L29745: $stack[@stack] = get_parent(&global_var(59));
    L29748: goto L29762 if &global_var(115) == &get_object(&thing_location(pop(@stack), 'parent'));
    L29752: &write_text(&decode_text(&global_var(80) * 2));
    L29754: # print "[abbrev 0]"
        &write_text(&decode_text(29755));
    L29757: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L29759: &write_text(&decode_text(&global_var(7) * 2));
    L29761: return 0;
    L29762: goto L29787 if &global_var(115) == &get_object(&thing_location(&global_var(59), 'parent'));
    L29766: $stack[@stack] = get_parent(&global_var(59));
    L29769: goto L29787 if &test_attr(pop(@stack), 10);
    L29773: # print "[abbrev 1]"
        &write_text(&decode_text(29774));
    L29776: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L29778: # print " [abbrev 5][abbrev 27]."
        &write_text(&decode_text(29779));
    L29785: &newline();
    L29786: return 0;
    L29787: $stack[@stack] = get_parent(&global_var(115));
    L29790: &insert_obj(&global_var(59), pop(@stack));
    L29793: return 1;
}

sub rtn29794 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L29801: goto L29807 if $locv[2] = get_child($locv[0]);
    L29805: return $locv[1];
    L29807: ($locv[1] = ($locv[1] + 1) & 0xffff);
    L29809: goto L29807 if $locv[2] = get_sibling($locv[2]);
    L29814: return $locv[1];
}

sub rtn29816 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L29823: goto L29842 unless $locv[1] = get_child($locv[0]);
    L29827: $stack[@stack] = z_call(29816, \@locv, \@stack, 29833, 0, $locv[1]);
    L29833: $locv[2] = unpack('s', pack('s', $locv[2])) + unpack('s', pack('s', pop(@stack)));
    L29837: goto L29827 if $locv[1] = get_sibling($locv[1]);
    L29842: $stack[@stack] = &get_prop($locv[0], 13);
    L29846: $stack[@stack] = unpack('s', pack('s', $locv[2])) + unpack('s', pack('s', pop(@stack)));
    L29850: return (pop @stack);
}

sub rtn29852 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 1, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L29863: $locv[2] = get_parent(&global_var(115));
    L29866: $locv[3] = &global_var(38);
    L29869: $locv[4] = &global_var(0);
    L29872: goto L29901 unless &test_attr($locv[0], 3);
    L29876: goto L29901 if 143 == &get_object(&thing_location(30, 'parent'));
    L29880: &write_text(&decode_text(&global_var(64) * 2));
    L29882: # print "go t[abbrev 21] without a boat."
        &write_text(&decode_text(29883));
    L29899: &newline();
    L29900: return 0;
    L29901: goto L29942 unless &test_attr($locv[0], 7);
    L29905: goto L29942 unless &test_attr(&global_var(0), 7);
    L29909: goto L29942 unless 143 == &get_object(&thing_location(30, 'parent'));
    L29913: # print "You'll [abbrev 19][abbrev 12]get out [abbrev 9][abbrev 0]raft first."
        &write_text(&decode_text(29914));
    L29940: &newline();
    L29941: return 0;
    L29942: goto L29983 unless 143 == &get_object(&thing_location(30, 'parent'));
    L29946: goto L29983 if &test_attr(&global_var(0), 7);
    L29950: goto L29983 unless &test_attr($locv[0], 7);
    L29954: goto L29983 unless &global_var(88) == 0;
    L29957: # print "[abbrev 1]"
        &write_text(&decode_text(29958));
    L29960: &write_text(&decode_text(&thing_location($locv[2], 'name')));
    L29962: # print " comes [abbrev 12]a rest [abbrev 59][abbrev 0]shore."
        &write_text(&decode_text(29963));
    L29981: &newline();
    L29982: &newline();
    L29983: goto L29993 unless 143 == &get_object(&thing_location(30, 'parent'));
    L29987: &insert_obj($locv[2], $locv[0]);
    L29990: goto L29996;
    L29993: &insert_obj(&global_var(115), $locv[0]);
    L29996: &global_var(0, $locv[0]);
    L29999: &global_var(38, z_call(21626, \@locv, \@stack, 30005, 54, &global_var(0)));
    L30005: goto L30068 unless $locv[3] == 0;
    L30009: goto L30068 unless &global_var(38) == 0;
    L30012: $stack[@stack] = &z_random(100);
    L30016: goto L30068 unless 80 > unpack('s', pack('s', pop(@stack)));
    L30020: # print "Oh[abbrev 3]no! [abbrev 28][abbrev 85]grue slit[abbrev 21]d [abbrev 31][abbrev 0]"
        &write_text(&decode_text(30021));
    L30043: goto L30055 unless 143 == &get_object(&thing_location(30, 'parent'));
    L30047: $stack[@stack] = get_parent(&global_var(115));
    L30050: &write_text(&decode_text(&thing_location(pop(@stack), 'name')));
    L30052: goto L30060;
    L30055: # print "room"
        &write_text(&decode_text(30056));
    L30060: $stack[@stack] = z_call(28324, \@locv, \@stack, 30067, 0, 23016);
    L30067: return 1;
    L30068: goto L30098 unless &global_var(38) == 0;
    L30071: goto L30098 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L30075: # print "[abbrev 2][abbrev 19]moved [abbrev 31]a dark place."
        &write_text(&decode_text(30076));
    L30094: &newline();
    L30095: &global_var(29, 0);
    L30098: $stack[@stack] = &get_prop(&global_var(0), 18);
    L30102: $stack[@stack] = z_call(pop(@stack) * 2, \@locv, \@stack, 30107, 0, 2);
    L30107: $stack[@stack] = z_call(22516, \@locv, \@stack, 30113, 0, $locv[0]);
    L30113: return 1 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L30117: goto L30125 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[4]);
    L30121: return 1 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29);
    L30125: return 1 if $locv[1] == 0;
    L30128: return 1 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L30132: $stack[@stack] = z_call(27534, \@locv, \@stack, 30137, 0);
    L30137: return 1 if pop(@stack) == 0;
    L30140: return 1 unless unpack('s', pack('s', &global_var(32))) > 0;
    L30144: $stack[@stack] = z_call(27652, \@locv, \@stack, 30149, 0);
    L30149: return 1;
}

sub rtn30150 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30153: &global_var(27, $locv[0]);
    L30156: $stack[@stack] = z_call(14964, \@locv, \@stack, 30163, 0, 102, $locv[0]);
    L30163: return 1;
}

sub rtn30164 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 1, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30171: goto L30198 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (130);
    L30175: goto L30198 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (130);
    L30179: # print "Those things aren't [abbrev 21]!"
        &write_text(&decode_text(30180));
	&newline();
	return(1);
    L30198: goto L30208 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (130);
    L30202: $locv[0] = &global_var(78);
    L30205: goto L30214;
    L30208: $locv[0] = &global_var(30);
    L30211: $locv[1] = 0;
    L30214: &global_var(29, 0);
    L30217: &global_var(102, 0);
    L30220: goto L30244 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L30224: &write_text(&decode_text(&global_var(64) * 2));
    L30226: # print "see any "
        &write_text(&decode_text(30227));
    L30233: $stack[@stack] = z_call(30284, \@locv, \@stack, 30239, 0, $locv[1]);
    L30239: # print " [abbrev 21]!"
        &write_text(&decode_text(30240));
	&newline();
	return(1);
    L30244: # print "[abbrev 1]"
        &write_text(&decode_text(30245));
    L30247: &write_text(&decode_text(&thing_location(&global_var(115), 'name')));
    L30249: # print " [abbrev 52]confused[abbrev 10]"I [abbrev 57]see any "
        &write_text(&decode_text(30250));
    L30270: $stack[@stack] = z_call(30284, \@locv, \@stack, 30276, 0, $locv[1]);
    L30276: # print " [abbrev 21]!""
        &write_text(&decode_text(30277));
	&newline();
	return(1);
}

sub rtn30284 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30289: goto L30303 if &global_var(114) == 0;
    L30292: goto L30297 if &global_var(70) == 0;
    L30295: &write_text(&decode_text(&global_var(42)));
    L30297: return 0 if &global_var(24) == 0;
    L30300: &write_text(&decode_text(&global_var(24)));
    L30302: return 1;
    L30303: goto L30323 if $locv[0] == 0;
    L30306: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L30310: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*7) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L30314: $stack[@stack] = z_call(19246, \@locv, \@stack, 30322, 0, $locv[1], pop(@stack), 0);
    L30322: return (pop @stack);
    L30323: $locv[1] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*8) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L30327: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(100) + 2*9) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L30331: $stack[@stack] = z_call(19246, \@locv, \@stack, 30339, 0, $locv[1], pop(@stack), 0);
    L30339: return (pop @stack);
}

sub rtn30340 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30341: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29);
    L30345: # print "Up? Down?"
        &write_text(&decode_text(30346));
	&newline();
	return(1);
}

sub rtn30356 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30357: goto L30386 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L30361: &global_var(29, 0);
    L30364: &global_var(102, 0);
    L30367: &write_text(&decode_text(&global_var(64) * 2));
    L30369: # print "talk [abbrev 12][abbrev 0]sailor [abbrev 17]way."
        &write_text(&decode_text(30370));
	&newline();
	return(1);
    L30386: goto L30407 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L30390: # print "[abbrev 7][abbrev 5]no sailor [abbrev 12][abbrev 40]seen."
        &write_text(&decode_text(30391));
	&newline();
	return(1);
    L30407: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (55);
    L30411: &global_var(120, "++");
    L30413: $stack[@stack] = ($t1 = unpack('s', pack('s', &global_var(120))), $t2 = 12, $t1 - $t2*int($t1/$t2));
    L30417: goto L30443 unless pop(@stack) == 0;
    L30420: # print "[abbrev 2]seem [abbrev 12][abbrev 40]repeating yourself."
        &write_text(&decode_text(30421));
	&newline();
	return(1);
    L30443: # print "Nothing happens [abbrev 21]."
        &write_text(&decode_text(30444));
	&newline();
	return(1);
}

sub rtn30458 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30459: goto L30477 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (42, 19);
    L30465: goto L30477 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (129);
    L30469: $stack[@stack] = z_call(14964, \@locv, \@stack, 30476, 0, 41, &global_var(59));
    L30476: return 1;
    L30477: goto L30487 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (106);
    L30481: $stack[@stack] = z_call(41184, \@locv, \@stack, 30486, 0);
    L30486: return (pop @stack);
    L30487: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (38);
    L30491: # print "[abbrev 1][abbrev 53] [abbrev 5][abbrev 74]"
        &write_text(&decode_text(30492));
    L30498: goto L30510 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (64);
    L30502: # print "muddy"
        &write_text(&decode_text(30503));
    L30507: goto L30515;
    L30510: # print "hard"
        &write_text(&decode_text(30511));
    L30515: # print " [abbrev 21]."
        &write_text(&decode_text(30516));
	&newline();
	return(1);
}

sub rtn30520 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30521: goto L30629 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L30526: # print "[abbrev 1]grue [abbrev 5]a sinister[abbrev 3][abbrev 85]presence [abbrev 22][abbrev 0]dark places [abbrev 9][abbrev 0]earth[abbrev 10]Its favorite diet [abbrev 5]adventurers[abbrev 3][abbrev 48]its insatiable appetite [abbrev 5]tempered by its fear [abbrev 9]light."
        &write_text(&decode_text(30527));
	&newline();
	return(1);
    L30629: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (50);
    L30633: # print "One [abbrev 5][abbrev 71][abbrev 85][abbrev 22][abbrev 0]dark nearby[abbrev 10]Don't let [abbrev 4]light go out!"
        &write_text(&decode_text(30634));
	&newline();
	return(1);
}

sub rtn30672 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30673: goto L30686 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L30677: &global_var(29, 0);
    L30680: &global_var(102, 0);
    L30683: &write_text(&decode_text(&global_var(131) * 2));
    L30685: return 1;
    L30686: goto L30702 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (52);
    L30690: goto L30702 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L30694: $stack[@stack] = z_call(14964, \@locv, \@stack, 30701, 0, 73, &global_var(59));
    L30701: return 1;
    L30702: goto L30729 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (43);
    L30706: # print "Auto-cannibalism [abbrev 5][abbrev 49][abbrev 0]answer."
        &write_text(&decode_text(30707));
	&newline();
	return(1);
    L30729: goto L30747 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 20);
    L30735: goto L30747 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L30739: $stack[@stack] = z_call(28324, \@locv, \@stack, 30746, 0, 25010);
    L30746: return (pop @stack);
    L30747: goto L30760 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L30751: # print "[abbrev 80]romantic!"
        &write_text(&decode_text(30752));
	&newline();
	return(1);
    L30760: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L30764: goto L30793 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37, 151);
    L30770: # print "[abbrev 33]image [abbrev 22][abbrev 0]mirror looks tired."
        &write_text(&decode_text(30771));
	&newline();
	return(1);
    L30793: # print "Are [abbrev 4]eyes prehensile?"
        &write_text(&decode_text(30794));
	&newline();
	return(1);
}

sub rtn30810 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30811: goto L30823 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (51, 73);
    L30817: $stack[@stack] = z_call(27474, \@locv, \@stack, 30822, 0);
    L30822: return (pop @stack);
    L30823: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (38);
    L30827: # print "Not a chance."
        &write_text(&decode_text(30828));
	&newline();
	return(1);
}

sub rtn30838 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30841: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L30845: # print "[abbrev 2][abbrev 13][abbrev 22]a squ[abbrev 13][abbrev 26][abbrev 11]tall ceilings[abbrev 10][abbrev 28]"
        &write_text(&decode_text(30846));
    L30870: goto L30888 unless $t1 = &global_var(25), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0), 83);
    L30876: # print "demolished"
        &write_text(&decode_text(30877));
    L30885: goto L30893;
    L30888: # print "huge"
        &write_text(&decode_text(30889));
    L30893: # print " mirror fills [abbrev 0][abbrev 51]wall[abbrev 10][abbrev 7][abbrev 13]exits [abbrev 65][abbrev 6][abbrev 79]east."
        &write_text(&decode_text(30894));
    L30926: return 1;
}

sub rtn30928 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L30931: goto L31009 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (83);
    L30936: goto L31009 unless &global_var(25) == 0;
    L30940: goto L30950 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37);
    L30944: $locv[0] = 151;
    L30947: goto L30953;
    L30950: $locv[0] = 37;
    L30953: $stack[@stack] = z_call(32432, \@locv, \@stack, 30961, 0, &global_var(0), 83, 0);
    L30961: $stack[@stack] = z_call(32432, \@locv, \@stack, 30969, 0, $locv[0], &global_var(0), 0);
    L30969: $stack[@stack] = z_call(32432, \@locv, \@stack, 30977, 0, 83, $locv[0], 0);
    L30977: $stack[@stack] = z_call(29852, \@locv, \@stack, 30984, 0, $locv[0], 0);
    L30984: # print "[abbrev 7][abbrev 5]a rumble [abbrev 18]deep with[abbrev 22][abbrev 0]earth."
        &write_text(&decode_text(30985));
	&newline();
	return(1);
    L31009: goto L31063 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46, 47);
    L31015: goto L31038 unless $t1 = &global_var(25), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0), 83);
    L31021: # print "[abbrev 1]mirror [abbrev 5]shattered."
        &write_text(&decode_text(31022));
	&newline();
	return(1);
    L31038: # print "An ugly pers[abbrev 59]stares back at you."
        &write_text(&decode_text(31039));
	&newline();
	return(1);
    L31063: goto L31076 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L31067: $stack[@stack] = z_call(31686, \@locv, \@stack, 31075, 0, 83, 24786);
    L31075: return (pop @stack);
    L31076: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (20, 93, 36);
    L31083: goto L31114 unless $t1 = &global_var(25), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0), 83);
    L31089: # print "You've d[abbrev 94]enough damage already."
        &write_text(&decode_text(31090));
	&newline();
	return(1);
    L31114: goto L31123 if &global_var(25) == 0;
    L31117: &global_var(25, 83);
    L31120: goto L31126;
    L31123: &global_var(25, &global_var(0));
    L31126: &global_var(23, 0);
    L31129: # print "[abbrev 1]mirror breaks[abbrev 10]I hope [abbrev 8][abbrev 19]a seven year supply [abbrev 9]good luck handy."
        &write_text(&decode_text(31130));
	&newline();
	return(1);
}

sub rtn31176 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31177: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L31181: # print "[abbrev 1]chimney [abbrev 44]"
        &write_text(&decode_text(31182));
    L31190: goto L31202 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L31194: # print "down"
        &write_text(&decode_text(31195));
    L31199: goto L31217;
    L31202: # print "up[abbrev 3][abbrev 6]looks climbable"
        &write_text(&decode_text(31203));
    L31217: &write_text(&decode_text(&global_var(7) * 2));
    L31219: return 1;
}

sub rtn31220 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31227: goto L31236 unless $locv[2] == 0;
    L31230: &clear_attr($locv[0], 19);
    L31233: &set_attr($locv[0], 24);
    L31236: $stack[@stack] = z_call(31442, \@locv, \@stack, 31242, 0, $locv[0]);
    L31242: goto L31249 unless pop(@stack) == 0;
    L31245: return 0 unless &global_var(0) == &get_object(&thing_location($locv[0], 'parent'));
    L31249: goto L31277 unless $locv[2] == 0;
    L31252: # print "[abbrev 1]"
        &write_text(&decode_text(31253));
    L31255: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L31257: # print " fizzles [abbrev 6]dies."
        &write_text(&decode_text(31258));
    L31270: &newline();
    L31271: $stack[@stack] = z_call(31514, \@locv, \@stack, 31276, 0);
    L31276: return (pop @stack);
    L31277: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L31281: &write_text(&decode_text(pop(@stack) * 2));
    L31283: &newline();
    L31284: return 1;
}

sub rtn31286 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31291: $locv[1] = &get_prop_addr(&global_var(0), 12);
    L31295: return 0 if $locv[1] == 0;
    L31298: $stack[@stack] = &get_prop_len($locv[1]);
    L31301: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 1;
    L31305: $stack[@stack] = z_call(21602, \@locv, \@stack, 31313, 0, $locv[0], $locv[1], pop(@stack));
    L31313: return (pop @stack);
}

sub rtn31314 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31321: goto L31325 if $locv[2] = get_child($locv[0]);
    L31325: return 0 if $locv[2] == 0;
    L31328: goto L31338 unless &test_attr($locv[2], $locv[1]);
    L31332: goto L31338 if $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L31336: return $locv[2];
    L31338: goto L31328 if $locv[2] = get_sibling($locv[2]);
    L31343: return 0;
}

sub rtn31344 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31351: $locv[1] = get_parent($locv[0]);
    L31354: return 0 if &test_attr($locv[0], 14);
    L31358: return 0 if $locv[1] == 0;
    L31361: return 1 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (45);
    L31365: goto L31378 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36);
    L31369: $stack[@stack] = z_call(31286, \@locv, \@stack, 31375, 0, $locv[0]);
    L31375: return 1 unless pop(@stack) == 0;
    L31378: $locv[2] = z_call(31418, \@locv, \@stack, 31384, 3, $locv[0]);
    L31384: $stack[@stack] = get_parent(&global_var(115));
    L31387: return 0 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0), pop(@stack));
    L31393: $stack[@stack] = get_parent(&global_var(115));
    L31396: return 1 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115), &global_var(0), pop(@stack));
    L31403: return 0 unless &test_attr($locv[1], 10);
    L31407: $stack[@stack] = z_call(31344, \@locv, \@stack, 31413, 0, $locv[1]);
    L31413: return 0 if pop(@stack) == 0;
    L31416: return 1;
}

sub rtn31418 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31421: return 0 if $locv[0] == 0;
    L31424: goto L31430 unless 45 == &get_object(&thing_location($locv[0], 'parent'));
    L31428: return 45;
    L31430: goto L31436 unless 27 == &get_object(&thing_location($locv[0], 'parent'));
    L31434: return $locv[0];
    L31436: $locv[0] = get_parent($locv[0]);
    L31439: goto L31421;
}

sub rtn31442 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31445: $locv[0] = get_parent($locv[0]);
    L31448: return 0 if $locv[0] == 0;
    L31451: goto L31445 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115));
    L31456: return 1;
}

sub rtn31458 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31465: $locv[1] = &get_next_prop(&global_var(0), $locv[1]);
    L31469: return 0 if unpack('s', pack('s', $locv[1])) < 19;
    L31473: $locv[2] = &get_prop_addr(&global_var(0), $locv[1]);
    L31477: $stack[@stack] = &get_prop_len($locv[2]);
    L31480: goto L31465 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (5);
    L31485: $stack[@stack] = $PlotzMemory::Memory[($locv[2] + 1) & 0xffff];
    L31489: goto L31465 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L31494: return $locv[1];
}

sub rtn31496 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31499: goto L31506 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(122));
    L31503: &global_var(122, 0);
    L31506: &remove_obj($locv[0]);
    L31508: $stack[@stack] = z_call(31514, \@locv, \@stack, 31513, 0);
    L31513: return (pop @stack);
}

sub rtn31514 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31515: return 1 if &global_var(38) == 0;
    L31518: $stack[@stack] = z_call(21626, \@locv, \@stack, 31524, 0, &global_var(0));
    L31524: return 1 unless pop(@stack) == 0;
    L31527: &global_var(38, 0);
    L31530: # print "[abbrev 38][abbrev 5][abbrev 95]pitch black."
        &write_text(&decode_text(31531));
	&newline();
	return(1);
}

sub rtn31546 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31551: goto L31560 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L31555: # print "[abbrev 38]is!"
        &write_text(&decode_text(31556));
	&newline();
	return(1);
    L31560: goto L31579 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37, 46, 47);
    L31567: # print "Lots [abbrev 9]"
        &write_text(&decode_text(31568));
    L31574: &write_text(&decode_text($locv[1] * 2));
    L31576: &write_text(&decode_text(&global_var(7) * 2));
    L31578: return 1;
    L31579: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L31583: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L31587: # print "Then it wouldn't [abbrev 40]a "
        &write_text(&decode_text(31588));
    L31604: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L31606: # print " anymore!"
        &write_text(&decode_text(31607));
	&newline();
	return(1);
}

sub rtn31616 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31621: # print "Underneath [abbrev 0]"
        &write_text(&decode_text(31622));
    L31632: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L31634: # print " [abbrev 5]a "
        &write_text(&decode_text(31635));
    L31639: &write_text(&decode_text(&thing_location($locv[1], 'name')));
    L31641: # print "[abbrev 10]As [abbrev 8]release [abbrev 0]"
        &write_text(&decode_text(31642));
    L31654: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L31656: # print "[abbrev 3][abbrev 0]"
        &write_text(&decode_text(31657));
    L31661: &write_text(&decode_text(&thing_location($locv[1], 'name')));
    L31663: # print " [abbrev 5]once aga[abbrev 22]concealed [abbrev 18]view."
        &write_text(&decode_text(31664));
	&newline();
	return(1);
}

sub rtn31686 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31691: # print "[abbrev 1]"
        &write_text(&decode_text(31692));
    L31694: &write_text(&decode_text(&thing_location($locv[0], 'name')));
    L31696: # print " [abbrev 5]securely fastened [abbrev 12][abbrev 0]"
        &write_text(&decode_text(31697));
    L31715: &write_text(&decode_text($locv[1] * 2));
    L31717: &write_text(&decode_text(&global_var(7) * 2));
    L31719: return 1;
}

sub rtn31720 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31727: goto L31745 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37);
    L31731: goto L31738 unless &test_attr($locv[0], 10);
    L31735: &write_text(&decode_text(&global_var(99) * 2));
    L31737: return 1;
    L31738: &set_attr($locv[0], 10);
    L31741: &write_text(&decode_text($locv[1] * 2));
    L31743: &newline();
    L31744: return 1;
    L31745: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L31749: goto L31760 unless &test_attr($locv[0], 10);
    L31753: &clear_attr($locv[0], 10);
    L31756: &write_text(&decode_text($locv[2] * 2));
    L31758: &newline();
    L31759: return 1;
    L31760: &write_text(&decode_text(&global_var(99) * 2));
    L31762: return 1;
}

sub rtn31764 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31767: &write_text(&decode_text($locv[0] * 2));
    L31769: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L31771: $stack[@stack] = z_call(14218, \@locv, \@stack, 31777, 0, &global_var(123));
    L31777: &write_text(&decode_text(pop(@stack) * 2));
    L31779: &write_text(&decode_text(&global_var(7) * 2));
    L31781: return 1;
}

sub rtn31782 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L31783: goto L31813 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (62, 84);
    L31789: &global_var(29, 0);
    L31792: # print "[abbrev 1][abbrev 39][abbrev 5]a strong[abbrev 3]silent type."
        &write_text(&decode_text(31793));
	&newline();
	return(1);
    L31813: goto L31863 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (93);
    L31817: goto L31863 unless &test_attr(&global_var(59), 29);
    L31821: &insert_obj(&global_var(59), &global_var(0));
    L31824: # print "[abbrev 2]missed hitting [abbrev 0]thief[abbrev 3][abbrev 48][abbrev 8]suceeded [abbrev 22]angering him."
        &write_text(&decode_text(31825));
	&newline();
	return(1);
    L31863: goto L31948 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (52, 93);
    L31870: goto L31948 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (112);
    L31875: &insert_obj(&global_var(59), 112);
    L31878: # print "[abbrev 1][abbrev 39]"
        &write_text(&decode_text(31879));
    L31883: goto L31918 unless &test_attr(&global_var(59), 4);
    L31887: # print "[abbrev 5]taken aback by [abbrev 4]unexpected generosity[abbrev 3][abbrev 48]"
        &write_text(&decode_text(31888));
    L31918: # print "puts [abbrev 0]"
        &write_text(&decode_text(31919));
    L31925: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L31927: # print " [abbrev 22][abbrev 63]bag [abbrev 6]thanks [abbrev 8]politely."
        &write_text(&decode_text(31928));
	&newline();
	return(1);
    L31948: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (47, 46);
    L31954: # print "[abbrev 1][abbrev 39]carries a [abbrev 14]bag [abbrev 6]a vicious stiletto[abbrev 3]whose blade [abbrev 5]aimed menacingly [abbrev 22][abbrev 4]direction."
        &write_text(&decode_text(31955));
	&newline();
	return(1);
}

sub rtn32016 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32029: $locv[1] = get_parent(112);
    L32032: goto L32042 if &test_attr(112, 14);
    L32036: $locv[3] = 1;
    L32039: goto L32045;
    L32042: $locv[3] = 0;
    L32045: goto L32051 if $locv[3] == 0;
    L32048: $locv[1] = get_parent(112);
    L32051: goto L32096 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (170);
    L32055: goto L32096 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0));
    L32059: $stack[@stack] = z_call(33054, \@locv, \@stack, 32065, 0, 170);
    L32065: goto L32176 if $locv[3] == 0;
    L32069: &set_attr(112, 14);
    L32072: goto L32076 if $locv[0] = get_child(170);
    L32076: goto L32090 if $locv[0] == 0;
    L32079: &clear_attr($locv[0], 14);
    L32082: goto L32076 if $locv[0] = get_sibling($locv[0]);
    L32087: goto L32076;
    L32090: $locv[3] = 0;
    L32093: goto L32176;
    L32096: goto L32127 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0));
    L32100: goto L32127 if &test_attr($locv[1], 19);
    L32104: goto L32127 if &global_var(0) == &get_object(&thing_location(103, 'parent'));
    L32108: $stack[@stack] = z_call(32554, \@locv, \@stack, 32114, 0, $locv[3]);
    L32114: return 1 unless pop(@stack) == 0;
    L32117: goto L32176 unless &test_attr(112, 14);
    L32121: $locv[3] = 0;
    L32124: goto L32176;
    L32127: goto L32141 unless $locv[1] == &get_object(&thing_location(112, 'parent'));
    L32131: goto L32141 if &test_attr(112, 14);
    L32135: &set_attr(112, 14);
    L32138: $locv[3] = 0;
    L32141: goto L32176 unless &test_attr($locv[1], 13);
    L32145: $stack[@stack] = z_call(32432, \@locv, \@stack, 32153, 0, $locv[1], 112, 1);
    L32153: goto L32170 unless &test_attr($locv[1], 2);
    L32157: goto L32170 unless &test_attr(&global_var(0), 2);
    L32161: $locv[5] = z_call(33096, \@locv, \@stack, 32167, 6, $locv[1]);
    L32167: goto L32176;
    L32170: $locv[5] = z_call(32346, \@locv, \@stack, 32176, 6, $locv[1]);
    L32176: goto L32185 if $locv[4] == 0;
    L32179: $locv[4] = 0;
    L32182: goto L32188;
    L32185: $locv[4] = 1;
    L32188: goto L32227 if $locv[4] == 0;
    L32191: goto L32227 unless $locv[3] == 0;
    L32194: goto L32201 if $locv[1] == 0;
    L32197: goto L32205 if $locv[1] = get_sibling($locv[1]);
    L32201: goto L32205 if $locv[1] = get_child(27);
    L32205: goto L32194 if &test_attr($locv[1], 5);
    L32210: goto L32194 unless &test_attr($locv[1], 7);
    L32215: &insert_obj(112, $locv[1]);
    L32218: &set_attr(112, 14);
    L32221: &global_var(108, 0);
    L32224: goto L32032;
    L32227: goto L32237 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (170);
    L32231: $stack[@stack] = z_call(32240, \@locv, \@stack, 32237, 0, $locv[1]);
    L32237: return $locv[5];
}

sub rtn32240 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32249: goto L32253 if $locv[1] = get_child(112);
    L32253: goto L32258 unless $locv[1] == 0;
    L32256: return $locv[3];
    L32258: goto L32262 if $locv[2] = get_sibling($locv[1]);
    L32262: goto L32339 if &test_attr($locv[1], 4);
    L32267: goto L32339 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (177, 63);
    L32274: $stack[@stack] = z_call(14192, \@locv, \@stack, 32280, 0, 30);
    L32280: goto L32339 if pop(@stack) == 0;
    L32283: &clear_attr($locv[1], 14);
    L32286: &insert_obj($locv[1], $locv[0]);
    L32289: goto L32339 unless $locv[3] == 0;
    L32292: goto L32339 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0));
    L32296: # print "[abbrev 1]robber rummages [abbrev 20][abbrev 63]bag [abbrev 6]drops a few valueless items."
        &write_text(&decode_text(32297));
    L32335: &newline();
    L32336: $locv[3] = 1;
    L32339: $locv[1] = $locv[2];
    L32342: goto L32253;
}

sub rtn32346 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32353: goto L32357 if $locv[1] = get_child($locv[0]);
    L32357: return 0 if $locv[1] == 0;
    L32360: goto L32364 if $locv[2] = get_sibling($locv[1]);
    L32364: goto L32426 unless &test_attr($locv[1], 4);
    L32369: goto L32426 unless &test_attr($locv[1], 17);
    L32373: goto L32426 if &test_attr($locv[1], 5);
    L32377: goto L32426 if &test_attr($locv[1], 14);
    L32381: $stack[@stack] = z_call(14192, \@locv, \@stack, 32387, 0, 10);
    L32387: goto L32426 if pop(@stack) == 0;
    L32390: &insert_obj($locv[1], 112);
    L32393: &set_attr($locv[1], 13);
    L32396: &set_attr($locv[1], 14);
    L32399: goto L32406 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (42);
    L32403: &global_var(90, 0);
    L32406: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0));
    L32410: # print "[abbrev 1]"
        &write_text(&decode_text(32411));
    L32413: &write_text(&decode_text(&thing_location($locv[1], 'name')));
    L32415: # print " [abbrev 75]vanished!"
        &write_text(&decode_text(32416));
	&newline();
	return(1);
    L32426: $locv[1] = $locv[2];
    L32429: goto L32357;
}

sub rtn32432 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32445: goto L32449 if $locv[4] = get_child($locv[0]);
    L32449: goto L32454 unless $locv[4] == 0;
    L32452: return $locv[5];
    L32454: goto L32458 if $locv[3] = get_sibling($locv[4]);
    L32458: goto L32489 if &test_attr($locv[4], 14);
    L32462: goto L32473 if $locv[2] == 0;
    L32465: goto L32489 if &test_attr($locv[4], 5);
    L32469: goto L32489 unless &test_attr($locv[4], 4);
    L32473: &insert_obj($locv[4], $locv[1]);
    L32476: &set_attr($locv[4], 13);
    L32479: $locv[5] = 1;
    L32482: goto L32489 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (112);
    L32486: &set_attr($locv[4], 14);
    L32489: $locv[4] = $locv[3];
    L32492: goto L32449;
}

sub rtn32496 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32497: goto L32532 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46, 73);
    L32503: # print "[abbrev 38]will [abbrev 40]taken over [abbrev 0]thief's dead body."
        &write_text(&decode_text(32504));
	&newline();
	return(1);
    L32532: goto L32543 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L32536: goto L32543 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (63);
    L32540: &write_text(&decode_text(&global_var(121) * 2));
    L32542: return 1;
    L32543: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (47, 30, 37);
    L32550: &write_text(&decode_text(&global_var(121) * 2));
    L32552: return 1;
}

sub rtn32554 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32561: goto L32568 unless &global_var(88) == 0;
    L32564: return 0 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (170);
    L32568: goto L32909 unless &global_var(108) == 0;
    L32572: goto L32681 unless &global_var(88) == 0;
    L32576: goto L32681 unless $locv[0] == 0;
    L32580: $stack[@stack] = &z_random(100);
    L32584: goto L32681 unless 30 > unpack('s', pack('s', pop(@stack)));
    L32589: &clear_attr(112, 14);
    L32592: &global_var(108, 1);
    L32595: $stack[@stack] = z_call(15158, \@locv, \@stack, 32603, 0, 16885, 2);
    L32603: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L32608: # print "Some[abbrev 94]carrying a [abbrev 14]bag [abbrev 5]casually leaning [abbrev 90][abbrev 0]wall[abbrev 10][abbrev 38][abbrev 5]clear [abbrev 17][abbrev 0]bag will [abbrev 40]taken only over [abbrev 63]dead body."
        &write_text(&decode_text(32609));
	&newline();
	return(1);
    L32681: goto L32698 if $locv[0] == 0;
    L32684: $stack[@stack] = &z_random(100);
    L32688: goto L32698 unless 30 > unpack('s', pack('s', pop(@stack)));
    L32692: &set_attr(112, 14);
    L32695: &write_text(&decode_text(&global_var(58) * 2));
    L32697: return 1;
    L32698: $stack[@stack] = &z_random(100);
    L32702: return 0 if 70 > unpack('s', pack('s', pop(@stack)));
    L32706: return 0 unless &global_var(88) == 0;
    L32709: $stack[@stack] = z_call(32432, \@locv, \@stack, 32717, 0, &global_var(0), 112, 1);
    L32717: goto L32726 if pop(@stack) == 0;
    L32720: $locv[1] = &global_var(0);
    L32723: goto L32740;
    L32726: $stack[@stack] = z_call(32432, \@locv, \@stack, 32734, 0, &global_var(115), 112, 1);
    L32734: goto L32740 if pop(@stack) == 0;
    L32737: $locv[1] = 30;
    L32740: &global_var(108, 1);
    L32743: goto L32843 if $locv[1] == 0;
    L32747: goto L32843 unless $locv[0] == 0;
    L32751: # print "[abbrev 28]suspicious-[abbrev 86]individual [abbrev 11]a [abbrev 14]bag just wandered [abbrev 20][abbrev 6]quietly abstracted some valuables [abbrev 18]"
        &write_text(&decode_text(32752));
    L32814: goto L32826 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(0));
    L32818: # print "[abbrev 0]room"
        &write_text(&decode_text(32819));
    L32823: goto L32835;
    L32826: # print "[abbrev 4]possession"
        &write_text(&decode_text(32827));
    L32835: &write_text(&decode_text(&global_var(7) * 2));
    L32837: $stack[@stack] = z_call(31514, \@locv, \@stack, 32842, 0);
    L32842: return 0;
    L32843: goto L32859 if $locv[0] == 0;
    L32846: &set_attr(112, 14);
    L32849: $locv[0] = 0;
    L32852: $stack[@stack] = z_call(32964, \@locv, \@stack, 32858, 0, $locv[1]);
    L32858: return 1;
    L32859: # print "[abbrev 28]"le[abbrev 73][abbrev 6]hungry" gentlem[abbrev 73]just wandered through[abbrev 3]carrying a [abbrev 14]bag[abbrev 10]"
        &write_text(&decode_text(32860));
    L32906: &write_text(&decode_text(&global_var(58) * 2));
    L32908: return 1;
    L32909: return 0 if $locv[0] == 0;
    L32912: $stack[@stack] = &z_random(100);
    L32916: return 0 unless 30 > unpack('s', pack('s', pop(@stack)));
    L32920: $stack[@stack] = z_call(32432, \@locv, \@stack, 32928, 0, &global_var(0), 112, 1);
    L32928: goto L32937 if pop(@stack) == 0;
    L32931: $locv[1] = &global_var(0);
    L32934: goto L32951;
    L32937: $stack[@stack] = z_call(32432, \@locv, \@stack, 32945, 0, &global_var(115), 112, 1);
    L32945: goto L32951 if pop(@stack) == 0;
    L32948: $locv[1] = 30;
    L32951: &set_attr(112, 14);
    L32954: $locv[0] = 0;
    L32957: $stack[@stack] = z_call(32964, \@locv, \@stack, 32963, 0, $locv[1]);
    L32963: return 0;
}

sub rtn32964 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L32967: goto L33051 if $locv[0] == 0;
    L32971: # print "[abbrev 1][abbrev 39]just left[abbrev 10][abbrev 2]may [abbrev 49][abbrev 19]noticed [abbrev 17]he "
        &write_text(&decode_text(32972));
    L32998: goto L33020 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L33002: # print "robbed [abbrev 8]blind first"
        &write_text(&decode_text(33003));
    L33017: goto L33043;
    L33020: # print "appropriated [abbrev 0]valuables [abbrev 22][abbrev 0]room"
        &write_text(&decode_text(33021));
    L33043: &write_text(&decode_text(&global_var(7) * 2));
    L33045: $stack[@stack] = z_call(31514, \@locv, \@stack, 33050, 0);
    L33050: return (pop @stack);
    L33051: &write_text(&decode_text(&global_var(58) * 2));
    L33053: return 1;
}

sub rtn33054 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33063: goto L33067 if $locv[1] = get_child(112);
    L33067: goto L33072 unless $locv[1] == 0;
    L33070: return $locv[3];
    L33072: goto L33076 if $locv[2] = get_sibling($locv[1]);
    L33076: goto L33089 unless &test_attr($locv[1], 4);
    L33080: &insert_obj($locv[1], $locv[0]);
    L33083: &clear_attr($locv[1], 14);
    L33086: $locv[3] = 1;
    L33089: $locv[1] = $locv[2];
    L33092: goto L33067;
}

sub rtn33096 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33103: goto L33107 if $locv[1] = get_child($locv[0]);
    L33107: return 0 if $locv[1] == 0;
    L33110: goto L33114 if $locv[2] = get_sibling($locv[1]);
    L33114: goto L33205 unless &test_attr($locv[1], 17);
    L33119: goto L33205 if &test_attr($locv[1], 14);
    L33124: $stack[@stack] = &z_random(100);
    L33128: goto L33205 unless 40 > unpack('s', pack('s', pop(@stack)));
    L33133: # print "[abbrev 77][abbrev 0]distance[abbrev 3]some[abbrev 94]says[abbrev 3]"My[abbrev 3]I wonder what [abbrev 50]fine "
        &write_text(&decode_text(33134));
    L33172: &write_text(&decode_text(&thing_location($locv[1], 'name')));
    L33174: # print " [abbrev 5]doing [abbrev 21].""
        &write_text(&decode_text(33175));
    L33185: &newline();
    L33186: $stack[@stack] = z_call(14192, \@locv, \@stack, 33192, 0, 60);
    L33192: return 1 if pop(@stack) == 0;
    L33195: &insert_obj($locv[1], 112);
    L33198: &set_attr($locv[1], 13);
    L33201: &set_attr($locv[1], 14);
    L33204: return 1;
    L33205: $locv[1] = $locv[2];
    L33208: goto L33107;
}

sub rtn33212 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33217: $locv[0] = &get_prop(&global_var(59), 15);
    L33221: goto L33231 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (103);
    L33225: $locv[1] = 45;
    L33228: goto L33239;
    L33231: $stack[@stack] = int(unpack('s', pack('s', &global_var(1))) / 4);
    L33235: $locv[1] = 15 + unpack('s', pack('s', pop(@stack)));
    L33239: $stack[@stack] = &z_random(100);
    L33243: goto L33460 unless unpack('s', pack('s', $locv[1])) > unpack('s', pack('s', pop(@stack)));
    L33248: $stack[@stack] = &z_random(100);
    L33252: goto L33351 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33257: $locv[0] = unpack('s', pack('s', $locv[0])) - 2;
    L33261: goto L33273 unless unpack('s', pack('s', $locv[0])) < 0;
    L33265: $stack[@stack] = z_call(33528, \@locv, \@stack, 33270, 0);
    L33270: goto L33454;
    L33273: $stack[@stack] = &z_random(100);
    L33277: goto L33313 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33281: # print "[abbrev 1]"
        &write_text(&decode_text(33282));
    L33284: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33286: # print " receives a deep gash [abbrev 22][abbrev 63]side."
        &write_text(&decode_text(33287));
    L33309: &newline();
    L33310: goto L33454;
    L33313: # print "Slash! [abbrev 33]"
        &write_text(&decode_text(33314));
    L33322: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L33324: # print " connects! [abbrev 15]could [abbrev 40]serious!"
        &write_text(&decode_text(33325));
    L33347: &newline();
    L33348: goto L33454;
    L33351: goto L33363 unless unpack('s', pack('s', ($locv[0] = ($locv[0] - 1) & 0xffff))) < 0;
    L33355: $stack[@stack] = z_call(33528, \@locv, \@stack, 33360, 0);
    L33360: goto L33454;
    L33363: $stack[@stack] = &z_random(100);
    L33367: goto L33415 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33371: # print "[abbrev 1]"
        &write_text(&decode_text(33372));
    L33374: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33376: # print " [abbrev 5]struck [abbrev 59][abbrev 0]arm; blood begins [abbrev 12]trickle down."
        &write_text(&decode_text(33377));
    L33411: &newline();
    L33412: goto L33454;
    L33415: # print "[abbrev 1]blow lands[abbrev 3]making a shallow gash [abbrev 22][abbrev 0]"
        &write_text(&decode_text(33416));
    L33444: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33446: # print "'s arm!"
        &write_text(&decode_text(33447));
    L33453: &newline();
    L33454: &put_prop(&global_var(59), 15, $locv[0]);
    L33459: return 1;
    L33460: $stack[@stack] = &z_random(100);
    L33464: goto L33500 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33468: # print "[abbrev 28]good slash[abbrev 3][abbrev 48]it misses [abbrev 0]"
        &write_text(&decode_text(33469));
    L33489: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33491: # print " by a mile."
        &write_text(&decode_text(33492));
	&newline();
	return(1);
    L33500: # print "[abbrev 2]charge[abbrev 3][abbrev 48][abbrev 0]"
        &write_text(&decode_text(33501));
    L33511: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33513: # print " jumps nimbly aside."
        &write_text(&decode_text(33514));
	&newline();
	return(1);
}

sub rtn33528 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33531: # print "[abbrev 1]fatal blow strikes [abbrev 0]"
        &write_text(&decode_text(33532));
    L33548: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33550: # print " squ[abbrev 13][abbrev 22][abbrev 0]heart: He dies[abbrev 10]As [abbrev 0]"
        &write_text(&decode_text(33551));
    L33575: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L33577: # print " breathes [abbrev 63]last breath[abbrev 3]a cloud [abbrev 9]sinister black fog envelops him; when it lifts[abbrev 3][abbrev 0]carcass [abbrev 5]gone."
        &write_text(&decode_text(33578));
    L33648: &newline();
    L33649: &remove_obj(&global_var(59));
    L33651: goto L33681 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (103);
    L33655: &put_prop(103, 15, 2);
    L33660: &insert_obj(25, &global_var(0));
    L33663: &clear_attr(25, 6);
    L33666: &set_attr(25, 29);
    L33669: &set_attr(25, 17);
    L33672: &global_var(16, 1);
    L33675: &global_var(1, unpack('s', pack('s', &global_var(1))) + 10);
    L33679: return &global_var(1);
    L33681: &put_prop(112, 15, 5);
    L33686: &insert_obj(177, &global_var(0));
    L33689: &clear_attr(177, 6);
    L33692: &set_attr(177, 17);
    L33695: &set_attr(177, 29);
    L33698: $stack[@stack] = z_call(15178, \@locv, \@stack, 33705, 0, 16008);
    L33705: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L33710: $stack[@stack] = z_call(33054, \@locv, \@stack, 33716, 0, &global_var(0));
    L33716: return 0 if pop(@stack) == 0;
    L33719: goto L33747 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (170);
    L33723: # print "As [abbrev 0][abbrev 39]dies[abbrev 3][abbrev 63][abbrev 91]reappear."
        &write_text(&decode_text(33724));
    L33744: goto L33762;
    L33747: # print "H[abbrev 5]booty remains."
        &write_text(&decode_text(33748));
    L33762: &newline();
    L33763: &newline();
    L33764: $stack[@stack] = z_call(25076, \@locv, \@stack, 33769, 0);
    L33769: return (pop @stack);
}

sub rtn33770 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33777: $stack[@stack] = z_call(15158, \@locv, \@stack, 33786, 0, 16885, 65535);
    L33786: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L33791: $locv[0] = &get_prop(30, 15);
    L33795: goto L33808 unless &global_var(0) == &get_object(&thing_location(103, 'parent'));
    L33799: $locv[2] = 55;
    L33802: $locv[1] = &global_var(95);
    L33805: goto L33818;
    L33808: goto L33857 unless &global_var(0) == &get_object(&thing_location(112, 'parent'));
    L33812: $locv[2] = 60;
    L33815: $locv[1] = &global_var(14);
    L33818: $stack[@stack] = &z_random(100);
    L33822: goto L33960 unless unpack('s', pack('s', $locv[2])) > unpack('s', pack('s', pop(@stack)));
    L33827: $stack[@stack] = &z_random(100);
    L33831: goto L33912 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33836: $locv[0] = unpack('s', pack('s', $locv[0])) - 2;
    L33840: goto L33884 unless unpack('s', pack('s', $locv[0])) < 0;
    L33844: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33848: $stack[@stack] = z_call(28324, \@locv, \@stack, 33854, 0, pop(@stack));
    L33854: goto L33954;
    L33857: $stack[@stack] = z_call(15178, \@locv, \@stack, 33864, 0, 16885);
    L33864: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L33869: $stack[@stack] = z_call(15158, \@locv, \@stack, 33878, 0, 16992, 65535);
    L33878: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L33883: return 0;
    L33884: $stack[@stack] = &z_random(100);
    L33888: goto L33902 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33892: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*5) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33896: &write_text(&decode_text(pop(@stack) * 2));
    L33898: &newline();
    L33899: goto L33954;
    L33902: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*4) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33906: &write_text(&decode_text(pop(@stack) * 2));
    L33908: &newline();
    L33909: goto L33954;
    L33912: goto L33929 unless unpack('s', pack('s', ($locv[0] = ($locv[0] - 1) & 0xffff))) < 0;
    L33916: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*6) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33920: $stack[@stack] = z_call(28324, \@locv, \@stack, 33926, 0, pop(@stack));
    L33926: goto L33954;
    L33929: $stack[@stack] = &z_random(100);
    L33933: goto L33947 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33937: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*3) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33941: &write_text(&decode_text(pop(@stack) * 2));
    L33943: &newline();
    L33944: goto L33954;
    L33947: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*2) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33951: &write_text(&decode_text(pop(@stack) * 2));
    L33953: &newline();
    L33954: &put_prop(30, 15, $locv[0]);
    L33959: return 1;
    L33960: $stack[@stack] = &z_random(100);
    L33964: goto L33976 unless 50 > unpack('s', pack('s', pop(@stack)));
    L33968: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*1) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33972: &write_text(&decode_text(pop(@stack) * 2));
    L33974: &newline();
    L33975: return 1;
    L33976: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L33980: &write_text(&decode_text(pop(@stack) * 2));
    L33982: &newline();
    L33983: return 1;
}

sub rtn33984 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L33991: $locv[0] = &get_prop(30, 15);
    L33995: $locv[1] = &get_prop(103, 15);
    L33999: $locv[2] = &get_prop(112, 15);
    L34003: goto L34031 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L34007: goto L34031 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L34011: goto L34031 unless $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (5);
    L34015: $stack[@stack] = z_call(15178, \@locv, \@stack, 34022, 0, 16992);
    L34022: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L34027: &global_var(93, 10);
    L34030: return 0;
    L34031: &global_var(93, "--");
    L34033: return 0 unless &global_var(93) == 0;
    L34036: goto L34049 unless unpack('s', pack('s', $locv[0])) < 6;
    L34040: $stack[@stack] = unpack('s', pack('s', $locv[0])) + 1;
    L34044: &put_prop(30, 15, pop(@stack));
    L34049: goto L34062 unless unpack('s', pack('s', $locv[1])) < 2;
    L34053: $stack[@stack] = unpack('s', pack('s', $locv[1])) + 1;
    L34057: &put_prop(103, 15, pop(@stack));
    L34062: goto L34075 unless unpack('s', pack('s', $locv[2])) < 5;
    L34066: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 1;
    L34070: &put_prop(112, 15, pop(@stack));
    L34075: &global_var(93, 10);
    L34078: return 0;
}

sub rtn34080 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34083: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L34087: # print "[abbrev 2][abbrev 13]standing [abbrev 22][abbrev 73]open field [abbrev 60][abbrev 9]a [abbrev 69]house[abbrev 3][abbrev 11]a boarded front door[abbrev 10]"
        &write_text(&decode_text(34088));
    L34134: goto L34160 if &global_var(98) == 0;
    L34137: # print "[abbrev 28]secret path [abbrev 44][abbrev 58] [abbrev 31][abbrev 0]forest[abbrev 10]"
        &write_text(&decode_text(34138));
    L34160: # print "[abbrev 2]could circle [abbrev 0]house [abbrev 12][abbrev 0][abbrev 61]or [abbrev 78]."
        &write_text(&decode_text(34161));
    L34185: return 1;
}

sub rtn34186 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34187: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L34191: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (167);
    L34195: $stack[@stack] = z_call(31686, \@locv, \@stack, 34203, 0, 167, 23890);
    L34203: return (pop @stack);
}

sub rtn34204 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34205: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (79);
    L34209: # print ""WELCOME TO ZORK[abbrev 3]a game [abbrev 9]adventure[abbrev 3]danger[abbrev 3][abbrev 6]low cunning[abbrev 10]No computer should [abbrev 40]without one!"^^Note: [abbrev 50]"mini-zork" contains only a sub-set [abbrev 9][abbrev 0]locations[abbrev 3]puzzles[abbrev 3][abbrev 6]descriptions found"
        &write_text(&decode_text(34210));
    L34350: &write_text(&decode_text(&global_var(66) * 2));
    L34352: return 1;
}

sub rtn34354 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34357: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L34361: $stack[@stack] = z_call(22076, \@locv, \@stack, 34366, 0);
    L34366: return (pop @stack);
}

sub rtn34368 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34371: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L34375: # print "[abbrev 2][abbrev 13]behind [abbrev 0][abbrev 69]house[abbrev 10]Paths lead [abbrev 31][abbrev 0]forest [abbrev 12][abbrev 0][abbrev 65][abbrev 6][abbrev 79]east[abbrev 10][abbrev 77][abbrev 94]corner [abbrev 9][abbrev 0]house"
        &write_text(&decode_text(34376));
    L34430: $stack[@stack] = z_call(34436, \@locv, \@stack, 34435, 0);
    L34435: return (pop @stack);
}

sub rtn34436 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34437: # print " [abbrev 5]a [abbrev 25]window [abbrev 24][abbrev 5]"
        &write_text(&decode_text(34438));
    L34450: goto L34460 unless &test_attr(176, 10);
    L34454: # print "open."
        &write_text(&decode_text(34455));
    L34459: return 1;
    L34460: # print "slightly ajar."
        &write_text(&decode_text(34461));
    L34471: return 1;
}

sub rtn34472 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34473: goto L34489 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18, 53, 125);
    L34480: goto L34489 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 50);
    L34486: &write_text(&decode_text(&global_var(99) * 2));
    L34488: return 1;
    L34489: goto L34544 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L34493: # print "[abbrev 1]house [abbrev 5]a beautiful [abbrev 69]colonial[abbrev 10][abbrev 1]owners must [abbrev 19]been extremely wealthy."
        &write_text(&decode_text(34494));
	&newline();
	return(1);
    L34544: goto L34557 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37, 29);
    L34550: $stack[@stack] = z_call(30150, \@locv, \@stack, 34556, 0, 21);
    L34556: return (pop @stack);
    L34557: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (25);
    L34561: # print "[abbrev 2]must [abbrev 40]joking."
        &write_text(&decode_text(34562));
	&newline();
	return(1);
}

sub rtn34574 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34575: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46, 73);
    L34581: $stack[@stack] = z_call(31686, \@locv, \@stack, 34589, 0, 54, 23649);
    L34589: return (pop @stack);
}

sub rtn34590 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34591: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 37);
    L34597: # print "[abbrev 1]windows [abbrev 13]boarded!"
        &write_text(&decode_text(34598));
	&newline();
	return(1);
}

sub rtn34612 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34613: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L34617: # print "[abbrev 1]nails [abbrev 13][abbrev 74]deeply imbedded."
        &write_text(&decode_text(34618));
	&newline();
	return(1);
}

sub rtn34638 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34639: goto L34649 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (45);
    L34643: $stack[@stack] = z_call(27474, \@locv, \@stack, 34648, 0);
    L34648: return (pop @stack);
    L34649: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (50);
    L34653: &write_text(&decode_text(&global_var(99) * 2));
    L34655: return 1;
}

sub rtn34656 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34659: goto L34670 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L34663: goto L34670 unless &global_var(116) == 0;
    L34666: &set_attr(21, 14);
    L34669: return 1;
    L34670: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L34674: # print "[abbrev 15][abbrev 5]a path [abbrev 20]a dimly lit forest[abbrev 3]curving [abbrev 18][abbrev 51][abbrev 12]east[abbrev 10][abbrev 28][abbrev 14]tree [abbrev 11]low branches stands by [abbrev 0]edge [abbrev 9][abbrev 0]path."
        &write_text(&decode_text(34675));
    L34745: goto L34777 unless &test_attr(21, 10);
    L34749: # print " [abbrev 7][abbrev 5][abbrev 73]open grating[abbrev 3]descending [abbrev 31][abbrev 88]."
        &write_text(&decode_text(34750));
    L34776: return 1;
    L34777: return 0 if &global_var(116) == 0;
    L34780: # print " [abbrev 7][abbrev 5]a [abbrev 34]securely fastened [abbrev 31][abbrev 0][abbrev 53]."
        &write_text(&decode_text(34781));
    L34805: return 1;
}

sub rtn34806 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34807: goto L34830 if &global_var(116) == 0;
    L34810: goto L34816 unless &test_attr(21, 10);
    L34814: return 154;
    L34816: # print "[abbrev 1][abbrev 34][abbrev 5][abbrev 27]!"
        &write_text(&decode_text(34817));
    L34825: &newline();
    L34826: &global_var(122, 21);
    L34829: return 0;
    L34830: &write_text(&decode_text(&global_var(36) * 2));
    L34832: return 0;
}

sub rtn34834 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34839: goto L34877 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L34843: # print "[abbrev 2][abbrev 13]ten [abbrev 64]above [abbrev 0][abbrev 53][abbrev 3]nestled among [abbrev 14]branches."
        &write_text(&decode_text(34844));
    L34876: return 1;
    L34877: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L34881: goto L34898 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (27);
    L34885: goto L34898 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (27, 76);
    L34891: $stack[@stack] = z_call(30150, \@locv, \@stack, 34897, 0, 22);
    L34897: return (pop @stack);
    L34898: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (41);
    L34902: $stack[@stack] = z_call(29740, \@locv, \@stack, 34907, 0);
    L34907: return 1 if pop(@stack) == 0;
    L34910: goto L34935 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (76, &global_var(115));
    L34916: &insert_obj(&global_var(59), 119);
    L34919: # print "[abbrev 1]"
        &write_text(&decode_text(34920));
    L34922: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L34924: # print " falls [abbrev 12][abbrev 0][abbrev 53]."
        &write_text(&decode_text(34925));
	&newline();
	return(1);
    L34935: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L34939: $stack[@stack] = z_call(28324, \@locv, \@stack, 34946, 0, 23730);
    L34946: return (pop @stack);
}

sub rtn34948 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34949: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L34953: $stack[@stack] = z_call(22516, \@locv, \@stack, 34959, 0, 74);
    L34959: return 0;
}

sub rtn34960 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34961: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (54, 37);
    L34967: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (74);
    L34971: # print "[abbrev 15]egg only opens"
        &write_text(&decode_text(34972));
    L34984: &write_text(&decode_text(&global_var(66) * 2));
    L34986: return 1;
}

sub rtn34988 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L34989: goto L35004 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (31);
    L34993: # print "69,105."
        &write_text(&decode_text(34994));
	&newline();
	return(1);
    L35004: goto L35052 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (25);
    L35008: $stack[@stack] = z_call(35124, \@locv, \@stack, 35013, 0);
    L35013: # print "[abbrev 1]leaves burn"
        &write_text(&decode_text(35014));
    L35024: $stack[@stack] = z_call(31442, \@locv, \@stack, 35030, 0, 108);
    L35030: goto L35043 if pop(@stack) == 0;
    L35033: $stack[@stack] = z_call(28324, \@locv, \@stack, 35040, 0, 24856);
    L35040: goto L35045;
    L35043: &write_text(&decode_text(&global_var(7) * 2));
    L35045: $stack[@stack] = z_call(31496, \@locv, \@stack, 35051, 0, &global_var(59));
    L35051: return (pop @stack);
    L35052: goto L35084 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (33);
    L35056: $stack[@stack] = z_call(35124, \@locv, \@stack, 35061, 0);
    L35061: # print "[abbrev 1]leaves seem [abbrev 12][abbrev 40][abbrev 74]soggy [abbrev 12]cut."
        &write_text(&decode_text(35062));
	&newline();
	return(1);
    L35084: goto L35098 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (69);
    L35088: $stack[@stack] = z_call(35124, \@locv, \@stack, 35093, 0);
    L35093: goto L35098 if pop(@stack) == 0;
    L35096: &newline();
    L35097: return 1;
    L35098: goto L35108 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L35102: $stack[@stack] = z_call(35124, \@locv, \@stack, 35107, 0);
    L35107: return 0;
    L35108: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L35112: return 0 unless &global_var(116) == 0;
    L35115: $stack[@stack] = z_call(31616, \@locv, \@stack, 35122, 0, 108, 21);
    L35122: return (pop @stack);
}

sub rtn35124 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35125: return 0 if &test_attr(21, 10);
    L35129: return 0 unless &global_var(116) == 0;
    L35132: &clear_attr(21, 14);
    L35135: &global_var(116, 1);
    L35138: # print "[abbrev 77]disturbing [abbrev 0]leaves[abbrev 3]a [abbrev 34][abbrev 5]revealed[abbrev 10]"
        &write_text(&decode_text(35139));
    L35165: return 1;
}

sub rtn35166 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35169: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L35173: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L35177: return 0 unless &global_var(59) == 0;
    L35180: $stack[@stack] = z_call(28324, \@locv, \@stack, 35187, 0, 23730);
    L35187: return (pop @stack);
}

sub rtn35188 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35189: goto L35201 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L35193: goto L35209 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L35197: goto L35209 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L35201: $stack[@stack] = z_call(28324, \@locv, \@stack, 35208, 0, 23730);
    L35208: return (pop @stack);
    L35209: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (94, 19);
    L35215: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (67);
    L35219: # print "[abbrev 1]"
        &write_text(&decode_text(35220));
    L35222: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L35224: # print " [abbrev 5][abbrev 95]lost [abbrev 22][abbrev 0]river."
        &write_text(&decode_text(35225));
    L35239: &newline();
    L35240: $stack[@stack] = z_call(31496, \@locv, \@stack, 35246, 0, &global_var(59));
    L35246: return (pop @stack);
}

sub rtn35248 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35249: goto L35272 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 32);
    L35255: goto L35265 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (15);
    L35259: $stack[@stack] = z_call(27474, \@locv, \@stack, 35264, 0);
    L35264: return (pop @stack);
    L35265: $stack[@stack] = z_call(30150, \@locv, \@stack, 35271, 0, 23);
    L35271: return (pop @stack);
    L35272: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L35276: # print "[abbrev 1][abbrev 36]River flows under [abbrev 0]rainbow."
        &write_text(&decode_text(35277));
	&newline();
	return(1);
}

sub rtn35302 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35303: goto L35320 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30, 37);
    L35309: $stack[@stack] = z_call(31720, \@locv, \@stack, 35319, 0, 176, 22880, 24836);
    L35319: return (pop @stack);
    L35320: goto L35365 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L35324: goto L35365 if &test_attr(18, 10);
    L35328: # print "[abbrev 1]window [abbrev 5]slightly ajar[abbrev 3][abbrev 48][abbrev 49]enough [abbrev 12]allow entry."
        &write_text(&decode_text(35329));
	&newline();
	return(1);
    L35365: goto L35392 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 24, 102);
    L35372: goto L35382 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L35376: push @stack, 30;
    L35379: goto L35385;
    L35382: push @stack, 29;
    L35385: $stack[@stack] = z_call(30150, \@locv, \@stack, 35391, 0, pop(@stack));
    L35391: return (pop @stack);
    L35392: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (47);
    L35396: # print "[abbrev 2][abbrev 68]see a "
        &write_text(&decode_text(35397));
    L35405: goto L35422 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L35409: # print "forest clearing."
        &write_text(&decode_text(35410));
	&newline();
	return(1);
    L35422: # print "kitchen."
        &write_text(&decode_text(35423));
	&newline();
	return(1);
}

sub rtn35430 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35433: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L35437: # print "[abbrev 2][abbrev 13][abbrev 22][abbrev 0]kitchen [abbrev 9][abbrev 0][abbrev 69]house[abbrev 10][abbrev 28]table [abbrev 75]been used recently [abbrev 42][abbrev 0]preparati[abbrev 59][abbrev 9]food[abbrev 10][abbrev 28][abbrev 55][abbrev 44][abbrev 60][abbrev 6]a dark [abbrev 92][abbrev 44]upward[abbrev 10][abbrev 28]chimney [abbrev 44]down [abbrev 6][abbrev 12][abbrev 0]east"
        &write_text(&decode_text(35438));
    L35530: $stack[@stack] = z_call(34436, \@locv, \@stack, 35535, 0);
    L35535: return (pop @stack);
}

sub rtn35536 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35537: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (89);
    L35541: return 0 unless &global_var(59) == &get_object(&thing_location(10, 'parent'));
    L35545: # print "Hot peppers!"
        &write_text(&decode_text(35546));
	&newline();
	return(1);
}

sub rtn35556 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35557: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (43);
    L35561: &remove_obj(&global_var(59));
    L35563: # print "[abbrev 2][abbrev 45]make friends [abbrev 50]way[abbrev 3][abbrev 48]nobody around [abbrev 21] [abbrev 5][abbrev 74]friendly anyhow[abbrev 10]Gulp!"
        &write_text(&decode_text(35564));
	&newline();
	return(1);
}

sub rtn35612 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35613: goto L35664 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 93);
    L35619: goto L35664 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97);
    L35623: # print "[abbrev 1]bottle shatters."
        &write_text(&decode_text(35624));
    L35638: goto L35656 unless &global_var(59) == &get_object(&thing_location(124, 'parent'));
    L35642: $stack[@stack] = z_call(31496, \@locv, \@stack, 35648, 0, 124);
    L35648: &write_zchar(32);
    L35651: &write_text(&decode_text(&global_var(79) * 2));
    L35653: goto L35657;
    L35656: &newline();
    L35657: $stack[@stack] = z_call(31496, \@locv, \@stack, 35663, 0, &global_var(59));
    L35663: return (pop @stack);
    L35664: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (87);
    L35668: return 0 unless &test_attr(&global_var(59), 10);
    L35672: return 0 unless &global_var(59) == &get_object(&thing_location(124, 'parent'));
    L35676: $stack[@stack] = z_call(31496, \@locv, \@stack, 35682, 0, 124);
    L35682: &write_text(&decode_text(&global_var(79) * 2));
    L35684: return 1;
}

sub rtn35686 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35687: goto L35708 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (24, 29);
    L35693: &write_text(&decode_text(&global_var(64) * 2));
    L35695: # print "swim [abbrev 22][abbrev 0]dungeon."
        &write_text(&decode_text(35696));
	&newline();
	return(1);
    L35708: goto L35721 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (49);
    L35712: $stack[@stack] = z_call(14964, \@locv, \@stack, 35720, 0, 19, &global_var(126), &global_var(59));
    L35720: return 1;
    L35721: goto L35740 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L35725: goto L35740 unless 97 == &get_object(&thing_location(&global_var(59), 'parent'));
    L35729: goto L35740 unless &global_var(126) == 0;
    L35732: $stack[@stack] = z_call(14964, \@locv, \@stack, 35739, 0, 73, 97);
    L35739: return 1;
    L35740: goto L35907 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19, 73);
    L35747: goto L35907 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L35754: goto L35775 unless &global_var(126) == 0;
    L35757: $stack[@stack] = z_call(31442, \@locv, \@stack, 35763, 0, 97);
    L35763: goto L35772 if pop(@stack) == 0;
    L35766: &global_var(126, 97);
    L35769: goto L35775;
    L35772: &global_var(126, 4);
    L35775: goto L35796 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (4);
    L35779: # print "[abbrev 1][abbrev 43]slips [abbrev 20][abbrev 4]fingers."
        &write_text(&decode_text(35780));
	&newline();
	return(1);
    L35796: $stack[@stack] = z_call(31442, \@locv, \@stack, 35802, 0, &global_var(126));
    L35802: goto L35815 unless pop(@stack) == 0;
    L35805: &write_text(&decode_text(&global_var(80) * 2));
    L35807: # print "[abbrev 0]"
        &write_text(&decode_text(35808));
    L35810: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L35812: &write_text(&decode_text(&global_var(7) * 2));
    L35814: return 1;
    L35815: goto L35863 if $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97);
    L35819: goto L35829 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L35823: $stack[@stack] = z_call(31496, \@locv, \@stack, 35829, 0, 124);
    L35829: # print "[abbrev 1][abbrev 43]leaks out [abbrev 9][abbrev 0]"
        &write_text(&decode_text(35830));
    L35842: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L35844: # print " [abbrev 6]evaporates immediately."
        &write_text(&decode_text(35845));
	&newline();
	return(1);
    L35863: goto L35881 if &test_attr(97, 10);
    L35867: &global_var(122, 97);
    L35870: # print "[abbrev 1]bottle [abbrev 5][abbrev 27]."
        &write_text(&decode_text(35871));
	&newline();
	return(1);
    L35881: return 0 if $stack[@stack] = get_child(97);
    L35885: &insert_obj(124, 97);
    L35888: # print "[abbrev 1]bottle [abbrev 5][abbrev 95]full [abbrev 9]water."
        &write_text(&decode_text(35889));
	&newline();
	return(1);
    L35907: goto L35935 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L35911: goto L35935 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3, 124);
    L35917: $stack[@stack] = z_call(31286, \@locv, \@stack, 35923, 0, 163);
    L35923: goto L35935 if pop(@stack) == 0;
    L35926: $stack[@stack] = z_call(14964, \@locv, \@stack, 35934, 0, 19, &global_var(59), 163);
    L35934: return 1;
    L35935: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (93, 52, 41);
    L35942: return 0 unless 97 == &get_object(&thing_location(124, 'parent'));
    L35946: goto L35961 if &test_attr(97, 10);
    L35950: # print "[abbrev 1]bottle [abbrev 5][abbrev 27]."
        &write_text(&decode_text(35951));
	&newline();
	return(1);
    L35961: $stack[@stack] = z_call(31496, \@locv, \@stack, 35967, 0, 124);
    L35967: &write_text(&decode_text(&global_var(79) * 2));
    L35969: return 1;
}

sub rtn35970 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L35971: goto L36056 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (95);
    L35976: goto L36041 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (41);
    L35981: goto L35987 if &global_var(90) == 0;
    L35984: &write_text(&decode_text(&global_var(105) * 2));
    L35986: return 1;
    L35987: &global_var(90, 1);
    L35990: &set_attr(42, 6);
    L35993: &set_attr(42, 11);
    L35996: &set_attr(42, 23);
    L35999: &insert_obj(42, &global_var(0));
    L36002: # print "[abbrev 1]rope drops over [abbrev 0]side [abbrev 6]comes with[abbrev 22]ten [abbrev 64][abbrev 9][abbrev 0]floor."
        &write_text(&decode_text(36003));
	&newline();
	return(1);
    L36041: &write_text(&decode_text(&global_var(64) * 2));
    L36043: # print "tie [abbrev 0]rope [abbrev 12][abbrev 41]."
        &write_text(&decode_text(36044));
	&newline();
	return(1);
    L36056: goto L36090 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (96);
    L36060: goto L36090 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (42);
    L36064: # print "[abbrev 1]"
        &write_text(&decode_text(36065));
    L36067: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L36069: # print " struggles [abbrev 6][abbrev 8][abbrev 47]tie him up."
        &write_text(&decode_text(36070));
	&newline();
	return(1);
    L36090: goto L36141 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (98);
    L36094: goto L36124 if &global_var(90) == 0;
    L36097: &global_var(90, 0);
    L36100: &clear_attr(42, 6);
    L36103: &clear_attr(42, 11);
    L36106: &clear_attr(42, 23);
    L36109: # print "[abbrev 1]rope [abbrev 5][abbrev 95]untied."
        &write_text(&decode_text(36110));
	&newline();
	return(1);
    L36124: # print "[abbrev 38][abbrev 5][abbrev 49]tied [abbrev 12]anything."
        &write_text(&decode_text(36125));
	&newline();
	return(1);
    L36141: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L36145: return 0 if &global_var(90) == 0;
    L36148: # print "[abbrev 1]rope [abbrev 5]tied [abbrev 12][abbrev 0]railing."
        &write_text(&decode_text(36149));
	&newline();
	return(1);
}

sub rtn36168 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36169: goto L36194 if &global_var(113) == 0;
    L36172: goto L36178 unless &test_attr(174, 10);
    L36176: return 22;
    L36178: &global_var(122, 174);
    L36181: # print "[abbrev 1]trap [abbrev 66][abbrev 5][abbrev 27]."
        &write_text(&decode_text(36182));
    L36192: &newline();
    L36193: return 0;
    L36194: &write_text(&decode_text(&global_var(36) * 2));
    L36196: return 0;
}

sub rtn36198 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36201: goto L36395 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L36206: # print "[abbrev 1]living [abbrev 26]opens [abbrev 12][abbrev 0]east[abbrev 10]To [abbrev 0][abbrev 60][abbrev 5]a"
        &write_text(&decode_text(36207));
    L36233: goto L36253 if &global_var(76) == 0;
    L36236: # print " [abbrev 67]-shaped opening [abbrev 22]a"
        &write_text(&decode_text(36237));
    L36253: # print " [abbrev 76]door[abbrev 3]above [abbrev 24][abbrev 5]strange gothic lettering[abbrev 10]"
        &write_text(&decode_text(36254));
    L36284: goto L36302 unless &global_var(76) == 0;
    L36287: # print "[abbrev 1][abbrev 66][abbrev 5]nailed shut[abbrev 10]"
        &write_text(&decode_text(36288));
    L36302: # print "[abbrev 7][abbrev 5]a trophy case [abbrev 21][abbrev 3][abbrev 6]a"
        &write_text(&decode_text(36303));
    L36321: goto L36366 if &global_var(113) == 0;
    L36324: # print " rug lying beside a"
        &write_text(&decode_text(36325));
    L36339: goto L36351 unless &test_attr(174, 10);
    L36343: # print "n open"
        &write_text(&decode_text(36344));
    L36348: goto L36354;
    L36351: # print " [abbrev 27]"
        &write_text(&decode_text(36352));
    L36354: # print " trap door"
        &write_text(&decode_text(36355));
    L36363: goto L36391;
    L36366: # print " [abbrev 14]oriental rug [abbrev 22][abbrev 0]center [abbrev 9][abbrev 0]room"
        &write_text(&decode_text(36367));
    L36391: &write_zchar(46);
    L36394: return 1;
    L36395: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L36399: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L36403: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (136);
    L36407: $stack[@stack] = z_call(36478, \@locv, \@stack, 36413, 0, 136);
    L36413: return 0 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (15);
    L36417: return 0 unless $t1 = &global_var(1), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (325);
    L36423: return 0 unless &global_var(98) == 0;
    L36426: &global_var(98, 1);
    L36429: &global_var(1, 350);
    L36434: &clear_attr(16, 14);
    L36437: &clear_attr(46, 13);
    L36440: # print "[abbrev 28]voice whispers[abbrev 3]"Look [abbrev 12][abbrev 4][abbrev 91][abbrev 42][abbrev 0]final secret.""
        &write_text(&decode_text(36441));
	&newline();
	return(1);
}

sub rtn36478 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36485: goto L36489 if $locv[1] = get_child($locv[0]);
    L36489: goto L36494 unless $locv[1] == 0;
    L36492: return $locv[2];
    L36494: goto L36500 unless &test_attr($locv[1], 4);
    L36498: ($locv[2] = ($locv[2] + 1) & 0xffff);
    L36500: $stack[@stack] = z_call(36478, \@locv, \@stack, 36506, 0, $locv[1]);
    L36506: $locv[2] = unpack('s', pack('s', $locv[2])) + unpack('s', pack('s', pop(@stack)));
    L36510: goto L36489 if $locv[1] = get_sibling($locv[1]);
    L36515: goto L36489;
}

sub rtn36518 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36519: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L36523: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (136);
    L36527: $stack[@stack] = z_call(31686, \@locv, \@stack, 36535, 0, 136, 24786);
    L36535: return (pop @stack);
}

sub rtn36536 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36537: goto L36554 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (93);
    L36541: # print "[abbrev 2]might break it!"
        &write_text(&decode_text(36542));
	&newline();
	return(1);
    L36554: goto L36580 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46, 21, 18);
    L36561: goto L36580 unless &test_attr(102, 24);
    L36565: # print "[abbrev 1]lamp [abbrev 75]burned out."
        &write_text(&decode_text(36566));
	&newline();
	return(1);
    L36580: goto L36597 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L36584: $stack[@stack] = z_call(15178, \@locv, \@stack, 36591, 0, 18322);
    L36591: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L36596: return 0;
    L36597: goto L36614 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L36601: $stack[@stack] = z_call(15178, \@locv, \@stack, 36608, 0, 18322);
    L36608: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L36613: return 0;
    L36614: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L36618: # print "[abbrev 1]lamp [abbrev 5]o"
        &write_text(&decode_text(36619));
    L36627: goto L36637 unless &test_attr(102, 19);
    L36631: &write_zchar(110);
    L36634: goto L36640;
    L36637: # print "ff"
        &write_text(&decode_text(36638));
    L36640: &write_text(&decode_text(&global_var(7) * 2));
    L36642: return 1;
}

sub rtn36644 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36649: $locv[1] = &global_var(45);
    L36652: $locv[0] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L36656: $stack[@stack] = z_call(15158, \@locv, \@stack, 36664, 0, 18322, $locv[0]);
    L36664: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L36669: $stack[@stack] = z_call(31220, \@locv, \@stack, 36677, 0, 102, $locv[1], $locv[0]);
    L36677: return 0 if $locv[0] == 0;
    L36680: &global_var(45, unpack('s', pack('s', $locv[1])) + 4);
    L36684: return &global_var(45);
}

sub rtn36686 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36687: goto L36702 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (66, 37);
    L36693: # print "[abbrev 38][abbrev 45]open."
        &write_text(&decode_text(36694));
	&newline();
	return(1);
    L36702: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 25);
    L36708: # print "Nice try."
        &write_text(&decode_text(36709));
	&newline();
	return(1);
}

sub rtn36718 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36719: goto L36775 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73, 78);
    L36725: # print "[abbrev 1]rug [abbrev 5][abbrev 74]heavy [abbrev 12]lift"
        &write_text(&decode_text(36726));
    L36742: goto L36772 unless &global_var(113) == 0;
    L36745: # print "[abbrev 3][abbrev 48][abbrev 8]noticed [abbrev 73]irregularity beneath it"
        &write_text(&decode_text(36746));
    L36772: &write_text(&decode_text(&global_var(7) * 2));
    L36774: return 1;
    L36775: goto L36837 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (77, 69);
    L36781: goto L36787 if &global_var(113) == 0;
    L36784: &write_text(&decode_text(&global_var(105) * 2));
    L36786: return 1;
    L36787: &clear_attr(174, 14);
    L36790: &global_var(122, 174);
    L36793: &global_var(113, 1);
    L36796: # print "[abbrev 2]drag [abbrev 0]rug [abbrev 12][abbrev 94]side [abbrev 9][abbrev 0]room[abbrev 3]revealing a [abbrev 27] trap door."
        &write_text(&decode_text(36797));
	&newline();
	return(1);
    L36837: goto L36852 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L36841: goto L36852 unless &global_var(113) == 0;
    L36844: $stack[@stack] = z_call(31616, \@locv, \@stack, 36851, 0, 40, 174);
    L36851: return (pop @stack);
    L36852: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (28);
    L36856: goto L36898 unless &global_var(113) == 0;
    L36859: # print "As [abbrev 8]try [abbrev 12]sit[abbrev 3][abbrev 8]notice [abbrev 73]irregularity beneath [abbrev 0]rug."
        &write_text(&decode_text(36860));
	&newline();
	return(1);
    L36898: # print "[abbrev 23][abbrev 49]a magic carpet."
        &write_text(&decode_text(36899));
	&newline();
	return(1);
}

sub rtn36914 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L36915: goto L36927 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (78);
    L36919: goto L36935 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L36923: goto L36935 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (53);
    L36927: $stack[@stack] = z_call(14964, \@locv, \@stack, 36934, 0, 37, 174);
    L36934: return 1;
    L36935: goto L36956 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30, 37);
    L36941: goto L36956 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (53);
    L36945: $stack[@stack] = z_call(31720, \@locv, \@stack, 36955, 0, &global_var(59), 23658, 23678);
    L36955: return (pop @stack);
    L36956: return 0 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (22);
    L36960: goto L36985 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97, 37);
    L36966: goto L36985 if &test_attr(174, 10);
    L36970: # print "[abbrev 23]latched [abbrev 18]above."
        &write_text(&decode_text(36971));
	&newline();
	return(1);
    L36985: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L36989: return 0 unless &test_attr(174, 10);
    L36993: &clear_attr(174, 10);
    L36996: # print "[abbrev 1][abbrev 66]latches shut."
        &write_text(&decode_text(36997));
	&newline();
	return(1);
}

sub rtn37010 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37013: goto L37096 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L37018: # print "[abbrev 2][abbrev 13][abbrev 22]a dark[abbrev 3]damp cellar [abbrev 11][abbrev 46]passageways [abbrev 12][abbrev 0][abbrev 61][abbrev 6]east[abbrev 10]On [abbrev 0][abbrev 60][abbrev 5][abbrev 0]bottom [abbrev 9]a steep metal ramp [abbrev 24][abbrev 5]unclimbable."
        &write_text(&decode_text(37019));
    L37095: return 1;
    L37096: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L37100: return 0 unless &test_attr(174, 10);
    L37104: return 0 if &test_attr(174, 13);
    L37108: &clear_attr(174, 10);
    L37111: &set_attr(174, 13);
    L37114: # print "[abbrev 1]trap [abbrev 66]crashes shut[abbrev 3][abbrev 6][abbrev 8]hear some[abbrev 94]barring it."
        &write_text(&decode_text(37115));
    L37149: &newline();
    L37150: &newline();
    L37151: return 1;
}

sub rtn37152 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37155: goto L37159 if $locv[0] = get_child(&global_var(115));
    L37159: $stack[@stack] = z_call(29794, \@locv, \@stack, 37165, 0, 30);
    L37165: goto L37178 unless unpack('s', pack('s', pop(@stack))) < 3;
    L37169: goto L37176 if &test_attr(174, 10);
    L37173: &clear_attr(174, 13);
    L37176: return 18;
    L37178: &write_text(&decode_text(&global_var(64) * 2));
    L37180: # print "fit [abbrev 11]what you're carrying."
        &write_text(&decode_text(37181));
    L37201: &newline();
    L37202: return 0;
}

sub rtn37204 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37205: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36);
    L37209: # print "Some paint chips away[abbrev 3]revealing more paint."
        &write_text(&decode_text(37210));
	&newline();
	return(1);
}

sub rtn37242 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37243: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36);
    L37247: # print "Don't [abbrev 40]a vandal!"
        &write_text(&decode_text(37248));
	&newline();
	return(1);
}

sub rtn37262 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37265: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L37269: return 0 unless &global_var(0) == &get_object(&thing_location(103, 'parent'));
    L37273: $stack[@stack] = z_call(15158, \@locv, \@stack, 37281, 0, 16885, 2);
    L37281: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L37286: &global_var(122, 103);
    L37289: return &global_var(122);
}

sub rtn37292 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37293: goto L37327 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L37297: &global_var(29, 0);
    L37300: # print "He's [abbrev 49]much [abbrev 9]a conversationalist."
        &write_text(&decode_text(37301));
	&newline();
	return(1);
    L37327: goto L37339 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L37331: $stack[@stack] = &get_prop(103, 14);
    L37335: &write_text(&decode_text(pop(@stack) * 2));
    L37337: &newline();
    L37338: return 1;
    L37339: goto L37368 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36);
    L37343: # print "[abbrev 1]troll laughs at [abbrev 4]puny gesture."
        &write_text(&decode_text(37344));
	&newline();
	return(1);
    L37368: goto L37443 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (52, 93);
    L37375: # print "[abbrev 1]troll grabs [abbrev 0]"
        &write_text(&decode_text(37376));
    L37388: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L37390: # print " and[abbrev 3][abbrev 49]having [abbrev 0]most discriminating tastes[abbrev 3]gleefully eats it."
        &write_text(&decode_text(37391));
    L37435: &newline();
    L37436: $stack[@stack] = z_call(31496, \@locv, \@stack, 37442, 0, &global_var(59));
    L37442: return (pop @stack);
    L37443: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (62);
    L37447: # print "[abbrev 1]troll [abbrev 5]mumbling [abbrev 22]a guttural tongue."
        &write_text(&decode_text(37448));
	&newline();
	return(1);
}

sub rtn37476 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37479: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L37483: # print "[abbrev 2][abbrev 13][abbrev 51][abbrev 9]"
        &write_text(&decode_text(37484));
    L37490: goto L37498 if &global_var(11) == 0;
    L37493: &write_text(&decode_text(&global_var(5) * 2));
    L37495: goto L37521;
    L37498: # print "a [abbrev 14]lake[abbrev 3]far [abbrev 74]deep [abbrev 6]wide [abbrev 12]be"
        &write_text(&decode_text(37499));
    L37521: # print " crossed[abbrev 10]Paths lead east[abbrev 3][abbrev 78][abbrev 3][abbrev 6][abbrev 58]."
        &write_text(&decode_text(37522));
    L37548: return 1;
}

sub rtn37550 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37553: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L37557: # print "[abbrev 2][abbrev 13]atop Flood Control Dam #3[abbrev 3][abbrev 24]was once quite a tourist attraction[abbrev 10][abbrev 7][abbrev 13]exits [abbrev 12][abbrev 0][abbrev 93][abbrev 6]west[abbrev 3][abbrev 6]a scramble down[abbrev 10][abbrev 1]"
        &write_text(&decode_text(37558));
    L37638: goto L37697 if &global_var(11) == 0;
    L37641: # print "[abbrev 43]level behind [abbrev 0]dam [abbrev 5]low; [abbrev 0]gates [abbrev 13]open [abbrev 6][abbrev 43]rushes [abbrev 20][abbrev 0]dam [abbrev 6]downstream"
        &write_text(&decode_text(37642));
    L37694: goto L37770;
    L37697: # print "sluice gates [abbrev 59][abbrev 0]dam [abbrev 13][abbrev 27][abbrev 10]Behind [abbrev 0]dam [abbrev 5]a wide reservoir[abbrev 10]Water [abbrev 5]pouring over [abbrev 0]top [abbrev 9][abbrev 0]abandoned dam"
        &write_text(&decode_text(37698));
    L37770: # print "[abbrev 10][abbrev 7][abbrev 5]a control panel [abbrev 21][abbrev 3][abbrev 59][abbrev 24]a [abbrev 14]metal bolt [abbrev 5]mounted[abbrev 10]Above [abbrev 0]bolt [abbrev 5]a [abbrev 25]green plastic bubble"
        &write_text(&decode_text(37771));
    L37835: goto L37853 if &global_var(77) == 0;
    L37838: # print " [abbrev 24][abbrev 5]glowing serenely"
        &write_text(&decode_text(37839));
    L37853: &write_zchar(46);
    L37856: return 1;
}

sub rtn37858 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L37861: goto L37985 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (25, 18);
    L37868: goto L37985 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12);
    L37873: goto L37894 if unpack('s', pack('s', &global_var(65))) > 0;
    L37877: # print "[abbrev 2][abbrev 19]run out [abbrev 9]matches."
        &write_text(&decode_text(37878));
	&newline();
	return(1);
    L37894: &global_var(65, "--");
    L37896: goto L37929 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (121, 139);
    L37902: # print "[abbrev 28]draft instantly blows [abbrev 0]match out."
        &write_text(&decode_text(37903));
	&newline();
	return(1);
    L37929: &set_attr(12, 25);
    L37932: &set_attr(12, 19);
    L37935: $stack[@stack] = z_call(15158, \@locv, \@stack, 37943, 0, 19066, 2);
    L37943: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L37948: # print "One [abbrev 9][abbrev 0]matches starts [abbrev 12]burn."
        &write_text(&decode_text(37949));
    L37971: &newline();
    L37972: return 1 unless &global_var(38) == 0;
    L37975: &global_var(38, 1);
    L37978: &newline();
    L37979: $stack[@stack] = z_call(25076, \@locv, \@stack, 37984, 0);
    L37984: return 1;
    L37985: goto L38025 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L37989: goto L38025 unless &test_attr(12, 25);
    L37993: &clear_attr(12, 25);
    L37996: &clear_attr(12, 19);
    L37999: $stack[@stack] = z_call(15158, \@locv, \@stack, 38007, 0, 19066, 0);
    L38007: # print "[abbrev 1]match [abbrev 5]out."
        &write_text(&decode_text(38008));
    L38018: &newline();
    L38019: $stack[@stack] = z_call(31514, \@locv, \@stack, 38024, 0);
    L38024: return (pop @stack);
    L38025: goto L38068 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37, 31);
    L38031: $locv[0] = unpack('s', pack('s', &global_var(65))) - 1;
    L38035: # print "[abbrev 2][abbrev 19]"
        &write_text(&decode_text(38036));
    L38040: goto L38050 if unpack('s', pack('s', $locv[0])) > 0;
    L38044: # print "no"
        &write_text(&decode_text(38045));
    L38047: goto L38053;
    L38050: &write_text(unpack('s', pack('s', $locv[0])));
    L38053: # print " match"
        &write_text(&decode_text(38054));
    L38058: goto L38065 if $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L38062: # print "es"
        &write_text(&decode_text(38063));
    L38065: &write_text(&decode_text(&global_var(7) * 2));
    L38067: return 1;
    L38068: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L38072: goto L38091 unless &test_attr(12, 19);
    L38076: # print "[abbrev 1]match [abbrev 5]burning."
        &write_text(&decode_text(38077));
	&newline();
	return(1);
    L38091: # print "[abbrev 1]matchbook [abbrev 5]uninteresting[abbrev 3]except [abbrev 42]what's written [abbrev 59]it."
        &write_text(&decode_text(38092));
	&newline();
	return(1);
}

sub rtn38132 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38133: # print "[abbrev 1]match [abbrev 75]g[abbrev 94]out."
        &write_text(&decode_text(38134));
    L38146: &newline();
    L38147: &clear_attr(12, 25);
    L38150: &clear_attr(12, 19);
    L38153: $stack[@stack] = z_call(31514, \@locv, \@stack, 38158, 0);
    L38158: return (pop @stack);
}

sub rtn38160 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38161: goto L38258 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (70);
    L38166: goto L38236 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (171);
    L38171: goto L38223 if &global_var(77) == 0;
    L38174: goto L38223 unless &global_var(11) == 0;
    L38177: &clear_attr(85, 13);
    L38180: &set_attr(64, 7);
    L38183: &clear_attr(64, 3);
    L38186: &clear_attr(166, 14);
    L38189: &global_var(11, 1);
    L38192: &global_var(1, unpack('s', pack('s', &global_var(1))) + 20);
    L38196: # print "[abbrev 1]sluice gates open [abbrev 6][abbrev 43]pours [abbrev 20][abbrev 0]dam."
        &write_text(&decode_text(38197));
	&newline();
	return(1);
    L38223: # print "[abbrev 1]bolt [abbrev 45]budge."
        &write_text(&decode_text(38224));
	&newline();
	return(1);
    L38236: # print "[abbrev 1]bolt [abbrev 45]turn using [abbrev 0]"
        &write_text(&decode_text(38237));
    L38253: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L38255: &write_text(&decode_text(&global_var(7) * 2));
    L38257: return 1;
    L38258: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L38262: &write_text(&decode_text(&global_var(85) * 2));
    L38264: return 1;
}

sub rtn38266 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38267: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L38271: &write_text(&decode_text(&global_var(85) * 2));
    L38273: return 1;
}

sub rtn38274 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38275: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30, 37);
    L38281: # print "Sounds reasonable[abbrev 3][abbrev 48][abbrev 50][abbrev 37]how."
        &write_text(&decode_text(38282));
	&newline();
	return(1);
}

sub rtn38304 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38305: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (77);
    L38309: goto L38346 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (148);
    L38313: # print "[abbrev 1][abbrev 26]lights "
        &write_text(&decode_text(38314));
    L38322: goto L38336 unless &test_attr(&global_var(0), 19);
    L38326: &clear_attr(&global_var(0), 19);
    L38329: # print "go off."
        &write_text(&decode_text(38330));
	&newline();
	return(1);
    L38336: &set_attr(&global_var(0), 19);
    L38339: # print "come on."
        &write_text(&decode_text(38340));
	&newline();
	return(1);
    L38346: goto L38363 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (104);
    L38350: &clear_attr(161, 13);
    L38353: &global_var(77, 0);
    L38356: # print "Click."
        &write_text(&decode_text(38357));
	&newline();
	return(1);
    L38363: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (47);
    L38367: &clear_attr(161, 13);
    L38370: &global_var(77, 1);
    L38373: # print "Click."
        &write_text(&decode_text(38374));
	&newline();
	return(1);
}

sub rtn38380 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38381: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (49, 22);
    L38387: goto L38399 if &global_var(0) == &get_object(&thing_location(160, 'parent'));
    L38391: $stack[@stack] = z_call(38734, \@locv, \@stack, 38398, 0, 23853);
    L38398: return (pop @stack);
    L38399: goto L38470 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (77);
    L38404: &insert_obj(143, &global_var(0));
    L38407: &global_var(122, 143);
    L38410: # print "[abbrev 1]boat inflates [abbrev 6][abbrev 56]seaworthy."
        &write_text(&decode_text(38411));
    L38433: goto L38462 if &test_attr(122, 13);
    L38437: # print " [abbrev 28]t[abbrev 73]label [abbrev 5]lying inside [abbrev 0]boat."
        &write_text(&decode_text(38438));
    L38462: &newline();
    L38463: $stack[@stack] = z_call(31496, \@locv, \@stack, 38469, 0, 160);
    L38469: return (pop @stack);
    L38470: goto L38495 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (109);
    L38474: # print "[abbrev 2]haven't enough lung power."
        &write_text(&decode_text(38475));
	&newline();
	return(1);
    L38495: # print "[abbrev 82]a "
        &write_text(&decode_text(38496));
    L38500: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L38502: # print "!?!"
        &write_text(&decode_text(38503));
	&newline();
	return(1);
}

sub rtn38508 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38513: goto L38631 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L38518: goto L38565 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (102);
    L38522: goto L38542 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26, 117, 32);
    L38529: return 0 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 30, 19);
    L38536: return 0 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (22, 23);
    L38542: goto L38552 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (64);
    L38546: return 0 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (31, 28);
    L38552: # print "Read [abbrev 0]t[abbrev 73]label!"
        &write_text(&decode_text(38553));
	&newline();
	return(1);
    L38565: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (61);
    L38569: goto L38580 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26, 117, 32);
    L38576: goto L38583 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (64);
    L38580: &write_text(&decode_text(&global_var(105) * 2));
    L38582: return 1;
    L38583: $locv[1] = z_call(41596, \@locv, \@stack, 38589, 2, &global_var(72));
    L38589: goto L38614 unless $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L38593: $stack[@stack] = z_call(41622, \@locv, \@stack, 38600, 0, &global_var(0), &global_var(51));
    L38600: $stack[@stack] = z_call(15158, \@locv, \@stack, 38608, 0, 20751, pop(@stack));
    L38608: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L38613: return 1;
    L38614: return 1 if $t1 = $locv[1], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L38618: &write_text(&decode_text(&global_var(64) * 2));
    L38620: # print "launch it [abbrev 21]."
        &write_text(&decode_text(38621));
	&newline();
	return(1);
    L38631: return 0 unless $locv[0] == 0;
    L38634: goto L38667 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (49, 22);
    L38640: # print "Inflating it further might burst it."
        &write_text(&decode_text(38641));
	&newline();
	return(1);
    L38667: goto L38721 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (35);
    L38671: goto L38682 unless 143 == &get_object(&thing_location(30, 'parent'));
    L38675: # print "[abbrev 30][abbrev 22]it!"
        &write_text(&decode_text(38676));
	&newline();
	return(1);
    L38682: goto L38694 if &global_var(0) == &get_object(&thing_location(143, 'parent'));
    L38686: $stack[@stack] = z_call(38734, \@locv, \@stack, 38693, 0, 24230);
    L38693: return (pop @stack);
    L38694: &insert_obj(160, &global_var(0));
    L38697: &global_var(122, 160);
    L38700: # print "[abbrev 1]boat deflates."
        &write_text(&decode_text(38701));
    L38713: &newline();
    L38714: $stack[@stack] = z_call(31496, \@locv, \@stack, 38720, 0, 143);
    L38720: return (pop @stack);
    L38721: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (28);
    L38725: $stack[@stack] = z_call(14964, \@locv, \@stack, 38732, 0, 24, &global_var(59));
    L38732: return 1;
}

sub rtn38734 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38737: &write_text(&decode_text(&global_var(64) * 2));
    L38739: &write_text(&decode_text($locv[0] * 2));
    L38741: # print "flate it unless it's [abbrev 59][abbrev 0][abbrev 53]."
        &write_text(&decode_text(38742));
	&newline();
	return(1);
}

sub rtn38762 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38763: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26, 27);
    L38769: # print "[abbrev 1]cliff [abbrev 5]unclimbable."
        &write_text(&decode_text(38770));
	&newline();
	return(1);
}

sub rtn38786 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38789: goto L38914 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L38794: # print "[abbrev 2][abbrev 13]at [abbrev 0]periphery [abbrev 9]a [abbrev 14]dome[abbrev 3][abbrev 24]forms [abbrev 0]ceiling [abbrev 9]another [abbrev 26]below[abbrev 10][abbrev 28][abbrev 76]railing protects [abbrev 8][abbrev 18]a precipitous drop."
        &write_text(&decode_text(38795));
    L38871: return 0 if &global_var(90) == 0;
    L38874: # print " [abbrev 28]rope hangs [abbrev 18][abbrev 0]rail [abbrev 6]ends [abbrev 54]ten [abbrev 64][abbrev 18][abbrev 0]floor below."
        &write_text(&decode_text(38875));
    L38913: return 1;
    L38914: goto L38979 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L38919: goto L38979 if &global_var(88) == 0;
    L38922: &insert_obj(&global_var(115), 78);
    L38925: &global_var(0, 78);
    L38928: # print "As [abbrev 8]enter[abbrev 3]a strong pull as if [abbrev 18]a wind draws [abbrev 8]over [abbrev 0]railing [abbrev 6]down."
        &write_text(&decode_text(38929));
	&newline();
	return(1);
    L38979: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L38983: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L38987: $stack[@stack] = z_call(28324, \@locv, \@stack, 38994, 0, 23730);
    L38994: return (pop @stack);
}

sub rtn38996 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L38997: return 0;
}

sub rtn38998 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39001: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L39005: # print "[abbrev 15][abbrev 5]a [abbrev 14]domed temple[abbrev 10]"
        &write_text(&decode_text(39006));
    L39022: goto L39091 if &global_var(90) == 0;
    L39026: # print "[abbrev 28]piece [abbrev 9]rope descends [abbrev 18][abbrev 0]railing [abbrev 9][abbrev 0]dome[abbrev 3][abbrev 54]20 [abbrev 64]above[abbrev 3]ending some five [abbrev 64]above [abbrev 4]head[abbrev 10]"
        &write_text(&decode_text(39027));
    L39091: # print "On [abbrev 0][abbrev 65]wall [abbrev 5][abbrev 73]ancient inscription[abbrev 3][abbrev 71]a prayer [abbrev 22]a long-forgotten language[abbrev 10]Below [abbrev 0]prayer[abbrev 3]a stair [abbrev 44]down[abbrev 10][abbrev 1]temple's altar [abbrev 5][abbrev 12][abbrev 0][abbrev 78][abbrev 10][abbrev 77][abbrev 0]center [abbrev 9][abbrev 0][abbrev 26]sits a [abbrev 69]marble pedestal."
        &write_text(&decode_text(39092));
    L39214: return 1;
}

sub rtn39216 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39217: goto L39236 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L39221: # print "[abbrev 1]torch [abbrev 5]burning."
        &write_text(&decode_text(39222));
	&newline();
	return(1);
    L39236: goto L39271 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (74);
    L39240: goto L39271 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L39244: # print "[abbrev 1][abbrev 43]evaporates before it gets close."
        &write_text(&decode_text(39245));
	&newline();
	return(1);
    L39271: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L39275: return 0 unless &test_attr(&global_var(59), 19);
    L39279: # print "[abbrev 2]nearly burn [abbrev 4]h[abbrev 6]trying [abbrev 12]extinguish [abbrev 0]flame."
        &write_text(&decode_text(39280));
	&newline();
	return(1);
}

sub rtn39312 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39313: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (82);
    L39317: goto L39324 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (99);
    L39321: return 0 if &global_var(129) == 0;
    L39324: # print "Ding[abbrev 3]dong."
        &write_text(&decode_text(39325));
	&newline();
	return(1);
}

sub rtn39336 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39337: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (78, 103);
    L39343: goto L39352 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (34);
    L39347: goto L39490 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (86);
    L39352: goto L39458 unless &global_var(101) == 0;
    L39356: # print "[abbrev 1][abbrev 84]solidifies [abbrev 6][abbrev 5][abbrev 95]walkable ([abbrev 0]stairs [abbrev 6]bannister [abbrev 13][abbrev 0]giveaway)."
        &write_text(&decode_text(39357));
    L39403: goto L39450 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (86);
    L39407: goto L39450 unless 86 == &get_object(&thing_location(105, 'parent'));
    L39411: goto L39450 unless &test_attr(105, 14);
    L39415: # print " [abbrev 28]shimmering pot [abbrev 9]gold [abbrev 56]at [abbrev 0]end [abbrev 9][abbrev 0]rainbow."
        &write_text(&decode_text(39416));
    L39450: &clear_attr(105, 14);
    L39453: &global_var(101, 1);
    L39456: &newline();
    L39457: return 1;
    L39458: &global_var(101, 0);
    L39461: # print "[abbrev 1][abbrev 84][abbrev 75]become somewhat run-of-the-mill."
        &write_text(&decode_text(39462));
	&newline();
	return(1);
    L39490: # print "Dazzling colors briefly emanate [abbrev 18][abbrev 0]sceptre."
        &write_text(&decode_text(39491));
	&newline();
	return(1);
}

sub rtn39524 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39527: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L39531: goto L39539 if &global_var(115) == &get_object(&thing_location(120, 'parent'));
    L39535: &global_var(71, 1);
    L39538: return 0;
    L39539: &global_var(71, 0);
    L39542: return 0;
}

sub rtn39544 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39545: goto L39562 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37);
    L39549: # print "[abbrev 1]book [abbrev 5][abbrev 35]open."
        &write_text(&decode_text(39550));
	&newline();
	return(1);
    L39562: goto L39583 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30);
    L39566: # print "Oddly[abbrev 3][abbrev 0]book [abbrev 47][abbrev 40][abbrev 27]."
        &write_text(&decode_text(39567));
	&newline();
	return(1);
    L39583: goto L39601 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (70);
    L39587: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (80);
    L39591: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (135);
    L39595: return 0 if $t1 = &global_var(112), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (569);
    L39601: # print "Beside page 569[abbrev 3]t[abbrev 21] [abbrev 5]only [abbrev 94]page [abbrev 11]legible printing[abbrev 10][abbrev 38][abbrev 52][abbrev 12][abbrev 40][abbrev 54][abbrev 0]banishment [abbrev 9]evil using certa[abbrev 22]noises[abbrev 3]lights[abbrev 3][abbrev 6]prayers."
        &write_text(&decode_text(39602));
	&newline();
	return(1);
}

sub rtn39688 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L39689: goto L39705 if &test_attr(17, 13);
    L39693: $stack[@stack] = z_call(15178, \@locv, \@stack, 39700, 0, 20048);
    L39700: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L39705: return 0 if $t1 = 17, grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(126));
    L39709: goto L39883 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (25, 18);
    L39716: goto L39751 unless &test_attr(17, 24);
    L39720: # print "Alas[abbrev 3]t[abbrev 21]'s [abbrev 49]enough candle left [abbrev 12]burn."
        &write_text(&decode_text(39721));
	&newline();
	return(1);
    L39751: goto L39764 unless &test_attr(17, 19);
    L39755: &write_text(&decode_text(&global_var(56) * 2));
    L39757: # print "[abbrev 35]lit!"
        &write_text(&decode_text(39758));
	&newline();
	return(1);
    L39764: goto L39802 unless &global_var(126) == 0;
    L39767: goto L39792 unless &test_attr(12, 25);
    L39771: # print "([abbrev 11][abbrev 0]match)"
        &write_text(&decode_text(39772));
    L39782: &newline();
    L39783: $stack[@stack] = z_call(14964, \@locv, \@stack, 39791, 0, 18, 17, 12);
    L39791: return 1;
    L39792: # print "[abbrev 82]what?"
        &write_text(&decode_text(39793));
    L39799: &newline();
    L39800: return 2;
    L39802: goto L39834 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (12);
    L39806: goto L39834 unless &test_attr(12, 19);
    L39810: &set_attr(17, 19);
    L39813: $stack[@stack] = z_call(15178, \@locv, \@stack, 39820, 0, 20048);
    L39820: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L39825: &write_text(&decode_text(&global_var(56) * 2));
    L39827: # print "[abbrev 13][abbrev 95]lit."
        &write_text(&decode_text(39828));
	&newline();
	return(1);
    L39834: goto L39873 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (8);
    L39838: # print "[abbrev 1]torch's heat vaporizes [abbrev 0]candles."
        &write_text(&decode_text(39839));
    L39865: &newline();
    L39866: $stack[@stack] = z_call(31496, \@locv, \@stack, 39872, 0, 17);
    L39872: return (pop @stack);
    L39873: $stack[@stack] = z_call(14218, \@locv, \@stack, 39879, 0, &global_var(107));
    L39879: &write_text(&decode_text(pop(@stack) * 2));
    L39881: &newline();
    L39882: return 1;
    L39883: goto L39924 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (31);
    L39887: # print "[abbrev 80]many [abbrev 22]a pair? Don't tell me[abbrev 3]I'll get it..."
        &write_text(&decode_text(39888));
	&newline();
	return(1);
    L39924: goto L39985 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L39928: $stack[@stack] = z_call(15178, \@locv, \@stack, 39935, 0, 20048);
    L39935: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L39940: goto L39974 unless &test_attr(17, 19);
    L39944: &clear_attr(17, 19);
    L39947: &set_attr(17, 13);
    L39950: # print "[abbrev 1]flame [abbrev 5]extinguished."
        &write_text(&decode_text(39951));
    L39967: &newline();
    L39968: $stack[@stack] = z_call(31514, \@locv, \@stack, 39973, 0);
    L39973: return (pop @stack);
    L39974: &write_text(&decode_text(&global_var(56) * 2));
    L39976: # print "[abbrev 49]lighted."
        &write_text(&decode_text(39977));
	&newline();
	return(1);
    L39985: goto L40002 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L39989: goto L40002 unless &test_attr(&global_var(126), 26);
    L39993: $stack[@stack] = z_call(14964, \@locv, \@stack, 40001, 0, 25, &global_var(126), 17);
    L40001: return 1;
    L40002: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L40006: &write_text(&decode_text(&global_var(56) * 2));
    L40008: goto L40019 unless &test_attr(17, 19);
    L40012: # print "burning."
        &write_text(&decode_text(40013));
	&newline();
	return(1);
    L40019: # print "out."
        &write_text(&decode_text(40020));
	&newline();
	return(1);
}

sub rtn40024 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40027: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L40031: return 0 unless &global_var(115) == &get_object(&thing_location(17, 'parent'));
    L40035: return 0 unless &test_attr(17, 19);
    L40039: $stack[@stack] = z_call(14192, \@locv, \@stack, 40045, 0, 50);
    L40045: return 0 if pop(@stack) == 0;
    L40048: $stack[@stack] = z_call(15178, \@locv, \@stack, 40055, 0, 20048);
    L40055: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40060: &clear_attr(17, 19);
    L40063: # print "[abbrev 28]gust [abbrev 9]wind blows out [abbrev 4]candles!"
        &write_text(&decode_text(40064));
    L40088: &newline();
    L40089: $stack[@stack] = z_call(31514, \@locv, \@stack, 40094, 0);
    L40094: return (pop @stack);
}

sub rtn40096 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40101: $locv[1] = &global_var(97);
    L40104: &set_attr(17, 13);
    L40107: $locv[0] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L40111: $stack[@stack] = z_call(15158, \@locv, \@stack, 40119, 0, 20048, $locv[0]);
    L40119: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40124: $stack[@stack] = z_call(31220, \@locv, \@stack, 40132, 0, 17, $locv[1], $locv[0]);
    L40132: return 0 if $locv[0] == 0;
    L40135: &global_var(97, unpack('s', pack('s', $locv[1])) + 4);
    L40139: return &global_var(97);
}

sub rtn40142 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40145: goto L40349 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L40150: # print "[abbrev 2][abbrev 13]outside a [abbrev 14]gate inscribed[abbrev 3]"Aband[abbrev 59]hope all ye who enter [abbrev 21]!" [abbrev 1]gate [abbrev 5]open; beyond [abbrev 8][abbrev 68]see a desolation[abbrev 3][abbrev 11]a pile [abbrev 9]mangled bodies [abbrev 22][abbrev 94]corner[abbrev 10]Thousands [abbrev 9]voices[abbrev 3]lamenting some hideous fate[abbrev 3][abbrev 68][abbrev 40]heard."
        &write_text(&decode_text(40151));
    L40297: return 0 unless &global_var(129) == 0;
    L40300: return 0 unless &global_var(88) == 0;
    L40303: # print " [abbrev 1]gate [abbrev 5]barred by evil spirits[abbrev 3]who jeer at [abbrev 4]attempts [abbrev 12]pass."
        &write_text(&decode_text(40304));
    L40348: return 1;
    L40349: goto L40730 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L40354: goto L40414 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L40358: goto L40365 if &global_var(129) == 0;
    L40361: &write_text(&decode_text(&global_var(105) * 2));
    L40363: &newline();
    L40364: return 1;
    L40365: $stack[@stack] = z_call(31442, \@locv, \@stack, 40371, 0, 58);
    L40371: goto L40395 if pop(@stack) == 0;
    L40374: $stack[@stack] = z_call(31442, \@locv, \@stack, 40380, 0, 75);
    L40380: goto L40395 if pop(@stack) == 0;
    L40383: $stack[@stack] = z_call(31442, \@locv, \@stack, 40389, 0, 17);
    L40389: goto L40395 if pop(@stack) == 0;
    L40392: &write_text(&decode_text(&global_var(8) * 2));
    L40394: return 1;
    L40395: # print "[abbrev 30][abbrev 49]equipped [abbrev 42][abbrev 73]exorcism."
        &write_text(&decode_text(40396));
	&newline();
	return(1);
    L40414: goto L40588 unless &global_var(129) == 0;
    L40418: goto L40588 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (82);
    L40423: goto L40588 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (58);
    L40428: &global_var(50, 1);
    L40431: $stack[@stack] = z_call(15158, \@locv, \@stack, 40439, 0, 20494, 6);
    L40439: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40444: # print "[abbrev 28]deep peal issues [abbrev 18][abbrev 0]bell[abbrev 10][abbrev 1]wraiths stop jeering [abbrev 6][abbrev 73]expressi[abbrev 59][abbrev 9]long-forgotten terror takes shape [abbrev 59]their ashen faces."
        &write_text(&decode_text(40445));
    L40529: goto L40586 unless &global_var(115) == &get_object(&thing_location(17, 'parent'));
    L40533: &insert_obj(17, &global_var(0));
    L40536: &clear_attr(17, 19);
    L40539: $stack[@stack] = z_call(15178, \@locv, \@stack, 40546, 0, 20048);
    L40546: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40551: # print " [abbrev 77][abbrev 4]confusion[abbrev 3][abbrev 0][abbrev 89]drop [abbrev 12][abbrev 0][abbrev 53] ([abbrev 6]they [abbrev 13]out)."
        &write_text(&decode_text(40552));
	&newline();
	return(1);
    L40586: &newline();
    L40587: return 1;
    L40588: return 0 if &global_var(124) == 0;
    L40591: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (79);
    L40595: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (75);
    L40599: return 0 unless &global_var(129) == 0;
    L40602: &remove_obj(149);
    L40604: &global_var(129, 1);
    L40607: $stack[@stack] = z_call(15178, \@locv, \@stack, 40614, 0, 20541);
    L40614: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40619: # print "[abbrev 1]prayer reverberates [abbrev 22]a deafening confusion[abbrev 10]As [abbrev 0]last word fades[abbrev 3]a heart-stopping scream fills [abbrev 0]cavern[abbrev 3][abbrev 6][abbrev 0]spirits[abbrev 3]sensing a greater power[abbrev 3]flee [abbrev 20][abbrev 0]walls."
        &write_text(&decode_text(40620));
	&newline();
	return(1);
    L40730: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L40734: return 0 if &global_var(50) == 0;
    L40737: return 0 unless &global_var(115) == &get_object(&thing_location(17, 'parent'));
    L40741: return 0 unless &test_attr(17, 19);
    L40745: return 0 unless &global_var(124) == 0;
    L40748: &global_var(124, 1);
    L40751: $stack[@stack] = z_call(15178, \@locv, \@stack, 40758, 0, 20494);
    L40758: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40763: $stack[@stack] = z_call(15158, \@locv, \@stack, 40771, 0, 20541, 3);
    L40771: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L40776: # print "[abbrev 1]flames flicker wildly [abbrev 6][abbrev 0]earth trembles beneath [abbrev 4]feet[abbrev 10][abbrev 1]spirits cower at [abbrev 4]unearthly power."
        &write_text(&decode_text(40777));
	&newline();
	return(1);
}

sub rtn40844 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40845: goto L40856 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29);
    L40849: $stack[@stack] = z_call(30150, \@locv, \@stack, 40855, 0, 21);
    L40855: return (pop @stack);
    L40856: # print "[abbrev 1]gate [abbrev 5]protected by [abbrev 73]invisible force[abbrev 10][abbrev 38]makes [abbrev 4]teeth ache [abbrev 12]touch it."
        &write_text(&decode_text(40857));
	&newline();
	return(1);
}

sub rtn40908 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40909: goto L40944 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L40913: # print "[abbrev 1]spirits jeer loudly [abbrev 6]ignore you."
        &write_text(&decode_text(40914));
    L40938: &newline();
    L40939: &global_var(29, 0);
    L40942: return &global_var(29);
    L40944: goto L40951 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (48);
    L40948: &write_text(&decode_text(&global_var(8) * 2));
    L40950: return 1;
    L40951: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 20);
    L40957: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (149);
    L40961: &write_text(&decode_text(&global_var(64) * 2));
    L40963: # print "attack a spirit [abbrev 11]material objects!"
        &write_text(&decode_text(40964));
	&newline();
	return(1);
}

sub rtn40988 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L40989: goto L41076 unless &global_var(124) == 0;
    L40993: goto L41076 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29);
    L40998: # print "[abbrev 1]tensi[abbrev 59][abbrev 9][abbrev 50]ceremony [abbrev 5]broken[abbrev 3][abbrev 6][abbrev 0]wraiths[abbrev 3]amused [abbrev 48]shaken at [abbrev 4]clumsy attempt[abbrev 3]resume their hideous jeering."
        &write_text(&decode_text(40999));
    L41075: &newline();
    L41076: &global_var(50, 0);
    L41079: return &global_var(50);
}

sub rtn41082 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41083: &global_var(124, 0);
    L41086: $stack[@stack] = z_call(40988, \@locv, \@stack, 41091, 0);
    L41091: return (pop @stack);
}

sub rtn41092 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41093: goto L41102 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L41097: # print "Yuk!"
        &write_text(&decode_text(41098));
	&newline();
	return(1);
    L41102: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (20, 25, 36);
    L41109: $stack[@stack] = z_call(28324, \@locv, \@stack, 41116, 0, 23786);
    L41116: return (pop @stack);
}

sub rtn41118 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41119: goto L41130 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37);
    L41123: $stack[@stack] = z_call(22516, \@locv, \@stack, 41129, 0, 81);
    L41129: return 0;
    L41130: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L41134: return 0 if 30 == &get_object(&thing_location(123, 'parent'));
    L41138: return 0 unless 123 == &get_object(&thing_location(81, 'parent'));
    L41142: &insert_obj(123, 30);
    L41145: # print "As [abbrev 8]take [abbrev 0]buoy[abbrev 3][abbrev 8]notice something odd [abbrev 54][abbrev 0]feel [abbrev 9]it."
        &write_text(&decode_text(41146));
	&newline();
	return(1);
}

sub rtn41184 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41185: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (38);
    L41189: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (91);
    L41193: goto L41217 unless unpack('s', pack('s', &global_var(49, "++"))) > 3;
    L41197: &global_var(49, 65535);
    L41202: goto L41209 unless &global_var(0) == &get_object(&thing_location(88, 'parent'));
    L41206: &set_attr(88, 14);
    L41209: $stack[@stack] = z_call(28324, \@locv, \@stack, 41216, 0, 23821);
    L41216: return (pop @stack);
    L41217: goto L41250 unless $t1 = &global_var(49), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L41221: return 0 unless &test_attr(88, 14);
    L41225: &global_var(122, 88);
    L41228: &clear_attr(88, 14);
    L41231: # print "[abbrev 2]spot a scarab [abbrev 22][abbrev 0]sand."
        &write_text(&decode_text(41232));
	&newline();
	return(1);
    L41250: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(40) + 2*&global_var(49)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L41254: &write_text(&decode_text(pop(@stack) * 2));
    L41256: &newline();
    L41257: return 1;
}

sub rtn41258 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41261: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L41265: # print "[abbrev 2][abbrev 13]near [abbrev 0]top [abbrev 9]Araga[abbrev 22]Falls[abbrev 10][abbrev 1]only path [abbrev 44][abbrev 79][abbrev 10][abbrev 28]"
        &write_text(&decode_text(41266));
    L41302: goto L41313 if &global_var(101) == 0;
    L41305: # print "solid"
        &write_text(&decode_text(41306));
    L41310: goto L41320;
    L41313: # print "beautiful"
        &write_text(&decode_text(41314));
    L41320: # print " [abbrev 84]spans [abbrev 0]falls [abbrev 12][abbrev 0]west."
        &write_text(&decode_text(41321));
    L41339: return 1;
}

sub rtn41340 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41341: goto L41437 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L41346: goto L41437 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (163);
    L41351: goto L41363 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L41355: $stack[@stack] = z_call(14964, \@locv, \@stack, 41362, 0, 29, 163);
    L41362: return 1;
    L41363: goto L41380 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (143);
    L41367: # print "Read [abbrev 0]t[abbrev 73]label!"
        &write_text(&decode_text(41368));
	&newline();
	return(1);
    L41380: goto L41411 unless &test_attr(&global_var(59), 26);
    L41384: # print "[abbrev 1]current sweeps it away."
        &write_text(&decode_text(41385));
    L41403: &newline();
    L41404: $stack[@stack] = z_call(31496, \@locv, \@stack, 41410, 0, &global_var(59));
    L41410: return (pop @stack);
    L41411: # print "[abbrev 1]"
        &write_text(&decode_text(41412));
    L41414: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L41416: # print " sinks [abbrev 31][abbrev 0]water."
        &write_text(&decode_text(41417));
    L41429: &newline();
    L41430: $stack[@stack] = z_call(31496, \@locv, \@stack, 41436, 0, &global_var(59));
    L41436: return (pop @stack);
    L41437: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 56);
    L41443: # print "[abbrev 1]river [abbrev 5]wide [abbrev 6]dangerous[abbrev 3][abbrev 11]swift currents [abbrev 6]hidden rocks[abbrev 10][abbrev 2]decide [abbrev 12]forgo [abbrev 4]swim."
        &write_text(&decode_text(41444));
	&newline();
	return(1);
}

sub rtn41502 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41505: goto L41525 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26, 117, 32);
    L41512: $stack[@stack] = z_call(15178, \@locv, \@stack, 41519, 0, 20751);
    L41519: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L41524: return 1;
    L41525: $locv[0] = z_call(41622, \@locv, \@stack, 41532, 1, &global_var(0), &global_var(52));
    L41532: goto L41587 if $locv[0] == 0;
    L41535: $stack[@stack] = z_call(41622, \@locv, \@stack, 41542, 0, &global_var(0), &global_var(51));
    L41542: $stack[@stack] = z_call(15158, \@locv, \@stack, 41550, 0, 20751, pop(@stack));
    L41550: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L41555: # print "[abbrev 1]current carries [abbrev 8]downstream."
        &write_text(&decode_text(41556));
    L41578: &newline();
    L41579: &newline();
    L41580: $stack[@stack] = z_call(29852, \@locv, \@stack, 41586, 0, $locv[0]);
    L41586: return (pop @stack);
    L41587: $stack[@stack] = z_call(28324, \@locv, \@stack, 41594, 0, 24188);
    L41594: return (pop @stack);
}

sub rtn41596 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41601: $locv[1] = z_call(41622, \@locv, \@stack, 41608, 2, &global_var(0), $locv[0]);
    L41608: return 0 if $locv[1] == 0;
    L41611: $stack[@stack] = z_call(29852, \@locv, \@stack, 41617, 0, $locv[1]);
    L41617: return 1 unless pop(@stack) == 0;
    L41620: return 2;
}

sub rtn41622 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0, 0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41631: $locv[3] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L41635: return 0 if unpack('s', pack('s', ($locv[2] = ($locv[2] + 1) & 0xffff))) > unpack('s', pack('s', $locv[3]));
    L41639: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*$locv[2]) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L41643: goto L41635 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[0]);
    L41648: return 0 if $t1 = $locv[2], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} ($locv[3]);
    L41652: $stack[@stack] = unpack('s', pack('s', $locv[2])) + 1;
    L41656: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=($locv[1] + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L41660: return (pop @stack);
}

sub rtn41662 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41665: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L41669: goto L41728 if &global_var(11) == 0;
    L41672: # print "[abbrev 2][abbrev 13][abbrev 59]what used [abbrev 12][abbrev 40]a [abbrev 14]lake[abbrev 3][abbrev 48][abbrev 24][abbrev 5][abbrev 95]a [abbrev 14]mud pile[abbrev 10][abbrev 7][abbrev 13]"shores" [abbrev 12][abbrev 0][abbrev 61][abbrev 6][abbrev 78]."
        &write_text(&decode_text(41673));
    L41727: return 1;
    L41728: # print "[abbrev 2][abbrev 13][abbrev 59][abbrev 0]lake [abbrev 11]beaches [abbrev 12][abbrev 0][abbrev 61][abbrev 6][abbrev 51][abbrev 6]a dam [abbrev 12][abbrev 0]east."
        &write_text(&decode_text(41729));
    L41763: return 1;
}

sub rtn41764 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41765: goto L41779 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 91);
    L41771: $stack[@stack] = z_call(14964, \@locv, \@stack, 41778, 0, 24, 124);
    L41778: return 1;
    L41779: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (32);
    L41783: $stack[@stack] = z_call(27474, \@locv, \@stack, 41788, 0);
    L41788: return (pop @stack);
}

sub rtn41790 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41791: goto L41809 if &global_var(11) == 0;
    L41794: # print "[abbrev 1]lake's gone..."
        &write_text(&decode_text(41795));
	&newline();
	return(1);
    L41809: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (29, 32);
    L41815: $stack[@stack] = z_call(14964, \@locv, \@stack, 41822, 0, 24, 124);
    L41822: return 1;
}

sub rtn41824 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41825: $stack[@stack] = z_call(31546, \@locv, \@stack, 41833, 0, 166, 23728);
    L41833: return (pop @stack);
}

sub rtn41834 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41837: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L41841: # print "[abbrev 2][abbrev 13][abbrev 22]cavern [abbrev 12][abbrev 0][abbrev 61][abbrev 9]"
        &write_text(&decode_text(41842));
    L41856: goto L41864 if &global_var(11) == 0;
    L41859: &write_text(&decode_text(&global_var(5) * 2));
    L41861: goto L41871;
    L41864: # print "a [abbrev 14]lake"
        &write_text(&decode_text(41865));
    L41871: # print "[abbrev 10][abbrev 28]slimy stairway climbs [abbrev 12][abbrev 0][abbrev 79]."
        &write_text(&decode_text(41872));
    L41896: return 1;
}

sub rtn41898 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41899: goto L41914 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26, 27, 29);
    L41906: goto L41934 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L41910: goto L41934 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (13);
    L41914: goto L41924 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (22);
    L41918: push @stack, 29;
    L41921: goto L41927;
    L41924: push @stack, 22;
    L41927: $stack[@stack] = z_call(30150, \@locv, \@stack, 41933, 0, pop(@stack));
    L41933: return (pop @stack);
    L41934: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L41938: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (168);
    L41942: return 0 unless &test_attr(&global_var(59), 17);
    L41946: # print "[abbrev 1]"
        &write_text(&decode_text(41947));
    L41949: &write_text(&decode_text(&thing_location(&global_var(59), 'name')));
    L41951: # print " dis[abbrev 56][abbrev 31][abbrev 0]slide."
        &write_text(&decode_text(41952));
    L41964: &newline();
    L41965: goto L41976 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L41969: $stack[@stack] = z_call(31496, \@locv, \@stack, 41975, 0, 124);
    L41975: return (pop @stack);
    L41976: &insert_obj(&global_var(59), 22);
    L41979: return 1;
}

sub rtn41980 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L41983: goto L42011 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L41987: # print "[abbrev 2][abbrev 13][abbrev 22]a [abbrev 25][abbrev 26][abbrev 11]exits [abbrev 12][abbrev 0][abbrev 65][abbrev 6][abbrev 78]."
        &write_text(&decode_text(41988));
    L42010: return 1;
    L42011: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L42015: return 0 unless &global_var(88) == 0;
    L42018: $stack[@stack] = get_parent(155);
    L42021: return 0 if $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115), &global_var(0));
    L42027: &newline();
    L42028: $stack[@stack] = z_call(42176, \@locv, \@stack, 42033, 0);
    L42033: return (pop @stack);
}

sub rtn42034 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42037: $stack[@stack] = get_parent(155);
    L42040: goto L42087 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115), &global_var(0));
    L42046: # print "[abbrev 77][abbrev 0]corner [abbrev 9][abbrev 0]ceiling[abbrev 3]a [abbrev 14]vampire bat [abbrev 5]holding [abbrev 63]nose."
        &write_text(&decode_text(42047));
	&newline();
	return(1);
    L42087: # print "[abbrev 28][abbrev 14]vampire bat swoops down at you!"
        &write_text(&decode_text(42088));
	&newline();
	return(1);
}

sub rtn42112 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42113: goto L42128 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (84);
    L42117: $stack[@stack] = z_call(42224, \@locv, \@stack, 42123, 0, 6);
    L42123: &global_var(29, 0);
    L42126: return &global_var(29);
    L42128: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 20, 73);
    L42135: $stack[@stack] = get_parent(155);
    L42138: goto L42169 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (&global_var(115), &global_var(0));
    L42144: &write_text(&decode_text(&global_var(64) * 2));
    L42146: # print "reach him; he's [abbrev 59][abbrev 0]ceiling."
        &write_text(&decode_text(42147));
	&newline();
	return(1);
    L42169: $stack[@stack] = z_call(42176, \@locv, \@stack, 42174, 0);
    L42174: return (pop @stack);
}

sub rtn42176 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42177: $stack[@stack] = z_call(42224, \@locv, \@stack, 42183, 0, 4);
    L42183: # print "[abbrev 1]bat grabs [abbrev 8][abbrev 6]lifts [abbrev 8]away..."
        &write_text(&decode_text(42184));
    L42208: &newline();
    L42209: &newline();
    L42210: $stack[@stack] = z_call(14218, \@locv, \@stack, 42216, 0, &global_var(106));
    L42216: $stack[@stack] = z_call(29852, \@locv, \@stack, 42222, 0, pop(@stack));
    L42222: return (pop @stack);
}

sub rtn42224 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42227: goto L42244 if unpack('s', pack('s', ($locv[0] = ($locv[0] - 1) & 0xffff))) < 1;
    L42231: # print "    Fweep!"
        &write_text(&decode_text(42232));
    L42240: &newline();
    L42241: goto L42227;
    L42244: &newline();
    L42245: return 1;
}

sub rtn42246 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42247: goto L42271 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (69);
    L42251: goto L42260 if &global_var(84) == 0;
    L42254: push @stack, 67;
    L42257: goto L42263;
    L42260: push @stack, 78;
    L42263: $stack[@stack] = z_call(14964, \@locv, \@stack, 42270, 0, pop(@stack), 127);
    L42270: return 1;
    L42271: goto L42321 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (78);
    L42275: goto L42281 if &global_var(84) == 0;
    L42278: &write_text(&decode_text(&global_var(99) * 2));
    L42280: return 1;
    L42281: &insert_obj(127, 178);
    L42284: &global_var(84, 1);
    L42287: # print "[abbrev 1]basket [abbrev 5]raised [abbrev 12][abbrev 0]top [abbrev 9][abbrev 0]shaft."
        &write_text(&decode_text(42288));
    L42314: &newline();
    L42315: $stack[@stack] = z_call(31514, \@locv, \@stack, 42320, 0);
    L42320: return (pop @stack);
    L42321: goto L42373 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (67);
    L42325: goto L42331 unless &global_var(84) == 0;
    L42328: &write_text(&decode_text(&global_var(99) * 2));
    L42330: return 1;
    L42331: &insert_obj(127, 121);
    L42334: &global_var(84, 0);
    L42337: # print "[abbrev 1]basket [abbrev 5]lowered [abbrev 12][abbrev 0]bottom [abbrev 9][abbrev 0]shaft."
        &write_text(&decode_text(42338));
    L42366: &newline();
    L42367: $stack[@stack] = z_call(31514, \@locv, \@stack, 42372, 0);
    L42372: return (pop @stack);
    L42373: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L42377: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (127);
    L42381: $stack[@stack] = z_call(31686, \@locv, \@stack, 42389, 0, 127, 22855);
    L42389: return (pop @stack);
}

sub rtn42390 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42391: goto L42408 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L42395: # print "[abbrev 1]cha[abbrev 22][abbrev 5]secure."
        &write_text(&decode_text(42396));
	&newline();
	return(1);
    L42408: goto L42423 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (69, 67, 78);
    L42415: $stack[@stack] = z_call(14964, \@locv, \@stack, 42422, 0, &global_var(75), 127);
    L42422: return 1;
    L42423: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L42427: return 0 unless &global_var(0) == &get_object(&thing_location(127, 'parent'));
    L42431: $stack[@stack] = &get_prop(127, 14);
    L42435: &write_text(&decode_text(pop(@stack) * 2));
    L42437: &newline();
    L42438: return 1;
}

sub rtn42440 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42443: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (6);
    L42447: $stack[@stack] = z_call(31442, \@locv, \@stack, 42453, 0, 17);
    L42453: goto L42460 if pop(@stack) == 0;
    L42456: goto L42486 if &test_attr(17, 19);
    L42460: $stack[@stack] = z_call(31442, \@locv, \@stack, 42466, 0, 8);
    L42466: goto L42473 if pop(@stack) == 0;
    L42469: goto L42486 if &test_attr(8, 19);
    L42473: $stack[@stack] = z_call(31442, \@locv, \@stack, 42479, 0, 12);
    L42479: return 0 if pop(@stack) == 0;
    L42482: return 0 unless &test_attr(12, 19);
    L42486: $stack[@stack] = z_call(28324, \@locv, \@stack, 42493, 0, 25801);
    L42493: return (pop @stack);
}

sub rtn42494 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42495: goto L42520 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (23);
    L42499: # print "[abbrev 7][abbrev 5][abbrev 74]much gas [abbrev 12]blow away."
        &write_text(&decode_text(42500));
	&newline();
	return(1);
    L42520: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (89);
    L42524: # print "[abbrev 38]smells like coal gas [abbrev 22][abbrev 21]."
        &write_text(&decode_text(42525));
	&newline();
	return(1);
}

sub rtn42546 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42547: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (26);
    L42551: $stack[@stack] = z_call(30150, \@locv, \@stack, 42557, 0, 23);
    L42557: return (pop @stack);
}

sub rtn42558 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0, 0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42563: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L42567: goto L42571 if $locv[1] = get_child(&global_var(115));
    L42571: &global_var(109, 1);
    L42574: goto L42590 if $locv[1] == 0;
    L42577: $stack[@stack] = z_call(29816, \@locv, \@stack, 42583, 0, $locv[1]);
    L42583: goto L42608 unless unpack('s', pack('s', pop(@stack))) > 4;
    L42587: &global_var(109, 0);
    L42590: return 0 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (121);
    L42594: return 0 if &global_var(38) == 0;
    L42597: return 0 unless &global_var(35) == 0;
    L42600: &global_var(35, 1);
    L42603: &global_var(1, unpack('s', pack('s', &global_var(1))) + 10);
    L42607: return 0;
    L42608: goto L42574 if $locv[1] = get_sibling($locv[1]);
    L42613: goto L42574;
}

sub rtn42616 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42619: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L42623: # print "[abbrev 15][abbrev 5]a chilly [abbrev 26]whose sole exit [abbrev 5][abbrev 12][abbrev 0][abbrev 79][abbrev 10][abbrev 77][abbrev 94]corner [abbrev 5]a machine[abbrev 3]reminiscent [abbrev 9]a clothes dryer[abbrev 3][abbrev 11]a switch labelled "START"[abbrev 10][abbrev 1]switch does [abbrev 49]appear [abbrev 12][abbrev 40]manipulable by any hum[abbrev 73]h[abbrev 6](unless [abbrev 0]fingers [abbrev 13][abbrev 54]1/16 by 1/4 inch)[abbrev 10][abbrev 1]machine [abbrev 75]a [abbrev 14]lid[abbrev 3][abbrev 24][abbrev 5]"
        &write_text(&decode_text(42624));
    L42798: goto L42808 unless &test_attr(142, 10);
    L42802: # print "open."
        &write_text(&decode_text(42803));
    L42807: return 1;
    L42808: # print "[abbrev 27]."
        &write_text(&decode_text(42809));
    L42813: return 1;
}

sub rtn42814 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42815: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (18);
    L42819: goto L42839 unless &global_var(126) == 0;
    L42822: &write_text(&decode_text(&global_var(64) * 2));
    L42824: # print "do it [abbrev 11][abbrev 4]b[abbrev 13]hands."
        &write_text(&decode_text(42825));
	&newline();
	return(1);
    L42839: $stack[@stack] = z_call(14964, \@locv, \@stack, 42847, 0, 70, 71, &global_var(126));
    L42847: return 1;
}

sub rtn42848 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42851: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (70);
    L42855: goto L42970 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (80);
    L42860: goto L42867 unless &test_attr(142, 10);
    L42864: &write_text(&decode_text(&global_var(119) * 2));
    L42866: return 1;
    L42867: goto L42871 if $locv[0] = get_child(142);
    L42871: $stack[@stack] = z_call(32432, \@locv, \@stack, 42879, 0, 142, 71, 0);
    L42879: goto L42889 unless 71 == &get_object(&thing_location(44, 'parent'));
    L42883: &insert_obj(133, 142);
    L42886: goto L42895;
    L42889: goto L42895 if $locv[0] == 0;
    L42892: &insert_obj(59, 142);
    L42895: # print "[abbrev 1]machine produces a dazzling display [abbrev 9]colored lights [abbrev 6]bizarre noises[abbrev 10][abbrev 28]moment later[abbrev 3][abbrev 0]excitement abates."
        &write_text(&decode_text(42896));
	&newline();
	return(1);
    L42970: # print "[abbrev 38][abbrev 52][abbrev 17]a "
        &write_text(&decode_text(42971));
    L42977: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L42979: # print " [abbrev 45]do."
        &write_text(&decode_text(42980));
	&newline();
	return(1);
}

sub rtn42986 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L42987: &remove_obj(59);
    L42989: # print "[abbrev 1]insubstantial slag crumbles at [abbrev 4]touch."
        &write_text(&decode_text(42990));
	&newline();
	return(1);
}

sub rtn43018 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43019: $stack[@stack] = z_call(31546, \@locv, \@stack, 43027, 0, 66, 23876);
    L43027: return (pop @stack);
}

sub rtn43028 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43029: goto L43095 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (73);
    L43034: goto L43095 unless &global_var(115) == &get_object(&thing_location(164, 'parent'));
    L43038: # print "As [abbrev 8]touch [abbrev 0]rusty knife[abbrev 3][abbrev 4]sword gives a single pulse [abbrev 9]blinding blue light."
        &write_text(&decode_text(43039));
    L43093: &newline();
    L43094: return 0;
    L43095: goto L43103 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (169);
    L43099: goto L43114 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (20);
    L43103: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (92);
    L43107: return 0 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (169);
    L43111: return 0 if &global_var(126) == 0;
    L43114: &remove_obj(169);
    L43116: $stack[@stack] = z_call(28324, \@locv, \@stack, 43123, 0, 23891);
    L43123: return (pop @stack);
}

sub rtn43124 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43125: goto L43146 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (69, 83, 73);
    L43132: goto L43146 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (67, 78, 77);
    L43139: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (59, 57, 20);
    L43146: $stack[@stack] = z_call(32432, \@locv, \@stack, 43154, 0, &global_var(0), 99, 1);
    L43154: $stack[@stack] = z_call(32432, \@locv, \@stack, 43162, 0, 30, 99, 1);
    L43162: # print "[abbrev 28]ghost appears[abbrev 3]appalled at [abbrev 4]desecrati[abbrev 59][abbrev 9][abbrev 0]remains [abbrev 9]a fellow adventurer[abbrev 10]He curses [abbrev 4]valuables [abbrev 6]banishes them [abbrev 12]Hades[abbrev 10][abbrev 1]ghost leaves[abbrev 3]muttering obscenities."
        &write_text(&decode_text(43163));
	&newline();
	return(1);
}

sub rtn43274 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43277: goto L43285 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L43281: &clear_attr(21, 14);
    L43284: return 1;
    L43285: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L43289: # print "[abbrev 2][abbrev 13][abbrev 22]a [abbrev 26]off [abbrev 0]maze[abbrev 3][abbrev 24]lies [abbrev 12][abbrev 0][abbrev 58][abbrev 10]Above [abbrev 8][abbrev 5]a"
        &write_text(&decode_text(43290));
    L43324: goto L43352 unless &test_attr(21, 10);
    L43328: # print "n open [abbrev 34][abbrev 11]sunlight pouring in."
        &write_text(&decode_text(43329));
    L43351: return 1;
    L43352: goto L43365 if &global_var(19) == 0;
    L43355: # print " grating."
        &write_text(&decode_text(43356));
    L43364: return 1;
    L43365: # print " [abbrev 34]locked [abbrev 11]a skull-and-crossbones lock."
        &write_text(&decode_text(43366));
    L43396: return 1;
}

sub rtn43398 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43399: goto L43416 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (37);
    L43403: goto L43416 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L43407: $stack[@stack] = z_call(14964, \@locv, \@stack, 43415, 0, 97, 21, 65);
    L43415: return 1;
    L43416: goto L43437 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97, 63);
    L43422: goto L43437 unless $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (119);
    L43426: &write_text(&decode_text(&global_var(64) * 2));
    L43428: # print "[abbrev 18][abbrev 50]side."
        &write_text(&decode_text(43429));
	&newline();
	return(1);
    L43437: goto L43451 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (63);
    L43441: &global_var(19, 0);
    L43444: # print "Locked."
        &write_text(&decode_text(43445));
	&newline();
	return(1);
    L43451: goto L43487 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97);
    L43455: goto L43487 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L43459: goto L43475 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (65);
    L43463: &global_var(19, 1);
    L43466: # print "Unlocked."
        &write_text(&decode_text(43467));
	&newline();
	return(1);
    L43475: # print "[abbrev 82]a "
        &write_text(&decode_text(43476));
    L43480: &write_text(&decode_text(&thing_location(&global_var(126), 'name')));
    L43482: # print "!?!"
        &write_text(&decode_text(43483));
	&newline();
	return(1);
    L43487: goto L43506 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (72);
    L43491: # print "[abbrev 2]haven't [abbrev 0]skill."
        &write_text(&decode_text(43492));
	&newline();
	return(1);
    L43506: goto L43593 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30, 37);
    L43513: goto L43582 if &global_var(19) == 0;
    L43517: $stack[@stack] = z_call(31720, \@locv, \@stack, 43527, 0, 21, 23809, 23813);
    L43527: goto L43578 unless &test_attr(21, 10);
    L43531: &set_attr(154, 19);
    L43534: return 1 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (119);
    L43538: return 1 unless &global_var(116) == 0;
    L43541: &global_var(116, 1);
    L43544: &insert_obj(108, &global_var(0));
    L43547: # print "[abbrev 28]pile [abbrev 9]leaves falls on[abbrev 12][abbrev 4]head [abbrev 6][abbrev 12][abbrev 0][abbrev 53]."
        &write_text(&decode_text(43548));
	&newline();
	return(1);
    L43578: &clear_attr(154, 19);
    L43581: return 1;
    L43582: # print "[abbrev 1][abbrev 34][abbrev 5]locked."
        &write_text(&decode_text(43583));
	&newline();
	return(1);
    L43593: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (19);
    L43597: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (21);
    L43601: # print "[abbrev 38][abbrev 45]fit [abbrev 20][abbrev 0]grating."
        &write_text(&decode_text(43602));
	&newline();
	return(1);
}

sub rtn43616 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43619: goto L43650 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (3);
    L43623: # print "[abbrev 15][abbrev 26][abbrev 75]a [abbrev 79][abbrev 60]exit [abbrev 6]a [abbrev 92][abbrev 87]up[abbrev 10]"
        &write_text(&decode_text(43624));
    L43644: $stack[@stack] = z_call(44270, \@locv, \@stack, 43649, 0);
    L43649: return (pop @stack);
    L43650: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L43654: return 1 if &global_var(130) == 0;
    L43657: $stack[@stack] = z_call(15178, \@locv, \@stack, 43664, 0, 22284);
    L43664: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L43669: return 1;
}

sub rtn43670 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L43671: goto L43735 unless $t1 = &global_var(115), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (137);
    L43676: goto L43694 if &global_var(6) == 0;
    L43679: # print "He's fast asleep."
        &write_text(&decode_text(43680));
	&newline();
	return(1);
    L43694: goto L43708 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (71);
    L43698: &global_var(115, 30);
    L43701: $stack[@stack] = z_call(14964, \@locv, \@stack, 43707, 0, 71);
    L43707: return 1;
    L43708: # print "He's [abbrev 49]much [abbrev 9]a conversationalist."
        &write_text(&decode_text(43709));
	&newline();
	return(1);
    L43735: goto L43746 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (46);
    L43739: $stack[@stack] = z_call(44270, \@locv, \@stack, 43744, 0);
    L43744: &newline();
    L43745: return 1;
    L43746: goto L43816 if &global_var(6) == 0;
    L43750: goto L43771 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (20, 57, 100);
    L43757: goto L43771 if $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 25);
    L43763: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (96);
    L43767: return 0 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (42);
    L43771: # print "[abbrev 1][abbrev 16]yawns [abbrev 6]stares at [abbrev 0]thing [abbrev 17]woke him up."
        &write_text(&decode_text(43772));
    L43802: &newline();
    L43803: &global_var(6, 0);
    L43806: return 0 unless unpack('s', pack('s', &global_var(130))) < 0;
    L43810: &global_var(130, 0 - unpack('s', pack('s', &global_var(130))));
    L43814: return &global_var(130);
    L43816: goto L44108 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (52);
    L43821: goto L44108 unless $t1 = &global_var(126), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (137);
    L43826: goto L43950 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (10);
    L43831: $stack[@stack] = z_call(15158, \@locv, \@stack, 43840, 0, 22284, 65535);
    L43840: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L43845: return 0 unless unpack('s', pack('s', &global_var(130))) > -1;
    L43851: &remove_obj(10);
    L43853: $stack[@stack] = 0 - unpack('s', pack('s', &global_var(130)));
    L43857: goto L43871 unless -1 < unpack('s', pack('s', pop(@stack)));
    L43863: &global_var(130, 65535);
    L43868: goto L43875;
    L43871: &global_var(130, 0 - unpack('s', pack('s', &global_var(130))));
    L43875: # print "[abbrev 1][abbrev 16]says[abbrev 3]"Yum[abbrev 3][abbrev 17]made me thirsty[abbrev 10]Perhaps I could drink [abbrev 0]blood [abbrev 9][abbrev 17]thing." [abbrev 38][abbrev 56][abbrev 17]YOU [abbrev 13]"[abbrev 17]thing.""
        &write_text(&decode_text(43876));
	&newline();
	return(1);
    L43950: goto L43964 if $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (124);
    L43954: goto L44070 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (97);
    L43959: goto L44070 unless 97 == &get_object(&thing_location(124, 'parent'));
    L43964: goto L44045 unless unpack('s', pack('s', &global_var(130))) < 0;
    L43969: $stack[@stack] = z_call(31496, \@locv, \@stack, 43975, 0, 124);
    L43975: &insert_obj(97, &global_var(0));
    L43978: &set_attr(97, 10);
    L43981: &global_var(6, 1);
    L43984: # print "[abbrev 1][abbrev 16]empties [abbrev 0]bottle[abbrev 3]yawns[abbrev 3][abbrev 6]falls fast asleep[abbrev 10](What did [abbrev 8]put [abbrev 22][abbrev 17]drink[abbrev 3]anyway?)"
        &write_text(&decode_text(43985));
	&newline();
	return(1);
    L44045: &write_text(&decode_text(&global_var(92) * 2));
    L44047: # print "n't thirsty [abbrev 6]refuses [abbrev 4]offer."
        &write_text(&decode_text(44048));
	&newline();
	return(1);
    L44070: goto L44093 unless $t1 = &global_var(59), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (155);
    L44074: &write_text(&decode_text(&global_var(92) * 2));
    L44076: # print "n't THAT hungry."
        &write_text(&decode_text(44077));
	&newline();
	return(1);
    L44093: # print "[abbrev 1][abbrev 16][abbrev 45]eat THAT!"
        &write_text(&decode_text(44094));
	&newline();
	return(1);
    L44108: goto L44213 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36, 20, 93);
    L44116: $stack[@stack] = z_call(15158, \@locv, \@stack, 44125, 0, 22284, 65535);
    L44125: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L44130: goto L44183 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (36);
    L44134: # print ""Do [abbrev 8]think I'm as stupid as my father was?"[abbrev 3]he says[abbrev 3]dodging."
        &write_text(&decode_text(44135));
	&newline();
	return(1);
    L44183: goto L44190 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (93);
    L44187: &insert_obj(&global_var(59), &global_var(0));
    L44190: # print "[abbrev 1][abbrev 16]ignores [abbrev 4]pitiful attempt."
        &write_text(&decode_text(44191));
	&newline();
	return(1);
    L44213: goto L44244 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (95);
    L44217: # print "[abbrev 2][abbrev 47]tie him[abbrev 3]though he [abbrev 5]fit [abbrev 12][abbrev 40]tied."
        &write_text(&decode_text(44218));
	&newline();
	return(1);
    L44244: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (62);
    L44248: # print "[abbrev 2][abbrev 68]hear [abbrev 63]stomach rumbling."
        &write_text(&decode_text(44249));
	&newline();
	return(1);
}

sub rtn44270 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L44271: goto L44302 if &global_var(76) == 0;
    L44274: # print "[abbrev 1][abbrev 65]wall [abbrev 75]a [abbrev 67]-sized opening [abbrev 22]it."
        &write_text(&decode_text(44275));
    L44301: return 1;
    L44302: goto L44337 if &global_var(6) == 0;
    L44305: # print "[abbrev 1][abbrev 16]sleeps blissfully at [abbrev 0]foot [abbrev 9][abbrev 0]stairs."
        &write_text(&decode_text(44306));
    L44336: return 1;
    L44337: goto L44423 unless &global_var(130) == 0;
    L44341: # print "[abbrev 28]hungry [abbrev 16]blocks [abbrev 0]staircase[abbrev 10]From [abbrev 0]bloodstains [abbrev 59][abbrev 0]walls[abbrev 3][abbrev 8]gather [abbrev 17]he [abbrev 5][abbrev 49]very friendly[abbrev 3]though he likes people."
        &write_text(&decode_text(44342));
    L44422: return 1;
    L44423: goto L44494 unless unpack('s', pack('s', &global_var(130))) > 0;
    L44428: &write_text(&decode_text(&global_var(92) * 2));
    L44430: # print " eyeing [abbrev 8]closely[abbrev 10]I [abbrev 57]think he likes [abbrev 8]very much[abbrev 10]He looks extremely hungry[abbrev 3]even [abbrev 42]a [abbrev 67]."
        &write_text(&decode_text(44431));
    L44493: return 1;
    L44494: return 0 unless unpack('s', pack('s', &global_var(130))) < 0;
    L44498: # print "[abbrev 1][abbrev 67][abbrev 3]having eaten [abbrev 0]hot peppers[abbrev 3][abbrev 56][abbrev 12][abbrev 40]gasping[abbrev 10]H[abbrev 5]enflamed tongue protrudes [abbrev 18][abbrev 63]man-sized mouth."
        &write_text(&decode_text(44499));
    L44567: return 1;
}

sub rtn44568 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L44569: return 1 unless &global_var(6) == 0;
    L44572: return 1 unless &global_var(88) == 0;
    L44575: goto L44592 if $t1 = &global_var(0), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (56);
    L44579: $stack[@stack] = z_call(15178, \@locv, \@stack, 44586, 0, 22284);
    L44586: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L44591: return 1;
    L44592: goto L44603 unless unpack('s', pack('s', &global_var(130))) < 0;
    L44596: $stack[@stack] = 0 - unpack('s', pack('s', &global_var(130)));
    L44600: goto L44606;
    L44603: push @stack, &global_var(130);
    L44606: goto L44630 unless unpack('s', pack('s', pop(@stack))) > 5;
    L44610: $stack[@stack] = z_call(15178, \@locv, \@stack, 44617, 0, 22284);
    L44617: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 0)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L44622: $stack[@stack] = z_call(28324, \@locv, \@stack, 44629, 0, 23600);
    L44629: return (pop @stack);
    L44630: goto L44639 unless unpack('s', pack('s', &global_var(130))) < 0;
    L44634: &global_var(130, "--");
    L44636: goto L44641;
    L44639: &global_var(130, "++");
    L44641: return 0 unless &global_var(6) == 0;
    L44644: &write_text(&decode_text(&global_var(92) * 2));
    L44646: goto L44657 unless unpack('s', pack('s', &global_var(130))) < 0;
    L44650: $stack[@stack] = 0 - unpack('s', pack('s', &global_var(130)));
    L44654: goto L44660;
    L44657: push @stack, &global_var(130);
    L44660: $stack[@stack] = unpack('s', pack('s', pop(@stack))) - 1;
    L44664: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(&global_var(33) + 2*pop(@stack)) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L44668: &write_text(&decode_text(pop(@stack) * 2));
    L44670: &newline();
    L44671: return 1;
}

sub rtn44672 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = (0);
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L44675: return 0 unless $t1 = $locv[0], grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (2);
    L44679: $stack[@stack] = z_call(15178, \@locv, \@stack, 44686, 0, 16008);
    L44686: $stack[@stack] = 256*$PlotzMemory::Memory[$t1=(pop(@stack) + 2*0) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1];
    L44690: return 0 unless $t1 = pop(@stack), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (1);
    L44694: return 0 unless &global_var(88) == 0;
    L44697: &clear_attr(112, 14);
    L44700: return 0 if &global_var(0) == &get_object(&thing_location(112, 'parent'));
    L44704: &insert_obj(112, &global_var(0));
    L44707: $stack[@stack] = z_call(15158, \@locv, \@stack, 44716, 0, 16885, 65535);
    L44716: $PlotzMemory::Memory[$t1 = (pop(@stack) + 2*0) & 0xffff] =
        ($t2 = 1)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff;
    L44721: # print "[abbrev 2]hear a scream [abbrev 9]anguish as [abbrev 0]robber rushes [abbrev 12]defend [abbrev 63]hideaway."
        &write_text(&decode_text(44722));
	&newline();
	return(1);
}

sub rtn44766 {
    my ($t1, $t2, @stack, @locv);
    if (my @frame = @{shift @_}) {
        @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
    } else {
        @locv = ();
        @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
    }
    L44767: return 0 unless $t1 = &global_var(75), grep {unpack('s', pack('s', $t1)) == unpack('s', pack('s', $_))} (30, 37);
    L44773: # print "Huh?"
        &write_text(&decode_text(44774));
	&newline();
	return(1);
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
000000   03 00 00 22 37 09 37 d9 28 5a 03 c6 02 b4 21 87
000010   00 00 38 37 31 31 32 34 01 f4 65 fc d8 70 00 50
000020   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000030   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000040   65 aa 80 a5 13 2d a8 05 13 d4 e8 05 96 60 7a 9a
000050   dc 05 bb 00 1a 69 80 a5 13 2d 2a ea 80 a5 7a 9a
000060   80 a5 d1 60 96 40 71 d9 b4 05 e6 80 1a ea 80 a5
000070   44 d7 b1 40 13 2d bb 00 23 c8 46 95 e0 05 65 a6
000080   e4 05 2e f4 c8 05 34 db a8 05 65 b7 53 4c b4 05
000090   35 57 a8 a5 ba 60 11 d9 17 18 80 a5 71 ae a1 a0
0000a0   62 46 c6 20 5e 94 c8 05 22 34 e1 49 90 c0 20 d3
0000b0   17 19 80 a5 13 d4 68 b8 dd 40 3a 79 d0 05 12 f4
0000c0   d2 45 13 d4 ea e0 32 e6 65 d3 b0 05 1a 37 28 c9
0000d0   f8 05 11 77 39 8e a4 05 3b 13 17 19 80 a5 11 d9
0000e0   80 a5 65 ae a9 60 9d 40 65 a6 e4 a5 2e 97 80 a5
0000f0   70 d9 aa e0 45 46 a7 00 72 93 17 19 80 a5 4c d7
000100   5e 9c 80 a5 20 d3 4e 99 80 a5 1f 59 80 a5 4e 99
000110   80 a5 65 ae e0 05 62 9a e5 a0 61 4a cb 00 32 f4
000120   ea 69 18 f4 eb 20 54 d8 60 cc a8 05 1a b5 28 d7
000130   e0 05 26 93 17 19 80 a5 62 9a 65 bc ab 19 d2 60
000140   71 58 e4 05 4e 97 e5 a0 13 2d 2a ea 17 18 80 a5
000150   35 d8 80 a5 2d 4a e4 05 28 d8 e4 05 26 94 dc 05
000160   23 c8 46 95 e0 a5 20 d3 80 a5 71 ae e5 40 13 2d
000170   9b 20 56 f4 1c c7 c7 c0 12 46 fd 45 9a 60 66 94
000180   80 a5 34 d8 80 a5 72 94 25 53 80 a5 11 d3 80 a5
000190   62 9a e5 a5 4e 97 e5 a5 11 b4 f0 05 72 9a c5 20
0001a0   13 8e e5 a0 61 53 65 53 a1 45 5c ce 4c f4 f0 05
0001b0   47 57 41 d3 b0 05 46 94 41 d3 b0 05 45 46 25 d3
0001c0   b0 05 24 d7 42 6a e3 05 20 d3 26 2a e0 05 19 86
0001d0   3a 78 e4 05 66 ea 1b 1a 5d 58 80 a5 63 26 3a e8
0001e0   1b 0a 80 a5 4e 97 65 aa 1b 19 80 a5 52 6a 80 a5
0001f0   4e 9c 80 a5 00 20 00 22 00 24 00 26 00 27 00 29
000200   00 2a 00 2c 00 2f 00 31 00 32 00 33 00 35 00 36
000210   00 38 00 3a 00 3c 00 3f 00 41 00 43 00 45 00 48
000220   00 4a 00 4b 00 4e 00 50 00 52 00 54 00 56 00 57
000230   00 5a 00 5d 00 5f 00 61 00 63 00 66 00 69 00 6c
000240   00 6f 00 71 00 73 00 74 00 76 00 78 00 7a 00 7c
000250   00 7f 00 82 00 85 00 87 00 89 00 8b 00 8d 00 8f
000260   00 91 00 93 00 96 00 99 00 9c 00 9f 00 a0 00 a2
000270   00 a4 00 a8 00 aa 00 ac 00 ae 00 b0 00 b3 00 b5
000280   00 b7 00 b9 00 bc 00 be 00 bf 00 c1 00 c3 00 c6
000290   00 c8 00 ca 00 cc 00 ce 00 d0 00 d2 00 d5 00 d8
0002a0   00 db 00 de 00 e1 00 e4 00 e7 00 ea 00 ee 00 f2
0002b0   00 f6 00 f8 00 00 00 00 00 00 00 00 1f a5 65 43
0002c0   00 00 58 5f 59 ee 00 00 00 00 00 00 00 00 00 00
0002d0   21 69 00 00 00 00 00 00 00 00 00 00 1e bd 00 00
0002e0   19 75 00 01 00 00 00 00 1e a1 00 00 00 00 00 00
0002f0   1f 41 1b d3 00 01 37 63 5d e5 00 00 64 a6 00 00
000300   00 00 62 c8 37 31 1e d1 00 00 1c c1 00 0f 37 15
000310   00 00 00 00 00 00 ff ff 00 00 37 37 37 45 00 b4
000320   1a dd 1a e5 5a 3a 5d f2 60 99 00 00 60 90 00 00
000330   00 00 00 b4 64 ac 00 06 62 15 20 6d 5c d8 00 00
000340   00 00 00 00 37 4d 00 00 21 35 00 00 00 00 00 00
000350   1e dd 60 d4 5d 09 00 00 00 00 5f 51 00 01 62 40
000360   61 d3 1d af 00 00 20 09 00 00 00 00 5a 3c 00 0a
000370   00 00 21 5b 1e d9 37 23 00 00 5d 26 1e a9 00 00
000380   00 00 00 00 00 00 62 c3 21 77 21 4f 00 00 00 00
000390   1e 28 37 09 00 00 00 00 00 00 00 00 00 00 00 00
0003a0   00 00 58 61 00 00 59 f8 00 00 21 45 00 00 5f 47
0003b0   00 00 00 00 00 00 00 00 00 00 65 25 00 00 28 10
0003c0   26 68 27 3c 21 87 00 00 00 00 00 00 00 00 00 00
0003d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05
0003e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0003f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
000400   00 00 00 00 02 00 00 00 24 93 00 0a 4f 05 00 10
000410   00 1b 77 5f 0a 5d 00 00 04 00 24 b3 00 0a 72 02
000420   00 00 08 2d 5a 00 0a 7e 05 00 10 00 1b 2e 00 0a
000430   91 02 00 00 00 a1 98 00 0a a5 01 00 00 00 1b a5
000440   29 0a b6 08 00 50 41 37 00 00 0a cd 08 00 40 00
000450   ac 32 00 0a e9 00 00 48 00 44 00 00 0b 06 01 00
000460   00 00 1b 57 70 0b 19 00 00 c0 00 a1 00 00 0b 2e
000470   00 00 00 02 2d 6d 00 0b 4b 21 00 00 00 1b 49 00
000480   0b 67 05 00 10 00 1b 72 00 0b 76 00 02 c0 00 88
000490   00 00 0b 90 00 00 50 41 8c 4b 00 0b ac 05 00 10
0004a0   00 1b 56 74 0b c8 05 00 00 00 1b 20 5b 0b ed 01
0004b0   00 00 00 1b 65 00 0c 03 02 02 02 00 24 a8 00 0c
0004c0   16 01 00 00 00 1b 35 00 0c 26 21 00 00 00 1b 39
0004d0   00 0c 45 05 00 10 00 1b 6b 8c 0c 54 02 00 00 04
0004e0   67 00 00 0c 67 14 00 10 00 1b 63 00 0c 7b 00 00
0004f0   00 00 00 00 aa 0c 95 05 00 10 00 1b 90 00 0c 99
000500   01 00 10 00 1b 21 95 0c c4 06 02 00 02 00 00 00
000510   0c ec 02 00 01 00 24 53 00 0c f9 14 00 10 00 1b
000520   75 7b 0d 0a 01 00 00 00 1b 97 00 0d 22 05 00 10
000530   00 1b 6a 00 0d 3a 05 00 00 00 1b b2 99 0d 5d 00
000540   00 00 00 2d 00 15 0d 78 01 00 00 00 1b 6e 00 0d
000550   7c 21 00 00 00 1b 6f 00 0d 8f 21 00 00 00 1b 0e
000560   00 0d 9e 02 10 00 00 35 45 00 0d ab 02 00 00 00
000570   07 00 00 0d bc 04 00 40 00 7d 71 00 0d cb 02 00
000580   01 00 24 43 00 0d e1 00 00 40 20 8b 00 00 0d ef
000590   01 fe 10 80 00 00 04 0e 05 05 00 10 00 1b 00 52
0005a0   0e 07 02 00 00 00 a2 00 00 0e 2a 02 04 00 00 2d
0005b0   24 00 0e 3e 02 00 00 00 24 1f 00 0e 4d 00 10 00
0005c0   02 ac 00 00 0e 5e 06 00 80 00 4e 3a 00 0e 6d 05
0005d0   00 10 00 1b 0f 00 0e 7e 05 00 10 00 1b 7d ae 0e
0005e0   97 02 00 00 00 24 31 00 0e ba 02 68 20 00 4e 00
0005f0   08 0e c8 01 00 00 00 1b 9a 89 0e d9 21 00 00 00
000600   1b 26 00 0e f4 00 00 40 00 4e 37 00 0f 01 00 10
000610   40 00 00 00 00 0f 14 01 00 00 00 1b 79 47 0f 34
000620   08 00 40 20 9e 00 00 0f 45 00 00 40 00 9d 00 00
000630   0f 68 02 10 00 00 70 00 00 0f 88 10 00 00 00 1b
000640   22 a6 0f 97 00 00 40 08 9d a9 00 0f b6 08 00 40
000650   00 9d 3e 00 0f c8 02 00 01 00 24 4c 00 0f ee 00
000660   40 60 20 74 00 9b 0f fa 02 80 82 00 35 66 00 10
000670   17 01 00 00 00 1b 18 00 10 2f 02 01 00 00 3c 8e
000680   00 10 46 02 00 01 00 a5 00 00 10 52 21 00 00 00
000690   1b 3c 00 10 68 08 00 40 00 5f 00 00 10 77 00 01
0006a0   e0 20 8c 00 00 10 91 02 00 01 00 24 01 00 10 b3
0006b0   00 00 40 08 83 00 00 10 c0 05 00 10 00 1b 07 33
0006c0   10 d8 05 00 10 00 1b a2 a0 10 f3 00 00 40 08 a2
0006d0   94 00 11 05 08 00 40 00 7b 00 00 11 16 02 00 02
0006e0   00 2e a7 00 11 28 02 10 00 00 24 76 00 11 37 02
0006f0   00 00 00 2d ad 00 11 45 01 00 00 00 1b 0b 00 11
000700   51 01 00 10 00 1b 34 69 11 74 01 00 00 00 1b 9e
000710   67 11 94 08 02 40 00 6a 5c 00 11 b3 00 00 c0 20
000720   a7 00 00 11 d7 02 00 00 00 2d 0d 00 11 ea 00 00
000730   40 08 13 00 00 12 03 02 00 00 00 6a 00 00 12 0f
000740   01 00 00 00 1b 23 00 12 1b 21 00 00 00 1b 9d 00
000750   12 2e 00 60 60 20 02 00 4a 12 3d 05 00 10 00 1b
000760   05 00 12 55 00 80 60 00 74 44 7c 12 76 08 00 40
000770   00 63 00 00 12 8e 01 00 10 00 1b 1d 62 12 a9 02
000780   10 00 00 24 9f 00 12 b8 01 00 00 00 1b 25 00 12
000790   d2 00 00 40 01 35 a4 00 12 e9 00 20 00 02 57 00
0007a0   19 13 0a 02 00 00 00 a2 2f 00 13 1c 08 02 40 00
0007b0   56 00 00 13 2e 01 00 00 00 1b 13 58 13 4a 01 00
0007c0   00 00 1b 4e 78 13 5b 00 10 40 20 77 00 00 13 6e
0007d0   02 00 00 00 2d 73 00 13 8a 01 00 00 00 1b 83 00
0007e0   13 9d 21 00 00 00 1b 5e 00 13 b9 00 62 20 02 0b
0007f0   00 b1 13 c8 00 10 40 04 7d 00 00 13 e2 05 00 10
000800   00 1b 02 00 13 f6 00 00 00 00 2d 81 00 14 11 02
000810   68 20 00 12 00 61 14 1f 14 00 00 00 1b 1a 00 14
000820   2b 02 00 01 00 24 03 00 14 41 05 00 10 00 1b 96
000830   6c 14 59 0c 40 60 00 6b 00 8d 14 76 05 00 00 00
000840   1b 8b 00 14 95 00 00 c0 20 8f 00 00 14 b6 00 40
000850   60 00 20 00 51 14 c9 00 10 44 00 61 00 00 14 e2
000860   05 00 00 00 1b 12 2a 14 fb 01 00 00 00 1b 14 00
000870   15 08 00 70 20 00 b2 00 00 15 1d 02 10 00 00 9d
000880   41 00 15 2f 00 00 00 00 2d 54 00 15 44 00 00 00
000890   00 00 00 00 15 54 01 00 00 00 1b 40 4d 15 5d 01
0008a0   00 00 00 1b 9c 00 15 7f 08 00 40 00 00 00 00 15
0008b0   92 21 00 00 00 1b 27 00 15 aa 00 00 00 08 2d 30
0008c0   00 15 bb 02 d0 20 00 35 00 10 15 c4 02 10 00 02
0008d0   38 00 00 15 d9 02 10 00 00 a1 92 00 15 e8 05 00
0008e0   00 00 1b 84 2c 15 fc 02 68 20 00 18 00 11 16 18
0008f0   08 00 40 00 78 00 00 16 24 02 50 20 00 3c 00 00
000900   16 3f 00 60 40 30 00 00 7a 16 54 05 00 10 00 1b
000910   60 00 16 6f 05 00 10 00 1b 1c 00 16 8e 02 11 00
000920   00 a1 06 00 16 a7 02 00 00 00 24 36 00 16 b6 02
000930   00 00 00 a2 68 00 16 ca 02 00 00 02 1d 00 00 16
000940   dc 05 00 10 00 1b 91 00 16 f5 01 00 10 00 1b 46
000950   00 17 0c 00 00 c0 20 a1 0c 00 17 1f 08 00 40 00
000960   23 00 00 17 39 01 00 00 00 1b 17 00 17 60 00 00
000970   48 00 44 0a 00 17 77 01 00 00 00 1b 5d 00 17 8e
000980   21 00 00 00 1b 86 80 17 a3 01 00 00 00 1b 16 3d
000990   17 b0 02 10 00 00 24 b0 00 17 c8 00 00 40 20 4f
0009a0   00 00 17 d8 01 00 10 00 1b 55 8a 17 f9 01 00 00
0009b0   00 1b a1 ab 18 0b 02 00 00 00 24 64 00 18 1e 00
0009c0   00 40 04 35 88 00 18 2c 05 00 00 00 1b 4f 48 18
0009d0   40 08 02 40 00 40 00 00 18 58 00 50 20 00 2e 00
0009e0   59 18 7e 00 00 01 00 24 a3 00 18 94 00 10 40 0c
0009f0   9d 42 00 18 a8 01 00 00 00 1b 38 af 18 c2 00 00
000a00   40 08 a2 50 00 18 db 05 00 00 00 1b 7e 09 18 e7
000a10   00 00 00 00 2d 87 00 18 f6 02 02 02 00 35 28 00
000a20   19 01 08 50 60 00 aa 00 00 19 16 02 00 02 00 24
000a30   2b 00 19 37 02 00 00 00 70 3f 00 19 45 01 00 00
000a40   00 1b ac 7f 19 55 00 00 00 00 24 00 00 19 6c 02
000a50   2e 97 ab 19 32 43 a7 71 2d 23 35 8f 00 04 13 55
000a60   00 c0 13 37 a9 45 37 64 ae 16 77 32 44 09 2c 4c
000a70   01 00 02 70 d9 aa e5 32 45 b3 31 36 7d 00 04 54
000a80   ce 5c 01 25 a6 cd 38 b1 31 4b 2d ee 2d e0 10 f6
000a90   00 06 11 d3 61 c9 28 01 00 87 1a f7 d3 85 32 43
000aa0   19 2e 57 79 00 05 22 93 66 f4 44 15 1a 6a c4 a5
000ab0   31 31 52 10 d0 00 03 11 34 49 40 88 05 1a 0b 76
000ac0   4e 6a 65 b5 32 4b c1 68 2b ef 4c 2a 00 02 66 97
000ad0   a1 a5 32 4c 98 b1 35 49 2e e3 35 81 30 c6 c5 2d
000ae0   00 14 2a 60 b4 29 00 0c 00 05 3c c9 28 0b 39 9a
000af0   5d d3 a8 a5 71 2c cf 35 81 30 b8 b7 2e 60 58 2d
000b00   00 0a 29 00 0d 00 02 47 53 a1 a5 b1 2d 00 32 fd
000b10   2f e6 30 e7 e6 2e 5a 28 00 03 12 f4 6a 69 80 40
000b20   1f 55 1e a5 1d 57 1c 46 19 07 2e 5a de 00 03 48
000b30   d9 21 a7 d2 90 32 49 f1 b1 30 33 30 41 30 3a 10
000b40   d3 2e 60 0a 2d 00 02 27 5e 06 00 06 1e e6 6d 40
000b50   19 3b 2a 79 6a ea dc a5 32 3b e8 f1 30 48 30 79
000b60   33 6d 28 b5 10 fb 00 01 8d 05 1f 49 1d 0e 19 27
000b70   16 9d 2e 5c 17 00 04 11 06 4f c2 6c 9b b9 5c 1e
000b80   34 1d 72 16 34 32 44 af 2e 63 12 4c 43 a3 2b 00
000b90   05 54 d7 21 b2 2a 79 02 46 d4 a5 31 30 25 50 e1
000ba0   e0 df 2d 00 02 2a 65 a6 27 5d bd 00 05 54 ce 5c
000bb0   01 25 06 4d 31 ab 05 32 4d 84 71 2a 98 31 4b 10
000bc0   c3 2d 00 0a 2a 59 a9 00 03 12 0e 65 0d aa 65 9e
000bd0   1c b0 00 00 00 1d 35 17 7d 36 5d f8 94 1c b0 00
000be0   00 00 32 45 33 4c b0 1f 76 29 00 0a 00 05 13 06
000bf0   4d 3e 00 87 28 c8 b4 a5 1c 22 1b 6a 2e 64 2c 2c
000c00   03 a3 00 03 13 11 39 2a 80 40 1d 7e 1c 65 16 16
000c10   2e 5b a6 0c a8 00 03 32 e6 65 d3 b0 a5 32 54 c3
000c20   71 2d af 2d b6 00 03 11 0a 46 26 dc a5 1f 57 1e
000c30   9e 3d 5c dc 97 35 ae 00 00 00 32 48 49 4c ae a8
000c40   76 29 00 19 00 01 8d 05 1c 39 1b 26 1a 6f 18 86
000c50   2e 5c 17 00 02 10 d1 e4 d7 1f 4e 76 21 57 58 03
000c60   32 4d 32 2e 61 1d 00 04 1e 34 51 3e 00 dd a8 a5
000c70   71 29 41 29 3a 10 d4 2d 00 19 00 03 08 84 5d db
000c80   aa e5 3e 65 18 1d 4f 37 64 bc 16 75 13 4f 2e 64
000c90   09 2c 03 a3 00 00 15 1b 00 05 10 ea 35 d3 24 04
000ca0   36 9a e1 45 1f 60 1e 96 9d 12 b0 00 00 00 1c 90
000cb0   1b 91 1a 60 18 90 95 12 b0 00 00 00 32 43 20 4c
000cc0   31 b0 01 00 06 11 53 66 e6 4d 0a 00 2c 11 a6 a5
000cd0   58 7c 63 91 5f 18 17 21 75 63 91 5f 18 32 4e 67
000ce0   0c 64 e8 2d 62 4f c6 2d 69 4f c6 00 01 fa 9a 32
000cf0   00 00 31 28 b5 2f 00 06 00 03 21 ae 4a 6a f8 a5
000d00   32 3c e4 31 2a f3 30 fe f9 00 03 08 84 5d db aa
000d10   e5 1e 13 1d a5 37 64 bc 33 64 27 2e 5f 25 2c 03
000d20   a3 00 04 13 8e 4d 3e 00 88 9b 6a 1f 46 1d 97 16
000d30   1d 32 4e 2c 2e 5b 80 0c 76 00 05 10 d7 19 86 06
000d40   c4 2c d1 c7 05 1f 13 7d 56 75 61 3e 77 56 75 61
000d50   3e 36 5e 12 32 50 95 6c 76 03 a3 2b 00 03 11 86
000d60   60 02 80 a5 1e 5d 1c b2 32 52 e4 2e 5b ca e8 2d
000d70   5b 52 ff 30 d4 52 ff 00 01 bb 25 00 04 12 4e 5e
000d80   f4 5c 02 80 a5 1e 6e 1b 65 32 3c 3b 0c 53 00 01
000d90   8d 05 1f 26 1e 39 19 17 17 86 2e 5c 17 00 01 8d
000da0   05 1f 49 1d 0e 17 9d 2e 5c 17 00 02 20 d7 d5 59
000db0   32 47 b7 71 32 cc 2a a6 30 f4 d8 00 03 0d 97 19
000dc0   d1 ba 6c 71 32 39 32 32 10 dc 00 02 5e 95 a8 a5
000dd0   32 46 41 71 32 be 2b 39 10 f4 2d 00 0a 2a 5d 82
000de0   00 03 5c ce 4c f4 f0 a5 32 44 d8 31 32 40 00 05
000df0   07 35 3a 2a 00 29 22 86 c4 a5 71 2b 2b 31 ad 10
000e00   f1 2d 00 14 00 00 00 05 13 8a 63 20 05 24 36 9a
000e10   e1 45 1f 60 3e 5c 54 1c 90 1b 60 19 90 78 05 72
000e20   00 00 32 42 90 4c 31 36 01 00 05 79 51 46 9c 00
000e30   fa 67 34 cc a5 32 4a d0 31 2a 91 10 cc 00 02 65
000e40   ae cd 85 f1 2e dc 35 03 2e 0a 2e 1f 00 03 0c ad
000e50   53 58 a8 a5 32 43 54 31 2e 42 30 ed ec 00 01 9c
000e60   d9 32 52 40 31 29 64 10 b9 26 52 19 00 02 56 e6
000e70   f9 57 71 31 de 2e 9d 30 df e1 27 5e 44 00 05 11
000e80   06 4f c2 6c 87 53 39 d2 45 1d 0f 1b 56 17 0f 2e
000e90   60 ee 4c 03 43 a3 00 04 12 2e 6d d3 30 02 80 a5
000ea0   1e 12 7d 38 5c 5c 63 56 46 a4 00 32 46 b3 0c 76
000eb0   e8 30 8e 43 9a 30 87 43 9a 00 02 1e 86 dd 25 32
000ec0   43 87 71 29 db 29 cd 00 03 55 49 2b 19 9a 25 31
000ed0   31 7c 30 ed c7 2b 00 1e 00 04 11 1e 22 34 57 00
000ee0   88 05 7e 35 5c 00 00 1a 39 77 aa 16 5c 2a 32 55
000ef0   30 0c 76 00 01 8d 05 1f 26 1c 17 19 38 2e 5c 17
000f00   00 04 1e e6 63 00 1d 51 c4 a5 32 4c c8 31 29 87
000f10   30 f1 dd 00 08 07 35 39 48 28 01 27 6e 66 ea 53
000f20   58 03 11 99 85 32 53 f5 71 31 9f 33 c8 30 f1 b5
000f30   2d 00 0a 00 04 12 46 21 ae 4d 40 88 05 1f 79 14
000f40   79 32 53 3c 00 03 54 ce 4f 2e cd 85 32 48 bd f1
000f50   31 44 29 09 2a 9f 35 81 30 ec d5 2e 60 7f 2d 00
000f60   0f 2a 59 87 29 00 07 00 07 1f 57 4d 49 17 94 6b
000f70   20 44 d3 65 57 cc a5 71 2f 68 2f 5a 70 b2 b1 b0
000f80   af 2d 00 14 2a 5c 8b 00 02 05 c7 99 85 32 3f 78
000f90   31 29 48 30 f4 f3 00 04 12 ea 61 57 6e 8e dc a5
000fa0   1f 83 3e 5c 84 1c 55 36 5c 84 32 51 5f 2c 03 9f
000fb0   68 34 77 51 92 00 04 62 0a 45 59 0b 70 ab c5 31
000fc0   2f 0d 10 ad 2d 00 0a 00 07 45 46 65 aa 5c 07 19
000fd0   80 05 28 51 d3 e0 a5 32 54 05 b1 29 48 2b 40 35
000fe0   81 30 e1 ae 2e 58 50 2d 00 0f 29 00 0b 00 02 22
000ff0   2e ad 65 32 44 ba 31 2b 08 00 04 1e f4 72 60 60
001000   c8 c0 a5 32 45 68 71 29 48 32 e8 10 e8 2d 00 09
001010   2b 00 09 2a 59 72 00 02 0d 89 d2 97 32 47 a7 b1
001020   2b fd 2f a7 36 d1 70 dc db da d9 27 5c 9b 00 06
001030   13 3c 3b 19 3a 6c 00 95 1b 18 99 8a 1f 0b 1c 21
001040   18 97 2e 5b 6e 00 02 63 8e e5 0d 32 53 b0 31 34
001050   c4 00 05 13 8d 3b 2a 00 88 45 cb af 05 32 4b b5
001060   71 2b 08 2b 0f 10 ed 00 01 8d 05 1e 57 1d 27 1b
001070   49 1a 0e 2e 5c 17 00 04 3d 5c 2a 2a 24 0a b1 85
001080   32 44 48 71 2c 51 35 81 10 ea 2a 65 84 29 00 06
001090   00 04 1e 26 22 00 1e 94 c0 a5 32 4d 3c f1 2a 05
0010a0   31 de 31 36 2a 0c 30 f4 c4 2d 00 0a 2a 59 98 27
0010b0   62 4e 00 02 66 ea a8 a5 71 35 88 2a 28 10 f4 00
0010c0   07 34 d3 24 bc 35 51 24 06 3a e0 57 52 d4 a5 71
0010d0   31 fa 28 ca 30 bd bc 00 03 13 2a 4a b1 a8 a5 1e
0010e0   6b 1c 18 37 64 b6 16 6b 32 4c 2b 0c 76 68 2b ef
0010f0   4c 2a 00 04 11 26 48 04 1c d8 a8 a5 17 a1 2e 63
001100   bd 2c 03 a3 00 04 61 17 2b 89 5d db aa e5 71 33
001110   3c 2c 20 10 ca 00 03 05 ca 49 57 9a 29 71 2c 5f
001120   35 81 10 f4 29 00 12 00 02 26 94 dc a5 32 47 a7
001130   31 2b fd 30 ef ee 00 02 49 d7 de 97 32 3c 68 71
001140   32 6a 30 56 00 02 60 ce c6 97 32 3b 4a 31 32 ef
001150   00 06 12 ea 61 57 6e 8e 5c 04 62 9a e5 a5 7f 40
001160   1b 5d 40 1e a1 1c 0b 18 57 32 49 32 0c 03 68 2f
001170   53 51 9f 00 05 11 53 24 01 24 97 19 d3 9e 9c 7e
001180   22 75 61 3e 18 34 77 22 75 61 3e 2e 63 96 6c 76
001190   03 2b a3 00 03 13 37 52 31 80 40 7e 0b 20 5f fc
0011a0   7d 49 20 5f fc 1c 16 7b 55 20 5f fc 32 48 c7 2e
0011b0   5a b0 00 08 1d 46 6b 2e 2f 51 01 ea 71 51 29 20
0011c0   61 06 dc c7 f1 33 19 2a 67 29 79 35 81 30 ec ea
0011d0   2d 00 08 29 00 0f 00 03 45 46 2e 2a e4 a5 32 42
0011e0   ce 71 2f 84 30 02 2d 00 02 00 03 54 d8 60 cc a8
0011f0   a5 32 3c 2d f1 35 65 31 6e 31 60 35 b2 70 fa f9
001200   f8 f7 00 02 61 b4 ed 51 31 33 90 2d 00 0f 00 02
001210   60 d3 a4 a5 32 50 70 31 32 f6 00 04 11 14 1a 20
001220   12 4e cd 45 1f 9c 1d 23 1c 5d 2e 5b e0 00 01 8d
001230   05 1c 5e 1b 9a 19 86 16 0e 2e 5c 17 00 04 1d d7
001240   24 b8 60 13 ab 19 32 44 42 31 30 aa 10 eb 2b 00
001250   14 2a 5d 32 00 05 12 74 5f 2d 00 29 11 b4 eb 0a
001260   1f 77 1e 1c 1d 2e 3c 60 e5 19 1c 18 2e 2e 62 d6
001270   6c 93 36 31 01 00 04 32 26 63 00 1e 99 e6 2a 32
001280   45 8e 31 2a 13 10 e5 2b 00 04 2a 60 aa 00 05 22
001290   fe 63 26 44 18 43 51 c4 a5 b1 33 c1 2d fc 35 81
0012a0   10 bf 2a 65 63 29 00 16 00 02 11 a6 a5 58 1f 1d
0012b0   14 1d 2e 58 13 0c 64 00 05 55 d1 28 01 24 f4 25
0012c0   ca e0 a5 32 50 42 f1 29 e9 29 f0 32 78 31 ad 10
0012d0   c0 00 06 13 8e 4d 2e 4d 80 12 a6 63 06 b1 45 1f
0012e0   14 1c 6e 18 25 2e 5b 6e 00 05 1e e6 63 00 44 d3
0012f0   65 57 cc a5 32 47 5c b1 2f 5a 2f 68 2f bc 10 dd
001300   2e 5f ed 2d 00 0f 2a 5e 32 00 02 66 f4 c6 25 32
001310   48 d6 31 35 96 2f 00 02 2e 5d a6 00 04 1e f4 72
001320   60 1f 59 e6 93 32 4a d0 31 2a 91 10 e8 00 04 56
001330   99 00 29 32 91 a4 a5 b1 31 c9 2d 9a 35 81 10 e9
001340   2d 00 0f 2a 59 55 29 00 13 00 04 13 06 4d 3e 00
001350   88 9b 6a 18 13 14 13 2e 5b 97 00 04 11 4c 7a b9
001360   38 69 88 05 1d 4e 17 4e 2e 5b 44 0c 76 00 05 55
001370   d1 28 01 26 2a 1b 6a e0 a5 32 44 56 b1 2f a0 2f
001380   7d 31 ad 2e 59 4b 2d 00 19 00 04 1e 26 63 20 05
001390   26 ba e5 f1 2f ed 28 c3 30 5d 2a 4b 00 05 11 37
0013a0   19 79 78 04 20 db a8 a5 1f 65 1d 25 1c 83 16 83
0013b0   32 4e 2c 2e 5b 80 0c 76 00 01 8d 05 1d 86 18 6f
0013c0   17 17 16 9d 2e 5c 17 00 02 65 ae a9 65 32 3e 13
0013d0   f1 35 11 32 b0 30 17 31 8a 10 f5 2f 00 05 2e 5f
0013e0   55 00 04 4c d8 67 c0 42 6e ad 45 b1 2f 30 2f 29
0013f0   29 b1 30 e4 e3 00 05 11 74 5d 58 64 04 29 2c a8
001400   a5 1e 0f 1d 96 1a 91 37 5f e1 2e 58 68 2c 4c 01
001410   00 02 0e ac df 4a 32 3b 9c 31 2d cb 10 fc 00 02
001420   64 c7 c5 45 31 34 d2 2b 00 32 00 03 08 84 5d db
001430   aa e5 37 64 bc 16 20 33 60 35 2e 5e a7 2c 03 a3
001440   00 03 63 26 3a fc 9b c5 32 3b 42 f1 34 2a 34 5b
001450   34 31 34 38 50 ff fe fd 00 05 11 74 5d 58 64 04
001460   54 d9 b4 a5 1e 91 1c 60 17 02 56 43 fb 00 32 43
001470   b0 4c 15 4c 01 00 04 32 91 24 08 51 6b ba 65 b1
001480   2b 32 2a bb 35 81 10 e9 2e 5f 05 2d 00 37 2b 00
001490   23 29 00 0d 00 04 11 37 19 79 78 02 80 a5 7e 8b
0014a0   7d 64 ed 1c 3c 74 8b 7d 64 ed 32 53 1f 2e 5b ed
0014b0   68 2a d0 52 cb 00 03 64 69 44 c7 aa 25 31 2f 45
0014c0   10 c8 2d 00 02 27 61 46 00 03 5d 49 00 fa d3 c5
0014d0   32 50 4f 31 2a 6e 10 cb 2d 00 0a 2b 00 14 2a 60
0014e0   3c 00 06 5b 46 4f 2e 67 c0 05 3c 1b 2a dc a5 32
0014f0   45 b3 71 36 7d 32 1d 2d 00 04 00 02 10 d9 e5 c8
001500   16 12 2e 5a 4e 0c 76 00 05 12 4e 4d 40 11 53 66
001510   e6 cd 0a 1f ac 1e 14 15 ac 2e 64 62 00 02 1c d8
001520   c1 59 32 52 83 31 29 5d 2e 5e 18 2b 00 32 00 03
001530   62 0a 45 59 d2 65 32 54 3a b1 29 fe 33 ac 29 f0
001540   2e 5e ca 00 01 8a a5 32 3b 7d f1 2d c4 32 f6 2b
001550   da 2c f2 00 02 65 ae cd 85 32 3a ea 00 06 12 ea
001560   61 57 6e 8e 5c 04 4e 97 e5 a5 1f 6e 7c 40 1b 5d
001570   40 17 6e 32 51 b5 2c 03 76 68 2f 53 51 9f 00 04
001580   11 14 1a 20 12 4e cd 45 1e 9c 1d 84 16 8b 2e 5b
001590   e0 00 04 37 4c 28 09 38 d2 d2 69 71 2b cc 35 81
0015a0   30 b4 b3 2e 60 64 29 00 19 00 01 8d 05 1e 26 1c
0015b0   17 19 6f 17 5e 16 9d 2e 5c 17 00 02 4f 52 9d 57
0015c0   31 2e b2 00 04 66 f4 55 be 01 06 e1 45 32 47 53
0015d0   31 2a b4 10 e2 2b 27 10 00 01 8c 65 32 55 4b 71
0015e0   2b 7f 2c a5 30 ac ab 00 04 32 ea 2a 60 1f 47 9e
0015f0   2a 32 4a bd 31 2a 60 50 f1 ce cd 00 04 12 26 25
001600   2a 5c 02 80 a5 7d 79 7d 64 ed 17 84 32 53 1f 2e
001610   59 b8 68 2f 4c 53 19 00 02 1a 39 9a e5 31 28 d8
001620   2b 00 32 00 03 61 0a 57 37 a8 a5 32 4c d4 71 33
001630   20 35 81 10 df 2d 00 03 2a 61 dc 29 00 09 00 03
001640   48 c8 35 d3 a8 a5 32 53 9f b1 2f fb 2c 2e 2f ae
001650   2b 00 32 00 04 48 cc 39 00 1e 86 e4 a5 32 4b 36
001660   71 29 e2 32 2b 30 c9 cd 2d 00 14 2b 00 64 00 05
001670   13 14 6b 2d 00 29 11 b4 eb 0a 3f 60 e5 1e 1c 1d
001680   2e 1b 1c 1a 2e 2e 62 f9 6c 93 36 31 01 00 03 11
001690   74 5d 58 e4 a5 1d 77 1c 96 19 72 18 1c 37 5f e1
0016a0   2e 5a 3e 2c 4c 01 00 02 1e 91 e4 a5 32 4a 88 31
0016b0   29 f7 30 cf f4 00 05 1e 86 5d 2a 24 1c 3a 69 d3
0016c0   85 32 43 8f 31 36 b5 10 ee 00 04 5d 49 00 fa 67
0016d0   34 cc a5 32 4a d0 31 2a 91 10 cb 00 05 4f 52 1d
0016e0   57 00 29 31 b4 e3 38 32 4f e6 b1 2d 77 34 1c 2d
0016f0   15 30 c2 c1 00 03 11 74 5d 58 e4 a5 1f 91 1e 72
001700   1d 1c 37 5f e1 2e 5a 3e 2c 4c 01 00 04 12 4e 5e
001710   f4 5c 02 80 a5 1e 21 1b 46 32 3c 3b 0c 53 00 05
001720   66 9a 5c 0c 69 c9 28 f4 d2 05 71 2a 05 2d d9 30
001730   d2 d1 2a 61 b9 27 58 83 00 0a 60 d5 55 ae 5d 45
001740   71 53 22 fa 63 2a 24 07 5c c8 2a 2a e4 a5 f1 2a
001750   21 2e f1 33 04 35 81 10 b6 2d 00 0a 29 00 0a 00
001760   04 11 97 1b 2e 4d 80 88 05 18 5e 97 77 15 5c fd
001770   00 32 54 85 0c 15 00 05 22 34 6d 40 05 2c 1a f1
001780   b9 05 32 45 72 71 2d 54 2b 24 2d 00 04 00 04 11
001790   14 1a 20 12 4e cd 45 1c 84 1b 9c 1a 5d 17 9c 2e
0017a0   5b e0 00 01 8d 05 1f 27 1a 0e 18 86 2e 5c 17 00
0017b0   03 13 19 69 2e d0 a5 1d 16 57 48 90 00 2e 5a 5d
0017c0   0c 1f 68 31 3d 48 aa 00 01 a4 d2 32 4a c1 f1 2b
0017d0   8d 2d 62 2d 69 2c b3 00 05 55 d1 28 01 26 b1 1b
0017e0   19 b9 05 32 4a f6 f1 29 e2 31 ad 31 bb 36 22 30
0017f0   cd c9 2e 60 22 2d 00 14 00 02 11 26 c8 a5 1d 55
001800   1b a2 16 4f 32 49 57 2c 03 9f 00 05 12 46 3a 79
001810   2a 66 4d 0a 80 40 18 a1 14 a1 2e 5a ff 00 02 5d
001820   db aa e5 32 50 be 31 32 a9 10 be 00 02 63 94 dd
001830   25 71 34 cb 29 b1 30 de e1 2d 00 1e 2a 65 03 00
001840   07 13 8d 3b 2a 00 88 45 cb 2f 00 10 ea 99 0d 1d
001850   0b 2e 63 ec 2c 03 a3 00 05 66 fa 4e 00 05 2f 2b
001860   8a c7 05 32 51 b0 f1 35 a4 2a ec 2e ff 35 81 10
001870   e1 2e 60 48 2d 00 23 2a 64 8b 29 00 0f 00 03 07
001880   32 19 d1 9e 9d 32 42 c5 71 30 09 2a 1a 30 f1 f0
001890   2b 00 0a 00 02 21 ba e5 45 32 51 d5 b1 2b 01 32
0018a0   4e 33 dd 50 bb cf ba 00 04 5f 58 67 c0 42 6e ad
0018b0   45 32 54 0a 71 2f 30 2f 29 10 b2 2d 00 14 2a 5d
0018c0   46 00 05 13 2d 39 4b 17 18 00 91 99 d7 16 38 32
0018d0   57 40 2e 5e 24 0c 76 29 00 14 00 02 72 ea cd 0d
0018e0   31 36 ca 2d 00 0a 00 03 10 e6 64 02 80 a5 1e b2
0018f0   1c 7e 32 51 fe 00 02 70 d1 c4 a5 71 36 6f 36 76
001900   00 03 66 e6 54 09 d2 97 32 48 19 b1 2b fd 35 7a
001910   35 73 30 d7 d6 00 03 21 a6 45 c8 a8 a5 32 57 6f
001920   b1 2a d7 2b 6a 35 81 30 aa a9 2e 60 73 2d 00 0a
001930   2b 00 05 29 00 14 00 02 71 d3 a6 9c 32 44 f3 31
001940   36 b5 10 f1 00 03 63 2e 45 59 e6 85 31 34 62 10
001950   f2 2d 00 0a 00 03 13 0d 19 79 80 40 1f 23 1d ac
001960   36 5f 40 2e 65 bf 68 2a d0 52 cb 00 02 57 0a e9
001970   34 32 3b e8 00 00 00 00 00 00 00 00 00 00 00 00
001980   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001990   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0019f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a20   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001a90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001aa0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ab0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ac0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ad0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ae0   00 00 00 00 00 3b 00 00 00 00 00 00 00 00 00 00
001af0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b20   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001b90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ba0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001bb0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001bc0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001bd0   00 00 00 3b 00 00 00 00 00 00 00 00 00 00 00 00
001be0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001bf0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c20   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001c90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ca0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001cb0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001cc0   00 3b 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001cd0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ce0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001cf0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d20   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001d90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001da0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 78
001db0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001dc0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001dd0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001de0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001df0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e20   00 00 00 00 00 00 00 00 78 00 00 00 00 00 00 00
001e30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001e90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ea0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001eb0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ec0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ed0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ee0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ef0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f00   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f10   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f20   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f30   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f40   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f50   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f60   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f70   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f80   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001f90   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001fa0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001fb0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001fc0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001fd0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001fe0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
001ff0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002000   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002010   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002020   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002030   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002040   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002050   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002060   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002070   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002080   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002090   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020a0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020c0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020d0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0020f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002100   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002110   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002120   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002130   00 00 00 00 00 00 00 00 60 00 77 00 1c 00 72 00
002140   91 00 96 00 0f 00 04 00 00 65 3c 5e de 57 75 00
002150   05 00 00 5c 4d 64 a1 62 39 5a 34 5f 77 5a 00 5a
002160   0e 5c be 5f 83 5a 19 5f 92 5f 9d 64 f9 5f ac 5e
002170   e4 5e f2 5f bc 5f ce 00 07 00 00 00 5d 00 9c 00
002180   84 00 8b 00 b2 00 7e 22 51 22 56 22 59 22 61 22
002190   6e 22 85 22 88 22 b3 22 b6 22 bb 22 ce 22 d6 22
0021a0   e6 22 e9 23 00 23 1a 23 1d 23 47 23 4c 23 55 23
0021b0   5c 23 5f 23 62 23 6e 23 81 23 91 23 94 23 a8 23
0021c0   b5 23 c5 23 ca 23 cf 23 d4 23 dc 23 df 23 e8 23
0021d0   f7 23 fa 24 06 24 31 24 34 24 39 24 3e 24 43 24
0021e0   46 24 4e 24 56 24 5d 24 6a 24 75 24 81 24 8d 24
0021f0   95 24 98 24 9d 24 ad 24 b9 24 bc 24 cf 24 d2 24
002200   df 24 e4 25 0f 25 12 25 2c 25 35 25 3c 25 43 25
002210   46 25 49 25 4c 25 51 25 5d 25 60 25 68 25 6d 25
002220   70 25 73 25 82 25 8b 25 94 25 97 25 9f 25 a4 25
002230   b3 25 b8 25 dd 25 e0 25 e5 25 f1 25 f6 25 f9 25
002240   fe 26 0a 26 1a 26 25 26 32 26 37 26 43 26 5c 26
002250   61 01 40 3b 1e 30 01 00 58 01 80 16 00 00 3e 1c
002260   f0 03 7c 45 00 30 79 45 00 30 40 45 00 30 04 7d
002270   15 13 fa 7a 29 00 84 80 2a 00 86 39 00 00 80 13
002280   00 86 3b 00 00 01 00 00 0b 7a 1b 17 30 7c 1a 17
002290   30 71 65 00 00 7f 65 00 00 76 38 00 00 79 1d 00
0022a0   00 7e 1d 00 00 7b 1d 00 00 77 66 00 00 40 66 00
0022b0   00 00 65 01 00 05 01 40 32 00 00 03 7b 25 00 f0
0022c0   ba 24 00 f0 3e 00 c8 80 24 00 f0 3e 00 c8 01 80
0022d0   61 00 30 3e 1c f8 03 80 50 10 f8 00 00 00 78 4f
0022e0   10 f8 40 4f 10 f8 01 00 55 06 74 38 00 00 78 38
0022f0   00 00 7b 38 00 00 75 38 00 00 76 38 00 00 00 38
002300   04 80 29 00 c0 38 00 00 80 4a 00 c0 39 00 00 80
002310   29 00 c0 3b 00 00 40 29 00 c0 01 00 63 08 80 49
002320   11 64 38 00 00 80 49 11 64 34 00 00 80 49 11 64
002330   3d 00 00 7c 2d 18 00 79 1c 1b 30 7d 2d 18 30 7b
002340   18 1b 30 40 49 11 34 01 40 1f 00 00 02 7c 4e 00
002350   00 40 4e 00 00 02 40 33 00 00 00 33 01 00 0c 01
002360   00 11 02 80 19 1f f0 3e 19 ca 40 12 1f fa 03 80
002370   46 00 00 3e 1c 00 80 13 00 86 3b 00 00 40 45 00
002380   30 03 80 25 16 f0 3e 1c f2 7c 25 16 f0 40 25 16
002390   f0 01 00 0f 04 7b 17 00 00 7c 16 00 00 bc 16 00
0023a0   00 3e 1c f0 7d 15 00 00 03 7a 14 1e 30 79 3c 00
0023b0   00 73 3c 00 00 03 7c 49 11 14 80 48 00 00 3e 00
0023c0   00 40 48 00 00 01 40 23 00 00 01 40 18 1b 30 01
0023d0   40 0e 00 00 01 80 13 00 00 3f 00 00 01 00 4b 02
0023e0   72 3e 00 00 7f 3e 00 00 02 bc 60 1e 30 3e 1c f2
0023f0   80 5f 00 00 3f 00 00 01 00 08 02 80 54 1e 20 2e
002400   00 00 40 54 1e 20 06 80 5e 00 c2 36 00 00 80 5e
002410   00 c2 34 00 00 80 2a 00 c2 39 00 00 80 13 00 c2
002420   3b 00 00 80 5d 00 c2 3e 1e 30 80 5d 00 c2 33 1e
002430   30 01 00 69 01 40 43 00 00 01 7f 54 1e 20 01 40
002440   57 00 02 01 00 04 01 80 14 1e 30 3e 1d c2 01 80
002450   14 1e 30 3e 1d c2 02 40 1d 00 00 00 2c 03 72 32
002460   00 00 7b 56 00 00 40 56 00 00 03 75 5b 00 00 7b
002470   5b 00 00 00 5b 02 80 62 00 f0 38 00 00 40 62 00
002480   f0 02 bc 4c 00 00 3e 00 00 7c 4c 00 00 01 80 21
002490   00 00 3e 1d c0 01 00 0b 01 40 52 00 08 03 80 46
0024a0   00 00 3e 1c 00 79 4d 00 34 40 4d 00 34 02 80 53
0024b0   00 00 3e 00 00 40 53 00 00 01 00 02 03 80 26 00
0024c0   30 3e 1c c2 bb 26 00 30 3e 1c c2 7b 26 00 30 01
0024d0   00 09 03 77 30 1e 00 7d 30 1e 00 40 30 00 00 01
0024e0   40 36 00 00 0b 72 32 00 00 7b 2f 00 f4 6f 42 00
0024f0   00 70 41 00 00 7e 2f 00 f4 79 2f 00 00 73 2e 00
002500   f4 7a 40 18 00 7c 40 18 00 71 40 18 00 00 40 01
002510   00 47 04 80 2a 00 86 39 00 00 80 13 00 86 3b 00
002520   00 80 13 00 86 3a 00 00 40 29 00 86 02 40 45 00
002530   30 7c 45 00 30 02 40 29 00 00 00 2d 02 40 22 1e
002540   00 00 22 01 00 0a 01 00 51 01 00 0d 01 40 15 13
002550   fa 02 80 5c 1d c2 33 1e 30 40 5c 1d c2 01 00 06
002560   01 80 24 1e 30 3e 1d c2 01 40 59 00 00 01 00 01
002570   01 00 03 02 80 35 1e 10 00 00 86 80 34 00 86 3f
002580   1e 10 02 7c 64 1e 30 40 64 1e 30 02 78 28 00 c0
002590   40 27 15 f0 01 00 68 01 80 3f 00 30 3e 1c f8 01
0025a0   40 12 1f f0 02 ba 19 1a f0 3e 19 f2 80 19 1a f0
0025b0   3e 19 f2 01 40 39 00 00 06 80 46 0f 00 32 00 00
0025c0   80 46 0f 00 3f 00 00 74 15 13 fa b9 12 00 00 3e
0025d0   00 02 79 12 1f f0 80 46 0f f0 3e 18 00 01 00 10
0025e0   01 40 20 00 00 02 80 14 1e 30 3e 1d c2 40 3a 1e
0025f0   30 01 40 44 00 00 01 00 07 01 40 1e 16 f0 02 40
002600   5a 00 f0 80 14 1e 30 3e 1d f2 03 73 67 00 00 80
002610   67 00 ca 33 00 00 40 67 00 ca 03 7c 2d 18 00 40
002620   2d 00 30 00 2d 03 79 2f 00 f4 7b 2f 00 f4 40 2e
002630   00 04 01 40 2b 14 f8 02 80 31 12 00 3e 00 00 40
002640   31 12 00 06 7e 1d 00 00 79 1c 1b 30 7b 18 1b 30
002650   40 1a 17 30 7a 1b 18 00 7c 1a 18 00 01 40 3d 1b
002660   00 02 40 37 00 00 00 37 2a 99 2a a3 2a ad 2a b9
002670   2b 10 2b 73 2b 7a 2b a9 2b af 2b b5 2c 06 2c 11
002680   2c 31 2c 7e 2c 95 2c 92 2c a5 2c a8 30 72 32 a7
002690   2c b4 30 58 30 31 2d 26 2d 17 2d 41 2d 7b 2d 97
0026a0   2d a5 34 48 2d ae 2d e4 2d eb 2e 05 2d f1 2e 60
0026b0   31 9b 31 dc 2e 66 2e 90 2e 94 2e a0 32 fe 2e a9
0026c0   2f 0b 2f 28 2f 0f 31 0b 2f 4e 2f 74 2f 81 2f d3
0026d0   2f ee 33 7b 30 06 30 0b 30 a9 30 38 33 97 30 3d
0026e0   30 47 30 a0 30 e8 30 f2 30 fa 31 4f 31 03 31 55
0026f0   31 5a 31 68 35 1a 31 a6 32 36 34 1d 32 3b 32 6c
002700   32 85 32 9b 33 15 33 1d 33 2d 33 32 33 3d 33 48
002710   34 26 33 4d 33 72 33 80 33 84 33 8d 33 b0 33 cf
002720   33 e3 34 7e 34 db 34 e6 34 fb 35 20 35 24 35 2f
002730   2c ab 35 a9 35 41 35 b6 35 bb 35 c1 00 00 00 00
002740   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002750   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002760   00 00 32 a0 00 00 00 00 00 00 00 00 2c ed 2d 2b
002770   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002780   00 00 00 00 31 7e 00 00 00 00 00 00 00 00 2e 99
002790   32 a0 00 00 00 00 00 00 00 00 00 00 00 00 2f 58
0027a0   00 00 00 00 2f d7 00 00 00 00 00 00 00 00 00 00
0027b0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0027c0   00 00 00 00 00 00 31 5f 35 02 00 00 00 00 33 ed
0027d0   00 00 00 00 00 00 00 00 00 00 33 19 00 00 00 00
0027e0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
0027f0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002800   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
002810   00 12 28 a0 00 ee 29 80 00 ef 35 dc 00 f0 29 02
002820   00 f1 2d 07 00 f2 29 17 00 f3 30 e9 00 f4 28 a7
002830   00 f5 31 2f 00 f6 29 33 00 f7 2d 38 00 f8 30 fe
002840   00 f9 2c 0b 00 fa 2e 7a 00 fb 36 0d 00 fc 31 28
002850   00 fd 36 bc 00 fe 35 42 00 ff 03 2e 2c 22 07 02
002860   18 14 c1 93 6a 41 ba 00 16 45 94 a5 04 f1 00 16
002870   65 94 a5 04 f0 00 16 e8 d2 52 41 e6 00 16 f7 9a
002880   69 41 e0 00 16 f7 a9 14 41 a9 00 16 fa ce ea 41
002890   ea 00 17 25 94 a5 04 ef 00 18 a5 94 a5 04 fc 00
0028a0   18 f4 eb 25 08 ee 00 19 17 d3 18 08 f5 00 19 19
0028b0   bb 66 41 ad 00 19 3b aa 79 80 01 00 19 86 ba 65
0028c0   04 ff 00 19 d7 94 a5 a0 01 bc 19 d7 97 95 80 01
0028d0   00 1a 31 94 a5 04 f5 00 1a 39 9a e5 80 01 00 1a
0028e0   65 94 a5 04 fb 00 1a 68 b9 53 22 df 00 1a 69 94
0028f0   a5 04 f8 00 1a 78 f1 57 41 f3 00 1a b5 c7 c5 41
002900   df 00 1a f4 ea 69 08 f1 00 1a f9 94 a5 80 01 00
002910   1b 10 94 a5 41 da 00 1b 25 94 a5 08 f3 00 1b 39
002920   99 0d 41 dc 00 1b 39 99 10 41 d3 00 1b 86 c1 45
002930   41 b1 00 1b 86 f8 a5 08 f7 00 1b a5 94 a5 80 01
002940   00 1b aa 94 a5 80 01 00 1c cc 94 a5 80 01 00 1c
002950   d3 bb 0d 41 c4 00 1c d7 a8 a5 22 f6 00 1c d8 c1
002960   59 80 01 00 1c d9 94 a5 80 01 00 1c d9 b5 45 41
002970   cf 00 1d 46 eb 2e 22 ec 00 1d 4a e6 2a 80 01 00
002980   1d 4d ba 69 08 ef 00 1d 51 c4 a5 80 01 00 1d 51
002990   d3 85 08 f0 00 1d 53 a8 d9 08 f0 00 1d d7 a7 05
0029a0   22 eb 00 1d d9 a8 a5 41 9f 00 1e 26 a2 05 22 c4
0029b0   00 1e 26 a5 45 80 01 00 1e 34 a2 05 41 f6 00 1e
0029c0   34 d1 3e 22 d4 00 1e 34 f0 a5 41 e5 00 1e 86 dd
0029d0   25 c0 01 e1 1e 86 dd 2a 22 ee 00 1e 86 dd 38 80
0029e0   01 00 1e 86 e4 a5 80 01 00 1e 89 b9 58 80 01 00
0029f0   1e 89 f8 a5 80 01 00 1e 91 e4 a5 80 01 00 1e 93
002a00   ab 05 80 01 00 1e 94 c0 a5 80 01 00 1e 94 c3 05
002a10   80 01 00 1e 99 e6 2a 80 01 00 1e 9d 94 a5 80 01
002a20   00 1e e6 a1 51 80 01 00 1e e6 cd 0d 80 01 00 1e
002a30   e6 cd 2e 41 a2 00 1e e6 e3 05 22 dd 00 1e e6 ed
002a40   45 22 fb 00 1e ea 9a 05 41 f6 00 1e ea 9b 2d 80
002a50   01 00 1e ee a9 65 41 b4 00 1e f4 f2 65 22 e8 00
002a60   1f 47 9e 2a 80 01 00 1f 4c 94 a5 80 01 00 1f 54
002a70   f8 a5 80 01 00 1f 57 cc a5 41 ac 00 1f 57 cd 49
002a80   22 b1 00 1f 57 cd d3 22 c3 00 1f 59 94 a5 04 f3
002a90   00 1f 59 e6 93 80 01 00 20 d3 a6 2a 80 01 00 20
002aa0   d3 ec d8 80 01 00 20 d7 d5 59 80 01 00 20 d7 df
002ab0   c5 41 ef 00 20 d8 a8 a5 80 01 00 20 d8 c1 59 80
002ac0   01 00 20 d8 e4 a5 41 c4 00 20 d9 a1 a5 41 ef 00
002ad0   21 a6 ba 65 80 01 00 21 a6 c5 c8 80 01 00 21 a6
002ae0   cf 25 41 f3 00 21 a6 e1 45 41 ec 00 21 aa e3 25
002af0   80 01 00 21 ae ca 6a 80 01 00 21 ba a2 05 41 d9
002b00   00 21 ba e5 45 80 01 00 22 2e ad 65 80 01 00 22
002b10   2e ad 78 80 01 00 22 2e c8 e5 41 9d 00 22 34 e1
002b20   45 41 a4 00 22 34 ed 45 80 01 00 22 86 c4 a5 80
002b30   01 00 22 8b ad d3 80 01 00 22 8e c4 a5 80 01 00
002b40   22 8e cf 05 80 01 00 22 93 e3 52 41 9f 00 22 93
002b50   e6 f4 22 d0 00 22 9a cf 25 41 ee 00 22 f4 e3 05
002b60   41 a8 00 22 fe e3 26 22 bf 00 23 55 94 a5 80 01
002b70   00 23 57 e1 45 41 bd 00 23 59 94 a5 41 cc 00 23
002b80   c8 c6 95 80 01 00 24 a5 94 a5 18 fa 16 24 d2 94
002b90   a5 80 01 00 24 d2 99 8a 41 f6 00 24 d2 cc a5 41
002ba0   bd 00 24 d7 c0 a5 22 fe 00 25 46 a4 a5 22 b0 00
002bb0   25 4b c4 d9 41 e2 00 25 58 a2 ee 41 a0 00 25 58
002bc0   e6 f4 41 f6 00 25 c6 b2 74 41 b3 00 25 c6 ca 93
002bd0   80 01 00 25 cc 94 a5 41 c6 00 25 d7 e4 a5 80 01
002be0   00 25 d8 aa 47 41 a1 00 25 db a8 a5 41 f2 00 26
002bf0   92 a8 a5 80 01 00 26 93 9b 2a 41 b2 00 26 94 dc
002c00   a5 80 01 00 26 9a e1 45 41 b9 00 26 9c cc a5 18
002c10   fa 16 26 ee ce 05 41 b0 00 26 ee ed 45 41 c4 00
002c20   26 ee ed 57 80 01 00 26 f4 d4 a5 41 c0 00 26 fe
002c30   aa e5 80 01 00 27 58 e7 c5 22 d6 00 28 a5 94 a5
002c40   13 1e 00 28 d8 e4 a5 13 1e 00 28 d9 94 a5 41 9f
002c50   00 29 8c 94 a5 80 01 00 2a 3b bb 0d 22 de 00 2a
002c60   4a dc d1 80 01 00 2a 74 de 54 22 b3 00 2a 79 aa
002c70   e5 41 d1 00 2b 6e c4 a5 22 c1 00 2b a6 c9 d3 41
002c80   a0 00 2b a8 aa b9 04 f2 00 2b ae e4 a5 41 a1 00
002c90   2b b4 dd 0e 41 c4 00 2b b6 e9 d8 22 b8 00 2b b9
002ca0   ba 6c 41 b9 00 2b ca 94 a5 80 01 00 2c d8 e5 53
002cb0   41 dc 00 2d 09 96 e5 80 01 00 2d 4a a4 a5 41 b2
002cc0   00 2d 4a c4 a5 41 c8 00 2d cc b7 25 41 d3 00 2d
002cd0   cc ea ee 80 01 00 2d d1 c4 a5 41 9e 00 2d d3 a4
002ce0   a5 41 f7 00 2e 26 c9 d3 22 c6 00 2e 2e d4 a5 41
002cf0   aa 00 2e 34 d2 e5 80 01 00 2e 91 c6 9c 41 ec 00
002d00   2e 94 a4 a5 80 01 00 2e 97 94 a5 08 f2 00 2e 97
002d10   9d c9 22 fd 00 2e 97 a1 45 80 01 00 2e 97 a4 a5
002d20   41 a8 00 2e 97 ab 19 a2 fa 01 2e ea a8 a5 41 ce
002d30   00 2e ee b1 c9 22 be 00 2e f4 c8 a5 08 f8 00 2e
002d40   f4 cf 25 22 ef 00 2f 48 c0 a5 41 bd 00 30 a5 94
002d50   a5 04 fe 00 30 d7 c5 c8 80 01 00 30 d8 94 a5 80
002d60   01 00 30 d9 a8 a5 80 01 00 30 d9 ab 05 80 01 00
002d70   31 59 94 a5 41 ef 00 31 b4 e3 38 80 01 00 31 c6
002d80   cf 25 22 ab 00 31 db a8 a5 41 b2 00 32 26 e3 05
002d90   22 e5 00 32 85 94 a5 41 f9 00 32 91 a4 a5 a0 01
002da0   e9 32 99 b5 c8 22 db 00 32 e6 9c a5 41 ef 00 32
002db0   e6 e5 45 80 01 00 32 e6 e5 d3 80 01 00 32 ea aa
002dc0   65 22 ce 00 32 f4 ea 69 80 01 00 32 fa a8 a5 80
002dd0   01 00 33 4e a5 45 22 d1 00 33 4e a5 47 80 01 00
002de0   34 d3 a4 a5 c0 01 b2 34 d3 a4 bc 22 bd 00 34 d3
002df0   a7 05 80 01 00 34 d9 a1 a5 41 c3 00 35 46 a4 a5
002e00   80 01 00 35 51 c6 85 41 9b 00 35 57 94 a5 80 01
002e10   00 35 57 a8 a5 04 eb 00 35 c5 94 a5 41 9b 00 35
002e20   d2 94 a5 80 01 00 35 d9 94 a5 41 d3 00 36 91 a4
002e30   a5 41 ef 00 36 95 94 a5 41 fe 00 36 99 94 a5 22
002e40   e7 00 36 9a e1 45 80 01 00 37 4c a8 a5 22 b4 00
002e50   37 53 b2 fe 22 ac 00 37 57 c4 a5 41 d9 00 37 57
002e60   e4 a5 41 d3 00 38 a5 94 a5 41 d4 00 39 93 bb 2a
002e70   41 ac 00 3a 47 b8 ea 41 b0 00 3a 65 94 a5 18 fb
002e80   15 3a 68 9a 79 41 f3 00 3a 68 ba 6a 41 ac 00 3a
002e90   6b c4 d9 62 c9 fd 3a 6f ea ea 41 d3 00 3a 78 a2
002ea0   ee 80 01 00 3a 78 aa f9 41 fb 00 3a 78 b9 2a 18
002eb0   fb 15 3a 79 cf 52 80 01 00 3a 79 d0 a5 18 fb 15
002ec0   3a 79 dd c8 22 a9 00 3a 7b aa 79 41 d4 00 3a 7b
002ed0   bb 0e 22 c2 00 3b 05 94 a5 04 f9 00 3b 25 94 a5
002ee0   80 01 00 3b 74 df c5 a0 01 c5 3c c9 a8 a5 22 b7
002ef0   00 3d 5c aa 25 80 01 00 3d 5c aa 2a 22 ea 00 3d
002f00   5c aa 38 80 01 00 3f 52 d4 a5 41 f2 00 41 5e 94
002f10   a5 80 01 00 41 c8 c0 a5 41 ab 00 41 d1 c4 a5 41
002f20   d2 00 41 d8 e0 a5 41 ff 00 42 6e ad 45 80 01 00
002f30   42 6e ed 58 80 01 00 42 74 a2 05 41 e4 00 44 a5
002f40   94 a5 41 c2 00 44 c7 aa 25 80 01 00 44 c9 a5 57
002f50   80 01 00 44 d0 a8 a5 80 01 00 44 d2 d4 a5 80 01
002f60   00 44 d3 a4 a5 13 13 00 44 d3 e5 57 80 01 00 44
002f70   d7 b1 45 22 f4 00 44 da cd 0d 41 9c 00 45 46 ac
002f80   a5 80 01 00 45 46 ae 2a 80 01 00 45 46 d4 a5 41
002f90   f2 00 45 46 e5 aa 22 ae 00 45 46 ed 45 41 be 00
002fa0   45 46 ed 58 80 01 00 45 59 e5 57 80 01 00 45 c9
002fb0   94 a5 80 01 00 45 cb e4 a5 41 ed 00 45 cc b7 25
002fc0   c0 01 e9 45 d8 e5 53 41 dd 00 46 88 c0 a5 41 ae
002fd0   00 46 93 b0 a5 22 f8 00 46 94 c0 a5 41 c2 00 46
002fe0   9c aa e5 41 d7 00 47 53 a1 a5 80 01 00 47 53 b3
002ff0   05 80 01 00 47 57 c1 d3 22 fc 00 48 c8 b5 d3 80
003000   01 00 48 ce c4 a5 a2 f0 01 48 ce c4 f4 80 01 00
003010   48 d0 a8 a5 41 a6 00 48 d3 94 a5 80 01 00 48 d3
003020   b2 2a 22 c0 00 48 d5 94 a5 80 01 00 48 d7 9e 2a
003030   22 c7 00 48 d9 a1 a5 a0 01 d3 48 d9 a1 a7 80 01
003040   00 48 d9 a1 aa 80 01 00 49 45 94 a5 80 01 00 49
003050   59 9a 25 22 cf 00 49 d7 de 97 80 01 00 4a 9a e5
003060   a5 80 01 00 4a 9b a8 a5 41 e8 00 4b 57 a5 57 41
003070   d2 00 4b 59 ba 26 22 d5 00 4b d8 aa 2b 80 01 00
003080   4c a5 94 a5 13 1f 00 4c ce c4 a5 80 01 00 4c ce
003090   c7 05 80 01 00 4c d7 de 9c 22 f9 00 4c d8 e7 c5
0030a0   22 e4 00 4d 45 94 a5 13 1b 00 4d 58 e4 a5 80 01
0030b0   00 4e 85 94 a5 04 ed 00 4e 97 e5 a5 13 1f 00 4e
0030c0   97 e5 aa 13 1b 00 4e 97 e5 bc 13 1a 00 4f 85 94
0030d0   a5 13 1a 00 51 34 dc a5 80 01 00 51 3e e3 0a 41
0030e0   c1 00 51 65 94 a5 04 f7 00 51 6b 94 a5 08 f4 00
0030f0   51 6b aa e5 41 b2 00 52 29 94 a5 22 e1 00 52 65
003100   94 a5 08 f9 00 52 6a 94 a5 04 f4 00 52 79 d0 a5
003110   08 f9 00 52 95 e0 a5 04 fd 00 52 aa cc a5 41 e7
003120   00 52 ee aa 79 22 d8 00 53 59 94 a5 18 fd 14 53
003130   6a dc a5 08 f6 00 54 cc a8 a5 80 01 00 54 ce cf
003140   25 80 01 00 54 ce cf 2e 80 01 00 54 ce dc a5 80
003150   01 00 54 d3 aa 25 80 01 00 54 d7 a1 b2 22 e0 00
003160   54 d8 e0 cc 80 01 00 54 d9 94 a5 41 c8 00 54 d9
003170   b4 a5 80 01 00 55 46 c4 a5 41 ca 00 55 49 ab 19
003180   80 01 00 55 55 d5 57 22 e6 00 55 57 e2 93 80 01
003190   00 55 59 94 a5 41 c8 00 55 c8 c0 a5 41 e3 00 55
0031a0   ca a1 45 80 01 00 55 ca dd 0a 41 cc 00 55 d1 a8
0031b0   a5 80 01 00 56 26 a1 45 41 fb 00 56 26 e3 2e a2
0031c0   cd 01 56 90 a8 a5 41 b6 00 56 99 94 a5 80 01 00
0031d0   56 9a dc a5 41 f1 00 56 e6 f8 a5 41 de 00 56 e6
0031e0   f9 57 80 01 00 56 ea e3 05 41 c9 00 56 f4 a1 4a
0031f0   41 f9 00 57 51 c4 a5 41 fc 00 57 52 d4 a5 c0 01
003200   cd 57 57 e3 4a 41 ec 00 57 58 b4 a5 41 c9 00 57
003210   59 94 a5 41 fb 00 58 a5 94 a5 41 f8 00 5b 46 cf
003220   2e 80 01 00 5b 4e e4 a5 41 f8 00 5c cb e4 a5 80
003230   01 00 5c ce c4 a5 80 01 00 5c ce c5 d3 80 01 00
003240   5c ce cc f4 80 01 00 5c ce e1 45 41 ed 00 5c d2
003250   d4 a5 80 01 00 5c d5 94 a5 41 e4 00 5d 46 a4 a5
003260   41 f4 00 5d 49 94 a5 22 cb 00 5d 4b c5 48 80 01
003270   00 5d 51 a8 d8 41 ce 00 5d 52 99 d3 80 01 00 5d
003280   52 d3 6a 41 ef 00 5d 55 aa 79 41 bb 00 5d 55 c7
003290   c5 41 f3 00 5d 58 e4 d7 41 b7 00 5d 58 e6 97 41
0032a0   a5 00 5d d3 b0 a5 41 ca 00 5d db aa e5 80 01 00
0032b0   5e 87 9d 57 80 01 00 5e 91 c4 a5 41 bf 00 5e 95
0032c0   a8 a5 80 01 00 5f 47 94 a5 41 c8 00 5f 4c 94 a5
0032d0   80 01 00 5f 53 94 a5 41 f9 00 5f 58 e7 c5 22 b2
0032e0   00 60 a5 94 a5 13 1c 00 60 c8 c0 a5 80 01 00 60
0032f0   ce c6 97 80 01 00 60 d3 a4 a5 80 01 00 60 d3 a7
003300   8e 80 01 00 60 d5 d5 ae a0 01 b6 60 db a8 a5 41
003310   db 00 60 de 94 a5 41 f3 00 61 06 dc c7 80 01 00
003320   61 0a d7 37 80 01 00 61 14 dd 45 41 c5 00 61 17
003330   a8 d2 41 af 00 61 17 ab 85 22 ca 00 61 17 ab 89
003340   80 01 00 61 17 ba b9 41 bc 00 61 45 94 a5 13 19
003350   00 61 46 dd 0d 41 d0 00 61 48 ea ea 41 dc 00 61
003360   4a 94 a5 41 f7 00 61 4a c0 a5 41 f7 00 61 51 ac
003370   a5 80 01 00 61 59 94 a5 41 aa 00 61 a6 c1 45 41
003380   d5 00 61 ae e4 a5 41 bd 00 61 b4 eb 25 41 af 00
003390   61 b4 ed 51 80 01 00 61 ba e4 a5 41 aa 00 61 d1
0033a0   ed 57 22 aa 00 61 d9 94 a5 41 9d 00 62 0a c5 59
0033b0   a2 ad 01 62 0e c8 a5 41 f4 00 62 0e d4 a5 41 fe
0033c0   00 62 1a c6 25 80 01 00 62 26 b0 a5 80 01 00 62
0033d0   26 f8 a5 41 d2 00 62 2e a1 45 41 cc 00 62 2e a5
0033e0   45 80 01 00 62 46 c6 25 22 f1 00 62 46 e1 a5 41
0033f0   f6 00 62 4a c6 25 41 b5 00 62 6e ad 65 41 b5 00
003400   62 9a e5 a5 13 1c 00 62 9a e5 aa 13 19 00 62 9a
003410   e5 bc 13 18 00 62 ae c6 25 41 f1 00 62 ae dd d9
003420   80 01 00 63 26 9c a5 41 a7 00 63 26 ba e5 80 01
003430   00 63 26 ba e8 80 01 00 63 26 ba fc 80 01 00 63
003440   26 cd 25 41 a1 00 63 26 df 31 41 b1 00 63 2a aa
003450   a5 22 bb 00 63 2a d4 a5 41 f9 00 63 2a d7 05 80
003460   01 00 63 2e c5 59 80 01 00 63 34 cd 45 22 ff 00
003470   63 37 9a 6c 22 da 00 63 37 a8 d2 80 01 00 63 37
003480   ba 0a 41 a3 00 63 3a ad 65 41 fb 00 63 55 aa e5
003490   41 c7 00 63 55 aa e7 41 c7 00 63 57 d6 ee 41 b1
0034a0   00 63 58 d5 c8 22 f5 00 63 85 94 a5 13 18 00 63
0034b0   86 c6 34 41 b0 00 63 8e c8 a5 41 cf 00 63 8e cd
0034c0   85 41 b8 00 63 8e e5 0d 80 01 00 63 94 dd 25 80
0034d0   01 00 64 c7 c5 45 80 01 00 64 d0 a8 a5 41 ef 00
0034e0   64 d1 c0 a5 41 d6 00 64 d3 94 a5 22 c8 00 64 d8
0034f0   e5 45 41 9f 00 65 51 c4 a5 41 da 00 65 aa 94 a5
003500   04 fa 00 65 aa c8 a5 80 01 00 65 aa cc a5 04 f6
003510   00 65 ae a9 65 80 01 00 65 ae a9 78 22 f3 00 65
003520   b7 d3 4c 08 fe 00 65 b7 d3 85 41 d9 00 65 b7 e8
003530   a5 08 fe 00 65 b7 eb 19 41 b8 00 65 ca 94 a5 41
003540   dc 00 66 85 94 a5 08 ff 00 66 97 a1 a5 80 01 00
003550   66 98 e0 a5 41 d9 00 66 9a a1 a5 41 c8 00 66 9a
003560   dc a5 22 d2 00 66 e6 ba 25 80 01 00 66 e6 d4 a5
003570   22 d7 00 66 e6 d4 bc 80 01 00 66 e6 d5 34 80 01
003580   00 66 ea 9b 1a 80 01 00 66 ea a8 a5 80 01 00 66
003590   ea ab 05 80 01 00 66 f4 c6 25 80 01 00 66 f4 d5
0035a0   be 22 e2 00 66 fa ce 05 80 01 00 67 4c 94 a5 41
0035b0   fc 00 67 53 cd 51 80 01 00 67 57 cc a5 41 aa 00
0035c0   67 8e e3 2e 22 ba 00 68 a5 94 a5 18 fc 17 6a 3e
0035d0   e3 0a 41 c1 00 6a 66 e7 26 41 ce 00 6a 69 aa e5
0035e0   08 f0 00 6a 69 aa f3 08 f0 00 6a 6b 9b 19 41 ce
0035f0   00 6a 71 d1 10 41 f5 00 6a 77 eb 19 22 e3 00 6a
003600   78 a2 ee 41 cb 00 6a 79 b9 45 41 ce 00 6a a5 94
003610   a5 18 fc 17 6b 0a c5 58 22 af 00 6b 0e cd 85 08
003620   fe 00 6c d1 ed 45 80 01 00 6c d2 d5 d7 22 b9 00
003630   6d 57 9e 98 41 fa 00 6d 57 e1 d4 41 eb 00 6d c8
003640   ba 9a 22 f2 00 6d d9 dd 54 22 b5 00 70 a5 94 a5
003650   33 1d d9 70 c9 a8 a5 41 cf 00 70 ce e4 a5 41 f0
003660   00 70 d0 a8 a5 41 b1 00 70 d1 c0 a5 41 f9 00 70
003670   d1 c4 a5 80 01 00 70 d1 c7 05 80 01 00 70 d9 aa
003680   e5 80 01 00 70 db a8 a5 41 a2 00 71 58 e4 a5 33
003690   1d d9 71 a6 e4 a5 41 a0 00 71 a6 e7 05 41 a0 00
0036a0   71 aa dd 45 41 f7 00 71 ae e5 45 22 ed 00 71 d3
0036b0   a5 d3 22 f7 00 71 d3 a6 9c 80 01 00 71 d9 b4 a5
0036c0   08 fe 00 72 94 a5 53 22 dc 00 72 ea cd 0d 80 01
0036d0   00 72 ee e5 d3 80 01 00 78 a5 94 a5 04 ec 00 78
0036e0   d3 c0 a5 41 fc 00 79 51 c4 a5 41 af 00 79 51 c6
0036f0   9c 22 cc 00 79 58 94 a5 04 ee 00 7c a5 94 a5 41
003700   f0 00 7e 97 c0 a5 41 d8 00 57 75 62 b9 59 49 62
003710   ba 62 bc 62 bf 00 4b 5d 8e 00 32 5d 94 00 0f 5d
003720   9f 00 00 00 14 5b 57 00 0a 5b 5d 00 05 5b 67 00
003730   00 5c ce 5d 19 64 53 00 06 00 1a 00 05 00 75 00
003740   04 00 20 00 03 00 03 00 1a 00 75 00 20 00 0a 00
003750   4f 00 1a 00 a5 00 20 00 13 00 20 00 55 00 40 00
003760   83 00 40 5d 7e 61 aa 59 db 62 25 59 e1 61 fc 00
003770   01 00 00 a0 27 cb e7 7f 64 00 63 01 00 c1 b1 e7
003780   3f 01 2c 00 63 01 00 c1 b1 00 06 00 00 00 00 00
003790   00 00 00 00 00 00 00 4f 01 00 02 4f 01 01 03 96
0037a0   02 54 01 02 01 56 03 02 00 74 01 00 06 75 02 03
0037b0   00 e7 bf 00 04 6f 06 04 05 4f 06 01 00 e1 ab 06
0037c0   04 00 e1 9b 06 01 05 95 03 61 03 02 45 0d 03 00
0037d0   e1 9b 01 00 03 ab 05 00 00 e0 03 1d 9b 3e 88 ff
0037e0   ff 00 e1 97 00 00 01 e0 07 1d 9b 4e 50 28 00 e0
0037f0   07 1d 9b 47 92 96 00 0d 10 2e 0d 8a a7 0d 36 01
003800   0d 83 1e 6e 83 10 e0 3f 2c 31 00 bb e0 3f 30 fa
003810   00 e0 3f 1c 0d 00 8c ff c2 00 01 00 00 e0 3f 1c
003820   13 01 8c ff fa 00 0c 00 00 00 00 00 00 00 00 00
003830   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0d
003840   04 00 0d 05 00 0d 08 01 e0 3f 1d f2 6e a0 6e 81
003850   fb 6f 2e 1d 01 6f 5e 1d 02 a0 8a 80 3e e0 2f 3d
003860   38 8a 00 a0 00 f5 0d 0a 00 25 04 01 d3 6f 2e 04
003870   00 41 00 30 3f f5 e1 ab 2e 04 8a 0d 0a 01 a0 0a
003880   57 0d 04 00 25 04 02 d0 6f 5e 04 00 41 00 30 3f
003890   f5 e1 ab 5e 04 8a 0d 04 00 a0 02 48 2d 03 02 8c
0038a0   00 33 43 02 01 58 2d 06 5e a0 01 48 0d 05 00 8c
0038b0   00 06 4f 2e 01 05 2d 03 02 8c 00 19 43 01 01 52
0038c0   0d 08 00 2d 06 2e 4f 5e 01 05 2d 03 01 8c 00 05
0038d0   0d 03 01 a0 05 4a 41 01 01 46 4f 2e 01 05 41 5b
0038e0   66 4f a0 2b cc e0 2b 1d 3a 5b 4b 07 8c 01 43 a0
0038f0   03 69 50 55 00 00 57 00 40 00 a0 00 4e e0 2f 1d
003900   3a 5b 07 0d 4b 00 8c 01 29 a0 36 47 ad 49 8c 01
003910   21 ad 32 0d 07 00 8c 01 19 0d 90 00 0d 21 00 43
003920   03 01 45 0d 21 01 0d 0a 00 25 04 03 00 57 43 90
003930   00 00 3d b2 84 25 61 90 03 c7 b2 53 2d aa e0 b2
003940   50 ef a9 19 41 90 01 c5 e5 7f 73 b2 00 31 05 12
003950   2a 79 3a 93 a9 20 41 90 01 c8 b2 9a ea 8c 00 05
003960   b2 bb 05 b2 4c b8 64 01 d4 b2 bb 8c 00 c4 a0 0a
003970   00 c0 ad 63 b2 06 a0 05 03 13 26 41 45 c8 a5 bb
003980   8c 00 af a0 08 c9 6f 5e 04 09 8c 00 06 6f 2e 04
003990   09 a0 08 c8 2d 0b 09 8c 00 05 2d 0b 05 a0 08 c8
0039a0   2d 0c 05 8c 00 05 2d 0c 09 43 03 01 d1 4f 74 06
0039b0   00 4f 00 00 00 c1 8f 00 28 d1 00 60 a3 83 07 41
0039c0   0b 82 47 95 90 8c ff 63 41 5b 49 58 a0 0c d5 4f
0039d0   74 06 00 4f 00 00 00 c1 8f 00 28 d1 47 66 0b 0c
0039e0   3f 49 41 78 01 68 41 5b 49 64 a3 0b 00 c1 aa 00
0039f0   83 10 07 d1 a3 0b 00 61 00 0c ca a3 0b 00 4a 00
003a00   0c 3f 28 4a 0b 11 c7 4a 0b 0b 3f 1f 41 09 30 47
003a10   aa 8a 8c 00 04 aa 09 b2 97 a0 2d 4b 0b 2d 8e 0c
003a20   0d 0a 01 e0 2a 1d 3a 5b 4b 8e 07 41 07 02 3e fb
003a30   41 07 02 ce a3 83 00 51 00 12 00 e0 9f 00 06 07
003a40   41 07 02 4b 0d 2d 00 8c 00 05 0d 2d 00 a0 6e c0
003a50   c1 95 5b 02 01 54 c1 c1 95 5b 0c 08 00 c1 c1 95
003a60   5b 09 06 05 c1 c1 95 5b 07 0b 0a c1 e0 3f 1d c4
003a70   07 ab 07 00 07 00 00 00 00 00 00 00 00 00 00 00
003a80   00 00 00 2d 05 5b 2d 06 4b 2d 07 8e c1 6b 30 03
003a90   02 4f e0 2f 3d 38 8a 00 a0 00 46 ad 32 9b 02 41
003aa0   02 30 45 2d 02 8a 41 03 30 45 2d 03 8a 2d 5b 01
003ab0   2d 4b 02 a0 4b cd 41 8e 30 c9 41 5b 66 c5 2d 8a
003ac0   4b 2d 8e 03 c1 6b 82 4b 8e 4b e0 3f 3a ea 04 a0
003ad0   04 00 5a 2d 02 4b 2d 03 8e 51 83 12 00 e0 bf 00
003ae0   04 a0 04 00 48 a3 83 00 51 00 12 00 e0 9f 00 01
003af0   04 a0 04 00 38 6f 97 01 00 e0 bf 00 04 a0 04 6d
003b00   a0 03 cd 51 03 12 00 e0 bf 00 04 a0 04 5f a0 02
003b10   d1 41 01 66 cd 51 02 12 00 e0 bf 00 04 a0 04 4d
003b20   6f 96 01 00 e0 bf 00 04 a0 04 c2 2d 5b 05 2d 4b
003b30   06 2d 8e 07 ab 04 03 00 00 00 00 00 00 e0 2f 1d
003b40   a5 01 03 e1 9b 03 01 02 ab 03 05 00 00 00 00 00
003b50   00 00 00 00 00 54 26 b4 03 74 26 45 04 61 04 03
003b60   58 55 45 06 45 a0 02 c6 55 4f 06 4f 74 26 45 05
003b70   e1 9b 05 02 01 ab 05 4f 04 02 00 61 00 01 44 ab
003b80   04 54 04 06 04 8c ff d7 04 00 00 00 00 00 00 00
003b90   00 a0 22 c6 0d 22 00 b1 a0 6e c8 e8 bf 45 8c 00
003ba0   05 e8 bf 4f 74 26 00 01 54 26 b4 02 61 01 02 46
003bb0   95 12 ab 04 4f 01 00 00 a0 00 e4 4f 01 01 03 a0
003bc0   03 dd 55 03 01 00 e1 9b 01 01 00 43 03 01 d0 4f
003bd0   01 02 00 e0 bf 00 00 a0 00 c5 0d 04 01 54 01 06
003be0   01 8c ff ca 0e 00 01 00 00 00 00 00 00 00 00 00
003bf0   00 00 00 00 00 00 00 00 00 00 00 ff ff 00 00 00
003c00   00 05 0c 09 d6 a0 82 4b 6f 74 0c 00 e1 ab 24 0c
003c10   00 e1 a7 74 0c 00 8c ff ea 2d 06 83 2d 07 4d 0d
003c20   1f 00 0d 4d 00 0d 13 00 e1 a7 5e 1d 00 e1 a7 2e
003c30   1d 00 e1 a7 14 1d 00 a0 76 55 41 83 1e d1 0d 83
003c40   1e e0 1f 3d 5d 1e 10 e0 2f 2a 3d 10 36 a0 8f de
003c50   2d 01 8f e0 2b 20 e3 3b 47 00 43 30 00 47 21 1e
003c60   83 43 bb 0d 8f 00 0d 2d 00 8c 00 3a a0 2d d8 2d
003c70   01 2d 43 30 00 4b 21 1e 83 47 41 5b 55 c3 bb 0d
003c80   2d 00 8c 00 21 0d 83 1e 0d 76 00 06 1e 8f c5 a3
003c90   83 10 e0 2f 2a 3d 10 36 43 30 00 43 bb e5 7f 3e
003ca0   e4 af 67 47 50 47 01 40 a0 40 45 ad 66 b1 6f 47
003cb0   01 02 c1 8f 02 31 13 01 15 54 01 02 00 6f 47 00
003cc0   00 c1 83 00 28 68 28 6f 48 54 01 02 01 96 40 43
003cd0   40 01 db b2 14 c2 6c 8e 00 3d 35 51 54 01 11 11
003ce0   6a 58 3a 6a 63 05 48 a6 8b a5 bb b1 4f 2a 00 00
003cf0   a0 00 80 bc 43 40 02 71 54 01 02 00 6f 47 00 00
003d00   c1 8f 00 28 92 63 b2 14 c2 6c 22 07 a8 52 f7 29
003d10   19 02 4e 63 26 41 58 00 36 5b 54 65 49 03 2a 77
003d20   25 48 a6 8b a5 bb b1 43 40 02 6c b2 14 c2 6c 9c
003d30   1a f3 3a 6c 17 a0 52 71 78 01 01 6e 5f 19 03 94
003d40   5d 20 19 79 2a e0 12 84 50 95 13 00 04 ba 61 49
003d50   16 45 98 5d bb 4f 2a 00 0e 54 01 02 00 6f 47 00
003d60   00 e1 ab 2f 0e 00 2d 83 06 56 01 02 00 54 00 06
003d70   00 70 47 00 0d 56 01 02 00 54 00 07 00 70 47 00
003d80   0e 4f 2a 00 00 56 00 02 00 54 00 03 00 e0 2a 21
003d90   1c 0d 0e 00 00 e0 2b 20 e3 2f 47 00 50 47 01 40
003da0   4f 2a 01 01 e0 2b 21 0d 7e 67 00 8c 00 30 e1 97
003db0   2a 03 00 b2 14 c2 6c 27 70 d8 02 74 03 94 5d 20
003dc0   05 97 2a b1 19 0a 16 85 98 5d bb b1 c1 83 02 28
003dd0   bc 2d 4d c5 0d 80 00 e1 97 2a 03 00 6f 47 01 00
003de0   c1 83 00 28 bc 2d 4d 00 f2 50 7e 01 00 a0 00 45
003df0   ad 66 b1 a0 82 e1 b2 14 c2 6c 37 25 cb 2d c8 6a
003e00   39 00 2c 5d 55 28 d9 01 77 19 92 2a 79 60 b2 14
003e10   c2 f4 a5 bb b1 a0 6e 5d b2 14 c2 6c 66 0e 2f 6b
003e20   19 02 ea 55 46 64 06 02 4e 63 26 41 45 48 a6 8b
003e30   a5 bb b1 43 40 01 00 4d 54 01 02 00 6f 47 00 00
003e40   c1 80 00 28 68 28 6f 35 0a d0 54 01 02 00 6f 47
003e50   00 00 c1 8f 00 28 ed 56 54 01 04 01 50 47 01 00
003e60   55 00 02 00 e2 9b 47 01 00 8c 00 2a b2 14 c2 6c
003e70   8e 00 59 6a 69 2a f8 64 26 06 23 4c b2 14 c2 f4
003e80   a5 bb b1 54 01 02 01 50 47 01 00 55 00 01 00 e2
003e90   9b 47 01 00 50 47 01 00 43 00 00 4f e0 2b 20 e3
003ea0   47 3b 00 2d 8f 01 8c 00 05 0d 8f 00 2d 83 06 2d
003eb0   4d 07 e0 2b 21 0d 7e 67 00 e0 2b 20 e3 2f 47 00
003ec0   cd 4f 0c ff ff 2d 09 86 05 0c 09 82 3e 6f 24 0c
003ed0   00 e1 ab 74 0c 00 8c ff f1 e0 2b 20 e3 47 2f 00
003ee0   e0 2b 21 0d 67 7e 00 e1 9b 2a 01 01 36 04 40 00
003ef0   e1 9b 2a 02 00 50 47 01 00 36 02 00 00 74 01 00
003f00   00 36 02 00 08 55 08 01 00 70 47 00 0e 55 08 02
003f10   00 70 47 00 00 74 0e 00 00 e1 9b 2a 03 00 0d 8f
003f20   00 2d 08 40 0d 19 00 0d 94 00 0d 78 00 04 40 00
003f30   48 0d 76 00 8c 01 d4 6f 47 01 02 a0 02 4c e0 2f
003f40   22 4c 01 02 a0 02 82 4a a0 40 48 0d 0a 00 8c 00
003f50   0a 54 01 02 00 6f 47 00 0a c1 8f 02 35 42 4e 41
003f60   04 da 4a cd 4f 02 28 92 8c 00 30 c1 8f 02 35 0a
003f70   6a 43 40 00 66 a0 04 63 a0 76 60 c1 93 0b 00 28
003f80   68 4a cd 4f 02 34 fc 8c 00 11 e1 97 74 00 da e1
003f90   97 74 01 00 cd 4f 02 28 92 c1 80 02 35 0a 28 68
003fa0   28 92 63 c1 8f 02 28 92 4e a0 76 c8 0d 76 00 8c
003fb0   00 05 0d 76 01 a0 40 c6 54 01 02 2d e2 9b 47 01
003fc0   40 8c 01 47 e0 25 21 4c 02 10 03 03 a0 03 80 5c
003fd0   c1 97 04 00 f9 00 55 41 08 01 f1 41 08 02 46 41
003fe0   04 f9 e9 c1 80 0a 35 0a 28 68 28 92 46 42 08 02
003ff0   5b a0 76 cc 41 08 02 48 c1 8f 0a 28 92 ce 43 08
004000   02 6a c1 83 0a 28 6f 28 ed 62 2d 09 03 c1 83 0a
004010   28 6f 28 ed 4c 54 01 02 00 e1 a3 47 00 35 0a 43
004020   08 02 81 1c 0d 76 00 8c 00 e1 e0 25 21 4c 02 40
004030   01 03 a0 03 f8 a0 04 75 2d 04 03 e1 9b 74 00 03
004040   e1 9b 74 01 39 e1 9b 39 00 02 56 01 02 00 54 00
004050   02 0c 70 47 0c 00 e2 9b 39 02 00 54 0c 01 00 70
004060   47 00 00 e2 9b 39 03 00 8c 00 d5 e0 25 21 4c 02
004070   08 00 03 a0 03 5f c1 83 02 28 d1 31 05 d7 e0 27
004080   21 4c 02 20 00 a0 00 4d e0 27 21 4c 02 80 00 a0
004090   00 80 92 43 40 01 5b c1 8f 0a 30 e2 55 a0 03 52
0040a0   c1 80 02 28 d1 31 05 28 99 c8 0d 05 01 8c 00 90
0040b0   a0 03 e2 a0 40 ca c1 83 0a 35 0a 28 68 57 0d 13
0040c0   01 42 94 02 00 7a e1 9b 74 02 03 e1 9b 74 03 02
0040d0   8c 00 6d 41 94 02 5d b2 14 c2 6c 27 71 57 28 03
0040e0   2a 46 4f c0 4e 9a 4f 00 06 c1 44 73 16 45 98 5d
0040f0   bb b1 95 94 2d 3e 04 e0 2a 21 5f 01 03 02 01 a0
004100   01 c0 42 01 00 7a 0d 76 00 e1 97 2a 00 00 a0 09
004110   80 87 0d 5b 66 2d 4b 09 0d 82 00 2d 2b 09 2d 86
004120   09 ab 86 c1 8f 02 30 e2 61 a0 05 ca c1 83 0a 28
004130   68 35 0a 49 e0 2f 23 ef 01 00 b1 0d 05 00 2d 0b
004140   02 54 01 02 01 8c fd e7 e0 27 21 4c 02 04 00 a0
004150   00 3f ed 41 04 da 74 e0 25 21 4c 02 40 01 00 a0
004160   00 e9 41 83 1e 65 b2 14 c2 6c 97 28 c9 00 20 48
004170   d3 68 d1 00 56 64 d1 41 d3 30 01 31 0d 1a e6 23
004180   2a 5f 05 48 a6 8b a5 bb b1 e0 2f 23 ef 01 00 b1
004190   e0 2f 23 c8 01 00 b1 a0 82 c7 e0 3f 22 90 00 0d
0041a0   2b 00 0d 86 00 e0 3f 24 2d 00 a0 00 c0 e0 3f 26
0041b0   95 00 a0 00 c0 e0 3f 29 d0 00 a0 00 c0 e0 3f 29
0041c0   5e 00 a0 00 41 b1 06 00 00 00 00 00 1d 00 01 00
0041d0   01 00 00 50 01 00 00 e2 9b 02 00 00 50 01 01 00
0041e0   e2 9b 02 01 00 6f 01 04 00 e1 ab 02 04 00 56 04
0041f0   02 00 54 00 02 06 70 01 06 00 e2 ab 02 06 00 56
004200   04 02 00 54 00 03 06 70 01 06 00 e2 ab 02 06 00
004210   54 04 02 04 25 05 03 3f ce b0 03 00 00 00 00 00
004220   00 50 01 00 00 55 00 01 03 70 01 03 00 e2 ab 02
004230   03 00 04 03 00 3f f4 b0 07 00 00 00 00 00 00 00
004240   00 00 00 00 00 00 00 4f 2a 03 06 a0 06 c8 2d 04
004250   06 8c 00 16 4f 2a 02 06 70 2f 06 07 54 06 01 00
004260   70 2f 00 00 74 07 00 04 74 04 01 00 e1 9b 2a 03
004270   00 74 04 05 07 74 02 05 00 70 67 00 00 e2 ab 7e
004280   07 00 95 05 61 05 01 3f ea e2 ab 2f 03 04 55 03
004290   01 00 e2 ab 2f 00 01 b0 05 00 00 00 00 00 05 00
0042a0   05 00 00 50 01 04 05 67 05 02 40 43 03 04 c1 49
0042b0   05 03 05 61 05 03 c4 95 04 70 01 04 00 b8 0a 00
0042c0   00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00
0042d0   00 00 00 55 94 01 00 56 00 02 04 a0 02 db 34 02
0042e0   04 05 e1 ab 74 05 02 54 05 01 00 e1 ab 74 00 03
0042f0   54 01 02 01 8c 00 04 95 40 a0 40 47 96 94 8b ff
004300   ff 34 06 04 05 56 01 02 00 74 47 00 00 e1 ab 74
004310   05 00 6f 47 01 00 c1 80 00 34 fc 28 99 28 df 4f
004320   6f 74 05 00 54 00 04 00 e1 ab 74 05 00 04 40 00
004330   56 54 05 01 0a 56 01 02 00 74 47 00 00 e1 ab 74
004340   0a 00 8b ff ff 6f 47 01 03 a0 03 4c e0 2f 22 4c
004350   01 03 a0 03 81 3d a0 40 48 0d 08 00 8c 00 0a 54
004360   01 02 00 6f 47 00 08 c1 83 03 28 ed 28 6f 48 0d
004370   06 01 8c 00 ff c1 83 03 28 d1 31 05 52 c1 8f 08
004380   30 e2 00 f0 96 40 54 01 02 01 8c 00 e7 c1 83 03
004390   35 0a 28 68 d6 e0 27 21 4c 03 08 00 a0 00 e4 4f
0043a0   74 00 00 a0 00 dd a0 07 5a 95 40 54 05 01 0a 56
0043b0   01 02 00 74 47 00 00 e1 ab 74 0a 00 55 01 02 00
0043c0   b8 e0 27 21 4c 03 80 00 a0 00 80 5e 43 40 00 51
0043d0   c1 8f 08 30 e2 4b c1 83 03 28 d1 31 05 00 95 e0
0043e0   25 21 4c 03 20 02 00 a0 00 d0 a0 08 cd e0 27 21
0043f0   4c 08 80 00 a0 00 00 7c a0 06 69 c1 83 08 2a 8a
004400   2c 82 e1 c1 83 08 28 ed 28 6f d9 54 05 01 0a 54
004410   01 02 00 56 00 02 00 74 47 00 00 e1 ab 74 0a 00
004420   ab 01 0d 06 00 8c 00 4c a0 4d 4c a0 82 49 4f 74
004430   00 00 a0 00 d6 e0 27 21 4c 03 20 00 a0 00 75 e0
004440   27 21 4c 03 04 00 a0 00 6b a0 06 f5 e0 27 21 4c
004450   03 10 00 a0 00 4c e0 27 21 4c 03 40 00 a0 00 e1
004460   55 01 04 01 54 01 02 00 e1 a3 47 00 35 0a 54 40
004470   02 40 2d 09 03 0d 07 00 54 01 02 01 8c fe b0 e0
004480   27 21 4c 03 08 00 a0 00 3f ea e0 2f 23 ef 01 00
004490   b1 e0 2f 23 c8 01 00 b1 07 00 00 00 00 00 00 00
0044a0   00 00 00 00 00 00 00 56 01 02 00 74 47 00 00 50
0044b0   00 02 02 56 01 02 00 74 47 00 00 50 00 03 03 04
0044c0   02 00 f2 70 67 03 04 41 04 3a 4b 2d 06 05 0d 05
0044d0   00 8c 00 1c c3 8f 05 27 10 c0 42 04 3a 40 43 04
0044e0   2f 40 56 05 0a 07 55 04 30 00 74 07 00 05 95 03
0044f0   8c ff ce e1 a3 47 01 2e b2 c3 8f 05 03 e8 c0 a0
004500   06 d9 42 06 08 49 54 06 0c 06 8c 00 06 43 06 17
004510   c0 56 06 3c 00 74 05 00 05 2d 80 05 8b 2e b2 00
004520   08 ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00
004530   00 0d 82 00 4f 74 01 00 4f 00 00 07 e0 25 21 4c
004540   07 40 01 08 4f 24 00 00 61 08 00 cc e0 27 21 4c
004550   07 20 00 a0 00 c8 0d 06 01 8c 00 2f e0 25 21 4c
004560   07 80 00 00 a0 00 e4 a0 94 61 e1 97 74 00 00 e1
004570   97 74 01 00 54 47 02 00 e1 9b 74 06 00 54 47 06
004580   00 e1 9b 74 07 00 0d 94 01 4f 74 00 03 a0 03 cd
004590   a0 06 4a 4f 24 00 00 61 03 00 40 41 94 02 c0 4f
0045a0   24 06 00 41 00 01 00 4b 4f 74 02 02 4f 24 02 00
0045b0   61 02 00 c5 a0 02 40 a0 06 e4 54 47 02 00 e1 9b
0045c0   24 06 00 4f 74 07 00 a0 00 4b 54 47 06 00 e1 9b
0045d0   74 07 00 a0 94 51 0d 94 01 8c 00 0b 4f 74 06 00
0045e0   e1 9b 24 06 00 4f 74 07 00 e1 9b 24 07 00 8c 00
0045f0   e6 4f 24 08 00 41 00 01 00 45 4f 74 02 02 4f 24
004600   04 00 61 02 00 c5 a0 02 40 a0 06 db 54 47 02 00
004610   e1 9b 74 06 00 4f 74 07 00 a0 00 4b 54 47 06 00
004620   e1 9b 74 07 00 4f 74 06 00 e1 9b 24 08 00 4f 74
004630   07 00 e1 9b 24 09 00 0d 94 02 8c 00 9a a0 1a 80
004640   96 41 94 01 c9 a0 06 46 0d 1a 00 b1 4f 74 06 04
004650   a0 06 c9 54 47 02 04 0d 06 00 4f 74 07 05 4f 04
004660   00 07 61 04 05 52 a0 06 cb e0 2f 23 87 06 00 8c
004670   00 65 0d 1a 00 b1 a0 06 74 50 07 04 00 47 00 20
004680   ca c1 83 07 28 d1 31 05 64 2d 06 07 54 04 04 04
004690   a0 05 3f cc 2d 05 04 0d 94 01 55 04 04 00 e1 9b
0046a0   74 06 00 e1 9b 74 07 04 8c ff b5 c1 8f 07 31 05
0046b0   4b e0 2f 23 87 06 00 8c 00 1d 50 07 04 00 47 00
0046c0   80 3f cb 61 07 2c 4b e0 2f 23 87 06 00 8c 00 07
0046d0   e0 3f 23 a6 00 4f 70 00 00 e1 9b 39 00 00 50 70
0046e0   02 00 e2 9b 39 02 00 50 70 03 00 e2 9b 39 03 00
0046f0   e1 9b 24 01 39 e2 97 39 02 00 05 01 09 46 0d 4d
004700   01 b0 6f 24 01 00 e1 ab 74 01 00 8c ff ee 01 00
004710   00 4f 24 00 00 e1 9b 74 00 00 e1 9b 46 00 1a 54
004720   1a 01 00 e1 9b 46 01 00 e1 9b 46 02 1a 54 1a 01
004730   00 e1 9b 46 03 00 e0 2a 25 f5 24 24 01 00 4f 24
004740   08 00 a0 00 c5 0d 94 02 0d 1a 00 b0 00 e1 97 46
004750   00 06 e1 97 46 01 07 e1 9b 46 02 1a 54 1a 01 00
004760   e1 9b 46 03 00 e0 2b 25 f5 74 24 00 4f 24 08 00
004770   a0 00 c5 0d 94 02 0d 1a 00 b0 02 00 00 00 00 04
004780   01 00 c1 70 67 02 00 e5 bf 00 95 02 8c ff f2 00
004790   03 00 00 00 00 00 00 e1 9b 2a 00 01 41 5b 55 45
0047a0   ad 87 b1 b2 14 c2 6c 8e 00 59 40 7f 04 1c 52 e9
0047b0   80 b9 56 01 02 02 74 47 02 00 50 00 02 03 74 47
0047c0   02 00 50 00 03 00 e0 2b 23 bd 03 00 00 b2 17 25
0047d0   48 a6 8b a5 bb 0d 76 00 0d 82 00 ab 82 00 03 00
0047e0   00 00 00 00 00 41 5b 55 45 ad 87 b1 b2 14 c2 6c
0047f0   22 6b 0a 24 01 03 94 5d 20 97 25 56 01 02 02 74
004800   47 02 00 50 00 02 03 74 47 02 00 50 00 03 00 e0
004810   2b 23 bd 03 00 00 b2 17 20 06 c6 03 86 78 01 44
004820   8e 00 59 6a 69 2a f8 64 d3 24 b2 14 c2 f4 a5 bb
004830   0d 76 00 0d 82 00 ab 82 03 00 00 00 00 00 00 41
004840   02 01 49 50 01 00 03 8c 00 06 50 01 04 03 49 03
004850   3f 03 a0 03 c0 54 03 c0 00 b8 0b 00 00 00 00 00
004860   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
004870   00 4f 74 00 08 a0 08 59 b2 14 c2 6c 27 70 d8 02
004880   74 03 6a 5c e0 06 c1 44 73 16 85 98 5d bb b1 35
004890   ff 08 00 6f 98 00 01 50 01 00 02 95 01 50 01 00
0048a0   00 57 00 40 03 63 94 03 80 3b 42 03 01 dd a0 94
0048b0   5a 4f 74 02 07 a0 07 cd e0 27 24 1c 01 01 00 61
0048c0   07 00 48 2d 05 01 8c 00 1c e0 27 24 1c 01 01 0b
0048d0   4f 74 02 00 61 0b 00 4d 41 03 02 6f 41 94 01 6b
0048e0   2d 06 01 04 02 01 00 3e a0 05 00 56 a0 06 00 52
0048f0   b2 14 c2 6c 66 0e 60 08 a3 78 8e 02 ea 22 8c 4d
004900   df 28 b2 14 c2 f4 a5 bb b1 43 03 01 52 e0 27 24
004910   1c 01 02 0b 4f 74 04 00 61 0b 00 3f c8 e0 2f 26
004920   54 01 00 b0 a0 03 49 54 01 02 01 8c ff 71 41 03
004930   01 49 54 01 04 01 8c ff 66 54 01 07 01 8c ff 5f
004940   a0 05 ed 50 05 02 0a 50 05 03 0b e0 27 24 1c 05
004950   01 00 e0 2a 26 5a 0a 0b 00 04 a0 04 d3 e1 a7 5e
004960   1d 01 e1 9b 5e 01 04 e0 2f 26 54 05 00 b8 a0 06
004970   ed 50 06 05 0a 50 06 06 0b e0 27 24 1c 06 02 00
004980   e0 2a 26 5a 0a 0b 00 04 a0 04 d3 e1 a7 2e 1d 01
004990   e1 9b 2e 01 04 e0 2f 26 54 06 00 b8 41 08 f7 5b
0049a0   b2 14 c2 6c 66 5b 4a 63 2e 0b 61 74 48 1a 78 71
0049b0   57 29 25 48 a6 8b a5 bb b1 41 83 1e c8 e0 3f 25
0049c0   20 00 b8 e0 2b 25 32 05 06 00 b2 14 c2 6c 9c 34
0049d0   d9 01 34 00 28 70 d3 64 01 b0 a5 4f 24 01 09 a0
0049e0   09 4a b2 65 51 c4 a5 8c 00 26 50 39 02 00 a0 00
0049f0   4b 4f 09 00 00 a7 00 8c 00 16 50 09 02 0b 50 09
004a00   03 00 e0 2b 23 bd 0b 00 00 e2 97 39 02 00 a0 06
004a10   cc e5 7f 20 e0 17 25 83 01 01 00 0d 82 01 a0 05
004a20   cc e0 27 24 1c 05 01 00 8c 00 09 e0 27 24 1c 06
004a30   02 00 e0 2f 25 eb 00 00 b2 16 a5 98 5d bb b1 00
004a40   00 b2 17 24 38 02 67 53 25 57 63 26 4d 25 50 04
004a50   71 a6 64 01 34 28 5d 4b 2a f7 3a 6c 03 34 16 a5
004a60   e4 a5 bb b1 03 00 00 00 00 ff ff a0 4d 47 e1 a7
004a70   53 1d 00 4f 39 00 00 e1 9b 70 00 00 50 39 02 00
004a80   e2 9b 70 02 00 50 39 03 00 e2 9b 70 03 00 05 03
004a90   09 ce 6f 74 03 00 e1 ab 24 03 00 8c ff f2 41 94
004aa0   02 5d e1 97 46 00 08 e1 97 46 01 09 e1 97 46 02
004ab0   08 e1 97 46 03 09 e0 2b 25 f5 74 24 00 42 94 01
004ac0   dd e1 97 46 00 06 e1 97 46 01 07 e1 97 46 02 06
004ad0   e1 97 46 03 07 e0 2b 25 f5 74 24 00 a0 01 d4 e0
004ae0   27 24 1c 01 01 00 e1 9b 24 02 00 e1 97 24 06 01
004af0   b0 a0 02 c0 e0 27 24 1c 02 02 00 e1 9b 24 04 00
004b00   e1 97 24 08 01 b0 04 00 00 00 00 00 00 00 00 a0
004b10   01 cd 4f 74 06 03 4f 74 07 04 8c 00 0a 4f 74 08
004b20   03 4f 74 09 04 e0 2a 25 97 03 04 02 00 b8 09 00
004b30   00 00 00 00 00 00 01 00 00 00 01 00 00 00 00 00
004b40   00 61 01 02 c1 4f 01 00 05 c1 8f 05 28 6f 48 b2
004b50   84 65 8c 00 0e a0 04 c8 0d 04 00 8c 00 05 e5 7f
004b60   20 c1 83 05 28 68 28 6f 48 0d 04 01 8c 00 61 c1
004b70   8f 05 30 48 4f b2 7a 9a 5f 0a c5 65 0d 07 01 8c
004b80   00 4e c1 8f 05 2e b2 4b e6 bf 80 0d 07 01 8c 00
004b90   3f a0 06 cb a0 07 48 a0 03 c5 b2 84 05 a0 82 45
004ba0   a0 4d c7 a7 05 8c 00 25 c1 8f 05 2e dc 50 e0 2f
004bb0   3d 38 8a 00 a0 00 c7 aa 8a 8c 00 11 50 01 02 09
004bc0   50 01 03 00 e0 2b 23 bd 09 00 00 0d 06 00 54 01
004bd0   04 01 8c ff 6e 00 02 00 00 00 00 a0 01 c0 e5 7f
004be0   20 e0 2f 26 41 01 02 a7 02 b0 06 00 00 00 00 00
004bf0   00 00 00 00 00 00 00 4f 46 00 00 6f 01 00 04 4f
004c00   46 01 00 6f 01 00 05 4f 46 02 06 6f 53 1d 00 56
004c10   00 02 00 54 00 02 00 74 53 00 00 e1 ab 02 06 00
004c20   61 04 05 5c 4f 46 03 06 6f 53 1d 00 56 00 02 00
004c30   54 00 02 00 74 53 00 00 e1 ab 02 06 00 b0 a0 03
004c40   d0 4f 04 00 00 61 2c 00 48 e0 2f 26 30 03 00 4f
004c50   04 00 00 e0 2f 26 30 00 00 54 04 04 04 8c ff c2
004c60   02 00 00 00 00 6f 53 1d 00 54 00 02 02 55 02 01
004c70   00 e1 ab 53 00 01 e1 a7 53 02 00 e1 ab 53 1d 02
004c80   b0 00 03 00 00 00 00 00 00 4f 95 00 00 56 00 02
004c90   03 25 02 03 c0 6f 95 02 00 61 00 01 3f f5 55 02
004ca0   01 00 6f 95 00 00 b8 00 01 00 00 2d 55 01 50 01
004cb0   01 5b ab 5b 04 00 00 00 00 00 00 00 00 41 01 18
004cc0   44 9b 1b 2d 4e 01 2d 1c 02 e1 a7 69 1d 00 e0 27
004cd0   27 99 69 00 00 a0 00 80 4f 0d 4e 00 6f 69 1d 00
004ce0   41 00 01 40 4f 69 01 04 e5 7f 5b a0 03 f2 a0 13
004cf0   6f e0 2f 26 41 03 03 a7 03 c1 8f 03 31 28 45 b2
004d00   82 8b e5 7f 20 41 04 04 4c b2 04 8d 1a 69 e0 a5
004d10   8c 00 07 b2 84 05 aa 04 e5 7f 5d bb ab 04 aa 04
004d20   e5 7f 5d bb ab 04 0d 4e 00 b1 03 00 00 00 00 00
004d30   00 e1 a7 14 1d 00 4f 74 08 02 a0 02 d5 50 55 06
004d40   1c 4f 74 09 00 e0 2a 26 ee 02 00 2e 00 a0 00 c0
004d50   4f 74 06 01 a0 01 d5 50 55 03 1c 4f 74 07 00 e0
004d60   2a 26 ee 01 00 5e 00 a0 00 c0 6f 14 1d 00 a0 00
004d70   c1 6f 5e 1d 03 a0 01 c8 e0 2f 26 ca 5e 5e a0 02
004d80   c1 a0 01 ca 6f 5e 1d 00 61 03 00 41 e0 2f 26 ca
004d90   2e 2e b0 00 07 00 00 00 00 00 00 00 01 00 00 00
004da0   00 00 00 6f 01 1d 02 e1 a7 69 1d 00 04 02 00 e0
004db0   6f 01 04 06 e0 2b 2a 18 06 14 00 a0 00 4d 54 05
004dc0   01 00 e1 ab 69 00 06 95 05 95 04 8c ff e0 e1 ab
004dd0   69 1d 05 2d 07 69 2d 69 01 ab 07 00 09 00 00 00
004de0   00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0d
004df0   61 00 41 78 01 45 0d 09 01 0d 78 00 e1 a7 03 1d
004e00   00 4f 01 00 07 61 01 02 5e a0 04 c8 e8 bf 04 8c
004e10   00 05 e8 bf 03 e0 2f 27 99 00 06 a0 09 44 ab 06
004e20   0d 78 01 ab 06 54 01 04 00 61 02 00 48 0d 08 00
004e30   8c 00 06 4f 01 02 08 c1 8f 07 28 d1 53 0d 78 01
004e40   c1 8f 08 30 e2 00 de 54 01 04 01 8c 00 d7 c1 83
004e50   07 2a 8a 2c 82 62 a0 04 c8 e8 bf 04 8c 00 05 e8
004e60   bf 03 e0 2f 27 99 00 00 a0 00 c0 2d 04 14 e1 a7
004e70   04 1d 00 8c 00 af c1 83 07 28 99 31 05 73 a0 3f
004e80   53 0d 78 02 c1 8f 08 30 e2 00 9a 54 01 04 01 8c
004e90   00 93 2d 25 62 a0 04 c8 e8 bf 04 8c 00 05 e8 bf
004ea0   03 e0 2f 27 99 00 00 a0 00 c0 a0 08 00 77 b0 c1
004eb0   83 07 28 ed 28 6f 64 c1 83 08 28 ed 28 6f dc 0d
004ec0   61 01 a0 04 c8 e8 bf 04 8c 00 05 e8 bf 03 e0 2f
004ed0   27 99 00 00 a0 00 00 4d b1 e0 27 21 4c 07 04 00
004ee0   a0 00 00 41 c1 83 07 28 ed 28 6f f9 c1 8f 07 30
004ef0   e2 4b a0 78 70 0d 78 04 8c 00 2a e0 25 21 4c 07
004f00   20 02 06 a0 06 ce a0 3f 4b 2d 3f 06 2d 85 07 8c
004f10   00 13 e0 25 21 4c 07 80 00 00 a0 00 c8 2d 25 07
004f20   2d 62 07 61 01 02 be df 54 01 04 01 2d 07 08 8c
004f30   fe d5 09 00 00 00 01 00 00 00 00 00 00 00 00 00
004f40   00 00 00 00 00 2d 05 1c 6f 01 1d 06 47 78 04 c1
004f50   a0 25 56 a0 3f d3 e0 25 21 4c 85 80 00 00 a0 00
004f60   c8 2d 25 85 0d 3f 00 a0 25 52 a0 3f 4f 41 78 01
004f70   cb a0 4e 48 a0 02 c0 ad 37 b1 41 78 01 45 a0 1c
004f80   47 cd 4f 1c ff ff 2d 77 01 a0 07 cb e0 2f 28 9a
004f90   01 00 8c 00 1b a0 36 d0 0c 1e 08 e0 25 29 01 10
004fa0   10 20 00 0b 1e 08 e0 15 29 01 1e 80 40 00 6f 01
004fb0   1d 00 75 00 06 04 47 78 01 80 ac 47 78 02 73 a0
004fc0   04 f0 41 04 01 e4 e7 bf 04 00 6f 01 00 00 e1 9b
004fd0   01 01 00 b2 14 c2 6c 70 0a c1 80 a5 4f 01 01 00
004fe0   aa 00 b2 16 a5 98 5d bb e1 a7 01 1d 01 8c 00 77
004ff0   43 04 01 cd a0 04 00 6f c1 8f 1c ff ff 80 68 c1
005000   8f 1c ff ff 58 2d 1c 05 2d 08 04 6f 01 1d 00 75
005010   00 04 00 e1 ab 01 1d 00 8c ff 70 a0 04 45 2d 04
005020   08 41 83 1e c8 e0 3f 25 20 00 b1 a0 02 ed a0 25
005030   ea e0 2a 28 57 06 04 01 00 61 01 5e 48 0d 1a 06
005040   8c 00 05 0d 1a 08 2d 59 3f 2d 2c 25 e0 17 25 32
005050   00 00 00 0d 82 01 8c 00 07 a0 02 c4 ad 37 0d 25
005060   00 0d 3f 00 b1 a0 04 75 a0 07 f2 a0 02 e8 2d 1c
005070   05 a0 36 46 41 5b 54 5c e0 1b 29 4f 82 01 00 2d
005080   28 25 2d 56 3f 2d 3a 85 0d 25 00 0d 3f 00 0d 85
005090   00 b0 ad 49 0d 25 00 0d 3f 00 b1 a0 04 48 0d 07
0050a0   01 8c fe e7 2d 1c 05 0d 25 00 0d 3f 00 b0 05 00
0050b0   00 00 00 00 00 00 00 00 00 2d 05 02 b2 14 c2 6c
0050c0   9c 35 c8 b4 05 a0 82 48 a0 4d 45 a0 61 dd a0 25
0050d0   c8 e8 bf 25 8c 00 0f a0 3f c8 e8 bf 85 8c 00 06
0050e0   e8 3f 31 05 a7 00 8c 00 15 61 03 5e c8 e8 7f 00
0050f0   8c 00 05 e8 7f 01 e0 2f 25 83 00 00 b2 01 34 00
005100   28 49 46 cc 23 95 01 6f 03 01 04 b2 84 05 aa 04
005110   41 02 02 51 41 05 02 c5 e5 7f 2c b2 02 97 80 a5
005120   8c 00 09 43 02 02 45 b2 84 65 04 02 01 3f d8 b3
005130   16 a5 98 5d 08 00 00 00 00 00 00 00 00 00 00 00
005140   00 00 00 00 00 6f 01 1d 02 2d 07 1c 52 10 0c 03
005150   a0 03 e3 a4 03 00 55 00 01 04 70 03 05 06 e0 2b
005160   2a 72 06 01 00 a0 00 c9 e0 2b 29 4f 06 01 00 25
005170   05 04 3f e8 52 10 08 03 a0 03 80 56 a4 03 00 57
005180   00 04 00 55 00 01 04 0d 05 00 56 05 02 00 6f 03
005190   00 00 61 25 00 77 56 05 02 00 54 00 01 00 6f 03
0051a0   00 00 e3 5b b3 12 00 12 b3 12 00 55 00 05 08 4f
0051b0   25 00 00 e1 9b 08 00 00 4f 25 01 00 e1 9b 08 01
0051c0   00 e0 1b 29 4f b3 01 00 8c 00 07 25 05 04 3f bc
0051d0   6f 01 1d 00 61 00 02 40 cd 4f 1c ff ff 2d 77 01
0051e0   e0 15 29 01 2d 01 01 00 2d 1c 07 6f 01 1d 00 a0
0051f0   00 40 c1 95 5b 2f 56 2e 40 e0 15 29 01 1b 01 01
005200   00 b8 04 00 00 00 00 00 00 00 00 74 02 03 00 67
005210   1c 00 4b e0 29 29 1b 01 77 01 00 b8 67 1c 02 4b
005220   e0 29 29 1b 01 77 00 00 b8 67 1c 03 41 e0 29 29
005230   1b 01 77 02 00 b8 05 00 00 00 00 00 00 00 00 00
005240   00 a2 01 01 40 41 03 02 da 52 01 11 00 a0 00 d3
005250   e0 2b 2a 72 01 02 00 a0 00 c9 e0 2b 29 4f 01 02
005260   00 a0 03 4a 4a 01 09 c6 4a 01 0c 6d a2 01 05 69
005270   4a 01 0a c6 4a 01 08 61 4a 01 0c 48 e8 7f 01 8c
005280   00 0f 4a 01 09 48 e8 7f 01 8c 00 05 e8 7f 00 e0
005290   2a 29 1b 01 02 00 04 a1 01 01 bf ab b0 00 03 00
0052a0   00 00 00 00 00 6f 02 1d 03 54 03 01 00 e1 ab 02
0052b0   00 01 54 03 01 00 e1 ab 02 1d 00 b0 01 00 00 50
0052c0   55 00 00 57 00 40 01 43 01 00 41 50 55 03 00 e0
0052d0   2b 29 75 5e 00 00 a0 00 c0 43 01 01 41 50 55 06
0052e0   00 e0 2b 29 75 2e 00 00 b8 00 05 00 00 00 00 00
0052f0   00 00 00 00 00 6f 01 1d 03 a0 03 c1 47 02 02 c6
005300   47 02 08 41 04 03 00 c1 54 03 01 00 6f 01 00 04
005310   41 04 30 51 e0 2f 3d 38 8a 00 a0 00 45 ad 32 b1
005320   2d 04 8a e0 2f 3d 69 04 00 a0 00 3f d9 c1 97 04
005330   04 0d bf d2 2d 4b 04 4a 04 0b 48 0d 05 01 8c 00
005340   23 41 83 1e c8 0d 05 00 8c 00 19 47 02 08 52 e0
005350   1f 39 94 00 00 41 00 01 48 0d 05 00 8c 00 05 0d
005360   05 01 a0 05 e4 47 02 02 60 41 83 1e 5c 41 04 82
005370   4b ad 60 b2 09 25 d0 a5 bb b1 2d 8a 04 ad 60 b2
005380   84 05 aa 04 ad 17 b1 a0 05 3f 7b 41 83 1e 3f 76
005390   b2 14 c2 6c 99 1a 0a 4c a6 8b a5 bb 8c ff 67 00
0053a0   03 00 00 00 00 00 00 6f 5e 1d 00 43 00 01 50 50
0053b0   55 03 00 47 00 04 c8 0d 01 01 8c 00 15 6f 2e 1d
0053c0   00 43 00 01 4d 50 55 06 00 47 00 04 c5 0d 01 02
0053d0   a0 01 c1 e5 7f 5b ad 50 b2 6b 0a 02 5a 47 2e 56
0053e0   2a 80 a5 41 01 02 45 b2 ba 65 b2 25 d7 29 19 02
0053f0   87 3d 48 67 00 05 65 e4 a5 4f 74 01 02 a0 02 4a
005400   b2 65 51 c4 a5 8c 00 20 a0 82 45 a0 4d cb 4f 02
005410   00 00 a7 00 8c 00 11 50 02 02 03 50 02 03 00 e0
005420   2b 23 bd 03 00 00 b2 17 25 48 a6 8b a5 bb b1 00
005430   04 00 00 00 00 ff ff 00 01 a0 02 c0 42 03 00 c8
005440   0d 04 00 8c 00 06 4f 02 00 03 6f 02 04 00 61 01
005450   00 4b 56 04 02 00 74 02 00 00 b8 25 04 03 3f ec
005460   b1 00 04 00 00 00 00 00 00 00 00 70 02 04 00 61
005470   01 00 c1 25 04 03 3f f5 b1 00 04 00 00 00 01 00
005480   00 00 00 a0 68 c6 41 83 1e c1 0d 4e 13 2d 03 10
005490   2d 10 01 a0 02 cc 4a 01 13 48 0d 04 01 8c 00 3e
0054a0   e1 a7 69 1d 00 2d 77 69 cd 4f 1c ff ff 61 03 01
0054b0   5a e0 25 29 01 83 01 01 00 41 83 1e ce 26 1e 01
0054c0   4a e0 15 29 01 1e 01 01 00 e0 25 29 01 01 01 01
0054d0   00 6f 77 1d 00 43 00 00 45 0d 04 01 2d 10 03 0d
0054e0   4e 00 ab 04 04 00 00 00 00 00 00 00 00 4a 01 0e
0054f0   c0 a0 25 dc 52 01 11 03 a4 03 00 57 00 02 00 55
005500   00 01 00 e0 2a 2a 18 25 03 00 00 a0 00 c0 a0 3f
005510   db 52 01 10 03 a0 03 c0 a4 03 00 55 00 01 00 e0
005520   2a 2a 31 3f 03 00 00 a0 00 c0 a0 4e c1 6a 01 4e
005530   c1 b1 00 0d 30 02 b3 12 46 75 d2 6a 40 6d 57 1e
005540   98 3b 3e 96 45 00 00 0d 30 01 b3 10 f7 39 4b 01
005550   2a 61 17 3a b9 3a 93 e0 b2 00 00 0d 30 00 b3 13
005560   1a 55 57 1e ee 29 60 25 58 22 ee 57 2e 52 78 96
005570   45 00 02 00 00 00 00 11 1e 0f 01 b2 04 41 b4 a5
005580   41 01 06 52 b2 06 d5 2a eb 29 19 01 aa 1a 39 b4
005590   a5 8c 00 39 41 01 05 52 b2 62 2e 31 b9 47 c0 72
0055a0   9a 4d 2a a4 a5 8c 00 25 c1 97 01 03 04 52 b2 62
0055b0   92 2b 8d 1b 20 72 9a 4d 2a a4 a5 8c 00 0f b2 61
0055c0   57 3a 9a 62 3e 03 94 6a 69 a9 25 41 01 06 ee b2
0055d0   04 62 43 8e 46 20 09 08 6a ea 24 06 2f 2a dc 05
0055e0   35 05 01 00 56 00 0a 00 74 00 6d 02 e6 bf 02 b2
0055f0   02 54 ed 45 41 02 01 c5 e5 7f 73 a0 6b e0 b2 05
005600   41 08 33 1d 4a 4c 10 3a 31 a9 20 41 6b 01 4a b2
005610   52 68 a8 a5 8c 00 07 b2 67 8e a1 45 ad 17 b0 00
005620   00 a2 83 00 49 e0 2f 36 8b 83 00 b8 b3 04 41 35
005630   52 57 3e 17 8d 1a 69 29 25 c8 a5 00 01 00 00 e0
005640   3f 2b b5 00 b2 14 e4 72 9a 45 20 05 11 3a 0a 00
005650   2c 5d 58 64 d7 64 01 48 20 1d 4c 3a 73 3a 6c 04
005660   77 2b 19 52 ea 00 c0 60 db 29 20 56 98 3b 2e 52
005670   61 0e 97 01 53 24 02 4b 0a 63 0e 0b 61 24 20 30
005680   d2 28 b5 14 e5 78 99 7a aa 00 97 11 44 60 99 10
005690   c4 5c 99 04 64 5c 8a 13 04 64 94 12 e4 28 23 52
0056a0   e0 12 c4 68 8e 13 25 7c bd 14 e0 14 c1 f8 a5 e4
0056b0   af 67 47 4f 47 01 01 c1 8f 01 32 94 48 b7 ad 54
0056c0   8c ff 83 c1 8f 01 32 9b 52 b6 4b b2 12 90 96 45
0056d0   bb 8c ff 72 ad 54 8c ff 6d c1 83 01 32 24 32 16
0056e0   3f 64 ba 8c ff 60 00 e0 0f 2b 82 61 14 00 a0 00
0056f0   c0 ba b0 00 00 e0 0f 2b 82 64 9e 00 a0 00 c0 b7
005700   ad 54 b0 00 01 00 00 e0 3f 2b b5 00 bb b2 11 34
005710   00 28 71 d8 34 01 b0 a5 ad 01 b2 16 a0 17 c4 78
005720   01 14 cb 2d d7 48 d9 3b 6a 17 e5 f4 05 e0 3f 2b
005730   9e 00 a0 00 41 b2 12 90 96 45 bb b1 00 e5 7f 3e
005740   e4 af 67 47 4f 47 01 00 c1 83 00 36 f4 36 d8 c1
005750   b1 00 00 b6 47 b3 12 90 96 45 ad 54 b0 00 00 b5
005760   47 b3 12 90 96 45 ad 54 b0 00 00 b2 08 38 22 97
005770   28 01 94 a5 e6 bf 11 b2 00 be 05 25 2c ad 15 00
005780   56 8e 4f 38 17 e1 8c 36 e6 bf 12 b2 02 54 ed 45
005790   41 12 01 c5 e5 7f 73 b2 05 41 3d 8e 6d 58 00 28
0057a0   04 17 1a 70 80 29 c1 8f 11 01 5e 4c b2 12 46 63
0057b0   2a dc a5 8c 00 35 43 11 fa 4c b2 13 0a 4d d4 dc
0057c0   a5 8c 00 27 43 11 96 4c b2 11 fa 4d d4 dc a5 8c
0057d0   00 19 43 11 4b 4c b2 12 74 6d c8 a8 a5 8c 00 0b
0057e0   b2 10 ea 31 d3 4d d3 b0 a5 b3 00 86 27 6a 4f 3a
0057f0   5d 57 96 45 02 00 00 00 00 51 01 09 02 43 02 00
005800   40 74 11 02 11 e3 97 01 09 00 b0 00 00 0f 00 08
005810   00 48 00 01 00 e1 5b 00 08 00 e0 0f 2c 1d 5a 32
005820   00 b8 00 e0 0f 2c 1d 64 8a 00 0f 00 08 00 c9 8f
005830   00 ff fe 00 e1 5b 00 08 00 b0 01 00 00 b2 11 aa
005840   dd 40 ad 01 b2 60 06 03 37 1a 78 22 ee 57 20 05
005850   2e 4f 2a 5c d9 38 5b 71 d9 b4 a5 bb e0 3f 2c 31
005860   00 b8 01 00 11 b2 12 44 38 93 11 c5 70 9f 12 84
005870   5c 90 00 8e 97 a0 ad 4c bb b2 11 14 57 d7 39 8d
005880   64 05 79 05 7c 05 24 b1 16 05 40 04 3a 6b 51 14
005890   48 23 11 d3 20 2a 10 d1 44 17 39 8d 67 00 5d 58
0058a0   2a fb 29 25 48 a7 13 e4 50 97 12 00 04 a6 02 ea
0058b0   31 d8 65 57 29 20 66 e6 25 52 1a f0 00 29 11 d3
0058c0   2e 88 52 41 0c 8e 4d 05 48 a7 12 ea 45 46 e1 40
0058d0   0f 00 01 00 c9 8f 00 07 ff 00 e6 bf 00 b2 00 ba
0058e0   00 98 2a ee 1a 20 4f 52 1d 57 80 a5 05 01 17 cc
0058f0   30 00 01 00 e5 bf 00 8c ff f4 bb b0 00 b2 13 6a
005900   5d cb 79 d3 30 b2 16 45 c8 a5 bb bd 4b b3 11 14
005910   5e ea 23 25 c8 a5 bb b2 14 c1 28 a6 05 45 98 2a
005920   ad 54 b0 00 00 f4 7f 01 b0 00 00 41 4b 87 d3 b3
005930   10 e6 24 08 1a 31 00 2c 16 e4 5c 93 11 25 c8 a5
005940   35 00 80 00 e7 bf 00 00 b0 00 00 f3 7f 04 b0 00
005950   00 f3 3f ff fc b0 00 b2 84 25 aa 4b b3 00 45 62
005960   2a 2a ae 4d 85 c8 a5 00 00 4a 4b 1e d2 b2 11 6e
005970   31 b9 3a 6c 80 c0 aa 4b b3 16 85 d4 b4 a0 8e c6
005980   41 8e 04 4a e0 0f 2c d5 60 8c 00 b8 66 8e 83 cc
005990   ad 60 b2 84 05 aa 8e ad 17 b0 4a 8e 1d c8 e0 3f
0059a0   2c d5 00 b8 e0 3f 40 de 00 b8 01 00 00 b2 13 37
0059b0   79 d3 30 01 30 d9 64 c8 40 06 80 a5 aa 4b b2 80
0059c0   2b a0 01 c7 ad 01 8c 00 07 b2 98 05 aa 8e b3 00
0059d0   25 63 4e 21 c9 1a 25 c8 a5 00 00 41 4b 8f 5f 66
0059e0   4b 10 d3 b2 84 25 aa 4b b2 00 45 0b 61 00 55 96
0059f0   85 bb 9b 02 06 1e 8f 40 ad 73 9b 02 c1 97 4b 03
005a00   7c 4a e0 1b 1d 3a 5b 4b 00 b0 b2 04 41 4c c0 65
005a10   aa 52 fe 00 5b 36 9c 00 2c 1e 86 5d 20 98 05 aa
005a20   4b b2 04 75 2a ed 1a b8 96 a5 bb 9b 02 00 01 00
005a30   00 b2 04 41 34 7f 06 c1 80 a5 aa 4b ad 17 6e 83
005a40   4b 51 4b 12 00 e0 9f 00 02 00 b0 00 00 e0 19 1d
005a50   3a 16 4b 6d 00 b8 00 a0 8e 53 b3 04 49 39 33 17
005a60   19 03 06 78 01 2f 8d 1b 25 d0 a5 4a 8e 19 46 4a
005a70   8e 13 c0 b2 0e 46 80 a5 aa 8e b3 16 a5 54 b4 96
005a80   a5 00 00 4a 4b 1a 00 61 66 4b 83 c6 66 83 4b 7d
005a90   b2 84 25 aa 4b b2 01 06 65 0d 2b 00 2d d7 28 2a
005aa0   13 53 2e 97 67 53 1b 2a 47 c1 0c 28 71 57 a8 05
005ab0   66 83 4b 48 b2 ba 65 8c 00 09 b2 36 91 25 d3 b0
005ac0   a5 e0 0f 37 52 64 f4 00 8c 00 17 b2 84 25 aa 4b
005ad0   b2 00 25 22 93 63 52 29 20 1f c0 2d d7 a8 b2 bb
005ae0   e0 2f 3d 84 4b 00 b8 ad 50 b2 1f 57 4c 06 80 a5
005af0   aa 4b ad 17 b0 00 00 41 4b ad 59 b3 11 11 3a 47
005b00   3a 6c 00 20 70 d1 47 00 04 a1 32 74 00 db 19 d1
005b10   96 45 c1 95 4b 4c 00 1b c6 4a 4b 17 49 e0 1f 3a
005b20   e3 17 00 b8 ad 50 b3 26 80 09 25 c8 a5 00 00 c1
005b30   95 4b 4c 00 1b c6 4a 4b 17 49 e0 1f 3a e3 16 00
005b40   b8 ad 50 b3 26 80 09 25 c8 a5 00 ad 50 b2 22 2e
005b50   48 e0 52 61 b0 20 aa 4b ad 17 b0 00 00 4a 4b 12
005b60   e0 4a 4b 16 dc b2 04 52 6b 19 03 2a 46 20 49 40
005b70   36 9c 00 2c 26 80 06 21 b0 c0 aa 4b ad 17 b0 4a
005b80   4b 0c e1 51 4b 0b 00 a0 00 da 4a 4b 0a 53 4c 4b
005b90   0a b2 11 11 53 0a a4 b2 bb e0 3f 3d 8d 00 b8 ad
005ba0   73 b0 4a 4b 16 58 4a 4b 0a 51 4c 4b 0a b2 84 25
005bb0   aa 4b b3 00 25 0f e1 ec b2 ad 73 b0 b3 04 42 3d
005bc0   11 53 0a 00 49 96 45 00 00 b3 04 41 4e 34 63 20
005bd0   04 92 3a 69 96 45 00 ad 50 b3 22 f4 63 00 09 25
005be0   d0 a5 00 b3 13 1a 21 a0 44 d3 33 46 31 40 06 c6
005bf0   01 ae 31 a5 71 11 1b 18 01 58 64 c7 45 d8 36 4a
005c00   4f 20 45 d0 28 19 35 d8 96 85 00 4a 4b 1e 4b e0
005c10   1a 1d 3a 14 4b 8e 00 b8 4a 4b 1a 00 63 4a 8e 1d
005c20   00 5e 66 83 4b 5f b3 12 74 64 06 00 f7 39 8d 64
005c30   0e 25 46 04 78 3a 68 28 1e 53 45 62 ea 00 36 3b
005c40   25 c8 a5 b2 08 38 41 d1 45 7a c4 05 aa 8e b2 62
005c50   46 4f 0d 3a a0 62 2e 21 58 80 20 aa 4b b2 00 3f
005c60   3a 73 6a 4a 5c c7 45 40 62 2e 6d 57 60 01 60 f1
005c70   53 80 1b 86 f8 b2 bb e0 2f 3d 84 4b 00 b8 4a 8e
005c80   1d e4 b2 04 25 65 1a 67 2e 4d 80 29 2c 28 b9 00
005c90   29 98 05 aa 8e b3 00 25 34 d7 26 3e 00 c9 2a da
005ca0   1b 2a 96 45 b2 13 19 5c d3 31 40 22 93 21 55 64
005cb0   23 23 59 65 d3 30 01 80 a5 aa 4b b3 16 45 c8 b2
005cc0   00 b3 11 14 49 40 52 61 0e 74 f0 b4 00 a0 8e 45
005cd0   0d 8e 04 41 8e 5b 55 b3 0b d3 50 17 28 d8 0b 61
005ce0   30 48 25 cc 31 d3 30 01 d4 b2 4a 8e 1c 5e b2 11
005cf0   2e 31 8e 4d 80 05 61 80 a5 aa 8e b3 00 25 62 34
005d00   70 01 1b 2a 25 d4 6b 05 c8 a5 b2 11 2e 31 8e 4d
005d10   80 05 66 80 a5 aa 8e b3 00 25 61 d1 47 c5 c8 a5
005d20   00 e0 3f 2e a9 00 b8 00 00 b3 0e 15 29 1a 45 c6
005d30   dc b4 00 26 1e 4b 40 e0 1b 1d 3a 2d 4b 00 b0 00
005d40   00 e0 3f 3a 16 00 a0 00 c0 b3 11 37 52 b5 29 25
005d50   c8 a5 01 00 00 4a 4b 14 69 e0 2f 3d 69 4b 00 a0
005d60   00 49 ad 60 b3 09 25 c8 a5 41 5b 27 4f b3 0e 03
005d70   10 28 26 ee 4e 00 09 25 d4 a5 e0 3f 2e f9 00 b8
005d80   4a 4b 15 00 55 a3 4b 01 46 4b 2d cf e0 1f 3d 1b
005d90   03 00 a0 00 46 41 4b b3 48 e0 3f 2e f9 00 b8 e0
005da0   2f 3d 38 01 00 a0 00 d0 66 01 83 cc ad 60 b2 84
005db0   05 aa 01 ad 17 b0 4a 01 0a da b2 13 d4 68 b8 46
005dc0   20 06 61 32 95 2a 60 84 05 aa 01 b3 01 6e 5f 19
005dd0   96 45 e0 3f 2e f9 00 b8 b2 06 fa 4e 2e 41 51 78
005de0   01 c4 20 aa 4b b3 00 71 19 97 29 40 05 7e 53 45
005df0   c8 a5 00 41 4b 7c 51 e0 1f 3d 1b 03 00 a0 00 48
005e00   e0 2f 3d 84 4b 00 b3 0c d7 28 d1 47 c0 35 d9 00
005e10   20 62 b4 e4 b2 00 00 e0 1f 3a e3 15 00 b8 00 51
005e20   4b 07 00 a0 00 ca 51 4b 07 00 ad 00 bb b0 4a 4b
005e30   12 c6 4a 4b 16 4c 41 4b af c8 e0 3f 31 0b 00 b8
005e40   ad 63 b2 62 aa 21 c6 44 02 d8 20 aa 4b ad 17 b0
005e50   00 c1 97 4b 1b 00 49 06 1e 8f 45 0d 4b 8f a0 4b
005e60   49 e0 1f 3a e3 14 00 b8 26 1e 4b c5 ad 73 b0 4a
005e70   10 07 54 6e 83 10 b3 04 41 34 5b 04 94 72 60 0c
005e80   06 30 ce cc b2 b2 11 8a 67 2e 4d 80 53 59 00 35
005e90   00 71 09 0b 1b 26 c4 b2 bb 9b 02 00 00 b3 13 8d
005ea0   1b 20 18 07 3b e6 5e ea 01 14 4d 0a 57 25 d0 a5
005eb0   00 a0 8e 67 e0 1f 3d 1b 03 00 a0 00 cb e0 19 1d
005ec0   3a 31 4b 03 00 b0 a3 83 00 26 7c 00 4b e0 19 1d
005ed0   3a 31 4b 7c 00 b0 ad 8d b0 c1 97 8e 03 7c c0 e0
005ee0   1a 1d 3a 13 8e 4b 00 b0 00 b3 04 52 1b c0 40 7f
005ef0   36 9c 00 2c 26 80 09 21 0c 50 11 c0 26 93 17 19
005f00   96 45 01 00 00 a3 4b 01 c1 97 4b 6d 04 5b b3 13
005f10   8e 65 a1 5b 0e 74 03 00 29 04 8d 28 c9 04 6d 52
005f20   aa 2f 51 47 c5 c8 a5 41 4b 0d 55 b3 07 c6 5e 9a
005f30   4d 20 06 a0 62 92 2b 81 54 b2 16 45 c8 a5 41 01
005f40   2d 4b b3 04 4b 3a 69 01 d9 96 45 66 4b 83 49 b3
005f50   04 41 4d d9 96 45 66 4b 10 cf e0 2f 3d 1b 4b 00
005f60   a0 00 46 41 4b b3 4b b3 06 f7 39 8d 64 01 d4 b2
005f70   4a 01 1e 4e b2 84 25 aa 01 b3 00 6b 3b 25 c8 a5
005f80   4a 01 0c 4c b2 06 e2 ec 20 aa 01 ad 17 b0 4a 01
005f90   12 4c b2 06 e1 d8 20 aa 01 ad 17 b0 b3 10 ea 1b
005fa0   38 02 4a 96 45 00 00 b3 07 d3 6b 38 96 85 00 e0
005fb0   2f 3d 69 4b 00 a0 00 40 b2 13 2d 1b 25 63 00 28
005fc0   d8 78 02 28 28 05 98 1b c0 61 d3 21 40 05 02 65
005fd0   5b 2a 60 06 61 80 a5 aa 4b ad 17 b0 00 4a 8e 1e
005fe0   d7 ad 50 b2 31 db 28 06 80 a5 aa 4b b2 00 2c 98
005ff0   05 aa 8e b3 96 85 b2 84 25 aa 8e b3 02 ea 2f 58
006000   2b 00 3b 20 56 91 3b 2a 47 c5 c8 a5 00 b3 10 ee
006010   7c d7 5d 45 d0 a5 00 a0 4b 80 40 4a 4b 1e 5a b2
006020   84 25 aa 4b b3 00 f4 73 00 0b ed 28 c9 00 36 32
006030   ea 2b 2e 4d 85 c8 a5 b2 12 93 47 c0 61 0d 3b f4
006040   55 b7 2a 6e 23 00 60 de 00 b9 11 aa 46 34 17 20
006050   05 86 80 a5 aa 4b ad 17 b0 b3 11 94 51 20 24 de
006060   96 45 00 b3 0e 03 10 28 3a 6b 44 d9 28 02 a4 b5
006070   00 e0 0f 3e 0a 5e a2 00 b8 00 00 b3 11 c5 61 20
006080   62 94 4d 57 02 0e 63 00 18 15 39 85 c8 a5 00 4a
006090   4b 16 4f b3 12 74 1e 89 78 b8 60 0d 52 4a 96 45
0060a0   b2 13 8d 78 10 4e 88 40 02 ec c0 aa 4b b3 96 a5
0060b0   00 4a 4b 1f 65 4a 4b 13 c9 b3 06 e2 0e 8b ac b2
0060c0   4c 4b 13 b2 84 25 aa 4b b2 00 25 0f f4 2d 65 c8
0060d0   a5 bb e0 3f 3d 8d 00 b8 ad 50 b3 67 57 4c 01 46
0060e0   8b ac b2 00 00 4a 4b 1f 6f 4a 4b 13 4b b3 08 c1
0060f0   14 43 52 65 c8 a5 4b 4b 13 b2 84 25 aa 4b b2 00
006100   25 0f f4 cc b2 bb a0 36 40 e0 2f 2a 3d 10 36 bb
006110   e0 3f 30 fa 00 b8 4a 4b 1a 5c b2 11 cb 00 28 71
006120   d8 34 01 30 fa 5e 60 84 05 aa 4b b3 04 78 1b c0
006130   62 85 c8 a5 ad 50 b3 67 57 4c 01 46 93 96 45 00
006140   00 b3 13 2d 1b 25 63 00 56 ea 67 3e 03 8a 3a e9
006150   96 45 02 00 00 00 00 a0 4b e9 4a 4b 1e 58 b2 84
006160   25 aa 4b b3 00 25 0d 47 39 80 05 8f 6a 55 02 9b
006170   2a e5 c8 a5 66 4b 10 48 e0 3f 33 84 00 b8 ad 89
006180   b0 52 10 16 01 a0 01 80 42 a4 01 02 41 02 02 d0
006190   41 02 04 71 50 01 01 00 ae 00 00 a0 00 67 b2 05
0061a0   fc 1b 00 0a 26 03 6a 5f c0 60 cb 28 15 44 c8 28
0061b0   01 33 37 78 0f 6a 55 3a 6c 85 45 e0 0f 37 52 5c
0061c0   b2 00 b8 e0 3f 33 84 00 b8 e0 3f 33 84 00 b8 00
0061d0   00 b2 84 25 aa 4b b3 02 46 41 58 02 74 03 14 6a
0061e0   69 96 45 00 00 b2 91 d9 e0 2f 1b c5 8b 00 ad 00
0061f0   ad 17 b0 00 00 e0 1f 35 c7 01 00 a0 00 c0 e0 1f
006200   36 02 01 00 b8 00 00 ad 63 b2 1d 4d 3a 69 80 20
006210   aa 4b ad 17 b0 00 00 4a 4b 16 6b 4a 4b 0a 5b b3
006220   06 f4 55 53 04 62 40 28 07 b8 29 40 71 a6 64 b8
006230   60 07 2b d4 4d 25 c8 a5 b2 84 25 aa 4b b3 00 25
006240   07 65 c8 a5 4a 4b 12 00 45 4a 4b 1e 51 ad 63 b3
006250   62 aa 21 c6 44 01 30 48 61 4a cc b2 e0 2f 37 4a
006260   4b 00 a0 00 dd a2 4b 00 4b e0 2f 36 8b 4b 00 a0
006270   00 41 b2 84 25 aa 4b b3 00 25 2a 55 67 c5 c8 a5
006280   b2 84 25 aa 4b b3 00 25 07 65 c8 a5 ad 50 b2 46
006290   94 40 0e 4f 0e 25 40 98 05 aa 4b ad 17 b0 00 ad
0062a0   63 b3 0a 09 6b 19 03 21 d4 b2 00 e0 0f 3e 0a 60
0062b0   c7 00 b8 00 00 ad 50 b3 26 80 09 25 c8 a5 00 e0
0062c0   2f 3d 69 4b 00 a0 00 c0 b3 12 54 6d 49 96 45 00
0062d0   00 4a 4b 11 5a b2 12 54 6d d3 30 01 80 a5 aa 4b
0062e0   b3 02 ea 6d 46 47 00 4e 99 35 d3 b0 b2 ad 50 b2
0062f0   4a 9b 28 01 80 a5 aa 4b ad 17 b0 00 00 a0 8e c6
006300   4a 8e 1d c0 b2 13 37 79 d3 30 01 31 2a 63 37 53
006310   c0 84 05 aa 4b b2 80 2b a0 8e 4e b2 04 87 05 ad
006320   1a 69 e0 a5 8c 00 07 b2 98 05 aa 8e b3 00 25 2f
006330   59 3a 2a 96 45 00 00 4a 4b 1e 4a e0 1b 1d 3a 14
006340   4b 00 b0 b3 12 6e 21 40 66 fe 96 45 00 41 10 38
006350   00 56 26 89 10 00 51 a0 16 00 4d e0 0f 1d a5 57
006360   0c 00 e1 97 00 00 00 0d 16 01 0d 5c 01 99 89 b3
006370   04 23 0c 23 35 46 5d d3 30 01 02 66 49 40 05 22
006380   7d 66 65 aa 5c b8 60 09 28 c9 47 c0 4d 52 2b 0e
006390   60 23 2e 2a 2b 00 1f c0 22 e6 61 ae 4d 80 06 81
0063a0   00 61 70 d1 c4 b2 b3 13 86 62 65 63 20 35 40 18
0063b0   18 19 d1 52 e5 d4 a5 00 02 00 00 00 00 4a 4b 12
0063c0   00 70 4a 4b 0c 80 6b 51 4b 0b 00 a0 00 80 63 4a
0063d0   4b 0a 4b b3 08 c1 14 43 52 aa cc b2 4b 4b 0a 4b
0063e0   4b 0d a2 4b 00 46 4a 4b 08 49 b3 12 95 2a 6a a4
0063f0   b2 a2 4b 01 62 a1 01 00 de 4a 01 0d da 51 01 0a
006400   02 a0 02 d3 b2 84 25 aa 4b b2 02 95 2a 78 96 45
006410   bb ad 02 bb b0 b2 12 95 2a 6e 4d 80 84 05 aa 4b
006420   b2 02 ea 6d 46 c7 00 e0 2f 36 63 4b 00 ad 17 b0
006430   4a 4b 16 60 4a 4b 0a 4b b3 08 c1 14 43 52 aa cc
006440   b2 b2 84 25 aa 4b b2 02 95 2a 78 96 45 bb 4b 4b
006450   0a b0 b2 04 52 6b 19 03 2a 46 20 49 40 36 9c 00
006460   2c 26 80 06 21 b0 c0 aa 4b ad 17 b0 00 ad 50 b3
006470   55 c8 40 02 a4 b2 00 41 4b 7c 00 55 4a 8e 19 62
006480   4a 8e 13 5e b2 84 25 aa 8e b2 00 25 2b b9 3a 6c
006490   69 d8 35 49 96 45 bb 4c 8e 13 4c 8e 19 8c 00 25
0064a0   b2 04 22 2f 15 3a 31 60 14 6d 57 80 20 aa 8e b2
0064b0   04 61 30 20 2e 34 52 e1 0c 26 2b 66 56 97 1b 2a
0064c0   e0 b2 bb e0 2f 3d 84 4b 00 e0 3f 3d 8d 00 b8 ad
0064d0   50 b3 56 9a 5c 02 a4 b2 00 41 10 18 50 74 11 3c
0064e0   11 0d 3c 00 e0 1f 3a 4e 72 00 b8 b3 11 cb 00 28
0064f0   56 e6 78 0a 4e 9a 31 a1 0c 24 56 e6 79 57 60 12
006500   1b c0 09 06 4f 1c 2a ea a4 b2 00 a0 8e d2 41 8e
006510   4d ce b2 0e 46 80 a5 aa 8e b3 16 85 d4 b4 26 4d
006520   83 4b e0 19 1d 3a 16 4b 4d 00 b8 b3 06 e2 45 11
006530   28 d7 01 b4 f0 b2 00 e0 0f 3e 0a 5d 2e 00 b8 00
006540   00 c1 97 4b 03 7c c0 e0 3f 2f d7 00 b8 00 03 00
006550   00 00 00 00 00 4a 8e 0a d7 4a 8e 16 d3 4a 8e 12
006560   cf 4a 8e 1b cb ad 50 b3 26 80 09 25 c8 a5 4a 8e
006570   0a d1 2d 8a 8e b2 84 25 aa 8e b3 00 45 52 aa cc
006580   b2 61 8e 4b 4d b3 0e 03 10 28 26 80 09 25 d4 a5
006590   66 4b 8e 45 ad 73 b0 e0 2f 3a 3c 8e 03 e0 2f 3a
0065a0   3c 4b 00 74 03 00 02 51 8e 0d 00 75 02 00 01 51
0065b0   8e 0b 00 63 01 00 4b b3 0b d3 50 17 52 92 96 45
0065c0   e0 2f 3d 69 4b 00 a0 00 50 4a 4b 0b 4c ad 60 b2
0065d0   84 05 aa 4b ad 17 b0 e0 2f 3d 69 4b 00 a0 00 4a
0065e0   e0 3f 39 94 00 a0 00 c1 6e 4b 8e 4b 4b 0d e0 2f
0065f0   2b fa 4b 00 b3 11 34 4d 45 c8 a5 00 00 41 8e 81
006600   4a e0 1b 1d 3a 29 4b 00 b0 4a 8e 0c 48 e0 3f 32
006610   a7 00 b8 b2 0b d3 50 0c 52 89 03 1a 5d 66 21 40
006620   0b 61 80 a5 aa 8e ad 17 b0 00 00 e0 3f 31 55 00
006630   b8 00 00 a0 36 40 ad 49 b0 00 00 4a 4b 10 4a 51
006640   4b 07 00 ad 00 bb b0 b2 0e 09 51 58 00 7e 5d 46
006650   24 06 80 a5 aa 4b b3 96 a5 00 00 e0 1b 1d 3a 4f
006660   4b 00 b0 00 00 b3 08 c8 53 51 24 1b 2a fe 03 8a
006670   46 20 09 03 2a 26 65 45 d0 a5 00 b3 11 b4 70 23
006680   2b a6 23 31 78 23 0c 81 22 ee 4d 80 09 25 d4 a5
006690   00 e0 0f 3e 0a 61 ce 00 b8 00 01 00 00 a0 2d 4b
0066a0   b3 13 06 78 1c 34 d9 96 a5 0d 76 00 e0 27 3d 29
0066b0   10 1e 01 a0 01 df b2 04 52 6b 19 00 c9 26 ea 63
0066c0   00 84 05 aa 01 b2 01 2e 5d 48 66 3e 96 45 bb 0d
0066d0   2d 00 b0 6f 47 2d 00 c1 8f 00 2e 03 c1 0d 2d 00
0066e0   ad 93 b0 00 00 b3 04 4b 3a 69 02 74 65 ae 4d 80
0066f0   6a 7a 63 46 c4 b2 00 e0 1a 1d 3a 34 8e 4b 00 b0
006700   00 b3 13 0d 1a 0a cc b2 00 b3 13 8d 29 4a 29 4a
006710   29 4a 28 b4 16 85 50 b4 96 85 00 b2 08 d8 49 51
006720   47 00 45 d0 28 06 80 a5 aa 4b ad 17 b0 00 01 00
006730   00 e0 17 3d 29 1e 1d 01 a0 01 cb e0 1a 1d 3a 14
006740   4b 01 00 b0 b2 11 34 00 28 56 f4 56 98 28 01 33
006750   19 18 e0 84 05 aa 4b b3 00 2b 04 95 3a 70 f8 b5
006760   00 4a 4b 1e 73 b3 04 46 5d 53 17 19 03 6a 5f 0a
006770   24 01 59 a6 4d 25 73 34 17 8d 04 c8 52 47 1b 25
006780   18 3b 03 d4 68 b8 24 07 2b 39 2a e0 6b 0a 00 c0
006790   71 46 56 93 96 45 e0 1b 1d 3a 12 4b 00 b0 00 b2
0067a0   13 1c 3a 52 3a 6c 00 45 1a 31 53 8a 24 01 d8 20
0067b0   a0 4b cd c1 97 4b 03 7c c7 aa 4b b3 96 45 b3 27
0067c0   53 31 54 cc b2 00 00 a0 8e 49 b3 13 8d 52 98 b4
0067d0   b4 e0 1a 1d 3a 14 8e 4b 00 b8 00 66 4b 83 45 ad
0067e0   79 b0 a3 4b 00 4a 00 12 60 a3 4b 00 4a 00 0a d9
0067f0   ad 50 b3 5d 46 21 a0 3a 78 39 2a 00 c0 07 60 22
006800   93 64 ce 4d 57 96 45 a0 8e e6 41 8e 81 46 0d 8e
006810   00 b1 a3 4b 00 61 8e 00 d3 b2 84 25 aa 4b b2 00
006820   45 06 c1 80 a5 aa 8e ad 17 b0 0d 8e 00 b1 26 1e
006830   4b 40 b3 07 c1 59 d9 96 85 00 00 e0 3f 39 94 00
006840   41 00 01 40 b3 13 26 41 53 96 45 00 00 4a 4b 1e
006850   69 a0 2d ca 2d 83 4b a3 83 10 ab 10 b2 84 25 aa
006860   4b b3 03 1a 31 8a 63 38 00 31 05 17 2a ea 19 20
006870   04 92 1a 7a 1a 25 c8 a5 ad 50 b2 64 d1 40 01 b0
006880   20 aa 4b e5 7f 21 bb 0d 76 00 0d 2d 00 9b 02 00
006890   01 00 00 4a 4b 16 52 e0 2f 3d 71 4b 01 a0 01 c9
0068a0   e0 2f 3a e3 01 00 b8 4a 4b 1b 4a e0 1b 1d 3a 18
0068b0   4b 00 b0 4a 4b 11 e2 b2 04 4d 3b 20 04 8d 28 c9
0068c0   00 7a 84 05 aa 4b b3 00 d8 00 28 1b 39 2a 55 64
0068d0   02 49 6a 1b 25 c8 a5 66 4b 83 59 b3 0c c3 45 d3
0068e0   6e 91 6d 40 5b 4e 65 40 18 08 52 79 52 f9 3a 93
0068f0   96 85 e0 2f 1b c5 7b 00 ad 00 bb b0 00 e0 3f 3a
006900   16 00 a0 00 80 ac 41 8e 0d 00 74 b2 84 25 aa 4b
006910   b2 01 14 4e 18 00 28 06 c1 01 aa 19 21 28 93 52
006920   f2 1a 31 78 23 0a 5c 53 51 26 65 63 20 26 80 4b
006930   48 34 09 1a 46 31 41 0c 50 05 0b 1a 31 02 9b 2a
006940   e0 1c c8 43 86 5d 38 03 37 79 d3 30 01 31 3a 22
006950   00 04 c7 5d 46 40 01 12 6a 22 01 0d fa 63 2e 21
006960   40 1d 4e 4d 80 63 8e 2f 20 04 d2 2a e8 39 7a 44
006970   01 d8 a5 ad 4c e0 0f 37 52 65 83 00 b8 a0 8e eb
006980   4a 8e 1e 67 b2 84 25 aa 8e b2 01 3a 22 18 00 d8
006990   80 20 aa 4b b3 01 71 39 58 00 fe 00 26 22 e6 61
0069a0   aa 60 01 30 20 0a a5 c8 a5 b3 13 2d 5e 9c cc b2
0069b0   b3 11 ba b4 b5 00 00 ad 50 b3 65 b7 53 80 1a 7e
0069c0   65 ae 4d 80 51 6b 00 29 09 25 d0 a5 00 61 8e 83
0069d0   57 ad 50 b3 65 ca 00 d3 7b 2d 3a 6c 00 2c 7a 9a
0069e0   5f 0a 45 65 c8 a5 ad 50 b2 65 ca 80 20 aa 4b b3
0069f0   00 2c 09 25 c8 a5 00 b2 0e 46 80 a5 aa 8e b3 16
006a00   85 d4 b4 00 00 c1 97 8e 1b 00 5d 41 4b 4b d9 b3
006a10   08 27 05 ad 1a 69 60 02 64 d5 55 46 5c 01 30 48
006a20   2a 74 69 8d 96 45 4a 4b 0f c0 ad 50 b3 67 57 4c
006a30   02 a4 b4 00 00 b3 05 e3 2e 74 01 4b 2d 48 e4 b2
006a40   00 e0 3f 30 f2 00 b8 00 00 b3 05 e2 3c 48 65 ca
006a50   24 23 62 80 3b 20 09 e2 23 53 65 ca a4 b4 01 00
006a60   03 b2 13 2e 49 40 54 d8 61 58 16 45 c8 b2 bb 04
006a70   01 00 cb e0 3f 1d c4 00 a0 00 bf f5 0d 22 01 ab
006a80   22 00 05 00 00 00 00 00 00 00 00 00 00 a0 2b 48
006a90   e0 3f 35 a9 00 b8 72 10 4b 01 a0 01 80 97 a4 01
006aa0   02 41 02 01 4d 50 01 00 00 e0 2f 3a 4e 00 00 b8
006ab0   41 02 02 4b 4f 01 00 00 ad 00 bb 9b 02 41 02 03
006ac0   56 4f 01 00 00 e0 bf 00 05 a0 05 c9 e0 2f 3a 4e
006ad0   05 00 b8 9b 02 41 02 04 67 50 01 01 00 ae 00 00
006ae0   a0 00 cd 50 01 00 00 e0 2f 3a 4e 00 00 b8 4f 01
006af0   01 03 a0 03 c7 ad 03 bb 9b 02 ad 34 9b 02 41 02
006b00   05 40 50 01 01 04 4a 04 0a 4d 50 01 00 00 e0 2f
006b10   3a 4e 00 00 b8 4f 01 01 03 a0 03 c7 ad 03 bb 9b
006b20   02 b2 84 25 aa 04 b2 00 25 07 65 c8 a5 bb 2d 8a
006b30   04 9b 02 a0 36 5a e7 7f 64 00 23 50 00 52 41 83
006b40   1e 4e 4a 10 03 ca e0 0f 37 52 59 35 00 b8 ad 34
006b50   9b 02 00 b3 13 58 28 08 52 55 1b 18 01 2e 5d 48
006b60   65 d4 4f 00 09 52 53 6a 49 53 e4 b2 00 e0 0f 3e
006b70   0a 60 ce 00 b8 00 00 b3 10 c6 1a f7 5d 8c 31 ad
006b80   b4 b4 00 b3 10 d9 00 24 61 57 6d c8 a8 b4 03 00
006b90   00 00 00 00 00 a0 01 46 41 30 02 45 0d 02 01 a0
006ba0   36 67 b2 08 c1 16 ae 65 0d 00 f1 19 10 05 41 08
006bb0   2d 45 d0 2a 3e 00 2c 09 0a 1b 2a 4c 07 78 06 01
006bc0   97 69 45 c8 a5 bb b1 4a 10 0d cb 4b 10 0d 0d 02
006bd0   01 8c 00 09 4a 10 02 45 0d 02 01 aa 10 06 1e 8f
006be0   49 b2 04 61 d8 20 9a 8f bb a0 02 c1 51 10 0e 03
006bf0   a0 03 c7 ad 03 8c 00 0b 51 10 12 00 e0 9f 00 03
006c00   00 bb b0 00 01 00 00 a0 36 e9 a2 10 00 40 a0 01
006c10   c8 2d 01 01 8c 00 12 41 30 02 c8 e8 7f 00 8c 00
006c20   05 e8 7f 01 2d 01 00 e0 28 36 8b 10 01 ff ff 00
006c30   b8 ad 49 b0 05 00 00 00 00 00 00 00 00 00 00 2d
006c40   35 01 a0 03 4e 51 01 06 00 e0 9f 00 05 00 a0 00
006c50   41 a0 03 59 4a 01 0d c9 51 01 0a 04 a0 04 49 51
006c60   01 0e 04 a0 04 c7 ad 04 8c 00 46 a0 03 65 b2 04
006c70   e1 94 c0 aa 01 b2 80 35 4a 01 13 51 b2 00 be 56
006c80   f4 6d c9 3a 6c 02 2e 31 b9 97 e5 e5 7f 2e 8c 00
006c90   20 6f 7f 03 00 ad 00 b2 87 85 aa 01 4a 01 13 51
006ca0   b2 00 be 56 f4 6d c9 3a 6c 02 2e 31 b9 97 e5 bb
006cb0   e0 2f 37 4a 01 00 a0 00 c0 a2 01 00 40 e0 2a 36
006cc0   8b 01 02 03 00 b8 06 00 00 00 00 00 00 00 01 00
006cd0   00 00 00 a2 01 02 40 a1 02 03 c2 a0 04 c8 0d 04
006ce0   00 8c 00 0b b2 84 65 a0 03 45 b2 84 c5 b2 98 05
006cf0   aa 02 a0 05 4b a0 06 48 2d 05 02 8c 00 08 0d 06
006d00   01 0d 05 00 2d 02 03 a0 02 3f ce a0 05 c1 a0 06
006d10   41 2d 8a 05 b0 00 0a 00 00 00 00 00 00 00 00 00
006d20   00 00 00 00 00 00 00 00 00 00 00 a2 01 04 41 06
006d30   1e 8f 45 a3 83 07 0d 05 01 0d 06 01 a3 01 00 c1
006d40   ab 83 01 00 68 0d 0a 01 a2 01 04 c2 a0 04 00 77
006d50   a0 09 d3 a0 07 d0 a2 07 00 4c 95 03 e0 2a 36 8b
006d60   07 02 03 00 a0 05 c1 a0 06 40 b0 a0 04 bf db 61
006d70   04 07 48 0d 09 01 8c 00 46 61 04 83 80 41 4a 04
006d80   0e 80 3c 4a 04 0d f8 51 04 0a 08 a0 08 f1 4a 04
006d90   06 c8 ad 08 bb 0d 06 00 e0 2f 37 4a 04 00 a0 00
006da0   de a3 04 00 51 00 06 00 a0 00 54 a2 04 00 50 e0
006db0   29 36 8b 04 02 00 00 a0 00 c5 0d 05 00 a1 04 04
006dc0   bf ab 8c ff a8 c1 a7 04 07 1e 80 5e 4a 04 0e 80
006dd0   59 a0 0a 4e 4a 04 0d ca 51 04 0a 00 a0 00 00 4a
006de0   4a 04 06 ed a0 05 d8 e0 2b 37 18 01 03 00 a0 00
006df0   c9 42 03 00 45 0d 03 00 95 03 0d 05 00 42 03 00
006e00   45 0d 03 00 e0 2a 36 1a 04 02 03 00 8c 00 1b a2
006e10   04 00 57 e0 2f 37 4a 04 00 a0 00 ce 95 03 e0 2a
006e20   36 8b 04 02 03 00 96 03 a1 04 04 bf 21 8c ff 1e
006e30   02 00 00 00 00 41 01 88 4d b3 08 23 6d d3 22 3a
006e40   25 45 f4 a5 61 01 83 49 b3 04 4d 1b 6a 97 a5 46
006e50   01 1b c0 43 02 00 48 6f 7f 02 00 ad 00 4a 01 0c
006e60   54 b2 13 0e 67 2e 4d 80 0b 61 80 a5 aa 01 b3 01
006e70   d8 97 a5 4a 01 1e 50 b2 84 25 aa 01 b3 00 25 36
006e80   91 25 d3 b0 bd b2 84 25 aa 01 b3 01 14 4f 26 3a
006e90   78 97 a5 00 01 00 00 4a 01 0e c0 4a 01 08 c1 4a
006ea0   01 0a c1 b1 01 00 00 0d 83 1e ad 01 a0 27 4f b2
006eb0   00 87 19 20 47 48 40 23 37 4d 96 a5 bb a0 68 ed
006ec0   b2 14 e4 22 93 32 e6 67 51 1b 2e 52 78 05 41 5c
006ed0   51 28 d8 78 01 30 48 41 d1 45 49 03 8d 3a 2a 00
006ee0   43 25 46 a4 b2 bb e0 3f 2b 1e 00 55 11 0a 11 b2
006ef0   00 a7 00 00 00 a6 05 45 18 2a 14 c1 28 a6 05 40
006f00   00 22 06 69 39 49 00 05 18 2a 14 c1 28 a6 05 45
006f10   18 2a 00 a7 94 e5 6e 83 10 42 6b 02 80 4c b2 04
006f20   48 45 46 5e 3e 00 2d 18 18 69 c8 39 26 44 12 1a
006f30   6e 19 01 28 41 5d 52 19 d3 60 1c 3a 31 00 48 57
006f40   59 00 36 11 a6 25 58 00 4a 04 8b 2a 31 53 80 19
006f50   3b 2a 79 6a ea 5f 00 05 8c 46 86 64 14 6d 57 96
006f60   45 bb e0 3f 2b 1e 00 b8 95 6b 6e 83 10 0a 18 0d
006f70   00 a1 b2 04 4b 29 51 02 ea 45 ca 6d 49 00 29 04
006f80   87 6a e9 2a 78 00 26 2d d3 24 1e 53 57 61 51 2c
006f90   07 29 74 5d 40 04 0c 1b 2a 60 01 24 8d aa 31 a0
006fa0   91 5b b2 04 7c 06 a0 04 18 55 d7 3b 38 01 ea 2a
006fb0   e0 04 c9 2a 7e 00 28 2a 79 df c5 b2 05 42 07 0a
006fc0   4f 0a 60 01 35 2e 63 3a 5c ea 24 2a 12 87 3d 48
006fd0   67 00 1a f4 6a 69 00 28 1a b5 28 d7 01 d3 25 d8
006fe0   65 d3 23 21 0c f1 28 c8 35 49 00 29 22 91 52 e1
006ff0   0d 5b 2a 60 6a 77 28 d1 96 45 bb bb 0d 68 01 0d
007000   20 01 e3 93 83 12 38 86 e0 1f 3a 4e 1d 00 8c 00
007010   48 b2 13 8a 46 21 0c 28 0c e9 2b 0a 5f 6a 00 d3
007020   53 2d 2a e0 21 a6 4d 0a 05 44 38 01 76 da 3b 2a
007030   01 6e 74 01 23 55 01 14 4a b1 2b 2a 47 c1 0c 50
007040   05 01 74 33 2b 6a 5f d9 35 d3 b0 b2 bb bb 0c ae
007050   0d e0 1f 3a 4e 72 00 0d 2d 00 e0 3f 38 33 00 e0
007060   3f 38 5f 00 9b 02 03 00 00 00 00 00 00 92 1b 01
007070   c2 26 66 83 45 0e 66 35 26 78 83 45 0e 78 6b a2
007080   83 03 c2 2d 02 03 a0 02 c1 a1 02 03 c2 4a 02 04
007090   60 4a 01 07 54 4a 01 13 d0 e7 7f 64 00 23 32 00
0070a0   48 6e 02 01 8c ff de a1 01 01 bf e7 8c ff e4 e7
0070b0   7f 07 00 6f 5a 00 00 6e 02 00 8c ff c8 00 00 e0
0070c0   0f 1d a5 50 0e 00 e1 97 00 00 00 e0 0f 1d a5 50
0070d0   3d 00 e1 97 00 00 00 e0 0f 1d a5 57 0c 00 e1 97
0070e0   00 00 00 e0 0f 1d a5 47 92 00 e1 97 00 00 00 e0
0070f0   0f 1d a5 4e 50 00 e1 97 00 00 00 e0 0f 1d a5 4a
007100   7a 00 e1 97 00 00 00 0c 0c 13 b0 00 02 00 00 00
007110   00 41 5b 66 5b 41 10 8b 40 41 4b 1d 40 b3 04 29
007120   5c cb 64 07 46 9c 60 01 20 e6 22 05 c8 a5 c1 95
007130   5b 02 00 01 c0 c1 95 5b 07 08 0c c0 c1 97 5b 06
007140   05 c0 c1 95 5b 64 24 14 c6 41 5b 5c 57 b3 10 d9
007150   64 c8 43 00 05 bb 18 36 06 c1 11 14 4d 2e 65 d4
007160   cc b2 c1 95 5b 2b 1e 25 d6 c1 95 5b 23 16 27 cf
007170   c1 95 5b 5f 19 46 c8 c1 97 5b 53 62 5d b3 13 1a
007180   21 a0 19 19 38 5b 04 a7 2b d4 4d 20 04 88 1a a6
007190   1d d1 3b 2e 2b 05 c8 a5 41 5b 63 5f b3 12 4e 31
0071a0   b9 00 d8 03 8a 46 21 28 9e 53 45 63 6a 01 94 64
0071b0   03 25 59 2a f3 3b 3e 96 45 41 5b 12 57 b3 04 53
0071c0   29 49 02 74 02 2e 31 b9 00 2c 33 4e 25 40 7a 9a
0071d0   96 45 41 5b 09 59 b3 07 c9 28 c9 16 80 0e 03 10
0071e0   28 65 ae 4e 00 05 21 13 08 52 ea 96 a5 c1 97 5b
0071f0   53 49 4f b3 08 2d 04 d5 1b 18 2b 00 06 8e e4 b2
007200   c1 95 5b 04 5d 29 51 b3 04 41 4e 74 02 b4 63 0a
007210   63 0e 52 78 96 45 41 5b 03 4b b3 04 41 35 2a 19
007220   25 c8 a5 41 5b 40 00 5c b2 04 21 6a 34 52 18 03
007230   53 28 d7 65 b1 f8 a5 a2 10 00 c8 e5 7f 2e 8c 00
007240   17 b2 00 26 50 ef 29 19 60 06 56 aa 1a e0 3a 69
007250   3b 19 3a 68 e4 b2 4a 10 13 e7 b2 00 86 47 2d 53
007260   4c 34 19 06 a0 04 b3 50 11 39 8d 64 23 04 01 68
007270   54 25 d2 47 c0 3a 31 6a 4e 4c d9 29 25 c8 a5 bb
007280   bb b1 41 5b 4b 00 92 41 10 18 00 7e 0c 66 0e e3
007290   97 83 12 00 0d 68 00 06 67 57 45 0d 20 00 b2 04
0072a0   38 53 53 24 01 24 c0 25 d8 64 d3 64 19 5f 52 55
0072b0   59 00 25 35 46 5d 21 28 22 2d d3 24 1e 53 57 61
0072c0   51 2c 01 58 20 72 94 27 01 0e ee 61 d3 30 06 60
0072d0   0e 2c 01 48 c0 46 93 30 18 45 4a 54 2a 07 87 5d
0072e0   4a 7d 40 5f 58 66 2a 60 01 03 37 29 59 52 b8 14
0072f0   c1 6c 19 35 53 04 66 46 20 04 b8 65 d1 c4 b2 bb
007300   bb e0 1f 3a 4e 72 00 b8 b3 08 35 5c de 2a f8 00
007310   2d 0a 2d 28 d7 a4 b2 ad 50 b2 2b 6a 4c 09 50 02
007320   a4 b2 bb 0d 2d 00 9b 02 05 00 01 00 00 00 00 00
007330   00 00 00 11 1e 0f 00 35 06 00 00 56 00 0a 00 35
007340   64 00 04 a0 68 d4 a0 01 c0 b2 08 2d 04 d5 1b 18
007350   2b 00 06 8e e4 b2 bb b1 4a 4b 11 cf a0 01 c0 e0
007360   2f 1b c5 7b 00 ad 00 bb b1 41 10 aa 62 26 70 10
007370   5e 4a 4b 04 5a a0 01 c0 b2 04 22 1d 34 2b 13 17
007380   19 02 2a 64 01 22 6a 1a e5 c8 a5 bb b1 a3 4b 00
007390   4a 00 12 49 a3 4b 00 4a 00 0a 40 a3 4b 00 66 00
0073a0   83 80 47 e0 2f 3a 3c 4b 05 e0 2f 3a 3c 83 00 74
0073b0   05 00 00 63 00 04 73 a0 01 ee b2 08 31 50 c9 00
0073c0   25 0d 4d 28 db f8 a5 42 04 64 5b b2 04 6a 62 aa
0073d0   21 c6 46 3e 00 36 45 cc 37 20 05 21 11 14 4d 2e
0073e0   65 d4 cc a5 ad 17 9b 02 41 5b 49 71 e0 2f 3a 31
0073f0   83 02 43 02 07 67 56 02 08 05 e7 7f 64 00 63 05
007400   00 5b b2 07 cd 52 29 3a 6c 00 6a 48 d3 78 19 35
007410   d3 33 00 1a 37 28 c9 f8 b4 bb b1 6e 4b 83 4c 4b
007420   06 4b 4b 0d e0 2f 2b fa 4b 00 b0 00 00 66 4b 83
007430   d3 a3 4b 00 66 00 83 cc ad 60 b2 84 05 aa 4b ad
007440   17 b1 66 4b 83 d7 a3 4b 00 4a 00 0a d0 b2 84 25
007450   aa 4b b2 00 25 07 65 c8 a5 bb b1 a3 83 00 6e 4b
007460   00 b0 03 00 00 00 00 00 00 a2 01 03 c4 ab 02 95
007470   02 a1 03 03 bf fb ab 02 03 00 00 00 00 00 00 a2
007480   01 02 51 e0 2f 3a 3c 02 00 74 03 00 03 a1 02 02
007490   bf f3 51 01 0d 00 74 03 00 00 b8 00 05 00 00 00
0074a0   01 00 00 00 00 00 00 a3 83 03 2d 04 36 2d 05 10
0074b0   4a 01 03 5b 06 1e 8f d7 ad 50 b2 32 80 64 35 03
0074c0   8e 65 b4 6b 20 18 07 50 d9 96 45 bb b1 4a 01 07
0074d0   67 4a 10 07 63 06 1e 8f 5f b2 13 d4 68 b8 46 20
0074e0   06 61 31 8a 64 14 6b 20 05 21 02 e6 2f 20 2d d7
0074f0   63 25 c8 a5 bb b1 06 1e 8f 67 4a 10 07 e3 4a 01
007500   07 5f a0 68 5c b2 84 25 aa 03 b2 01 14 49 58 00
007510   2c 18 17 2b 19 00 5b 04 18 36 97 a8 b2 bb bb 06
007520   1e 8f 48 6e 03 01 8c 00 05 6e 83 01 2d 10 01 e0
007530   2f 2a 3d 10 36 a0 04 00 3d a0 36 7a e7 7f 64 00
007540   23 50 00 72 b2 12 8d 04 73 50 b4 00 3c 0e ac 5f
007550   4a 03 11 3b 21 55 20 07 e1 80 a5 06 1e 8f 4a a3
007560   83 00 aa 00 8c 00 07 b2 5e 94 c8 a5 e0 0f 37 52
007570   59 e8 00 b0 a0 36 5d 41 83 1e 59 b2 04 41 4e 54
007580   6d 49 00 3f 18 09 1a f0 02 b1 19 0a 96 45 bb 0d
007590   2d 00 51 10 12 00 e0 9f 00 02 00 e0 2f 2b fa 01
0075a0   00 61 10 01 41 61 10 05 46 41 10 1d c1 a0 02 c1
0075b0   41 83 1e 41 e0 3f 35 c7 00 a0 00 c1 43 30 00 41
0075c0   e0 3f 36 02 00 b0 01 00 00 2d 2b 01 e0 1b 1d 3a
0075d0   66 01 00 b0 03 00 00 00 01 00 00 41 4b 82 59 41
0075e0   8e 82 55 b3 13 2d 53 0a 03 2d 3a 6c 60 06 5d 53
0075f0   17 19 00 35 96 85 41 4b 82 48 2d 01 5e 8c 00 08
007600   2d 01 2e 0d 02 00 0d 2d 00 0d 76 00 41 83 1e 56
007610   ad 50 b2 61 4a 00 d3 f8 05 e0 2f 3b 26 02 00 b3
007620   00 35 96 85 b2 84 25 aa 83 b2 00 54 22 93 2f 58
007630   29 21 28 b9 11 c0 0b 38 29 40 1a 7e 80 a5 e0 2f
007640   3b 26 02 00 b3 00 35 16 85 e4 a5 00 02 00 00 00
007650   00 a0 82 cd a0 56 c4 a7 3a a0 28 c0 a7 28 b0 a0
007660   01 d3 4f 74 06 02 4f 74 07 00 e0 29 25 97 02 00
007670   00 00 b8 4f 74 08 02 4f 74 09 00 e0 29 25 97 02
007680   00 00 00 b8 00 41 5b 1d 40 b3 13 55 16 a0 11 34
007690   72 65 d4 a5 00 41 5b 54 5b 0d 2d 00 0d 76 00 ad
0076a0   50 b3 64 d1 40 01 30 20 60 ce 46 97 00 31 70 de
0076b0   96 45 41 5b 2e 53 b3 04 e1 16 74 03 06 3a 34 5c
0076c0   01 30 48 61 4a cc b2 41 5b 37 40 95 88 58 88 0c
0076d0   00 a0 00 59 b3 04 58 29 52 00 2c 09 17 2a aa 1b
0076e0   2e 4d 80 7a 9a 5f 0a 45 65 c8 a5 b3 12 74 65 ae
0076f0   4d 80 34 d5 55 53 60 01 d4 b2 00 c1 97 5b 2a 13
007700   4e 41 8e 81 4a e0 1b 1d 3a 29 4b 00 b0 41 10 6a
007710   48 e0 3f 50 70 00 b8 41 5b 26 40 b2 04 22 54 01
007720   94 6a 41 10 40 4a b2 4b 49 a7 c5 8c 00 07 b2 34
007730   d7 a4 a5 b3 00 35 96 45 00 41 5b 2e 00 69 b3 04
007740   2c 5f 4a 00 25 18 18 3a 6e 63 2a 5c 23 0e b5 5d
007750   58 2a 68 28 01 58 20 24 d7 40 15 44 c8 2b 00 05
007760   21 01 46 5f 2d 05 44 3b 38 01 66 6e 97 3b 2a 01
007770   2e 2b 20 04 a6 27 6a 4f 3a 5d 57 60 23 0a 0e 67
007780   00 3a 78 1b 2e 18 f1 28 06 56 aa 65 d9 28 01 17
007790   2a 4a aa 5d 49 00 fe 01 d9 60 0b 28 d7 00 29 45
0077a0   cc 37 25 c8 a5 41 5b 32 40 b3 12 93 28 01 14 67
0077b0   0e a1 58 20 24 d7 40 13 28 d7 1f c1 28 89 52 65
0077c0   63 20 45 59 00 24 45 cc 37 20 32 80 53 59 96 85
0077d0   00 41 5b 54 4b 0d 2d 00 0d 76 00 ad 93 b0 41 5b
0077e0   34 4e 41 8e 0d 4a e0 1b 1d 3a 49 4b 00 b0 41 5b
0077f0   2b 59 b3 10 da 66 85 71 06 4e 6e 1c d1 3b 12 00
007800   25 0a 21 00 d3 63 8a dc b2 c1 97 5b 24 14 4e 41
007810   4b 0d 4a e0 0f 37 52 61 b2 00 b8 41 5b 49 4b b3
007820   0e 17 52 46 4f 2e a0 b4 41 5b 2e 40 c1 97 10 25
007830   97 59 b3 08 2e 48 cc 28 01 58 20 49 d7 5e 97 02
007840   34 52 18 03 2e 5d 49 96 45 b3 10 d7 28 01 11 5e
007850   2b 00 56 ea 35 53 61 d1 a8 b5 00 c1 97 5b 33 49
007860   48 e0 3f 35 a9 00 b8 41 5b 26 40 b3 12 74 64 06
007870   01 0d 1a 68 a8 b2 01 00 00 41 01 03 40 b2 04 41
007880   34 36 18 18 5b 41 34 3a 05 79 1a 31 01 0a 3a 2e
007890   4d 98 05 41 f0 a5 c1 a7 29 10 53 4e b2 25 52 52
0078a0   2e 61 aa a4 a5 8c 00 07 b2 37 4c a8 a5 b2 02 4e
0078b0   5e f4 5c 0b 3a 31 60 01 00 53 70 d1 44 2a 04 e1
0078c0   35 5d 3b 38 00 61 04 c3 3d 46 63 25 c8 a5 b0 00
0078d0   01 00 00 41 5b 53 00 4b a0 29 00 47 41 10 25 48
0078e0   0d 01 97 8c 00 05 0d 01 25 e0 25 3f 58 10 53 00
0078f0   00 e0 29 3f 58 01 10 00 00 e0 19 3f 58 53 01 00
007900   00 e0 27 3a 4e 01 00 00 b3 04 e1 14 c0 5f 52 1e
007910   2a 00 32 25 4a 54 1c 3b 2d 06 c1 01 46 5f 2d 96
007920   45 c1 97 5b 2e 2f 72 c1 a7 29 10 53 53 b3 04 32
007930   3a f7 52 e0 04 b8 34 d9 65 57 29 25 c8 a5 b3 10
007940   d3 03 4c 47 c0 55 57 60 5b 63 26 5d 58 00 e6 22
007950   00 1b 20 7a 9a 96 45 41 5b 49 4b e0 13 3d e3 53
007960   60 d2 00 b8 c1 95 5b 14 5d 24 40 c1 a7 29 10 53
007970   5b b3 13 d4 68 b8 6d 40 24 7e 2a 74 69 8d 01 26
007980   48 cc 28 06 46 ea 19 3e 96 45 a0 29 c8 0d 29 53
007990   8c 00 05 2d 29 10 0d 27 00 b3 04 32 3a f7 52 e0
0079a0   1e ea 1a 18 05 44 38 0d 52 aa 00 28 06 66 03 0a
0079b0   6d 53 03 ca 1a e0 63 55 56 3e 00 29 32 94 24 11
0079c0   69 10 01 a6 4d 3e 96 45 00 41 5b 2e 40 b2 04 28
0079d0   35 d2 4d 5e 80 4c 41 10 12 4a b2 26 9c cc a5 8c
0079e0   00 11 b2 6a a1 0c 26 46 94 43 00 22 2e 48 e6 9e
0079f0   2a ad 17 b0 03 00 00 00 00 00 00 a0 03 48 4c 01
007a00   13 4b 01 18 e0 2f 3d 69 01 00 a0 00 46 66 01 10
007a10   40 a0 03 5b b2 84 25 aa 01 b2 01 6e 7f f1 2b 00
007a20   04 c9 39 58 96 45 bb e0 3f 3d 8d 00 b8 4f 02 01
007a30   00 ad 00 bb b0 00 02 00 00 00 00 52 10 0c 02 a0
007a40   02 c0 a4 02 00 55 00 01 00 e0 2a 2a 31 01 02 00
007a50   00 b8 03 00 00 00 00 00 00 a2 01 03 c2 a0 03 c0
007a60   6a 03 02 48 41 03 1e c4 ab 03 a1 03 03 bf f3 b1
007a70   03 00 00 00 00 00 00 a3 01 02 4a 01 0e c0 a0 02
007a80   c0 41 02 2d c1 41 02 24 4b e0 2f 3d 1b 01 00 a0
007a90   00 41 e0 2f 3d 5d 01 03 a3 83 00 c1 ab 03 10 00
007aa0   40 a3 83 00 c1 aa 02 83 10 00 c1 4a 02 0a 40 e0
007ab0   2f 3d 38 02 00 a0 00 c0 b0 00 01 00 00 a0 01 c0
007ac0   46 01 2d 44 9b 2d 46 01 1b 44 ab 01 a3 01 01 8c
007ad0   ff ed 01 00 00 a3 01 01 a0 01 c0 61 01 83 3f f7
007ae0   b0 00 03 00 00 00 00 00 00 73 10 02 02 42 02 13
007af0   c0 72 10 02 03 a4 03 00 41 00 05 3f ee 50 03 01
007b00   00 61 00 01 3f e5 ab 02 01 00 00 61 01 8a 45 0d
007b10   8a 00 a9 01 e0 3f 3d 8d 00 b8 00 a0 36 c1 e0 2f
007b20   2a 3d 10 00 a0 00 41 0d 36 00 b3 08 c1 14 7f 55
007b30   d9 21 a0 1e 26 22 05 c8 a5 00 02 00 00 00 00 41
007b40   5b 1e 47 b3 08 ce e0 b4 c1 95 5b 25 2e 2f 4e b2
007b50   12 34 67 00 85 25 ad 02 ad 17 b0 41 5b 13 40 61
007b60   8e 01 40 b2 13 2d 2a 60 3b 20 72 9a 45 33 17 19
007b70   00 48 98 05 aa 01 b3 00 d3 7a 54 5d 45 d0 a5 00
007b80   02 00 00 00 00 b2 13 53 25 57 4d 46 65 a0 84 05
007b90   aa 01 b2 00 25 98 05 aa 02 b2 05 44 1b 00 05 17
007ba0   2a 2a 1b 0a 80 20 aa 01 b2 04 61 80 a5 aa 02 b3
007bb0   00 25 52 68 28 06 30 c1 59 14 4d 0a 1a 2a 24 01
007bc0   4b 6e 2b 85 c8 a5 02 00 00 00 00 b2 84 25 aa 01
007bd0   b2 00 25 61 48 6a ea 47 c0 2c d8 65 53 29 20 05
007be0   81 80 a5 ad 02 ad 17 b0 03 00 00 00 00 00 00 41
007bf0   5b 25 50 4a 01 0a 45 ad 73 b0 4b 01 0a ad 02 bb
007c00   b0 41 5b 1e 40 4a 01 0a 49 4c 01 0a ad 03 bb b0
007c10   ad 73 b0 00 01 00 00 ad 01 aa 4b e0 2f 1b c5 8b
007c20   00 ad 00 ad 17 b0 00 c1 97 5b 3e 54 5a 0d 2d 00
007c30   b3 04 22 1c 25 18 18 66 f4 4d 81 0f 0e 45 53 64
007c40   19 7a aa 96 45 41 5b 5d 70 4a 4b 1d 6c 6e 4b 10
007c50   b3 04 52 3b 18 29 20 35 d9 65 d3 30 01 03 2d 39
007c60   4b 04 62 40 28 63 48 29 49 29 20 06 c6 4d 8a 5d
007c70   d3 30 0d 3a 45 c8 a5 c1 97 5b 34 5d 00 50 41 8e
007c80   70 00 4b 4e 4b 70 b2 04 22 9c a5 4a 4b 04 61 b2
007c90   04 b9 1a 0a 4c 06 1c c8 40 07 78 01 13 53 2b b5
007ca0   29 19 29 20 31 53 2a f4 61 d9 78 23 8a 05 b2 57
007cb0   59 60 01 80 a5 aa 4b b3 00 36 0b e7 19 80 04 d9
007cc0   34 d3 43 00 05 15 52 2e 65 51 f8 b2 c1 97 5b 2f
007cd0   2e 40 b3 04 22 1d 06 5e ee 2b 00 18 01 38 e6 30
007ce0   01 18 c0 6d c8 3a 9a 60 18 65 d1 2b 39 50 23 71
007cf0   b4 61 40 1e 26 25 40 04 a6 3a 4a 24 12 2a 66 21
007d00   d3 32 3e 00 36 04 89 3a ea 23 2e 52 65 c8 a5 00
007d10   06 00 00 00 00 00 00 00 00 00 00 00 00 93 70 02
007d20   0a 70 0e c8 0d 04 01 8c 00 05 0d 04 00 a0 04 c5
007d30   93 70 02 41 02 aa 6b 61 02 10 e7 e0 1f 40 8f aa
007d40   00 a0 04 80 6d 0b 70 0e 92 aa 01 c2 a0 01 cd 4c
007d50   01 0e a1 01 01 bf f7 8c ff f4 0d 04 00 8c 00 52
007d60   61 02 10 5d 4a 02 13 d9 26 67 10 d5 e0 2f 3f 95
007d70   04 00 a0 00 41 0a 70 0e 79 0d 04 00 8c 00 33 26
007d80   70 02 4c 0a 70 0e c8 0b 70 0e 0d 04 00 4a 02 0d
007d90   61 e0 25 3f 58 02 70 01 00 4a 02 02 4f 4a 10 02
007da0   4b e0 2f 40 a4 02 06 8c 00 08 e0 2f 3f 2d 02 06
007db0   a0 05 c8 0d 05 00 8c 00 05 0d 05 01 a0 05 e6 a0
007dc0   04 63 a0 02 c6 a1 02 02 c6 92 1b 02 c2 4a 02 05
007dd0   bf f2 4a 02 07 3f ed 2e 70 02 0b 70 0e 0d 7c 00
007de0   8c ff 3f 41 02 aa c8 e0 2f 3e f8 02 00 ab 06 00
007df0   04 00 00 00 00 00 00 00 00 92 70 02 c2 a0 02 44
007e00   ab 04 a1 02 03 c2 4a 02 04 80 4a c1 97 02 b1 3f
007e10   80 43 e0 1f 1b b8 1e 00 a0 00 fa 4c 02 0e 6e 02
007e20   01 a0 04 71 61 01 10 6d b2 04 37 50 e7 2a e0 5f
007e30   52 48 cc 2b 00 06 82 7c e6 30 01 19 37 52 b8 00
007e40   c0 2d 5c 03 66 47 4a 45 58 60 0e 65 52 e0 b2 bb
007e50   0d 04 01 2d 02 03 8c ff a6 00 03 00 00 00 00 00
007e60   00 a2 01 02 c2 a0 02 c0 a1 02 03 c2 4a 02 04 00
007e70   3b 4a 02 11 77 4a 02 05 f3 4a 02 0e ef e0 1f 1b
007e80   b8 0a 00 a0 00 e6 4e 02 70 4b 02 0d 4b 02 0e 41
007e90   02 2a 45 0d 6a 00 61 01 10 40 b2 84 25 aa 02 b3
007ea0   00 6b 6c d3 3b 0d 29 25 d0 a5 2d 02 03 8c ff b7
007eb0   06 00 00 00 00 00 00 00 00 00 00 00 00 a2 01 05
007ec0   c2 a0 05 44 ab 06 a1 05 04 c2 4a 05 0e dd a0 03
007ed0   ca 4a 05 05 d6 4a 05 04 52 6e 05 02 4b 05 0d 0d
007ee0   06 01 41 02 70 45 4b 05 0e 2d 05 04 8c ff d4 00
007ef0   00 c1 97 5b 2e 49 5f b3 08 dc 3a 31 00 48 64 d0
007f00   2a 60 53 6a 5c 01 03 2d 39 4b 17 18 01 2a 19 20
007f10   1e 89 f8 b2 41 5b 13 49 41 8e 3f 45 ad 89 b0 c1
007f20   95 5b 2f 1e 25 40 ad 89 b0 00 03 00 00 00 00 00
007f30   00 a0 68 46 41 10 aa c0 a0 7c 01 53 a0 68 00 6b
007f40   a0 01 00 67 e7 7f 64 00 23 1e 00 00 5e 0c 70 0e
007f50   0d 7c 01 e0 07 1d 9b 41 f5 02 00 e1 97 00 00 01
007f60   b3 13 14 49 43 79 06 5e fe 3a 6c 00 c0 05 c7 19
007f70   80 04 a8 1b 1a 1a 31 78 11 28 d3 3a 6c 00 7a 04
007f80   1c 1a 31 05 42 18 25 22 2a 1a e0 06 21 00 e6 30
007f90   1c 3a 31 00 48 64 d0 2a 60 52 71 78 14 6d 57 00
007fa0   5f 25 46 24 07 51 3e 96 45 a0 01 d0 e7 7f 64 00
007fb0   23 1e 00 48 0b 70 0e ad 4a b0 e7 7f 64 00 23 46
007fc0   00 c0 a0 68 40 e0 25 3f 58 10 70 01 00 a0 00 c8
007fd0   2d 02 10 8c 00 10 e0 25 3f 58 83 70 01 00 a0 00
007fe0   c5 0d 02 1e 0d 7c 01 a0 02 80 62 a0 01 00 5e b2
007ff0   07 98 6b 15 39 0e 53 58 17 83 59 d3 25 db 39 3a
008000   1a 20 05 66 00 2e 1c cc 01 fa 63 20 70 d3 25 57
008010   29 20 06 81 1a da 39 59 47 c0 18 f8 66 e6 23 2a
008020   24 18 52 4a 03 66 47 46 1e 2a 60 01 c8 a5 61 02
008030   10 4a b2 04 17 d2 92 8c 00 0b b2 04 95 53 18 2b
008040   18 ba 93 ad 17 e0 3f 3d 8d 00 b1 a0 01 cf 0b 70
008050   0e 0d 01 00 e0 2f 40 62 02 00 b0 b2 07 85 66 2a
008060   0d 21 19 ba 4d 97 78 b9 01 8a 4f 31 2a 43 25 fa
008070   63 20 70 d3 25 57 29 20 65 b7 53 4c 34 23 20 d7
008080   5f ce 4d 80 18 01 38 e6 b0 2a ad 4a b0 a0 01 c0
008090   e7 7f 64 00 23 1e 00 40 e0 25 3f 58 10 70 01 00
0080a0   a0 00 c8 2d 02 10 8c 00 10 e0 25 3f 58 83 70 01
0080b0   00 a0 00 c5 0d 02 1e 0b 70 0e 0d 01 00 e0 2f 40
0080c0   62 02 00 b1 01 00 00 a0 01 80 52 b2 04 22 1d fa
0080d0   63 20 45 4b 64 2a 04 52 1b c0 0a 21 4e 74 65 c8
0080e0   29 20 06 2d a8 05 41 01 1e 54 b2 5e 87 1d 49 00
0080f0   28 1e 2e 4d 20 2d d7 e3 25 8c 00 19 b2 1a b5 5e
008100   95 5d c6 65 49 00 20 6c d1 68 c7 45 58 00 36 04
008110   17 d2 92 ad 17 e0 3f 3d 8d 00 b8 ad 4a b0 04 00
008120   00 00 00 00 00 00 00 92 70 02 c2 a0 02 44 ab 04
008130   a1 02 03 c2 4a 02 04 4b 6e 02 01 4c 02 0e 0d 04
008140   01 2d 02 03 8c ff e6 00 03 00 00 00 00 00 00 a2
008150   01 02 c2 a0 02 c0 a1 02 03 c2 4a 02 11 00 58 4a
008160   02 0e 80 53 e7 7f 64 00 23 28 00 00 4a b2 0d a1
008170   01 2e 63 26 4d 0a 04 78 52 4a 0f d8 1b d8 04 65
008180   64 92 78 23 11 c0 72 93 25 57 03 8d 1b 20 0a 4b
008190   3a 6a 80 a5 aa 02 b2 00 25 26 8e 4d 80 06 a5 c8
0081a0   b9 bb e0 1f 1b b8 3c 00 a0 00 c1 4e 02 70 4b 02
0081b0   0d 4b 02 0e b0 2d 02 03 8c ff 9a 00 02 00 00 00
0081c0   00 51 4b 0f 01 41 4b 67 48 0d 02 2d 8c 00 0a 57
0081d0   11 04 00 34 0f 00 02 e7 7f 64 00 63 02 00 00 d6
0081e0   e7 7f 64 00 23 32 00 00 60 55 01 02 01 42 01 00
0081f0   4a e0 3f 41 7c 00 8c 00 b7 e7 7f 64 00 23 32 00
008200   62 b2 84 25 aa 4b b2 02 ea 21 4e 6d 58 00 c0 25
008210   4a 54 0c 1b 0d 00 36 0b f8 39 2a 96 45 bb 8c 00
008220   8f b2 13 11 1b 0d 16 80 88 25 aa 8e b2 01 14 4e
008230   6a 23 38 16 80 05 e8 53 51 24 02 23 0a 5d d4 6b
008240   05 d0 a5 bb 8c 00 69 04 01 00 4a e0 3f 41 7c 00
008250   8c 00 5d e7 7f 64 00 23 32 00 6e b2 84 25 aa 4b
008260   b2 00 25 63 37 69 10 00 5b 04 06 5e 45 18 3b 00
008270   f1 52 89 00 ea 31 d3 60 01 33 37 39 10 45 40 26
008280   9c cc b2 bb 8c 00 29 b2 04 27 46 9c 02 26 4d 38
008290   04 72 1a 0e 4d 80 18 18 34 d1 46 9c 01 86 61 a0
0082a0   06 c1 80 a5 aa 4b b2 17 18 00 d7 c8 b4 bb e3 9b
0082b0   4b 0f 01 b0 e7 7f 64 00 23 32 00 62 b2 07 8c 52
0082c0   89 03 11 1b 0d 04 62 41 d9 02 4e 63 0a 60 01 80
0082d0   a5 aa 4b b3 00 fe 00 c0 49 d1 a8 b2 b2 04 48 34
0082e0   d7 31 41 0c 50 84 05 aa 4b b3 01 fa 4a b8 02 6e
0082f0   48 f1 78 06 61 c9 a8 b2 01 00 00 b2 04 2b 1b 26
008300   44 07 46 9c 03 19 5d d0 2b 00 84 05 aa 4b b2 03
008310   16 68 2d 06 c1 01 aa 1a f9 17 a0 11 aa 01 2e 2b
008320   01 28 86 60 01 80 a5 aa 4b b2 00 f7 28 d9 35 58
008330   00 5f 44 d8 64 07 5d 46 65 a1 0c c0 22 34 69 20
008340   05 38 3a 6e 63 2a 5c 07 44 c8 40 0b 51 80 2a 7b
008350   2a 34 57 00 35 d2 14 c1 6c 1c 35 53 01 d9 02 2e
008360   2f 38 04 61 01 06 5d 06 63 00 04 ac 52 6a 96 45
008370   bb a9 4b 41 4b 67 5c e3 57 67 0f 02 2e 19 10 0c
008380   19 06 0b 19 1d 0b 19 11 0d 20 01 54 11 0a 11 ab
008390   11 e3 57 70 0f 05 2e b1 10 0c b1 06 0b b1 11 0b
0083a0   b1 1d e0 0f 1d a5 3e 88 00 e1 97 00 00 00 e0 2f
0083b0   40 8f 10 00 a0 00 c0 41 10 aa 5a b2 10 d8 00 20
0083c0   08 e9 39 58 04 62 7c 7b 5d 46 56 aa 1a e5 c8 a5
0083d0   8c 00 11 b2 11 a1 14 f4 53 3e 02 ea 48 ce 4f 05
0083e0   c8 a5 bb bb e0 3f 30 fa 00 b8 03 00 00 00 00 00
0083f0   00 e0 03 1d 9b 41 f5 ff ff 00 e1 97 00 00 01 11
008400   1e 0f 01 26 67 10 4b 0d 03 37 2d 02 6f 8c 00 0c
008410   26 70 10 6f 0d 03 3c 2d 02 1e e7 7f 64 00 63 03
008420   00 00 87 e7 7f 64 00 23 32 00 00 4e 55 01 02 01
008430   42 01 00 6a 4f 02 06 00 e0 2f 37 52 00 00 8c 00
008440   63 e0 0f 1d a5 41 f5 00 e1 97 00 00 00 e0 03 1d
008450   9b 42 60 ff ff 00 e1 97 00 00 01 b1 e7 7f 64 00
008460   23 32 00 4c 4f 02 05 00 ad 00 bb 8c 00 36 4f 02
008470   04 00 ad 00 bb 8c 00 2c 04 01 00 4f 4f 02 06 00
008480   e0 2f 37 52 00 00 8c 00 1b e7 7f 64 00 23 32 00
008490   4c 4f 02 03 00 ad 00 bb 8c 00 09 4f 02 02 00 ad
0084a0   00 bb e3 5b 1e 0f 01 b0 e7 7f 64 00 23 32 00 4a
0084b0   4f 02 01 00 ad 00 bb b0 4f 02 00 00 ad 00 bb b0
0084c0   03 00 00 00 00 00 00 11 1e 0f 01 11 67 0f 02 11
0084d0   70 0f 03 41 01 06 5a 41 02 02 56 41 03 05 52 e0
0084e0   0f 1d a5 42 60 00 e1 97 00 00 00 0d 6d 0a b1 96
0084f0   6d a0 6d 40 42 01 06 4b 54 01 01 00 e3 5b 1e 0f
008500   00 42 02 02 4b 54 02 01 00 e3 5b 67 0f 00 42 03
008510   05 4b 54 03 01 00 e3 5b 70 0f 00 0d 6d 0a b1 00
008520   01 00 00 41 01 03 40 b2 04 41 37 19 1a 69 3a 6c
008530   00 36 0d 34 55 53 01 6e 2a 29 00 5c 05 26 00 65
008540   36 9a 61 41 0c 2b 18 07 50 d7 25 49 01 77 52 79
008550   01 34 52 e1 a8 a5 a0 72 d9 b2 07 98 29 17 2b 20
008560   54 d9 34 02 30 5a 00 3f 04 0b 52 ea 63 21 a8 a5
008570   b2 04 48 53 51 24 08 3a e8 45 40 04 0d 53 58 28
008580   01 30 20 0b b4 5c 03 b8 b2 b0 00 41 5b 49 40 41
008590   4b a7 40 e0 13 3d e3 a7 5d 52 00 b8 00 41 5b 4f
0085a0   40 b2 17 24 70 8a 12 24 20 94 12 44 28 04 64 94
0085b0   00 9f 12 84 5c 90 04 66 01 86 49 40 05 26 27 6a
0085c0   4f 3a 5d 41 0d 26 4d 8a 5c 23 04 d1 53 80 23 53
0085d0   4d d3 30 2a 12 74 01 14 4a ba 65 57 03 0d 53 51
0085e0   24 02 23 8e 65 b4 6b 20 52 6a 16 85 64 a7 14 e4
0085f0   4e 99 28 bd 00 52 17 32 3a 6e 17 9f 52 f0 17 20
008600   22 93 64 ce 4f 00 52 71 78 06 03 1a 1c bc 61 59
008610   00 29 04 11 51 06 65 d4 4f 01 0e ba 7f f1 2b 01
008620   0c 26 25 58 22 ee 57 2e 52 78 01 74 ea 69 ad 52
008630   b0 00 01 00 00 41 01 06 40 e0 3f 2b 1e 00 b8 00
008640   01 00 00 41 01 03 40 b2 04 41 34 ea 35 d3 24 01
008650   00 65 36 9a 61 41 28 95 1b 2d 60 11 28 c9 00 3f
008660   04 0b 52 ea 63 20 05 81 00 61 04 c3 3d 46 63 21
008670   28 6d 0f c8 52 f3 2a e0 05 21 01 b4 eb 0a e0 3f
008680   43 42 00 b8 00 b2 00 25 18 01 67 8e 4d 34 70 01
008690   e0 25 0a b0 0a 48 b2 52 aa cc b2 b0 b2 62 2e 31
0086a0   b9 47 c0 19 e6 dc b2 b0 00 c1 95 10 12 35 7d 4b
0086b0   c1 97 5b 1d 32 45 ad 73 b0 41 5b 2e 75 b3 04 2d
0086c0   53 58 28 01 14 c0 1d 46 6b 2e 2f 51 00 65 22 91
0086d0   52 6e 1a 21 28 21 53 93 2a f8 02 5a 63 20 06 67
0086e0   29 53 01 5d 66 ea 49 51 78 1c 28 d1 65 be 96 45
0086f0   c1 97 5b 25 1d 49 e0 1f 3a e3 15 00 b8 41 5b 19
008700   40 b3 04 52 6b 19 00 48 3e 90 3a 6c 96 45 00 c1
008710   97 5b 2e 49 40 e0 13 3d e3 36 5c 61 00 b8 00 c1
008720   97 5b 24 25 40 b3 04 3c 3a 69 53 98 00 2d 1e 86
008730   5d 2a a4 b4 00 41 5b 49 40 b3 04 33 19 d1 60 01
008740   34 6a 25 4a 56 3e 01 d2 1d 49 25 49 96 45 00 41
008750   5b 2d 48 e0 3f 35 a9 00 b8 41 5b 32 40 ad 73 b0
008760   01 00 00 41 01 02 49 a0 84 46 0b 15 0e b0 41 01
008770   03 40 b2 05 e1 14 c0 54 d9 34 01 50 c0 25 d2 47
008780   c0 45 d9 01 74 5d 58 64 23 23 57 6d d3 30 01 48
008790   53 05 8a 1b 19 05 41 70 2e 66 ea 28 01 2e 34 70
0087a0   07 5c d3 21 aa 60 18 64 d3 27 00 1f c0 04 0a 25
0087b0   8a 00 29 04 15 1b 2d 96 45 0a 15 0a 5e b2 00 27
0087c0   04 a3 26 95 2a 60 32 e6 65 d3 30 23 25 58 21 53
0087d0   25 d3 30 01 7c 78 96 45 b0 a0 84 c0 b2 00 27 04
0087e0   a6 00 42 61 48 6a ea 47 c0 2c d8 65 53 29 20 07
0087f0   e1 00 55 96 45 b0 00 a0 84 d6 0a 15 0a 44 9b 9a
008800   b2 04 22 08 25 07 65 d0 a5 bb 0d 8a 15 b1 ad 34
008810   b1 00 02 00 00 00 00 41 01 03 64 b2 04 41 37 2a
008820   4c 03 00 c7 53 6a 00 20 0a a1 0e 6a 63 31 29 20
008830   1a 54 4d 80 05 c7 5c d3 21 aa e0 b2 b0 41 01 01
008840   40 41 5b 1b 4f c1 97 4b 1b 4c 49 e0 1f 3a e3 16
008850   00 b8 41 5b 29 40 e0 3f 3a 16 00 a0 00 c1 c1 9b
008860   4b 4c 83 d5 4e 4b 77 b2 84 25 aa 4b b3 01 66 46
008870   38 00 2c 04 02 d4 b2 41 5b 38 40 e0 0f 37 52 5c
008880   b2 00 b8 00 00 41 5b 49 40 e0 1f 2b fa 4a 00 b1
008890   00 c1 97 5b 36 25 40 41 4b 4a 40 b2 05 ea 31 80
0088a0   52 71 78 14 55 53 e0 a5 ad 52 b0 00 00 41 5b 1f
0088b0   4d b3 15 c5 44 b3 15 25 20 ad 96 45 41 5b 19 6e
0088c0   e0 3f 44 9a 00 b2 04 31 28 db 2b 00 1f 57 cc a5
0088d0   e0 1f 3d 69 6c 00 a0 00 cc e0 0f 37 52 61 18 00
0088e0   8c 00 04 ad 17 e0 2f 3d 84 4b 00 b8 41 5b 21 5e
0088f0   e0 3f 44 9a 00 b3 04 31 28 db 2b 00 61 4a 48 01
008900   30 48 0d 58 51 8c 78 01 31 1a e4 b2 41 5b 45 4c
008910   e0 3f 44 9a 00 a0 00 c4 bb b0 41 5b 49 48 e0 3f
008920   44 9a 00 b1 41 5b 41 40 a0 84 40 e0 17 3d c0 6c
008930   15 00 b8 00 00 0a 15 0a c0 a0 84 40 0c 15 0e 0d
008940   84 01 b2 0d a9 3b 19 6a e7 3a 6c 00 20 45 46 6d
008950   58 04 66 00 42 04 b7 2b 6a 1a 2a a4 2a b0 01 00
008960   00 41 01 01 40 41 5b 38 40 a0 4b 40 e0 0f 37 52
008970   5c b2 00 b8 00 41 5b 38 ca 41 5b 13 4e 41 4b 0d
008980   4a e0 0f 37 52 5c b2 00 b8 c1 97 5b 5e 13 40 41
008990   8e 43 40 b2 84 25 aa 4b b2 00 25 0f f1 53 19 00
0089a0   36 04 17 3b 6a dc b2 bb e0 2f 3d 84 4b 00 b8 00
0089b0   00 c1 97 5b 1d 20 53 41 10 0f 48 e0 3f 35 a9 00
0089c0   b8 e0 1f 3a e3 17 00 b8 41 5b 41 40 b3 04 22 10
0089d0   97 3b 6a 5c 0b 46 9c 60 1a 4d 2a 5c 01 02 e6 3a
0089e0   67 53 85 c8 a5 00 00 c1 97 5b 1e 25 4d e0 10 3d
0089f0   f4 b0 59 60 61 04 00 b8 41 5b 2e 6b 0a 12 0a e7
008a00   b3 04 3c 3a 69 53 80 04 b8 45 cc 37 31 78 06 3c
008a10   d7 04 62 40 51 2a 74 69 8d 00 2c 1a 31 53 80 2a
008a20   79 5f c5 c8 a5 c1 95 5b 1d 18 66 56 41 10 12 48
008a30   e8 7f 1e 8c 00 05 e8 7f 1d e0 2f 3a e3 00 00 b8
008a40   41 5b 2f 40 b2 04 43 13 0a 28 06 80 a5 41 10 12
008a50   4f b3 2e 97 2b 19 01 11 28 d7 3a 6c 96 45 b3 41
008a60   d9 21 aa cc b2 00 01 00 00 41 01 03 40 b2 04 41
008a70   34 36 04 10 3b 28 35 53 00 29 04 03 15 b4 6b 0a
008a80   05 41 73 26 1e 2a 00 6b 1d 4a 4c 1a 61 49 02 ea
008a90   21 53 66 3e 00 4a 04 15 5d 55 1a e6 65 c2 6c 29
008aa0   2e 94 24 2a 07 82 5c 4c 0b 81 18 c0 24 d7 40 03
008ab0   70 4c 6a bc 1a e9 05 41 71 0d 3a 53 2b c0 09 89
008ac0   53 93 00 26 05 81 01 46 e3 25 e0 3f 43 42 00 b8
008ad0   00 41 5b 59 40 26 0a 4b 40 b3 11 b4 64 15 2a b5
008ae0   2a f8 96 85 00 41 5b 2b 40 a9 4b b3 04 42 36 46
008af0   41 40 2e ee 2a 69 60 02 4b 86 78 23 0a 13 50 f4
008b00   27 c0 1a f4 6a 69 00 35 00 25 0d 4b 5d ca 4d 31
008b10   78 06 4f cd 53 81 28 8c 6a 35 96 85 00 c1 97 5b
008b20   24 5d 6f 41 4b 61 6b b2 04 27 53 39 45 40 61 a6
008b30   67 2a 5f 05 c8 a5 26 7c 4b 50 e0 1f 3d 84 7c 00
008b40   e5 7f 20 ad 5f 8c 00 03 bb e0 2f 3d 84 4b 00 b8
008b50   41 5b 57 40 4a 4b 0a 40 26 7c 4b 40 e0 1f 3d 84
008b60   7c 00 ad 5f b0 00 00 c1 97 5b 18 1d 51 ad 50 b3
008b70   63 8e 48 01 58 20 27 53 31 54 cc b2 41 5b 31 4b
008b80   e0 1a 1d 3a 13 8e 4b 00 b0 41 5b 49 51 46 4b 61
008b90   4d a0 8e 4a e0 17 1d 3a 49 61 00 b0 c1 97 5b 13
008ba0   49 00 a2 c1 97 4b 03 7c 00 9b a0 8e 54 e0 1f 3d
008bb0   69 61 00 a0 00 c8 0d 8e 61 8c 00 05 0d 8e 04 41
008bc0   8e 04 53 b3 04 22 2f 11 3a b8 00 34 04 8b 3a 6c
008bd0   2a f8 96 45 e0 2f 3d 69 8e 00 a0 00 4c ad 60 b2
008be0   84 05 aa 8e ad 17 b0 41 8e 61 ee 41 4b 7c 48 e0
008bf0   1f 3d 84 7c 00 b2 04 22 2e 2a 1a 18 02 9a 64 01
008c00   a4 20 aa 8e b3 00 26 2b 66 56 97 1b 2a 60 0e 4a
008c10   4a 25 c6 65 51 f8 b2 0a 61 0a d0 0d 8a 61 b3 04
008c20   27 53 39 45 40 04 a1 ec b2 92 61 00 c0 0e 7c 61
008c30   b3 04 27 53 39 45 40 04 a3 7d 7a 46 20 05 3c 1b
008c40   2a dc b2 41 5b 13 5a c1 97 8e 03 7c 54 e0 1f 3d
008c50   1b a3 00 a0 00 cb e0 19 1d 3a 13 4b a3 00 b0 c1
008c60   95 5b 5d 34 29 40 06 7c 61 40 0a 61 0a cd b3 04
008c70   27 53 39 45 40 04 a1 ec b2 e0 1f 3d 84 7c 00 ad
008c80   5f b0 00 41 5b 5f 00 52 41 8e 29 00 3e a0 6a c5
008c90   ad 79 b0 0d 6a 01 0b 2a 06 0b 2a 0b 0b 2a 17 2e
008ca0   2a 10 b3 04 37 52 aa 01 37 52 b8 02 9b 2a e0 04
008cb0   18 39 2a 00 26 22 92 2b 00 71 d9 34 36 65 53 00
008cc0   60 05 21 01 71 52 97 96 45 ad 50 b3 65 ca 00 20
008cd0   5e 95 28 01 30 49 96 45 41 5b 60 60 41 8e 2a 5c
008ce0   b2 84 25 aa 4b b3 03 19 5f 4c 32 2a 60 01 18 28
008cf0   09 f9 39 40 35 d2 03 55 96 45 41 5b 62 71 a0 6a
008d00   dd 0d 6a 00 0c 2a 06 0c 2a 0b 0c 2a 17 b3 04 37
008d10   52 aa 00 25 0f fa 4f 2e 29 25 c8 a5 b3 08 c1 14
008d20   51 65 ca 24 01 30 d3 7b 2d 3a 6c 96 45 41 5b 49
008d30   40 a0 6a c0 b3 04 37 52 aa 00 25 65 ca 24 01 30
008d40   20 5c ce 45 d3 b0 b2 00 00 a0 81 d8 0a ae 0a 44
008d50   9b 16 0d 8a ae b2 04 39 5c d5 00 62 04 a1 ec b2
008d60   bb b1 ad 34 b1 00 01 00 00 41 01 03 00 bf b2 04
008d70   31 3b 6e 4d 80 07 54 55 53 60 01 30 20 28 d8 64
008d80   2a 13 34 00 20 0b 81 94 c5 a0 5c d3 b2 00 63 17
008d90   98 34 d5 29 20 52 aa 4d d3 30 01 d8 c5 b2 00 6c
008da0   26 94 5c 23 18 f4 6d 40 07 01 17 19 5c d3 31 40
008db0   32 99 35 c8 02 2a 67 2a 5d d3 b0 2a a0 5c 51 b2
008dc0   04 23 08 25 4c ce 45 49 03 0d 6b 21 a8 a5 b2 04
008dd0   e1 14 c0 66 f4 55 be 01 06 61 40 06 a1 0c 26 98
008de0   a5 a0 81 ec b2 02 fa 30 11 79 d3 30 07 2b 0e 25
008df0   40 98 a5 0a ae 0a 4a b2 4c 14 d5 53 8c 00 05 b2
008e00   80 3b b2 03 37 1a a0 26 94 dc a5 8c 00 1b b2 00
008e10   2e 52 ee 2a 79 1a 20 5f 4c 00 36 04 08 2a 79 2a
008e20   e0 05 21 02 f4 d2 45 e5 7f 2e b0 41 01 06 40 41
008e30   5b 13 40 41 8e 88 40 e0 1f 47 3f 88 00 41 00 0f
008e40   40 c1 8f 11 01 45 40 a0 72 40 0d 72 01 cd 4f 11
008e50   01 5e 0c 10 0e 0c 2e 0d b3 07 9b 51 c8 28 1c 35
008e60   d8 55 57 60 23 17 24 46 94 40 01 30 24 0f 62 28
008e70   20 2d d3 1a 20 61 48 5d 59 16 45 e4 a5 00 03 00
008e80   00 00 00 00 00 a2 01 02 c2 a0 02 44 ab 03 4a 02
008e90   04 44 95 03 e0 2f 47 3f 02 00 74 03 00 03 a1 02
008ea0   02 bf e8 8c ff e5 00 41 5b 49 40 41 4b 88 40 e0
008eb0   13 3d e3 88 60 d2 00 b8 00 41 5b 5d 4f b3 04 52
008ec0   39 8d 64 07 5d 46 40 0e e4 b4 c1 95 5b 2e 15 12
008ed0   55 0a 66 18 51 b3 04 31 1a 55 00 6b 1f 57 4d 49
008ee0   02 9a e4 b2 41 5b 12 4f e0 0f 1d a5 47 92 00 e1
008ef0   97 00 00 01 b1 41 5b 15 4f e0 0f 1d a5 47 92 00
008f00   e1 97 00 00 00 b1 41 5b 2e 40 b2 04 31 1a 55 00
008f10   25 d0 a5 0a 66 13 48 e5 7f 6e 8c 00 05 b2 ad 65
008f20   ad 17 b0 00 02 00 00 00 00 9e 3d 02 4f 02 00 01
008f30   e0 0b 1d 9b 47 92 01 00 e1 97 00 00 01 e0 1a 3c
008f40   fa 66 02 01 00 a0 01 c0 54 02 04 3d ab 3d 00 c1
008f50   97 5b 42 25 4b b3 08 c2 36 95 2a 65 c8 a5 c1 97
008f60   5b 24 19 40 b3 12 6e 21 40 66 fe 96 45 00 00 c1
008f70   97 5b 49 4e 74 b2 04 37 69 80 04 a3 29 aa 1b 7e
008f80   00 2c 45 cb e4 a5 a0 81 5d b2 04 62 40 28 4e 99
008f90   39 0a 24 03 25 d7 5d 4c 6a 26 5d d9 78 07 2a 6a
008fa0   1b 2d 81 d9 ad 17 b0 c1 97 5b 4d 45 7a a0 81 c5
008fb0   ad 79 b0 0c ae 0e 0d 8a ae 0d 81 01 b3 04 49 5c
008fc0   cc 00 20 5f 4c 00 2c 0f d8 39 2a 00 29 04 17 52
008fd0   92 04 77 2b 6a 1a 2e 4d 80 18 01 6c 19 5c d5 01
008fe0   34 52 e5 c8 a5 41 5b 41 4d a0 81 4a e0 17 3d c0
008ff0   28 ae 00 b8 41 5b 1c 40 a0 81 69 b3 10 d8 00 28
009000   66 fe 00 2c 61 d9 04 61 22 74 65 c8 28 03 25 d7
009010   5d 4c 6a 26 5d d9 78 07 2a 6a 1b 2d 00 20 5f 4c
009020   96 45 b3 06 e2 44 c0 48 cc 39 00 20 d7 55 59 96
009030   45 00 00 41 5b 4e ca 41 5b 41 4e 41 10 35 4a e0
009040   17 1d 3a 25 ae 00 b0 c1 97 5b 1e 25 51 41 10 35
009050   4d e0 20 3d f4 4b 5c 6a 5c 7e 00 b8 41 10 16 40
009060   c1 97 5b 61 25 55 0a ae 0a d1 b3 06 f1 1b 28 35
009070   49 00 32 18 f4 6d 45 c8 a5 41 5b 1e 40 0a ae 0a
009080   40 0c ae 0a b3 04 23 0a 26 65 0d 2b 00 61 ba e4
009090   b2 00 01 00 00 41 01 03 00 50 b2 04 41 34 36 18
0090a0   09 1a f0 04 69 1a 55 01 0a 46 26 5c 01 2c 4e 54
0090b0   d8 60 cc 2b 86 7b 00 05 81 00 5d 04 ca 1b 19 05
0090c0   44 52 60 04 02 70 25 04 07 53 39 52 40 05 26 03
0090d0   19 29 55 02 4a 64 d1 02 e6 4a a0 07 01 17 53 22
0090e0   2e 48 e6 1e 2a 96 45 b0 41 01 02 40 0a ae 0a 40
0090f0   0a ae 0d c0 0c ae 0a 0b ae 0d b2 04 39 5c d5 00
009100   62 22 e6 61 aa 60 18 37 59 04 61 18 28 35 46 5c
009110   18 52 4a 0f c7 1a f7 3a 6c 01 d9 96 45 bb bb b0
009120   01 00 00 a2 83 01 c2 e0 1f 3a 31 1e 00 42 00 03
009130   4b 0a ae 0a c5 0c ae 0d 9b 12 ad 50 b2 2d d9 00
009140   2b 71 a6 64 1e 53 45 62 ea 01 06 5e fe 3a 6c 96
009150   45 bb b1 00 00 41 5b 24 40 b3 13 14 49 40 54 ce
009160   4f 20 21 ae 57 00 1b 86 78 23 5d 5b 28 d1 3a 6c
009170   02 54 5d 40 54 ce 4f 25 c8 a5 00 41 5b 24 40 b3
009180   11 34 4c b8 64 02 20 c0 6c d3 24 d1 96 85 01 00
009190   00 41 01 02 40 26 67 10 40 e0 07 1d 9b 41 f5 02
0091a0   00 e1 97 00 00 01 0d 8a 67 ab 8a 00 00 41 5b 54
0091b0   60 0d 2d 00 b3 11 aa 17 18 00 51 4b 48 34 01 24
0091c0   c0 22 93 6d 57 60 d9 3a 93 1a 2e 63 25 c8 a5 41
0091d0   5b 2e 4a 11 67 0e 00 ad 00 bb b0 41 5b 24 5b b3
0091e0   04 39 5e 91 44 11 1b 4c 37 00 1b 20 04 95 6a 7e
0091f0   01 8a 63 3a 5d 45 c8 a5 c1 97 5b 34 5d 00 46 b2
009200   04 39 5e 91 44 0c 5c c7 60 01 80 a5 aa 4b b2 00
009210   d3 24 23 0a 2d 1b 6e 4d 80 04 12 53 19 01 2e 61
009220   17 3a 4e 4c d9 3a 6c 03 26 63 2a 60 23 32 2a 29
009230   7a 46 3e 01 46 67 00 3b 25 c8 a5 bb e0 2f 3d 84
009240   4b 00 b8 41 5b 3e 40 b3 04 39 5e 91 44 01 16 5a
009250   48 f1 3a 6c 00 36 18 0c 6b 39 6a e6 44 19 52 6c
009260   69 45 c8 a5 01 00 00 41 01 03 40 b2 04 41 34 53
009270   85 25 a0 1b c7 ad 15 8c 00 19 b2 18 01 3a 26 41
009280   41 0d 66 5c 03 29 2a 2a a0 04 dc 39 2a 00 2c 9d
009290   45 b2 01 17 53 18 29 21 28 95 1b 2d 60 11 28 c9
0092a0   01 46 63 21 0c 6e 04 61 18 5a 96 45 b0 00 01 00
0092b0   00 41 01 03 40 b2 04 41 34 d9 52 a0 11 71 52 89
0092c0   00 88 52 79 5e 91 00 89 1a 40 16 e5 2c 23 07 1c
0092d0   1b 00 52 68 28 16 69 d9 28 06 03 34 6a ee 63 20
0092e0   1b 39 5c c8 65 d4 4c 2a 04 e1 35 5d 3b 38 00 2c
0092f0   04 03 74 26 71 58 64 23 04 c6 03 08 5c d2 1e 2a
009300   01 34 72 61 a8 21 a0 1b fa b2 09 71 2b 6a 44 07
009310   29 ae 4d 20 04 09 1a 40 04 b1 53 85 18 3b 00 20
009320   30 d9 2b 00 05 b4 55 53 00 26 09 77 6b 0d 2b 00
009330   06 81 01 26 48 01 19 34 72 78 66 ea 9a 45 8c 00
009340   4b b2 62 3a 39 0a 01 86 65 58 00 5b 04 09 1a 40
009350   05 a1 6c 2a 10 ea 35 d3 24 01 01 26 48 01 14 c0
009360   71 c9 28 17 2b 0a 5f 74 3a e1 28 9c 1b 2a 5c 01
009370   16 b4 6a ee 4d 80 53 6a 5c 01 03 34 54 01 24 20
009380   18 e6 4d 34 4d 49 01 26 c8 a5 b2 05 41 1c 25 18
009390   08 52 79 5e 91 02 a6 4d 51 00 35 04 62 6c 38 18
0093a0   01 3a 4a 64 d1 00 f4 47 20 04 b2 53 53 65 49 05
0093b0   44 18 f4 6d 40 04 07 52 39 00 25 18 01 65 97 29
0093c0   53 02 b1 1b 19 39 00 1f 47 9e 2a a0 5d d1 b2 00
0093d0   38 04 ac 46 9c 3a 6c 03 0a 5d 53 aa 3e e5 7f 2e
0093e0   b0 00 01 00 00 c1 97 5b 19 12 00 77 41 4b 0c 00
0093f0   72 43 51 00 d3 b3 04 41 4e fa 4c 14 6b 20 05 32
009400   1b 28 35 58 96 45 96 51 c1 97 10 79 8b 5d b3 07
009410   89 5c cb 64 0e 4f 19 1a 79 47 c0 1e 34 73 00 04
009420   12 1b 28 34 14 6b 25 c8 a5 0b 0c 19 0b 0c 13 e0
009430   07 1d 9b 4a 7a 02 00 e1 97 00 00 01 b2 12 93 28
009440   01 24 20 48 d9 21 aa 60 18 64 d7 67 00 05 87 6a
009450   f3 96 45 bb a0 36 41 0d 36 01 bb e0 3f 30 fa 00
009460   b0 41 5b 15 66 0a 0c 19 62 0c 0c 19 0c 0c 13 e0
009470   07 1d 9b 4a 7a 00 00 b2 04 32 1b 28 34 01 16 9a
009480   e4 b2 bb e0 3f 3d 8d 00 b8 c1 97 5b 25 1f 67 55
009490   51 01 01 b2 04 41 cc a5 43 01 00 c8 b2 ce 85 8c
0094a0   00 05 e6 bf 01 b2 02 46 e5 0d 41 01 01 c5 b2 ab
0094b0   05 ad 17 b0 41 5b 2e 40 0a 0c 13 51 b3 04 32 1b
0094c0   28 34 01 14 fa 5e 6e 4d 85 c8 a5 b3 04 32 1b 28
0094d0   34 f4 52 00 04 ba 4d d3 65 57 2b 19 3a 6c 04 6a
0094e0   75 0a 57 20 09 5c 34 d9 17 18 03 97 3b 39 2a 60
0094f0   0b 6e e4 b2 00 b2 04 32 1b 28 34 03 2d 83 7a 9a
009500   e4 b2 bb 0c 0c 19 0c 0c 13 e0 3f 3d 8d 00 b8 00
009510   00 41 5b 46 00 5e 41 8e ab 00 43 a0 5d f3 a0 1b
009520   70 0c 55 0d 0b 40 07 0c 40 03 0c a6 0e 0d 1b 01
009530   54 11 14 11 b3 04 38 47 4e 21 40 30 d9 2b 00 52
009540   aa 4c 01 18 4b 56 9a 5f 00 06 81 01 26 c8 b2 b3
009550   04 27 52 39 00 4d 1f 49 31 45 c8 a5 b2 04 27 52
009560   39 00 4d 67 57 4c 1a 61 d3 30 01 80 a5 aa 8e ad
009570   17 b0 41 5b 49 40 ad 65 b0 00 00 41 5b 49 40 ad
009580   65 b0 00 c1 97 5b 1e 25 40 b3 13 14 6a 69 60 17
009590   28 d8 52 66 1e 2a 04 62 40 52 08 ad 53 85 c8 a5
0095a0   00 41 5b 4d 40 41 4b 94 63 b2 04 21 6a 2e 31 b9
0095b0   e0 05 4a 10 13 4c 4c 10 13 b3 32 80 51 6b 96 45
0095c0   4b 10 13 b3 22 92 28 14 cc b2 41 4b 68 4f 0c a1
0095d0   0d 0d 5d 00 b3 11 11 39 10 96 45 41 4b 2f 40 0c
0095e0   a1 0d 0d 5d 01 b3 11 11 39 10 96 45 00 c1 97 5b
0095f0   31 16 40 26 a0 10 ca e0 0f 4b a7 5d 2d 00 b8 41
009600   8e 4d 00 44 2e 8f 10 0d 8a 8f b2 04 27 50 d9 01
009610   d3 2e 26 65 58 00 26 0b 18 28 dc 52 f9 37 c5 c8
009620   a5 0a 7a 0d db b2 00 3c 64 69 44 c7 2a 20 04 b1
009630   79 d3 30 0e 4f 0e 25 40 04 07 50 d9 96 45 bb e0
009640   1f 3d 84 a0 00 b8 41 8e 6d 57 b3 04 4d 1b 6a 4c
009650   b8 64 0a 4e 9a 31 a0 47 53 30 15 53 8a dc b2 b2
009660   0e 46 80 a5 aa 8e b3 16 85 d4 b4 00 02 00 00 00
009670   00 41 01 01 00 73 41 5b 66 6d c1 95 10 1a 75 20
009680   4f c1 95 4b 1d 1e 13 c0 c1 97 4b 16 17 c0 41 10
009690   40 48 c1 97 4b 1f 1c c0 b3 12 ea 19 20 04 19 0d
0096a0   31 18 ea c4 b4 41 5b 3d 40 c1 95 10 1a 75 20 c6
0096b0   41 10 40 45 ad 79 b0 e0 2f 51 3e 58 02 41 02 01
0096c0   57 e0 2b 51 4b 10 43 00 e0 0b 1d 9b 51 0f 00 00
0096d0   e1 97 00 00 01 b0 41 02 02 c1 ad 50 b3 44 da 4d
0096e0   0d 01 d9 00 35 96 45 a0 01 40 c1 97 5b 31 16 5d
0096f0   b3 11 d3 2e 26 65 d3 30 0e 64 0b 6a f9 35 57 02
009700   4e 31 b9 00 fa 5f 19 01 d9 96 45 41 5b 23 74 06
009710   1e 8f 49 b3 07 c1 59 d9 96 85 26 8f 10 ca e0 0f
009720   4b a7 5e a6 00 b8 2e a0 10 0d 8a a0 b2 04 27 50
009730   d9 01 2a 2e 26 65 58 96 45 bb e0 1f 3d 84 8f 00
009740   b8 41 5b 1c 40 e0 1b 1d 3a 18 4b 00 b0 00 01 00
009750   00 ad 50 ad 01 b3 2e 26 65 40 3b 20 6a 71 2b 18
009760   01 d9 17 18 00 5b 04 02 d4 b2 00 c1 97 5b 1a 1b
009770   40 b3 04 28 45 cb 2c 01 17 53 22 2e 48 e6 1e 2a
009780   96 45 01 00 00 41 01 03 00 7a b2 04 41 34 d9 00
009790   20 55 57 3a ad 2a fe 00 29 18 01 39 34 49 41 0c
0097a0   38 2e 97 4b 00 04 08 29 d1 3a 6c 00 29 1a 74 65
0097b0   aa 5c 01 68 ea 46 9c 05 41 70 6c 5c ce 45 d3 30
0097c0   15 5e 99 29 19 60 01 20 32 18 15 5d 48 3a ae 66
0097d0   9a 60 09 5e 95 96 45 a0 6a c0 b2 00 3c 5e 95 28
0097e0   0d 1a 6c 60 01 48 20 5c ce 44 01 19 53 27 00 0a
0097f0   d9 2a 60 0c 01 48 20 2e 34 52 e0 1d 51 53 85 c8
009800   a5 b0 41 01 02 00 3e a0 68 fb 4e 83 4e 0d 10 4e
009810   b3 10 d8 00 28 2a 79 2a e1 0c c0 63 37 52 6c 02
009820   ba 46 20 1b 00 39 60 06 46 03 8e 4d 20 26 e6 73
009830   00 05 14 6d 57 00 20 5c ce 45 d3 30 01 19 34 72
009840   65 c8 a5 41 01 01 40 41 5b 38 40 e0 0f 37 52 5c
009850   b2 00 b8 00 00 b1 01 00 00 41 01 03 40 b2 05 e1
009860   14 c0 05 c9 52 4a 24 19 2a 55 45 41 a8 a5 a0 6a
009870   80 43 b2 07 95 39 48 28 01 26 f4 55 40 25 58 21
009880   53 27 00 06 41 02 e6 3a 2e 4d 80 05 21 01 34 49
009890   41 0c 56 15 45 20 03 00 c7 53 6a 04 6a 4d 2e 4d
0098a0   80 62 92 28 0b 3b 6a 00 60 18 f4 6d 40 04 8d 28
0098b0   c9 85 45 b2 12 93 00 20 0c 3c 1a 31 00 25 0d 26
0098c0   4d 0e 2a 79 01 d3 61 17 3a b9 3a 93 04 63 1c c0
0098d0   56 e6 79 57 00 36 18 11 52 6c 17 8b 52 ec 53 39
0098e0   2a 60 44 d3 33 46 31 41 28 87 2a 34 70 01 02 b7
0098f0   1b ca 5c 23 18 18 64 ce 5c 02 31 34 72 61 28 21
009900   65 52 56 2a 17 18 00 d1 64 d7 00 25 05 81 00 6e
009910   05 43 34 20 21 53 65 57 00 29 04 01 6b 0e 67 00
009920   18 03 16 46 5c f1 28 15 29 2a 63 26 c4 b2 b0 00
009930   00 41 5b 2e 51 b3 04 39 52 e8 34 01 14 fa 5e 6e
009940   4d 85 c8 a5 41 5b 4a 61 41 4b 7c 5d b3 04 22 2d
009950   5b 1a b4 5c d9 2b 00 1d 4b 52 ea 01 d9 01 8a 67
009960   00 22 34 61 45 c8 a5 41 5b 15 40 4a 4b 13 40 b3
009970   04 53 28 d7 47 c0 1f 57 4c 01 11 a1 1b 37 79 d3
009980   30 01 31 5d 65 d3 33 4e 61 a0 04 0b 44 d2 a8 b2
009990   00 41 5b 52 40 41 10 63 45 a0 91 c0 b3 11 2e 4d
0099a0   81 0d 34 4d 85 c8 a5 00 00 c1 97 5b 4e 67 40 41
0099b0   10 22 c7 41 10 56 00 8c a0 75 00 68 b2 04 23 53
0099c0   14 45 c9 39 6e 2b 00 04 c1 14 7f 70 d1 40 c7 45
0099d0   40 17 c1 03 19 19 d7 60 01 18 e6 4e 6e 63 2a 5c
0099e0   01 34 20 31 db 28 dc 1b c5 fc b2 41 10 56 6d 06
0099f0   69 56 69 0a 69 0e 65 b2 00 3c 61 ae 4a 4a 5d d3
009a00   30 15 53 20 05 2c 52 29 00 58 1b 20 04 0a 4d 20
009a10   05 21 02 e6 3a 67 53 85 c8 a5 0c 69 0e 0d 75 01
009a20   bb b0 0d 75 00 b3 04 23 50 6b 1d 48 52 4a 03 14
009a30   49 5c 34 d9 02 fa 4c bc 51 65 73 2d 28 bc 49 d1
009a40   c4 b2 b3 11 26 7f f1 3a 6c 01 14 46 97 60 07 5d
009a50   ca 2e 3e 01 52 1a 66 65 40 06 41 03 08 2a b9 5d
009a60   45 c8 a5 00 01 00 00 41 01 01 40 26 78 83 c6 0d
009a70   57 01 b1 0d 57 00 b1 00 00 41 5b 25 4f b3 04 27
009a80   52 90 00 25 08 74 55 53 96 45 41 5b 1e 53 b3 12
009a90   89 26 3e 04 61 00 f4 52 00 09 e2 20 3b 96 45 41
009aa0   5b 46 d0 41 5b 50 40 41 8e 87 40 c1 8f 80 02 39
009ab0   c0 b3 10 ea 61 c9 28 15 19 8a 00 ad 15 c5 44 23
009ac0   64 35 00 25 52 71 78 03 7a a6 31 40 05 71 29 8e
009ad0   1e 2a 02 b7 3a 79 3a 6c 05 42 18 54 05 82 20 56
009ae0   04 07 1a 6e 61 b2 2a 79 00 29 2b 6e 44 1a 61 d3
009af0   30 08 2a f9 18 36 4e 8e 61 58 04 71 39 8d 67 01
009b00   0c 26 56 e6 79 57 e0 b2 00 0a 11 0d ce e0 0f 1d
009b10   a5 4e 50 00 e1 97 00 00 01 21 11 8e c0 c1 97 5b
009b20   19 12 00 a9 0a 11 18 61 b3 10 d1 1b 01 0f 21 54
009b30   b8 60 02 45 53 53 4c 34 08 1a 69 45 40 45 4b 64
009b40   01 30 fa 5e 65 c8 a5 0a 11 13 4b ad 48 b3 08 71
009b50   3b 25 d0 a5 a0 8e 65 0a 0c 19 57 b2 17 c1 2c 20
009b60   48 d9 21 a5 fc a5 bb e0 15 1d 3a 12 11 0c 00 b0
009b70   b2 0e 5c 34 d9 96 a5 bb 9b 02 41 8e 0c 5e 0a 0c
009b80   13 5a 0b 11 13 e0 0f 1d a5 4e 50 00 e1 97 00 00
009b90   01 ad 48 b3 05 a3 7e 2e e4 b2 41 8e 08 65 b2 04
009ba0   39 52 e8 34 b8 60 0d 28 d9 03 66 56 97 3b ea 60
009bb0   01 01 06 4d 31 2b 05 c8 a5 bb e0 1f 3d 84 11 00
009bc0   b8 e0 2f 1b c5 7b 00 ad 00 bb b0 41 5b 1f 67 b3
009bd0   0e 12 1a 7e 00 36 18 15 19 d7 16 a0 11 34 4c b8
009be0   64 19 2a 31 02 4a 04 64 38 b8 46 20 31 59 01 d9
009bf0   16 45 c8 b2 41 5b 15 7b e0 0f 1d a5 4e 50 00 e1
009c00   97 00 00 00 0a 11 13 60 0c 11 13 0b 11 0d b2 04
009c10   2b 44 d2 28 01 15 5d 65 d3 33 4e 61 aa a4 b2 bb
009c20   e0 3f 3d 8d 00 b8 ad 48 b3 0a 31 39 8d 65 49 96
009c30   45 41 5b 13 4f 4a 8e 1a 4b e0 19 1d 3a 19 8e 11
009c40   00 b0 41 5b 2e 40 ad 48 0a 11 13 49 b3 1f 57 4d
009c50   d3 b0 b2 b3 53 59 96 45 01 00 00 41 01 06 40 26
009c60   11 83 40 0a 11 13 40 e0 1f 1b b8 32 00 a0 00 c0
009c70   e0 0f 1d a5 4e 50 00 e1 97 00 00 00 0c 11 13 b2
009c80   07 8c 6b 19 00 29 71 d3 24 07 46 9c 60 14 6b 20
009c90   04 88 1a 69 45 58 96 85 bb e0 3f 3d 8d 00 b8 00
009ca0   02 00 00 00 00 9e 71 02 0b 11 0d 4f 02 00 01 e0
009cb0   0b 1d 9b 4e 50 01 00 e1 97 00 00 01 e0 1a 3c fa
009cc0   11 02 01 00 a0 01 c0 54 02 04 71 ab 71 00 01 00
009cd0   00 41 01 03 00 c9 b2 04 41 36 9a 67 0e 25 40 18
009ce0   01 39 86 65 40 3a 78 22 ee 1d 49 04 65 64 86 1c
009cf0   d3 24 5b 36 95 28 06 46 20 79 40 71 b4 01 53 65
009d00   57 00 35 16 85 64 01 05 86 65 40 04 b4 55 53 14
009d10   c1 6c 07 2b d4 4d 20 05 03 13 0a 28 06 01 2a 62
009d20   91 1b 2e 52 61 0c 2b 18 15 3a 2a 00 29 48 d3 32
009d30   2a 24 07 51 2e 2b 00 06 c3 79 14 5e 6a 5c 2a 13
009d40   2d 53 58 1a 69 60 01 27 74 39 0a 60 23 44 d2 2a
009d50   79 3a 6c 03 14 49 40 35 c9 2a 9a 60 0b 1b 2a 04
009d60   63 10 48 35 46 5d 25 c8 a5 a0 91 40 a0 68 40 b2
009d70   00 21 30 d9 28 01 14 e6 5e ea 24 07 78 0a 6d d1
009d80   03 15 3a ee 67 01 0f 8d 50 0f 29 57 00 d9 00 24
009d90   1b 39 2a 55 67 00 05 95 1b 18 96 45 b0 41 01 01
009da0   01 7a 41 5b 30 7a a0 91 c6 ad 79 bb b0 e0 1f 3d
009db0   69 3a 00 a0 00 d7 e0 1f 3d 69 4b 00 a0 00 ce e0
009dc0   1f 3d 69 11 00 a0 00 c5 ad 18 b0 b3 07 c2 45 56
009dd0   69 d5 55 49 00 4a 0d 2a 76 97 21 d8 c8 b2 a0 91
009de0   00 ac 41 5b 52 00 a7 41 4b 3a 00 a2 0d 42 01 e0
009df0   07 1d 9b 50 0e 06 00 e1 97 00 00 01 b2 07 89 29
009e00   55 02 aa 1a 20 3b 18 69 58 00 32 04 07 2a 31 05
009e10   41 07 97 19 d9 37 00 63 34 54 0f 29 57 3a 6c 00
009e20   26 0d 2a 76 b7 2b 18 38 5b 05 31 52 6c 17 8b 52
009e30   ec 53 39 2a 60 65 57 5e 97 03 26 41 58 03 0d 1a
009e40   aa 00 5b 65 aa 3a e0 1b 0d 2a 60 2c c8 2b 05 c8
009e50   a5 26 11 83 77 2e 11 10 0c 11 13 e0 0f 1d a5 4e
009e60   50 00 e1 97 00 00 00 b3 00 6d 04 88 52 6b 6b 0e
009e70   52 61 0c 20 0f 29 5e 95 00 2c 04 02 54 05 78 26
009e80   65 aa 78 01 36 9a 64 bf 96 45 bb b0 a0 8c c0 41
009e90   5b 4f 40 41 4b 4b 40 a0 91 40 99 95 0d 91 01 e0
009ea0   0f 1d a5 50 3d 00 e1 97 00 00 00 b3 04 35 5c de
009eb0   2a e0 5d 5b 2a e7 2a e6 65 58 00 36 18 09 28 cb
009ec0   2a 6e 4d 80 22 93 2f 58 3a 93 05 44 1b 00 04 11
009ed0   1b 19 03 94 5d 20 2c c9 2b 01 0c c0 35 46 5f 25
009ee0   73 19 52 b5 3a 6c 03 08 5d 46 48 0b 3a 31 60 01
009ef0   01 06 6d 57 4c 23 04 c1 03 15 3a ee 67 01 0f 0a
009f00   4f 0e 4d 80 18 0c 5d 46 65 57 02 b4 71 57 04 6b
009f10   45 4a 00 34 04 1c 1a 31 e0 b2 41 01 06 40 a0 42
009f20   c0 26 11 83 40 0a 11 13 40 a0 8c 40 0d 8c 01 e0
009f30   0f 1d a5 50 0e 00 e1 97 00 00 00 e0 07 1d 9b 50
009f40   3d 03 00 e1 97 00 00 01 b3 04 2b 44 d2 2b 00 2e
009f50   2e 22 0a 5c 1c 3a 29 47 c0 04 c1 01 46 5f 2d 03
009f60   37 2a 47 45 58 00 ea 4d 46 65 a0 04 8b 29 59 05
009f70   41 07 15 3a ee 67 00 22 9c 2a e0 1b 20 04 9a 4d
009f80   46 5f 2d 47 c0 56 9c 2a e5 c8 a5 00 00 41 5b 1d
009f90   49 e0 1f 3a e3 15 00 b8 b3 04 2c 1b 2a 00 25 56
009fa0   f4 65 48 65 49 00 fe 00 69 3a 7b 3b 0e 1e 2a 01
009fb0   74 5d 0a 05 42 1a 46 41 58 00 24 65 4a 65 a0 19
009fc0   0d 28 01 33 34 69 0d 01 d9 96 45 00 00 41 5b 54
009fd0   61 b2 04 38 55 d7 3b 38 01 ea 2a e0 46 9a 26 3e
009fe0   00 26 39 93 52 ea 03 d4 e8 b2 bb 0d 2d 00 ab 2d
009ff0   41 5b 30 45 ad 18 b0 c1 97 5b 24 14 40 41 4b 95
00a000   40 ad 50 b3 1b 39 19 10 00 c0 62 ae 5d d9 00 2b
00a010   48 d9 2a ee 1a 20 50 ef 29 19 e0 b4 00 a0 8c 00
00a020   55 41 10 1d 00 50 b2 04 39 2a 78 38 5b 05 22 49
00a030   0a 5d 52 52 7e 00 25 1e f4 41 53 04 61 18 20 72
00a040   e6 3b 2d 60 23 1a 5a 61 49 00 50 61 a6 41 53 00
00a050   d9 00 24 22 3a 4b 1e 00 d9 65 52 57 21 0e ea 63
00a060   52 28 19 35 4e 5c 0d 39 2a 53 58 01 ea 2a ee 4d
00a070   85 c8 a5 bb 0d 42 00 ab 42 00 00 0d 8c 00 e0 3f
00a080   50 0e 00 b8 00 41 5b 49 47 b3 13 da c0 b4 c1 95
00a090   5b 14 19 24 40 e0 0f 37 52 5c ea 00 b8 00 00 41
00a0a0   5b 25 49 e0 1f 2b fa 51 00 b1 41 5b 49 40 06 7b
00a0b0   1e c0 06 51 7b 40 0e 7b 1e b3 10 d8 00 28 64 d0
00a0c0   28 01 00 fa 53 c1 0c 28 4e 99 39 0a 03 14 49 59
00a0d0   35 d3 30 14 25 20 0a c1 01 6a 2a 20 05 2e e4 b2
00a0e0   00 41 5b 26 40 41 8e 5b 40 05 41 03 56 cd 4f 41
00a0f0   ff ff 26 58 10 45 0b 58 0e e0 0f 37 52 5d 0d 00
00a100   b8 41 41 03 5f 0a 58 0e 40 0d 8a 58 0c 58 0e b3
00a110   04 58 56 99 00 c0 61 06 5c c7 00 36 04 18 1a 69
00a120   96 45 6f 38 41 00 ad 00 bb b0 01 00 00 41 01 03
00a130   40 b2 04 41 36 6a 1a e0 04 19 52 a0 05 24 1a e6
00a140   30 c1 58 8b 1a 31 60 2a 04 34 4e 3e 02 a6 65 a0
00a150   09 83 3c 2a 87 85 a0 75 ca b2 62 91 b9 25 8c 00
00a160   09 b2 1d 46 6b 2e af 51 b2 00 74 62 a6 4f 00 04
00a170   0b 1a 31 60 01 30 20 71 58 e4 b2 b0 00 41 5b 13
00a180   00 5d 41 8e a3 00 58 41 4b 0d 4a e0 17 1d 3a 1d
00a190   a3 00 b0 41 4b 8f 4f b3 12 ea 19 20 04 19 0d 31
00a1a0   18 ea c4 b4 4a 4b 1a 5d b2 04 28 6a f7 2a 79 03
00a1b0   1c 29 55 60 0e 64 06 70 de 96 45 bb e0 2f 3d 84
00a1c0   4b 00 b8 b2 84 25 aa 4b b2 03 0e 4e 18 00 3f 04
00a1d0   1c 1b 2a dc b2 bb e0 2f 3d 84 4b 00 b8 c1 97 5b
00a1e0   1d 38 40 b3 04 37 3b 6a 5c 01 17 8e 25 40 04 c9
00a1f0   1a 6c 2a f4 6b 01 0c 2b 63 8e 2f 20 23 57 5d 53
00a200   67 00 04 cd 39 29 2a 60 5e 88 43 01 28 22 25 48
00a210   39 2a 00 2c 2e 97 32 80 04 98 71 d2 96 45 01 00
00a220   00 c1 95 10 1a 75 20 cf e0 0f 1d a5 51 0f 00 e1
00a230   97 00 00 00 b0 e0 2b 51 4b 10 44 01 a0 01 f6 e0
00a240   2b 51 4b 10 43 00 e0 0b 1d 9b 51 0f 00 00 e1 97
00a250   00 00 01 b2 04 28 6a f7 2a 79 01 06 5e ee 2b 00
00a260   05 09 53 93 63 37 28 d2 96 45 bb bb e0 2f 3a 4e
00a270   01 00 b8 e0 0f 37 52 5e 7c 00 b8 00 02 00 00 00
00a280   00 e0 2b 51 4b 10 01 02 a0 02 c0 e0 2f 3a 4e 02
00a290   00 a0 00 41 9b 02 04 00 00 00 00 00 00 00 00 4f
00a2a0   02 00 04 25 03 04 c0 6f 02 03 00 61 00 01 3f f5
00a2b0   61 03 04 c0 54 03 01 00 6f 02 00 00 b8 00 01 00
00a2c0   00 41 01 03 40 a0 1b fa b2 04 41 34 5b 71 a6 64
00a2d0   1a 61 49 00 2c 09 06 00 2e 44 d0 28 23 0a 01 60
00a2e0   25 0f e6 00 2e 4b 49 02 ae 45 41 28 27 05 a5 67
00a2f0   0d 52 ea 60 b9 00 2c 04 02 74 26 0d c5 c8 a5 b0
00a300   b2 04 41 34 5b 04 11 1a 0a 00 2b 1d 46 21 aa 60
00a310   01 30 20 0b a1 18 53 04 c6 01 26 48 01 30 20 28
00a320   d8 e4 b2 b0 00 c1 97 5b 1d 5b 4a e0 17 1d 3a 18
00a330   7c 00 b0 41 5b 20 40 e0 3f 35 a9 00 b8 00 00 a0
00a340   1b d1 b3 04 31 1a 0a 17 18 01 94 4d 45 48 b2 96
00a350   45 c1 97 5b 1d 20 40 e0 17 1d 3a 18 7c 00 b0 00
00a360   00 e0 13 3d 9d a6 5c b0 00 b8 01 00 00 41 01 03
00a370   40 b2 04 41 34 36 20 db 2a f3 00 2c 04 02 f4 29
00a380   a0 1b c7 ad 15 8c 00 09 b2 18 01 3a 26 c1 45 b2
00a390   05 41 73 11 3a 5e 03 19 19 d7 70 de 01 11 3a 47
00a3a0   60 01 30 20 0d e5 c8 a5 b0 00 00 c1 95 5b 1a 1b
00a3b0   1d ca 41 5b 13 5a 41 4b 0d 56 41 10 16 48 e8 7f
00a3c0   1d 8c 00 05 e8 7f 16 e0 2f 3a e3 00 00 b8 41 5b
00a3d0   13 40 41 8e a8 40 4a 4b 11 40 b2 84 25 aa 4b b2
00a3e0   01 2e 60 58 07 e1 03 11 39 2a 96 45 bb 41 4b 7c
00a3f0   49 e0 1f 3d 84 7c 00 b8 4e 4b 16 b0 01 00 00 41
00a400   01 03 5a b2 04 41 34 36 18 01 64 3a 05 6a 75 d9
00a410   60 01 30 20 0c 21 18 6e 96 45 b0 41 01 06 40 a0
00a420   68 40 93 9b 00 c1 ab 00 83 10 c0 bb e0 3f 52 60
00a430   00 b8 01 00 00 93 9b 00 c1 ab 00 83 10 6b b3 0d
00a440   a1 01 14 5e 6a 5c 01 24 20 21 4e 45 d3 30 23 18
00a450   01 3b 66 4a ae 5d 40 1c d9 00 25 36 91 25 d3 30
00a460   02 7e 74 61 45 c8 a5 b3 07 81 3b 66 4a ae 5d 40
00a470   1c d9 03 1c 52 95 60 09 53 93 00 d9 03 d4 e8 b4
00a480   00 41 5b 54 4d e0 1f 52 78 06 00 0d 2d 00 ab 2d
00a490   c1 95 5b 24 14 49 40 93 9b 00 c1 ab 00 83 10 5b
00a4a0   ad 50 b3 5d 46 21 a0 35 d2 14 c1 6c 0d 28 b8 60
00a4b0   02 6c 20 21 4e 45 d3 b0 b2 e0 3f 52 60 00 b8 00
00a4c0   00 e0 1f 52 78 04 00 b2 04 27 1b 20 32 e6 1f 00
00a4d0   05 01 1a 2e 2f 38 00 28 1b 86 78 b2 16 45 c8 a5
00a4e0   bb bb e0 2f 1b c5 7a 00 e0 2f 3a 4e 00 00 b8 00
00a4f0   01 00 00 04 01 01 cf b2 00 00 00 8b 71 4a d4 b4
00a500   bb 8c ff f1 bb b0 00 41 5b 45 56 a0 64 c8 e8 7f
00a510   43 8c 00 05 e8 7f 4e e0 27 1d 3a 00 7f 00 b0 41
00a520   5b 4e 70 a0 64 c5 ad 73 b0 0e 7f b2 0d 64 01 b2
00a530   04 27 1b 10 2b 20 04 b7 19 d8 29 20 05 81 03 34
00a540   54 01 24 20 61 a6 2f 25 c8 a5 bb e0 3f 3d 8d 00
00a550   b8 41 5b 43 72 a0 64 45 ad 73 b0 0e 7f 79 0d 64
00a560   00 b2 04 27 1b 10 2b 20 04 b1 53 8a 5d 49 00 2c
00a570   04 07 53 39 52 40 05 21 03 0d 19 79 96 45 bb e0
00a580   3f 3d 8d 00 b8 41 5b 49 40 41 4b 7f 40 e0 13 3d
00a590   e3 7f 59 47 00 b8 00 41 5b 49 4f b3 04 28 34 c1
00a5a0   58 25 61 48 6a ea 96 45 c1 95 5b 45 43 4e 4a e0
00a5b0   27 1d 3a 5b 7f 00 b0 41 5b 2e 40 26 7f 10 40 11
00a5c0   7f 0e 00 ad 00 bb b0 00 01 00 00 41 01 06 40 e0
00a5d0   1f 3d 69 11 00 a0 00 c6 0a 11 13 dc e0 1f 3d 69
00a5e0   08 00 a0 00 c6 0a 08 13 cf e0 1f 3d 69 0c 00 a0
00a5f0   00 c0 0a 0c 13 40 e0 0f 37 52 64 c9 00 b8 00 41
00a600   5b 17 57 b3 04 e1 14 6a 4b 48 34 0c 1b 00 05 87
00a610   46 9c 00 dc 1b c5 c8 a5 41 5b 59 40 b3 08 d8 49
00a620   51 47 00 45 d0 28 08 50 d1 01 86 60 01 58 35 96
00a630   45 00 00 41 5b 1a 40 e0 1f 3a e3 17 00 b8 02 00
00a640   00 00 00 41 01 01 40 a2 83 02 c2 0d 7d 01 a0 02
00a650   cf e0 2f 3a 3c 02 00 43 00 04 57 0d 7d 00 41 10
00a660   79 40 a0 36 c0 a0 33 40 0d 33 01 54 11 0a 11 b1
00a670   a1 02 02 bf db 8c ff d8 01 00 00 41 01 03 40 b2
00a680   05 e1 14 c0 21 ae 46 3e 00 3a 71 b4 61 40 62 91
00a690   28 0a 75 d9 00 25 05 81 00 6f 05 43 34 7e 22 97
00a6a0   4d 57 00 25 18 12 19 0d 3a 6a 04 77 2a 4e 4d d8
00a6b0   21 53 64 01 24 c0 22 34 65 aa 60 09 5f ca 5c 23
00a6c0   05 66 03 1c 3b 28 34 11 18 ea 46 2a 24 05 64 98
00a6d0   13 24 18 97 13 25 64 2a 04 38 71 d9 21 a0 26 8a
00a6e0   60 02 44 d5 55 46 5c 01 30 48 48 d3 3a ba 44 c7
00a6f0   45 40 1f c0 1a 7e 01 ba 48 69 34 26 17 da 4e 2a
00a700   63 00 04 0b 3a 6c 2a f8 00 2d 0a c5 24 ba 15 25
00a710   38 07 78 05 24 ba 15 80 3a 68 34 bf 05 41 06 46
00a720   21 ae 4d 40 0d 66 00 2e 45 c9 04 61 e0 25 0a 8e
00a730   0a 48 b2 52 aa cc b2 b0 b2 07 65 c8 a5 b0 00 41
00a740   5b 12 40 a0 8e 53 ad 50 b3 26 80 3b 20 05 61 10
00a750   e1 35 a6 4d 38 96 45 e0 16 1d 3a 46 47 8e 00 b0
00a760   01 00 00 41 5b 46 40 41 8e 50 00 70 0a 8e 0a 45
00a770   ad 87 b0 92 8e 01 c2 e0 15 3f 58 8e 47 00 00 06
00a780   2c 47 48 0e 85 8e 8c 00 08 a0 01 c5 0e 3b 8e b3
00a790   04 32 19 0d 3a 6a 02 b7 51 3a 21 58 00 c0 24 df
00a7a0   7e 2e 4d 80 25 d8 56 26 78 01 25 14 46 97 29 20
00a7b0   45 cc 37 38 00 26 1d df 1a f7 28 13 51 d8 2b 01
00a7c0   28 3c 4a 92 2a 79 02 26 65 57 04 61 01 5d 21 d9
00a7d0   2a 4a 4f 20 18 e6 65 58 96 45 b2 08 c2 50 31 98
00a7e0   05 aa 8e b3 00 4d 26 85 c8 a5 00 99 3b b3 04 2e
00a7f0   4f 1a 1f 19 1a 79 38 d1 03 11 19 80 22 fa 48 f1
00a800   2b 00 1b 20 04 99 53 48 b4 b2 00 e0 13 3d 9d 42
00a810   5d 44 00 b8 00 41 5b 49 00 3f 26 a4 83 7b b2 10
00a820   d8 00 28 66 9a 21 a0 04 17 6b 19 78 10 4d cb 28
00a830   23 04 98 72 97 24 0c 3b 6a 60 06 03 0e 4d 91 28
00a840   15 6a 38 28 01 24 f1 3a 69 3a 6c 00 f1 69 40 45
00a850   cc 37 25 c8 a5 bb b1 41 8e a9 46 41 5b 14 cd 41
00a860   5b 5c 40 41 4b a9 40 a0 8e c0 99 a9 e0 0f 37 52
00a870   5d 53 00 b8 00 c1 95 5b 45 53 49 d0 c1 95 5b 43
00a880   4e 4d c9 c1 95 5b 3b 39 14 40 e0 25 3f 58 10 63
00a890   01 00 e0 15 3f 58 1e 63 01 00 b3 07 8c 36 98 64
00a8a0   06 56 aa 1a f8 04 66 56 a6 46 2a 24 06 64 01 11
00a8b0   2a 61 48 5c d9 38 5b 05 21 02 ea 48 ce 4f 00 05
00a8c0   26 01 6a 46 34 70 06 27 6a 4f 3a 5d 57 05 44 35
00a8d0   40 23 57 61 58 00 24 6c d1 68 c7 45 58 00 26 1c
00a8e0   d3 3b 0d 2b 00 65 aa 48 01 30 8d 19 2a 60 2a 04
00a8f0   2c 36 98 64 11 28 db 2b 01 0e 5a 67 2a 5d d3 30
00a900   14 1f 08 2a 6e 65 ca e0 b2 00 01 00 00 41 01 02
00a910   46 0c 15 0e b0 41 01 03 40 b2 04 41 34 36 18 01
00a920   6a 8b 2c 01 02 46 7d 41 0c 38 45 ca 60 01 30 20
00a930   0b 41 28 86 1e 9b 28 01 20 25 98 a5 0a 15 0a 5a
00a940   b2 4c 14 55 53 00 42 05 78 6a 71 39 8d 64 15 53
00a950   57 3a 6c 01 d3 96 45 b0 a0 23 cc b2 01 97 1b 2e
00a960   4d 85 c8 a5 b0 b2 00 42 46 88 41 49 00 2b 18 18
00a970   43 51 44 bc 1a 69 17 88 5e 98 60 f4 4d 58 02 34
00a980   22 05 c8 a5 b0 00 00 41 5b 25 4f 41 8e 41 4b e0
00a990   15 1d 3a 61 15 41 00 b0 c1 97 5b 61 3f 51 41 10
00a9a0   77 4d ad 50 b3 06 42 4b 0e 25 45 c8 a5 41 5b 3f
00a9b0   4c 0d 23 00 b3 12 34 22 0a a4 b2 41 5b 61 62 41
00a9c0   4b 15 5e 41 8e 41 4e 0d 23 01 b3 13 53 46 88 41
00a9d0   49 96 45 b2 0e 46 80 a5 aa 8e b3 16 85 d4 b4 41
00a9e0   5b 48 51 b3 04 4d 1b 6a 4c b8 64 01 03 10 3a 31
00a9f0   96 45 c1 97 5b 1e 25 00 52 a0 23 80 43 e0 10 3d
00aa00   f4 15 5d 01 5d 05 00 0a 15 0a 71 0b 9a 13 41 10
00aa10   77 c1 a0 84 41 0d 84 01 2e 6c 10 b3 07 95 3a 2a
00aa20   00 29 45 46 6d 58 01 66 46 38 02 93 05 81 11 aa
00aa30   19 20 04 c1 30 20 0a a5 c8 a5 0c 9a 13 b0 b3 04
00aa40   22 08 25 46 88 41 49 96 45 41 5b 13 40 41 8e 15
00aa50   40 b3 08 c2 35 6e 64 01 50 20 32 e6 65 d3 b0 b2
00aa60   01 00 00 41 01 03 5d b2 05 e1 68 6b 18 03 3c 5c
00aa70   2b ae 64 01 18 c0 0f 83 5f 55 85 45 e0 3f 56 77
00aa80   00 b8 41 01 02 40 a0 92 c1 e0 0f 1d a5 57 0c 00
00aa90   e1 97 00 00 01 b0 00 41 83 89 00 3d a0 16 d1 b3
00aaa0   11 aa 17 18 01 66 63 20 1b 11 29 55 96 45 41 5b
00aab0   47 4c 0d 83 1e e0 1f 1d 3a 47 00 b0 b3 11 aa 17
00aac0   18 00 51 4b 48 34 01 24 c0 22 93 6d 57 60 d9 3a
00aad0   93 1a 2e 63 25 c8 a5 41 5b 2e 49 e0 3f 56 77 00
00aae0   bb b0 a0 16 80 44 c1 95 5b 14 39 64 d0 c1 97 5b
00aaf0   24 19 ca 41 5b 60 40 41 8e 2a 40 b2 04 21 43 c6
00ab00   72 78 00 26 63 26 5d 58 00 d9 00 20 65 ae 4d 80
00ab10   06 3c 52 0a 01 ae 48 1a d4 b2 bb 0d 16 00 42 92
00ab20   00 40 35 00 92 92 ab 92 41 5b 34 01 21 41 8e 89
00ab30   01 1c 41 4b 0a 00 79 e0 03 1d 9b 57 0c ff ff 00
00ab40   e1 97 00 00 01 c3 8f 92 ff ff 40 99 0a 35 00 92
00ab50   00 c2 2f ff ff 00 4a cd 4f 92 ff ff 8c 00 06 35
00ab60   00 92 92 b3 04 21 43 06 7b 01 0c b9 13 da 48 23
00ab70   06 32 19 2a 02 4a 03 2d 3a f8 67 c1 28 95 2a ed
00ab80   1a b8 00 8e 01 14 6a 29 01 37 3a 70 00 20 1e 34
00ab90   51 20 05 21 47 2d 3a 6c 16 45 64 02 18 58 06 24
00aba0   78 94 13 40 05 a5 64 31 65 ae 4d 85 c8 b9 41 4b
00abb0   7c cc 41 4b 61 00 71 06 7c 61 00 6c 42 92 00 00
00abc0   4e e0 1f 3d 84 7c 00 2e 61 10 0b 61 0a 0d 16 01
00abd0   b3 04 21 41 52 57 2e 2b 00 04 07 53 39 45 41 0f
00abe0   c6 72 78 04 61 19 66 46 38 01 66 63 20 1b 11 29
00abf0   55 05 45 78 9c 34 d9 01 2e 24 01 22 ba 64 01 58
00ac00   31 26 ee 4e 01 0c d3 7b 86 78 b5 97 e5 ad 6c b3
00ac10   4c b8 64 19 35 d7 63 3e 00 26 5d 4b 6b 0a 60 01
00ac20   12 8b 2d 57 96 45 41 4b 9b 55 ad 6c b3 4c b8 64
00ac30   04 64 8d 10 c4 64 0d 6a 6c 5f c5 c8 a5 b3 04 21
00ac40   40 4d 28 d9 00 99 11 a4 18 99 96 85 c1 95 5b 24
00ac50   14 5d 00 63 e0 03 1d 9b 57 0c ff ff 00 e1 97 00
00ac60   00 01 41 5b 24 73 b3 17 24 26 80 05 19 35 d3 40
00ac70   04 38 b8 48 06 60 18 67 55 39 20 1b 00 4b c0 2c
00ac80   d9 35 57 03 86 60 b5 17 21 0d aa 03 06 7b 01 0d
00ac90   34 25 8e 4d 85 c8 a5 41 5b 5d 45 6e 4b 10 b3 04
00aca0   21 41 cc 4e 97 2b 00 04 95 3b 2e 2f 51 00 d9 65
00acb0   52 57 25 c8 a5 41 5b 5f 5d b3 04 42 3f 2e 28 0d
00acc0   3a 41 0f 2d 53 4c 34 0d 28 01 15 6e 64 01 30 48
00acd0   65 ca a4 b2 41 5b 3e 40 b3 04 43 11 aa 1a e0 0b
00ace0   f8 66 92 19 0d 02 fa 48 f1 3a 6c 96 45 00 00 a0
00acf0   5c de b2 04 23 07 86 46 20 0d 66 00 63 17 98 3b
00ad00   ea 24 14 55 53 3a 6c 00 36 3b 25 c8 a5 b0 a0 16
00ad10   e2 b2 04 21 43 11 29 55 60 07 45 d8 61 7a 46 3e
00ad20   00 d9 00 20 2e 94 64 01 24 20 63 26 3a f8 96 45
00ad30   b0 a0 92 00 54 b2 07 8d 6a 6c 5f c0 06 07 46 88
00ad40   43 00 04 18 64 ce 5d 06 61 41 28 8b 5e 92 00 20
00ad50   1e 34 51 38 64 ce 4f 00 0b 61 03 86 46 38 04 61
00ad60   21 86 65 aa 5c 01 45 aa 00 25 0a 3b 2a fe 01 77
00ad70   39 53 26 3e 04 79 36 9a 31 a0 35 40 45 d0 2b 00
00ad80   55 54 56 2a 96 45 b0 43 92 00 00 44 ad 6c b2 01
00ad90   5e 29 d3 30 01 21 11 53 0a 47 c1 28 8e 00 59 65
00ada0   ae 4e 00 35 40 45 d0 2b 00 05 1b 2a fe 02 5a 21
00adb0   a1 28 8d 28 11 52 90 60 0a 77 37 2a 4a 47 c0 37
00adc0   53 32 fe 04 6a 6d 53 00 4a 18 03 8c b2 b0 42 92
00add0   00 40 b2 04 23 0c 23 34 db 3a 6c 01 46 65 53 00
00ade0   20 36 99 02 aa 56 aa 5f 01 0c 58 05 82 21 86 62
00adf0   ae 4d 81 28 8d 04 aa 4d 71 1a 4a 24 19 52 6c 69
00ae00   40 56 f4 66 fa 25 58 00 32 0b f2 1a 65 73 0e 7d
00ae10   49 02 54 6b 2d 96 45 b0 00 a0 16 41 a0 68 41 41
00ae20   10 38 cf e0 0f 1d a5 57 0c 00 e1 97 00 00 00 b0
00ae30   42 92 00 49 35 00 92 00 8c 00 05 e8 bf 92 43 00
00ae40   05 56 e0 0f 1d a5 57 0c 00 e1 97 00 00 00 e0 0f
00ae50   37 52 5c 30 00 b8 42 92 00 47 96 92 8c 00 04 95
00ae60   92 a0 16 40 ad 6c 42 92 00 49 35 00 92 00 8c 00
00ae70   05 e8 bf 92 55 00 01 00 6f 31 00 00 ad 00 bb b0
00ae80   01 00 00 41 01 02 40 e0 0f 1d a5 3e 88 00 4f 00
00ae90   00 00 41 00 01 40 a0 68 40 0c 70 0e 26 70 10 c0
00aea0   2e 70 10 e0 03 1d 9b 41 f5 ff ff 00 e1 97 00 00
00aeb0   01 b3 04 4d 28 d7 00 c0 61 17 28 d2 00 29 1a 6c
00aec0   69 d8 34 06 60 01 02 f4 1c ea 5c 17 6b 0d 2b 00
00aed0   05 89 29 6a 4d 20 0b ed 39 2a 1b 86 f8 b2 00 c1
00aee0   97 5b 1e 25 40 b3 11 ba b4 b5 00 6b 4e 80 29 6b
00aef0   a9 19 04 41 4d 53 65 57 29 20 18 18 64 7e 1c d7
00af00   5e 9c 05 41 04 62 22 34 61 58 00 ea 35 d3 24 1e
00af10   53 41 0e 2a 1b 6e 4d 80 05 01 58 78 04 62 40 cd
00af20   28 c9 00 25 18 07 5d cc 37 31 78 bc 45 d9 01 06
00af30   6d 57 4c 2a 11 71 50 d9 3a 6c 00 36 04 08 1b 6a
00af40   5e 60 04 a6 00 2e 61 cc 4c bd 00 b9 04 41 4d 14
00af50   4a b1 2b 2a 24 06 01 97 28 d9 00 26 55 57 3a 34
00af60   6b 00 19 3b 2a 79 6a ea 00 38 0d 79 2b 19 29 20
00af70   04 9c 3b 20 04 c8 53 57 19 8a 05 41 08 33 48 d8
00af80   65 57 29 20 04 0b 3a f8 64 15 1a f9 00 29 04 04
00af90   7c 94 12 e4 40 19 5d d1 51 9e 05 44 56 ea 54 2d
00afa0   7a 9a 5f 0a 45 60 09 43 25 5b 2a 60 32 ea 1b 2a
00afb0   5c 19 2b 19 16 85 64 a7 14 e1 04 9f 12 84 5c 90
00afc0   03 37 3a 34 33 c0 22 93 65 d3 69 58 00 2b 17 24
00afd0   7c 94 12 e4 40 04 38 8e 17 a0 04 24 71 df 1a e9
00afe0   00 29 11 77 50 f4 7f e5 64 01 18 b9 13 e4 50 97
00aff0   12 00 11 c4 38 8e 17 a0 04 24 27 53 31 42 6c 92
00b000   1b 19 2a e5 c8 b9 04 4d 1b 6a 4c b8 64 06 02 b7
00b010   1b ca 5c 01 25 8a 67 2e 4d 80 04 08 51 6b 06 c9
00b020   53 93 03 21 d4 b2 04 41 4d 53 65 57 29 20 04 04
00b030   44 26 05 21 00 91 3b 6e 4d 80 11 2a 19 21 28 99
00b040   36 9a 60 d3 27 00 05 31 53 19 03 14 6a 38 00 64
00b050   09 0d 28 d7 24 1c 29 55 3a 6c 00 26 4a 86 4d d3
00b060   30 2a 0d a6 01 14 5e 6a 5c 01 34 20 5d 52 19 d3
00b070   60 01 26 b7 2b 6e 53 58 00 c9 6d 53 67 57 2a f8
00b080   02 2a 63 00 2e 97 67 53 1b 2a 03 2d 0d 3e 53 57
00b090   61 51 2c 2a 07 82 5d 5d 3b 38 00 2c 04 03 bc b2
00b0a0   10 d3 02 91 24 11 28 d9 35 57 00 e6 30 23 1f 51
00b0b0   31 d3 30 01 2d 14 3a 78 04 61 14 35 96 45 16 45
00b0c0   9c a5 12 74 65 ae 4d 80 34 d5 55 53 60 b2 94 e5
00b0d0   12 a6 65 b8 02 2a 19 20 07 e1 01 74 5d 58 64 01
00b0e0   30 20 0b 81 18 6f 71 58 64 2a 10 d1 62 81 0c c0
00b0f0   71 51 44 bc 48 d7 41 49 02 a6 65 a0 2b b9 2a 69
00b100   60 0a 1b 19 96 45 17 24 2e 34 51 20 11 14 4f 37
00b110   52 20 11 26 48 05 5c ab 03 86 60 08 52 78 66 fa
00b120   23 2a 24 01 58 af 16 05 2c 04 30 9a 11 40 05 66
00b130   01 97 1a 79 00 29 15 65 3c 12 3a 31 38 5b 7e 97
00b140   42 4e 27 00 06 44 46 97 24 04 25 d2 71 d9 00 8b
00b150   44 d9 35 46 24 01 00 8a 75 0a 63 0e 6d 41 28 2f
00b160   3a 55 5d 58 61 db 28 18 66 fa 23 3a 5d 40 04 a8
00b170   52 55 53 0a 24 01 24 ab 15 e5 20 b3 15 05 20 a8
00b180   01 1a 1d c8 00 60 05 28 52 68 5d 59 28 23 04 a5
00b190   28 ad 15 c0 0c 19 1a 31 00 26 15 25 44 ab 00 60
00b1a0   71 c9 28 b2 14 e5 1c 21 22 93 63 37 69 19 38 5b
00b1b0   05 24 2c 88 11 25 5c ab 03 34 52 00 15 25 24 aa
00b1c0   01 26 7b 00 06 42 54 07 5d 46 41 d3 30 01 31 2a
00b1d0   25 c8 1b 2e 52 61 28 46 5d 56 69 d7 29 20 18 1c
00b1e0   52 f0 01 74 5d 0a 00 29 15 65 40 ac 03 11 1b 6a
00b1f0   60 23 15 65 30 18 44 db 28 09 5d db 2a f8 04 61
00b200   18 a9 15 40 2a 6c 3a 6a 2a f8 04 65 28 ab 15 85
00b210   34 07 6a ea 1b 48 5c d9 60 23 04 d3 28 d7 47 c0
00b220   0f d2 3a 31 38 5b 25 46 24 19 5d 4a 60 b2 14 e5
00b230   1c 86 60 01 23 19 1a f9 00 24 66 9a 5c 23 4e 99
00b240   39 0a 00 20 4a 97 28 0e 4f 2a 5d 58 65 d3 30 0b
00b250   28 d9 6a ea 60 01 24 8b 11 04 24 b7 15 61 28 94
00b260   4c 01 12 ee 31 b9 16 45 c8 b2 12 8d 04 73 50 b4
00b270   00 22 06 7c 1a 30 29 20 07 e1 03 11 1b 6a 5d d3
00b280   30 0b 1a 6c 60 01 24 c0 0e ac 5f 4a 96 85 21 a6
00b290   ba 65 00 00 80 a5 12 93 00 20 0a a0 04 a6 02 ae
00b2a0   45 40 05 31 28 db 2b 05 c8 a5 10 d9 00 20 2a 69
00b2b0   00 29 04 03 50 25 18 15 53 20 05 2c 52 29 96 45
00b2c0   0e 4c 5d 46 64 0a 2d 74 5f 21 0c 28 52 aa 4c 01
00b2d0   03 8e 4d 34 70 0a 4e 9a 31 a0 05 86 46 34 70 0a
00b2e0   4f 37 f8 b2 12 93 00 20 64 c7 45 40 04 a3 25 51
00b2f0   52 6c 1b 2a 24 07 5e 9c 4c 18 19 10 04 78 49 51
00b300   45 d3 30 01 25 b4 64 15 2a b5 2a f8 96 45 12 93
00b310   00 20 2c d7 03 86 46 20 04 a6 02 a6 3a 79 3a 6c
00b320   00 29 6a 75 1a e6 46 2a 45 49 00 ea 1b 59 f8 b2
00b330   12 93 00 20 1a 39 1a e0 04 a6 00 2e 1e 26 22 00
00b340   1e 94 40 23 52 aa 4c 01 32 a6 31 40 15 a5 38 b1
00b350   96 45 12 93 00 20 67 94 01 53 27 00 05 21 00 d1
00b360   64 d7 00 2d 1f 57 4d d3 30 08 1a 69 45 58 96 45
00b370   10 d9 00 20 0c 2a 4d 20 05 22 48 4e 54 d8 60 cc
00b380   28 23 18 11 19 29 2a e0 09 9a 57 86 5d 21 28 5e
00b390   18 18 66 f4 4d 80 26 e6 2f 20 06 41 03 8a 63 21
00b3a0   0f 81 54 01 00 57 4c d7 5e 9c 60 0a 6d 53 01 7a
00b3b0   5f 2d 2a e5 c8 a5 00 76 09 58 52 4a 65 ae 4d 85
00b3c0   c8 a5 00 76 1b 20 05 01 19 37 52 91 3a 6c 96 45
00b3d0   00 26 25 5b 53 57 29 20 7a 9a 96 85 04 52 6b 19
00b3e0   02 aa 5d 74 5e 40 04 08 2a ea 4a 93 78 b2 94 e5
00b3f0   0c c3 44 48 18 0c 52 89 03 37 39 10 16 45 9c a5
00b400   04 26 75 40 22 e6 61 aa 60 03 68 20 5e 88 40 23
00b410   65 b7 53 8e 4d 80 62 a6 5e 18 96 85 04 26 75 40
00b420   1e 26 25 40 4d c8 43 00 04 98 39 2a 05 44 53 48
00b430   b4 b4 10 d3 00 dd 28 18 66 f4 41 40 48 d0 2b 00
00b440   18 09 29 55 03 94 6a 69 00 36 04 91 29 85 c8 a5
00b450   07 8d 53 20 55 55 55 57 03 06 4d 3c 39 0d 00 25
00b460   06 a5 c8 a5 1d 4c ba 65 13 8d 1b 20 18 08 52 68
00b470   2a b9 96 85 04 23 e4 2d 04 21 c1 d8 05 e1 14 c0
00b480   25 d2 47 c0 45 d9 01 74 5d 58 64 23 05 61 3b 37
00b490   29 58 00 d1 44 06 5e 9a 4d 25 c8 a5 05 e1 14 20
00b4a0   1b 39 39 01 28 21 52 71 78 0a 75 d9 00 25 04 18
00b4b0   64 ce 5f 86 78 09 53 93 96 45 05 fc 1b 00 52 68
00b4c0   28 03 24 d7 65 d8 64 b8 60 18 67 49 3a 81 28 21
00b4d0   70 d1 47 00 05 b8 56 26 67 2a 5d 49 00 2b 54 ce
00b4e0   4f 38 00 29 15 c5 44 09 39 6b 2a ea 4f 20 22 91
00b4f0   52 f8 05 44 66 80 04 02 70 25 18 09 52 97 70 de
00b500   00 be 1a 38 50 08 53 6a 5d 49 00 2b 54 ce 4f 25
00b510   7c 2a 07 89 1a f0 00 26 09 c8 35 d2 4d 5e 00 4c
00b520   6a a0 06 46 01 6e 5d 55 44 c8 28 a6 07 60 1a 39
00b530   36 9a 31 a0 05 12 39 8d 64 02 20 c7 45 40 05 8c
00b540   2b 20 6a a0 3b 21 0d d9 00 54 6a 71 3a 0a 47 c0
00b550   05 08 53 51 24 0c 2b 20 1c c8 40 09 53 93 96 45
00b560   05 e1 14 c0 07 21 68 2b 54 d8 60 cc 2b 00 05 81
00b570   01 46 63 21 0c 7d 04 c3 38 23 04 c6 01 74 5c ee
00b580   25 2e 4d 80 36 91 28 03 5f 8a 63 21 28 87 46 94
00b590   27 19 19 d3 60 01 19 2a 2a a0 61 17 1b 28 35 58
00b5a0   00 be 55 57 34 d5 60 12 19 2a 00 fe 00 69 1b aa
00b5b0   17 e0 48 d7 00 20 70 d1 47 05 c8 a5 05 e1 14 c0
00b5c0   21 d7 23 51 1a e0 07 41 2e a6 63 06 31 58 00 36
00b5d0   1a 31 01 2e 5d 48 65 d4 4f 01 28 98 2b 6a 5c d1
00b5e0   00 33 6a 6b 52 f9 6a 66 65 51 78 07 29 53 00 f1
00b5f0   51 10 29 20 1f c0 20 db 28 bc 3a 78 96 45 05 fc
00b600   1b 00 04 12 19 d3 65 53 1a 68 28 01 68 4a 11 71
00b610   52 89 00 88 52 79 5e 91 00 89 1a 40 16 e5 2c 2a
00b620   10 d5 54 d7 2a 79 47 c1 0c 20 07 43 2c ea 2a 60
00b630   5c d3 60 c8 41 49 04 62 2a 54 63 20 05 21 03 66
00b640   47 46 1e 2a 01 56 69 d5 49 53 64 01 15 94 4d 41
00b650   28 94 4c 03 7b 86 46 20 04 a6 01 97 53 55 00 29
00b660   1f 59 66 93 60 08 52 34 5d 49 03 ca 46 34 70 23
00b670   1e f4 72 61 0c 26 5d 49 05 41 06 93 47 c0 26 94
00b680   5f 86 78 01 14 5a 96 45 05 f1 52 90 60 11 3a 0a
00b690   00 69 11 4c 7a b9 38 69 66 92 1c 2a 07 98 64 ce
00b6a0   5c 06 61 0a 4d 38 00 2c 04 1c 2b 19 96 45 04 23
00b6b0   65 97 53 80 61 b4 5f 2a dc b2 04 23 64 2d 1d 48
00b6c0   52 4e 4d 80 5b 4e 65 40 61 b4 5f 25 c8 a5 04 23
00b6d0   64 4d 44 d8 64 11 52 6c 02 74 f0 b2 05 e1 14 c0
00b6e0   22 f4 52 0a 24 08 52 f7 39 34 5c 01 48 20 0d e1
00b6f0   0c 2b 2e 97 43 00 05 81 00 5a 00 26 0d c5 c8 a5
00b700   05 e1 14 c0 65 d3 78 08 1b 6a 00 2b 2a 79 5c d3
00b710   21 58 00 5c 04 c3 3c 23 04 c6 01 26 5e 01 0d 74
00b720   5c ee 25 2e 4d 80 0f 83 5d 34 72 65 c8 a5 05 e1
00b730   14 c0 60 d3 24 bc 2d d1 45 49 01 06 6d 40 71 b4
00b740   61 40 2b ae 64 01 14 2c 04 02 e8 b2 05 e1 65 0d
00b750   1a 47 2a e0 0b 01 30 33 1d 4a 4c 15 1a f9 00 29
00b760   18 08 50 d1 02 4e 4d 41 28 99 50 01 00 5c 04 c2
00b770   4c 2d 54 d8 60 cc 2b 01 0c 26 18 18 65 4a 54 12
00b780   2b 26 44 18 45 c9 28 19 71 d8 67 00 26 9c 4f 86
00b790   5d 25 c8 a5 05 e1 6b 12 2a 31 60 18 66 f4 4d 91
00b7a0   78 01 25 14 1a 20 30 d8 05 44 4c d7 5e 9c 03 3a
00b7b0   4e 6a 47 00 45 46 24 11 28 c9 00 61 04 c3 b8 b2
00b7c0   05 e1 14 c0 4e 93 25 58 22 ee 57 20 54 d7 64 01
00b7d0   24 c0 22 86 44 12 3a 6a 96 45 05 e1 14 c0 07 21
00b7e0   68 d9 00 20 1e 99 66 92 00 29 18 11 52 6c 03 0d
00b7f0   19 79 05 41 71 aa 1b 7e 01 d7 0b 68 34 c1 59 a6
00b800   4d 98 01 34 72 60 04 18 34 cb 64 2a 13 34 00 20
00b810   0a 61 14 c0 54 d8 60 cc 2b 86 78 01 18 2c 04 03
00b820   04 c0 6d 57 78 02 3a a6 63 06 31 45 c8 a5 05 e1
00b830   16 a6 5f 20 05 26 02 46 7d 40 05 39 71 d8 67 c0
00b840   45 d9 66 2a 02 a6 63 06 31 58 04 66 46 20 1a 2e
00b850   41 45 c8 a5 04 21 40 4d 45 59 00 28 54 d8 e4 b2
00b860   04 23 0c 23 65 d7 29 20 05 21 13 37 39 10 2a fe
00b870   04 6c 5c c7 60 01 21 6e 5e 51 78 2a 17 24 4a 52
00b880   05 44 3f 58 64 11 3a 0a 00 92 52 40 6b 0a 24 01
00b890   32 46 41 40 17 0a 48 b2 97 25 07 9b 1a 2e 1a 79
00b8a0   00 d9 65 52 57 25 c8 a5 04 23 08 25 1e 86 5d 2a
00b8b0   24 01 18 28 07 b7 2a 54 6d 40 04 07 50 d7 27 05
00b8c0   c8 a5 36 9a e1 45 04 23 08 25 4c ce 45 49 03 0d
00b8d0   6b 25 c8 a5 04 23 0a ea 47 48 64 d3 66 3e 02 95
00b8e0   2a 78 00 2c 5d 5b 28 d1 00 c0 5d c8 41 59 78 03
00b8f0   71 2a 61 0a 4d 2e 4d 80 07 e3 e0 b2 04 23 0b 1c
00b900   3a 6c 60 18 37 59 96 45 04 29 1a 40 1e 34 22 18
00b910   00 24 70 de 96 45 04 29 29 0a 1b 0a 24 06 27 6a
00b920   4f 3a 5d 57 17 18 03 58 2a 2a 63 00 44 d3 65 57
00b930   4c 01 14 35 96 45 04 2a 4d 97 1b 6e 4d 98 03 37
00b940   1a 78 44 d9 28 01 30 b9 05 f8 54 c8 28 0e 4f 2a
00b950   4f 2e 52 66 46 3e 02 2a 2f 20 1e 26 4e 05 c8 b9
00b960   3d 5c aa 38 04 58 36 9a 45 20 06 71 52 90 29 20
00b970   1d 4b 52 ea 00 28 45 46 55 49 96 45 04 2b 44 d9
00b980   00 29 04 19 5e 91 44 b8 60 06 75 40 62 0e 4f 00
00b990   19 17 53 18 00 24 2e 97 28 d7 c8 b2 04 58 29 52
00b9a0   00 2c 09 09 39 8c 3a 6c 00 c0 36 91 28 01 d4 b2
00b9b0   11 66 3a 2a 24 b2 94 e5 04 59 5f c0 05 86 61 0a
00b9c0   4d 20 04 17 1a 55 04 62 43 11 39 2a 00 e6 22 00
00b9d0   26 9c cc b2 07 9b 51 c8 28 07 52 92 60 01 48 20
00b9e0   0f 01 0c b9 08 29 3b 17 2b 15 29 19 01 14 63 38
00b9f0   00 28 04 91 39 6a 16 85 e4 a5 04 22 08 25 07 65
00ba00   c8 a5 04 22 0a 95 2a 78 96 45 04 22 09 11 53 0a
00ba10   e0 b2 07 c2 45 b4 45 2e cd 80 04 2d 52 2a 01 14
00ba20   46 26 57 0a 60 23 62 54 65 aa 5d d3 30 1e 53 45
00ba30   c8 a5 04 2d 52 2a 00 25 31 59 65 d3 30 09 29 55
00ba40   2a e1 0c 50 09 25 63 00 0a ce e4 b2 12 34 52 00
00ba50   1a f4 6a 69 03 d4 68 b2 94 e5 ba 65 12 ba 61 ae
00ba60   4d 80 84 05 10 ea 61 c9 28 01 20 5b 04 07 5c d3
00ba70   21 a0 04 a6 00 39 1d d7 24 b8 60 13 2b 19 96 45
00ba80   04 43 45 37 53 93 96 45 22 8e cf 05 10 ea 61 c9
00ba90   28 01 03 10 2a 2a 64 5b 04 a6 02 fa 63 3e 02 13
00baa0   39 6a 96 45 8a a5 04 30 4d cb 28 23 4a 9b 3a 6c
00bab0   00 2b 3b 38 02 9c 4c 0b 52 e8 28 23 62 34 72 3e
00bac0   03 3a 5e 78 00 24 34 d3 24 23 6a 79 3a 20 04 07
00bad0   44 c9 28 01 14 d9 00 24 4d 48 40 2a 04 30 4d cb
00bae0   28 02 50 2c 61 d3 30 06 60 0e 64 18 1b 66 31 51
00baf0   78 18 45 d9 60 01 13 2d 5e 86 e4 b2 00 cc 3b 26
00bb00   65 49 96 45 07 81 39 14 3a 20 05 37 52 aa 00 25
00bb10   47 ce 4d 80 06 c1 01 14 5e 6a dc b2 04 31 1a 55
00bb20   00 58 25 d2 49 57 96 45 04 31 1a 55 00 25 25 4b
00bb30   3a 6e 65 51 78 09 3a 52 2a e0 4e 9c 96 45 04 31
00bb40   1a 55 00 25 4d 46 5e 3e 02 9a e4 b2 07 99 5e 91
00bb50   44 23 1e e6 4d 2e 61 ae 4d 80 18 07 46 94 27 c0
00bb60   1b aa 04 67 46 88 43 00 1a 31 02 a6 63 06 31 58
00bb70   02 9a 64 01 24 20 5e 94 c8 b2 04 32 1a a0 61 b4
00bb80   73 00 18 0d 53 58 28 01 58 c0 2e 97 2b 19 01 11
00bb90   28 d7 3a 6c 05 44 61 5b 2a e6 44 15 1b 2d 60 11
00bba0   28 db 28 01 01 11 28 d7 3a 6c 14 c1 6c 14 4d 41
00bbb0   0c 77 0b 41 0c 25 48 d7 41 49 00 b9 13 34 00 98
00bbc0   64 7e 10 e6 5e f4 70 b9 96 45 06 e2 45 11 28 d7
00bbd0   03 8d 1b 20 7a 9a 17 17 28 17 29 6a 5e ee 4d 80
00bbe0   66 85 c8 a7 06 e3 29 26 5e 00 05 98 29 45 c8 a7
00bbf0   12 93 47 c0 13 06 4f 26 00 88 44 da 60 08 45 d2
00bc00   1f 00 26 9c 4c 08 35 d2 4d 5e e0 b2 17 c4 22 34
00bc10   61 40 22 9b 2a e0 1d 4b 52 ea 03 19 5d d0 3a 6c
00bc20   16 45 fc a5 06 e6 02 34 4d 80 70 de 16 45 c8 b2
00bc30   11 77 52 40 04 08 34 c1 58 25 63 58 55 53 25 49
00bc40   00 c0 1c d8 41 59 96 45 04 34 4e 3e 03 6e 61 c7
00bc50   45 40 2b ae 64 01 15 34 72 60 18 18 64 ce 5d 06
00bc60   61 45 c8 a5 07 87 1b 39 2a fe 17 95 53 8a 5d 49
00bc70   00 f7 1b 18 02 26 4f 2a 5e 60 04 a2 6c 20 66 f4
00bc80   55 be 01 06 61 45 c8 a5 04 35 5c de 2a e0 04 a6
00bc90   02 ad 3a 2e 56 ae 20 03 68 39 3a 78 29 19 60 23
00bca0   18 f8 2a 79 17 92 3a 69 29 33 2b 18 04 61 18 20
00bcb0   55 c8 41 d3 30 1a 54 01 19 37 52 b5 3a 6c 00 29
00bcc0   07 34 1d ea 23 38 05 44 1a 31 01 5b 39 2a 4d 0a
00bcd0   01 d3 25 c8 1b 2a 60 01 44 20 1d 51 39 4b 60 01
00bce0   24 20 1a 68 39 53 64 04 7e 97 41 57 60 1c 2a ea
00bcf0   02 87 61 1a 5d 45 c8 a5 13 53 2e 97 67 53 1b 2a
00bd00   47 c1 0c 20 5c cb 64 15 5e 9b 39 2a 60 11 3b 39
00bd10   45 40 56 f4 65 48 65 c2 6c 32 04 07 53 51 25 57
00bd20   60 03 7a 4a 2b 38 00 d9 00 20 1e 99 66 92 00 29
00bd30   70 d9 2a eb 1a 31 60 2a 11 d3 22 3a 25 d3 30 02
00bd40   4a 93 a8 b2 12 0e 22 0e 4d 80 84 05 a5 45 04 37
00bd50   3b 6a 5c 09 2b 08 2a 69 60 01 54 01 7c c0 6c d1
00bd60   45 5e 05 41 04 2d 4e 80 44 d3 25 d3 33 00 0b 6a
00bd70   3b 2d 2a e0 61 b4 5d 41 28 6d 04 09 3b 19 1a 68
00bd80   28 06 01 66 3a 79 02 fa 48 f1 3a 6c 00 64 09 0d
00bd90   28 d7 a4 b2 07 98 41 51 2b 34 4c 23 0c e1 02 ea
00bda0   48 ce 4f 00 05 26 02 3a 22 11 2b 18 00 c9 6d 53
00bdb0   67 57 2a e1 0e 2e 2b 00 06 a5 c8 a5 00 45 4e 99
00bdc0   18 f1 78 0d 2a 35 af 51 04 38 65 d1 2b 21 31 71
00bdd0   1b 0d 2b 01 0c 26 1e 34 51 20 71 51 47 00 06 41
00bde0   12 2a b0 b2 04 38 65 d1 2b 21 31 86 61 aa 60 01
00bdf0   11 74 5d 4d 28 c9 04 61 18 f1 52 89 02 87 61 1a
00be00   5d 58 00 24 6d d8 3a 93 96 45 04 38 52 2e 24 bc
00be10   32 91 24 08 51 6b 06 da 61 49 00 4a 04 07 6a ee
00be20   1a 20 05 24 5c d2 61 58 00 8e 11 c0 04 a1 d4 b2
00be30   04 38 55 d7 3b 38 00 f1 51 10 00 28 06 55 1b 18
00be40   3a 6c 00 34 04 0c 1b 2a 96 45 04 38 53 53 24 01
00be50   26 fa 61 ae 4d 80 09 61 16 6a 1a f1 78 1a 4c ea
00be60   1a e6 1e 2a 00 35 05 44 52 60 04 07 53 2d 00 20
00be70   0c 21 18 5c 61 b4 5d 58 00 2d 1d 46 21 aa e0 b2
00be80   04 38 34 cb 64 01 14 6a 07 22 2b d4 e8 b2 04 e1
00be90   16 74 65 ae 4d 80 05 8b 3a 31 01 d9 03 8e 65 a5
00bea0   c8 a7 04 e1 16 74 65 ae cd 80 04 e1 14 c0 63 58
00beb0   55 c8 3a 9a 60 bc 0e ce 4d 2e 6d c9 68 d1 04 6d
00bec0   52 29 3a 6c 00 c0 05 c7 19 81 0e 2a 1a 6e 4d 80
00bed0   0f 43 7b 86 46 21 28 8d 28 01 14 d7 49 49 00 2b
00bee0   18 09 28 c9 47 c0 63 2e 45 59 66 85 c8 a5 04 39
00bef0   5e 91 44 b8 60 06 75 40 1c d7 2a 3e 02 4e 63 0a
00bf00   60 01 11 46 dc b2 04 39 5e 91 44 08 34 d7 31 58
00bf10   04 61 18 5f 1b aa 03 11 1b 0d 2b 00 05 02 6c 24
00bf20   1a f2 96 45 04 39 5e 91 44 13 28 d9 47 c0 5d 52
00bf30   53 6a 60 01 11 aa 19 25 c8 a5 04 22 1f 19 18 f8
00bf40   02 74 4d 0d 1a 26 4f 31 78 01 2c 5f 63 2e 45 59
00bf50   05 81 1a 4e 63 0a e0 b2 04 22 1d 37 1b 98 00 f1
00bf60   52 89 04 77 1a 0e 4d 80 0b f8 65 d1 2b 21 30 c8
00bf70   5e 98 60 01 10 d7 c8 b2 04 22 1f 11 1b 0d 2b 00
00bf80   04 9c 5d d8 64 23 45 46 6d d3 30 01 11 97 3a a0
00bf90   62 2e 56 aa 5f c0 05 67 46 94 a4 b2 04 39 35 ca
00bfa0   2c 23 2e 97 31 59 65 d3 30 02 7d 8a 4f 2a 2a 20
00bfb0   6a a7 5d d3 31 d3 30 23 23 59 60 01 13 2d 5e 86
00bfc0   e4 b2 04 e1 16 74 03 37 29 40 06 a0 63 4e 64 c7
00bfd0   45 40 09 48 45 d2 1d d3 b0 b2 04 e1 14 c0 1e e6
00bfe0   63 00 44 d3 65 57 4c 05 78 e6 67 2a 5f c5 72 b4
00bff0   71 57 29 25 7c 01 d4 b2 04 39 5e 91 44 0b 2a 69
00c000   60 01 22 8b 2c 01 2c c0 49 53 19 0e 4d 80 31 58
00c010   67 57 a8 b2 04 e1 14 c0 48 d9 21 a7 52 90 03 8d
00c020   53 0a 01 14 6d 57 03 06 7b 00 17 24 6d d8 3b 20
00c030   10 ea 1b 59 39 7a 44 04 2c 88 11 25 5c ab 17 20
00c040   06 a5 c8 a5 04 e1 14 c0 2e 91 25 49 02 ae 45 40
00c050   05 35 44 d8 65 c8 00 35 00 38 0d 66 00 39 6c d1
00c060   6d 40 1b 39 19 0d 29 25 c8 a5 04 e1 36 74 02 26
00c070   4d 2e 4d 98 00 35 96 45 04 e1 14 c0 5d 49 00 fa
00c080   53 c0 06 a0 17 c3 1c c0 70 d7 4d d3 30 bf 96 45
00c090   04 e1 14 69 52 29 03 37 6a 70 00 35 04 67 6a 2c
00c0a0   3a 6c 00 2b 1b 18 52 f9 29 20 3d 5c 2a 38 96 45
00c0b0   04 e1 14 69 2b b6 69 d8 3b 2a 01 e6 25 40 2d cc
00c0c0   6a ee 4d 40 06 a5 c8 a5 04 e1 14 69 2a 74 5e 54
00c0d0   6b 00 25 c6 4a 93 24 05 7a aa 5d 6a 23 31 78 08
00c0e0   6b 25 7c 01 d4 b2 04 e1 14 69 3a 79 5d c8 1b 2a
00c0f0   03 0e 47 6a 5c 08 34 d1 39 0a 00 35 96 45 07 95
00c100   19 d3 65 d3 30 07 78 06 02 6a 32 2a 23 2a 24 0c
00c110   2a 6e 6b 00 04 a1 d4 b2 04 87 05 ad 1a 69 e0 a5
00c120   04 24 32 ea 1b 20 13 53 25 57 0a a0 11 52 55 d7
00c130   a8 a5 11 6e 4d 2e 4d 80 4e 99 35 d3 30 01 27 66
00c140   47 4a 04 61 00 47 45 4b 64 23 0e c9 3b 0c 6b 19
00c150   29 25 c8 a7 07 87 53 39 45 40 04 b8 3b 39 3a 6c
00c160   00 5b 04 19 18 f1 a8 b2 13 0e 67 2e 4d 80 0b 61
00c170   02 aa 25 58 64 d1 00 25 18 0b 44 d2 3a 6c 03 34
00c180   5d 0d 04 72 19 2a 00 29 3b 74 5f c5 c8 a5 12 b1
00c190   1b ce 4d 80 06 c2 4b 86 78 01 ac 20 13 86 6d d3
00c1a0   30 01 80 a5 70 d1 c4 a5 04 22 2f 15 3a 31 60 01
00c1b0   30 20 2e 34 52 e0 04 ca 6c d5 52 e6 65 58 01 d2
00c1c0   49 49 38 d9 2a 3e 16 45 9c a5 04 3c 3a 69 53 98
00c1d0   00 2d 1a 31 00 f4 1a e9 29 25 c8 a5 04 3c 1a 31
00c1e0   60 01 24 20 5d db 2a e0 20 d3 78 5b 48 de 00 48
00c1f0   22 2e 48 e6 1e 2a 00 35 05 44 66 80 04 03 74 25
00c200   18 02 3a a6 65 a5 c8 a5 04 3c 3a 69 53 80 22 34
00c210   61 58 00 be 4a 97 28 0a 1b 0e 47 c0 65 a3 25 d9
00c220   02 95 2a 6a 24 bf 96 45 45 46 6d 40 04 0c 9a 4a
00c230   04 61 1b 14 01 34 03 d4 e8 b2 13 19 1a 69 3a 6c
00c240   00 fe 00 20 65 52 56 2a 17 18 00 d1 64 d7 04 61
00c250   20 64 61 4a 00 c0 07 2d 52 2a 00 36 04 0b 46 94
00c260   5c 01 60 4c 07 e3 60 2a 04 37 2b 19 00 29 04 19
00c270   2a 55 45 40 04 a2 74 29 06 a5 c8 a5 11 03 24 28
00c280   70 d1 40 02 6c 4b 6c d5 52 e5 d4 a5 11 aa 46 34
00c290   04 64 60 ce 46 97 16 80 11 d3 63 37 69 19 3a 93
00c2a0   60 bd 00 99 50 0a 4f 2a 5c 06 00 f4 27 c0 05 3c
00c2b0   1b 2a 5c 23 60 de 00 b9 12 26 6a 68 34 b9 05 44
00c2c0   66 80 31 59 00 2c 61 b4 5d 41 0f 06 78 05 64 91
00c2d0   1a 69 17 20 52 e0 04 09 3a ea 23 2e 0b 61 23 86
00c2e0   4f 20 05 8c 50 2a 11 64 5c 94 10 e4 50 9f 13 e0
00c2f0   12 44 18 8c 11 c4 20 04 1c 94 10 c4 64 04 20 94
00c300   12 44 54 86 12 64 78 04 70 d7 5c d3 67 c5 74 01
00c310   3c f4 1b 20 04 ac 68 d7 1a 79 29 49 00 4a 16 20
00c320   61 48 52 69 60 01 49 26 65 40 05 35 6a e8 34 d8
00c330   28 14 5c 1a 4f 2e 44 1a 61 49 04 7c 35 c8 35 5b
00c340   2a e0 22 92 2b 00 2d d7 63 21 28 8c 52 89 00 91
00c350   69 10 96 85 01 8a 67 2e 4d 80 4a 97 28 06 31 d9
00c360   1b 2a a4 b2 12 b4 51 61 0f d4 68 b8 5d 40 25 46
00c370   a4 b4 07 8c 69 c9 28 f4 52 00 2a 79 3b 31 29 20
00c380   17 24 2e 34 51 20 11 14 4f 37 52 20 11 26 48 05
00c390   5c ab 17 20 04 a2 6c 20 0a a5 c8 a5 11 6e 25 31
00c3a0   3a 6c 00 2b 84 05 14 c2 6c 8e 00 ea 30 01 12 a6
00c3b0   5d 34 4c b5 14 c2 f4 a7 07 98 21 55 66 ea 04 75
00c3c0   53 18 38 f1 78 01 44 29 1a 68 39 53 64 04 29 9e
00c3d0   57 20 3b 38 2a 2b 04 61 14 36 04 08 51 6b 3a 61
00c3e0   28 21 61 0a 57 37 28 01 16 97 4c d2 2a 79 29 20
00c3f0   05 6f 2b 8a 47 05 c8 a5 00 d5 56 f4 19 0d 3a 6c
00c400   00 36 0d 3a 4d 77 39 53 26 3e 02 46 4e 6a 5c 2a
00c410   04 48 1a 65 74 05 24 2a 12 2a 1b 6a 00 aa 05 44
00c420   1d 48 52 4a 01 2e 4e 6a dc b2 00 36 04 11 1a ec
00c430   2a e1 0d 2e 62 05 70 e6 61 49 03 6a 5f 0e 0b 61
00c440   24 9f 52 f0 00 8e 16 45 9c a5 00 7f 36 91 25 d3
00c450   30 18 1a 39 00 26 55 55 55 57 05 44 22 93 25 d2
00c460   2a 79 60 02 28 69 6a a8 52 4e 4d 80 62 66 22 05
00c470   d4 a5 12 74 64 07 46 94 27 c0 45 d0 2a 3e 96 45
00c480   08 c1 14 69 3a 79 29 97 1a 20 54 d7 64 01 24 20
00c490   22 93 66 f4 44 15 1a 6a 44 b2 94 e5 11 14 4a 46
00c4a0   4d 32 2a 79 00 b7 15 25 28 ad 16 25 28 a7 14 e4
00c4b0   51 a0 79 40 71 b4 03 06 78 bd 00 b9 11 aa 46 34
00c4c0   03 06 3a 34 5c b9 17 a5 1c 89 53 19 03 2d 53 40
00c4d0   40 7f 65 be 03 0e 4c b5 14 e4 79 46 04 79 36 9a
00c4e0   03 0d 1a 39 00 48 22 fa 61 aa 24 07 78 18 66 93
00c4f0   2b 05 48 a7 13 0d 1a 31 00 d3 32 fe 01 94 27 00
00c500   67 57 4c 19 35 4a 00 2c 27 58 64 b5 14 e4 61 a6
00c510   46 20 65 aa 78 18 64 c7 03 2d 78 0a 79 40 05 66
00c520   03 19 39 10 16 85 1c 8a 6d 53 00 2c 2b 2a 5e 6e
00c530   67 c0 61 a6 47 20 65 b4 68 17 50 d2 00 d3 24 a7
00c540   13 53 05 84 34 c9 2b 00 61 a6 47 20 65 b4 68 02
00c550   23 0a 4f 20 1b 20 44 d8 64 b2 14 e4 63 57 2a 3e
00c560   03 2d 53 40 61 a6 47 20 65 aa 4c 17 2a aa 4f 25
00c570   c8 a5 80 05 00 00 80 00 00 00 00 00 80 05 00 00
00c580   00 00 00 00 80 a5 04 42 0d 2e 24 02 24 b4 94 e5
00c590   14 c2 6c 27 0a 81 30 48 18 13 53 53 02 4e 63 0e
00c5a0   4d 80 06 c1 44 73 16 85 18 5d 94 e5 04 41 35 66
00c5b0   21 d3 30 01 00 5d 61 c9 28 01 24 c0 0c ad 53 58
00c5c0   28 2a 04 e1 16 74 00 62 06 a1 0c 26 1a 31 00 20
00c5d0   71 d3 26 9c 60 01 34 f4 1a e9 29 20 6a a1 28 3c
00c5e0   09 d5 1b 2d 03 8e 4d 38 00 5d 06 81 03 37 29 58
00c5f0   96 45 04 41 35 66 21 d3 30 01 00 53 61 c9 28 01
00c600   24 c0 0c ad 53 58 28 2a 04 e1 16 74 00 62 06 a1
00c610   0c 26 1a 31 00 20 71 d3 26 9c 60 01 34 f4 1a e9
00c620   29 25 c8 a5 04 41 34 d9 52 a0 04 02 73 86 46 20
00c630   05 26 01 97 28 d9 01 06 4f d4 4c 23 51 6b 2a ee
00c640   4d 80 18 12 1a fb 2a 34 6b 00 6d ca 70 01 24 20
00c650   49 cc 37 3e 00 44 12 ee 6d 57 00 ea 46 9c 05 44
00c660   19 17 53 18 00 20 20 d3 7a 93 04 61 03 86 46 38
00c670   00 29 04 04 71 ae 65 40 11 11 39 6b 60 0f 50 36
00c680   04 12 39 8d 67 c0 5c d2 54 d7 67 00 05 21 00 8b
00c690   44 d9 35 46 24 04 4a 9a 4f 26 3a 78 05 44 66 80
00c6a0   04 03 3c 23 10 d7 19 86 06 c4 2c d1 47 00 48 de
00c6b0   00 48 61 4a 4c 23 22 92 56 2a 65 40 05 77 19 d3
00c6c0   1e 9c 05 44 2b 6a 4c 0b 6a f9 35 57 03 55 63 37
00c6d0   28 d2 04 61 02 ee 6d 57 01 71 53 98 02 9a 64 01
00c6e0   24 c0 32 ea 1b 20 24 d7 40 08 1b 6a 5e 61 28 99
00c6f0   50 01 00 5c 04 a3 25 d2 49 53 61 40 2e 97 2b 19
00c700   04 78 66 ea 65 0d 3a 6c 00 4a 49 d1 2b 01 28 46
00c710   0a 95 53 18 38 f1 28 01 31 11 3a 47 01 34 72 60
00c720   07 e1 01 06 4f c2 6c 32 06 a5 c8 a5 04 41 34 5b
00c730   18 18 48 d1 44 23 5e 88 43 c0 1d 46 21 a0 1f c0
00c740   04 02 10 97 3b 6a 5c 23 1d 51 53 80 04 0b 1a 31
00c750   60 2a 07 83 51 17 53 18 2b 00 53 6a 5c 01 01 66
00c760   46 38 00 2c 04 03 04 26 18 02 3a a6 65 a0 22 93
00c770   65 d3 69 58 00 2c 04 02 e8 b2 04 41 34 d9 00 20
00c780   1c d8 28 01 24 20 24 d2 04 61 62 34 52 58 00 c7
00c790   53 6a 03 d4 68 2a 04 37 3b 6a 5c 02 10 ea 31 d3
00c7a0   60 01 54 2a 10 c8 5e 98 60 0e 64 23 05 81 01 46
00c7b0   63 21 0d 11 39 6b 60 0b 52 f2 01 8e 1a 79 03 86
00c7c0   46 38 03 19 5d 59 21 ae 4d 80 0d e5 70 53 1a 34
00c7d0   4d 80 04 18 36 97 a8 b2 04 41 34 5b 18 02 3b 19
00c7e0   5d d5 00 29 1d 46 21 a0 1d 59 71 4a 4c 01 00 9c
00c7f0   35 d9 28 04 22 2e 2d 78 00 26 04 02 10 97 3b 6a
00c800   5c 2a 07 99 3a 7e 00 57 09 82 70 3f 04 08 45 cb
00c810   ac b2 04 41 34 5b 04 02 10 97 3b 6a 5c 0f 6b 19
00c820   00 ea 46 9c 00 20 24 d2 05 41 06 ee 6d 57 01 71
00c830   53 98 02 da 39 59 47 c0 06 a1 28 27 04 a6 02 26
00c840   4d 2e 4d 80 0b 61 00 5c 61 b4 5d 45 c8 a5 11 46
00c850   63 20 52 e0 71 58 e4 b5 04 41 34 5b 18 01 38 ea
00c860   19 0d 00 5b 04 03 07 0d 52 ea 00 29 04 17 3b 6a
00c870   5c 23 07 0b 46 9c 60 07 78 16 69 c8 42 3e 05 41
00c880   72 a6 65 a0 5f 53 60 02 4c d1 52 6c 00 20 5d db
00c890   2a e1 0c 26 18 18 1a 69 17 8b 3a 31 29 20 0a e2
00c8a0   30 6f 28 d8 e4 b2 04 41 37 1a 5e f4 6a 69 29 20
00c8b0   1f c0 18 1c 1a 31 00 29 60 26 0b 66 46 20 61 c9
00c8c0   2b 05 c8 a5 04 41 34 d9 00 20 2a 79 5c d3 21 40
00c8d0   05 23 24 c7 1a 69 52 6a 24 08 50 d1 02 4e 4d 41
00c8e0   28 98 66 e6 4d 8a 03 16 69 46 43 c0 62 9a 4d 38
00c8f0   01 14 49 40 06 41 00 57 1b 20 04 02 75 53 24 2a
00c900   04 52 1b c0 1a 38 50 0a 61 06 55 40 05 81 01 46
00c910   63 25 c8 a5 aa 69 11 a6 45 65 70 fa 5d ca 24 01
00c920   58 20 4b 49 00 25 0d 34 45 20 66 fa 4e 01 0c fa
00c930   45 8e 4d 80 05 6f 2b 8a 47 05 c8 a5 5d 58 64 d7
00c940   e4 a5 04 41 74 48 61 57 3a 9a e0 b2 04 41 75 94
00c950   00 31 70 de 16 45 9c a5 04 41 f4 a5 04 42 3d 11
00c960   3a 47 00 d3 78 0d 39 8d 2a e5 c8 a5 04 42 3e ea
00c970   19 0d 00 20 5e 95 a8 b2 04 42 3d 94 03 55 63 37
00c980   28 d2 01 3a 28 01 33 19 5e 93 30 08 6a f7 2a 79
00c990   e0 b2 12 8d 01 2a 1a e1 28 66 62 4a 46 20 70 d8
00c9a0   01 14 1a 20 30 d8 05 44 38 03 44 33 65 b4 69 8d
00c9b0   64 19 71 c8 28 02 59 06 5e fe 3a 6c 01 71 1a 4e
00c9c0   4d 80 50 ef 29 19 60 01 58 35 16 45 1c a7 10 f4
00c9d0   52 94 52 94 48 b4 16 85 d0 a5 04 41 75 6e 64 01
00c9e0   50 2b 06 31 50 c9 96 45 01 d9 00 d9 00 20 65 d2
00c9f0   a8 b2 04 49 51 2c 28 06 60 01 00 47 22 92 2b 00
00ca00   06 d1 53 85 c8 a5 10 c7 53 6a 00 20 66 f4 55 be
00ca10   01 06 61 40 34 d3 33 00 0d 2a 47 6e 61 a0 63 94
00ca20   5d 20 05 2c 5d 46 64 06 4f 2e 5b 4e 67 c5 c8 a5
00ca30   04 24 71 ae 65 40 11 11 39 6b 60 15 5d 5b 2a 79
00ca40   00 24 44 d3 25 d3 30 01 d4 b2 13 26 46 0e 4d 80
00ca50   05 9e 53 57 61 51 2c 01 17 06 39 20 05 82 20 c0
00ca60   61 cc 4c 01 25 d2 55 53 25 d3 30 12 2a 79 1a 20
00ca70   22 91 44 d5 61 45 c8 a7 01 34 2b 13 17 19 03 0a
00ca80   2a 40 05 9c d2 f0 71 a6 64 1c 1b 00 2e 97 49 57
00ca90   47 c0 18 11 1a 0a 05 44 36 9c 2b 6a 5c 23 05 61
00caa0   00 4b 45 5b 2a 20 46 9c 2a ea 24 23 64 35 00 25
00cab0   49 57 2a 3e 00 c0 61 a6 46 34 70 18 66 ea 1a 41
00cac0   0d 46 61 d1 f8 a5 12 3e 3a 6c 00 36 0f c8 52 f3
00cad0   2a e0 04 a6 00 ea 1b 59 39 7a 46 3e 01 06 5f 6a
00cae0   24 08 5f d8 64 d1 03 10 6a 31 05 42 18 58 05 82
00caf0   21 97 3a 73 3a 6c 00 d9 00 28 5c d9 35 57 02 66
00cb00   63 2e 47 c5 c8 a5 96 45 0d a1 00 ee 5d 25 63 00
00cb10   4d 58 64 01 14 c0 05 ca 31 80 2a 68 5f 58 65 49
00cb20   00 2b 56 ea 21 d4 6b 00 3d 5c 2a 38 04 66 56 a6
00cb30   5d 53 66 3e 03 08 1b 6a 4d 8a 24 07 78 06 01 0d
00cb40   3a 29 45 58 60 18 52 6c 1d d7 a4 b2 0d a1 03 37
00cb50   52 ad 78 08 1b 0a 00 25 0d 26 4d 0e 2a 79 02 a6
00cb60   5d 0d 49 53 64 12 1a a5 c8 a5 13 d4 68 b8 24 0b
00cb70   5c c8 67 57 28 12 1a 7e 00 f4 4d 58 96 45 0d a1
00cb80   02 4e 25 31 28 02 48 3a 18 01 67 0d 19 79 01 2a
00cb90   61 0a 4d 38 00 3f 0f 00 1d 51 53 81 28 86 1e 9b
00cba0   28 01 03 0d 19 79 00 25 18 12 2b 26 44 0b 5c d2
00cbb0   2b 94 5e 00 05 81 60 c0 35 46 6f c0 3a e2 6d 0d
00cbc0   18 36 04 a6 67 26 21 aa 24 2a 04 e1 35 5d 3b 38
00cbd0   00 2c 04 02 70 26 0d e1 28 3c 2e 9a 44 14 26 97
00cbe0   00 64 09 09 2b 2a 23 2a 24 01 48 20 44 d9 65 57
00cbf0   01 2e 5d 48 65 d4 cc b2

);
    @Dynamic_Orig = @Memory[0 .. 8582];
}

sub checksum {
    #my $flen = $main::Constants{file_length};
    my $header_size = 0x40; # don't count header bytes.
    my $sum = 0;
    for (@Dynamic_Orig[$header_size .. 8582 -1], 
        @Memory[8582 .. 52216-1]) 
    {
	$sum += $_;
    }
    # 512K * 256 = 128M: definitely less than 2G max integer size for Perl.
    # so we don't need to do mod within the for loop
    $sum = $sum % 0x10000;
    return $sum;
}

sub get_dynamic_memory {
    [@Memory[0 .. 8582]];
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
    @Memory[0 .. 8582] = 
	$restoring ? @$restore_mem_ref : @Dynamic_Orig;
}

} # End package PlotzMemory

