package Hardware::Simulator::MIX;

use Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(new reset step mix_char mix_char_code get_overflow 
          is_halted read_mem write_mem set_max_byte get_pc 
          get_reg get_current_time get_max_byte
          get_exec_count get_exec_time get_last_error get_cmp_flag );

$VERSION   = 0.4;

use strict;
use warnings;

use constant 
{
    MIX_OK              => 0,
    MIX_HALT            => 1,
    MIX_ERROR           => 2,
    MIX_IOWAIT          => 3
};

# Unit 0 to 7 is tapes; Unit 8 to 15 is disks and drums.
# To specify a tape unit, the convention here is to write (U_TAPE + i).
# Typewriter and Papertape share the same unit number, 
# because they are physically combined.
use constant
{
    U_TAPE              => 0,
    U_DISK              => 8,
    U_CARDREADER        => 16,
    U_CARDPUNCH         => 17,
    U_PRINTER           => 18,
    U_TYPEWRITER        => 19,
    U_PAPERTAPE         => 19
};

# Op Dispatch Table
my @op_dispatch_table = (
    \&X_NOP,             #00
    \&X_ADD,             #01
    \&X_SUB,             #02
    \&X_MUL,             #03
    \&X_DIV,             #04
    \&X_MISC,            #05
    \&X_SHIFT,           #06
    \&X_MOVE,            #07
    \&X_LDA,             #08
    \&X_LDI,             #09
    \&X_LDI,             #10
    \&X_LDI,             #11
    \&X_LDI,             #12
    \&X_LDI,             #13
    \&X_LDI,             #14
    \&X_LDX,             #15
    \&X_LDAN,            #16
    \&X_LDIN,            #17
    \&X_LDIN,            #18
    \&X_LDIN,            #19
    \&X_LDIN,            #20
    \&X_LDIN,            #21
    \&X_LDIN,            #22
    \&X_LDXN,            #23
    \&X_STA,             #24
    \&X_STI,             #25
    \&X_STI,             #26
    \&X_STI,             #27
    \&X_STI,             #28
    \&X_STI,             #29
    \&X_STI,             #30
    \&X_STX,             #31
    \&X_STJ,             #32
    \&X_STZ,             #33
    \&X_JBUS,            #34
    \&X_IOC,             #35
    \&X_INPUT,           #36
    \&X_OUTPUT,          #37
    \&X_JRED,            #38
    \&X_JMP_COND,        #39
    \&X_JMP_REG,         #40
    \&X_JMP_REG,         #41
    \&X_JMP_REG,         #42
    \&X_JMP_REG,         #43
    \&X_JMP_REG,         #44
    \&X_JMP_REG,         #45
    \&X_JMP_REG,         #46
    \&X_JMP_REG,         #47
    \&X_ADDR_TRANSFER,   #48
    \&X_ADDR_TRANSFER,   #49
    \&X_ADDR_TRANSFER,   #50
    \&X_ADDR_TRANSFER,   #51
    \&X_ADDR_TRANSFER,   #52
    \&X_ADDR_TRANSFER,   #53
    \&X_ADDR_TRANSFER,   #54
    \&X_ADDR_TRANSFER,   #55
    \&X_CMP,             #56
    \&X_CMP,             #57
    \&X_CMP,             #58
    \&X_CMP,             #59
    \&X_CMP,             #60
    \&X_CMP,             #61
    \&X_CMP,             #62
    \&X_CMP,             #63
    );

my @regname = qw(rA rI1 rI2 rI3 rI4 rI5 rI6 rX);

################################################################
# Initialization
################################################################

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { @_ };
    bless $self, $class;

    $self->{max_byte} = 64 if !exists $self->{max_byte};

    $self->{timeunit} = 5  if !exists $self->{timeunit};
    $self->{ms} = 1000/$self->{timeunit};

    $self->{dev} = {};
    $self->reset();
    return $self; 
}

sub reset 
{
    my $self = shift;

    $self->{rA} = ['+', 0, 0, 0, 0, 0];
    $self->{rX} = ['+', 0, 0, 0, 0, 0];
    $self->{rJ} = ['+', 0, 0, 0, 0, 0];
    $self->{rZ} = ['+', 0, 0, 0, 0, 0];

    $self->{rI1} = ['+', 0, 0, 0, 0, 0];
    $self->{rI2} = ['+', 0, 0, 0, 0, 0];
    $self->{rI3} = ['+', 0, 0, 0, 0, 0];
    $self->{rI4} = ['+', 0, 0, 0, 0, 0];
    $self->{rI5} = ['+', 0, 0, 0, 0, 0];
    $self->{rI6} = ['+', 0, 0, 0, 0, 0];

    $self->{mem} = [];
    $self->{execnt} = [];
    $self->{exetime} = [];

    for (0 .. 3999) {
	push @{$self->{mem}}, ['+', 0, 0, 0, 0, 0];
	push @{$self->{execnt}}, 0;
	push @{$self->{exetime}}, 0;
    }

    $self->{devstat} = [];
    for (0 .. 19) {
        push @{$self->{devstat}}, {
            laststarted => 0,
            delay => 0
        };
    }

    # MIX running time from last reset, recorded in time units
    $self->{time}      = 0;
        
    $self->{pc}        = 0;
    $self->{next_pc}   = 0;
    $self->{ov_flag}   = 0;
    $self->{cmp_flag}  = 0;
    $self->{status}    = MIX_OK;
    $self->{message}   = 'running';
}

