# $Id: Action.pm,v 1.5 2006-11-04 10:11:11 mike Exp $

# Action.pm - an action in a Scott Adams game.

package Games::ScottAdams::Action;
use strict;


sub new {
    my $class = shift();
    my($verb, $noun, $num) = @_;

    return bless {
	verb => $verb,
	noun => $noun,
	num => $num,		# 0-based index into Game's list of actions
				### I don't think we actually use this
	comment => undef,	# optional comment to be written through
	cond => [],		# array of conditions to be satisfied
	res => [],		# array of results to be executed
    }, $class;
}


sub verb {
    my $this = shift();
    return $this->{verb};
}

sub noun {
    my $this = shift();
    return $this->{noun};
}

sub comment {
    my $this = shift();
    my($name) = @_;

    my $old = $this->{comment};
    if (defined $name) {
	$this->{comment} = $name;
    }
    return $old;
}


# We'd like to compile these up front so we can complain about
# unrecognised condition and actions while we still know where we are
# in the source file.  Unfortunately, we can't do it in general as the
# action may refer to the names of rooms or items that have not yet
# been defined.  So all we can do at this stage is remember them for
# later.
#
sub add_cond {
    my $this = shift();
    my($text) = @_;

    push @{ $this->{cond} }, $text;
}


sub add_result {
    my $this = shift();
    my($text) = @_;

    push @{ $this->{res} }, $text;
}


# PRIVATE to the compile() method.
sub ARG_NONE { 0 }		# no argument
sub ARG_NUM { 1 }		# argument specifies a flag
sub ARG_ROOM { 2 }		# argument identifies a room
sub ARG_ITEM { 3 }		# argument identifies an item
sub ARG_ITEMROOM { 4 }		# arguments identify an item and a room
sub ARG_ITEMITEM { 5 }		# arguments identify two items

use vars qw(%_cond %_res);	# Global as they need to be visible to "sad"
%_cond = (
	     carried =>		[ 1, ARG_ITEM ],
	     here =>		[ 2, ARG_ITEM ],
	     accessible =>	[ 3, ARG_ITEM ],
	     at =>		[ 4, ARG_ROOM ],
	     '!here' =>		[ 5, ARG_ITEM ],
	     '!carried' =>	[ 6, ARG_ITEM ],
	     '!at' =>		[ 7, ARG_ROOM ],
	     flag =>		[ 8, ARG_NUM ],
	     '!flag' =>		[ 9, ARG_NUM ],
	     loaded =>		[ 10, ARG_NONE ],
	     '!loaded' =>	[ 11, ARG_NONE ],
	     '!accessible' =>	[ 12, ARG_ITEM ],
	     exists =>		[ 13, ARG_ITEM ],
	     '!exists' =>	[ 14, ARG_ITEM ],
	     counter_le =>	[ 15, ARG_NUM ],
#	     counter_ge =>	[ 16, ARG_NUM ],
	     counter_gt =>	[ 16, ARG_NUM ],
		#   ###	The documentation accompanying the scottfree
		#	interpreter says that condition 16 tests for
		#	current counter's value greater than or equal
		#	to the argument, but inspection of the source
		#	shows that it actually tests for strictly
		#	greater-than.
	     '!moved' =>	[ 17, ARG_ITEM ],
	     moved =>		[ 18, ARG_ITEM ],
	     counter_eq =>	[ 19, ARG_NUM ],
	     );

%_res = (
	    get =>		[ 52, ARG_ITEM ],
	    drop =>		[ 53, ARG_ITEM ],
	    moveto =>		[ 54, ARG_ROOM ],
	    destroy =>		[ 55, ARG_ITEM ],
	    set_dark =>		[ 56, ARG_NONE ],
	    clear_dark =>	[ 57, ARG_NONE ],
	    set_flag =>		[ 58, ARG_NUM ],
	    destroy2 =>		[ 59, ARG_ITEM ],
		# Same as 55 in ScottFree
	    clear_flag =>	[ 60, ARG_NUM ],
	    die =>		[ 61, ARG_NONE ],
	    put =>		[ 62, ARG_ITEMROOM ],
	    game_over =>	[ 63, ARG_NONE ],
	    look =>		[ 64, ARG_NONE ],
	    score =>		[ 65, ARG_NONE ],
	    inventory =>	[ 66, ARG_NONE ],
	    set_0 =>		[ 67, ARG_NONE ],
	    clear_0 =>		[ 68, ARG_NONE ],
	    refill_lamp =>	[ 69, ARG_NONE ],		### UNTESTED
	    clear_screen =>	[ 70, ARG_NONE ],		### UNTESTED
	    save_game =>	[ 71, ARG_NONE ],
	    swap =>		[ 72, ARG_ITEMITEM ],
	    continue =>		[ 73, ARG_NONE ],		### UNTESTED
		# Automatic -- is there ever any need to use it explicitly?
	    superget =>		[ 74, ARG_ITEM ],		### UNTESTED
	    put_with =>		[ 75, ARG_ITEMITEM ],
	    look2 =>		[ 76, ARG_NONE ],		### UNTESTED
		# Same as 64 in ScottFree
	    decrease_counter =>	[ 77, ARG_NONE ],
	    print_counter =>	[ 78, ARG_NONE ],
	    set_counter =>	[ 79, ARG_NUM ],
	    swap_loc_default =>	[ 80, ARG_NONE ],
	    select_counter =>	[ 81, ARG_NUM ],		### UNTESTED
		# Current counter is swapped with specified backup counter
	    add_counter =>	[ 82, ARG_NUM ],		### UNTESTED
	    subtract_counter =>	[ 83, ARG_NUM ],		### UNTESTED
	    print_noun =>	[ 84, ARG_NONE ],
	    print_noun_nl =>	[ 85, ARG_NONE ],
	    nl =>		[ 86, ARG_NONE ],
	    swap_loc =>		[ 87, ARG_NUM ],
	    pause =>		[ 88, ARG_NONE ],
	    special =>		[ 89, ARG_NUM ],
		# This is special -- see ../../../../scottfree/Definition
	    );


