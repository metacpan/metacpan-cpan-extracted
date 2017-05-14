package GPIB;

    use strict;
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %config @tmo_name
                $config_fname $DEFAULT_PKG);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( );

@EXPORT_OK = qw(
    ALL_SAD ATN BIN BusATN BusDAV BusEOI BusIFC BusNDAC BusNRFD BusREN 
    BusSRQ CIC CMPL DABend DCAS DCL DTAS EABO EADR EARG EBTO EBUS ECAP
    ECIC EDMA EDVR EFSO ELCK END ENEB ENOL EOIP EOWN ERR ESAC
    ESRQ ESTB ETAB EVENT GET GTL IbaAUTOPOLL IbaBNA IbaBaseAddr IbaBaud
    IbaCICPROT IbaComIrqLevel IbaComPort IbaComPortBase IbaDMA IbaDataBits 
    IbaDmaChannel IbaEOSchar IbaEOScmp IbaEOSrd IbaEOSwrt IbaEOT 
    IbaEndBitIsNormal IbaEventQueue IbaHSCableLength IbaIRQ IbaIrqLevel
    IbaLON IbaNoEndBitOnEOS IbaPAD IbaPP2 IbaPPC IbaPPollTime IbaParity 
    IbaREADDR IbaReadAdjust IbaSAD IbaSC IbaSPollBit IbaSPollTime IbaSRE 
    IbaSendLLO IbaSignalNumber IbaSingleCycleDma IbaSpollBit IbaStopBits
    IbaTIMING IbaTMO IbaUnAddr IbaWriteAdjust IbcAUTOPOLL IbcCICPROT IbcDMA 
    IbcEOSchar IbcEOScmp IbcEOSrd IbcEOSwrt IbcEOT IbcEndBitIsNormal
    IbcEventQueue IbcHSCableLength IbcIRQ IbcLON IbcNoEndBitOnEOS IbcPAD 
    IbcPP2 IbcPPC IbcPPollTime IbcREADDR IbcReadAdjust IbcSAD IbcSC 
    IbcSPollBit IbcSPollTime IbcSRE IbcSendLLO IbcSignalNumber IbcSpollBit 
    IbcTIMING IbcTMO IbcUnAddr IbcWriteAdjust LACS LAD LLO LOK NLend NO_SAD 
    NULLend PPC PPD PPE PPU REM REOS RQS SDC SPD SPE SPOLL SRQI STOPend
    T1000s T100ms T100s T100us T10ms T10s T10us T1ms T1s T300ms T300s
    T300us T30ms T30s T30us T3ms T3s TACS TAD TCT TIMO TNONE UNL
    UNT ValidATN ValidDAV ValidEOI ValidIFC ValidNDAC ValidNRFD ValidREN 
    ValidSRQ XEOS
);

$VERSION = '0.30';

$config_fname = "/etc/pgpib.conf";
$config_fname = "c:/pgpib.conf" if $^O =~ /MSWin32/;   # geez

%config = ();

