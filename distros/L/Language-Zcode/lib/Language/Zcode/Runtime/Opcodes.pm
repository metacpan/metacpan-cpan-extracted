package Language::Zcode::Runtime::Opcodes;

use strict;
use warnings;
use vars qw(@EXPORT @ISA $DEBUG);
use Exporter;
@ISA=qw(Exporter);
# Export subs called by external programs
@EXPORT = qw (
    decode_text
    print_addr print_paddr
    z_read z_tokenise
    get_parent get_child get_sibling
    insert_obj remove_obj
    get_prop put_prop get_next_prop get_prop_addr get_prop_len
    set_attr clear_attr test_attr
    z_random
    z_verify

    bracket_var
    global_var

    get_object
    thing_location

    $DEBUG
);

=head1 NAME

Language::Zcode::Runtime::Opcodes

=head1 DESCRIPTION

This module is included by Perl translations of Z files.
It includes functionality that'll be the same for every game,
namely the implementations of the Z opcodes.
Simpler opcode translations are translated into native Perl.
sub names are (usually) opcode names prefixed by "z_"

It also contains other useful subs, like decode_text

=cut

=head2 Z_machine

Build and run the Z-machine

=cut

# XXX This should probably be in Language::Zcode::State
sub Z_machine {
    my %opts = @_;
    $DEBUG = defined $opts{d};
    my ($rows, $columns, $terminal) = @opts{qw(r c t)};

    # read memory (into @PlotzMemory::Memory) and store original dynamic memory
    PlotzMemory::read_memory(); 

    # Create objects for IO. (Most IO setup happens in setup_IO, which gets
    # called again for restart/restore))
    Language::Zcode::Runtime::IO::start_IO($rows, $columns, $terminal);

    ############### 
    # The below loop allows the Z-machine to "reboot" if we hit a
    # restart or restore opcode.
    my ($rebooting, $Z_Result) = (0, 0, "");

    RESTART:
    do { # 'do {BLOCK} while $foo' runs once before checking loop condition

	# Load RAM
	PlotzMemory::reset_dynamic_memory($Z_Result eq "Restore");
	# Change flags and write them back to memory
	Language::Zcode::Runtime::IO::update_header();
	# Reset screen etc.
	Language::Zcode::Runtime::IO::setup_IO();
	
	#####################
	# Until now we've been "building/booting" the Z-machine. Now run it!
	# 'main' sub has one byte (num_locals) before first instruction address
	my $addr = $main::Constants{first_instruction_address} - 1;
	# Empty args will generate the dummy frame in the call stack
	eval {
	    &Language::Zcode::Runtime::State::z_call(
		$addr, [], [], 0, undef);
	    # We should never return from main sub
	    die "Call stack underflow\n";
	};

	#####################
	# Now decide if we're rebooting or exiting
	# exit after running program unless we hit a restart or restore opcode
	$rebooting = 0; 

	# Catch any "die"s, which we use for restart/restore AND for real errors.
	if (($Z_Result = $@) =~ /^Rest(art|ore)$/) {
	    chomp($Z_Result);
	    $rebooting = 1; # Loop!

	} elsif ($Z_Result eq "Quit\n") { # 'quit' opcode
	    $Z_Result = ""; # so we don't die() later

	} 
	# Any other error is a real error; we'll die after cleaning up IO
	# if main sub ends w/out a 'quit', $Z_Result should be empty

    } while $rebooting;

    ############### 
    # Close fancy IO windows etc.
    # (But don't allow die() to overwrite the error message we were storing.)
    eval {Language::Zcode::Runtime::IO::clean_IO()}; $Z_Result .= $@;

    return $Z_Result;

}

# Random number OR seed random number generator 
# return a random number between 1 and specified number.
# With arg 0, seed random number generator, return 0
# With arg < 0, seed with that value, return 0
# XXX TODO - OR give non-random sequence
# XXX TODO - Note that "restart" yields regular randomness again.
sub z_random {
    my $value = shift;
    my $result = 0;
    if ($value == 0) {
        # seed the random number generator
        srand();
    } elsif ($value < 0) {
	# use specified value as a seed
	srand($value);
    } else {
	$result = int(rand($value)) + 1;
    }
    return $result;
}

# verify game image
# This is supposed to be a checksum on the file itself, not the current
# memory state, so use the original dynamic memory.
sub z_verify {
    my $checksum = $main::Constants{file_checksum};
    my $sum = &PlotzMemory::checksum();
    return ($sum == $checksum);
}

