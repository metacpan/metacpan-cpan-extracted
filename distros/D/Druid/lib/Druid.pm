package Druid;


use Moo;
use JSON::MaybeXS qw(encode_json decode_json);
use LWP::UserAgent;
use HTTP::Request;
use Druid::Util qw(iso8601_yyyy_mm_dd_hh_mm_ss);

our $VERSION = '0.003';

has 'api_url' => (
    'is' => 'ro',
);

has 'ua' => (
    'is'      => 'ro',
    'default' => sub {
        my $self = shift;
        my $ua   = LWP::UserAgent->new();
        $ua->ssl_opts( 'verify_hostname' => 0 );
        return $ua;
    },
);

has 'req' => (
    'is'      => 'ro',
    'lazy'    => 1,
    'default' => sub {
        my $self = shift;
        my $req  = HTTP::Request->new( 'POST' => $self->api_url );
        $req->header( 'Content-Type' => 'application/json' );
        return $req;
    },
);

sub send {
    my $self = shift;
    my $query = shift;

    $self->{error} = undef;

    my $response;
    my $request_hash = $query->gen_query;
    $self->req->content( encode_json( $request_hash ) );

    my $res = $self->ua->request( $self->req );
    if ($res->is_success) {
        eval {
            $response = decode_json($res->content) if $res->content ne "";
            $_->{'timestamp'} = iso8601_yyyy_mm_dd_hh_mm_ss( $_->{'timestamp'} )
                for @{$response};
            1;
        } or do {
            $self->handle_error("500", "Parsing of the reponse failed");
            warn "error: $@";
        }
    }else{
        $self->handle_error($res->code, $res->message, $res->content);
    }
    return $response;
}

sub handle_error {
    my $self = shift;
    my ($code, $message, $content) = @_;

    $self->{error} = {
        "code"      => $code,
        "message"   => $message,
        "content"   => $content
    };

}

1;

__END__

=head1 NAME

Druid - The great new perl client for Druid!

=head1 VERSION

Version 0.003

=cut


our $VERSION = '0.003';
	
=head1 AUTHOR

Gaurav Kohli, C<< <gaurav.in at gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Gaurav Kohli.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Druid
