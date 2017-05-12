package Language::Zcode::Translator::PIR;

use strict;
use warnings;

=head1 Language::Zcode::Translator::PIR

Translate Z-code into PIR, aka IMCC, aka PIL, aka a language that Parrot
preprocesses to Parrot assembly before compiling to Parrot bytecode.

=cut

@Language::Zcode::Translator::PIR::ISA = qw(Language::Zcode::Translator::Generic);
my $indent = ""; # indent subs for readability

sub new {
    my ($class, @arg) = @_;
    bless {}, $class;
}

sub program_start {
    my $addr = $Language::Zcode::Util::Constants{first_instruction_address} - 1;
    my $first_sub = "_rtn$addr";
    my $g = $Language::Zcode::Util::Constants{global_variable_address};
    my $top = <<"ENDTOP";

.include "main.pir"

.sub _main2
	# this will at some point do the stuff we repeat for restart/restore
	$first_sub()
.end

#.macro z_get_global (RESULT, GLOBAL_NUM)
#	.loadw_indexed(.RESULT, $g, .GLOBAL_NUM)
#.endm
#
#.macro z_set_global (VALUE, GLOBAL_NUM)
#	.storew_indexed(.VALUE, $g, .GLOBAL_NUM)
#.endm

#############################################
ENDTOP
    my $cstr = ".sub _set_machine_info\n";
    $cstr .= "\t\$P0 = new .PerlInt\n\t\$P1 = new PerlString\n";
    for (sort keys %Language::Zcode::Util::Constants) {
	my $val = $Language::Zcode::Util::Constants{$_};
	my $n = $val =~ /^\d+$/ ? 0 : 1;
	$cstr .= "\t\$P$n = $Language::Zcode::Util::Constants{$_}\n";
	$cstr .= "\tglobal \"$_\" = \$P$n\n"
    }
    $cstr .= ".end\n";
    return "$top\n$cstr\n";
}