##############################################################################
# Instruction Execution
##############################################################################

# Execute an instruction, update the machine state
# Return 1 if successfully execute one; 0 if there are something happen.
# On returning zero, it is not necessarily an error, maybe
# you just need to type a line to get the program continue.
sub step
{
    my $self = shift;

    if ($self->{status} == MIX_IOWAIT) { # Need to read a line to proceed
	return 0;
    } elsif ($self->{status} != MIX_OK) {
	return 0;
    }

    my $start_time = $self->{time};

    # Fetch instruction

    my $loc = $self->{pc};
    if ($loc < 0 || $loc > 3999)
    {
	$self->{status} = MIX_ERROR;
	$self->{message} = "instruction overflow: $loc";
	return 0;
    }

    # one time unit for one memory access
    $self->{time} = $self->{time} + 1;

    # read instruction and unpack the fields
    my @word = @{@{$self->{mem}}[$loc]};
    my $c = $word[5];
    my $f = $word[4];
    my $r = $f % 8;
    my $l = int($f / 8);
    my $i = $word[3];
    my $a = $word[1] * $self->{max_byte} + $word[2];
    $a = ($word[0] eq '+')? $a : (0 - $a);
    my $m = $a;
    if ($i >= 1 && $i <= 6)
    {
	my $ireg = $self->{$regname[$i]};
	my $offset = @{$ireg}[4] * $self->{max_byte} + @{$ireg}[5];
	$offset = 0 - $offset if (@{$ireg}[0] eq '-');
	$m += $offset;
    }
    
    # default next program counter
    $self->{next_pc} = $self->{pc} + 1;

    # execute instruction
    if ($c >= 0 || $c <= 63 )
    {
	my $opfunc = $op_dispatch_table[$c];
	goto ERROR_INST if &{$opfunc}($self, $c, $f, $r, $l, $i, $a, $m) == 0;
    }
    else
    {
ERROR_INST:
	$self->{status} = MIX_ERROR;
	$self->{message} = "invalid instruction at $loc";
	return 0;
    }

    # update program counter
    $self->{pc} = $self->{next_pc};

    # update performance data
    @{$self->{execnt}}[$loc]++;
    @{$self->{exetime}}[$loc] += $self->{time} - $start_time;

    return 1;
}

# MIX "GO" button
sub go 
{
    my ($self) = @_;

    $self->load_card(0);
    while ($self->{status} == MIX_OK) {
	$self->step();
    }
}

sub X_ADD {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->add(\@tmp);
    return 1;
}

sub X_ADDR_TRANSFER {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    my $reg = $self->{$regname[$c-48]};
    if ($f == 0) { ## INC
	my $v = word_to_int($reg, $self->{max_byte});
	if (int_to_word($v+$m, $reg, $self->{max_byte})) {
	    $self->{ov_flag} = 0;
	} else {
	    $self->{ov_flag} = 1;
	}
    } elsif ($f == 1) { ## DEC
	my $v = word_to_int($reg, $self->{max_byte});
	if (int_to_word($v-$m, $reg, $self->{max_byte})) {
	    $self->{ov_flag} = 0;
	} else {
	    $self->{ov_flag} = 1;
	}
    } elsif ($f == 2) { ##ENT
	int_to_word($m, $reg, $self->{max_byte});
    } elsif ($f == 3) { ##ENN
	int_to_word(-$m, $reg, $self->{max_byte});
    } else {
	return 0;
    }

    return 1;
}

sub X_CMP {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    my $tmp1 = $self->get_reg($regname[$c-56], $l, $r);
    my $tmp2 = $self->read_mem_timed($m, $l, $r);
    $self->{cmp_flag} = $tmp1 - $tmp2;

    return 1;
}

sub X_DIV {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    return 0 if $f == 6;

    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->div(\@tmp);

    # DIV requires 10 additional time units
    $self->{time} += 10;
    return 1;
}

# Usage: $self->wait_until_device_ready($devnum)
#
# Used only before IN/OUT operations. 
# 
# If the device is busy, that is, the current time - last started < delay,
# increase the current time, so that the device would be ready
sub wait_until_device_ready
{
    my ($self, $devnum) = @_;

    return if $devnum < 0 || $devnum > 19;

    my $devstat = @{$self->{devstat}}[$devnum];
    my $laststarted = $devstat->{laststarted};

    # See whether the device is still busy
    if ($self->{time} - $laststarted < $devstat->{delay})
    {
        # advance the current system time to the point
        # that the device would be ready
        $self->{time} = $laststarted + $devstat->{delay};
    }
}

sub X_INPUT {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    $self->wait_until_device_ready($f);
    if ($f == U_CARDREADER) { ## CARD READER
	$self->load_card($m);
    } elsif ($f >= U_TAPE && $f < U_DISK) {
	$self->read_tape($f, $m);
    } elsif ($f >= U_DISK && $f < U_CARDREADER) {
	$self->read_disk($f, $m);
    } elsif ($f == U_TYPEWRITER) { # Input from typewriter
	$self->read_typewriter($m);
    } else {
	$self->{status} = MIX_ERROR;
	$self->{message} = "invalid input device(#$f)";
    }
    return 1;
}