my @tmo_name = qw(
    TNONE T10us T30us T100us T300us T1ms  T3ms  
    T10ms T30ms T100ms T300ms T1s   T3s   T10s  
    T30s  T100s T300s T1000s
);

    use constant REOS               => 0x0400;
    use constant XEOS               => 0x0800;
    use constant BIN                => 0x1000;
    use constant DCL                => 0x14;
    use constant GET                => 0x08;        
    use constant GTL                => 0x01;
    use constant LAD                => 0x20;        
    use constant LLO                => 0x11;        
    use constant PPC                => 0x05;        
    use constant PPD                => 0x70;        
    use constant PPE                => 0x60;        
    use constant PPU                => 0x15;        
    use constant SDC                => 0x04;        
    use constant SPD                => 0x19;        
    use constant SPE                => 0x18;        
    use constant TAD                => 0x40;        
    use constant TCT                => 0x09;        
    use constant UNL                => 0x3f;        
    use constant UNT                => 0x5f;        
    use constant ERR                => 0x8000;
    use constant TIMO               => 0x4000;
    use constant END                => 0x2000;
    use constant SRQI               => 0x1000;
    use constant RQS                => 0x0800;
    use constant SPOLL              => 0x0400;
    use constant EVENT              => 0x0200;
    use constant CMPL               => 0x0100;
    use constant LOK                => 0x0080;
    use constant REM                => 0x0040;
    use constant CIC                => 0x0020;
    use constant ATN                => 0x0010;
    use constant TACS               => 0x0008;
    use constant LACS               => 0x0004;
    use constant DTAS               => 0x0002;
    use constant DCAS               => 0x0001;
    use constant EDVR               => 0;
    use constant ECIC               => 1;
    use constant ENOL               => 2;
    use constant EADR               => 3;
    use constant EARG               => 4;
    use constant ESAC               => 5;
    use constant EABO               => 6;
    use constant ENEB               => 7;
    use constant EDMA               => 8;
    use constant EBTO               => 9;
    use constant EOIP               => 10;
    use constant ECAP               => 11;
    use constant EFSO               => 12;
    use constant EOWN               => 13;
    use constant EBUS               => 14;
    use constant ESTB               => 15;
    use constant ESRQ               => 16;
    use constant ETAB               => 20;
    use constant ELCK               => 21;
    use constant TNONE              => 0;
    use constant T10us              => 1;
    use constant T30us              => 2;
    use constant T100us             => 3;
    use constant T300us             => 4;
    use constant T1ms               => 5;
    use constant T3ms               => 6;
    use constant T10ms              => 7;
    use constant T30ms              => 8;
    use constant T100ms             => 9;
    use constant T300ms             => 10;
    use constant T1s                => 11;
    use constant T3s                => 12;
    use constant T10s               => 13;
    use constant T30s               => 14;
    use constant T100s              => 15;
    use constant T300s              => 16;
    use constant T1000s             => 17;
    use constant ValidDAV           => 0x0001;
    use constant ValidNDAC          => 0x0002;
    use constant ValidNRFD          => 0x0004;
    use constant ValidIFC           => 0x0008;
    use constant ValidREN           => 0x0010;
    use constant ValidSRQ           => 0x0020;
    use constant ValidATN           => 0x0040;
    use constant ValidEOI           => 0x0080;
    use constant BusDAV             => 0x0100;
    use constant BusNDAC            => 0x0200;
    use constant BusNRFD            => 0x0400;
    use constant BusIFC             => 0x0800;
    use constant BusREN             => 0x1000;
    use constant BusSRQ             => 0x2000;
    use constant BusATN             => 0x4000;
    use constant BusEOI             => 0x8000;
    use constant BUS_DAV            => 0x0100;
    use constant BUS_NDAC           => 0x0200;
    use constant BUS_NRFD           => 0x0400;
    use constant BUS_IFC            => 0x0800;
    use constant BUS_REN            => 0x1000;
    use constant BUS_SRQ            => 0x2000;
    use constant BUS_ATN            => 0x4000;
    use constant BUS_EOI            => 0x8000;
    use constant IbcPAD             => 0x0001;
    use constant IbcSAD             => 0x0002;
    use constant IbcTMO             => 0x0003;
    use constant IbcEOT             => 0x0004;
    use constant IbcPPC             => 0x0005;
    use constant IbcREADDR          => 0x0006;
    use constant IbcAUTOPOLL        => 0x0007;
    use constant IbcCICPROT         => 0x0008;
    use constant IbcIRQ             => 0x0009;
    use constant IbcSC              => 0x000A;
    use constant IbcSRE             => 0x000B;
    use constant IbcEOSrd           => 0x000C;
    use constant IbcEOSwrt          => 0x000D;
    use constant IbcEOScmp          => 0x000E;
    use constant IbcEOSchar         => 0x000F;
    use constant IbcPP2             => 0x0010;
    use constant IbcTIMING          => 0x0011;
    use constant IbcDMA             => 0x0012;
    use constant IbcReadAdjust      => 0x0013;
    use constant IbcWriteAdjust     => 0x0014;
    use constant IbcEventQueue      => 0x0015;
    use constant IbcSPollBit        => 0x0016;
    use constant IbcSpollBit        => 0x0016;
    use constant IbcSendLLO         => 0x0017;
    use constant IbcSPollTime       => 0x0018;
    use constant IbcPPollTime       => 0x0019;
    use constant IbcNoEndBitOnEOS   => 0x01A;
    use constant IbcEndBitIsNormal  => 0x1A;
    use constant IbcUnAddr          => 0x001B;
    use constant IbcSignalNumber    => 0x001C;
    use constant IbcHSCableLength   => 0x01F;
    use constant IbcLON             => 0x0022;
    use constant IbaPAD             => 0x0001;
    use constant IbaSAD             => 0x0002;
    use constant IbaTMO             => 0x0003;
    use constant IbaEOT             => 0x0004;
    use constant IbaPPC             => 0x0005;
    use constant IbaREADDR          => 0x0006;
    use constant IbaAUTOPOLL        => 0x0007;
    use constant IbaCICPROT         => 0x0008;
    use constant IbaIRQ             => 0x0009;
    use constant IbaSC              => 0x000A;
    use constant IbaSRE             => 0x000B;
    use constant IbaEOSrd           => 0x000C;
    use constant IbaEOSwrt          => 0x000D;
    use constant IbaEOScmp          => 0x000E;
    use constant IbaEOSchar         => 0x000F;
    use constant IbaPP2             => 0x0010;
    use constant IbaTIMING          => 0x0011;
    use constant IbaDMA             => 0x0012;
    use constant IbaReadAdjust      => 0x0013;
    use constant IbaWriteAdjust     => 0x0014;
    use constant IbaEventQueue      => 0x0015;
    use constant IbaSPollBit        => 0x0016;
    use constant IbaSendLLO         => 0x0017;
    use constant IbaSPollTime       => 0x0018;
    use constant IbaPPollTime       => 0x0019;
    use constant IbaNoEndBitOnEOS   => 0x01A;
    use constant IbaEndBitIsNormal  => 0x1A;
    use constant IbaUnAddr          => 0x001B;
    use constant IbaSignalNumber    => 0x001C;
    use constant IbaHSCableLength   => 0x01F;
    use constant IbaLON             => 0x0022;
    use constant IbaBNA             => 0x200;
    use constant IbaBaseAddr        => 0x201;
    use constant IbaDmaChannel      => 0x202;
    use constant IbaIrqLevel        => 0x203;
    use constant IbaBaud            => 0x204;
    use constant IbaParity          => 0x205;
    use constant IbaStopBits        => 0x206;
    use constant IbaDataBits        => 0x207;
    use constant IbaComPort         => 0x208;
    use constant IbaComIrqLevel     => 0x209;
    use constant IbaComPortBase     => 0x20A;
    use constant IbaSingleCycleDma  => 0x20B;
    use constant NO_SAD             => 0;
    use constant ALL_SAD            => -1;

