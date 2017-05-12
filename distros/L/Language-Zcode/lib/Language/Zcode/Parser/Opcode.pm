package Language::Zcode::Parser::Opcode;

=head1 NAME

Language::Zcode::Parser::Opcode - parse one opcode

=head1 DESCRIPTION

This package parses one opcode. It uses the syntax described in the
Z-spec's table, 14.1. It parses the opcode and its arguments into
a hash:

=over 4

=item opcode

Name of the opcode

=item opcode_address

Byte address of the opcode (in hex)

=item args

Arguments to a subroutine call

=item negate_jump

Negates the condition of a branch instruction

=item jump_return

Return true/false if branch condition is met, instead of jumping

=back

Other keys are (almost) identical to the arg names in the spec.
For example, "je a b ?(label)" yields keys a, b, and label.
For example2, word-index is changed to word_index to make my life easier.

=cut

# Program Counter
our $PC;

sub parse_sub_header {
    $PC = shift;
    my $nl = eat_byte();
    die "Bad number of locals $nl" if $nl > 15;
    # skip local variable values
    my @locals = (0) x $nl;
    if ($Language::Zcode::Util::Constants{version} <= 4) { 
	@locals = map { &eat_word } 1..$nl 
    }
    return @locals;
}

{ # Extra scoping brace: doing all this just once instead of each time
  # (out of thousands) that we call this sub speeds up by several times!

    ##############3###### Many, many constants here...
    use constant OP_UNKNOWN => -1;
    use constant OP_0OP => 0;
    use constant OP_1OP => 1;
    use constant OP_2OP => 2;
    use constant OP_VAR => 3;
    use constant OP_EXT => 4;

    # two bits to store operand type: large or small constant, var, or none
    use constant OP_TYPE_LARGE => 0;
    use constant OP_TYPE_SMALL => 1;
    use constant OP_TYPE_VAR => 2;
    use constant OP_TYPE_DONE => 3; # Also, all remaining ops must also be '11'

    my @TYPE_LABELS;
    $TYPE_LABELS[OP_0OP] = "0OP";
    $TYPE_LABELS[OP_1OP] = "1OP";
    $TYPE_LABELS[OP_2OP] = "2OP";
    $TYPE_LABELS[OP_VAR] = "VAR";
    $TYPE_LABELS[OP_EXT] = "EXT";

    # OPCODE TABLES AND INFORM ASSEMBLY SYNTAX TAKEN FROM Z-SPEC
    # (Minor changes to text, like changing - to _)
    # Note: if an opcode is only in certain versions, we have a hash.
    # Keys are 3 for version 3, 3- for versions 3 and over, 
    # 1-4 for versions 1 through 4, and 5:7:8 for versions 5,7,8
    # (Last one necessary cuz 6 has fancy opcodes that 7 and 8 don't have.)
    # Zero-operand opcodes 0OP
    my @zero_ops = (
	'rtrue', 				# 0
	'rfalse', 				# 1
	# As far as I can tell, print & print_ret are always b2/b3 (0OP)
	# so we don't need to read their strings.
	'print      (literal_string)',		# 2
	'print_ret 	(literal_string)',	# 3
	'nop',					# 4
	# Version 1, version 4
	{ "1-3" => 'save ?(label)',		# 5
	  "4"   => 'save -> (result)'
	}, # illegal in v5+
	{ "1-3" => 'restore ?(label)',		# 6
	   "4"  => 'restore  -> (result)'
	}, # illegal in v5+
	'restart',				# 7
	'ret_popped',				# 8
	{ "1-4" => 'pop',
	  "5-"  => 'catch -> (result)',		# 9
	},
	'quit',					# a
	'new_line',				# b
	{ "3" => 'show_status'},		# c (v3 only)
	{ "3-" => 'verify ?(label)'},		# d
	{ "5-" => 'extended'},			# e [byte 1 of extended opcode]
	{ "5-" => 'piracy ?(label)'},		# f
    );

    # One-operand opcodes 1OP
    my @one_ops = (
	'jz              a ?(label)',			# 0x00
	'get_sibling     object -> (result) ?(label)',	# 0x01
	'get_child       object -> (result) ?(label)',	# 0x02
	'get_parent      object -> (result)',		# 0x03
	'get_prop_len    property_address -> (result)',	# 0x04
	'inc             (variable)',			# 0x05
	'dec             (variable)',			# 0x06
	'print_addr      byte_address_of_string',	# 0x07
	{ "4-" => 'call_1s     routine -> (result)'},	# 0x08
	'remove_obj      object',			# 0x09
	'print_obj       object',			# 0x0a
	'ret             value',			# 0x0b
	'jump            ?(label)',			# 0x0c
	'print_paddr     packed_address_of_string',	# 0x0d
	'load            (variable) -> (result)',	# 0x0e
	{ "1-4" => 'not value       -> (result)',	# 0x0f
	  "5-"  => 'call_1n         routine',	
	},
    );

    # Two-operand opcodes 2OP
    my @two_ops = (
	'',						# 0x00
	# XXX Spec says "je a b ?(label)" but je may take up to four (?) test values
	# (The thing tested and up to 3 to test against)
	'je              a (1-3args) ?(label)',		# 0x01
	'jl              a b ?(label)',			# 0x02
	'jg              a b ?(label)',			# 0x03
	'dec_chk         (variable) value ?(label)',	# 0x04
	'inc_chk         (variable) value ?(label)',	# 0x05
	'jin             obj1 obj2 ?(label)',		# 0x06
	'test            bitmap flags ?(label)',	# 0x07
	'or              a b -> (result)',		# 0x08
	'and             a b -> (result)',		# 0x09
	'test_attr       object attribute ?(label)',	# 0x0a
	'set_attr        object attribute',		# 0x0b
	'clear_attr      object attribute',		# 0x0c
	'store           (variable) value',		# 0x0d
	'insert_obj      object destination',		# 0x0e
	'loadw           array word_index -> (result)',	# 0x0f
	'loadb           array byte_index -> (result)',	# 0x10
	'get_prop        object property -> (result)',	# 0x11
	'get_prop_addr   object property -> (result)',	# 0x12
	'get_next_prop   object property -> (result)',	# 0x13
	'add             a b -> (result)',		# 0x14
	'sub             a b -> (result)',		# 0x15
	'mul             a b -> (result)',		# 0x16
	'div             a b -> (result)',		# 0x17
	'mod             a b -> (result)',		# 0x18
	{ "4-" => 'call_2s  routine arg1 -> (result)'},	# 0x19
	{ "5-" => 'call_2n  routine arg1'},		# 0x1a
	{ "5:7:8" => 'set_colour foreground background',# 0x1b
	  "6"     => 'set_colour foreground background window',
	},
	{ "5-" => 'throw  value stack_frame'},		# 0x1c
	'',						# 0x1d
	'',						# 0x1e
	'',						# 0x1f
    );

    # Variable-operand opcodes VAR
    my @var_ops = (
	# Versions 1-3 use "call" instead of "call_vs". But aren't they the same?
	#'call            routine (0-3args) -> (result)',
	'call_vs         routine (0-3args) -> (result)',	# 0x00
	'storew          array word_index value',		# 0x01
	'storeb          array byte_index value',		# 0x02
	'put_prop        object property value',		# 0x03
    # (Inform calls them sread/aread, but they're really all read
	{ "1-3" => 'read text parse',
	  "4"   => 'read text parse time routine',
	  "5-"  => 'read text parse time routine -> (result)',	# 0x04
	},
	'print_char      output_character_code',		# 0x05
	'print_num       value',				# 0x06
	'random          range -> (result)',			# 0x07
	'push            value',				# 0x08
	{ "1-5" => 'pull (variable)',				# 0x08
	  "6"   => 'pull stack -> (result)',
	  "7-9" => 'pull (variable)',
	},
	{ "3-"  => 'split_window lines'},			# 0x0a
	{ "3-" => 'set_window      window'},			# 0x0b
	{ "4-" => 'call_vs2        routine (0-7args) -> (result)'},	# 0x0c
	{ "4-" => 'erase_window    window'},			# 0x0d
	# XXX translate_command will get different keys depending on version!
	# I believe this is the only command for which this happens. All other
	# commands you just get extra (possibly optional) args.
	{ "4:5:7:8:9" => 'erase_line      value',		# 0x0e
	  "6"         => 'erase_line      pixels',
	},
	{ "4:5:7:8:9" => 'set_cursor      line column',		# 0x0f
	  "6"         => 'set_cursor      line column window',
	},

	{ "4-" => 'get_cursor      array'},			# 0x10
	{ "4-" => 'set_text_style  style'},			# 0x11
	{ "4-" => 'buffer_mode     flag'},			# 0x12
	{ "3-4"   => 'output_stream number ',			# 0x13
	  "5:7:8" => 'output_stream number table',
	  "6"     => 'output_stream number table width',
	},
	{ "3-" => 'input_stream    number'},				# 0x14
	# Spec says defined in v5, first used in v3?!
	{ "3-" => 'sound_effect    number effect volume routine'},	# 0x15
	{ "4-" => 'read_char       1 time routine -> (result)'},	# 0x16
	{ "4-" => 'scan_table      x table len form -> (result)'},	# 0x17
	{ "5-" => 'not             value -> (result)'},			# 0x18
	{ "5-" => 'call_vn         routine (0-3args)'},			# 0x19
	{ "5-" => 'call_vn2        routine (0-7args)'},			# 0x1a
	{ "5-" => 'tokenise        text parse dictionary flag'},	# 0x1b
	{ "5-" => 'encode_text     zscii_text length from coded_text'},	# 0x1c
	{ "5-" => 'copy_table      first second size'},			# 0x1d
	{ "5-" => 'print_table     zscii_text width height skip'},	# 0x1e
	# Bug in spec?! It doesn't list label
	{ "5-" => 'check_arg_count argument_number ?(label)'},		# 0x1f
    );

    # Extended opcodes EXT
    my @ext_ops = (
	# XXX "table bytes name" are optional. IF we get that many args,
	# fill in those values, else we just get a result & do a normal save
	{ "5-" => 'save            table bytes name -> (result)'}, 	# 0x00
	{ "5-" => 'restore         table bytes name -> (result)'}, 	# 0x01
	{ "5-" => 'log_shift       number places -> (result)'},		# 0x02
	{ "5-" => 'art_shift       number places -> (result)'},		# 0x03
	{ "5-" => 'set_font        font -> (result)'},			# 0x04
	{ "6" => 'draw_picture    picture_number y x'},			# 0x05
	{ "6" => 'picture_data    picture_number array ?(label)'},	# 0x06
	{ "6" => 'erase_picture   picture_number y x'},			# 0x07
	{ "6" => 'set_margins     left right window'},			# 0x08
	{ "5-" => 'save_undo       -> (result)'},			# 0x09
	{ "5-" => 'restore_undo    -> (result)'},			# 0x0a
	{ "5-" => 'print_unicode   char_number'},			# 0x0b
	{ "5-" => 'check_unicode   char_number -> (result)'},		# 0x0c
	'',								# 0x0d
	'',								# 0x0e
	'',								# 0x0f

	{ "6" => 'move_window     window y x'},				# 0x10
	{ "6" => 'window_size     window y x'},				# 0x11
	{ "6" => 'window_style    window flags operation'},		# 0x12
	{ "6" => 'get_wind_prop   window property_number -> (result)'},	# 0x13
	{ "6" => 'scroll_window   window pixels'},			# 0x14
	{ "6" => 'pop_stack       items stack'},			# 0x15
	{ "6" => 'read_mouse      array'},				# 0x16
	{ "6" => 'mouse_window    window'},				# 0x17
	{ "6" => 'push_stack      value stack ?(label)'},		# 0x18
	{ "6" => 'put_wind_prop   window property_number value'},	# 0x19
	{ "6" => 'print_form      formatted_table'},			# 0x1a
	{ "6" => 'make_menu       number table ?(label)'},		# 0x1b
	{ "6" => 'picture_table   table'},				# 0x1c
    );

    my (@generic_opcodes);
    $generic_opcodes[OP_0OP] = \@zero_ops;
    $generic_opcodes[OP_1OP] = \@one_ops;
    $generic_opcodes[OP_2OP] = \@two_ops;
    $generic_opcodes[OP_VAR] = \@var_ops;
    $generic_opcodes[OP_EXT] = \@ext_ops;

sub parse_command {
    # See ZMachine spec chapter 4

##################### OK, finally ready to start the real sub
    my %parsed = ( "opcode_address" => $PC );
    my $z_version = $Language::Zcode::Util::Constants{version};

    my $opcode = &eat_byte();
    my $op_style = OP_UNKNOWN;
    my @operands = ();
    my $is_var_ops = 0;
    if (($opcode & 0x80) == 0) {
	# If top bit is zero: opcode is "long" format, which is always 2OP
	# ME: Handle these first as they seem to be the most common.
	# Next two bits give operand types for the two ops
	# type is small constant (0) or variable number (1)
	@operands = (load_operand($opcode&0x40 ? OP_TYPE_VAR : OP_TYPE_SMALL),
		     load_operand($opcode&0x20 ? OP_TYPE_VAR : OP_TYPE_SMALL));
	$opcode &= 0x1f; # last 5 bits
	$op_style = OP_2OP;

    } elsif ($opcode & 0x40) {
	# top 2 bits are both 1: "variable" format opcode. Opcode in bottom 5
	# bits. This may actually be a 2OP opcode...
	$op_style = $opcode & 0x20 ? OP_VAR : OP_2OP;
	$opcode &= 0x1f;
	$is_var_ops = 1; # load operands later
      
    } elsif ($opcode == 0xbe && $z_version >= 5) {
	# "extended" opcode
	$opcode = &eat_byte();
	$op_style = OP_EXT;
	$is_var_ops = 1; # load operands below
    } else {
      # "short" format opcode: next two bits mean zero or 1 OP
	if (($opcode & 0x30) == 0x30) {
	    $op_style = OP_0OP;
	} else {
	    $op_style = OP_1OP;
	    my $optype = ($opcode & 0x30) >> 4;
	    push @operands, &load_operand($optype);
	}
	$opcode &= 0x0f;
    }

    # Which command is it?
    my $syntax = $generic_opcodes[$op_style]->[$opcode] 
	or warn("Unknown opcode $TYPE_LABELS[$op_style]  $opcode"), return;
    # Deal with version-dependent codes
    if (ref $syntax eq "HASH") {
	my %syn = %$syntax;
	my $v = $z_version; # nickname for conciseness below
	$syntax = "";
	foreach my $range (keys %syn) {
	    if (($range =~ /^(\d+)$/  && $v == $1) ||
	        ($range =~ /^(\d+)-$/ && $v >= $1) ||
	        ($range =~ /^(\d+)-(\d+)$/ && $v >= $1 && $v <= $2) ||
		# One day there might be a version 10, and v1 shouldn't match...
	        ($range =~ /:/ && $range =~ /\b$v\b/)) 
	    { 
		$syntax = $syn{$range}; 
		last;
	    }
	}
	if (!$syntax) {
	    warn("opcode $TYPE_LABELS[$op_style] $opcode illegal for v$v");
	    return;
	}
    }
    my ($command, @keys) = split " ", $syntax;

    # Read leftover ops for VAR opcodes
    my ($operand_types, $i);
    if ($is_var_ops) {
      # a VAR or EXT opcode with variable argument count.
      # Load the arguments.
      if ($op_style == OP_VAR &&
	  ($command =~ /^call_v[sn]2$/)) {
          # 4.4.3.1: there may be two bytes of operand types, allowing
          # for up to 8 arguments.  This byte will always be present,
          # though it does NOT have to be used...
          $i = 14;
          # start shift mask: target "leftmost" 2 bits
          $operand_types = &eat_word();
      } else {
	  # 4.4.3: one byte of operand types, up to 4 args.
	  $i = 6;
	  $operand_types = &eat_byte();
      }
#      printf STDERR "%s: ", $operand_types;
      for (; $i >=0; $i -= 2) {
	  my $optype = ($operand_types >> $i) & 0x03;
#          print STDERR "$optype\n";
	  if (defined (my $op = &load_operand($optype))) {
	      push @operands, $op;
	  } else {
	      last; # done getting args
	  }
      }
#      print STDERR "\n";
    }

    # Read any remaining args if necessary.
    # Also, assign operands to operand names, creating %parsed
    $parsed{opcode} = $command;
#    print "$command @operands\n";
    for my $key (@keys) {
	next if $key eq "->";
	
	# Read branch/result args, which are not counted in the Z-code
	# argument count bits (VAR/1OP etc.).
	if ($key eq "?(label)") {
	    # XXX HACK! jump counts the ?(label) as an arg and
	    # reads it as a SIXTEEN-bit offset
	    # XXX Change jump's arg in @one_ops?
	    my $offset;
	    if ($command eq "jump") {
		$offset = shift @operands;
		# I *think* this doesn't happen
		if ($offset =~ /\D/) { 
		    die "jump opcode takes a variable offset at $PC\n";
		}
		$offset -= (1<<16) if $offset & (1<<15); # SIGNED offset
		# negate_jump doesn't exist
	    } else {
		my $arg = eat_byte();
		$parsed{"negate_jump"} = ($arg & 0x80) == 0;
		$offset = $arg & 0x3f; # offset is 0-63 OR...
		if (!($arg & 0x40)) { # 14-bit signed offset
		    $offset <<= 8;
		    $offset |= eat_byte();
		    $offset -= (1<<14) if $offset & (1<<13); # SIGNED offset
		}
	    }
	    # Offset of 1 or 0 really means return
	    if ($offset == 1 || $offset == 0) {
		$parsed{"jump_return"} = $offset;
		$parsed{"label"} = "";
	    } else {
		# 4.7.2: "Address after branch data + Offset - 2"
		# (-2 seems to apply to jump also, maybe because you read
		# a two-byte word, then apply offset)
		my $destination = $PC + $offset - 2;
#		printf("addr: %s, PC: %x, offset: %s%x, dest: %d\n",
#		    $parsed{opcode_address}, $PC, ($offset<0 && "-"), 
#		    (abs$offset), $destination);
		$parsed{"label"} = $destination;
	    }
	    next;
	} elsif ($key eq "(result)") {
	    # Store the raw number, which we use for call stack's store_var,
	    # as well as the variable name, like local2.
	    $parsed{"result_num"} = eat_byte();
	    $parsed{"result"} = num_to_var($parsed{"result_num"});
	    next;
	} elsif ($key eq "(literal_string)") {
	    # Make this just a print_addr
	    $parsed{literal_string} = $PC;
	    # For debugging purposes, get the string to print
	    my $q = decode_text(); $q =~ s/\n/^/g;
	    $parsed{print_string} = $q;
	}

	# At this point, we've theoretically read all possible args.
	# So if @operands is empty, there's an optional arg that wasn't given
	next unless @operands;

	# Now handle all the other arg types
	if ($key =~ /arg[s1]/) { # call_* has 'args', call_2* has 'arg1'
	    # args are already sitting in operands
	    $parsed{"args"} = \@operands;
	} elsif ($key eq "routine") {
	    $parsed{$key} = shift @operands;
	} elsif ($key eq "(variable)") {
	    # Spec: "passed by reference"
	    $parsed{"variable"} = num_to_var(shift @operands);
	} else {
	    $parsed{$key} = shift @operands;
	}
    }

    # Calls need to store the address of the command AFTER the call,
    # which is where the Z-machine resumes after finishing the call.
    # (For saves, quetzal stores the byte of the store variable in the @save)
    if ($command =~ /^call/) { $parsed{"next_pc"} = $PC }
    elsif ($command eq "save") { $parsed{"restore_pc"} = $PC-1 }

    if (0) { #$write_opcodes) {
	#warn sprintf "addr:%s type:%s opcode:%02x (%s) operands:%s\n",
	    #$TYPE_LABELS[$op_style],
	print((map {"$_=$parsed{$_} "} keys %parsed), "\n");
    }

    return %parsed;
# async interpreter call (v4+), not implemented
#    elsif ($op_style == OP_1OP && $opcode == 0x0b) {
#        my $result = StoryFile::ret($operands[0]); }
}

} # Extra scoping brace around parse_command init stuff

