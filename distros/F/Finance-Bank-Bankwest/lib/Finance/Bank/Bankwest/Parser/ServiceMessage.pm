package Finance::Bank::Bankwest::Parser::ServiceMessage;
# ABSTRACT: Online Banking service message web page parser
$Finance::Bank::Bankwest::Parser::ServiceMessage::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
use HTTP::Response::Switch::Handler 1.000000;
class Finance::Bank::Bankwest::Parser::ServiceMessage
    with HTTP::Response::Switch::Handler
{
    use Finance::Bank::Bankwest::Error::ServiceMessage ();
    use Web::Scraper qw{ scraper process };

    my $scraper = scraper {
        process '#divInterceptContent', 'div' => sub { 1 };
        process '#btnStartBanking', 'button' => sub { 1 };
    };
    method handle {
        my $s = $scraper->scrape( $self->response );
        $self->decline if not $s->{'div'} or not $s->{'button'};
        Finance::Bank::Bankwest::Error::ServiceMessage
            ->throw( $self->response );
    }
}

__END__

=pod

=for :stopwords Alex Peters dismissible

=head1 NAME

Finance::Bank::Bankwest::Parser::ServiceMessage - Online Banking service message web page parser

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

This module holds the logic for identifying an L<HTTP::Response> object
as a dismissible "service message" page occasionally served by Bankwest
Online Banking after login occurs.

This module always throws a
L<Finance::Bank::Bankwest::Error::ServiceMessage> exception on
detection of such a page rather than returning anything.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::ServiceMessage>

=item *

L<Finance::Bank::Bankwest::SessionFromLogin>

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