# Read and tokenize a command.
sub z_read {
    my ($text_address, $parse_address, $time, $routine) = @_;
    my $version = $main::Constants{version};

    # sect15.html#read
    my $max_text_length = get_byte_at($text_address);
    $max_text_length++ if ($version <= 4);

    # sect15.html#read
    # XXX ADK confirm this is only v5+
    my $initial_buf;
    if ($version >= 5) {
	# there may be some text already displayed as if we had typed it
	my $initial = get_byte_at($text_address + 1);
	$initial_buf = get_string_at($text_address + 2, $initial) if $initial;
    }

    my $s = &Language::Zcode::Runtime::IO::read_command(
	$max_text_length, $time, $routine, $initial_buf);

    # truncate input if necessary
    $s = substr($s, 0, $max_text_length);

    # Put the string into a buffer
    save_buffer($s, $text_address);

    # Tokenize the string
    if ($version < 5 || $parse_address) {
	# Tell tokenise to use standard dictionary & don't set special flag.
	z_tokenise($text_address, $parse_address, 0, 0, length $s);
    }
    # XXX else { print STDERR "Skipping tokenization; test this!\n";}

    # sect15.html#sread; store terminating char ("newline")
    return(10) if $version >= 5;
}

sub save_buffer {
    # copy the input buffer to story memory.
    my ($buf, $text_address) = @_;
    my $mem_offset;
    $text_address++; # skip max-input-letters byte
    my $len = length $buf;
    my $version = $main::Constants{version};
    if ($version >= 5) {
	$PlotzMemory::Memory[$text_address++] = $len;
    }

    # copy the buffer to memory
    @PlotzMemory::Memory[$text_address .. $text_address + length($buf) - 1] =
        map {ord} split //, lc $buf;

    # terminate the line
    $PlotzMemory::Memory[$text_address + length $buf] = 0 if $version <= 4;
}

sub z_tokenise {
    
    # XXX Spec 'tokenise': If the number of entries is given as -n, then the
    # interpreter reads this as "n entries unsorted" (for user dictionaries)
    
    # text_len gets passed in if this sub is called from read()
    my ($text_address, $parse_address, $dict, $flag, $text_len) = @_;

    $dict ||= $main::Constants{dictionary_address};

    #  get token separators
    my $sep_count = $PlotzMemory::Memory[$dict++];
    my %separators;
    for (1..$sep_count) {
	# Spec 13.2: XXX IRL these are ZSCII not ASCII
	$separators{chr($PlotzMemory::Memory[$dict++])} = 1;
    }

    # number of bytes for each encoded word
    # Spec 13.3: this includes the word itself PLUS some data
    my $entry_length = $PlotzMemory::Memory[$dict++];
    # number of words in the dictionary
    my $entry_count = get_word_at($dict);
    $dict +=2;
    # Where the entries in the dictionary actually start
    my $word_start = $dict;

    #  my $b1 = new Benchmark();
    my $max_tokens = $PlotzMemory::Memory[$parse_address];
    # pointer to location where token data will be written
    my $token_p = $parse_address + 2;

    #
    #  Step 1: parse out the tokens
    #
    my $text_p = $text_address + 1;
    # skip past max bytes enterable
    if ($main::Constants{version} >= 5) {
	# needed if called from tokenize opcode (VAR 0x1b)
	$text_len = $PlotzMemory::Memory[$text_p] unless defined $text_len;
	# move pointer past length of entered text.
	$text_p++;
    }
    # Number of bytes between start of text_buffer and start of input bytes
    my $offset = $text_p - $text_address;

    # Get entered text from memory
    my $raw_input = join "", 
        map {chr} @PlotzMemory::Memory[$text_p .. $text_p + $text_len - 1];
    my @tokens;
    # Separate into tokens based on separators or spaces
    my $sep = join "", keys %separators;
    while ($raw_input =~ /[$sep]|[^ $sep]+/g) {
	push @tokens, [$&, $-[0] + $offset];
    } 

#    printf STDERR "tokens: %s\n", join "/", map {$_->[0]} @tokens;

    #
    #  Step 2: store dictionary addresses for words
    #
    my $encoded_length = $main::Constants{encoded_word_length};
    my $wrote_tokens = 0;
    my $untrunc_token;
    for (@tokens) {
	my ($token, $offset) = @{$_};
	# $offset = position in string, but there's 1/2 extra bytes at
	# beginning of text_buffer
	if ($wrote_tokens++ < $max_tokens) {
	    $untrunc_token = lc($token);
	    $token = substr($token,0,$encoded_length)
	        if length($token) > $encoded_length;
	    my $addr = get_dictionary_address(
		$token, $word_start, $entry_count, $entry_length);

	    # sect15.html#tokenise:
	    # when $flag is set, don't touch entries not in the dictionary.
	    #print "address is $addr\n";
	    if ($addr || !$flag) {
	        $PlotzMemory::Memory[$token_p++] = $addr >> 8;
	        $PlotzMemory::Memory[$token_p++] = $addr & 0xff;
	        $PlotzMemory::Memory[$token_p++] = length $untrunc_token;
	        $PlotzMemory::Memory[$token_p++] = $offset;
		#	printf "Wrote %x %x %d %d\n", @PlotzMemory::Memory[$token_p -4 .. $token_p -1];
	    }
	} else {
	    warn "Too many tokens: ignoring $token\n";
	    #  $self->write_text("Too many tokens; ignoring $token");
	    #$self->newline();
	}
    }

    # record number of tokens written
    $PlotzMemory::Memory[$parse_address + 1] = $wrote_tokens;

    #  my $b2 = new Benchmark();
    #  my $td = timediff($b2, $b1);
    #  printf STDERR "took: %s\n", timestr($td, 'all');

}

