package Finance::Bank::Bankwest::Parser::TransactionExport;
# ABSTRACT: transaction CSV export parser
$Finance::Bank::Bankwest::Parser::TransactionExport::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
use HTTP::Response::Switch::Handler 1.000000;
class Finance::Bank::Bankwest::Parser::TransactionExport
    with HTTP::Response::Switch::Handler
{
    use Finance::Bank::Bankwest::Transaction ();
    use IO::String ();
    use Text::CSV_XS 0.66 (); # for "empty_is_undef" attribute

    method handle {
        $self->decline
            if $self->response->headers->content_type ne 'text/csv';

        my $io = IO::String->new( $self->response->content_ref );
        my $csv = Text::CSV_XS->new({
            auto_diag       => 2,
            empty_is_undef  => 1,
        });
        $csv->column_names( $csv->getline($io) );

        my @txns;
        while (my $row = $csv->getline_hr($io)) {
            my $amount;
            for (qw{ Credit Debit }) {
                next if not defined $row->{$_};
                $amount = $row->{$_};
                undef $amount if $amount == 0;
            }
            push @txns, Finance::Bank::Bankwest::Transaction->new(
                date        => $row->{'Transaction Date'},
                narrative   => $row->{'Narration'},
                cheque_num  => $row->{'Cheque Number'},
                amount      => $amount,
                type        => $row->{'Transaction Type'},
            );
        }
        return @txns;
    }
}

__END__

=pod

=for :stopwords Alex Peters CSV

=head1 NAME

Finance::Bank::Bankwest::Parser::TransactionExport - transaction CSV export parser

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This module holds the logic for identifying an L<HTTP::Response> object
as a Bankwest Online Banking transaction CSV export, and extracting the
details of each transaction from it as
L<Finance::Bank::Bankwest::Transaction> objects.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Transaction>

=item *

L<HTTP::Response::Switch::Handler>

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
