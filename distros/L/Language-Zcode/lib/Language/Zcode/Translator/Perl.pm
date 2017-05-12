package Language::Zcode::Translator::Perl;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Translator::Perl - Translate Z-code into Perl code

=cut

@Language::Zcode::Translator::Perl::ISA = qw(Language::Zcode::Translator::Generic);
my $indent = ""; # indent subs for readability

sub new {
    my ($class, @arg) = @_;
    bless {}, $class;
}

# Write the beginning of the program
sub program_start {
    my $self = shift;
    my $top = <<'ENDTOP';
#!perl -w

use strict;
use Getopt::Std;

use Language::Zcode::Runtime::Opcodes; # Perl translation of complex opcodes
use Language::Zcode::Runtime::State; # save/restore game state
use Language::Zcode::Runtime::IO; # All IO stuff

# Set constants
use vars qw(%Constants);
CONSTANTS_HERE

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

ENDTOP
    # Version-dependent constants in Z-file become true constants in output
    # file
    my $cstr = join("",
	"\%Constants = (\n",
	    map({ "    $_ => $Language::Zcode::Util::Constants{$_},\n" }
		sort keys %Language::Zcode::Util::Constants),
	");\n"
    );
    $top =~ s/^CONSTANTS_HERE/$cstr/m;
    return $top;
}

=pod

=head3 routine_start

This sub writes out a string that starts a sub.
Basically, we need to handle setting local variables the sub was
called with, and declaring an empty eval stack.

The much more complicated situation is when we're restoring a game in which
this sub was in the call stack when @save was called.  If sub A called B called
C, which saved, then when we restore the save, we'll start executing sub C,
right after the @save command - and we need to set the local variables and eval
stack in C to the values they had when we saved. When we return from C, z_call
will call B, which needs to start executing at the command right after the call
to C.  But when we start executing B, for example, the local variables and eval
stack need to be set to the values they had when we called C.  (We get that
information from the save file.)

Arg 0 of the created sub will be an arrayref.  It's empty for normal calls.
However, if we restored a game where this sub was in the call stack, then the
sub will be called with information giving the sub's state when it called the
next sub in the stack (or @save): namely, arg0 will then contain the PC where
we should resume execution, and the values to set the eval stack to.

arg1-argn will contain input values for the local variables.  If we're
restoring, those values will be the values from the appropriate frame
of the call stack.

Note: it's legal to pass in too many or too few args.
Set only as many values as were passed in, & don't auto-expand array.
(Important pre-V5, when local var initial values may not be 0)

=cut

