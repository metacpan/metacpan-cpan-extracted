package Devel::OpProf;

=head1 NAME

Devel::OpProf - Profile the internals of a Perl program

=head1 SYNOPSIS

    use Devel::OpProf qw(profile print_stats);
    ...
    profile(1);    # turn on profiling
    ...            # code to be profiled
    profile(0);    # turn off profiling
    ...
    print_stats;   # print out operator statistics

=head1 DESCRIPTION

This module lets perl keep a count of each internal operation in a
program so that you can profile your Perl code. The following
functions are exported.

=over

=item profile(FLAG)

Turns profiling on if FLAG is non-zero, off if FLAG is zero. The
operator profile counts are only incremented whilst profiling is on.

=item stats

Returns a reference to a hash containing the current profile counts.
Each key in the hash is an operator description (e.g. "constant item",
"addition" or "string comparison") and the corresponding value is the
associated count.

=item print_stats

Prints a formatted, sorted list of all operators with non-zero counts
to stdout.

=item zero_stats

Zeroes the profile counts of all operators.

=item op_count

Returns an array of the raw profiling counts (indexed by opcode).
This is mainly for internal use but may be useful for internals
hackers: functions in the Opcode module may be helpful here.

=back

=head1 BUGS

Part of the internal operations involved in statements such as
C<profile(1)> and C<profile(0)> affect the profiling counts themselves.
This should be unimportant if the code being profiled is non-trivial.

=head1 AUTHOR

Malcolm Beattie, mbeattie@sable.ox.ac.uk.

=cut

use Exporter ();
use DynaLoader ();
use Opcode qw(opset_to_ops full_opset opdesc);

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(profile op_count stats print_stats zero_stats);
$VERSION = "0.1";
my @opdescs = opdesc(opset_to_ops(full_opset));

sub stats {
    my @counts = op_count();
    my %stats;
    foreach my $opdesc (@opdescs) {
	$stats{$opdesc} = shift @counts;
    }
    return \%stats;
}

sub print_stats {
    my @counts;
    if (@_) {
	@counts = @_;
    } else {
	@counts = op_count();
    }
    my @indices = sort { $counts[$b] <=> $counts[$a] } 0 .. $#counts;
    foreach my $i (@indices) {
	printf("%-24s %d\n", $opdescs[$i], $counts[$i]) if $counts[$i];
    }
}
    
bootstrap Devel::OpProf $VERSION;

1;