# Get the dictionary address for the given token.
# Spec 13.5: "Words must be in numerical order of the encoded text (when the
# encoded text is regarded as a 32 or 48-bit binary number with
# most-significant byte first)"
sub get_dictionary_address {
    my ($token, $dict_start, $num_words, $entry_length) = @_;
    #   Contains ugly hacks for non-alphanumeric "words".

    # make sure token is truncated to max length
    # Note: this is number of Zchars, not characters
    my $word_length = $main::Constants{encoded_word_length};

    # find the word
    # XXX z_encode_text should call encode_text, too.
    my @encoded = &encode_text($token, $word_length);
    $word_length = $word_length / 3; # encode 3 Z-chars per two-byte word
#    print map(sprintf("%x ",$_), @encoded), " is $token\n";
    die "Word @encoded is the wrong length" unless @encoded == $word_length;

    my $first = ($encoded[0] & 0x7c00) >> 10; # first Z-char
#    print "First is $first\n";
    my $search_index;
    my $linear_search;
    # XXX This'll probably break for special alphabets
    # space or shift: something special's going on, but we know this
    # special word should be one of the first few in the dictionary
    # because all regular (i.e., A0) words have first char 6-31
    if ($first < 6) { 
        $search_index = 0;
        $linear_search = 1;
    } else {
    # Sneakily guess where to start looking from.
    # In half the cases, a good first guess can save several binary chops
    # OTOH, in a number of cases it won't help at all!
# XXX        $search_index = int(($num_words - 1) * ($first - 6) / 26);
	$search_index = int($num_words/2);
        $linear_search = 0;
    }

      # In theory, we could optimize by caching dictionary hits.
      # But since this happens only once per turn, and we've already
      # got a binary search, and there shouldn't be more than a couple
      # thousand words (i.e., < 15 searches), it's probably not worth it.
      # Another option would be caching locations of first letters.
    my ($address, @word, $delta_mult, $delta, $next);
    my $behind = -1;
    my $ahead = $num_words;
    while (1) {
        $address = $dict_start + ($search_index * $entry_length);
#	printf"Trying %s at $search_index %x\n", decode_text($address),$address;
	my $diff;
	my $p = $address;
	for (0 .. $word_length - 1) {
	    #$word = 256*$PlotzMemory::Memory[$p++] +PlotzMemory::Memory[$p++];
#	    printf'%x_', get_word_at($p);
	    $diff = $encoded[$_] <=> get_word_at($p) and last;
	    $p+=2;
	}
#	print "Found ",decode_text($address),"\n" if !$diff;
	# found the word we're looking for: done
        return $address unless $diff;

	# missed: search further
	if ($linear_search) {
	    $next = $search_index + 1; # try next word
	} else {
	    # determine direction we need to search
	    if ($diff < 0) {
		# ahead; need to search back
		$delta = int(($search_index - $behind) / 2);
		$ahead = $search_index;
	    } else {
		# behind; need to search ahead
		$delta = int(($ahead - $search_index) / 2);
		$behind = $search_index;
	    }
	    $delta = 1 if $delta == 0;
	    $next = $search_index + ($delta * $diff);
	}

	if ($next < 0 or $next >= $num_words) {
	    # out of range
	    return 0;
	} elsif ($next == $ahead or $next == $behind) {
	    # word does not exist between flanking words
	    return 0;
	} else {
	    $search_index = $next;
	}
    }
    die "Finished a while(1) loop in dictionary search?!";
}