sub routine_start {
    my ($self, $addr, @params) = @_;
    my $name = "rtn$addr";
    $indent = " " x 4;
    my $hex_address = sprintf("%x", ($name =~ /\d+/ && $&));
    my $start = "sub $name {\n";
    my $out_str = <<'ENDRTN1'; # single quotes make life a bit easier
my ($t1, $t2, @stack, @locv);
if (my @frame = @{shift @_}) {
    @locv = @{$frame[1]}; @stack = @{$frame[2]}; goto "L$frame[0]";
} else {
    @locv = (PUT_VALS_HERE);
    @locv[0 .. ($#_ > $#locv ? $#locv : $#_)] = @_;
}
ENDRTN1
    $out_str =~ s/PUT_VALS_HERE/join(", ", @params)/e; # default values
    $out_str =~ s/^(?!$)/$indent/gm;
    return "$start$out_str";
}

sub routine_end {
    $indent = "";
    return "}\n\n";
}


##############################################3
#
# Opcode translations...
# Z_* will later be replaced with values of %parsed
# _SW implements conversion to signed word.
# Branching "?(label)" and results "-> (result)" are not put into these
# translations because they're always handled the same way.
#
# SPEC 2.2: The operations of numerical comparison, multiplication,
# addition, subtraction, division, remainder-after-division and printing of
# numbers are signed; bitwise operations are unsigned.
#
# WARNING!!! If the same Z_* is found twice in the same translation,
# and that Z_* is translated to "pop@stack", bad things could happen!
# So use temporary variables.
# XXX Maybe I should fix this somehow, e.g. s/// add's translation to:
# $Z_A = $parsed{a}; $Z_B = $parsed{b}; _SW#\$Z_A# + _SW#$Z_B#;
# Then I can use $Z_FOO in the translation without fear.
# Only problem is things like make_var, especially var_to_lval
my %replace_trans = (
    # Arithmetic ops
    add => "_SW#Z_A# + _SW#Z_B#",
    'sub' => "_SW#Z_A# - _SW#Z_B#",
    mul => "_SW#Z_A# * _SW#Z_B#",
    div => "int(_SW#Z_A# / _SW#Z_B#)",
    # Perl: # (13 % -5) == -2; Zcode: 13 % -5 = (13 - (-5 * -2)) = 3
    # How many times does $y fit into $x; always round towards zero!
    # Use commas so we can later set $result = (..., ... , a%b)
    mod=>'($t1 = _SW#Z_A#, $t2 = _SW#Z_B#, $t1 - $t2*int($t1/$t2))',

    # logical ops - make sure we get the right number of bits
    'or' => "Z_A | Z_B",
    'and'=> "Z_A & Z_B",
    'not' => "0xffff & ~Z_VALUE",
    log_shift => '($t1 = _SW#Z_PLACES#) > 0 ' .
        '? Z_NUMBER << $t1 : (Z_NUMBER & 0xffff) >> -$t1',
    # The |(...) fills in 1s from the left if bit fifteen (sign bit) is set
    art_shift => 'do { $t2 = Z_NUMBER; 
        ($t1 = _SW#Z_PLACES#) > 0 ? 
	Z_NUMBER << $t1 : 
	($t2 >> -$t1) | ($t2>>15 && ~(2**-$t1))}',

    # Jumps (conditional & unconditional)
    jump => "goto LZ_LABEL",
    # Branch instructions just write their conditions: they'll be added to later
    jz => "Z_A == 0",
    jg => "_SW#Z_A# > _SW#Z_B#",
    jl => "_SW#Z_A# < _SW#Z_B#",
    # jump if all given flags in the given bitmap are set
    test => '(Z_BITMAP & ($t1 = Z_FLAGS)) == $t1',
    # Zspec 1.1 'je 5' is illegal.
    # I need to do _SW for the case of je -1 65535
    # XXX If I move this to sub_trans, then I can use grep for > 2 args,
    #    and just test == for 2 args.
    je => '$t1 = Z_A, grep {_SW#$t1# == _SW#$_#} (_ARG_LIST)',

    # Stack and Variables
    # Note: this is where Z_VARIABLE lives - indirect variables. Beware!
    'pop' => 'pop @stack',
    'push' => 'push @stack, Z_VALUE',
    pull => 'Z_VARIABLE = pop @stack',
    store => "Z_VARIABLE = Z_VALUE",
    load => "Z_VARIABLE",
    # Spec15.html#inc: "This is signed, so -1 increments to 0."
    # Spec15.html#dec: "This is signed, so 0 decrements to -1."
    inc => "++Z_VARIABLE",
    dec => "--Z_VARIABLE",
    inc_chk => "_SW#++Z_VARIABLE# > _SW#Z_VALUE#",
    dec_chk => "_SW#--Z_VARIABLE# < _SW#Z_VALUE#",

    # Memory access
    loadb => '$PlotzMemory::Memory[(Z_ARRAY + Z_BYTE_INDEX) & 0xffff]',
    loadw => 
        '256*$PlotzMemory::Memory[$t1=(Z_ARRAY + 2*Z_WORD_INDEX) & 0xffff] +
	$PlotzMemory::Memory[$t1 + 1]',
    storeb => 
        '$PlotzMemory::Memory[(Z_ARRAY + Z_BYTE_INDEX) & 0xffff] = Z_VALUE & 0xff',
    storew => '$PlotzMemory::Memory[$t1 = (Z_ARRAY + 2*Z_WORD_INDEX) & 0xffff] =
        ($t2 = Z_VALUE)>>8 & 0xff,
	$PlotzMemory::Memory[$t1 + 1] = $t2 & 0xff',

    # Return
    ret => "return Z_VALUE",
    ret_popped => "return (pop \@stack)",
    rtrue => "return 1",
    rfalse => "return 0",

    # Print_*
    # print is equivalent to print_addr with address of the literal string!
    "print" => '# print "Z_PRINT_STRING"
        &write_text(&decode_text(Z_LITERAL_STRING))',
    print_ret => '# print "Z_PRINT_STRING"
        &write_text(&decode_text(Z_LITERAL_STRING));
	&newline();
	return(1)',
    print_num => "&write_text(_SW#Z_VALUE#)",
    print_addr => "&write_text(&decode_text(Z_BYTE_ADDRESS_OF_STRING))",
    # This is why we need to store entire program in memory
    print_paddr => "&write_text(&decode_text(Z_PACKED_ADDRESS_OF_STRING))",
    # XXX We're doing ASCII. Need to do ZSCII
    print_char => "&write_zchar(Z_OUTPUT_CHARACTER_CODE)",
    new_line => "&newline()",

    # Other I/O
    "read" => "&z_read(Z_TEXT, Z_PARSE, Z_TIME, Z_ROUTINE)", 
    show_status => "&show_status()",
    tokenise => "&z_tokenise(Z_TEXT, Z_PARSE, Z_DICTIONARY, Z_FLAG)",

    # Streams & windows & cursors
    output_stream => "&output_stream(_SW#Z_NUMBER#)", # arg may be < 0
    input_stream => "&input_stream(Z_NUMBER)",
    split_window => "&split_window(Z_LINES)",
    set_window => "&set_window(Z_WINDOW)",
    erase_window => "&erase_window(_SW#Z_WINDOW#)", # arg may be < 0
    get_cursor => "&get_cursor(Z_ARRAY)",
    set_cursor => "&set_cursor(_SW#Z_LINE#, Z_COLUMN, Z_WINDOW)", # < 0 for v6
    set_text_style => "&set_text_style(Z_STYLE)",

    # Objects
    get_parent => "get_parent(Z_OBJECT)",
    get_child => "get_child(Z_OBJECT)",
    get_sibling => "get_sibling(Z_OBJECT)",
    jin => "Z_OBJ2 == &get_object(&thing_location(Z_OBJ1, 'parent'))",
    print_obj => "&write_text(&decode_text(&thing_location(Z_OBJECT, 'name')))",
    insert_obj => "&insert_obj(Z_OBJECT, Z_DESTINATION)",
    remove_obj => "&remove_obj(Z_OBJECT)",
    
    # Properties
    get_prop => "&get_prop(Z_OBJECT, Z_PROPERTY)",
    put_prop => "&put_prop(Z_OBJECT, Z_PROPERTY, Z_VALUE)",
    get_next_prop => "&get_next_prop(Z_OBJECT, Z_PROPERTY)",
    get_prop_addr => "&get_prop_addr(Z_OBJECT, Z_PROPERTY)",
    get_prop_len => "&get_prop_len(Z_PROPERTY_ADDRESS)",

    # Attributes
    set_attr => "&set_attr(Z_OBJECT, Z_ATTRIBUTE)",
    clear_attr => "&clear_attr(Z_OBJECT, Z_ATTRIBUTE)",
    test_attr => "&test_attr(Z_OBJECT, Z_ATTRIBUTE)",

    # Save/restore
    # XXX Different for v1-3
    save => '&save_state(Z_RESTORE_PC, \@locv, \@stack)',
    restore => "&restore_state",
    # Spec "save_undo": terp must return -1 if it doesn't implement save_undo
    save_undo => "-1",
    # Spec "restore_undo": illegal for a game to use this if save_undo
    # returns -1.
    restore_undo => "0",
    restart => 'die "Restart\n"',
    
    # Misc
    check_arg_count => '@_ >= Z_ARGUMENT_NUMBER',
    quit => 'die "Quit\n"',
    # Spec 15, 'piracy': "Interpreters are asked to be gullible"
    piracy => "1",
    random => "&z_random(_SW#Z_RANGE#)",
    verify => "&z_verify()",
    nop => 1,

    # Calls: Z subs are turned into Perl subs
    # Use Perl's calling stack instead of building a separate one BUT do some
    # bookkeeping (w/ extra args) to be able to save/restore machine state
    call_1s => 
       'z_call(Z_ROUTINE, \@locv, \@stack, Z_NEXT_PC, Z_RESULT_NUM, _ARG_LIST)',

);

# All call subs work the same! (store var will be set to undef for call_*n,
# and "result = " will be added to call_s).
@replace_trans{qw(call_2s call_vs call_vs2 call_1n call_2n call_vn call_vn2)} =
    ($replace_trans{call_1s}) x 7;
#@replace_trans{ qw(call_2n call_vn call_vn2) } = ($replace_trans{call_1n}) x 3;

# Translate Z opcode and ops into Perl
my %unimplemented; # keep track of unimplemented opcodes
sub translate_command {
    # Keys to %parsed are based on the arguments in the opcode syntax list
    # in LZ::Parser::Opcode. There's a few others I put in:
    # - opcode, opcode address are the name & address of the opcode
    # - result is variable name (or stack top) where we're supposed
    #   to store the result, if any
    # - negate_jump means negate the condition of jump opcodes
    # - jump_return means return this value (0 or 1) instead of branching
    #   if the branch condition is met
    # - op is an arrayref to remaining arguments (used for e.g., call_*)
    my ($self, $href) = @_;
    my %parsed = %$href;
    my $opcode = $parsed{opcode} or return; # totally unknown opcode?
    my $command = "OOPS. No Command Here\n"; # command to return

    my %sub_trans = (
	# There's nothing to see here. Move along...
    );

    # Build the actual line of Perl code
    # XXX Only print labels we actually jump to? Requires separate pass.
    my $label = "L$parsed{opcode_address}: ";
    # Quetzal stores the byte BEFORE the next command as its restore_pc,
    # so we'll eventually call a sub and try to goto that address.
    $label .= "1; L$parsed{restore_pc}: " if exists $parsed{restore_pc};

    # Translate, e.g., "local1" to language-specific
    # code representing second local variable
    # Treat key "variable" specially - it's used in "indirect opcodes"
    # (See make_var)
    foreach my $key (keys %parsed) {
	my %skip = map {$_=>1}
	    qw(args jump_return label literal_string negate_jump
	       next_pc opcode opcode_address print_string restore_pc);
	if (!exists $skip{$key}) {
	    #warn "$key $parsed{$key}\n";
	    warn "undefined $key\n" if !defined $parsed{$key};
	    $parsed{$key} = $self->make_var($parsed{$key}, $key eq "variable");
	}
    }
    # Pack addresses
    foreach my $key (qw(packed_address_of_string routine)) {
	if (exists $parsed{$key}) {
	    $parsed{$key} = $self->packed_address_str($parsed{$key}, $key);
	}
    }

    # Turn variable number of args (if any) into a Perl list
    # Btw, call_1n takes no args, so arg_list will be "" for call_1n, too
    my $arg_list = exists $parsed{args}
        ?  join(", ", map {$self->make_var($_)} @{$parsed{"args"}})
	: "";

    # Turn Z ops into Perl ops
    if (exists $replace_trans{$opcode}) {
	local $_ = $replace_trans{$opcode};
	# Put in actual arguments
	# (Note that sometimes there's a letter before the Z,
	# but never after the whole key.)
	# If there are optional args, then some of the args won't exist.
	# First handle things where we set an lval to an rval
	s/Z_(\w+)\s+=\s+(.+)/$self->var_to_lval($parsed{lc $1}, $2)/e;
	s/([+-]{2})Z_(\w+)/$self->var_to_lval($parsed{lc $2}, $1)/e;
	s/Z_(\w+)/exists $parsed{lc $1} ? $parsed{lc $1}:"undef"/ge;
	s/_ARG_LIST/$arg_list/;
	s/, (undef(, )?)?\)(;|$)/)$3/; # clean up unneeded args

	# Change numbers to signed/unsigned words. 
	s/_SW#(.*?)#/$self->signed_word($1)/ge;
	    
#	print "$parsed{opcode_address} $command\n";
	$command = $_;

    } elsif (exists $sub_trans{$opcode}) {
	$command = &{$sub_trans{$opcode}}();

    } else {
	warn "Unimplemented opcode $opcode at $parsed{opcode_address}\n" 
	    unless $unimplemented{$opcode}++;
	$command = "&unimplemented_$opcode";
    }
	
    # Handle commands that have a "-> (result)" argument
    # (result has already been translated from e.g. 3 to 'local2')
    $command = $self->var_to_lval($parsed{result}, $command) 
	if exists $parsed{result};
    
    # Handle branch instructions
    # Do this AFTER store_result, so we get "goto L3 if $c = $a+$b"
    # rather than "$c = goto L3 if $c=$a+$b"
    # (Note: jump doesn't count as a branch instruction!)
    # (This assumes Perl command is pretty simple)
    if (exists $parsed{negate_jump}) {
	my $action;
	if (exists $parsed{jump_return}) {
	    $action = "return $parsed{jump_return}";
	} else {
	    die "no label for command!" unless exists $parsed{label};
	    $action = "goto L$parsed{label}";
	}
	my $cond .= $parsed{negate_jump} ? "unless" : "if";
	$command = "$action $cond $command";
    }

    $command = "$indent$label$command;\n";

    return ($command);
}

