use lib "./lib";
use Hardware::Simulator::MIX;
use Data::Dumper;
use Getopt::Long;

my $opt_byte_size = 64;
my $opt_batch_mode = 0;
my $opt_interactive_mode = 0;
my $opt_myloader = 0;
my $opt_verbose;
my $opt_help = 0;

my $opt_card_reader = "";
my $opt_card_punch = "";
my $opt_printer = "";
my $opt_tape0 = "";
my $opt_tape1 = "";
my $opt_tape2 = "";
my $opt_tape3 = "";
my $opt_tape4 = "";
my $opt_tape5 = "";
my $opt_tape6 = "";
my $opt_tape7 = "";
my $opt_disk0 = "";
my $opt_disk1 = "";
my $opt_disk2 = "";
my $opt_disk3 = "";
my $opt_disk4 = "";
my $opt_disk5 = "";
my $opt_disk6 = "";
my $opt_disk7 = "";


GetOptions ("bytesize=i"   => \$opt_byte_size,
            "cardreader=s" => \$opt_card_reader,
            "cardpunch=s"  => \$opt_card_punch,
            "printer=s"    => \$opt_printer,
            "tape0=s"      => \$opt_tape0,
            "tape1=s"      => \$opt_tape1,
            "tape2=s"      => \$opt_tape2,
            "tape3=s"      => \$opt_tape3,
            "tape4=s"      => \$opt_tape4,
            "tape5=s"      => \$opt_tape5,
            "tape6=s"      => \$opt_tape6,
            "tape7=s"      => \$opt_tape7,
            "disk0=s"      => \$opt_disk0,
            "disk1=s"      => \$opt_disk1,
            "disk2=s"      => \$opt_disk2,
            "disk3=s"      => \$opt_disk3,
            "disk4=s"      => \$opt_disk4,
            "disk5=s"      => \$opt_disk5,
            "disk6=s"      => \$opt_disk6,
            "disk7=s"      => \$opt_disk7,
            "batch"        => \$opt_batch_mode,
            "interactive"  => \$opt_interactive_mode,
            "help"         => \$opt_help,
            "myloader"     => \$opt_myloader,
            "verbose"      => \$opt_verbose);

usage() if $opt_help;

$opt_card_reader = shift @ARGV if $opt_card_reader eq "";

my $next_unasm_loc = 0;

my @default_loader = (
		      " O O6 Y O6    I   B= D O4 Z IQ Z I3 Z EN    E   EU 0BB= H IU   EJ  CA. ACB=   EU",
		      " 1A-H V A=  CEU 0AEH 1AEN    E  CLU  ABG H IH A A= J B. A  9                    ");

my $mix = Hardware::Simulator::MIX->new(max_byte => $opt_byte_size);

install_devices();

########################################################################
# Batch Mode
########################################################################

if ($opt_batch_mode) {
    my $start_time = time();
    $mix->reset();
    $mix->go();
    if ($mix->{status} == 2) {
	print_machine_status();
    } 
    flush_devices();
    my $time = $mix->get_current_time();
    my $realtime = $time*$mix->{timeunit}/1000000;
    print "MIX RUN TIME: ", $time, "u, ", $realtime, "s\n";
    my $t = time() - $start_time;
    print "Simulation time: $t s\n";
    exit;
}

########################################################################
# Interactive Mode
########################################################################

my %break_points;
my $cmdtable = init_cmdtable();
my $memloc   = 0;
$mix->reset();

print "\n    M I X   S i m u l a t o r\n\n";
print "Type 'h' for help messages.\n";

$mix->load_card(0);
if ($mix->{status}==2) {
    print "\nLoader missing\n";
}

while (1) 
{
    print "MIX> ";
    my $cmdline = <STDIN>;
    chop($cmdline);
    $cmdline =~ s/^\s+//;
    my @args = split /\s+/, $cmdline;
    next if @args == 0;
    my $cmd = shift @args;
    my $cb = $cmdtable->{$cmd}->{cb};
    next if !defined $cb;
    &$cb(@args);
}
print "MIX TIME: ", $mix->get_current_time(), "\n";
exit(0);

########################################################################

sub init_cmdtable
{
    $cmdtable = {
        prt => {  help => "prt => Show current page, prt n => show page n",
		  cb => sub { show_page(@_) } },
	u => {  help => "Unasm",
		cb => sub {unasm(@_)} },
	b => {  help => "toggle break point",
		cb => sub {toggle_break_point(@_)}},
        s => {  help => "Step",
                cb => sub {step()} },
	g => {  help => "Go to location",
		cb => sub { run_until(@_)}},
	e => {  help => "Edit memory",
		cb => sub {edit_memory(@_)} },
	d => {  help => "Display memory",
		cb => sub { display_memory(@_) } },
	h => {  help => "Display help messages",
		cb => sub { help() } },
	q => {  help => "Quit",
		cb => sub { exit(0) } },
	r => {  help => "Display registers",
		cb => sub { print_machine_status() } }
    };
}