sub X_IOC {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    $self->wait_until_device_ready($f);
    if ($f == U_PRINTER) { ## Printer: set up new page
	$self->new_page($m);
    } elsif (U_TAPE <= $f && $f <= (U_TAPE+7)) {
	$self->set_tape_pos($f, $m);
    } elsif (U_DISK <= $f && $f <= (U_DISK+7)) {
	$self->set_disk_pos($f);
    } elsif ($f == U_PAPERTAPE) {
	$self->rewind_paper_tape;
    } else {
	$self->{status} = MIX_ERROR;
	$self->{message} = "invalid ioc for device(#$f)";
    }
    return 1;
}

# Jump when device busy: always no busy
sub X_JBUS {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    return 1;
}

sub X_JMP_COND {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    return 0 if $f > 9;
    my $ok   = 1;
    my $savj = 0;
    my $cf   = $self->{cmp_flag};
    my @cond = ($cf<0,$cf==0,$cf>0,$cf>=0,$cf!=0,$cf<=0);

    if ($f == 0) {
	$ok = 1;
    }elsif ($f == 1) {
	$savj = 1;
    } elsif ($f == 2) {
	$ok = $self->{ov_flag};
    } elsif ($f == 3) {
	$ok = !$self->{ov_flag};
    } else {
	$ok = $cond[$f-4];
    }

    if ($ok) {
	if (!$savj) {
	    int_to_word($self->{next_pc}, $self->{rJ}, $self->{max_byte});
	}
	$self->{next_pc} = $m;
    }

    return 1;
}

sub X_JMP_REG {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    return 0 if $f > 5;
    my $val = $self->get_reg($regname[$c-40]);
    my @cond = ($val<0,$val==0,$val>0,$val>=0,$val!=0,$val<=0);
    if ($cond[$f]) {
	int_to_word($self->{next_pc}, $self->{rJ}, $self->{max_byte});
	$self->{next_pc} = $m;
    }
    return 1;
}

# Jump ready: jump immediately
sub X_JRED {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    int_to_word($self->{next_pc}, $self->{rJ}, $self->{max_byte});
    $self->{next_pc} = $m;

    return 1;
}

sub X_LDA {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->set_reg('rA', \@tmp);
    return 1;
}

sub X_LDAN {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    @tmp = neg_word(\@tmp);
    $self->set_reg('rA', \@tmp);
    return 1;
}

sub X_LDI {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->set_reg('rI' . ($c-8), \@tmp);
    return 1;
}

sub X_LDIN {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    @tmp = neg_word(\@tmp);
    $self->set_reg('rI' . ($c-16), \@tmp);
    return 1;
}

sub X_LDX {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->set_reg('rX', \@tmp);
    return 1;
}

sub X_LDXN {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    @tmp = neg_word(\@tmp);
    $self->set_reg('rX', \@tmp);
    return 1;
}

sub X_MISC {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    if ($f == 2) # HLT
    {
	$self->{status} = MIX_HALT;
	$self->{message} = 'halts normally';	
    }
    elsif ($f == 0) # NUM
    {
	my @a = @{$self->{rA}};
	my @x = @{$self->{rX}};
	my $m = $self->{max_byte};
	my $M = $m*$m*$m*$m*$m;
	my $sa = shift @a;
	shift @x;
	push @a, @x;
	my $val = 0;
	while (@a) {
	    my $d = shift @a;
	    $val = $val*10+($d % 10);
	}
	if ($val >= $M) {
	    $val = $val % $M;
	    $self->{ov_flag} = 1;
	} else {
	    $self->{ov_flag} = 0;
	}
	int_to_word($val, $self->{rA}, $m);
	@{$self->{rA}}[0] = $sa;
    }
    elsif ($f == 1) # CHAR
    {
	my $val = word_to_uint($self->{rA}, $self->{max_byte});
	my $i;
	for ($i = 5; $i >= 1; $i--) {
	    @{$self->{rX}}[$i] = 30 + $val%10;
	    $val = int($val/10);
	}
	for ($i = 5; $i >= 1; $i--) {
	    @{$self->{rA}}[$i] = 30 + $val%10;
	    $val = int($val/10);
	}
    }
    return 1;
}

sub X_MOVE {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    my $dest = $self->get_reg('rI1');
    for (my $i = 0; $i < $f; $i++, $m++, $dest++) {
	my @w = $self->read_mem_timed($m);
	$self->write_mem_timed($dest, \@w);
    }
    my @tmp = ('+', 0,0,0,0,0);
    int_to_word($dest, \@tmp, $self->{max_byte});
    $self->set_reg('rI1', \@tmp);

    return 1;
}

sub X_MUL {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    return 0 if $f == 6;

    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->mul(\@tmp);

    # MUL requires 8 additional time units
    $self->{time} += 8;
    return 1;
}

sub X_NOP {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    return 1;
}