# Change the rval created by make_var to an lval (HACKISH!)
# Note that when we get called, make_var has already been called on the lval,
# generating possibly incorrect 
# If $lval is an indirect variable (see make_var), then the variable
# is really an RVAL which returns a variable that should be treated as an LVAL!
# E.g., store [g0f] 17 means "set the variable represented by the number
# stored in global_var(15) to 17" so global_var(15) is still treated as an rval.
# If global_var(15) is 0 ("sp"), then treat sp as an LVAL, i.e., 
# push 17 onto the stack
# XXX Now that indirect var is treated differently, can I merge this
# XXX back into make_var, only called with an extra arg?
# Special case: if $rval is ++ or --, then inc/dec the lval.
sub var_to_lval {
    my ($self, $lval, $rval) = @_;
    local $_ = $lval; # for convenience in //'s.
    # XXX what's correct protocol for store [sp] sp?
    # Pop stack before reading indirect variable?
    my $is_bracket = /bracket_var\(/;

#    $rval = "($rval) % 0x10000";

    if ($is_bracket) { # add $rval to args to bracket_var
	$rval =~ s/^[+-]{2}$/"$&"/; # Yuck!
	s/\)$/, $rval)/;
    } elsif (/global_var/) { # global_var(number) -> global_var(number, rval)
	$rval =~ s/^[+-]{2}$/"$&"/; # Yuck!
	s/\)$/, $rval)/;
    } elsif (/locv/) { # $locv[num] -> $locv[num] = rval
	if ($rval eq "++" || $rval eq "--") {
	    my $op = substr($rval, 0, 1);
	    # XXX this wrong. Spec 15#dec/inc say this should be signed!
	    # XXX So it should really be:
	    #     $_ = "($_ = ($_
	    $_ = "($_ = ($_ $op 1) & 0xffff)";
	} else {
	    $_ .= " = $rval";
	}
    } elsif (/stack/) { # pop @stack -> $stack[@stack] = rval
	# push returns number of elements in array. I need the value I pushed.
	# If indirect variable, this s/// won't happen.
	s/pop\(\@stack\)/\$stack[\@stack]/;
	if ($rval eq "++" || $rval eq "--") {
	    my $op = substr($rval, 0, 1);
	    $_ = "($_ = ($_ $op 1) & 0xffff)";
	} else {
	    $_ .= " = $rval";
	}
    } else {
	warn "Unexpected arg to var_to_lval $lval";
    }

    return $_;
}

