package MARC::Record::Stats::Report;

use warnings;
use strict;

=head1 NAME

MARC::Record::Stats::Report - report generator for MARC::Record::Stats

=head1 SYNOPSIS

See SYNOPSIS and report method in L<MARC::Record::Stats>

=head1 METHODS

=head2 report $fh, $stats, $config?

Prints out to a filehandle $fh a report on statistics
collected in $stats (L<MARC::Record::Stats>),
using options from $config, which is a HASHREF with keys:

=over

=item dots => [undef|0|1]

Replace spaces with dots if dots => 1 for readability. Table will look like:

	955..............86.67
	...a.............86.67
	...e.............20.00
	...t.............46.67

=back 

=cut

sub report{
	my ($self, $FH, $stats, $config) = @_;
	
	my $hash = $stats->get_stats_hash;
	
	my @lines;
	my $nrecords = $hash->{nrecords};
	
	foreach my $tag ( sort keys %{$hash->{tags}} ) {
		my $tagstat = $hash->{tags}->{$tag};
		my $is_repeatable = $tagstat->{repeatable} ? '[Y]' : '   ';
		my $occurence = sprintf("%6.2f",100*$tagstat->{occurence}/$nrecords);
		push @lines, "$tag     $is_repeatable     $occurence";
		
		foreach my $subtag ( sort keys %{ $tagstat->{subtags} } ) {
			my $subtagstat = $tagstat->{subtags}->{$subtag};
			my $occurence = sprintf("%6.2f",100.0*$subtagstat->{occurence}/$nrecords);
			my $is_repeatable = $tagstat->{repeatable} ? '[Y]' : '   ';
			push @lines, "   $subtag    $is_repeatable     $occurence";
		}
		 
	}
	
	if ( $config->{'dots'} ) {		
		@lines = map { s/\s/./g; $_ } @lines;
	}
	
	unshift @lines, "Tag     Rep.    Occ.,%";
	unshift @lines, "Statistics for $nrecords records";
	
	
	
	print $FH join ("\n",@lines), qq{\n\n};
	
}


=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/marc-record-stats at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/MARC-Record-Stats>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MARC::Record::Stats::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/MARC-Record-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/MARC-Record-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/MARC-Record-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/MARC-Record-Stats/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MARC::Record::Stats::Report