sub X_OUTPUT {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    $self->wait_until_device_ready($f);
    if ($f == U_CARDPUNCH) { ## CARD Punch
	$self->punch_card($m);
    } elsif ($f == U_PRINTER)  { ## Printer
	$self->print_line($m);
    } elsif (U_TAPE <= $f && $f <= (U_TAPE+7)) {
	$self->write_tape($f, $m);
    } elsif (U_DISK <= $f && $f <= (U_DISK+7)) {
	$self->write_disk($f, $m);
    } elsif ($f == U_PAPERTAPE) { ## Output to paper tape
	$self->write_paper_tape($m);
    } else {
	$self->{status} = MIX_ERROR;
	$self->{message} = "invalid output device(#$f)";
    }

    return 1;
}

sub X_SHIFT {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;

    return 0 if $m < 0;

    my @a = @{$self->{rA}};
    my @x = @{$self->{rX}};
    my $sa = shift @a;
    my $sx = shift @x;
    if ($f == 0) { ## SLA
	$m = $m%5;
	while (--$m >= 0) {
	    shift @a;
	    push @a, 0;
	}
    } elsif ($f == 1) { ## SRA
	$m = $m%5;
	while (--$m >= 0) {
	    pop @a;
	    unshift @a, 0;
	}
    } elsif ($f == 2) { ## SLAX
	$m = $m%10;
	while (--$m >= 0) {
	    shift @a;
	    push @a, shift @x;
	    push @x, 0;
	}
    } elsif ($f == 3) { ## SRAX
	$m = $m%10;
	while (--$m >= 0) {
	    pop @x;
	    unshift @x, pop @a;
	    unshift @a, 0;
	}
    } elsif ($f == 4) { ## SLC
	$m = $m%10;
	while (--$m >= 0) {
	    push @a, shift @x;
	    push @x, shift @a;
	}
    } elsif ($f == 5) { ## SRC
	$m = $m%10;
	while (--$m >= 0) {
	    unshift @a, pop @x;
	    unshift @x, pop @a;
	}
    } else {
	return 0;
    }

    unshift @a, $sa;
    unshift @x, $sx;
    $self->set_reg('rA', \@a);
    $self->set_reg('rX', \@x);

    # shift operations takes additional 1 time unit
    $self->{time} = $self->{time} + 1;

    return 1;
}

sub X_STA {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    $self->write_mem_timed($m, $self->{rA}, $l, $r);
    return 1;
}

sub X_STI {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my $ri = 'rI' . ($c-24);
    $self->write_mem_timed($m, $self->{$ri}, $l, $r);
    return 1;
}

sub X_STJ {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    $self->write_mem_timed($m, $self->{rJ}, $l, $r);
    return 1;
}

sub X_STX {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    $self->write_mem_timed($m, $self->{rX}, $l, $r);
    return 1;
}

sub X_STZ {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    $self->write_mem_timed($m, $self->{rZ}, $l, $r);
    return 1;
}

sub X_SUB {
    my ($self, $c, $f, $r, $l, $i, $a, $m) = @_;
    my @tmp = $self->read_mem_timed($m, $l, $r);
    $self->minus(\@tmp);
    return 1;
}

##############################################################################
# Access registers and memory
##############################################################################

sub get_reg
{
    my ($self, $reg, $l, $r) = @_;

    if (!exists $self->{$reg}) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "accessing non-existed reg: $reg";
	return undef;
    }

    my @retval = @{$self->{$reg}};
    if (defined $l)
    {
	$r = $l if !defined $r;

	if ($l == 0)
	{
	    $l = 1;
	}
	else
	{
	    $retval[0] = '+';
	}

	my $i = 5;
	for (my $i = 5; $i > 0; $i--, $r--)
	{
	    if ($r >= $l)
	    {
		$retval[$i] = $retval[$r];
	    }
	    else
	    {
		$retval[$i] = 0;
	    }
	}
    }

    if (wantarray)
    {
	return @retval;
    }
    else
    {
	my $value = word_to_int(\@retval, $self->{max_byte});
	return $value;
    }
}

sub set_reg
{
    my ($self, $reg, $wref) = @_;

    if (!exists $self->{$reg}) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "accessing non-existed reg: $reg";
	return;
    }
    my @word = @{$wref};

    my $sign = '+';
    if (@{$wref}[0] eq '+' || @{$wref}[0] eq '-') {
	$sign = shift @{$wref};
    }
    @{$self->{$reg}}[0] = $sign;

    my $l = ($reg =~ m/r(I|J)/)?4:1;
    my $r = 5;
    while ($r >= $l && @word != 0) {
	@{$self->{$reg}}[$r] = pop @word;
	--$r;
    }
}


sub read_mem_timed
{
    my $self = shift;
    $self->{time} = $self->{time} + 1;
    return $self->read_mem(@_);
}

sub write_mem_timed
{
    my $self = shift;
    $self->{time} = $self->{time} + 1;
    return $self->write_mem(@_);
}