# Create a string describing a variable  from the given string. 
# (e.g., '$locv[2]' from 'local2')
# Indirect variables are a special case - stack doesn't get popped.
# Usually, it'll be a string describing the stack ("sp"), or a local
# or global variable. But if it's an expression in [], then
# e.g., [local2] means the value of the variable stored in
# $locv[2]. If $locv[2] is 11, then we really want the value stored in
# $locv[10]!
sub make_var {
    my ($self, $var, $is_indirect) = @_;
    my $is_bracket = ($var =~ s/\[(.*)\]/$1/);

    local $_ = $var;
    if (/^g([\da-f]+)$/) { # Global variable
	my $var_num = hex($1);
	$_ = "&global_var($var_num)";
    } elsif (/^local([\da-f]+)$/) { # Local variable
	$_ = "\$locv[$1]";
    } elsif ($_ eq "sp") { # Stack
	# Spec Version 1.1 (draft7): "an indirect reference to the stack 
	# pointer does not push or pull the top item of the stack - it is read
	# or written in place."
	# ADK: From testing (winfrotz2002) it apears this is true for
	# "load sp". "load [sp]" does pop the stack in getting the number
	# of the variable to use. But if sp == 0, "load [sp]" still pops
	# only once.
	$_ = $is_indirect && !$is_bracket ? '$stack[-1]' : 'pop(@stack)';
    } elsif (/^\d+$/) {
	# Leave the numeric constant as it is
    } else { # not a number? What is it?
	warn "Unexpected arg to make_var: '$var'";
	# keep the garbage in the output file
    }

    # Get the value stored in the variable referenced by the current $_
    # Pass in local variables & stack so we have their values.
    # No, pass in *refs* to local variables & stack, in case the indirect
    # var is an lval which references e.g. a local variable which we 
    # then need to set within indirect_var!
    $_ = "bracket_var($_, \\\@locv, \\\@stack)" 
	if $is_bracket;

    return $_;
}

