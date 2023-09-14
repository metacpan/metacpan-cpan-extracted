package FixerIO::API;

use 5.006;
use strict;
use warnings;
use HTTP::Tiny;
use JSON 'decode_json';
use Carp;

=head1 NAME

FixerIO::API - Access to the fixer.io currency exchange rate API.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use FixerIO::API;

    my $access_key = <your-key-here>;
    my $fixer = FixerIO::API->new( $access_key );

    # get latest data
    my $ld = $fixer->latest;

    use DDP hash_max=>5;
    p $ld, as=>"Latest Data:";

    Will print,
    Latest Data:
    {
        success     1 (JSON::PP::Boolean),
        base        "EUR",
        date        "2023-09-03" (dualvar: 2023),
        timestamp   1693764783,
        rates       {
            AED   3.965325,
            AFN   79.575894,
            ALL   108.330797,
            AMD   418.325847,
            ANG   1.954454,
            (...skipping 165 keys...)
        }
    }

=head1 DESCRIPTION

This is a Perl module for accessing the API provided by fixer.io.  See, F<"http://fixer.io/documentation">.

This module doesn't export anything. Nor does it keep any data, other than your API access key. Your script will keep or do what it wants with the data.

You have to obtain your own API key from the fixer.io web site. There is a free option.

=head1 IMPLEMENTED ENDPOINTS

Please note that depending on your subscription plan, certain API endpoints may not be available.

=head2 LATEST RATES

Returns real-time exchange rate data for all available or a specific set of currencies.

Specifying symbols is not implemented. Changing the base is not implemented. The etags optimization is not implemented.

=head1 EXPORT

No exports.

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new API access object. Pass in your API access key as an argument.

=cut

sub new {
    my $class = shift;
    my $access_key = shift;
    return undef unless defined $access_key;
    return bless \$access_key, $class;
}

=head2 api_call

Perform the HTTP(S) request, return the response data.

=cut

sub api_call {
    my ($self, $options, $defaults) = @_;
    my $ua = HTTP::Tiny->new(
	    agent => sprintf '%s/%s ', 'FixerIO-API', $VERSION
    );
    my %options = (
        %{$defaults},
        %{$options},
    );
    my $url = "http://data.fixer.io/api/latest?access_key=$$self";
    while (my ($k, $v) = each %options) {
        $url .= sprintf '&%s=%s', $k, $v; # values always have no spaces
    }
    my $resp = $ua->get($url);
    return $resp->{'content'} if $resp->{'success'};

    #TODO: Handle HTTP exceptions
    croak 'HTTP Error!? How can that be?';
}

=head2 latest

Return the latest data.

=cut

sub latest {
    my ($self, %options) = @_;
    my $defaults = {format => 1};
    my $json = $self->api_call( \%options, $defaults );
    my $data = decode_json( $json );# could die
    return $data;
}

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 AUTHOR

Harry Wozniak, C<< <woznotwoz at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fixerio-api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=FixerIO-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FixerIO::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=FixerIO-API>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/FixerIO-API>

=item * Search CPAN

L<https://metacpan.org/release/FixerIO-API>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Harry Wozniak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

'That is all.';