# Read one operand of the given type, or 
# return undef if given an argument of OP_TYPE_DONE
sub load_operand {
    my $op_type = shift;
    # My kingdom for a switch!
    if ($op_type == OP_TYPE_VAR) {
	return num_to_var(eat_byte());
    } elsif ($op_type == OP_TYPE_SMALL) {
        return eat_byte();
    } elsif ($op_type == OP_TYPE_LARGE) {
	return eat_word();
    } elsif ($op_type == OP_TYPE_DONE) {
	return undef;
    } else {
	die "Unknown arg '$op_type' to load_operands" ;
    }
}

# Read a byte and move the Program Counter forward
sub eat_byte { 
    return $Language::Zcode::Util::Memory[$PC++];
}

# Read a word and move the Program Counter forward
sub eat_word { 
    my $word = $Language::Zcode::Util::Memory[$PC++] << 8;
    $word += $Language::Zcode::Util::Memory[$PC++];
    return $word;
}

sub num_to_var {
    my $num = shift;
    if ($num =~ /^(sp|local\d+|g[a-f\d]{2})$/) {
	# e.g., load sp (load, store, etc. pass by reference)
	# Can't dereference until runtime.
	return "[$1]";
    } elsif ($num == 0) {
	return "sp";
    } elsif ($num >=1 && $num <=15) {
	return "local" . ($num-1);
    } elsif ($num >= 16 && $num <= 255) {
	return "g" . sprintf("%02x", $num - 16);
    } else {
	die "Illegal value '$num' passed to num_to_var";
    }
}