# Convert num to signed_word & unsigned_word. Stolen from Games::Rezrov.

# Signed word: if high bit is set, take ~ number, else just the number
# IF the expression we're sign'ing is just an integer constant,
# convert it to a signed word constant now. 
# Otherwise, the term is a variable, so we just have to put in Perl code
# that will convert it at runtime
# Note that dzip and zip fail *differently* on test.inf wrt signed numbers!
sub signed_word {
    my ($self, $exp) = @_;
#    $exp =~ s/^\((.*)\)$/$1/ 
#	or die "Unexpected expression '$exp' to signed_word\n";
    my $ret;
    if ($exp =~ /^\d+$/) {
	$ret = $exp & 0x8000 ?  $exp - 0x10000 : $exp;
    } else {
	# XXX Aha! $ret = "($exp-0x8000) % 0x10000 - 0x8000"
	$ret = "unpack('s', pack('s', $exp))";
    }
    return $ret;
}

# XXX might need to also explicity cast to unsigned
# when setting variables - see Games::Rezrov::StoryFile
sub unsigned_word {
    return "unpack('S', pack('s', $_[1]))";
}

sub newlineify {
    my $s = pop;
    $s =~ s/\n/\\n/g;
    return $s;
}

# Write memory to the file, as well as code to read it back
# (and to store original dynamic memory)
sub write_memory {
    my ($self) = @_;
    # Top of package
    my $str = q(

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

);
    
    
    # change each byte to two hex digits
    my $l = @Language::Zcode::Util::Memory;
    my $flen = $Language::Zcode::Util::Constants{file_length}; # stated length
    # Spec1.1: "Padding"
    # The standard currently states that story file padding beyond the length
    # specified in the header must be all zero bytes. Many Infocom story files
    # in fact contain non-zero data in the padding, so interpreters must be
    # sure to exclude the padding from checksum calculations.
    my $hexed = "";
    for (my $c = 0; $c < $l; $c+=16) {
	# Add hex "line number" & \n's.
	my $len = $l - $c;
	$len = 16 if $len > 16;
	$hexed .= sprintf("%06x  " . " %02x" x $len . "\n",  $c,
	    @Language::Zcode::Util::Memory[$c .. $c + $len -1]);
    }
    # Actually, this is $#dynamic, not @dynamic
    my $dynamic_size = $Language::Zcode::Util::Constants{static_memory_address} - 1;
    $str .= <<"ENDUNPACK";
sub read_memory {
# (The map below removes address number and hexifies the other numbers)
    my \$c = 0;
# Addr    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    \@Memory = map {\$c++ % 17 ? hex : ()} qw(
$hexed
);
    \@Dynamic_Orig = \@Memory[0 .. $dynamic_size];
}

