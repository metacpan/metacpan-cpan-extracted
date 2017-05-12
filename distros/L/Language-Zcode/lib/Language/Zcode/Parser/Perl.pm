package Language::Zcode::Parser::Perl;

use strict;
use warnings;
use base qw(Language::Zcode::Parser::Generic);

=head1 NAME

Language::Zcode::Parser::Perl - Z-code parser in pure Perl

=head1 DESCRIPTION

=head2 Finding subroutine starts and ends

Things we know:

=over 4

=item 1a

We understand the syntax of all opcodes that are in the spec. (modulo bugs)

=item 1b

0 is not a legal opcode (almost every other 1-byte number is,
depending on version -- but see NOTES)

=item 2a

Subs must start at packed addresses. Bytes between subs are always zero 
(I hope!)

=item 2b

Subs must start with a byte 0-15

=item 2c

If header byte is zero, next byte CAN'T be a zero, cuz there are
no locals so it has to be a command, and 0 isn't a command

=item 2d

Subs must be called with call* opcodes, although it is legal to call
a variable (like "call_2n sp 1 2")

=item 3a

There is no way for the program to get past a ret, rfalse (etc.) or jump
(backwards) command without jumping past it.  

=item 3b

jump opcodes cannot take variable args

=item 3c

There may be code after a sub-ender that is not jumped into. This is a (rare,
but existent) orphan fragment.

=back

The upshot of this is that, if we propose that a sub starts at a given address,
we can unambiguously read (the header and) commands until we hit a sub-ender
that is not jumped past.  If we find unexpected 0 bytes, for example, then we
were wrong about the sub's starting address.

So:

    read a command. (Note if it has a sub call or a jump)

    if next byte is a known start of sub {
       we finished this sub! Celebrate

    } else if next byte is a 0 {   
       # there must be a sub next
       if there's more than one 0 { 
	  skip to the last 0 in the series 
	  again, if we get to known start of sub, we're done
       }
       if last 0 is on packed address {
	  start a sub here # 0 local vars, so next byte must be (non-zero) cmd
       } else if next byte is on packed address and is 1-15 {
	  start a sub at that byte
       } else error!

    } else if not on packed address OR next byte is not 1-15 { # must be command
       read next command

    } else { # start doing things I'm less sure about
       # During this less sure part, if I get a parsing error, try
       # the other possibility
       if previous command was a ret, rfalse etc. that we have not jumped past {
	  read sub
       } else {
	  read command
       }
    }

Also stop if we get to a known string address or end of the file. The
first string may be referenced in a sub we don't see, or may not be referenced
at all (Zork1 always call print_paddr with variables, not constant string
addresses.) so we'll run past the end of the last sub and into the strings.

Arg to a call is considered the most authoritative demonstration that
a sub exists. 0..15 byte at a packed address is slightly less sure, especially
if there are no 0 bytes separating it from the previous sub (could be
an orphan fragment).

=cut

use constant SURE => 8;
use constant ALMOST_SURE => 4;
use constant PROBABLE => 2;
use constant MAYBE => 1;

# Note throughout that eat_byte gets a byte and sets PC() to be that byte's
# position PLUS ONE
    # TODO get rid of @todo. Just use 
    # (grep {$prob ^ DONE} sort {$prob} keys %prob)[0]
    # When finishing a sub, $prob |= DONE
    # $packed, %end_codes go into main while loop (which becomes subroutine)
    # $string_min, %prob = try_sub($string_min, %prob);
