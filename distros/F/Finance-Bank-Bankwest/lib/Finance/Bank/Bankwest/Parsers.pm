package Finance::Bank::Bankwest::Parsers;
# ABSTRACT: feed HTTP responses to multiple parsers in succession
$Finance::Bank::Bankwest::Parsers::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireFinalReturn)
use MooseX::Declare;
use HTTP::Response::Switch 1.001000; # for exception class loading
class Finance::Bank::Bankwest::Parsers
    with HTTP::Response::Switch
{
    sub handler_namespace   { 'Finance::Bank::Bankwest::Parser' }
    sub default_handlers    { qw( Login ) }
    sub default_exception   { 'Finance::Bank::Bankwest::Error::BadResponse' }
}

__PACKAGE__->load_handlers;
1;

__END__

=pod

=for :stopwords Alex Peters parsers

=head1 NAME

Finance::Bank::Bankwest::Parsers - feed HTTP responses to multiple parsers in succession

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This module provides a convenient means to apply several classes in the
C<Finance::Bank::Bankwest::Parser> namespace to an L<HTTP::Response> at
once in order to receive structured data from it, or have the most
appropriate exception thrown.

=for Pod::Coverage handler_namespace default_handlers default_exception

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::BadResponse>

=item *

L<Finance::Bank::Bankwest::Session>

=item *

L<Finance::Bank::Bankwest::SessionFromLogin>

=item *

L<HTTP::Response::Switch>

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