################################################################################
# Variables

# 1 arg - get, 2 args - set to value
# Special hack: if second arg is ++ or --, inc/dec the variable.
sub global_var {
    my ($index, $value) = @_;
    my $i = $main::Constants{global_variable_address} + $index * 2;
    if (defined $value) {
	if ($value eq "++" || $value eq "--") {
	    my $delta = $value eq "++" ? 1 : -1;
	    # XXX could do this without a sub call
	    # (Don't need to &0xffff cuz it's done below)
	    $value = global_var($index) + $delta;
	}
#    printf("g%x (%d) -> %d\n", $index, $index, $value);
	$PlotzMemory::Memory[$i] = ($value >> 8) & 0xff;
	$PlotzMemory::Memory[$i+1] = $value & 0xff;
	return $value;  # may be needed by caller
    } else {
	return 256*$PlotzMemory::Memory[$i] + $PlotzMemory::Memory[$i + 1];
    }
}

# Deal with bracketed indirect variables, that can't be computed at compile time
# (E.g., load [local1] -> result. See notes to Spec 14)
#
# Args: number representing a stack/local/global variable,
#       references to the current local vars & stack,
#       (optionally) a value
# If final arg is given, set the variable to the value (or the stack). 
# (Special case: if rval is '++' or '--', inc or dec the value/top of stack
# Otherwise, return the value of the variable (or top of stack).
#
# Spec v1.1draft7: indirect variables. If the bracketed thing refers
# to the stack, read/write to top of stack; do NOT push/pop the stack.
# (Any time we get to this sub, we're guaranteed to be an indirect variable.)

sub bracket_var {
    my ($var_num, $locv_ref, $stack_ref, $rval) = @_;
    die "Non-number passed to bracket_var: '$var_num'" 
	unless $var_num =~ /^\d+$/;

    # 0 means the stack
    if ($var_num == 0) {
	die "Empty stack in bracket_var" unless @$stack_ref;
	if (!defined $rval) {
	    return $$stack_ref[-1];
	} elsif ($rval eq "++" || $rval eq "--") {
	    my $delta = $rval eq "++" ? 1 : -1;
	    $stack_ref->[-1] = ($stack_ref->[-1] + $delta) & 0xffff;
	} else {
	    $stack_ref->[-1] = $rval;
	}

    # 1-15 means local variables
    } elsif ($var_num >=1 && $var_num <=15) {
	$var_num--; # var 1 refers to locv[0]
	if (!defined $rval) {
	    return $locv_ref->[$var_num];
	} elsif ($rval eq "++" || $rval eq "--") {
	    my $delta = $rval eq "++" ? 1 : -1;
	    $locv_ref->[$var_num] = ($locv_ref->[$var_num] + $delta) & 0xffff;
	} else {
	    $locv_ref->[$var_num] = $rval;
	}

    # 16-255 means global variables
    } elsif ($var_num >= 16 && $var_num <= 255) {
	# If $rval is defined, global_var will set, otherwise, just return value
	# If $rval is "++" or "--", global_var will handle correctly
	global_var($var_num - 16, $rval);

    } else {
	die "Illegal value '$var_num' passed to indirect_var";
    }
}

################################################################################
# Objects
#
# Object table starts with max_properties words of default properties
# Then each object has:
# - attribute_bytes bytes of attributes
# - 1 object pointer parent
# - 1 object pointer sibling
# - 1 object pointer child
# - 1 object pointer prop offset

# set_ptr/get_ptr uses bytes or words, depending on version
my $zstrict_warn = 0;
sub get_object {
    my ($arr) = @_;
    if (!defined $arr) {
	warn "\nCalled get/set parent/child/sibling with object 0" 
	    unless $zstrict_warn++;
	return 0;
    }
    if ($main::Constants{pointer_size} == 1) {
	return $PlotzMemory::Memory[$arr];
    } else {
	return 256*$PlotzMemory::Memory[$arr] + 
	    $PlotzMemory::Memory[$arr+1];
    }
}