sub compile {
    my $this = shift();
    my($game) = @_;

    my $verb = $game->resolve_verb($this->verb());
    my $noun = $this->noun();
    if ($verb == 0) {
	# This is a %occur, so the noun is a percentage probability
	$noun = 100 if !$noun;
    } else {
	$noun = $game->resolve_noun($noun);
    }

    my @condval = ( 150*$verb + $noun );
    foreach my $cond (@{ $this->{cond} }) {
	my($opcode, $arg) = _lookup($game, $cond, 'condition', \%_cond);
	$arg = 0 if !defined $arg;
	push @condval, $opcode + 20*$arg;
    }

    die "Oops!  SA format doesn't support >5 conditions in an action"
	if @condval > 6;

    # Now gather results, with parameters going on the end of @condval
    #warn "handling results:\n" . join ('', map {"\t$_\n"}
    #				       @{ $this->{res} });
    my @resval;
    foreach my $res (@{ $this->{res} }) {
	my($opcode, @arg) = _lookup($game, $res, 'result', \%_res);
	push @resval, [ $opcode, @arg ];
    }

    # Right.  This is slightly tricky.  We now want to pack all the
    # results, together with their parameters, into as few action
    # octuplets as possible.  We have four result slots available in
    # the first one, together with zero or more parameter slots
    # remaining in the condition area; thereafter, each action
    # octuplet offers four more result slots together with five
    # parameter slots in the condition area (which of course is one
    # more than we'll ever need.)
    my @conds;			# list of completed octuplets
    my $argslot = @condval;	# 0-based index within current octuplet
    my $resslot = 0;		# 0-based index into "virtual array"
    push @condval, map { 0 } 1..(8-@condval);

    for (my $i = 0; $i < @resval; $i++) {
	my $res = $resval[$i];
	my($opcode, @arg) = @$res;
	@arg = grep { defined } @arg;

	### Seems like 6 in next line should be 5.  Think harder.
	if ($argslot + @arg > 6 || $resslot == 4 ||
	    ($resslot == 3 && $i < @resval-1)) {
	    # Current octuplet is full: skip to next
	    my $cindex = 6 + int($resslot/2);
	    $condval[$cindex] +=
		($resslot % 2 == 0 ? 150 : 1) * 73;
	    push @conds, join(' ', @condval);
	    @condval = map { 0 } 1..8;
	    $argslot = 1;	# because slot 0 holds verb & noun
	    $resslot = 0;
	}

	my $cindex = 6 + int($resslot/2);
	$condval[$cindex] +=
	    ($resslot % 2 == 0 ? 150 : 1) * $opcode;
	$resslot++;
	foreach my $arg (@arg) {
	    if (!defined $arg) {
		print STDERR "", "arg in '@arg' (", scalar(@arg), ") undef\n";
	    }
	    $condval[$argslot] = 20*$arg;
	    $argslot++;
	}
    }

    push @conds, join(' ', @condval);
#print STDERR "", "returning conds: ", join(' -- ', @conds), "\n";
    return @conds;
}


sub _lookup {
    my($game, $text, $caption, $href) = @_;

    $text =~ s/^\s+//;
    my($op, $arg) = split /\s+/, $text, 2;
    if ($op eq 'msg') {
	# This check is a hack, but does spot an otherwise subtle bug
	die "Oops!  `msg' used as a condition (missing %result line?)"
	    if $caption eq 'condition';

	my $mnum = $game->resolve_message($arg);
	return ($mnum <= 51 ? $mnum : $mnum+50);
    }

    my $ref = $href->{$op};
    die "unrecognised $caption op '$op'"
	if !defined $ref;

    my($opcode, $argtype) = @$ref;
    if ($argtype == ARG_NONE) {
	return ($opcode);
    } elsif ($argtype == ARG_NUM) {
	# Numeric argument already has the right numeric value.
    } elsif ($argtype == ARG_ROOM) {
	$arg = $game->resolve_room($arg, 'action');
    } elsif ($argtype == ARG_ITEM) {
	$arg = $game->resolve_item($arg, 'action');
    } elsif ($argtype == ARG_ITEMROOM) {
	my($arg1, $arg2) = split /\s+/, $arg, 2;
	$arg1 = $game->resolve_item($arg1, 'action');
	$arg2 = $game->resolve_room($arg2, 'action');
	return ($opcode, $arg1, $arg2);
    } elsif ($argtype == ARG_ITEMITEM) {
	my($arg1, $arg2) = split /\s+/, $arg, 2;
	$arg1 = $game->resolve_item($arg1, 'action');
	$arg2 = $game->resolve_item($arg2, 'action');
	return ($opcode, $arg1, $arg2);
    } else {
	die "unsupported argument type $argtype for op '$op'";
    }

    return ($opcode, $arg);
}


1;
