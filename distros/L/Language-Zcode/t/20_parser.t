# Tests for Language::Zcode::Parser 
# (Hey vim! use Perl syntax highlighting... vim: filetype=Perl 
# __DATA__ has the Inform code that this test will test
# Run this file with arg 'Inform' to create a .inf file from __DATA__.

use strict;
use warnings;
use Test;

# TODO
# test routine addresses vs. @subs
# test jump labels, printing addresses

# TODO 
# v3 save, restore, show_status, call
# v4 save, restore
# v<5 pop
# v5 save/restore table bytes name
# All the opcodes I skipped (v5/6 especially)

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 100, todo => [] } #3,4] }

use Language::Zcode::Parser;
use Language::Zcode;

my $Z_version = 5;

# Inform source code!
my @Inform; while(<DATA>) {last if /# END INFORM/; push @Inform, $_}

if (@ARGV && (shift @ARGV eq "Inform")) { 
    (my $outfile = $0) =~ s/\.t/.inf/;
    open OUT, ">$outfile" or die "Creating Inform file: $!\n";
    print OUT "! Inform file created from $0\n\n";
    print OUT join("", @Inform), "\n";
    close OUT;
    exit;
}

(my $infile = $0) =~ s/\.t/.z$Z_version/;
my $pParser = new Language::Zcode::Parser "Perl";
ok($pParser->isa("Language::Zcode::Parser::Perl"));

$pParser->read_memory($infile);
# (first byte is game version)
ok(&Language::Zcode::Util::get_byte_at(0), $Z_version, 
    "read memory. first byte"); 

# Parse the header
$pParser->parse_header();
ok($Language::Zcode::Util::Constants{version}, 5, "version");
ok($Language::Zcode::Util::Constants{release_number}, 1, "release_number");
ok($Language::Zcode::Util::Constants{serial_code}, '"314159"', "serial_code");

# Find subroutines
my @subs = $pParser->find_subs($infile);
#print "#Found ",scalar @subs,"\n";
my $num_subs = 1 + grep /^\[\s*[a-zA-Z]/, @Inform; # Inform creates an extra sub
ok(@subs, $num_subs, "number of subs");
my $main_sub = shift @subs; # don't test all opcodes in 1st Inform-generated sub
ok($main_sub->address, 
    # Only works because main() has no locals
    $Language::Zcode::Util::Constants{first_instruction_address}-1,
    "Address of main()");

# Parse each subroutine
$_ = <DATA> until /^# BEGIN EXPECTED RESULTS/;
for my $sub (@subs) {
    $sub->parse;
    do {$_ = <DATA>} until /\w/ || eof(DATA); s/\s+$//;
    s/^locals\s+// or warn "Expected sub data to start with 'locals'\n";
    ok($sub->locals, $_, "Number of locals is " . scalar $sub->locals);
    my @commands = $sub->commands;
    while (<DATA>) {
	s/\s+$//; # platform-independent chomp!
	next unless /\w/;
	last if /^end_sub/; # finished sub
	warn "Expected opcode '$_' to start with 'opcode'\n" unless /^opcode/;
	my %data = eval "($_)";
	# Test jump labels? 
	# Test routine addresses in call* commands based on Parser output
	my $cmd = shift @commands or 
	    warn "Missing expected command\n", ok(0), next;
	my %command = %{$cmd} or warn("Command not a hash\n"), ok(0), next;
	my $bad_key = "";
	for my $key (keys %data) {
	    my $d = $data{$key};
	    if ($d eq "EXISTS") { # can't possibly be legitimate Z-arg
		$bad_key = "Key $key not in command", last
		    unless exists $command{$key};
		next;
	    }
	    my $c = $command{$key}; $c = "undef" unless defined $c;
	    if (ref $d eq "ARRAY") {
		$bad_key = "$key => Not an arrayref", last if ref $c ne "ARRAY";
		$c = "@$c"; $d = "@$d";
	    }
	    ($bad_key = "$key => $c"), last if $c ne $d;
	}
	ok($bad_key, "", "bad key/value for command: $_");
    }
}

exit;

__DATA__

! Version-specific constants - Ifdef these to test only certain versions
Iftrue #version_number >= 4;
   Constant V4PLUS = 1;
Endif;
Iftrue #version_number >= 5;
   Constant V5PLUS = 1;
Endif;

Release 1;
Serial "314159";

Global G0;
Global G1;
Array arr -> 512;
Array arr2 -> 512;

! Object stuff
! First objects are qw(Class Object Routine String)
! It appears that the first declared property (propa) is #4
! First declared attr is 0
Attribute attr1;
Attribute attr2;
Attribute attr3;
Attribute attr4;
Property propa 11;
Property propb 12;
Property propc 13;
Property propd 14;
Property prope 15;

Object Obj1 "Test Object #1"
  has   attr1 attr2
  with  propa 1,
	propb 2,
	propd 4 5 6;

Object Obj2 "Test Object #2" Obj1
  has   attr3 attr4
  with  propa 2,
	propd 4;

Object Obj3 "Test Object #3" Obj1
  with  propa 3,
	propd 4;

Object Obj4 "Test Object #4" Obj3
  with  propa 4,
	propd 4;

#Ifdef V4PLUS; ! limit of 4-byte properties
! This object is only valid on standard 1.0 interpreters because of
! the 64 byte property.
Object Obj5 ""
 with  propa 1,
       propb 1 2 3,
       propc 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29,
       prope 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32;
#Endif;

[ Main i j; 
   ! Math
   @add 3 2 -> i;
   @sub 3 2 -> G0;
   @mul 3 2 -> sp;
   @div 12 i -> sp;
   @mod 9 sp -> i;
   @random 3 -> i;
   ! TODO indirect

   ! Binary math
   @or 4 3 -> j;
   @and 4 3 -> j;
   @not 1 -> i;
   @art_shift 4 1 -> i;
   @log_shift 4 65535 -> i;

   ! Prints
   @print_num G0;
   @print_char 'A';
   @new_line;

   ! Input
   @read_char 1 -> i;
   ! Note aread won't work for v4
   @aread arr arr2 -> i;
   @tokenise arr arr2;

   ! Fancy I/O
#Ifdef V4PLUS;
   @buffer_mode 1;
#Endif;
#Ifdef V5PLUS;
   @output_stream 3 arr;
#Ifnot;
   @output_stream 4;
#Endif;
   @input_stream 0; ! no effect

   ! Memory
   @loadw $0c 0 -> G1;
   @loadb G1 1 -> j; ! g00
   @storeb i 1 3; ! change g00

   @store i arr;
   @storew i 0 $11aa; ! 4 13 10: Shift-He
   @storew i 1 $4634; ! 17 17 20: llo
   @print_addr i;
   @store i "This is a long string that Inform will put in high memory.";
   @print_paddr i;

   ! Variables
   @inc i;
   .b0;
   @inc_chk i 5 ?b1;
   @dec [i];
   .b1;
   @dec_chk j (-10) ?~b0;
   @store i 17;
   @load i -> j;

   ! Calls
   @call_1s sub1 -> sp;
   @call_1n sub1;
   @call_2s sub1 sp -> i;
   @call_2n sub1 j;
   @call_vs sub1 j 2 G0 -> i;
   @call_vn sub1;
   @call_vs2 sub1 1 2 3 4 5 6 7 -> i;
   @call_vn2 sub1 1 2 3 4 5 6 7;
   @store j sub1;
   @call_1n j;

   ! Objects
   @print_obj Obj1;
   @insert_obj Obj3 Obj2;
   @jin Obj4 Obj2 ?b2;
   @remove_obj Obj4;
   .b2;
   @get_sibling Obj1 -> i ?b3;
   @get_child Obj1 -> i ?b3;
   @get_parent Obj2 -> i;
   .b3;

   @get_prop Obj1 propa -> i;
   @get_next_prop Obj1 propa -> i;
   @get_prop_addr Obj1 propd -> i;
   @get_prop_len i -> j;
   @put_prop Obj1 propa 17;

   @test_attr Obj1 attr1 ?b4;
   @set_attr Obj1 attr3;
   .b4;
   @clear_attr Obj2 attr3;

   ! GUI
   @split_window 10;
   @set_window 1;
   @erase_window -1;
   @get_cursor arr;
   @set_cursor 3 4;
   @erase_line 5;
   @set_text_style 0;

   ! Game state
   @save_undo -> i;
   @restore_undo -> i;
   @save -> i;
   @restore -> i;
   quit;
];

[ sub1 a b c;
   ! Jumps / branches / returns
   .j0;
   @jl 1 2 ?~j2;
   @push 3;
#Ifdef V5PLUS;
   @piracy ?~j4;
   @check_arg_count 3 ?~j4;
#Endif;
   @ret_popped;
   .j4;
   @jz 1 ?rfalse;
   @je 1 1 ?~rtrue;
   @je 1 2 3 ?j3;
   @jg a 5 ?j1;
   jump j0; ! using @jump seems to break Inform
   .j1;
   @nop;
   @ret c;
   .j2;
   @test 7 3 ?j5;
   @rtrue;
   .j3;

   @verify ?j5;
   @pull b;
   @print "Hello, ";
   @print_ret "world!^";
   .j5;

   @rfalse;
];

# END INFORM

# BEGIN EXPECTED RESULTS
locals 2
opcode => "add", a => 3, b => 2, result => "local0"
opcode => "sub", a => 3, b => 2, result => "g00"
opcode => "mul", a => 3, b => 2, result => "sp"
opcode => "div", a => 12, b => "local0", result => "sp"
opcode => "mod", a => 9, b => "sp", result => "local0"
opcode => "random", range => 3, result => "local0"

opcode => "or", a => 4, b => 3, result => "local1"
opcode => "and", a => 4, b => 3, result => "local1"
opcode => "not", value => 1, result => "local0"
opcode => "art_shift", number => 4, places => 1, result => "local0"
opcode => "log_shift", number => 4, places => 65535, result => "local0"

opcode => "print_num", value => "g00"
opcode => "print_char", output_character_code => 65
opcode => "new_line"

opcode => "read_char", result => "local0"
opcode => "read", text => "EXISTS", parse => "EXISTS", result => "local0"
opcode => "tokenise", text => "EXISTS", parse => "EXISTS"

opcode => "buffer_mode", flag => 1
opcode => "output_stream", number => 3
opcode => "input_stream", number => 0
opcode => "loadw", array => 0x0c, word_index => 0, result => "g01"
opcode => "loadb", array => "g01", byte_index => 1, result => "local1"
opcode => "storeb", array => "local0", byte_index => 1, value => 3

opcode => "store", variable => "local0"
opcode => "storew", array => "local0", word_index => 0, value => 0x11aa
opcode => "storew", array => "local0", word_index => 1, value => 0x4634
opcode => "print_addr", byte_address_of_string => "local0"
opcode => "store", variable => "local0"
opcode => "print_paddr", packed_address_of_string => "local0"

opcode => "inc", variable => "local0"
opcode => "inc_chk", variable => "local0", value => 5, label => "EXISTS"
opcode => "dec", variable => "[local0]"
opcode => "dec_chk", variable => "local1", value => -10 & 0xffff, label => "EXISTS"

opcode => "store", variable => "local0", value => 17
opcode => "load", variable => "local0", result => "local1"

opcode => "call_1s", result => "sp", routine => "EXISTS"
opcode => "call_1n", routine => "EXISTS"
opcode => "call_2s", result => "local0", args => ["sp"], routine => "EXISTS"
opcode => "call_2n", args => ["local1"], routine => "EXISTS"
opcode => "call_vs", result => "local0", args => ["local1", 2, "g00"], routine => "EXISTS"
opcode => "call_vn", routine => "EXISTS"
opcode => "call_vs2", result => "local0", args => [1..7], routine => "EXISTS"
opcode => "call_vn2", args => [1..7], routine => "EXISTS"
opcode => "store", variable => "local1"
opcode => "call_1n", routine => "local1"

opcode => "print_obj", object => 5
opcode => "insert_obj", object => 7, destination => 6
opcode => "jin", obj1 => 8, obj2 => 6, label => "EXISTS"
opcode => "remove_obj", object => 8

opcode => "get_sibling", object => 5, result => "local0", label => "EXISTS"
opcode => "get_child", object => 5, result => "local0", label => "EXISTS"
opcode => "get_parent", object => 6, result => "local0"

opcode => "get_prop", object => 5, property => 4, result => "local0"
opcode => "get_next_prop", object => 5, property => 4, result => "local0"
opcode => "get_prop_addr", object => 5, property => 7, result => "local0"
opcode => "get_prop_len", property_address => "local0", result => "local1"
opcode => "put_prop", object => 5, property => 4, value => 17

opcode => "test_attr", object => 5, attribute => 0, label => "EXISTS"
opcode => "set_attr", object => 5, attribute => 2
opcode => "clear_attr", object => 6, attribute => 2

opcode => "split_window", lines => 10
opcode => "set_window", window => 1
opcode => "erase_window", window => 65535
opcode => "get_cursor", array => "EXISTS"
opcode => "set_cursor", line => 3, column => 4
opcode => "erase_line", value => 5
opcode => "set_text_style", style => 0

opcode => "save_undo", result => "local0"
opcode => "restore_undo", result => "local0"
opcode => "save", result => "local0"
opcode => "restore", result => "local0"
opcode => "quit"
end_sub

locals 3
opcode => "jl", a => 1, b => 2, negate_jump => 1, label => "EXISTS"
opcode => "push", value => 3
opcode => "piracy", negate_jump => 1, label => "EXISTS"
opcode => "check_arg_count", argument_number => 3
opcode => "ret_popped"
opcode => "jz", a => 1, jump_return => 0, negate_jump => "", label => ""
opcode => "je", jump_return => 1, negate_jump => 1, label => "", a => 1, args => [1]
opcode => "je", negate_jump => "", a => 1, args => [2, 3], label => "EXISTS"
opcode => "jg", a => "local0", b => 5, label => "EXISTS"
opcode => "jump", label => "EXISTS"
opcode => "nop"
opcode => "ret", value => "local2"
opcode => "test", bitmap => 7, flags => 3
opcode => "rtrue"

opcode => "verify"
opcode => "pull", variable => "local1"

opcode => "print", print_string => "Hello, "
opcode => "print_ret", print_string => "world!^"
opcode => "rfalse"
end_sub