sub routine_start {
    my ($self, $addr, @params) = @_;
    my $name = "_rtn$addr";
    my $out_str = ".sub $name\n";
    $indent = "\t";
    # Create local variables with the same names as Inform variables
    # call_v?2 passes in at most 7 args
    for (0 .. ($#params > 6 ? 6 : $#params)) {
	$out_str .= "${indent}.param int local$_\n";
    }
    for (7 .. $#params) {
	$out_str .= "${indent}.local int local$_\n";
    }
    for (qw(result)) {
	$out_str .= "${indent}.local int $_\n";
    }
    $out_str .= "${indent}.local pmc memory\n\tmemory = global \"_Z_Memory\"\n";
    # Declare this sub's local variables
    # XXX get last arg = num_args
    # while i < num_args && i < num_locals
    # get argi
    return $out_str
}

sub routine_end {
    $indent = "";
    return ".end\n\n";
}


##############################################3
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

# XXX Perl translations - ignore these!
my %Perl_trans = ( 
    # Arithmetic ops
    div => "int(_SW#Z_A# / _SW#Z_B#)",
    # Perl: # (13 % -5) == -2; Zcode: 13 % -5 = (13 - (-5 * -2)) = 3
    # How many times does $y fit into $x; always round towards zero!
    # Use commas so we can later set $result = (..., ... , a%b)
    mod=>'($t1 = _SW#Z_A#, $t2 = _SW#Z_B#, $t1 - $t2*int($t1/$t2))',

    # logical ops - make sure we get the right number of bits
    'not' => "0xffff & ~Z_VALUE",
    log_shift => '($t1 = _SW#Z_PLACES#) > 0 ' .
        '? Z_NUMBER << $t1 : (Z_NUMBER & 0xffff) >> -$t1',
    # The |(...) fills in 1s from the left if bit fifteen (sign bit) is set
    art_shift => 'do { $t2 = Z_NUMBER; 
        ($t1 = _SW#Z_PLACES#) > 0 ? 
	Z_NUMBER << $t1 : 
	($t2 >> -$t1) | ($t2>>15 && ~(2**-$t1))}',

    # Jumps (conditional & unconditional)
    # Branch instructions just write their conditions: they'll be added to later
    # jump if all given flags in the given bitmap are set
    test => '(Z_BITMAP & ($t1 = Z_FLAGS)) == $t1',
    # Zspec 1.1 'je 5' is illegal.
    # I need to do _SW for the case of je -1 65535
    # XXX If I move this to sub_trans, then I can use grep for > 2 args,
    #    and just test == for 2 args.
    je => '$t1 = Z_A, grep {_SW#$t1# == _SW#$_#} (_ARG_LIST)',

    # Stack and Variables
    # Note: this is where Z_VARIABLE lives - indirect variables. Beware!
    # Spec15.html#inc: "This is signed, so -1 increments to 0."
    # Spec15.html#dec: "This is signed, so 0 decrements to -1."
    inc_chk => "_SW#++Z_VARIABLE# > _SW#Z_VALUE#",
    dec_chk => "_SW#--Z_VARIABLE# < _SW#Z_VALUE#",

    # Return
    ret_popped => "return (pop \@stack)",

    # Print_*
    # print is equivalent to print_addr with address of the literal string!
    "print" => '# print "Z_PRINT_STRING"
        &write_text(&decode_text(Z_LITERAL_STRING))',
    print_ret => '# print "Z_PRINT_STRING"
        &write_text(&decode_text(Z_LITERAL_STRING));
	&newline();
	return(1)',
    #print_num => "&write_text(_SW#Z_VALUE#)",
    print_addr => "&write_text(&decode_text(Z_BYTE_ADDRESS_OF_STRING))",
    # This is why we need to store entire program in memory
    print_paddr => "&write_text(&decode_text(Z_PACKED_ADDRESS_OF_STRING))",
    # XXX We're doing ASCII. Need to do ZSCII
    #print_char => "&write_zchar(Z_OUTPUT_CHARACTER_CODE)",
    #new_line => "&newline()",

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
    #quit => 'die "Quit\n"',
    # Spec 15, 'piracy': "Interpreters are asked to be gullible"
    piracy => "1",
    random => "&z_random(_SW#Z_RANGE#)",
    verify => "&z_verify()",

    # Calls: Z subs are turned into Perl subs
    # Use Perl's calling stack instead of building a separate one BUT do some
    # bookkeeping (w/ extra args) to be able to save/restore machine state
    #call_1s => 'z_call(Z_ROUTINE, \@locv, \@stack, Z_NEXT_PC, Z_RESULT_NUM, _ARG_LIST)',

);

my %replace_trans = ( 
    # Arithmetic ops
    add => "_SW#Z_A# + _SW#Z_B#",
    'sub' => "_SW#Z_A# - _SW#Z_B#",
    mul => "_SW#Z_A# * _SW#Z_B#",
    div => "_SW#Z_A# / _SW#Z_B#",
    # Perl: # (13 % -5) == -2; Zcode: 13 % -5 = (13 - (-5 * -2)) = 3
    # How many times does $y fit into $x; always round towards zero!
    # Use commas so we can later set $result = (..., ... , a%b)
#    mod=>'($t1 = _SW#Z_A#, $t2 = _SW#Z_B#, $t1 - $t2*int($t1/$t2))',

    # logical ops - make sure we get the right number of bits
    'or' => "Z_A | Z_B",
    'and'=> "Z_A & Z_B",

    # Jumps (conditional & unconditional)
    jump => "goto LZ_LABEL",
    # Branch instructions just write their conditions: gotos will be added later
    jz => "Z_A == 0",
    jg => "_SW#Z_A# > _SW#Z_B#",
    jl => "_SW#Z_A# < _SW#Z_B#",

    # Stack and Variables
    # Note: this is where Z_VARIABLE lives - indirect variables. Beware!
    # TODO not really tested!
    # TODO die on stack underflow
    'pop' => 'restore $I0', # (and do nothing with $I0)
    'push' => 'save Z_VALUE',
    pull => 'restore Z_VARIABLE',
    store => "Z_VARIABLE = Z_VALUE",
    load => "Z_VARIABLE",
    inc => "inc Z_VARIABLE",
    dec => "dec Z_VARIABLE",

    # Memory access
    loadb => ".loadb_indexed(Z_RESULT, Z_ARRAY, Z_BYTE_INDEX)",
    loadw => ".loadw_indexed(Z_RESULT, Z_ARRAY, Z_WORD_INDEX)",
    storeb => ".storeb_indexed(Z_VALUE, Z_ARRAY, Z_BYTE_INDEX)",
    storew => ".storew_indexed(Z_VALUE, Z_ARRAY, Z_WORD_INDEX)",

    # Calls
    # TODO calculated calls
    call_1s => "_rtnZ_ROUTINE(_ARG_LIST)",

    # Return
    ret => [".pcc_begin_return", ".return Z_VALUE", ".pcc_end_return"],
    rtrue => [".pcc_begin_return", ".return 0", ".pcc_end_return"],
    rfalse => [".pcc_begin_return", ".return 1", ".pcc_end_return"],
#    ret_popped => "return (pop \@stack)",

    # Prints
#    print_num => "&write_text(_SW#Z_VALUE#)",
    print_num => "print _SW#Z_VALUE#",
#    print_char => "&write_zchar(Z_OUTPUT_CHARACTER_CODE)",
    print_char => ['$S0 = chr Z_OUTPUT_CHARACTER_CODE', "print \$S0"],
#    new_line => "&newline()",
    new_line => 'print "\n"',
# TODO KLUDGE!
    "print" => 'print "Z_PRINT_STRING"',

    # Misc
    # TODO should really call IO cleanup, etc.
    quit => "end",
);

# All call subs work the same! (store var will be set to undef for call_*n,
# and "result = " will be added to call_s).
@replace_trans{qw(call_2s call_vs call_vs2 call_1n call_2n call_vn call_vn2)} =
    ($replace_trans{call_1s}) x 7;

# Translate Z opcode and ops into Perl
my %unimplemented; # keep track of unimplemented opcodes
my $lcount = 0;
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
    my $vcount = 100;

    my %sub_trans = (
	# There's nothing to see here. Move along...
    );

    # XXX Only print labels we actually jump to? Requires separate pass.
    my $label = "L$parsed{opcode_address}:\t";
    # Quetzal stores the byte BEFORE the next command as its restore_pc,
    # so we'll eventually call a sub and try to goto that address.
#    $label .= "1; L$parsed{restore_pc}: " if exists $parsed{restore_pc};

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
    my ($pre_command, $post_command) = ("", "");
    if (exists $replace_trans{$opcode}) {
	$_ = $replace_trans{$opcode};
	# opcodes like @add need "result = ", but I've already added
	# the lvalue for more complicated commands
	s/^/Z_RESULT = / if exists $parsed{result} && !/Z_RESULT/;
	# TODO spacing is screwed up for first line, .commands, etc.
	if (ref $_ eq "ARRAY") {
	    #$_ = join "\n", map {/^\./ ? "$_" : "\t$_"} @$_;
	    $_ = join "\n\t", @$_;
	}

	# Replace Z_* with variables/constants FIRST
	
	# TODO undef is bad!
	s/Z_(\w+)/exists $parsed{lc $1} ? $parsed{lc $1} : "undef"/ge;
	# Put in actual arguments
	# (Note that sometimes there's a letter before the Z,
	# but never after the whole key.)
	# If there are optional args, then some of the args won't exist.
	# First handle things where we set an lval to an rval
	#s/Z_(\w+)\s+=\s+(.+)/$self->var_to_lval($parsed{lc $1}, $2)/e;

	# g17 = local1 + local2 -> 
	#     $Ix = local1 + local2
	#     .set_global($Ix, 17)
	# TODO what if it's an lval in a macro? Use "LVAL_" prefix?
	#     E.g, .loadb_indexed(g00, 0, 0);
	while (/\b(g([\da-f]{2})|sp)\b(\s+=\s+)?/) {
	    my $name = $1;
	    my $temp_var = "\$I$vcount"; $vcount++;
	    my $set;
	    # TODO use ".const global_variable_address" & use that here?
	    my $g = $Language::Zcode::Util::Constants{global_variable_address};
	    if ($3) { # lval
		if ($2) { # global = $I17
		    $set = ".storew_indexed($temp_var, $g, " .  hex($2) .  ")";
		} else { # sp = $I17
		    $set = "save $temp_var";
		}
		$post_command .= "\n\t$set";
		s/$name/$temp_var/; # there can be only one lval; no s///g nec.
	    } elsif ($2) { # rval: $I17 = global
		# replace all g17's in call_vs 12a5 g17 g17 g17 
		# with the same variable
		$set = ".loadw_indexed($temp_var, $g, " .  hex($2) .  ")";
		$pre_command .= "$set\n\t";
		s/$name/$temp_var/g; 
	    } else { # rval: $I17 = sp
		# Need to replace each sp with a new variable
		$set = "restore $temp_var";
		$pre_command .= "$set\n\t";
		s/$name/$temp_var/; 
	    }
	}
	# Put in actual arguments
	# (Note that sometimes there's a letter before the Z,
	# but never after the whole key.)
	# If there are optional args, then some of the args won't exist.
	# First handle things where we set an lval to an rval
#	s/Z_(\w+)\s+=\s+(.+)/$self->var_to_lval($parsed{lc $1}, $2)/e;
#	s/([+-]{2})Z_(\w+)/$self->var_to_lval($parsed{lc $2}, $1)/e;
	# May need to replace in "g00 + g01", so we replace differently
	# OR may need to replace g00 more than one time in the expression
	# for some reason
#	while (/.z_get_global\((\$I\d+).*?\)/) {
#	    print "hi '$_' $& $1\n";
#	    s//$1/g && print "did";
#	    print "bye $_\n";
#	    $pre_command .= "$&\n\t";
#	}
	s/_ARG_LIST/$arg_list/;
	s/, (undef(, )?)?\)(;|$)/)$3/; # clean up unneeded args

	# Change numbers to signed words. 
	s/_SW#(.*?)#/my $res = $1;
	    if ($res =~ m#^-?\d+$#) {
		$res -= 0x10000 if $res > 0x8000;
	    } else {
		$pre_command .= ".signed_word($res)\n\t"
	    }
	    $res/ge;
	    
	$command = $_;