sub toggle_break_point
{
    my $loc = shift;
    return if !defined $loc;
    return if $loc < 0 || $loc > 3999;
    if (has_break_point($loc)) {
	$break_points{$loc} = 0;
    } else {
	$break_points{$loc} = 1;
    }
}

sub has_break_point
{
    my $loc = shift;
    return 0 if !defined $loc;
    return 0 if $loc < 0 || $loc > 3999;
    if (exists $break_points{$loc}) {
	return $break_points{$loc};
    } else {
	return 0;
    }
}

# show_page(optional $page_num)
#     print the newest page if $page_num is not specified.
#
sub show_page
{
    my $page_num = shift;
    my $pages = $mix->get_device_buffer(18);
    my $n = @{$pages};
    return if $n == 0;
    $page_num = $n if !defined $page_num || $page_num > $n;
    
    my $page = @{$pages}[$page_num-1];
    print "Page $page_num of $n\n";
    print $page;   
}

sub step
{
    $mix->step();
    print_machine_status();
}

sub run_until
{
    my ($loc) = @_;
    if ($mix->{status} != 0) {
        print $mix->{message}, "\n";
        return;
    }
    $mix->step();
    while ($mix->get_pc() != $loc && $mix->{status} == 0) {
	last if has_break_point($mix->get_pc());
        $mix->step();
    }
    print_machine_status();
}

sub help
{
    for (sort keys %{$cmdtable}) {
	print $_, "\t", $cmdtable->{$_}->{help}, "\n";
    }
}

sub display_memory
{
    my ($loc) = @_;
    $memloc = $loc if defined $loc;
    for ( $memloc .. $memloc+9 ) {
	my $loc = $_;
	next if $_ < 0;
	last if $_ > 3999;
	my @w = $mix->read_mem($_);
	printf "%04d: %s  %2d %2d %2d %2d %2d    ",
	$_, $w[0], $w[1], $w[2], $w[3], $w[4], $w[5];
	for (1 .. 5) {
	    my $ch = mix_char($w[$_]);
	    print $ch if defined $ch;
	    print '^' if!defined $ch;
	}

	print "\n";
    }

    $memloc += 10 if $memloc+10 < 4000;
}

sub edit_memory
{
    my ($loc) = @_;
    return if !defined $loc || $loc < 0;
    while ($loc < 4000) {
	printf "%04d: ", $loc;
	my $w = <STDIN>;
	chop($w);
	last if $w =~ /^\s*$/;
	$w =~ s/^\s+//;
	my @w = split /\s+/, $w;
	$mix->write_mem($loc, \@w);
	$loc++;
    }
}

sub usage {
    print STDERR "perl mixsim.pl [options] <mixprogram.crd>\n";
    print STDERR "   --bytesize=<number>\n";
    print STDERR "   --cardreader=<file>\n";
    print STDERR "   --cardpunch=<file>\n";
    print STDERR "   --printer=<file>\n";
    print STDERR "   --tape[0-7]=<file>\n";
    print STDERR "   --disk[0-7]=<file>\n";
    print STDERR "   --batch\n";
    print STDERR "   --help\n";
    print STDERR "   --myloader=<cardfile>\n";
    print STDERR "   --verbose\n";
    exit(1);
}

sub install_devices {
    my @cards = @default_loader;
    my @opt_tape = ($opt_tape0, $opt_tape1, $opt_tape2, $opt_tape3, 
		    $opt_tape4, $opt_tape5, $opt_tape6, $opt_tape7);
    my @opt_disk = ($opt_disk0, $opt_disk1, $opt_disk2, $opt_disk3,
		    $opt_disk4, $opt_disk5, $opt_disk6, $opt_disk7);
    if (open CRDFILE, "<$opt_card_reader") {
	while (<CRDFILE>) {
	    chop;
	    push @cards, $_ if length($_) > 0;
	}
	close CRDFILE;
    }

    $mix->add_device(16,\@cards);
    $mix->add_device(18);
    $mix->add_device(17);

    my $u = 0;

    foreach( @opt_tape ) {
	my @words = ();
	if ($_ ne "" && open TAPEFILE, "<$_") {
	    while(<TAPEFILE>) {
		chop;
		next if m/^\s*$/;
		my @tmp = split;
		push @words, \@tmp;
	    }      
	    close TAPEFILE;
	}
	$mix->add_device($u++, \@words);
    }

    foreach ( @opt_disk) {
	my @words = ();
	if ($_ ne "" && open DISKFILE, "<$_") {
	    while(<DISKFILE>) {
		chop;
		next if m/^\s*$/;
		my @tmp = split;
		push @words, \@tmp;
	    }
	    close DISKFILE;
	}
	$mix->add_device($u++, \@words);
    }
}

