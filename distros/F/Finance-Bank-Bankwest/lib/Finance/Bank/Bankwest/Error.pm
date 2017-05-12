package Finance::Bank::Bankwest::Error;
# ABSTRACT: Finance-Bank-Bankwest error superclass
$Finance::Bank::Bankwest::Error::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
use Throwable::Error 0.101110; # for bug fix
class Finance::Bank::Bankwest::Error
    extends Throwable::Error
{
    use MooseX::StrictConstructor; # no exports


    has '+message' => (
        builder => 'MESSAGE',
        lazy    => 1,
    );
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error - Finance-Bank-Bankwest error superclass

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

All exceptions thrown by the Finance-Bank-Bankwest distribution are
parented by this class.  It allows the user to easily identify an error
as belonging to this distribution without caring about specifics:

    use TryCatch; # for "try" and "catch"
    try {
        $session->logout;
    }
    catch (Finance::Bank::Bankwest::Error $e) {
        warn "logout failed, but don't care";
    }

=head1 METHODS

=head2 MESSAGE

Defined in subclasses that are directly instantiated, and called if the
exception is being stringified.  Prepares and returns a textual
representation of the error message, accessible via the C<message>
attribute (see L<Throwable::Error/message>).

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::BadResponse>

=item *

L<Finance::Bank::Bankwest::Error::ExportFailed>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn>

=item *

L<Throwable::Error>

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
