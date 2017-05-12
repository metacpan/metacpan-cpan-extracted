package Finance::Bank::Bankwest::Error::WithResponse;
# ABSTRACT: make exceptions hold an L<HTTP::Response>
$Finance::Bank::Bankwest::Error::WithResponse::VERSION = '1.2.8';

## no critic (RequireUseStrict, RequireUseWarnings, RequireEndWithOne)
use MooseX::Declare;
role Finance::Bank::Bankwest::Error::WithResponse {

    use MooseX::Types; # for "class_type"

    # Allow instantiation via single argument: ->new($http_response).
    class_type 'HTTP::Response';
    with 'MooseX::OneArgNew' => {
        type        => 'HTTP::Response',
        init_arg    => 'response',
    };

    has 'response' => (
        is          => 'ro',
        isa         => 'HTTP::Response',
        required    => 1,
    );
}

__END__

=pod

=for :stopwords Alex Peters

=head1 NAME

Finance::Bank::Bankwest::Error::WithResponse - make exceptions hold an L<HTTP::Response>

=head1 VERSION

This module is part of distribution Finance-Bank-Bankwest v1.2.8.

This distribution's version numbering follows the conventions defined at L<semver.org|http://semver.org/>.

=head1 DESCRIPTION

Exception classes consuming this role provide access to the Bankwest
Online Banking response that triggered the exception.

Catching exceptions of this type allows calling code to log responses
for later analysis if desired.

=head1 ATTRIBUTES

=head2 response

An L<HTTP::Response> object holding the response causing the exception
to be thrown.

=head1 SEE ALSO



=over 4

=item *

L<Finance::Bank::Bankwest::Error::BadResponse>

=item *

L<Finance::Bank::Bankwest::Error::NotLoggedIn::UnknownReason>

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