sub flush_devices {
    my @opt_tape = ($opt_tape0, $opt_tape1, $opt_tape2, $opt_tape3, 
		    $opt_tape4, $opt_tape5, $opt_tape6, $opt_tape7);
    my @opt_disk = ($opt_disk0, $opt_disk1, $opt_disk2, $opt_disk3,
		    $opt_disk4, $opt_disk5, $opt_disk6, $opt_disk7);
    my $u = 0;
    foreach (@opt_tape) {
	if ($_ ne "") {
	    if (open DISKFILE, ">$_") {
		my $buf = $mix->get_device_buffer($u);
		foreach (@{$buf}) {
		    my @w = @{$_};
		    printf DISKFILE "%s %2d %2d %2d %2d %2d\n", 
		    $w[0], $w[1], $w[2],$w[3],$w[4],$w[5];
		}
		close DISKFILE;
	    } else {
		print STDERR "MIX: can not flush unit %u to file $_\n";
	    }	
	}
	$u++;
    }
    foreach (@opt_disk) {
	if ($_ ne "") {
	    if (open DISKFILE, ">$_") {
		my $buf = $mix->get_device_buffer($u);
		foreach (@{$buf}) {
		    my @w = @{$_};
		    printf DISKFILE "%s %2d %2d %2d %2d %2d\n", 
		    $w[0], $w[1], $w[2],$w[3],$w[4],$w[5];
		}
		close DISKFILE;
	    } else {
		print STDERR "MIX: can not flush unit %u to file $_\n";
	    }
	}
	$u++;
    }

    my $buf = $mix->get_device_buffer(17);
    if ($opt_card_punch ne "" && open CRDFILE, ">$opt_card_punch") {
	foreach (@{$buf}) {
	    print CRDFILE $_, "\n";
	}
	close CRDFILE;
    } elsif (@{$buf} > 0) {	
	print "[CARD PUNCH]\n";
	foreach (@{$buf}) {
	    print $_, "\n";
	}
    }

    $buf = $mix->get_device_buffer(18);
    if (@{$buf} > 0) {
	my $tot = @{$buf};
	my $pg = 1;
	if ($opt_printer ne "" && open PRTFILE, ">$opt_printer") {	
	    foreach (@{$buf}) {
		print PRTFILE "[PAGE $pg/$tot]\n";
		print PRTFILE $_;
		$pg++;
	    }
	    close PRTFILE;
	} else {
	    foreach (@{$buf}) {
		print "[PRINTER $pg/$tot]\n";
		print $_;
		$pg++;
	    }	    
	}
    }
}

################################################################
#
# UN-ASSEMBLER
#
################################################################

sub unasm_word
{
  my %unasm_table = (
	1  => "ADD FADD",
	2  => "SUB FSUB",
	3  => "MUL FMUL",
	4  => "DIV FDIV",
	5  => "NUM CHAR HLT",
	6  => "SLA SRA SLAX SRAX SLC SRC",

	55 => "INCX DECX ENTX ENNX",
	54 => "INC6 DEC6 ENT6 ENN6",
	53 => "INC5 DEC5 ENT5 ENN5",
	52 => "INC4 DEC4 ENT4 ENN4",
	51 => "INC3 DEC3 ENT3 ENN3",
	50 => "INC2 DEC2 ENT2 ENN2",
	49 => "INC1 DEC1 ENT1 ENN1",
	48 => "INCA DECA ENTA ENNA",
	47 => "JXN JXZ JXP JXNN JXNZ JXNP",
	46 => "J6N J6Z J6P J6NN J6NZ J6NP",
	45 => "J5N J5Z J5P J5NN J5NZ J5NP",
	44 => "J4N J4Z J4P J4NN J4NZ J4NP",
	43 => "J3N J3Z J3P J3NN J3NZ J3NP",
	42 => "J2N J2Z J2P J2NN J2NZ J2NP",
	41 => "J1N J1Z J1P J1NN J1NZ J1NP",
	40 => "JAN JAZ JAP JANN JANZ JANP",
	39 => "JMP JSJ JOV JNOV JL JE LG JGE JNE JLE");

    my @unasm_ops = qw(MOVE
                       LDA  LD1  LD2  LD3  LD4  LD5  LD6  LDX
                       LDAN LD1N LD2N LD3N LD4N LD5N LD6N LDXN
                       STA  ST1  ST2  ST3  ST4  ST5  ST6  STX
                       STJ  STZ  JBUS IOC  IN   OUT  JRED);

    my @w = @_;
    my $a = $w[1] * $mix->get_max_byte() + $w[2];
    $a = -$a if $w[0] eq '-';
    my $i = $w[3];
    my $f = $w[4];
    my $c = $w[5];
    my $op;

  if ($c >= 7 && $c <= 38) {
      $op = $unasm_ops[$c - 7];
  } elsif ($c == 0) {
      $op = "NOP";
  } elsif ($c == 56) {
      $op = "FCMP" if $f == 6;
      $op = "CMPA" if $f != 6;
  } elsif (57 <= $c && $c <= 62) {
      $op = "CMP" . $c - 56;
  } elsif (63 == $c) {
      $op = "CMPX";
  } else {
      $f -= 5 if 1 <= $c && $c <= 4;
      my @t = split(/ /, $unasm_table{$c});
      $op = @t[$f];
  }

    $op = "???" if !defined $op;
    return sprintf "%-5s%d,%d(%d)", $op, $a, $i, $f;
}

