package Finance::Dogechain::Base;
$Finance::Dogechain::Base::VERSION = '1.20210605.1754';
use Mojo::Base -base, -signatures;
use Mojo::UserAgent;
use Net::SSLeay;

has 'ua'       => sub { Mojo::UserAgent->new->max_redirects(3) };
has 'base_url' => sub { 'https://dogechain.info/api/v1' };

sub return_field_if_success($self, $url_path, $field) {
    my $res = $self->ua->get( $self->base_url . $url_path )->result;

    if ($res->is_success) {
        my $json = $res->json;
        return $json->{$field} if $json->{success};
        return 0;
    }

    return;
}

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogechain::Base - base class for all Finance::Dogechain classes

=head1 SYNOPSIS

    use Mojo::Base -base, -signatures, 'Finance::Dogechain::Base';

    # your methods here

=head1 DESCRIPTION

C<Finance::Dogechain::Base> is a base class for all Finance::Dogechain classes.
You should not use it directly; inherit from it.

=head1 METHODS

This module provides several methods.

=head2 new( ua => ..., base_url => ... )

Creates a new instance of this object. Default values are:

=over 4

=item * C<ua>, a user agent. Defaults to an instance of L<Mojo::UserAgent>.

=item * C<base_url>, the base URL path of the dogechain.info API (or an equivalent).

=back

These attributes are available by instance methods C<ua()> and C<base_url()>.

=head2 return_field_if_success($url_path, $field)

Given a URL path, suffixed to the C<base_url> provided in the constructor,
calls the API. If the result is successful, extracts and returns the JSON data
structure in the returned JSON payload at the top-level field provided in
C<$field>.

Returns an undefined value (C<undef> in scalar context or an empty list in list
context) if the HTTP call did not succeed.

Returns C<0> if the HTTP call did succeed but the API returned an unsuccessful payload.

=head1 COPYRIGHT & LICENSE

Copyright 2021 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.32.

=cut
