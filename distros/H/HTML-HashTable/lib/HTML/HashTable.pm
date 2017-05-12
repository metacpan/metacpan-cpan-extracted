
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::HashTable ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.


$VERSION = $VERSION = 0.60;

require 5.005;

package HTML::HashTable;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(tablify);

use strict;

=head1 NAME

C<HTML::HashTable> - Create an HTML table from a Perl hash

=head1 SYNOPSIS

    use HTML::HashTable;
    print tablify({
        BORDER      => 0, 
	DATA        => $myhashref, 
	SORTBY      => 'key', 
	ORDER       => 'desc'}
    );

=head1 DESCRIPTION

This module takes an arbitrary Perl hash and presents it as an HTML
table.  The hash can contain anything you want -- scalar data, 
arrayrefs, hashrefs, whatever.  Yes, this means you can use a tied
hash if you wish.

The HTML produced is nicely formatted and indented, suitable for
human editing and manipulation.

Some options are provided with the tablify() function to allow you
to specify whether you wish to have a border or not, and whether you
wish your table to be sorted by key or value (but note that sorting
by value gives almost meaningless results if your values are 
references, as in a deeply nested Perl data structure.)

The options given to the tablify() function are:

=item C<BORDER>

True or false depending on whether you want your table to have a
border.  Defaults to true (1).

=item C<DATA>

Reference to your hash

=item C<SORTBY>

Either 'key' or 'value' depending on how you want your data sorted.
Note that sorting by value is more or less meaningless if your
values are references (as in a deeply nested data structure).  Defaults
to "key".

=item C<ORDER>

Either 'asc' or 'desc' depending on whether you want your sorting to
be in ascending or descending order.  Defaults to "asc".

=cut

sub tablify {
	$HTML::HashTable::output = '';
	$HTML::HashTable::depth = 0;
	my $tsref = shift;
        $tsref->{SORTBY} ||= "key";
        $tsref->{ORDER}  ||= "asc";
        $tsref->{BORDER} = 1 unless (defined $tsref->{BORDER});
	make_table($tsref);
	return $HTML::HashTable::output;
}

#
# This subroutine does most of the work by recursing through the
# hash supplied.  We look to see whether the value of any hash
# item is a scalar, an arrayref or a hashref, and act accordingly.
# Recursion's so rare in Perl... this is *fun*
#

sub recurse_through {
	my $tsref = shift;
	my $thingy = shift;
	if (ref($thingy) eq 'ARRAY') {
		foreach (@$thingy) {
			recurse_through($tsref, $_);
		}
	} elsif (ref($thingy) eq 'HASH') {
		my $newref = {%$tsref};
		$newref->{DATA} = $thingy;
		open_cell();
		make_table($newref);
		close_cell($HTML::HashTable::depth);
	} else {	# plain old scalar data
		open_cell();
		$HTML::HashTable::output .= $thingy;
		close_cell(0);
	}
}

sub open_table {
	my $tsref = shift;
	$HTML::HashTable::output .= "\n";
	$HTML::HashTable::output .= "\t" x $HTML::HashTable::depth;
	$HTML::HashTable::output .= $tsref->{BORDER} ? "<table border=1>\n" : "<table border=0>\n";
}

sub close_table {
	$HTML::HashTable::output .= "\t" x $HTML::HashTable::depth;
	$HTML::HashTable::output .= "</table>\n";
}

sub open_row {
	$HTML::HashTable::output .= "\t" x ($HTML::HashTable::depth);
	$HTML::HashTable::output .= "<tr>\n";
	$HTML::HashTable::depth++;
}

sub close_row {
	$HTML::HashTable::depth--;
	$HTML::HashTable::output .= "\t" x ($HTML::HashTable::depth);
	$HTML::HashTable::output .= "</tr>\n";
}

sub open_cell {
	$HTML::HashTable::output .= "\t" x ($HTML::HashTable::depth);
	$HTML::HashTable::output .= "<td>";
	$HTML::HashTable::depth++;
}

sub close_cell {
	my $d = shift;
	$d-- if $d;
	$HTML::HashTable::output .= "\t" x ($d);
	$HTML::HashTable::output .= "</td>\n";
	$HTML::HashTable::depth--;
}
	
sub make_table {
	my $tsref = shift;
	open_table($tsref);
	foreach my $key (sort { 
		if ($tsref->{SORTBY} eq "value") {
			if ($tsref->{ORDER} eq 'asc') {
				${$tsref->{DATA}}{$a} cmp ${$tsref->{DATA}}{$b};
			} else { 
				${$tsref->{DATA}}{$b} cmp ${$tsref->{DATA}}{$a};
			}
		} else {
			if ($tsref->{ORDER} eq 'asc') {
				$a cmp $b;
			} else {
				$b cmp $a;
			}
		}
	} keys %{$tsref->{DATA}}) {
		open_row;
		open_cell;
		$HTML::HashTable::output .= $key;
		close_cell(0);
		recurse_through($tsref, ${$tsref->{DATA}}{$key});
		close_row;
	}
	close_table;
}	




=head1 AUTHOR

Kirrily "Skud" Robert <skud@cpan.org>

=head1 SEE ALSO

L<perl>.

=cut
