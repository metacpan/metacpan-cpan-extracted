package Filter::Undent;

use 5.006;

use Exporter;
push @ISA, 'Exporter';
@EXPORT = qw(undent);

use strict;
use warnings;
use Filter::Simple;

=head1 NAME

Filter::Undent - Un-indent heredoc strings automatically

=cut

our $VERSION = '1.0.3';

=head1 SYNOPSIS

Don't you wish heredocs could align with your docs?  Now they can!

	use Filter::Undent;
	print <<'EOF'
		What is printed is magically undented to the level of the
		first line of the heredoc.

			Only these lines will be indented in the output, since they
			are indented relative to the first line
	EOF

If you want to disable the unindent of the heredocs, simply:

	no Filter::Undent;

=cut

FILTER_ONLY
    quotelike => sub {s{^<<}{undent <<}gs},
    all       => sub {
        return unless $Filter::Undent::DEBUG;
        print STDERR join '', map {"Filter::Undent> $_\n"} split /\n/, $_;
    },
;

=head1 EXPORTED FUNCTIONS

=head2 undent

This function does the actual work of unindenting.  It returns the modified
version of the input string, ignoring any leading newlines, and if the first
line of the provided string is indented with space or tab characters, it will 
remove the same whitespace from the beginning of all of the subsequent lines
in the output.  Any lines which are outdented from the first line, or is using
a different combination of spaces or tabs will not have its leading space
removed.

=cut

sub undent ($) {
    no warnings 'uninitialized';
    if ( $_[0] =~ m/^(\r?\n)*([ \t]+)/ ) {
        my $i = $2;
        return join '', map { s/^\Q$i\E/$1/g; $_ } grep { $_ ne '' }
            split /(.*?\n)/, $_[0];
    }
    return $_[0];
}

=head1 AUTHOR

Anthony Kilna, C<< <anthony at kilna.com> >> - L<http://anthony.kilna.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-filter-undent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-Undent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filter::Undent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filter-Undent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filter-Undent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filter-Undent>

=item * Search CPAN

L<http://search.cpan.org/dist/Filter-Undent/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Kilna Companies.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Filter::Undent