sub set_object {
    my ($arr, $value) = @_;
    if ($main::Constants{pointer_size} == 1) {
	$PlotzMemory::Memory[$arr] = $value;
    } else {
	$PlotzMemory::Memory[$arr] = ($value >> 8) & 0xff;
	$PlotzMemory::Memory[$arr+1] = $value & 0xff;
    }
}

# XXX In theory I could inline this
sub thing_location {
    my ($object_id, $thing) = @_;
    # XXX untested handling for object 0
    return undef if $object_id == 0;
    # XXX Some way to test for object_id > num_objects?
    # name & prop come after child, so first do child offset, then do more
    my %ind = (parent => 0, sibling => 1, child => 2, name => 3, prop => 3);
    my %prop = (name => 1, prop => 1);
    # Start of all objects
    my %c = %main::Constants;
    # Where object table's attributes start
    my $address = $c{object_table_address} + $c{max_properties} * 2;
    $address += $c{object_bytes}*($object_id-1);
    return $address if $thing =~ /^attr(ibute)?s?$/;

    if (exists $ind{$thing}) {
	$address += $c{attribute_bytes};
	$address += $c{pointer_size} * $ind{$thing};
	#print "address is $address\n";
	if (exists $prop{$thing}) {
	    # we're currently at address of properties address, so go there
	    $address = 256*$PlotzMemory::Memory[$address] + 
		$PlotzMemory::Memory[$address+1];
	    # name-length-byte, name-length words, properties
	    if ($thing eq "name") {
		$address++; # address where Z-string starts
	    } else { # "prop"
		my $text_words = $PlotzMemory::Memory[$address];
		$address += $text_words*2 + 1; # address where properties start
	    }
	}
    } else {
	die "Bad arg '$thing' to thing_location";
    }
    return $address;
}

sub get_parent { get_object(&thing_location($_[0], 'parent')) }
sub get_child { get_object(&thing_location($_[0], 'child')) }
sub get_sibling { get_object(&thing_location($_[0], 'sibling')) }

sub set_parent { set_object(&thing_location($_[0], 'parent'), $_[1]) }
sub set_child { set_object(&thing_location($_[0], 'child'), $_[1]) }
sub set_sibling { set_object(&thing_location($_[0], 'sibling'), $_[1]) }

sub remove_obj {
    # remove this object from its parent/sibling chain.
    my ($object) = @_;
    # TODO change vec(thing_location) in ProtzTranslate to get_parent
    # since we use it here too? Or use vec here? Same for child/sib
    # No parent? don't need to remove from anything
    my $parent = get_parent($object) or return;

    my $parent_child = get_child($parent);
    my $sibling = get_sibling($object);
    # get child of old parent
    if ($parent_child == $object) {
        # first child matches: set child of old parent to first sibling
        # of the object being removed
        set_child($parent, $sibling);
    } else {
        # set the "next sibling" pointer of the previous
        # sibling in the chain to the next sibling of this
        # object (the one we're removing).
	# We'd better find the object before the end of the sibling chain
        my $prev_sib = $parent_child;
        my $this_sib = $prev_sib;
        while ($this_sib != $object) {
	    $prev_sib = $this_sib;
	    $this_sib = get_sibling($this_sib) or die
		"remove_obj: Failed for object '$object'. Bad sibling chain?";
        }
	set_sibling($prev_sib, get_sibling($this_sib));
    }

    set_parent($object, 0);
    set_sibling($object, 0);
}


# move object to become the first child of the destination object. 
sub insert_obj {
    my ($object, $new_parent) = @_;
  
    # if object being moved is ID 0, do nothing (bogus object)
    return unless $object;

    # unlink o from its parent and siblings
    remove_obj($object);
  
    # set new o's parent to d
    set_parent($object, $new_parent);
  
    # Only set children if new parent is not zero
    if ($new_parent) {
        my $old_child = get_child($new_parent);
        set_child($new_parent, $object);
    
        # If new parent already had children, make them the new siblings of o,
        # which is now d's "firstborn".
        set_sibling($object, $old_child) if $old_child;
    }
}
  
############################
# Attributes