sub read_mem
{
    my ($self,$loc,$l, $r) = @_;

    if ($loc < 0 || $loc > 3999) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "access invalid memory location: $loc";
	return;
    }


    my @retval = @{@{$self->{mem}}[$loc]};
    if (defined $l)
    {
	$r = $l if !defined $r;

	if ($l == 0)
	{
	    $l = 1;
	}
	else
	{
	    $retval[0] = '+';
	}

	my $i = 5;
	for (my $i = 5; $i > 0; $i--, $r--)
	{
	    if ($r >= $l)
	    {
		$retval[$i] = $retval[$r];
	    }
	    else
	    {
		$retval[$i] = 0;
	    }
	}
    }

    if (wantarray)
    {
	return @retval;
    }
    else
    {
	my $value = word_to_int(\@retval, $self->{max_byte});
	return $value;
    }
}

# $loc: location, must be in [0..3999]
# $wref: reference to a mix word
# $l,$r: field specification of destinated word, 0<=$l<=$r<=5
sub write_mem
{
    my ($self,$loc,$wref, $l, $r) = @_;

    if ($loc < 0 || $loc > 3999) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "access invalid memory location: $loc";
	return;
    }

    my @word = @{$wref};

    if (!defined $l) {
	$l = 0;
	$r = 5;
    } elsif (!defined $r) {
	$r = $l;
    }
    my $dest = @{$self->{mem}}[$loc];

    for (my $i = $r; $i >= $l;  $i--) {
	@{$dest}[$i] = pop @word if $i > 0;
	if ($i == 0) {
	    if (@word > 0 && ($word[0] eq '+' || $word[0] eq '-')) {
		@{$dest}[0]  = $word[0];
	    } else {
		@{$dest}[0]  = '+';
	    }
	}
    }

}

#######################################################################
# Arithmetic Operations
#######################################################################

sub add
{
    my ($self, $w) = @_;
    my $m = $self->{max_byte};
    my $a = $self->{rA};

    if (!int_to_word(word_to_int($w,$m)+word_to_int($a,$m), $a, $m)) {
	$self->{ov_flag} = 1;
    } else {
	$self->{ov_flag} = 0;
    }
}

sub minus
{
    my ($self, $w) = @_;
    my @t = @{$w};
    if ($t[0] eq '+') {
	$t[0] = '-';
    } else {
	$t[0] = '+';
    }
    $self->add(\@t);
}

sub mul
{
    my ($self, $w) = @_;
    my $a = $self->{rA};
    my $x = $self->{rX};
    my $m = $self->{max_byte};
    my $M = $m*$m*$m*$m*$m;

    my $v = word_to_int($a,$m)*word_to_int($w,$m);

    my $sign = ($v>=0?'+':'-');
    $v = -$v if $v < 0;

    int_to_word($v%$M, $x, $m);
    int_to_word(int($v/$M), $a, $m);

    @{$x}[0] = @{$a}[0] = $sign;
    $self->{ov_flag} = 0;
}

sub div
{
    my ($self, $w) = @_;
    my $a = $self->{rA};
    my $x = $self->{rX};
    my $m = $self->{max_byte};
    my $M = $m*$m*$m*$m*$m;

    my $v  = word_to_uint($w,$m);

    if ($v==0) {
	$self->{ov_flag} = 1;
	return;
    }

    my $va = word_to_uint($a,$m);
    my $vx = word_to_uint($x,$m);
    my $V  = $va*$M+$vx;

    my $sign;
    my $sa = @{$a}[0];
    if ($sa eq @{$w}[0]) {
	$sign = '+';
    } else {
	$sign = '-';
    }
    
    int_to_word($V%$v, $x, $m);
    @{$x}[0] = $sa;
    if (int_to_word(int($V/$v), $a, $m)) {
	$self->{ov_flag} = 0;
    } else {
	$self->{ov_flag} = 1;
    }
    @{$a}[0] = $sign;
}


sub set_max_byte
{
    my $self = shift;
    $self->{max_byte} = shift;
}

sub get_max_byte
{
    my $self = shift;
    return $self->{max_byte};
}

sub get_last_error
{
    my $self = shift;
    my $status = $self->{status};
    my $msg = uc($self->{message});
    return "OK"   if $status == MIX_OK;
    return "HALT" if $status == MIX_HALT;
    return $msg   if $status == MIX_ERROR;
    return "WAIT IO READY - " . $msg if $status == MIX_IOWAIT;
}


# For tape and disk units, each item in buffer is a word, like
#   ['+', 0, 0, 0, 1, 2]
# For card reader and punch, each item of buffer is a line.        
# For printer, each item of buffer is a page.
# e.g.   $mix->add_device(16, \@cards);
sub add_device 
{
    my ($self, $u, $buf) = @_; 
    # FIXME: paper tape?
    return 0 if $u > 19 || $u < 0;
    $self->{dev}->{$u} = {};
    if (defined $buf) {
	$self->{dev}->{$u}->{buf} = $buf;
    } else {
	$self->{dev}->{$u}->{buf} = [];
    }
    $self->{dev}->{$u}->{pos} = 0;
    return 1;
}


sub get_overflow
{
    my $self = shift;
    return $self->{ov_flag};
}

sub get_cmp_flag
{
    my $self = shift;
    return $self->{cmp_flag};
}

sub get_pc
{
    my $self = shift;
    return $self->{pc};
}

sub get_current_time
{
    my $self = shift;
    return $self->{time};
}

