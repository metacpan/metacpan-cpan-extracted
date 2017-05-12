package Language::Zcode::Runtime::State;

use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(z_call save_state restore_state);

use Language::Zcode::Runtime::Quetzal;

=head1 NAME

Language::Zcode::Runtime::State - Handle saving, restoring, etc. the game state

=cut


# @Call_Stack is a Z-machine (Quetzal) call stack we read from a save file.
# To restore a saved state, we climb it and restore each frame.
# Call stack originally has a dummy frame in it
# (I'm creating that by doing a z_call(first sub) tho.
# TODO v6 there's no dummy frame.
my @Call_Stack;
my $Restore_PC;

=head2 restoring

Getter/setter: currently in the process of restoring or not?

=cut

my $Restoring = 0;
sub restoring() {
    $Restoring = $_[0] if defined $_[0];
    return $Restoring;
}

=head2 start_machine

Start executing the Z-machine.

In the normal case (starting a new game, or restarting), this is as simple
as calling the Z-machine subroutine whose address is stored in the header.

If we're restoring from a save file, it's more complicated.  
See L</"resume_execution">.

=back

=cut

sub start_machine {
    if (restoring()) { # resume Z-machine execution right where we left off
	&resume_execution();

    } else { # regular old (re)start

    }

}

=head2 z_call

Wrapper around Z-code subroutine calls. The main reason we need it is
for save/restore.

In the normal case, z_call just calls the Z-code subroutine at address arg0
with the given args (arg5-argn), if any. Args 1-4 aren't used by z_call, but
(hack alert!) they go into the Perl call stack, which is needed for
saving Z-machine state.

Input: subroutine address to call, local variables & eval stack (arrayrefs),
next PC, store variable, args to the Z-sub.

See L</"The call stack"> for far more detail on this sub and save/restore.

=cut