sub find_subs {
    # Only sub we know of right now is (1 byte before)
    # the start address in the header
    my $main_sub = $Language::Zcode::Util::Constants{first_instruction_address} - 1;
    my @todo = ($main_sub);
    my %prob = ($main_sub => SURE); 
    # Also, try the address just after the dictionary ends
    my $dict_end = &end_of_dictionary;
    if ($dict_end != $main_sub) {
	push @todo, $dict_end;
	$prob{$dict_end} = MAYBE;
    }
    # For finding packed addresses
    my $packed = $Language::Zcode::Util::Constants{packed_multiplier};
    my $string_min = $Language::Zcode::Util::Constants{file_length}-1; # min addr of strings
    my @subs;
    # Codes that can end a routine
    my %end_codes = map {$_ => 1} 
	# Note: only jump can cleanly end a sub, not je & other branch ops
	qw(ret rfalse rtrue ret_popped print_ret jump quit);

    # We shift subs out. So if we find something we're sure is a sub,
    # unshift it into the list. If we're not so sure, push it onto the end,
    # so we won't look at it until after looking at subs we're sure of.
    while (defined (my $rtn = shift @todo)) {
	my $hr = sprintf('%x', $rtn);
#	print "Routine $hr ($rtn): ";
	# Read num_locals -- and read the locals, for v1-4
	eval {&Language::Zcode::Parser::Opcode::parse_sub_header($rtn)};
	if ($@) { warn $@; delete $prob{$rtn}; next }
	my $max_PC = PC(); # we know the sub goes at least until...
	my $last_command = $max_PC; # address of last command in the sub
	while (1) {
	    # changes PC
	    my %command=&Language::Zcode::Parser::Opcode::parse_command;
	    delete $prob{$rtn}, last unless %command; # unknown opcode
	    $last_command = $command{opcode_address};
	    my $sub_ender = exists $end_codes{$command{opcode}};
	    my $pc = PC();

	    if ($pc >= $string_min) {
#		print "sub ends at $pc, start of strings\n";
		$max_PC = $string_min -1;
		last;
	    }

	    # If we can branch to a point later in the code, we know the
	    # sub goes at least until there.
	    # (IRL, you can jump outside a sub, but we're ignoring that.)
	    # jz foo 0/1 will have label = "", cuz it really means "return"
	    if (exists $command{label} && !exists $command{jump_return}) {
		my $l = $command{label};
		die "Illegal to jump to a variable ($pc)!?" if $l =~ /\D/;
		$max_PC = $l if $l > $max_PC;
	    }

	    # For call* commands, note addresses of the subs they call
	    if (exists $command{routine}) {
		# p_a_s will return 0/undef if it's not a "useful" call
		if (my $r = packed_address_str($command{routine}, "routine")) {
		    unshift @todo, $r if !exists $prob{$r};
		    $prob{$r} |= ALMOST_SURE; # pretty sure it's a sub
		}
	    }

	    # Find address of first string - stop parsing routines there!
	    if (exists $command{packed_address_of_string}) {
		my $s = $command{packed_address_of_string};
		$s = packed_address_str($s, "packed_address_of_string");
		if (defined $s && $s < $string_min) {
#		    print "$s < $string_min - new string min\n";
		    $string_min = $s;
		}
	    }


	    # Now go through a long complicated procedure to see if
	    # we've finished the sub

	    # 0 byte means there must be a sub next
	    # (Note: we may change PC() in here)
	    if ((my $byte = &peek()) == 0) { 
		# byte starting next sub must be at packed address
		# and must be (0 followed by nonzero OR 1..15)
		# (We also know $packed is always at least 2)
		# Skip zero or more 0's until byte AFTER me is NOT zero
		$byte = Language::Zcode::Parser::Opcode::eat_byte() 
		    until peek() != 0;
		$pc = PC();
		if ($pc >= $string_min) {
#		    print "sub followed by zeroes and first string $pc\n";
		    $max_PC = $string_min -1;
		    last;
		}
		# If we read 0 byte starting a sub, (numlocals = 0), back up
		if ($pc % $packed == 1 && $byte == 0) { PC(--$pc); }
		
		# ERRORS. If we read a 0 byte, but a new sub doesn't start
		# at the next packed address, then the *current* sub
		# we're reading must not really be a sub!
		if ($pc % $packed || &peek() > 15) { # 0 byte, but no new sub!
		    warn peek(), " at $pc > 15. 0 in middle of sub!\n";
		    delete $prob{$rtn};
		    last;
		} elsif ($max_PC>$pc) {
		    warn "Max $max_PC > $pc in rtn $rtn. Jump past sub end?\n";
		    delete $prob{$rtn};
		    last;
		}

		# Sub to try. May or may not be new. We'll "last" below
		$prob{$pc} |= PROBABLE; # somewhat sure it's a new sub

	    # If we *can* finish a sub now, but we don't KNOW there's
	    # another sub starting now, then *probably* we ended sub,
	    # but it might be an orphan code fragment
	    } elsif ($sub_ender && $max_PC < $pc && !exists $prob{$pc}) {
		if ($byte <=15 && $pc % $packed == 0) {
		    # COULD be an orphan code fragment w/ 1..15 byte: very rare
#		    printf "ASSUME ";
		    $prob{$pc} |= MAYBE; # not entirely sure it's a new sub
		} else {
#		    printf "Orphan code fragment: PC %x ($pc)\n",$pc
		}
	    }
	    
	    # We know sub lasts at least until end of command we just read
	    $max_PC = $pc-1 if $pc > $max_PC;

	    # Found a new sub here?
	    if (exists $prob{$pc}) {
#		print "sub ends at ";
#		print "start of sub " if $prob{$pc} & ALMOST_SURE;
#		printf "%x ($pc).\n", $pc;
		# less sure of these subs; 'push' means try them last
		push @todo, $pc if $prob{$pc} < ALMOST_SURE; 
		last; # Starting a new sub, so stop reading this one
	    } # else keep reading commands
	}

	if (exists $prob{$rtn}) { # bad subs have been delete()d
	    my $routine = new Language::Zcode::Parser::Routine $rtn;
	    $routine->end($max_PC);
	    $routine->last_command_address($last_command);
	    push @subs, $routine;
	    # If we made it to the end of a sub, we're pretty sure it's real
	    $prob{$rtn} |= ALMOST_SURE; # (if we weren't sure about it already)
	}
    }

    return sort {$a->address <=> $b->address} @subs;
}

