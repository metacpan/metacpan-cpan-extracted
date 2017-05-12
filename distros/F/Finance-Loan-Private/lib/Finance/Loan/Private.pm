package Finance::Loan::Private;

use warnings;
use strict;
use base qw(Exporter);
use DateTime;
our @EXPORT_OK=qw(premium sorter);

=head1 NAME

Finance::Loan::Private - Private loan under UK tax law.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This script calculates the repayment schedule and tax deductions for a private loan under UK tax law.

Perhaps a little code snippet.

    use Finance::Loan::Private;

    my $foo = Finance::Loan::Private->new();
    ...

=head1 EXPORT

 premium

=head1 SUBROUTINES/METHODS

=head2 premium($principal, $rate, $years)

Calculates a conventional monthly mortgage premium. The calculated figure is slightly too high for our
purposes as it does  not take account of the tax deductions.

=over

=item $principal

The amount of the loan.

=item $rate

The interest rate as a percentage.

=item $years

The period of the loan in years

=item Returns

A monthly premium

=back

=cut

sub premium {
    my $principal= shift;
    my $rate	= shift;
    my $years	= shift;
    my $periods = 12*$years;
    my $r       = $rate/1200.0;
    my $logr1   = log($r+1.0);
    my $mult    = exp($periods*$logr1);
    my $payment = $r*$mult*$principal/($mult-1);
    return $payment;
}


=head2 sorter($list)

Sorts a list of hashrefs each of which contains a 'date' key. The value of the date key is a 
ISO8601 date in the form yyyy-mm-dd.
Used for sorting lists of advances on the loan, changes of tax rate etc.

=over

=item  $list

An arrayref of hashrefs. Each hashref must contain a 'date' key whose value is a ISO8601 date.

=item Returns

A list (not a list ref) of sorted hashref.

=back

=cut

sub sorter {
   my $list	= shift;
   return sort {($a->{date} cmp $b->{date});} @$list;
}

=head1 AUTHOR

Raphael Mankin, C<< <rapmankin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-loan-private at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Loan-Private>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Loan::Private


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Loan-Private>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Loan-Private>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Loan-Private>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Loan-Private/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Raphael Mankin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Finance::Loan::Private
