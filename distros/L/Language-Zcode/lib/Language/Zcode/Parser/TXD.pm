package Language::Zcode::Parser::TXD;

use strict;
use base qw(Language::Zcode::Parser::Generic);

=head1 Language::Zcode::Parser::TXD

Z-code parser that uses pure Perl to find where the Z subroutines
start and end.

=cut

# Command to use when running txd. In theory, I could get a path for this
use constant TXD_COMMAND => "txd";
# -d dump hex of opcodes and data
# -a will give Inform assembly style:
#     lower case opcodes, no commas between arguments,
#     "local1" instead of L01, label/~label instead of [TRUE|FALSE] label,
#     ^ instead of literal newline -- this last one lets me use while (<>)
# -n print addresses ("a82") instead of labels ("?l0001") for branch ops
# -g doesn't write unneeded lines like 'Action routine for "verbos"'
use constant TXD_OPTIONS => "-dang -w 0";


=head2 find_subs (filename)

Run txd on the given file to create bare (unparsed) LZ::Parser::Routine
objects. (Really to get the address where each subroutine starts.)

=cut

sub find_subs {
    # TODO sub takes a path for txd?
    my ($self, $infile) = @_;
    my $txd_cmd = TXD_COMMAND . " " . TXD_OPTIONS;
    my $TXD = new IO::File "$txd_cmd $infile |" or die "txd error: $!\n";
    # Read in pre-code header information
    $_ = <$TXD> until $_ && /^\[Start of code at/; <$TXD>;

    my @Subs = ();
    my ($rtn); #NOT in while loop; we only know to end a sub as we read the next
    while (<$TXD>) {
	if (/^(Main )?routine ([\da-f]+), (\d+) locals?/i) {
	    my $addr = hex $2; # my $num_locals = $3;
	    # Previous sub, if any, (and any padding 0's) must have ended by now
	    $rtn->end($addr -1) if @Subs; 

	    # Now create the new sub, and read all of its commands
	    $rtn = new Language::Zcode::Parser::Routine ($addr);
	    push @Subs, $rtn;
	    $self->get_txd_commands($rtn, $TXD);

	} elsif (/^\[End of code at ([0-9a-f]+)/) {
	    $rtn->end(hex($1)-1);
	    last; # done reading routines

	} elsif (/^orphan code fragment/) {
	    # Keep putting this code into previous named routine.
	    # IRL, I think this code can NEVER be reached ('jump sp'
	    # is not AFAIK legal) so we could ignore it.
	    $self->get_txd_commands($rtn, $TXD);

	} else {
	    die "Unknown line outside sub: $_";
	}
    }
    close($TXD);

    return @Subs;
}

=head2 get_txd_commands (Routine, filehandle)

Read the commands in a Z-code sub from the given filehandle (which is a pipe
from txd) and add them to the given LZ::Parser::Routine.

OR read commands in an orphan code fragment and add them to the routine's
already existing commands.

=cut

sub get_txd_commands {
    my ($self, $rtn, $fh) = @_;
    my @commands;
    <$fh>; # blank line always proceeds list of commands
    while (<$fh>) {
	last if /^$/; # blank line means done with subroutine or orphan fragment

	# txd -d sometimes runs over into two lines
	chomp, $_ .= <$fh> if /^ *([0-9a-f]+): *(( [a-f\d]{2})+) $/;
	    
	if (/^ *([0-9a-f]+): *(( \.+| [a-f\d]{2})+) +(\w+)\s+(.*)$/) {
	    push @commands, {
		# (I use base 10 for jump/call and labels)
		addr=>hex($1), hexbytes => $2, opcode => $4, args => $5
	    };
	} else {
	    die "Unhandled line in sub: '$_'";
	}
    }

    $rtn->txd_commands($rtn->txd_commands, @commands);
    # As of this moment, last command we read is the last in the sub
    $rtn->last_command_address(($rtn->txd_commands)[-1]->{addr});
    return;
}

1;