sub get_exec_count
{
    my ($self, $loc) = @_;
    return @{$self->{execnt}}[$loc];
}

sub get_exec_time
{
    my ($self, $loc) = @_;
    return @{$self->{exetime}}[$loc];
}


sub get_device_buffer 
{
    my $self = shift;
    my $u = shift;
    if (exists $self->{dev}->{$u}) {
	return $self->{dev}->{$u}->{buf};
    } else {
	return undef;
    }    
}

sub write_tape 
{
    my ($self, $u, $m) = @_;

    #FIXME: error checking

    my $tape = $self->{dev}->{$u};
    my $n = @{$tape->{buf}};    
    for (my $i = 0; $i < 100; $i++) {	
	my @w = $self->read_mem($m+$i);
	if ($tape->{pos} < $n) {
	    @{$tape->{buf}}[ $tape->{pos} ] = \@w;
	} else {
	    push @{$tape->{buf}}, \@w;
	}
	$tape->{pos}++;
    }    

}

sub read_tape 
{
    my ($self, $u, $m) = @_;

    #FIXME: error checking

    my $tape = $self->{dev}->{$u};
    my $n = @{$tape->{buf}};    

    for (my $i = 0; $i < 100 && $tape->{pos} < $n; $i++) {	
	my $w = @{$tape->{buf}}[ $tape->{pos} ];
	$self->write_mem($m+$i, $w);
	$tape->{pos}++;
    }        
}


# TODO: tape and disk io

# device ability is aligned with IBM1130.org
# tape io: 10ms
# disk io: 10ms
# seek : 10ms

sub set_tape_pos {
    my ($self) = @_;
}
sub set_disk_pos {
    my ($self) = @_;
}
sub write_disk {
    my ($self) = @_;
}
sub read_disk {
    my ($self) = @_;
}

# Load cards into memory started at $loc
sub load_card 
{
    my ($self,$loc) = @_;

    # Check if card reader installed
    if (!exists $self->{dev}->{+U_CARDREADER}) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "missing card reader";
	return 0;
    }

    my $reader = $self->{dev}->{+U_CARDREADER};
    my $buf = $reader->{buf};
    my $pos = $reader->{pos};

    # Check if there are cards unread
    if ($pos >= @{$buf}) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "no card in card reader";
	return 0;
    }
    
    my $crd = @{$buf}[$pos];
    $reader->{pos}++;

    # Pad spaces to make the card have 80 characters
    if (length($crd)!=80) {
	$crd .= " " x (80-length($crd));
    }
    my @w = ('+');
    for (my $i = 0; $i < 80; $i++) {
	my $c = mix_char_code( substr($crd,$i,1) );
	if ($c == -1) {
	    $self->{status} = MIX_ERROR;
	    $self->{message} = "invalid card: '$crd'";
	    return 0;
	} else {
	    push @w, $c;
	    if (@w == 6) {
		$self->write_mem($loc++, \@w);
		@w = ('+');
	    }
	}
    }

    my $devstat = @{$self->{devstat}}[U_CARDREADER];
    $devstat->{laststarted} = $self->{time};
    # Read one card need 0.1 second
    $devstat->{delay} = 100 * $self->{ms};
    
    return 1;
}


sub punch_card 
{
    my ($self, $loc) = @_;

    if (!exists $self->{dev}->{+U_CARDPUNCH}) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "missing card punch";
	return;
    }    

    my $crd;
    for (my $i = 0; $i < 16; $i++) {
	my @w = $self->read_mem($loc++);
	shift @w;
	while (@w) {
	    my $ch = mix_char(shift @w);
	    if (defined $ch) {
		$crd .= $ch; 
	    } else {
		$crd .= "^";
	    }
	}
    }

    my $dev = $self->{dev}->{+U_CARDPUNCH};
    push @{$dev->{buf}}, $crd;

    my $devstat = @{$self->{devstat}}[U_CARDPUNCH];
    $devstat->{laststarted} = $self->{time};
    $devstat->{delay} = 500 * $self->{ms}; # Punch 2 cards per second
}

sub print_line 
{
    my ($self, $loc) = @_;
    my $printer = $self->{dev}->{+U_PRINTER};
    if (!defined $printer) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "missing printer";
	return;
    }

    my $page = pop @{$printer->{buf}};
    $page = "" if !defined $page;

    my $line;
    for (my $i = 0; $i < 24; $i++) {
	my @w = $self->read_mem($loc++);
	shift @w;
	while (@w) {
	    my $ch = mix_char(shift @w);
	    if (defined $ch) {
		$line .= $ch; 
	    } else {
		$line .= "^";
	    }
	}
    }
    $line =~ s/\s+$//;
    $page .= $line . "\n";
    push @{$printer->{buf}}, $page;

    my $devstat = @{$self->{devstat}}[U_PRINTER];
    $devstat->{laststarted} = $self->{time};
    $devstat->{delay} = 100 * $self->{ms}; # Print 10 lines per second
}