#	print "$parsed{opcode_address} $command\n";

    } elsif (exists $sub_trans{$opcode}) {
	$command = &{$sub_trans{$opcode}}();

	# Handle commands that have a "-> (result)" argument
	# (result has already been translated from e.g. 3 to 'local2')
	$command = $self->var_to_lval($parsed{result}, $command) 
	    if exists $parsed{result} && $command !~ /result =/;
	
    } else {
	warn "Unimplemented opcode $opcode at $parsed{opcode_address}\n" 
	    unless $unimplemented{$opcode}++;
	$command = "&unimplemented_$opcode";
    }
	
    # Handle branch instructions
    # Do this AFTER store_result, so we get "goto L3 if $c = $a+$b"
    # rather than "$c = goto L3 if $c=$a+$b"
    # (Note: jump doesn't count as a branch instruction!)
    # (This assumes Perl command is pretty simple)
    if (exists $parsed{negate_jump}) {
	my $action;
	if (exists $parsed{jump_return}) {
	    $action = ".return $parsed{jump_return}";
	} else {
	    die "no label for command!" unless exists $parsed{label};
	    $action = "goto L$parsed{label}";
	}
	my $cond .= $parsed{negate_jump} ? "unless" : "if";
	if (exists $parsed{result}) { # needs to be two lines
	    $command .= "\n${indent}$cond $parsed{result} $action";
	} else {
	    $command = "$cond $command $action";
	}
    }

    $command = join("",
        $indent, $label, $pre_command, $command, $post_command, "\n");