sub checksum {
    my \$header_size = 0x40; # don't count header bytes.
    my \$sum = 0;
    for (\@Dynamic_Orig[\$header_size .. $dynamic_size -1], 
        \@Memory[$dynamic_size .. $flen-1]) 
    {
	\$sum += \$_;
    }
    # 512K * 256 = 128M: definitely less than 2G max integer size for Perl.
    # so we don't need to do mod within the for loop
    \$sum = \$sum % 0x10000;
    return \$sum;
}

sub get_dynamic_memory {
    [\@Memory[0 .. $dynamic_size]];
}

sub get_orig_dynamic_memory {
    [\@Dynamic_Orig];
}

my \$restore_mem_ref;
sub store_dynamic_memory {
    \$restore_mem_ref = shift;
}

# Reset memory EXCEPT the couple bits that get saved even during a restart.
sub reset_dynamic_memory {
    my \$restoring = shift;
    Language::Zcode::Runtime::IO::store_restart_bits();
    \@Memory[0 .. $dynamic_size] = 
	\$restoring ? \@\$restore_mem_ref : \@Dynamic_Orig;
}

} # End package PlotzMemory

ENDUNPACK

    return $str;
}

# This functionality is supplied by the "use Language::Zcode::Runtime" at the
# top of the program (written in program_start)
sub library {
    return "";
}

1;