# return true of specified attribute of this object is set,
# false otherwise.
# spec 12.3.1.
# attributes are numbered from 0 to 31, and stored in 4 bytes,
# bits starting at "most significant" and ending at "least".
# ie attrib 0 is high bit of first byte, attrib 31 is low bit of 
# last byte.
sub test_attr {
    my ($object_id, $attribute) = @_;

    # which of the 4 or 6 bytes the attribute is in
    my $byte_offset = $attribute / 8;
    # which bit in the byte (starting at high bit, counted as #0)
    my $bit_position = ($attribute % 8);
    my $bit_shift = 7 - $bit_position;
    my $attr_start = &thing_location($object_id, "attribute");
    my $the_byte = $PlotzMemory::Memory[$attr_start + $byte_offset];
    # move target bit into least significant byte
    my $the_bit = ($the_byte >> $bit_shift) & 0x01;

    return ($the_bit == 1);
}

# set an attribute for an object; spec 12.3.1
sub set_attr {
    my ($object_id, $attribute) = @_;
    my $byte_offset = $attribute / 8;
    my $bit_position = $attribute % 8;
    my $bit_shift = 7 - $bit_position;
    my $mask = 1 << $bit_shift;
    my $attr_start = &thing_location($object_id, "attribute");
    $PlotzMemory::Memory[$attr_start + $byte_offset] |= $mask;
}

# clear an attribute for an object; spec 12.3.1
sub clear_attr {
    my ($object_id, $attribute) = @_;
    my $byte_offset = $attribute / 8;
    my $bit_position = ($attribute % 8);
    my $bit_shift = 7 - $bit_position;
    my $mask = ~(1 << $bit_shift); # all 1's except a zero at our bit
    my $attr_start = &thing_location($object_id, "attribute");
    $PlotzMemory::Memory[$attr_start + $byte_offset] &= $mask;
}

###########################
# Properties

sub get_prop_addr {
    # Return address of prop data, or 0 if no such data
    # (Also returns zero for object 0 -- is that spec?)
    my ($object, $prop_num) = @_;
    return 0 if $prop_num == 0;

    my $prop_table = &thing_location($object, 'prop');
    my ($pnum, $paddr, $plen) = &get_prop_info($prop_table, $prop_num);
    return $paddr;
}

sub get_prop_len {
    my ($prop_addr) = @_;
    # Spec version 1.1draft7
    return 0 if $prop_addr == 0;

    # Note if the size is a word instead of a byte, we'll get the second
    # byte first!
    $prop_addr--;
    my $size_byte = $PlotzMemory::Memory[$prop_addr];
    my $plen;
    # Stolen from get_prop_info - see comments there
    if ($main::Constants{version} < 4) {
	$plen = ($size_byte >> 5) + 1;
    } elsif ($size_byte & 0x80) {
	# Inform compiles length 64 as length 0. Whatever.
	$plen = $size_byte & 0x3f || 64;
    } else {
	$plen = ($size_byte & 0x40) ? 2 : 1;
    }
    return $plen;
}

# Return the property after prop_num, or first property if prop_num == 0
sub get_next_prop {
    my ($object, $prop_num) = @_;
    my $prop_table = &thing_location($object, 'prop');
    # First get property prop_num
    my ($pnum, $paddr, $plen) = &get_prop_info($prop_table, $prop_num);
    die "Called get_next_prop on non-existent prop '$prop_num', " . 
        "object '$object'\n" unless $pnum;
    return $pnum if $prop_num == 0;

    # go to end of property prop_num, and call get_prop_info(0) to get next prop
    $paddr += $plen; 
    ($pnum, $paddr, $plen) = &get_prop_info($paddr, 0);
    return $pnum;
}

# return this value for this property - default value if this property
# doesn't exist in this object
sub get_prop {
    my ($object, $prop_num) = @_;
    my $prop_table = &thing_location($object, 'prop');
    # First get property prop_num
    my ($pnum, $paddr, $plen) = &get_prop_info($prop_table, $prop_num);
    my $value;
    if ($pnum == 0) { # get word stored at beginnning of object table
	$plen = 2;
	# Spec 12.1, 12.2: props are numbered from 1
	$paddr = $main::Constants{object_table_address} + 2 * ($prop_num - 1);
    }

    if ($plen == 1) {
	$value = $PlotzMemory::Memory[$paddr];
    } elsif ($plen == 2) {
	$value = 256 * $PlotzMemory::Memory[$paddr] +
	    $PlotzMemory::Memory[$paddr+1];
    } else {
	die "get_prop: Illegal length $plen for obj $object, prop $prop_num\n";
    }

    return $value;
}