#    print "$command";
    return ($command);
}

# TODO this is copied from Perl. Needs to do PIR
my $vcount = 100;
sub make_var {
    my ($self, $var, $is_indirect) = @_;

    return $var; # for now, don't modify

    my $is_bracket = ($var =~ s/\[(.*)\]/$1/);
    # TODO Are is_bracket and is_indirect slightly overlapping?
    # Isn't it impossible to be is_bracket w/out being is_indirect?

    local $_ = $var;
    if (/^g([\da-f]{2})$/) { # Global variable
	my $var_num = hex($1);
	$_ = ".z_get_global(\$I$vcount, $var_num)";
	$vcount++;
    } elsif (/^local([\da-f]+)$/) { # Local variable
	#my $h = hex $1;
	#$_ = "local$h";
	# NOOP: local variables are named just like Inform locals
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
sub var_to_lval {
    my ($self, $lval, $rval) = @_;
    local $_ = $lval; # for convenience in //'s.
    # XXX what's correct protocol for store [sp] sp?
    # Pop stack before reading indirect variable?
    my $is_bracket = /bracket_var\(/;

#    $rval = "($rval) % 0x10000";

    if ($is_bracket) { # add $rval to args to bracket_var
	die "Can't handle indirect vars yet\n";
	$rval =~ s/^[+-]{2}$/"$&"/; # Yuck!
	s/\)$/, $rval)/;
    } elsif (/.z_get_global\((\$I\d+)/) { # ...
	$rval =~ s/^[+-]{2}$/"$&"/; # Yuck!
	my $temp = $1;
	s/^/$temp = $rval\n\t/;
	s/z_get/z_set/; # TODO WRONG!!!
	#s/\)$/, result)/;
	#$_ = "result = $rval\n${indent}$_";
    } elsif (/local[\da-f]/) { # $I0 -> $I0 = rval
	if ($rval eq "++" || $rval eq "--") {
	    die "Can't handle ++ or -- yet\n";
	    my $op = substr($rval, 0, 1);
	    # XXX this wrong. Spec 15#dec/inc say this should be signed!
	    $_ = "($_ = ($_ $op 1) & 0xffff)";
	} else {
	    # $_ = "result = $rval\n\t$lval = result";
	    # local0 = ... should just work
	    s/$/ = $rval/;
	}
    } elsif (/stack/) { # pop @stack -> $stack[@stack] = rval
	die "Can't handle stack yet!\n";
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

# TODO put something in here!
sub signed_word {
    my ($self, $num) = @_;
    return $num;
}

sub write_memory {
    my $l = @Language::Zcode::Util::Memory; # i.e., file/memory length
    my $str = <<"ENDUNPACK";
.sub _read_memory
	\$P0 = new .Array
	\$P0 = $l
	global \"_Z_Memory\" = \$P0
	#         Address    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
ENDUNPACK
    # change each byte to two hex digits
    for (my $c = 0; $c < $l; $c+=16) {
	# Add hex "line number" & \n's.
	my $len = $l - $c;
	$len = 16 if $len > 16;
	$str .= sprintf(
	    "\t_mem_add(0x%06x, \"" . " %02x" x $len . "\")\n",
	    $c, @Language::Zcode::Util::Memory[$c .. $c + $len -1]);
    }
    $str .= ".end\n";
    return $str;

}

sub library {
    return "";
}
1;
