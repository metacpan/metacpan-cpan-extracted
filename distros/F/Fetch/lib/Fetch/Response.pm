package Fetch::Response;

use strict;
use warnings;

our $VERSION = '0.06';

require Fetch;

1;

__END__

=head1 NAME

Fetch::Response - an HTTP response from L<Fetch>

=head1 SYNOPSIS

    my $res = $ua->get($url)->get;
    if ($res->is_success) {
        print $res->status, "\n";
        print $res->header('Content-Type'), "\n";
        print $res->content;
    }

=head1 METHODS

=head2 status

The numeric HTTP status code.

=head2 headers

The response headers as a L<Fetch::Headers> object, in the order received. It
is itself a blessed C<[ key, value, key, value, ... ]> arrayref, so older code
that dereferenced C<< @{$res->headers} >> still works, while C<get>/C<get_all>
give case-insensitive and multi-valued access (C<get_all('set-cookie')>).

=head2 header($name)

The value of a single header, matched case-insensitively (first occurrence).

=head2 content

The response body as bytes.

=head2 json

    my $data = $res->json;

Decode the response body as JSON into a Perl data structure. C<true>/C<false>
become L<JSON::PP::Boolean> values and C<null> becomes C<undef>. Dies if the
body is not valid JSON. Uses L<Cpanel::JSON::XS> when installed, falling back to
core L<JSON::PP>.

=head2 is_success / is_redirect

True for 2xx / 3xx status codes respectively.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