# set this property in this object to specified value
sub put_prop {
    my ($object, $prop_num, $value) = @_;
    my $prop_table = &thing_location($object, 'prop');
    # First get property prop_num
    my ($pnum, $paddr, $plen) = &get_prop_info($prop_table, $prop_num);
    die "put_prop: nonexistent property $prop_num in object $object"
        unless $pnum;
    if ($plen == 1) {
	$PlotzMemory::Memory[$paddr] = $value & 0xff;
    } elsif ($plen == 2) {
	$PlotzMemory::Memory[$paddr] = ($value >>8) & 0xff;
	$PlotzMemory::Memory[$paddr +1] = $value & 0xff;
    } else {
	die "put_prop: Illegal length $plen for obj $object, prop $prop_num\n";
    }
}

# search in properties starting at arg0 for a specific property arg1
# If called with property 0, get next property, whatever number it is
# Otherwise, return the requested property, or 0 if it doesn't exist
sub get_prop_info {
    # Spec 12.4: properties are stored in descending numerical order
    # So search until you get property <= search id (if any)
    my ($start_address, $search_id) = @_;
    my $address = $start_address;

    my $property_number = 0;
    my $property_length = 0;
    my $property_address = 0;
    my $exists = 0; # did we find something?
    do {
	my $size_byte = $PlotzMemory::Memory[$address++];
	return (0, 0, 0) if $size_byte == 0; # end of property list

	if ($main::Constants{version} < 4) {
	    # spec 12.4.1:
	    # 32 times the number of data bytes minus one, plus property number
	    $property_number = $size_byte & 0x1f;
	    $property_length = ($size_byte >> 5) + 1;
	} else {
	    # spec 12.4.2:
	    # property number in bottom 6 bits
	    $property_number = $size_byte & 0x3f;
	    if ($size_byte & 0x80) {
	        # top bit is set, there is a second size byte
	        # length in bottom 6 bits
		# (Inform compiles length 64 as length 0!)
	        $property_length = 
		    $PlotzMemory::Memory[$address++] & 0x3f || 64;
	    } else {
	        $property_length = ($size_byte & 0x40) ? 2 : 1;
	    }
	}
	$property_address = $address;
	$address += $property_length;

	    # This was in ME's code. Don't know why it's needed
	    #if ($last_id and $property_number > $last_id) {
	    # this means we are past the end
	    # ...need example case here!
	    #last; }
    } while ($search_id && $search_id < $property_number);

    if (!$search_id || $property_number == $search_id) {
	return ($property_number, $property_address, $property_length);
    } else {
	return (0,0,0);
    }
}

################################################################################
# Text
# Move this to LZ::Runtime::IO, then we don't need this.
use constant Z_NEWLINE => 13; 

# These are entries 6-31 in the 3 ZSCII alphabets
# XXX Versions 5+ may have different alphabet table.
# Note that in that case, alpha_table should hold not characters but integers.
# Those integers will be ZSCII values, so e.g. if alpha_table[0][0]=155,
# then use the first extra character (defined in the Unicode translation table)
# when you get Z-character 6
my @alpha_table = (
       [ 'a' .. 'z' ],
       [ 'A' .. 'Z' ],
       # char 6 means 10-bit ZSCII follows, so we should never translate it
       [ 'PLOTZ ERROR!', chr(Z_NEWLINE),
                     split//,qq{0123456789.,!?_#'"/\\-:()} ]
);

# decode and return text at this address; see spec section 3
# Note that this sub only reads things in low memory!
# XXX Differences for versions 1,2
sub decode_text {
    my ($address) = @_;
    my $buffer = "";

    my ($word, $zshift, $zchar);
    my $alphabet = 0;
    my $abbreviation = 0;
    my $two_bit_code = 0;
    my $two_bit_flag = 0;
    # XXX HACK!
    my $flen = @PlotzMemory::Memory;
      
    while (1) {
	last if $address >= $flen;
	# Deal with translation problems of Advent.z5
	if (!defined $PlotzMemory::Memory[$address]) {
	    warn "Bad address $address to decode_text";
	    return
	}
	$word = 256*$PlotzMemory::Memory[$address++] +
	    $PlotzMemory::Memory[$address++];
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
		# Spec 3.3, 1.2.2: fetch and convert the "word address" of the
		# given entry in the abbreviations table.
		# "word address"; only used for abbreviations (packed address
		# rules do not apply here)
		my $abbrev_addr = $main::Constants{abbrev_table_address} + 
		    $entry * 2;
		my $addr = get_word_at($abbrev_addr) * 2;
		my $expanded = decode_text($addr);
		$buffer .= $expanded;
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
		      # XXX from rezrov
		      $buffer .= chr(Z_NEWLINE);
		      #	$buffer .= "\n";
		    } else {
			$buffer .= $alpha_table[$alphabet]->[$zchar];
		    }
		}
		# XXX applies to this character for version > 2 (3.2.3)
		$alphabet = 0; # turn "Shift" off
	      }
	}
	# Last bit set
	last if $word & 0x8000;
    }
  
    return $buffer;
}