sub PC { 
    $Language::Zcode::Parser::Opcode::PC = $_[0] if $_[0];
    return $Language::Zcode::Parser::Opcode::PC 
}
sub peek { $Language::Zcode::Util::Memory[$Language::Zcode::Parser::Opcode::PC] }

# Returns undef for situations where we don't get a true address
# "@call sp", where we don't know sub address, OR "call 0", which isn't a call
sub packed_address_str {
    my ($address, $key) = @_;
    return undef if !$address;
    my %c = %Language::Zcode::Util::Constants;
    my $mult = $c{packed_multiplier};
    my $add;
    # (Add will be zero for versions not 6 or 7)
    if ($key eq "routine") {
	$add = 8 * $c{routines_offset};
    } elsif ($key eq "packed_address_of_string") {
	$add = 8 * $c{strings_offset};
    } else { die "Unknown key $key to packed_address_str" }

    # Now actually create the string. Only do calculation for true number
    if ($address =~ /^\d+$/) {
	return $mult * $address + $add;
    } else {
	return undef;
    }
}

=head2 end_of_dictionary

Find the first packed address after the end of the dictionary.
(This is a likely place for the lowest-address subroutine.)

=cut

sub end_of_dictionary {
    my $dict = $Language::Zcode::Util::Constants{dictionary_address};
    PC($dict);

    #  get token separators
    my $sep_count = Language::Zcode::Parser::Opcode::eat_byte(); 
    Language::Zcode::Parser::Opcode::eat_byte() for 1..$sep_count;

    # number of bytes for each encoded word
    # Spec 13.3: this includes the word itself PLUS some data
    # number of words in the dictionary
    my $entry_length = Language::Zcode::Parser::Opcode::eat_byte();
    my $entry_count = Language::Zcode::Parser::Opcode::eat_word();
    # Now skip N M-byte words -> first byte AFTER dictionary
    # Then go to first packed address after that
    my $word_start = PC();
    my $dict_end = $word_start + $entry_count * $entry_length;
#    printf "Start at $dict (%x). $entry_count $entry_length-byte words.",$dict;
#    printf "\nEnd at $dict_end (%x)\n", $dict_end;
    my $byte;
    my $packed = $Language::Zcode::Util::Constants{packed_multiplier};
    PC($dict_end);
    $byte = Language::Zcode::Parser::Opcode::eat_byte() 
	until PC() % $packed == 0;
    $dict_end = PC();
#    printf "First possible sub after dict is PC $dict_end (%x)\n", $dict_end;
    return $dict_end;
}

=head1 NOTES

Actually, the remarks on section 14 of the spec say, "The 2OP opcode 0 was
possibly intended for setting break-points in debugging (and may be used for
this again). It was not nop." So in theory my algorithm may not be right.
Oh well.

=head1 TODO

This will break if there's data interleaved between the subs.
See SPEC comments on section 1.

Start at the byte after the end of the dictionary. Look at every packed
address that's not included in a subroutine I've already found, up until
we get to the strings. If I find something that looks like a sub, start
parsing commands as above, except with a "not sure" flag set. If we find
calls in that sub, follow them, but propagate the "not sure" flag.

=cut

1;