sub new_page 
{
    my ($self, $m) = @_;
    my $printer = $self->{dev}->{+U_PRINTER};

    if (!defined $printer) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "missing printer";
	return;
    }

    if ($m == 0) {
	push @{$printer->{buf}}, "";
    } else {
	$self->{status} = MIX_ERROR;
	$self->{message} = "printer ioctrl error: M should be zero";
    }

    my $devstat = @{$self->{devstat}}[U_PRINTER];
    $devstat->{laststarted} = $self->{time};
    $devstat->{delay} = 10 * $self->{ms};
}


sub read_typewriter
{
    my ($self, $loc) = @_;
    # FIXME: use constant
    my $typewriter = $self->{dev}->{19};

    if (!defined $typewriter) {
	$self->{status} = MIX_ERROR;
	$self->{message} = "missing typewriter";
	return 0;
    }

    if (!exists($typewriter->{line}))
    {
	$self->{status} = MIX_IOWAIT;
	$self->{message} = "need to type a line";
	return 0;
    }

    my $line = $typewriter->{line};
    # Pad spaces to make the line has 70 characters
    if (length($line)!=70) {
	$line .= " " x (70-length($line));
    }
    my @w = ('+');
    for (my $i = 0; $i < 70; $i++) {
	my $c = mix_char_code( substr($line,$i,1) );
	if ($c == -1) {
	    $self->{status} = MIX_ERROR;
	    $self->{message} = "invalid line: '$line'";
	    return 0;
	} else {
	    push @w, $c;
	    if (@w == 6) {
		$self->write_mem($loc++, \@w);
		@w = ('+');
	    }
	}
    }

    my $devstat = @{$self->{devstat}}[19];
    $devstat->{laststarted} = $self->{time};
    $devstat->{delay} = 100 * $self->{ms}; # Read 10 cards per second
    
    
}

sub is_halted 
{
    my $self = shift;
    return 0 if $self->{status} == MIX_OK;
    return 1;
}


########################################################################
# Utilities
########################################################################

# Input: partial word, for example, (+ 10 20)
# Output: add 0s to fix the word: (+ 0 0 0 10 20)
# For load instructions when reading only part of the fields.
sub fix_word
{
    my @tmp = @_;
    my $sign = shift @tmp;
    if ($sign eq '+' || $sign eq '-') {
	
    } else {
	unshift @tmp, $sign;
	$sign = '+';
    }
    while (@tmp != 5) {
	unshift @tmp, 0;
    }
    unshift @tmp, $sign;
    return @tmp;
}

sub neg_word
{
    my @tmp = @{$_[0]};
    if ($tmp[0] eq '-') {
	$tmp[0] = '+';
    } elsif ($tmp[0] eq '+') {
	$tmp[0] = '-';
    } else {
	unshift @tmp, '-';
    }
    return @tmp;
}

sub word_to_int
{
    my ($wref, $m) = @_;
    my $val = 0;
    
    $m = 64 if (!defined $m); 
    
    for my $i (1 .. 5) {
	$val = $val * $m + @{$wref}[$i];
    }
    if (@{$wref}[0] eq '+') {
	return $val;
    } else {
	return -$val;
    }
}

sub word_to_uint
{
    my ($wref, $m) = @_;
    my $val = 0;
    
    $m = 64 if (!defined $m); 
    
    for my $i (1 .. 5) {
	$val = $val * $m + @{$wref}[$i];
    }
    return $val;
}

# If overflow return 0;
# If ok, return 1;
sub int_to_word
{
    my ($val, $wref, $m) = @_;
    my $i = 5;

    $m = 64 if (!defined $m); 

    if ($val < 0) {
	@{$wref}[0] = '-';
	$val = -$val;
    } else {
	@{$wref}[0] = '+';
    }

    for (; $i > 0; $i--) {
	@{$wref}[$i] = $val % $m;
	$val = int($val/$m);
    }
    return $val==0;
}

my $debug_mode = 0;

sub debug 
{
    return if !$debug_mode;
    print "DEBUG: ";
    print $_ foreach @_;
    print "\n";
}

my $mix_charset = " ABCDEFGHI^JKLMNOPQR^^STUVWXYZ0123456789.,()+-*/=\$<>@;:'";

# Return a MIX char by its code.
# valid input: 0 .. 55
# If the input is not in the range above, an `undef' is returned.
sub mix_char 
{
    return undef if $_[0] < 0 || $_[0] >= length($mix_charset);
    return substr($mix_charset, $_[0], 1);
}

# Return code for a MIX char
# If not found, return -1.
# Note, char '^' is not a valid char in MIX charset.
sub mix_char_code 
{ 
    return -1 if $_[0] eq "^";
    return index($mix_charset, $_[0]); 
}

1;

__END__

=head1 NAME

Hardware::Simulator::MIX - A simulator of Knuth's famous virtual machine

=head1 SYNOPSIS
  
    use Hardware::Simulator::MIX;

    my $mix = new Hardware::Simulator::MIX;
    while (!$mix->is_halted()) {
        $mix->step();
    }

=head1 DESCRIPTION

This implementation includes the GO button and the default loader is the answer to
Exercise 1.3 #26.

Trace execution count and time for every instruction.

For detailed architecture information, search MIX in wikipedia.

=head1 CONSTRUCTOR

    $mix = Hardware::Simulator::MIX->new(%options);