# Spec 3.7: When an interpreter is encrypting typed-in text to match against
# dictionary words, the following restrictions apply. Text should be converted
# to lower case (as a result A1 will not be needed unless the game provides its
# own alphabet table). Abbreviations may not be used. The pad character, if
# needed, must be 5. The total string length must be 6 Z-characters (in
# Versions 1 to 3) or 9 (Versions 4 and later): any multi-Z-character
# constructions should be left incomplete (rather than omitted) if there's no
# room to finish them.

# Default encoding (not counting alphabet table). ZSCII is mostly ASCII
# '5' means A2, '6' in A2 means next two 5-bit numbers are 10-bit ZSCII char. 
my %encode_table = (
    (map {chr, [5, 6, $_>>5, $_&0x1f]} 32..126),
    " " => [0],
    "\n" => [13],
);

# Return an array that encodes the given string in exactly the given length
# (I.e., chop if too long, pad with shift chars (5) if too short
sub encode_text {
    # Length of end-product in bytes (not number of bytes to encode)
    my ($text, $entry_length) = @_;
    $text = lc $text;
    my $c = 6;
    # Create the encoding table
    for (@{$alpha_table[0]}) {
	$encode_table{$_} = [$c++];
    }
    $c = 6;
    # shift to alphabet 1, letter
    for (@{$alpha_table[1]}) {
	$encode_table{$_} = [4, $c++];
    }
    # shift to alphabet 2, letter
    $c = 6;
    for (@{$alpha_table[2]}) {
	$encode_table{$_} = [5, $c++];
    }

    # Spec 3.8.4:
    # Defined for input only
    # 129: cursor up  130: cursor down  131: cursor left  132: cursor right
    # 133: f1         134: f2           ....              144: f12
    # 145: keypad 0   146: keypad 1     ....              154: keypad 9
    # XXX TODO

    # Spec 3.8.5
    # Special characters 155-251
    # XXX TODO

    # Spec 3.8.6:
    # ZSCII codes 252 to 254 are defined for input only: 
    # 252: menu click   253: mouse double-click   254: mouse single-click
    # 
    # Menu clicks are available only in Version 6. In Versions 5 and later it
    # is recommended that an interpreter should only send code 254, whether the
    # mouse is clicked once or twice. 
    # TODO

    die "Illegal to create a Z-char > 31" if 
	grep {$_ > 31} map {@$_} values %encode_table;

    # Encode each letter
    # XXX die if unknown char?
    my @zchar = map {@{$encode_table{$_}}} split //, $text;
    # pad w/ shift chars as necessary
    push @zchar, (5) x $entry_length; 
#    print "Chars @zchar\n";
    # Cut to correct length, breaking multi-byte chars in the middle.
    $#zchar = $entry_length - 1;
    
    # Turn into 5-bit chars
    die "Need a length that's a multiple of 3: $entry_length" 
	if $entry_length %3;
    my @words = ();
    my $n = 0;
    for (0 .. ($entry_length/3) - 1) {
	my $word = ($zchar[$n++] << 10) + ($zchar[$n++] << 5) + $zchar[$n++];
	push @words, $word;
    }
    $words[-1] |= (1 << 15);

    return @words;
}

sub get_byte_at {
    my ($arr, $index) = @_;
    $index = 0 if !defined $index;
    return $PlotzMemory::Memory[$arr + $index];
}

sub get_word_at {
    my ($arr, $index) = @_;
    $index = 0 if !defined $index;
    return 256*$PlotzMemory::Memory[$arr + $index] + 
	    $PlotzMemory::Memory[$arr + $index + 1];
}

1;