# The user shouldn't have to call this routine.
# new() calls this to load /etc/pgpib.conf into
# memory.  This helps mod_perl performance by not
# reading /etc/pgpip.conf everytime a script is
# run. 
sub loadConfig {
    %config = ();
    $config{loaded} = 1;
    open FD, "<$config_fname" || return;
    while (<FD>) {
        next if (/^\s*#/);
        my @elem = split ;
        next if @elem < 2;      # At least 2 elements
        for (@elem) {
            $_ = hex($_) if $_ =~ /^0x/;
            if (/^T\d+m?s/ || /^TNONE$/) {
                for(my $i=0; $i< @tmo_name; $i++) {
                    if ($tmo_name[$i] eq $_) {
                        $_ = $i;
                        last;
                    }
                }
            }
        }
        {
            my @line = @elem[1 .. @elem-1];
            print STDERR "Duplicate $elem[0] in $config_fname\n" if defined($config{$elem[0]});
            $config{$elem[0]} = \@line;
        }
    }
    close FD;
}

sub new {
    my $pkg = shift; 
    my $name = shift;
    my $g = {};
    my @params;
    my $pkg2;
    my $v;

    no strict 'refs';
    GPIB->loadConfig if !defined($config{loaded});
    if (defined($config{$name})) {
        @params = @{$config{$name}};
        $pkg2 = shift @params;
    } else {
        @params = @_;
        $pkg2 = $name; 
    }
    # print "Using package $pkg2, calling new(@params)\n";
    eval "use $pkg2;";
    if ($@) {
        die "Cannot load $pkg2 for $name\n    $@" if $pkg2 ne $name;
        die "Cannot locate $pkg2 in $config_fname or as a package\n    ";
    }
    if (!defined(&{$pkg2 . "::new"})) {
        die "\nCannot fine new() in package $pkg2\n    ";
    }
    $$g{dev} = &{$pkg2 . "::new"}($pkg2, @params); 
    bless $g, $pkg;
    return $g;
}

sub msleep {
    my $t = shift;

    $t /= 1000.0;
    select(undef, undef, undef, $t);
}

sub devicePresent {
    my $g = shift;

    # ibln() doesn't seem to see some devices with one call, so
    # I call ibln() up to 10 times looking for a single postive
    # response.
    #
    # This is kind of mess with LLP, LLP doesn't have either
    # ibask or ibln...
    my $pad = $g->ibask(GPIB->IbaPAD);
    my $sad = $g->ibask(GPIB->IbaSAD);
    my $active = 0;
    for(1 .. 10) {
        if ($g->ibln($pad, $sad)) {
            $active = 1;
            last;
        }
    }
    return $active;
}

sub query {
    my $qsize = 1024;           # default query size
    my $g = shift;              # Get reference
    my $cmd = shift;            # Get command to device
    my $response;               # reponse from device

    $qsize = $_[0] if @_;       # Get size if there is another parameter
    $g->ibwrt($cmd);
    return if ($g->ibsta & GPIB->ERR);
    $response = $g->ibrd($qsize);
}
    
sub hexDump {
    shift if (ref($_[0]) || @_ == 2);      # Strip object ref is passed

    my ($di) = @_;
    my $do = "";
    my ($i, $j, $c);

    for($i=0; $i < length($di); $i+=8) {
        $do .= sprintf("%04x    ", $i);
        for($j=$i; $j<$i+8; $j++) {
            if ($j < length($di)) {
                $do .= sprintf("%02x ", vec($di, $j, 8)); 
            } else {
                $do .= "   ";
            }
        }
        $do .= "    ";
        for($j=$i; $j<$i+8 && $j< length($di); $j++) {
            $c = ' ';
            $c = chr(vec($di, $j, 8)) if vec($di, $j, 8) >=32 && 
                    vec($di, $j, 8) < 127;
            $do .= "$c ";
        }
        $do .= "\n";
    }
    return $do;
}

sub errorCheck {
    my ($gpib, $header) = @_;
    
    if ($gpib->ibsta & GPIB->ERR) {
        $gpib->printStatus($header . " ");
        die($header);
    }
}

sub printStatus {
    my ($gpib, $header) = @_;
    my $ibsta = $gpib->ibsta;
    my $ibcnt = $gpib->ibcnt;
    my $iberr = $gpib->iberr;
    my $v;

    printf STDERR "$header$gpib\n";
    printf STDERR "    ibsta 0x%04x  ", $ibsta;
    GPIB->ERR  & $ibsta and print STDERR "ERR ";
    GPIB->TIMO & $ibsta and print STDERR "TIMO ";
    GPIB->END  & $ibsta and print STDERR "END ";
    GPIB->SRQI & $ibsta and print STDERR "SRQI ";
    GPIB->RQS  & $ibsta and print STDERR "RQS ";
    GPIB->CMPL & $ibsta and print STDERR "CMPL ";
    GPIB->LOK  & $ibsta and print STDERR "LOK ";
    GPIB->REM  & $ibsta and print STDERR "REM ";
    GPIB->CIC  & $ibsta and print STDERR "CIC ";
    GPIB->ATN  & $ibsta and print STDERR "ATN ";
    GPIB->TACS & $ibsta and print STDERR "TACS ";
    GPIB->LACS & $ibsta and print STDERR "LACS ";
    GPIB->DTAS & $ibsta and print STDERR "DTAS ";
    GPIB->DCAS & $ibsta and print STDERR "DCAS ";
    print STDERR "\n";

    printf STDERR "    ibcnt 0x%04x  (%d)\n", $ibcnt, $ibcnt;
    printf STDERR "    iberr 0x%04x  ", $iberr;
    if ($ibsta & GPIB->ERR) {
        print STDERR "EDVR System error" if ($iberr == GPIB->EDVR);
        print STDERR "ECIC Board not CIC" if ($iberr == GPIB->ECIC);
        print STDERR "ENOL No listeners" if ($iberr == GPIB->ENOL);
        print STDERR "EADR GPIB board not addressed" if ($iberr == GPIB->EADR);
        print STDERR "EARG Invalid arguments" if ($iberr == GPIB->EARG);
        print STDERR "ESAC GPIB board not system controller" if ($iberr == GPIB->ESAC);
        print STDERR "EABO I/O operation aborted" if ($iberr == GPIB->EABO);
        print STDERR "ENEB Nonexistent GPIB board" if ($iberr == GPIB->ENEB);
        print STDERR "EDMA DMA error" if ($iberr == GPIB->EDMA);
        print STDERR "EOIP Async I/O in progress" if ($iberr == GPIB->EOIP);
        print STDERR "ECAP No capability for operation" if ($iberr == GPIB->ECAP);
        print STDERR "EFSO File system error" if ($iberr == GPIB->EFSO);
        print STDERR "EBUS GPIB bus error" if ($iberr == GPIB->EBUS);
        print STDERR "ESTB Serial poll status queue overflow" if($iberr == GPIB->ESTB);
        print STDERR "ESRQ SRQ stuck in ON position" if ($iberr == GPIB->ESRQ);
        print STDERR "ETAB Table problem" if ($iberr == GPIB->ETAB);
        print STDERR "ELCK Board is locked" if ($iberr == GPIB->ELCK);
    }
    print STDERR "\n";
}

sub printConfig {
    my $gpib = shift;
    my $ibsta = $gpib->ibsta;
    my $ibcnt = $gpib->ibcnt;
    my $iberr = $gpib->iberr;
    my $v;

    print "Configuration for $gpib\n";
    $v = $gpib->ibask(GPIB->IbaAUTOPOLL);
    print "    Automatic serial polling enabled.\n" if $v;
    print "    Automatic serial polling diabled.\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaCICPROT);
    print "    CIC protcol enabled.\n" if $v;
    print "    CIC protcol disable.\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaDMA);
    print "    DMA enabled.\n" if $v;
    print "    DMA disabled.\n" if !$v;

    print "    GPIB read configuration:\n";
    $v = $gpib->ibask(GPIB->IbaEOSrd);
    print "        Read operation terminated by EOS\n" if $v;
    print "        EOS character ignored on read\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaEndBitIsNormal);
    print "        END bit set by EOI, EOS, or EOI+EOS match.\n" if $v;
    print "        END bit set by EOI or EOI+EOS match.\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaEOSchar);
    printf"        EOS character for read is 0x%02x.\n", $v;

    $v = $gpib->ibask(GPIB->IbaEOScmp);
    print "        8-bit compare used for EOS on read.\n" if $v;
    print "        7-bit compare used for EOS on read.\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaReadAdjust);
    print "        Bytes swapped on read\n" if $v;
    print "        Bytes not swapped on read\n" if !$v;


    print "    GPIB write configuration:\n";
    $v = $gpib->ibask(GPIB->IbaEOSwrt);
    print "        EOI asserted when EOS char sent during write\n" if $v;
    print "        EOI not asserted when EOS char sent during write\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaEOT);
    print "        EOI asserted at end of write\n" if $v;
    print "        EOI not asserted at end of write\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaWriteAdjust);
    print "        Bytes swapped on write\n" if $v;
    print "        Bytes not swapped on write\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaHSCableLength);
    printf"    HS-488 enabled , cable length is %dm.\n",$v if $v;
    print "    HS-488 disabled\n" if !$v;

#   In the manual, but not in NI's .h file...
#    $v = $gpib->ibask(GPIB->IbaIst);
#    print "    Individual status bit set\n" if $v;
#    print "    Individual status bit not set\n" if !$v;
    
    $v = $gpib->ibask(GPIB->IbaPAD);
    printf "    Primary address is   0x%02x.\n", $v;
    $v = $gpib->ibask(GPIB->IbaSAD);
    printf "    Secondary address is 0x%02x.\n", $v;

    $v = $gpib->ibask(GPIB->IbaPP2);
    print "    PP2 mode, local parallel poll\n" if $v;
    print "    PP1 mode, remote parallel poll\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaPPC);
    printf "    Parallel poll configuration 0x%02x.\n", $v;

    $v = $gpib->ibask(GPIB->IbaPPollTime);
    printf "    Parallel poll time 0x%02x.\n", $v;
 
#    $v = $gpib->ibask(GPIB->IbaRsv);
#    printf "    Serial poll status 0x%02x.\n", $v;

    $v = $gpib->ibask(GPIB->IbaSC);
    print "    Board is system controller\n" if $v;
    print "    Board is not system controller\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaSendLLO);
    print "    LLO command is sent\n" if $v;
    print "    LLO command is not sent\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaSRE);
    print "    REN is automatically asserted\n" if $v;
    print "    REN is not automatically asserted\n" if !$v;

    $v = $gpib->ibask(GPIB->IbaTIMING);
    print "    T1 delay of 2us (normal)\n" if ($v == 1);
    print "    T1 delay of 500ns (high speed)\n" if ($v == 2);
    print "    T1 delay of 350ns (very high speed)\n" if ($v == 3);
    printf"    T1 timing of %d.\n" if ($v<1 || $v>3);

    $v = $gpib->ibask(GPIB->IbaTMO);
    printf "    TMO is %s (0x%02x).\n", $tmo_name[$v], $v;
}

# GPIB calls are not inherited from a lower level module because
# the module used for inheritence might change on an instance by
# instance basis.  A user might have a serial device using 
# GPIB::hpserial open at the same time as a gpib device using 
# GPIB::ni.  So, GPIB delegates to the appropriate module setup
# when new() is called.  This involves an extra call for each
# GPIB function but the gain is functionality is so great that
# it's worth it.
sub ibcnt {
    my $dev = shift;
    $$dev{dev}->ibcnt(@_);
}

sub iberr {
    my $dev = shift;
    $$dev{dev}->iberr(@_);
}

sub ibsta {
    my $dev = shift;
    $$dev{dev}->ibsta(@_);
}

sub ibrda {
    my $dev = shift;
    $$dev{dev}->ibrda(@_);
}

sub ibwrta {
    my $dev = shift;
    $$dev{dev}->ibwrta(@_);
}

sub ibcmda {
    my $dev = shift;
    $$dev{dev}->ibcmda(@_);
}

sub ibfind {
    my $dev = shift;
    $$dev{dev}->ibfind(@_);
}

sub ibnotify {
    my $dev = shift;
    $$dev{dev}->ibnotify(@_);
}

sub ibask {
    my $dev = shift;
    $$dev{dev}->ibask(@_);
}

sub ibbna {
    my $dev = shift;
    $$dev{dev}->ibbna(@_);
}

sub ibcac {
    my $dev = shift;
    $$dev{dev}->ibcac(@_);
}

sub ibclr {
    my $dev = shift;
    $$dev{dev}->ibclr(@_);
}

sub ibcmd {
    my $dev = shift;
    $$dev{dev}->ibcmd(@_);
}

sub ibcmda {
    my $dev = shift;
    $$dev{dev}->ibcmda(@_);
}

sub ibconfig {
    my $dev = shift;
    $$dev{dev}->ibconfig(@_);
}

sub ibdev {
    my $dev = shift;
    $$dev{dev}->ibdev(@_);
}

sub ibdma {
    my $dev = shift;
    $$dev{dev}->ibdma(@_);
}

sub ibeos {
    my $dev = shift;
    $$dev{dev}->ibeos(@_);
}

sub ibeot {
    my $dev = shift;
    $$dev{dev}->ibeot(@_);
}

sub ibgts {
    my $dev = shift;
    $$dev{dev}->ibgts(@_);
}

sub ibist {
    my $dev = shift;
    $$dev{dev}->ibist(@_);
}

sub iblines {
    my $dev = shift;
    $$dev{dev}->iblines(@_);
}

sub ibln {
    my $dev = shift;
    $$dev{dev}->ibln(@_);
}

sub ibloc {
    my $dev = shift;
    $$dev{dev}->ibloc(@_);
}

sub ibnotify {
    my $dev = shift;
    $$dev{dev}->ibnotify(@_);
}

sub ibonl {
    my $dev = shift;
    $$dev{dev}->ibonl(@_);
}

sub ibpad {
    my $dev = shift;
    $$dev{dev}->ibpad(@_);
}

sub ibpct {
    my $dev = shift;
    $$dev{dev}->ibpct(@_);
}

sub ibppc {
    my $dev = shift;
    $$dev{dev}->ibppc(@_);
}

sub ibrd {
    my $dev = shift;
    $$dev{dev}->ibrd(@_);
}

sub ibrda {
    my $dev = shift;
    $$dev{dev}->ibrda(@_);
}

sub ibrdf {
    my $dev = shift;
    $$dev{dev}->ibrdf(@_);
}

sub ibrpp {
    my $dev = shift;
    $$dev{dev}->ibrpp(@_);
}

sub ibrsc {
    my $dev = shift;
    $$dev{dev}->ibrsc(@_);
}

sub ibrsp {
    my $dev = shift;
    $$dev{dev}->ibrsp(@_);
}

sub ibrsv {
    my $dev = shift;
    $$dev{dev}->ibrsv(@_);
}

sub ibsad {
    my $dev = shift;
    $$dev{dev}->ibsad(@_);
}

sub ibsic {
    my $dev = shift;
    $$dev{dev}->ibsic(@_);
}

sub ibsre {
    my $dev = shift;
    $$dev{dev}->ibsre(@_);
}

sub ibstop {
    my $dev = shift;
    $$dev{dev}->ibstop(@_);
}

sub ibtmo {
    my $dev = shift;
    $$dev{dev}->ibtmo(@_);
}

sub ibtrg {
    my $dev = shift;
    $$dev{dev}->ibtrg(@_);
}

sub ibwait {
    my $dev = shift;
    $$dev{dev}->ibwait(@_);
}

sub ibwrt {
    my $dev = shift;
    $$dev{dev}->ibwrt(@_);
}

sub ibwrtf {
    my $dev = shift;
    $$dev{dev}->ibwrtf(@_);
}

# An idea that never worked out
# sub close {
#     my $dev = shift;
#     $$dev{dev}->close(@_);
# }

1;
__END__

=head1 NAME

GPIB - Perl extension for GPIB devices

=head1 SYNOPSIS

  use GPIB;

  $g = GPIB->new("name");
  $g = GPIB->new($interface_module_name, @interface_parameters);

  # GPIB Functions
  $var = $g->ibcnt              # Read GPIB ibcnt variable
  $var = $g->iberr              # Read GPIB iberr variable
  $var = $g->ibsta              # Read GPIB ibsta variable

  $data = $g->ibrd($maxcnt)     # Read from device
  $data = $g->ibrda($maxcnt)
  $data = $g->ibrdf($maxcnt)

  $ibsta = $g->ibwrta($data)    # Write data to device
  $ibsta = $g->ibwrt($data)
  $ibsta = $g->ibwrtf($data)

  $ibsta = $g->ibcmd            # Write commands to GPIB bus
  $ibsta = $g->ibcmda 

  # GPIB Functions
  $value = $g->ibask($option)
  $ibsta = $g->ibbna($name)
  $ibsta = $g->ibcac($v)
  $ibsta = $g->ibclr 
  $ibsta = $g->ibconfig ($option, $value)
  $ibsta = $g->ibdma($v) 
  $ibsta = $g->ibeos($v) 
  $ibsta = $g->ibeot($v) 
  $ibsta = $g->ibgts($v) 
  $ibsta = $g->ibist($v) 
  $lines = $g->iblines 
  $dev = $g->ibln($pad, $sad)
  $ibsta = $g->ibloc 
  $ibsta = $g->ibnotify($v) 
  $ibsta = $g->ibonl($v) 
  $ibsta = $g->ibpad($v) 
  $ibsta = $g->ibpct 
  $ibsta = $g->ibppc($v) 
  $pp = $g->ibrpp($v) 
  $ibsta = $g->ibrsc($v) 
  $sp = $g->ibrsp($v) 
  $ibsta = $g->ibrsv($v) 
  $ibsta = $g->ibsad($v) 
  $ibsta = $g->ibsic 
  $ibsta = $g->ibsre($v) 
  $ibsta = $g->ibstop 
  $ibsta = $g->ibtmo($v) 
  $ibsta = $g->ibtrg($v) 
  $ibsta = $g->ibwait($mask) 

  # Utility Function
  $result = $g->query($command);
  print "OK" if $g->devicePresent;
  print $g->hexDump($data);
  $g->errorCheck;
  $g->printStatus;
  $g->printConfig;

  GPIB::msleep($milliseconds);

  # Normally not called by user, GPIB->new() calls these
  $ibsta = $g->ibfind()
  $ibsta = $g->ibdev()

=head1 DESCRIPTION

Gpib.pm provides a convenient and powerful interface to electronic 
test equipment through GPIB, serial, or other interfaces.  The module provides 
Perl versions of familiar GPIB calls through an object interface.

GPIB.pm works in conjunction with interface modules that
perform low level access.  GPIB::ni is an XS module that interfaces
to National Instruments GPIB cards, GPIB::hpserial is an XS module
that interfaces to the serial port of HP equipment, GPIB::rmt is
a client to access a GPIB sever running on a remote machine with 
TCP/IP protocols.   GPIB::rmt also provides a standalone Perl 
server to allow remote access.

Normally, the GPIB module uses /etc/pgpib.conf file to 
configure the low level interface for particular devices.  
In general, the applications programmer doesn't need to be 
aware of the lower level interface and applications work 
transparent to the lower level interface.

GPIB->new() is used to create a reference for operations on a 
device.  A typical program might use the following to open a 
device:

    use GPIB;

    $g = GPIB->new("Generator");

First, Generator is looked up in  /etc/pgpib.conf (c:\pgpib.conf on 
Windows). A typical /etc/pgpib.conf entry is:

    # name      driver    Board   PAD   SAD TMO  EOT  EOS
    Generator   GPIB::ni  0       0x10  0   T1s  1    0

This entry describes a device called "Generator" that uses the 
National Instruments driver, board 0, primary address 16, and a 
timeout value of 1 second.  See the sample /etc/pgpib.conf.sample
file for more information on parameters for other interfaces.

GPIB->new() can be called to open a device bypassing /etc/pgpib.conf.
Used in this manner, the first parameter is the name of the 
low level interface module.  Other parameters are those required
by the low level module.  Here is an example for opening a device
using the National Instruments driver with a primary address of 16.
In the case of the GPIB::ni module, the parameters to new() are 
the parameters passed to ibdev() in a GPIB program written in C:

    $g = GPIB->new("GPIB::ni", 0, 16, 0, GPIB->T1s, 1, 0);

If GPIB::ni gets 6 parameters it uses ibdev() to open the device.
If it gets 1 parameter it calls ibfind() to open the device. To
open the bus (as opposed to a specific device), ibfind() is used
with the nameof the bus as a parameter.  Here is an example for
open the GPIB bus on the first board.  This can also be done
in the /etc/pgpib.conf file.

   $g = GPIB->new("GPIB::ni", "gpib0");

The reference return by GPIB->new is used by all other GPIB methods
to indentify the device.  Most of the methods are object methods
of standard GPIB function calls.  A simple program for accessing the
device is shown below:

    use GPIB;

    $g = GPIB->new("Generator");
    $g->tmo(GPIB->T3s);             # Set timeout to 3s
    $g->ibwrt('*IDN?');             # Send *IDN? to device
    $id = $g->ibrd(1024);           # Read result
    print "Got $id\n";

See GPIB documentation or example programs for examples using standard
GPIB calls.

$t = $g->hexDump($data) produces a human readable dump of scalar 
containing binary data.  This is useful for debugging GPIB programs.

GPIB::msleep($milliseconds)  sleeps for specified number of mS.  This
is often useful in GPIB programming.

$result = $g->query($command) is a convenience function that does an
$g->ibwrt($command) followed by an $g->ibrd() if the write succeeds.
This simplifies the example shown above for read the ID string as
follows:

    use GPIB;

    $g = GPIB->new("Generator");
    print "Got ", $g->query('*IDN?');

$g->printStatus() and $g->printConfig() are utility functions for
printing status of the last operation (printStatus) or the 
configuration of the device (printConfig).

$g->errorCheck() is convenience function that check the ibsta 
return code from the previous operation.  If there was an error
then some diagnostic information is printed and the program exits.
It's a quick and dirty method for doing error checking:

    use GPIB;

    $g = GPIB->new("device");   # new() dies on error

    $g->ibwrt('*IDN?');
    $g->errorCheck("ibwrt error ");

    $d = $g->ibrd(1024);
    $g->errorCheck("ibrd error ");

$g->ibsta(), $g->ibcnt(), and $g->iberr() are methods for
accessing the global ibsta, ibcnt, and iberr variables normally 
associated with GPIB programming.  These are usually 
global variables in GPIB C programs.  In Perl these are instance
variables.  GPIB constants are accessed in the GPIB namespace.
A typical piece of code for checking errors is:

    $g->ibwrt("Hello, world.");
    print "There was an error\n" if $g->ibsta & GPIB->ERR;
    print "Timeout\n" if $g->ibsta & GPIB->TIMO;

Look in GPIB.pm for a list of exportable constants.

=head1 INHERITANCE

The GPIB module is written with the intention of it being inherited
by other modules.  Driver modules that provide functionality for specific
devices inherit GPIB.  See documentation for specific modules, a 
short example is shown below.  The GPIB::hp33120a driver module
provides methods for conveniently setting parameters on this device
while still providing all of the functionality of the GPIB module.
An example is shown below:

    use GPIB::hp33120a;
  
    $g = GPIB::hp33120a->new("name");

    $g->freq(20000.0);    # Set frequency to 20kHz
    $g->shape(SIN);       # Sine wave
    $g->amplitude(4)      # 4v peak-to-peak
    $g->offset(2)         # Dc offset of 2v

The GPIB::hp33120a module is a very simple module written in
completely in Perl.  It inherits GPIB and implements methods
that generate SCPI commands for the HP33120A functionality.
It's very easy to write these modules and create resuable
code useful for other projects.

=head1 POLYMORPHISM

A big word for a small piece of advice.  If device driver modules
that provide similar functionality for different devices adopt
consistent naming for their methods, application programmers can
write programs that might work across a number of devices.  For example,
if someone writes a new module for a function generator and she 
uses the same naming convention as GPIB::hp33120a, life is more
convenient for everyone:

    use GPIB::hp33120a;
    use GPIB::xyzgen;

    $g[0] = GPIB::hp33120a->new("device1");
    $g[1] = GPIB::xyzgen->new("device2");

    for (@g) {
        $_->freq(1000000.0);
        $_->shape(SIN);
    }

In the example above, an array contains references to function
generators.  The loop sets all function generators to 1MHz 
sine waves without knowledge of the details of each device.  This
is a really great concept, but it only works if a consistent 
naming convention is used for similar modules.  Please keep this 
in mind when you write new instrument drivers.

=head1 CONFIGURATION

/etc/pgpib.conf (C:\PGPIB.CONF on NT) contains local configuration
information.  It associates a name with the proper low level driver
and parameters for that driver.  In most cases, local configurations
issues can be resolved with this file.

The file has one device per line.  Blank lines or lines beginning with
a '#' are ignored.  The file is read once the first time GPIB->new()
is called.  From that point the configuration information is held
in memory in a hash called %gpib::config.  %gpib::config is a hash
keyed off the name of the entry.  Each element is a reference to an
array of parameters on the configuration line.  test.pl in the gpib
traverses this data structure.

Each parameter in the file can be either a string, a decimal number,
a hex number if it begins with '0x', or one of the National
Instruments timeout constants TNONE, T10us, T30uS, etc. 

It's not essential to have a /etc/pgpib.conf file, but it makes life
much easier to confine all local configuration issues to this one file.
If the address of a device is changed or if a device is moved from 
GPIB to a serial port, the only change required is in this file. 
When using Perl-GPIB the first time it's probably best to enter a device
or two into this file and do some simple tests from the Perl debugger
until you get confortable that things are working.  Here's a sample 
test on my setup:

    % perl -MGPIB::hp33120a -de1

    Loading DB routines from perl5db.pl version 1.0401
    Emacs support available.
    
      DB<1> $g = GPIB::hp33120a->new("HP33120A")

      DB<2> x $g->get
            0  'SIN'
            1  '1.000000000000E+06'
            2  '+1.000000E+00'
            3  '+0.000000E+00'

      DB<3> p $g->query('*IDN?')
            HEWLETT-PACKARD,33120A,0,7.0-4.0-1.0

Entries for the GPIB::ni (National Instruments GPIB) interface look
like this.  The parameters after GPIB::ni correspond to the 6 parameters
to ibdev():

  # NI GPIB card
  # name                      Board   PAD     SAD     TMO     EOT     EOS
  #
  K2002       GPIB::ni        0       0x10    0       T1s     1       0

Entries for the GPIB::rmt remote access interface look like this:

  # Remote connections
  # name        driver        machine          user   password  device
  #
  HP33120A      GPIB::rmt     sparky.mock.com  jeff   fiddle    HP33120A 

Entries for the GPIB::hpserial serial port interface look like this:

  # Serial port
  # name      driver              port        speed   TMO     EOS     FLAG
  #
  HP33120AS   GPIB::hpserial      /dev/cua1   9600    T3s     0x0a    0x0001


=head1 CREDIT

These modules were insprired by a GPIB module written by Steve Tell at 
the MSL at UNC (tell@cs.unc.edu).  Steve's module showed me 
how great Perl is as a language for GPIB programming.  So much 
of GPIB programming is munging text strings and Perl just can't be
beat for this.  

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), GPIB::hpserial(3), GPIB::ni(3), GPIB::hp33120a(3), pgpib.conf(4).

=cut