# TODO put 'A' variables into a [], maybe after @args because they're not 
# used by the sub. Just pop them off.
sub z_call {
    # 'A' vars are just passed in so they'll be in the Perl call stack;
    # they're not actually used in this sub!
    # $Astore is undef for call_?n
    my ($sub_address, $Aloc, $Astack, $Anext, $Astore, @args) = @_;

    # Spec 6.4.3, 15 'call': "When the address 0 is called as a routine, nothing
    # happens and the return value is false".
    return 0 if $sub_address == 0;

    printf "Sub $sub_address (%x) called with params (@args)\n", $sub_address
        if $main::DEBUG;

    # Special info for recreating the call stack during restore, 
    # when the called sub has to start in the middle,
    my $frame_info = []; 

    if (restoring()) {
	# Recursively call z_call to climb the stack (which as a side effect
	# rebuilds the Perl call stack), store the return value,
	# then call the Z-code sub with new args so it starts in the middle
	# and has the correct @locv/@stack
	my %frame = %{shift @Call_Stack};
	my ($locref, $stackref) = @frame{qw(locals eval_stack)};
	my @locv = @$locref;
	my @stack = @$stackref;

	# address to resume at (jump to) in the to-be-called sub.
	my $next_PC;
	if (@Call_Stack) {
	    # Climb one frame on the stack and call z_call recursively
	    %frame = %{$Call_Stack[0]}; # don't shift; need it next time
	    $next_PC = $frame{next_PC};

	    my $next_next = @Call_Stack > 1 ? 
	        $Call_Stack[1]->{next_PC} : $Restore_PC;
	    my $sub_to_call = &_find_sub_start($next_next);
	    # All we need is correct *number* of args, so call stack looks right
	    my @dummy_args = (-1) x ($frame{args} =~ tr/1//);
	    my $store_var = $frame{discard_result} ? undef : $frame{store_var};
	    my $result = z_call($sub_to_call, $locref, $stackref, $next_PC, 
	        $store_var, @dummy_args);

	    # Store the result in variables from the calling sub (or globals)
	    if (defined $store_var) { # otherwise, discard result
		die ("Invalid store_var $store_var in restored state")
		    if $store_var =~ /\D/ || $store_var > 255;
		if ($store_var == 0) {
		    push @stack, $result;
		} elsif ($store_var < 16) {
		    $locv[$store_var - 1] = $result;
		} else {
		    Language::Zcode::Runtime::Opcodes::global_var($store_var - 16, $result);
		}
	    }

	} else {
	    # we're about to jump into the top stack frame, and we'll start
	    # it at the address where it calls save
	    #   - Don't store result in a store_var. &save_state will return
	    #     a value to @save.
	    #   - next_PC will be restore_PC instead of a frame's next_PC
	    #   - stop recursion
	    $next_PC = $Restore_PC;
	}

	# Call the sub with extra info so that it starts execution in the middle
	$frame_info = [$next_PC, \@locv, \@stack];
    } # end if (restoring())


    # Actually call the subroutine, possibly telling it to start executing
    # somewhere in the middle with restored values
    my $result = do {
	no strict 'refs'; &{"main::rtn$sub_address"}($frame_info, @args) 
    };

    return $result; # may be undef
}

# Given an address, find the subroutine that that address falls in.
# HACK: Find all subroutine start addresses by peeking at the symbol table.
sub _find_sub_start {
    my $addr = shift;
    my @rtns = sort grep { /^rtn(\d+)/ and $_ = $1 } keys %::;
#    print "Match $addr. Routines are @rtns\n";
    # Binary search (except we won't find an exact match - but that's OK
    # because first byte in a sub CAN'T be an opcode address.)
    # Perl golf'ed down to one line, tho I didn't take out the whitspace :)
    my ($lo, $hi, $i) = (0, $#rtns+1); # +1 so $lo can get up to $#rtns
    ($addr >= $rtns[$i = int(($lo + $hi)/2)] ? $lo : $hi) = $i 
	while $hi - $lo > 1;
    return $rtns[$lo];
}

=head2 save_state

Implement the @save opcode, saving the current Z-machine state (as opposed to
writing a table to a file, the other use of the @save opcode)

Note that this sub also gets called at the very end of the restoring process.

Returns 0 for failed save, 1 for successful save, 2 for "just finished
restoring".

=cut

sub save_state {
    my ($PC, $locref, $stackref) = @_;
    my $save_result = 0;

    if (&restoring()) { # Just finished a restore
	&restoring(0); # We're done restoring
	$save_result = 2;

    } else { # really save
	
	my $save_name = Language::Zcode::Runtime::IO::filename_prompt("-ext"=>"sav",-check=>1)
	    or return 0;

	my $header = {
	    release => $main::Constants{release_number}, 
	    serial => $main::Constants{serial_code},
	    checksum => $main::Constants{file_checksum},
	    restore_PC => $PC,
	};

	# Munge the Perl call stack to create a Z-machine call stack
	# that will get saved. 
	my @Z_Stack = build_save_stack($locref, $stackref);

	my ($str) = Language::Zcode::Runtime::Quetzal::build_quetzal(
	    $header, \@Z_Stack, &PlotzMemory::get_dynamic_memory);
	if ($str) {
	    write_file($save_name, $str);
	    $save_result = 1;
	}
    }

    return $save_result;
}

=head2 build_save_stack

Create a Z-machine call stack by peeking at the Perl call stack.

When calling Z_machine subroutines, we call z_call with all the information
contained in a Z stack frame. We retrieve that information from the Perl
call stack and build a Z-machine call stack with it.

=cut

sub build_save_stack {
    my ($locref, $stackref) = @_;
    my @save = ();
    {
	package DB; # make caller() set @DB::args
	my $i = 0;
	my ($lref, $sref) = ($locref, $stackref);
	while (my ($p,$f,$l,$s) = caller(++$i)) {
	    if ($s =~ /z_call/) {
	    #z_call(ROUTINE, \@locv, \@stack, NEXT_PC, STORE_VAR, ARG_LIST)
		my @a = @DB::args;
		my $discard = defined $a[4] ? 0 : 1;
		my $store_var = $discard ? 0 : $a[4];
		#my $args = substr('0'x8 . '1'x($#a - 4), -8, 8);
		my $args = sprintf('%08s', '1' x ($#a - 4));
		unshift @save, {
		    discard_bit => $discard, store_var => $store_var,
		    args => $args, next_PC => $a[3],
		    locals => $lref, eval_stack => $sref,
		};
		($lref, $sref) = @a[1, 2]; # for next frame
	    }
	}
    }
    # Quetzal 4.11.1: Dummy frame at bottom of stack has discard=0, too
    $save[0]{discard_bit} = 0;
    return @save;
}

=head2 restore_state

Implement the @restore opcode, restoring the current Z-machine state (as
opposed to reading a table from a file, the other use of the @restore opcode)

=cut

sub restore_state {
    # TODO static variable in this package stores name of the last
    # restore file, and offers to reuse. in case user e.g., keeps dying
    my $restore_name = Language::Zcode::Runtime::IO::filename_prompt(
	"-ext" => "sav") or return 0;
    warn "Can't find file '$restore_name'\n", return 0 
        unless -e $restore_name;

    my $restore_result = 0;
    my $save_string = read_file($restore_name) or return 0;
    my ($memory_ref, $stack_ref, $header_ref) = 
	Language::Zcode::Runtime::Quetzal::parse_quetzal($save_string);
    # Store new memory to be restored after we "die"
    PlotzMemory::store_dynamic_memory($memory_ref);
    my %header = %$header_ref;
    my ($release, $serial, $checksum, $PC) = 
	@header{qw(release serial checksum restore_PC)};

    # verify this is a valid restore for this game
    my $error = "";
    if ($release ne $main::Constants{release_number}) {
	$error = "Save file is for game release $release, " .
	    "not $main::Constants{release_number}";
    } elsif ($checksum ne $main::Constants{file_checksum}) {
	$error = "Checksum in save file is different than game checksum";
    } elsif ($serial ne $main::Constants{serial_code}) {
	$error = "Save file is for game serial # $serial, " .
	    "not $main::Constanst{serial_code}";
    }
    if ($error) {
	Language::Zcode::Runtime::IO::write_text($error);
	Language::Zcode::Runtime::IO::newline();
    } else {
	$Restore_PC = $PC;
	@Call_Stack = @$stack_ref;
	&restoring(1); # turn on global restoring flag

	# Now throw an exception that'll reboot the Z-machine
	die "Restore\n";
    }
    return $restore_result; # 0. Otherwise, we've restored and are elsewhere
}

# read save file
sub read_file {
    my $save_file = shift;
    open F, $save_file or 
        warn "Opening $save_file for read: $!\n" and return 0; 
    binmode F;
    my $st;
    { local $/; undef $/; $st = <F>; }
    close F;
    return $st;
}

# write save file
sub write_file {
    my ($save_file, $str) = @_;
    open F, ">$save_file" or die "Opening $save_file for write: $!\n";binmode F;
    print F $str;
    close F;
}

=head1 NOTES

=head2 The call stack

The Z-code call stack is much different than the Perl call stack, so it
takes a bit of work to convert one to the other. Almost all of the work
is done by the z_call routine which is a wrapper around Z-code subs.

B<Building the call stack>

z_call is called with extra args (arg1-arg4), that are not technically used
by z_call or the subs it calls. However, the Perl call stack stores
these args, and we can later build a Z-machine (Quetzal) call stack
using @DB::args (see L<perlfunc/"caller">). Sneaky!

B<Restoring>

How do we restore from a save file? We need to start execution with the
Z-machine in the same state it was in when we did the @save.  So we need to
restore local variables and the eval stack. We also need to restore the call
stack, so that when we finish a sub, we jump back into the middle of the sub
that called that sub (at the address right after the call).  

restore_state is quite simple: it just sets the restoring flag and then die()s
(i.e., reboots the Z-machine). Most of the work is done by &z_call, when it
sees the restoring flag.

When we're restoring, z_call is more complicated. We need to start executing
subroutines in the middle (i.e., wherever the program counter was when @save
was called), with the correct local variable and eval stack values.

z_call does this by reading data from the call stack and calling the Z-code
subs with special args that tell them to start executing at a given address.

Where the usual calling tree looks like this:
 The main Perl program calls z_code(A)
     z_call calls Z-code sub A ('main' sub)
	Z-code sub A calls z_call(B)
	    z_call calls B
		Z-code sub B calls z_call(C), etc.

We instead do this:
 The main Perl program calls z_code(A)
     z_call sees that A will call B, so it calls z_call(B)
	 z_call(B) sees that B will call C, so it calls z_call(C)
	     ...
	     z_call(E) calls z_call(F), exhausting the restored call stack
		 z_call(F) stops recursing and calls Z-code sub F with special
		 args saying to start executing at the @save command
		     F says "stop restoring", and returns
	     z_call(E) calls E, saying to start executing after the call to F
	     ...
	 z_call(B) calls B, saying to start executing after the call to C

This is complicated, but has several benefits:

=over 4

=item *

We rebuild the Perl call stack so that if we call @save again from, say, a
later point in E, we'll save the stack correctly.  

=item *

By climbing up the stack, we can properly store C's return value in a variable
in B, etc.

=item *

The complexity is (mostly) kept in z_call, not all over the translated
Z-code.

=item *

Each Z-code sub ends up executing in the middle of the sub, right where it was
- and in the same state as it was - when the @save happened.

=back

The very first opcode we execute when z_call gets to the top of the stack is
guaranteed to be @save. This turns the restoring flag off.  By the time we
return from the called Z-code sub back to z_call, even though we're within
several levels of recursion, we're in normal program flow. 

(Note that z_call and the Z-code subs were calling each other recursively
anyway.  We just change the order around when restoring, so z_call calls itself
and then calls the Z-code sub.)

B<Frame mismatch>

Another piece of complexity is a mismatch between Quetzal and Perl.

Assume sub B calls sub C, with a call like
 $result = z_call(C, Blocals, Bstack, Bnext_PC, Bstore_var, args);

(where Blocals means the local variables in subroutine B).

Quetzal frames actually mix values from different (Perl) subroutines, so
we have frames like (Clocals, Cstack, Bnext_PC, Bstore_var).

In addition, the only way we can figure out C while restoring is to
get Cnext_PC (which will be in the frame with Dlocals et al.!) and
to find the sub that contains the Cnext_PC address. So we actually
need to look at three different frames in order to recreate the
z_call that happened in the saved program.

B<Starting subs in the middle>

z_call is called with @args, the list of arguments to be passed to the Z-code
sub.  Usually, we just pass the @args to the subroutine we call. However, when
we're restoring, we replace @args with the values that should be in @locv for
the called sub (which we got from the frame). We ignore @args in that case.
Since Z-code subs automatically set @locv to be equal to the input args,
this sets @locv to have the same value as it had when machine state
was saved.

Also note that Quetzal saves only the number of args in a subroutine call, not
their values. So when we're restoring and recursively calling z_call as we
climb the stack, we don't know which @args to pass to those z_call calls. So we
just pass in dummy values. (We need to get the right number of args so that the
call stack is built correctly.)

=cut

1;
