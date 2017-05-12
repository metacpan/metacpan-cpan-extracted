package Finance::Bank::Bankwest::Error::ExportFailed;
# ABSTRACT: transaction CSV export failure exception
$Finance::Bank::Bankwest::Error::ExportFailed::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
class Finance::Bank::Bankwest::Error::ExportFailed
    extends Finance::Bank::Bankwest::Error
{
    method MESSAGE {
        return sprintf(
            "%s %s [%s], %s\n%s",
            'the Bankwest Online Banking server rejected transaction',
            'parameter/s',
            join(q{, }, $self->params),
            'giving the following reason/s:',
            join("\n", map { qq{  * $_} } $self->errors),
        );
    }


    has 'params' => (
        isa         => 'ArrayRef[Str]',
        traits      => [qw{ Array }],
        handles     => { 'params' => 'elements' },
        required    => 1,
    );


    has 'errors' => (
        isa         => 'ArrayRef[Str]',
        traits      => [qw{ Array }],
        handles     => { 'errors' => 'elements' },
        required    => 1,
    );
}

__END__

=pod

=for :stopwords Alex Peters CSV params

=head1 NAME

Finance::Bank::Bankwest::Error::ExportFailed - transaction CSV export failure exception

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This exception is thrown when the Bankwest Online Banking server
rejects the information supplied to
L<Finance::Bank::Bankwest::Session/transactions>.

In cases where the reason for failure cannot be determined, a
L<Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason>
exception is thrown instead.

=head1 ATTRIBUTES

=head2 params

A list of the parameters passed to
L<Finance::Bank::Bankwest::Session/transactions> that the Bankwest
Online Banking server rejected.  The reason/s for rejection can be
determined by inspecting the L</errors> list.

=head2 errors

A list of error messages returned by Bankwest Online Banking as to why
the transaction export failed.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error>

=item *

L<Finance::Bank::Bankwest::Error::ExportFailed::UnknownReason>

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
