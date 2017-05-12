package Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason;
# ABSTRACT: general transaction CSV export failure exception
$Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason
    extends Finance::Bank::Bankwest::Error::ExportFailed
    with Finance::Bank::Bankwest::Error::WithResponse
{
    method MESSAGE {
        'the Bankwest Online Banking server declined to export '
            . 'transactions for an unknown reason'
    }

    # The contents of these fields couldn't be determined if this
    # exception is being thrown, so don't enforce their collection.
    has '+params' => ( default => sub { [] } );
    has '+errors' => ( default => sub { [] } );
}

__END__

=pod

=for :stopwords Alex Peters CSV programmatically

=head1 NAME

Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason - general transaction CSV export failure exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception may be thrown on calls to
L<Finance::Bank::Bankwest::Session/transactions> when the Bankwest
Online Banking server declines to action a transaction export request
for a reason that cannot be programmatically determined.

It is also internally thrown when the transaction search form is loaded
for the first time, but then caught since this is an anticipated event.

=head1 ATTRIBUTES

=head2 response

An L<HTTP::Response> object holding the response causing the exception
to be thrown.  May be useful for diagnosing the cause of the problem.

This attribute is made available via
L<Finance::Bank::Bankwest::Error::WithResponse>.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::ExportFailed>

=item *

L<Finance::Bank::Bankwest::Error::WithResponse>

=item *

L<Finance::Bank::Bankwest::Session/transactions>

=back

=head1 AUTHOR

Alex Peters <lxp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