This method constructs a new C<Hardware::Simulator::MIX> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

    KEY                     DEFAULT
    -----------             --------------------
    max_byte                64
    timeunit                5   (microseconds, not milliseconds)

C<max_byte> is the maximum value a MIX byte can express.
C<timeunit> is one memory access time.
According to knuth, in 1960s, one time unit on a high-priced machine is 1 us. 
and for a low cost computer it is 10 us.  
To change the default settings, do like this:

    $mix = Hardware::Simulator::MIX->new(max_byte => 100, timeunit => 10);

=head1 MACHINE STATE

=over 4

=item Registers

Accessing registers:

    $mix->{reg_name}

It is a reference to a MIX word. A MIX word is an array of six elements.
Element 0 is the sign of word,
with value either '+' or '-'. Elements 1~5 are MIX bytes with numerical values.
Available registers are listed below:

    REGNAME                FORMAT
    -----------            -----------------------
    rA                     [?, ?, ?, ?, ?, ?]
    rX                     [?, ?, ?, ?, ?, ?]
    rI1                    [?, 0, 0, 0, ?, ?]
    rI1                    [?, 0, 0, 0, ?, ?]
    rI2                    [?, 0, 0, 0, ?, ?]
    rI3                    [?, 0, 0, 0, ?, ?]
    rI4                    [?, 0, 0, 0, ?, ?]
    rI5                    [?, 0, 0, 0, ?, ?]
    rI6                    [?, 0, 0, 0, ?, ?]
    rJ                     [?, 0, 0, 0, ?, ?]
    pc                     Integer in 0..3999

Note: the names are case sensitive.

    $mix->get_reg($reg_name);
    $mix->set_reg($reg_name, $wref);

For registers rI1 ~ rI6, rJ, the bytes 1~3 are always set to zero.
You should not modify them. Or the result will be undefined.

=item Memory

A MIX memory word is similar to the register rA and rX word.

    $mix->read_mem($loc);
    $mix->read_mem($loc, $l);
    $mix->read_mem($loc, $l, $r);

Return a MIX word from memory. C<$loc> must be among 0 to 3999. 
If field spec C<$l> and C<$r> are missing, they are 0 and 5;
If C<$r> is missing, it is same as C<$l>.

    $mix->read_mem(4);

equals to

    $mix->read_mem(4,4);

Write memory.

    $mix->write_mem($loc, $wref, $l, $r);

=item Status

$mix->get_cmp_flag() returns an integer. If the returned value is
negative, the flag is "L"; if the return value is positive, the flag
is "G"; if the return value is 0, the flag is "E".

$mix->get_overflow() return 0 if there is no overflow. return 1 if
overflow happen.

$mix->get_current_time() returns the current mix running time in time
units since the last reset.

$mix->is_halted() returns 1 if the machine halts.

=back

=head1 TRACING

=over 4

=item Get the execution count of an instruction

    $mix->get_exec_count($loc);

=item Get the time spent on an instruction

The result is in MIX time units.

    $mix->get_exec_time($loc);

=back

=head1 EXECUTION

=over 4


=item $mix->reset()

Reset machine status to initial state.
Automatically invoked when a MIX object is created.
Clear the machine memory and registers to zero.
Discard all statistics. 
PC will be cleared to zero, so next time the machine
will read instruction from location zero.

=item $mix->step()

Execute one instruction. Return 1 if success, otherwise return 0.
Please check the machine status when this method returns 0.

=item $mix->go()

Simulate MIX go button. Load a card into location 0, and then
execute instructions from 0 until a halt condition is met, 
either by error or by the instruction HLT.

=back

=head1 IO DEVICES

General information about MIX io devices.

    Unit number          Device            
    ===========          ======
         t               Tape (0 <= t <= 7)
         d               Disk or drum (8 <= d <= 15)
         16              Card reader
         17              Card punch
         18              Printer
         19              Typewriter and paper tape

Unit 16,17,18 are oftener used.

Each type of device has its own buffer convention.
Card reader 's buffer is an array of strings.
Each string is a card. The maximum length of a card is 80 characters.
The first item in the array is always the first to be consumed by the machine.
When MIX executes one C<IN ?,?(16)> instruction, the first card will be read in,
and that card is also discarded out of the buffer. 

Printer's buffer is for output, it is also array of strings.
Each string is a page.

=over 4

=item $mix->add_device($devnum, $buf)

Register a device with its buffer.

=item $mix->get_device_buffer($devnum)

Return the reference to the device buffer.

=item $mix->load_card($loc)    

Load the first card in the card reader buffer into memory, 
starting from location C<$loc>.

=back

=head1 MIX LOADER

When you press the MIX GO button, MIX firstly loads the first
card into memory 0000~0015, and then executes from location 0.

Please refer to Section 1.3.1, Exercise 26.

=head1 AUTHOR

Chaoji Li<lichaoji@gmail.com>

http://www.litchie.net

Please feel free to send a email to me if you have any question.

=head1 SEE ALSO
 
The package also includes a mixasm.pl which assembles MIXAL programs. Usage:

    perl mixasm.pl <yourprogram>

This command will generate a .crd file which is a card deck to feed into the mixsim.pl.
Typical usage:

    perl mixsim.pl <yourprogram.crd>

=cut