# XXX TODO move this (back) to Language::Zcode::Util?
#
# decode and return text at this address; see spec section 3
# These are entries 6-32 in the 3 ZSCII alphabets
# XXX Differences for versions 1,2
sub decode_text {
    my $buffer = "";
    # XXX Versions 5+ may have different alphabet table.
    my @alpha_table = (
	   [ 'a' .. 'z' ],
	   [ 'A' .. 'Z' ],
	   # char 6 means 10-bit ZSCII follows
	   [ undef, split//,qq{\n0123456789.,!?_#'"/\\-:()} ]
    );

    my ($word, $zshift, $zchar);
    my $alphabet = 0;
    my $abbreviation = 0;
    my $two_bit_code = 0;
    my $two_bit_flag = 0;
    # XXX HACK!
    my $flen = @Language::Zcode::Util::Memory;
      
    while (1) {
	last if $PC >= $flen;
	$word = eat_word();
	# spec 3.2
	for ($zshift = 10; $zshift >= 0; $zshift -= 5) {
	    # break word into 3 zcharacters of 5 bytes each
	    $zchar = ($word >> $zshift) & 0x1f;
	    if ($two_bit_flag > 0) {
		# Ten-bit ZSCII character. spec 3.4
		if ($two_bit_flag++ == 1) { # middle of char
		  $two_bit_code = $zchar << 5; # first 5 bits
		} else { # end of char
		  $two_bit_code |= $zchar; # last 5
		  $buffer .= chr($two_bit_code);
		  $two_bit_code = $two_bit_flag = 0;
		}
	    } elsif ($abbreviation) {
		# synonym/abbreviation; spec 3.3
		my $entry = (32 * ($abbreviation - 1)) + $zchar;
		# Spec 3.3, 1.2.2: fetch and convert the "word PC" of the
		# given entry in the abbreviations table.
		# "word address"; only used for abbreviations (packed address
		# rules do not apply here)
		#	my $abbrev_addr = 
		#	    $Language::Zcode::Util::Constants{abbrev_table_address} + 
		#           $entry * 2;
		#my $addr = Language::Zcode::Util::get_word_at($abbrev_addr) * 2;
		#my $expanded = decode_text($addr);
		$buffer .= "[abbrev $entry]";
		#print STDERR "abbrev $abbreviation $expanded\n";
		$abbreviation = 0;
	    } elsif ($zchar < 6) {
		if ($zchar == 0) {
		    $buffer .= " ";
		} elsif ($zchar == 4) {
		    # spec 3.2.3: shift character; alphabet 1
		    $alphabet = 1;
		} elsif ($zchar == 5) {
		    # spec 3.2.3: shift character; alphabet 2
		    $alphabet = 2;
		} elsif ($zchar >= 1 && $zchar <= 3) {
		    # spec 3.3: next zchar is an abbreviation code
		    $abbreviation = $zchar;
		}
	    } else {
		# spec 3.5: convert remaining chars from alpha table
		$zchar -= 6;
		# convert to string index
		if ($alphabet != 2) {
		    $buffer .= $alpha_table[$alphabet]->[$zchar];
		} else {
		  # alphabet 2; some special cases (3.5.3)
		    if ($zchar == 0) {
			$two_bit_flag = 1;
		    } elsif ($zchar == 1) {
		      # Why did rezrov do this? -ADK
		      #$buffer .= chr(Games::Rezrov::ZConst::Z_NEWLINE());
			$buffer .= "\n";
		    } else {
			$buffer .= $alpha_table[$alphabet]->[$zchar];
		    }
		}
		$alphabet = 0; # turn "Shift" off
		# XXX applies to this character for version > 2 (3.2.3)
	      }
	}
	# Last bit set
	last if $word & 0x8000;
    }
    return $buffer;
}

1;

