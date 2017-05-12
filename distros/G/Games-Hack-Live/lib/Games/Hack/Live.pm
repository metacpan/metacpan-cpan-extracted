#!/usr/bin/perl
# vim: set sw=2 expandtab : #
# Master version is at https://developer.berlios.de/projects/games-hack/


package Games::Hack::Live; 

use Expect;
use Getopt::Std;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Run);


$VERSION=0.62;


# Client program name
our($prg,
# Client PID
    $prg_pid,
# Timeout for GDB's answers
    $TIMEOUT,
# The Expect object connected to GDB
    $gdb,
# The STDIN Expect object
    $input,
# Whether the program should currently be running
    $should_be_running,
# Which extra strings we look for
    $callbacks,
# Patch commands
    @summary,
# Base path for file dumps
    $dumppath,
# Dump start number
    $dump,
# Patches to the program image
    @patches,
# GDB Prompt variables
    $gdb_prompt_base,
    $gdb_prompt_count,
    %cmd_opts);


sub Run
{
  Inits();
  StartDebuggee();
  GDBStart();


#	For debugging ...
#$gdb->log_file("/tmp/expect-log", "w");
#$gdb->debug(2);


  $quit=0;
  while (!$quit)
  {
    print "---> ";
    (undef, $error) = expect( undef, 
        '-i', [ $input ], 
        [ qr/^\s*dumpall(?:\s+(.+))?/i, \&DumpAll, ],
        [ qr/^\s*#/, sub { return 0; print "comment ignored\n"; 0; },  ],
        [ qr/^\s*cleanup/i, \&CleanUp, ],
        [ qr/^\s*help/i, \&Help, ],
        [ qr/^\s*find\s+(.+)/i, \&Find, ],
        [ qr/^\s*find/i, \&ShowMatches, ],
        [ qr/^\s*patch\s+(\S+)/i, \&PatchBin, ],
        [ qr/^\s*
            keepvalueat \s+             # command name
            (\S+)                       # address,
            (?:\s+|\s*=\s*)             # = or whitespace
            (?: \( ([\w ]+) \) \s* )?   # opt. type
            (\S+)                       # value
            (?:\s+["'](.+?)["'])?
            /ix, \&KeepValueAt, ],
        [ qr/^\s*
            killwrites \s+
            (\S+)                       # address
            (?: \s+ 
             (["'])(.+)\3              # opt. name
            )?
            (?: \s+
             (ask)                     # opt. flag to ask for description
            )?/ix, \&KillWrites, ],
        [ qr/^\s*(.+?)\s*$/, \&PassThru, ],
        [ 'eof', sub { $quit=1; 0; },  ],
        '-i', [ $gdb ],
        GDBmatches(1),
        );
  }

  print "\n\nQuitting ...\n";
  $gdb->send("kill\n");
  $gdb->send("q\n");
  $gdb->hard_close();

# Print results.
  print @summary;
}

###################################   The end. 
###################################****************************


###################################****************************
### ### ### ### ### ### ### ### ###   Initialization functions

# Set initial variables.
sub Inits
{
  $input = Expect->init(\*STDIN);

  $SIG{"INT"} = sub { 
    $should_be_running=0; 
    DebuggeeBreak(); 
    print "\nDebuggee stopped.\n"; 
  };

# Could we do the conversion using gdb?
# We can find out how many bytes that type has (print sizeof(...)),
# but how do we get the representation? (for searching)
  %type_convs = (
      "long"                => [ "l", 0 ],

      "char"                => [ "C", 0 ],
      "unsigned char"       => [ "C", 0 ],
      "signed char"         => [ "c", 0 ],

      "short"               => [ "s", 0 ],
      "signed short"        => [ "s", 0 ],
      "unsigned short"      => [ "S", 0 ],

      "int"                 => [ "i", 0 ],

      "unsigned"            => [ "I", 0 ],
      "unsigned int"        => [ "I", 0 ],
      "unsigned long"       => [ "L", 0 ],

      "long long"           => [ "q", 0 ],
      "unsigned long long"  => [ "Q", 0 ],

      "float"               => [ "f", 0.01 ],
      "double"              => [ "d", 0.01 ],
      "long double"         => [ "D", 0.01 ],
      );

  $|=1;

# Parse options
# Getopt::Std uses unqualified @ARGV, so that must be copied here.
  @ARGV=@main::ARGV;
  $Getopt::Std::STANDARD_HELP_VERSION=1;
  $main::VERSION=$VERSION;
  getopts("p:h", \%cmd_opts);


  $TIMEOUT=15; 
  $should_be_running=0;
  $callbacks=();
  $dumppath="/tmp";
  $dump=0;
  $gdb_prompt_base="GDB-delim-$$-" . time;
  $gdb_prompt_count="a000000";


  chomp($machine=`uname -m`);
  print "Loading patch library for $machine...\n";
  $machine =~ s#\W#_#;

  eval "use Games::Hack::Patch::$machine;";
  die $@ if $@;
}


# Start the program to-be-debugged
sub StartDebuggee
{
  $prg_pid=$cmd_opts{"p"};
  if ($prg_pid)
  {
  # program already started? find executable.
  }
  else
  {
    $prg=shift(@ARGV) || die "What should be debugged?\n"; 

    $prg_pid=fork();
    die "fork(): $!\n" unless defined($prg_pid);

    if (!$prg_pid)
    {
      exec($prg);
      die "exec($prg): $!\n";
    }

    print "Started $prg as $prg_pid.\n";
    # Wait for exec() to replace the binary.
    for(0 .. 3) 
    {
      select(undef,undef,undef, 0.2);
      last if readlink("/proc/$prg_pid/exe") ne readlink("/proc/$$/exe");
    }
  }

# The program may have been found via $PATH.
# For some things (like patching) we need the full path.
# TODO: works only on linux.
  $prg=readlink("/proc/$prg_pid/exe") || 
	  die "Executable of pid $prg_pid not determined: $!\n" . `ls -la "/proc/$prg_pid" ; ps fax`;

  print "Using $prg with pid $prg_pid\n";
}


# Start gdb, and attach to debuggee
sub GDBStart
{
  my($type);

  $gdb = new Expect;
  $gdb->raw_pty(1);
  $gdb->log_stdout(0);
  $gdb->spawn("gdb 2>&1", ()) or die "Cannot spawn gdb: $!\n";


  GDBSync($gdb);
  GDBSend("set pagination off");
  GDBSend("attach $prg_pid");

  CleanUp();

# Determine machine word sizes
  for $type (qw(short int long char), "long long")
  {
    print "print sizeof($type)\n";
    GDBSend("print sizeof($type)", GDBmatches(0));
    ($len) = ($gdb->before =~ m#\$\d+\s+=\s+(\d+)\s+#);
    $type_has_length{$type}=$len;
    $length_to_type[$len]=$type;
    print "got $type as $len\n";
  }

# We need to be able to write single bytes; more would be better, but is 
# not strictly necessary.
  die "No type with length 1 found!\n" 
    unless $length_to_type[1];

  $should_be_running=1;
  DebuggeeCont();
}


###################################****************************
### ### ### ### ### ### ### ### ###   GDB I/O

# Returns an array with currently allowed matches
# $cbs: include callbacks?
sub GDBmatches
{
  my($cbs)=@_;
  my(@a);

  @a=();
  map { push @a, [ $_, @{$callbacks{$_}} ]; } keys %callbacks 
    if $cbs;

  push @a,
       [ $gdb_prompt_delimiter, sub { $is_running=0; }, ],
       [ "Continuing", sub { $is_running=1; }, ];
  return @a;
}


# Change the GDB Prompt, and re-sync
# The debuggee must be stopped when calling that.
sub GDBSync
{
  my($obj)=@_;

  $gdb_prompt_count++;
  $gdb_prompt_delimiter = $gdb_prompt_base . "-" . $gdb_prompt_count . "-ZZ";
  $obj->print_log_file("new prompt set to $gdb_prompt_delimiter\n");
  $obj->send("set prompt $gdb_prompt_delimiter\\n\n");
# We allow *only* that single string, so that all previous data gets consumed.
  $obj->expect($TIMEOUT, $gdb_prompt_delimiter);
}


# Look for the expected prompt, or other specified strings.
sub GDBPrompt
{
# $no_cbs??? TODO
  my(@others)=@_;
  my($obj);

  $obj=ref($others[0]) eq "Expect" ? shift(@others) : $gdb;
  @others=GDBmatches(1) if !@others;
  if (!$obj->expect($TIMEOUT, @others))
  {
    $obj->print_log_file(">>> NO MATCH ... expected $gdb_prompt_delimiter, Continuing, or @others\n");
    $obj->print_log_file("got ", $obj->clear_accum());
    die "No match\n";
  }
}


# Send a command to GDB, and wait for answer.
sub GDBSend
{
  my(@parm)=@_;
  my($stg, @mat);
  my($obj);

  $obj=ref($parm[0]) eq "Expect" ? shift(@parm) : $gdb;
  ($stg, @mat)=@parm;
  if ($stg)
  {
    $obj->print_log_file(">>> SENDING: $stg\n");
    $obj->send($stg . "\n");
    $obj->clear_accum();
  }
  GDBPrompt($obj, @mat);
  $obj->print_log_file(">>> after sending: run=$is_running ",
      "should=$should_be_running\n");
}


###################################****************************
### ### ### ### ### ### ### ### ###   User commands

# Unknown string - just pass to GDB
sub PassThru 
{ 
  my($self)=@_;
  my($cmd);


  $cmd=($self->matchlist())[0];
  $should_be_running=1 if $cmd =~ m#^\s*c(o(nt?)?)?#i;

  $gdb->print_log_file(">>> passing '$cmd' $is_running $should_be_running");
  return if ($should_be_running && $is_running);

  DebuggeeBreak($gdb);
  GDBSync($gdb);
  GDBSend($gdb, $cmd, GDBmatches(0)); 
  print $gdb->before,"\n";
  DebuggeeCont() if ($should_be_running);
  0; 
}


# show help
sub Help
{
  local(*F);
  my($t);

# Sucks on debian, when the dummy perldoc is installed.
# Should we do open(F, "perldoc ... |") and count the lines?
  if (system("perldoc Games::Hack::Live"))
  {
#    map { print $_, " ", $INC{$_},"\n" } keys %INC;
    $t=$INC{"Games/Hack/Live.pm"};
    if ($t && open(F, "< $t"))
    {
      $t=0;
      while (<F>)
      {
        last if m#^=head1 DESCRIPTION#;

        $t += $t || m#^=head1 SYNOPSIS#;
        print if $t>1;
      }
      close(F);
      print "\nHTH.\n";
    }
    else
    {
      print "Sorry, cannot show any help. I can't even find myself.\n";
    }
  }
}


# Clean up search history
sub CleanUp
{
  @findlist=();
  %find_adr=();

  %callbacks=();

  DebuggeeBreak($gdb);
  GDBSend($gdb, "delete", GDBmatches(0)); 
  DebuggeeCont() if ($should_be_running);
}


sub PatchBin
{
  my($self)=@_;
  my($name);
  my($base, $end, $ret);
  local(*F);

  $name=($self->matchlist())[0]; 

  print "Patching $prg into $name\n";

# find virtual start and end address
  $base=0;

  DebuggeeBreak($gdb);
  GDBSend($gdb, "info proc stat", GDBmatches(0));
$data=$gdb->before();
  DebuggeeCont() if ($should_be_running);

  ($base) = ($data =~ /Start of text: (0x\w+)/m);
  ($end) = ($data =~ /End of text: (0x\w+)/m);
  print("Cannot get start address\n"), return unless $base;
  print("Cannot get end address\n"), return unless $end;

  print "  start is $base, end is $end\n";

  $base=oct($base) if $base =~ m#^0#;
  $end=oct($end) if $end =~ m#^0#;

  unlink($name) || die "cannot remove $name: $!"
    if (-e $name);

# A fast copy, plus the small modifications, is likely faster than trying 
# to copy here ...
  print "  copying.\n";
  $ret=system('cp',$prg,$name);
  print("copying failed with $?\n"),return if ($ret);

# apply patches ...
  print "  patching:\n";
  print("cannot open $name for patching: $!\n"),return 
    if (!open(F, "+< $name"));

  for $patch (@patches)
  {
    ($adr, $val)=@$patch;
    if ($adr >= $base && $adr < $end)
    {
      printf "    0x%x (file offset %d): %s\n",
      $adr, $adr-$base, unpack("H*", $val);
      seek(F, $adr-$base, 0) || die "cannot seek on $name: $!\n";
      print F $val;
    }
    else
    {
# TODO: patch shared objects, too
      printf "Warning: cannot patch address 0x%X - not in image.\n",
             $adr;
    }
  }

  chmod 0755, *F;
  close(F);
}


sub ShowMatches
{
  my(@most);

# Find best matches
  @most=sort { $find_adr{$b} <=> $find_adr{$a}; } keys %find_adr;

  print "\nMost wanted:\n  ";
  map { printf "0x%08X(%d)  ", $_,$find_adr{$_}; } splice(@most, 0, 5);
  print "\n";
}


# Find some value in the program
sub Find
{
  my($self)=@_;
  my($parm);
  my($ref, $bin, @most);

  $parm=($self->matchlist())[0]; 

  ($len, $re)=String2Bin($parm);

  DebuggeeBreak($gdb);

# use a reference, so that the callback can give us data.
  $ref=[];
  push @findlist,  [$parm, $len, $re, $ref];

  print "Searching for $re\n";
  $gdb->print_log_file("Searching for ". unpack("H*", $bin)."\n");

  forEachRWMem(\&FindCallBack, $len, $re, $ref);

# Count matches
  map { $find_adr{$_}++; } @$ref;

  ShowMatches();

  DebuggeeCont() if ($should_be_running);
}


# Register a watchpoint for the memory location, and when it's triggered
# kill the write command.
sub KillWrites
{
  my($self)=@_;
  my($adr, $name, $always_ask, @opt);

  $adr=oct(($self->matchlist())[0]);
  $name=($self->matchlist())[2];

  $always_ask=0;
  # "3 .. " as index doesn't work, splice doesn't take a subroutine call..
  @opt=$self->matchlist();
  splice(@opt, 0, 3);
  for (grep(/\w/,@opt))
  {
    if ($_ eq "ask") { $always_ask=1; }
    else {
      print "Unknown option '$_'\n";
      return;
    }
  }

  DebuggeeBreak();
  GDBSend("watch *(int*)$adr", GDBmatches(0));
  $gdb->before =~ m#(watchpoint \d+:)#i || die;
  if (!$1)
  {
    print "Watchpoint could not be set:\n",$gdb->before,"\n";
    return;
  }

  print "Using ", $1," killing writes to $adr.\n";

  $gdb->print_log_file("Registering callback for '$1':");
  $callbacks{$1}= [ \&KillWriteCallBack, 
    $adr, $name, 
    { "ask" => $always_ask, }, ];
  DebuggeeCont() if ($should_be_running);
}


# Register a watchpoint for the memory location, and tell GDB to change the 
# value back.
sub KeepValueAt
{
  my($self)=@_;
  my($adr,$val,$type,$name);
  my($l1, $l2, $l3);

  ($adr, $type, $val, $name)=$self->matchlist();

  
  $type ||= AutoType($val);
  ValType_to_BinCharHexTypedef($val, $type);

  DebuggeeBreak();
  $l1="set *($type*)$adr=$val";
  $l2="watch *($type*)$adr";
  $l3=["commands",
    "silent",
    $l1,
    "c",
    "end"];
  GDBSend($l1, GDBmatches(0));
  GDBSend($l2, GDBmatches(0));
  $gdb->before =~ m#(watchpoint \d+:)#i;
  if (!$1)
  {
    print "Watchpoint could not be set:\n",$gdb->before,"\n";
    return;
  }

  print "Using ", $1," keeping value at $adr ($type) at $val.\n";

  $gdb->print_log_file("Registering actions for $name '$1':");
  GDBSend(join("\n",@$l3), GDBmatches(0));
  $gdb->print_log_file("Keeping $adr at $val -- $name\n");

  push @summary,
       sprintf("# keeping \"%s\" (0x%x) at 0x%x (%d):\n\t%s\n\n",
           $name, $adr, $val, $val, join("\n\t", $l1, $l2, @$l3));

  DebuggeeCont() if ($should_be_running);
}


# Dump each writeable memory area to a distinct file.
sub DumpAll
{
  my($self)=@_;
  my($dir, $desc, $c);

  $desc=($self->matchlist())[0];

  $dir=sprintf("%s/%d-%04d-%s", $dumppath, $prg_pid, $dump, $desc);
  mkdir($dir) || die $!;
  $dump++;
  print "dumping into $dir...\n";

  $c=forEachRWMem(\&SaveMem, $dir);
  print "Dumped $c mappings.\n";
  0;
}


###################################****************************
### ### ### ### ### ### ### ### ###   Break/Continue Debuggee

sub DebuggeeCont
{
  my($obj)=@_;
  return if ($is_running);

  $obj=$gdb unless $obj;

  $obj->print_log_file("continuing: is_running=$is_running\n");
  $obj->print_log_file(">>> continuing\n");
  GDBSend($obj, "c", GDBmatches(0));
}


sub DebuggeeBreak
{
  my($obj)=@_;
  my(@a, $i);

  $obj=$gdb unless $obj;

  $obj->print_log_file("Try to stop: is_running=$is_running\n");
  return if (!$is_running);

  $i=1;
  $obj->print_log_file(">>> callstack($i): ", join("; ", @a), "\n"), $i++
    while (@a = caller($i));

  $obj->print_log_file(">>> Stopping program via signal\n");
  kill "INT", $prg_pid;
  $obj->clear_accum();
  $is_running=0;
  select(undef, undef, undef, 0.01);
#	GDBSend(undef, "Program received signal");
  GDBSync($obj);
  print $obj->clear_accum();
  $obj->print_log_file("Should be stopped: is_running=$is_running\n");
}


###################################****************************
### ### ### ### ### ### ### ### ###   Utility Functions

# Write some memory block to a file.
sub SaveMemtoFile
{
  my($start, $end, $name)=@_;

  $gdb->print_log_file(
      sprintf(">>> dumping 0x%08x to 0x%08x into %s\n",
        $start, $end, $name));
  GDBSend("dump binary memory $name $start $end", GDBmatches(0));
}


# Wrapper function.
sub SaveMem
{
  my($start, $end, $dir)=@_;

  SaveMemtoFile($start, $end, 
      sprintf("%s/0x%8X-0x%8X", $dir, $start, $end));
}


# Returns GDB commands that writes the bytes of $bin at $adr
sub GetGDBWriteCommands
{
  my($adr, $bin)=@_;
  my($tmp, $stg, $len, $ctype);

  $stg="";


  while ( ($len=length($bin)) )
  {
# Search for a type of the same or smaller length
    $len-- while !($ctype=$length_to_type[$len]);

    $tmp=substr($bin, 0, $len);
    substr($bin, 0, $len)="";

# It doesn't matter that the byte order is host-specific ...
# the binaries are too, after all.
    $stg .= sprintf("set *(%s*)0x%x=0x%x",
        $ctype, $adr, 
        unpack($type_convs{$ctype}[0], $tmp));

    $adr += $len;
  }

  return $stg;
}


# Worker function for KillWrites
sub KillWriteCallBack
{
  my($exp, $data_adr, $name, $opt)=@_;
  my($adr, $p1, $p2, $l, $cmd);
  my($killer);

# When we get here, the program has already stopped.
  $is_running=0;

  ($old) = $exp->after() =~ m#Old value = (\d+)#;

  $exp->clear_accum();
  $exp->print_log_file("### Got callback!\n");
  DebuggeeBreak($exp);
# resync
  GDBSync($exp);

  $exp->print_log_file("Got old value as $old\n");
  GDBSend($exp, "set *(int*)$data_adr=$old", GDBmatches(0))
    if ($old);

  GDBSend($exp, "info program", GDBmatches(0)); 
  $quit=1,return 
    if ($exp->before =~ 
        m#program being debugged is not being run.#i);

  $exp->before =~ m#Program stopped at ((0x)?[0-9a-f]+)#i;
  $adr=oct($1);
  $exp->print_log_file("### Program at $adr!\n");
  GDBSync($exp);

# We need the instruction immediately before, as on Intel EIP is already 
# changed.
# Is there some more reliable way to get it? There may be aliasing issues ..
# Are there longer sequences than 16 Bytes?
# As a watchpoint works with memory, there must be a memory operand to this 
# instruction, so there should be *at least* 2 bytes.
# Less wouldn't work with the relative jump anyway - we'd need to put NOPs.
  $p1=0;
  for $aliasing (2 .. 16)
  {
# We start with some offset before, to let the disassembler synchronize.
    $startadr=$adr-$aliasing-32;
    GDBSend($exp, "disassemble $startadr, " . ($adr+1), GDBmatches(0)); 

    my $x = $exp->before;
    $x =~ s/\n=> /\n   /;

# GDB prints the EIP without leading zeroes (info program), but the 
# diassembly has it. Don't know now how it's printed on 64bit. 
# We fetch an array, and the interesting parts should be the last two ...
#  0x00007fe627b742f3 <__mpn_submul_1+227>:     mov    %ebx,%eax
    @found = ($x =~ m/\n\s*(0x\w+)\s+\<\S+\>:\s+(.*)/mg);

    unless (@found) {
#   0x0000000000414b13:  sub    0x18(%rcx,%rdx,1),%eax
      @found = ($x =~ m/\n\s*(0x\w+):\s+(\w.*)/mg);
    }

#    print "??? @found \n";

# Look whether we had the correct address at the end (instruction aliasing 
# might prevent this)
    $p1=oct($found[-4]), $cmd = $found[-3] if (oct($found[-2]) == $adr);

# Length of instruction
    $l=$adr - $p1;
    $exp->print_log_file("### (aliasing $aliasing) $cmd: $p1-$adr=$l\n");
    last if ($p1);
  }

  die "cannot match opcode addresses for " . $exp->before unless $p1;

  $binary=GetNOP($p1, $adr, $cmd);
  die "Patch is longer than instruction!\n"
    if $l < length($binary);

# Look how many bytes we need to write.
  $killer = GetGDBWriteCommands($p1, $binary);

  push @patches, [ $p1, $binary ];

  GDBSend($exp, $killer, GDBmatches(0));

# Remove tabs and similar
  $cmd =~ s/\s+/ /g;

  printf "\nKilled a write to 0x%X (%s): %s\n\tpatched with %s\n",
    $adr, $name, $cmd, unpack("H*", $binary);

  $desc="";
  if ($opt->{"ask"})
  {
    print "Please enter a description of this event:\n";
    $desc=<STDIN>;
    $desc =~ s/^\s+//;
    $desc =~ s/\s+$//;
  }

  push @summary,
       sprintf('# stopped at 0x%x for "%s" (at 0x%x); killing command "%s" ' .
           "via\n\t%s\n\n",
           $adr, 
           $name .  ($desc ? " [" . $desc . "]" : ""),
           $data_adr, $cmd, $killer);

  DebuggeeCont() if ($should_be_running);

  0;
# display prompt again.
#  exp_continue; 
}


# Main worker function for Find
sub FindCallBack
{
  my($start, $end, $blen, $re, $foundref)=@_;
  my($size, $buff, $offset, $l, $pos, $np, $adr);
  my($tmp)="/tmp/xxx.$$." . rand();
  my($count, $tmpc);

  SaveMemtoFile($start, $end, $tmp);

# We read the (arbitrarily large) memory blobs in pieces, and keep
# the last few bytes from the previous round - in case the match would span 
# two such blocks.

# Size of each block
  $size=128 * 1024;
  $buff="";
  $offset=0;
  open(TMP, "< $tmp") || die "read $tmp: $!";
  while (1)
  {
    $l=sysread(TMP, $buff, $size, length($buff));
    $gdb->print_log_file(
        sprintf("searching for %s at 0x%x (%d) + 0x%x (%d)\n", 
          unpack("H*", $bin), 
          $start, $start, $offset, $offset));
    die $! unless defined($l);
    last if !$l;

    $pos=0;
    while ( $buff =~ m#$re#g )
    {
      $np=$-[0];
      $adr=$start+$offset+$np;

# Should we still print addresses?
      $tmpc=($count++) -5;
      printf "  found at 0x%08x (0x%08x + 0x%x): %s\n", 
      $adr, $start, $np+$offset,
      unpack("H*", substr($buff, $np, 8)), 
      if ($tmpc <0);

# Should we print "more here..."?
      printf "  ...\n", $adr 
        if ($tmpc ==0);

      push @$foundref, $adr;
    }

# We advance the offset ...
    $offset+=length($buff);
# and take only as much from the end as necessary for further matches
    $buff=substr($buff, -$blen);
# but that many characters were kept.
    $offset-=length($buff);
  }
  close(TMP);
  unlink $tmp;
}


# For each writeable memory, do ...
sub forEachRWMem
{
  my($func, @parm)=@_;
  local(*MAP);
  my($start, $end, $count);

  DebuggeeBreak();
# read writeable mappings
  open(MAP, "/proc/$prg_pid/maps") || die $!;
  $count=0;
  while (<MAP>)
  {
    ($start,$end) = m#^(\w+)-(\w+) rw.. #;
# virtual address 0 would be invalid anyway
    next unless $start; 

    &$func(oct("0x$start"), oct("0x$end"), @parm);
    $count++;
  }

  DebuggeeCont() if ($should_be_running);

  close MAP;
  return $count;
}


###################################****************************
### ### ### ### ### ### ### ### ###   Conversion Functions


# Returns a default type for this string
sub AutoType
{
  my($val1, $val2)=@_;

  return (length($val2) == 0 && 
      $val1 =~ /^(\d+|0x[0-9a-f])$/i) 
    ? "int" : "float";
}


sub ValType_to_BinCharHexTypedef
{
  my($value, $type)=@_;
  my($stg, $char, @chars, @hex);

  return undef if !$type_convs{$type};

  ($char)=@{$type_convs{$type}};

  $stg=pack($char, $value);
  @chars=unpack("C*", $stg);
  @hex=map { sprintf("\\x%02X", $_); } @chars;

  return 
    ( 
     $stg, [ @chars ], [ @hex ], 
     @{$type_convs{$type}}
    );
}

# Returns a regex describing the data the user wants to find.
# Format see in documentation.
# Returns undef for invalid input; else 
#   ( $number_of_bytes, $regular_expression ).
sub String2Bin
{
  my($stg)=@_;

  if ($stg =~ m/^\s*(["'])(.*?)\1?$/)
  {
    my($srch, $len);

    $srch=$2;
    $len=length($srch);

# escape special characters
    $srch =~ s#(\W)#\\\1#g;

    return ($len, "(?-xism:$srch)" );
  }

 # it might be nice to search for a regular expression ... but then we 
 # wouldn't know how many bytes to advance. simply go for 16 bytes?


  my($type, $val1, $val2) = ($stg =~ 
    m/^
      (?: \( ([a-z ]+ ) \) )?               # optional type, in ( )
      \s*
      (\S+)                                 # number 1
      (?:                                   # optional 2nd number
        (?: \s*\.\.\s* | \s*-\s* | \s+ )    # delimiter
        (\S+)                               # number 2
      )?
    $/xi);

# auto-type
  $type ||= AutoType($val1, $val2);

  my $chars, $hex;
  my $stg1, $range;

  ($stg1, $chars, $hex, $char, $range) = 
    ValType_to_BinCharHexTypedef($val1, $type);

  return undef unless $stg1;

  # Only a single value given?
  if (!$range)
  {
    return (
      length($stg1), 
      join("", "(?-xism:", @$hex, ")" )
        );
  }

  # floating point type.
  # We do a fuzzy match, eg. for floating point values
  # Eg. if only a few digits are shown.
  if (length($val2) == 0)
  {
    my $o=$val1;
    my $m=$val1;

    $val2=$m*(1+$range);
    $val1=$m*(1-$range);

# See documentation on find - take bigger range
    $m=int($o-1.0)+0.5;
    $val1=$m if ($m<$val1);

    $m=int($o+1);
    $val2=$m if ($m>$val2);

    print "Searching for the range [$val1 .. $val2]\n";
  }

  $val1 += 0;
  $val2 += 0;

  ($val1,$val2) = ($val2, $val1) if abs($val2) < abs($val1);

  my $stg1;
  # pack again, because the order could have changed.
  # TODO: use ValType_to_BinCharHexTypedef()
  $stg1=pack($char, $val1);
  $stg2=pack($char, $val2);

  # TODO machine-dependent - the IEEE formats are MSB 
  # (exponent at higher addresses) (?)

  # Change all bytes left of different bytes.

  # convert to bit vector
  vec($stg1, 1, 2);
  print "1=", unpack("H*", $stg1), "  ",
        "2=", unpack("H*", $stg2), "\n";

 
  $xor= $stg1 ^ $stg2;
  $xor =~ m/(\0+)$/;
  $common_bytes=length( $1 );
  # TODO
  die "strings completely different" if $common_bytes==0;

  $to_chop=@$chars - $common_bytes;
  if ($to_chop>0)
  {
# first different byte gets changed to range, rest ignored.
# We have to re-calculate the characters, because we might have done
# +-1% off the original value.
    splice(@$chars, 0, $to_chop);
    @hex=();
    if ($to_chop>1)
    {
      push @hex, sprintf("[\\x%02x-\\x%02x]", 
          unpack("C*", substr($stg1, $to_chop-1, 1)),
          unpack("C*", substr($stg2, $to_chop-1, 1))
          );
      $to_chop--;
    }

    push @hex, map { sprintf("\\x%02X", $_); } @$chars;
  }

# "." is not *any* character, sadly.
# So we use "\C".
  return (
    length($stg1),
    join("", "(?-xism:", ("\\C" x $to_chop), @hex, ")" ) 
      );
}


##### Success!
1;

###################################****************************
### ### ### ### ### ### ### ### ###
### ### ### ### ### ### ### ### ###   Really the end.
### ### ### ### ### ### ### ### ###   Only documentation left.
### ### ### ### ### ### ### ### ###
###################################****************************

__END__

=head1 NAME

Games::Hack::Live - Perl script to ease playing games

=head1 SYNOPSIS

To start the script:

  hack-live {<name of executable>|-p pid}

Commands for the script:

  help
  dumpall [name]
  find <value>
  find
  cleanup
  keepvalueat <address> <value> ["textual name"]
  killwrites <address> ["textual name"] [ask]
  patch <destination name>

All other strings are passed through to GDB.

=head1 DESCRIPTION

This script helps you patch your favourite programs, to keep them from
incrementing error counters or decrementing life values.

It does this by starting your program, and attaching C<gdb> (the GNU 
debugger) to it; with its help it can examine memory, change it, and find 
locations in the program that try to modify it.

In order to use that script, you need a machine-dependent perl library for 
patching the programs; for 32bit x86 machines, it would be 
C<Games::Hack::Patch::i686>.

You can also attach C<gdb> to already running processes, via the C<-p> 
switch; please do not forget to put the double dash C<--> in front of that, 
otherwise the perl interpreter will take that option for itself.

=head1 SOME DETAILS

=head2 Controlling the run-state - C<CTRL-C> and C<SIGINT>, "C<cont>"

To control whether the debuggee should run or not you can simply press 
CTRL-C; the resulting signal gets caught by the script, and it will try to 
stop the debuggee, so that its state can be examined.

Use any abbreviation of C<cont> (like eg. C<c>) to continue its execution.

=head2 C<help>

This just shows the documentation of the C<Games::Hack::Live> module, which 
you're just reading now.

If C<perldoc> is not available, it tries to show the synopsis by using 
C<%INC>; if that doesn't work, too, the user is out of luck.

=head2 C<dumpall>

  dumpall [name]

This command writes all writeable mappings of the program into files like 
F</tmp/$PID-$DUMP_NUMBER-$NAME/$start-$end>.

These could be used to compare the data at different times.

=head2 C<find>

  find <value>
  find (<format>)<value>
  find (<format>)<value> .. <value>
  find (<format>)<value> - <value>
  find

The most important step is to find the memory location where the debuggee 
stores the precious values. If you know that you have 982 money points 
left, you can simply say

  find 982

and you'll see a list of some memory locations where this value was found. 
If you buy something and see the number 922, use

  find 922

to see an updated list; especially the I<most wanted> list, where the number of 
matches is counted. If you typed C<find> 7 times, and one memory location 
was found every time, it's very likely that this is the address you want.

Normally 2 or 3 searches suffice to determine a location.

C<find> without an argument just prints the last output list again.

The default search only looks for an integer value; you can change that by 
the format specification:

=over

=item Integer types, with an optional C<signed> or C<unsigned> prefix.

These are 

=over

=item char

A character; should be 8 bits long.

=item short

Always 16bit.

=item long

Always 32bit.

=item long long

Always 64bit.

=item int

The C<C> type C<int>, which can (machine-dependent) be anything from 16 to 
64 bits.

=back

Please note that (because of the perl conventions) an C<int> can here be 
B<bigger> than a C<long> - which violates C standard!
--- should possibly be changed?

Only for C<char> the default is C<unsigned>; all other integer types 
default to <signed>.

=item Floating point types - C<float> and C<double>

These are native representations, which on most machine will be conforming 
to the IEEE-standard anyway.

As most floating point values cannot be represented exactly, and they 
surely won't be displayed with full precision, some range has to be 
allowed; for the C<..> and C<-> specifications you can give start and end value 
like

  find 200 - 200.9999
  find 200 .. 200.9999

If you don't do that, a range of values is assumed:

=over

=item +-1% of the given value, or 

=item the range of C<[ int(X-1)+0.5, int(X+1) ]>

=back

The second case tries to account for the fact that a
visible value of 94 might be anything from 93.5 to 94.9.


Note that if you 
want to use the auto-range feature, you'll need to either prepend the 
correct type, or use an explicit decimal point:

  find 55.0
  find (float)54


=item String type

This consists of single or double quotes, and the string therein:

  find "Player 1"

This B<should> be used sometime to get relative positioning of the patch 
addresses; currently it's nearly useless.

=back

If you give a single value, C<int> is taken as default type; for two 
values, C<float>. 

=head2 C<cleanup>

  cleanup

If you found an interesting memory location (and used it with the commands 
L</keepvalueat> or L</killwrites>, or wrote it down), you might want to 
start a new search.

Use the C<cleanup> command for that; it cleans the search history.

=head2 C<keepvalueat>

  keepvalueat <address> [(type)]<value> ["textual name"]

If you found out where your money, life or wizard points are stored, you 
might want to keep that at a value that eases the game a bit. Simply tell 
which memory location should be kept at which value, and an optional name 
(which is used for L</Final output>), and you get a watchpoint registered 
that resets the value after it has been changed.

  keepvalueat 0xafad1208 20000 "Money"
  keepvalueat 0xafad120c (float)120 "Energy"
  keepvalueat 0xafad1218 10.0 "Power"

Please note that this might cause a (very slight) runtime overhead, in that 
B<every write> to this location causes a break into C<gdb>, which 
overwrites the value again, and has to return to the debuggee.

Depending on the frequency of changes you might be able to notice that.

=head2 C<killwrites>

  killwrites <address> ["textual name"] [ask]

This command has a purpose similar to L</keepvalueat>, but achieves that by 
patching the program.

It registers a watchpoint, too; but on a write to the given address the 
script takes momentarily control, deassembles a bit of the program, and 
patches the assembler code so that the modified value doesn't reach its 
memory location.

  killwrites 0xafad1208 "Money"

If you specify the optional flag C<ask>, you get asked for a description on 
every such event; this is handy if you want to differentiate between 
I<good> and I<bad> events later.

=head2 Discussion about C<keepvalueat> and C<killwrites>

=over

=item *

L</killwrites> has to be done only for a single run; the patch commands 
might then simply be loaded without runtime-overhead. 

If a modified binary was written (see L</patch>), this can simply be 
started; not even gdb has to be invoked.

=item *

L</keepvalueat> gives a better starting point - instead of having to do some 
steps to get enough money you simply B<have> the money needed.

=back

Possibly both could be done - patching writes out of the binary, and change 
the initial value that gets loaded. Volunteers?

=head2 C<patch>

  patch <destination name>

With this command the program gets copied to the new name; the 
currently known locations are patched, as found by L<killwrites>.

  patch patched-prg

=head2 Final output

Currently after the script was ended with C<EOF> (C<CTRL-D> on the command 
line) it outputs the patching commands used.


=head1 SEE ALSO

The C<gdb> documentation for other useful commands, and I<Star Trek - 
TODO> about ethical considerations (Kirk patches a simulation, and so is 
the only one that ever made it).


=head1 BUGS/CAVEATS/TODO/IDEAS/WISHLIST

=over

=item Operating system - Linux only

I found no way to determine in C<gdb> which memory regions are mapped 
read-write (C<info proc mappings> doesn't show the mode), so I had to 
read F</proc/*/maps> directly - which limits this script to B<Linux only>
currently.

=item Stability

This is my first project using L<Expect>, which was recommended to me by 
Gabor Szabo (CPAN id SZABGAB) during the YAPC::Vienna 2007 -- instead of 
writing my own loop.

So there might be bugs; the script might break the connection, but the 
debuggee will run along.

You're welcome to help.

=item Search intelligence

For some things it might be good (or even necessary) to avoid giving
distinct values to look for - eg. because they're simply not known.
If you have just some kind of barchart showing energy left, you might 
know when it changes, but no value. 
(Similar if the display differs from the internal representation).

So storing/comparing memory dumps might prove helpful for such cases.
First attempts done in L</dumpall> - we'd have to ask for two (or more) 
dumps with the interesting value unchanged, and a few with it changed - 
to compare the dumps and find the location.
(Which is the fastest way - simple use the dumps as bitvectors, XOR them, 
and look for 0/!0 values?)

=item Hardware (in)dependence

Hardware breakpoints (for the L</keepvalueat> and L</killwrites> 
commands) are available on the higher x86 (Pentium and above, I believe) - 
don't know about other platforms.

The number of available hardware breakpoints is not checked.

More patch libraries are needed.

=item Binary matching

The commands given by L</killwrites> are meaningful only for a single 
executable; if it gets only recompiled, they might be off.

So this should maybe get bound to a MD5 of the binary or some such.

=item Binary patching, program start

Simply patching the program is already possibly; another way would be to
print a shell script, that took care of patching the 
binary (via C<gdb>) itself - so this script would 
have to be started instead of the original executable.
(Should check for the same executable - MD5/SHA-256 or whatever.)

A further idea might be to export a shell script that uses 
C<echo>/C<dd>/C<perl> or suchlike to patch the binary in the filesystem.
This would avoid permission problems (users normally can't write to the 
binaries) and easily allows to transmit the I<changes> via email.

=item Updates

The region around the patched location could be stored as a disassembly 
dump, to possibly find the same program code again after an update.

=item More difficult - finding locations by output

As in the good old times (C64 and similar) sometimes the easiest way is to 
look for the output code - eg. search for C<Lifes: %4d  Energy: %3d> in the 
program data, do a cross-reference where it's used, and resolve back to 
the memory locations used for the output (eg. via C<printf>).

Would need some kind of intelligent disassembler - to (reversely) follow the 
data-stream; but should be doable, at least for easier things (like 
C<printf> output - simply look for argument I<N> on the stack, where it 
comes from).

Should be C<Games::Hack::Offline>, or some such.

=item Interface

Some kind of graphical interface would be nice (eg. Tk) - on another screen, X 
server, or some serial console?

=item Other points

As linux is getting address space randomizations, the data addresses reported 
might not be worth anything in the long run; if the executable sections get 
moved, too, not even the patch commands given by L</killwrites> will help.

There should be some way to describe the relative positioning of the memory 
segments - easy for C<heap>, C<stack> or executable segments, but other 
anonymous ranges?

=back

Patches are welcome.


=head1 AUTHOR

Ph. Marek <pmarek@cpan.org>


=head1 HOMEPAGE

The homepage is at http://games-hack.berlios.de/.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ph. Marek;
licensed under the GPLv3.

=cut