sub unasm
{
    my $loc = shift;
    $loc = $next_unasm_loc if !defined $loc;
    $loc = 0 if $loc > 3999 || $loc < 0;
    
    my $end = $loc + 10;
    while ($loc >= 0 && $loc < $end && $loc < 4000) {
	my @w = $mix->read_mem($loc);
	printf "%04d: %s  %2d %2d %2d %2d %2d  %s %-20s",
	  $loc, $w[0], $w[1], $w[2], $w[3], $w[4], $w[5],
	  has_break_point($loc)?">":" ",
	  unasm_word(@w);

	if ($mix->get_exec_count($loc) > 0) {
	    printf "  %8d %11d u", $mix->get_exec_count($loc), $mix->get_exec_time($loc);
	}
	printf "\n";
	$loc++;
    }
    $next_unasm_loc = $loc;
}

sub alf_word
{
    my @word = @_;
    my $s = "";
    for (my $i = 1; $i <= 5; $i++) {
	my $ch = mix_char($word[$i]);
	$s .= $ch if  defined $ch;
	$s .= ' ' if !defined $ch;
    }
    return $s;
}

sub print_machine_status
{
    my @word  = $mix->get_reg('rA');
    my $value = $mix->get_reg('rA');
    printf(" rA: %s %02d %02d %02d %02d %02d %s%-10d %s%s%s%s%s\n",
	   $word[0],
	   $word[1], $word[2], $word[3], $word[4], $word[5],
	   $word[0],
	   $value >= 0? $value : -$value,
	   alf_word(@word));
    @word  = $mix->get_reg('rX');
    $value = $mix->get_reg('rX');
    printf(" rX: %s %02d %02d %02d %02d %02d %s%-10d %s%s%s%s%s\n",
	   $word[0],
	   $word[1], $word[2], $word[3], $word[4], $word[5],
	   $word[0],
	   $value >= 0? $value : -$value,
	   alf_word(@word));

    for (my $i = 1; $i <= 6; $i++) {
	@word  = $mix->get_reg("rI$i");
	$value = $mix->get_reg("rI$i");
	printf("rI$i: %s %02d %02d %s%04d   ",
	       $word[0],
	       $word[4], $word[5],
	       $word[0],
	       $value >= 0? $value : -$value);	       
	print "\n" if $i % 2 == 0;
    }

    @word  = $mix->get_reg("rJ");
    $value = $mix->get_reg("rJ");
    printf(" rJ: %s %02d %02d %s%04d   ",
	   $word[0],
	   $word[4], $word[5],
	   $word[0],
	   $value >= 0? $value : -$value);	       
    
    my @flags = ("LT", "EQ", "GT");
    
    printf("%2s %2s  %su\n",
	   $mix->get_overflow() ? "OV" : "NO",
	   $flags[1 + $mix->get_cmp_flag()],
	   $mix->get_current_time());

    @word = $mix->read_mem($mix->get_pc());
    printf("%04d: %s\n", $mix->get_pc(), unasm_word(@word));
    printf("HALTED\n") if $mix->{status} == 1;
    printf("ERROR: %s\n", $mix->get_last_error()) if $mix->{status} >= 2;
}

__END__

=head1 NAME

Command line tool for running MIX programs using Hardware::Simulator::MIX

=head1 SYNOPSIS

    perl mixsim.pl primes.crd
    perldoc mixsim.pl

=head1 DESCRIPTION

The tools has basic debugging utilities. Like view memory (d),
unassemble(u), toggling break points(b), step(s), run to location(g),
view machine status(r, for registers).

=head2 Commands

=cut
