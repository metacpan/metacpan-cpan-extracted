package Finance::BlockIO;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use WWW::Curl::Simple;
use JSON;
use Exporter 'import';
our @EXPORT_OK = qw(get_new_address
                get_my_addresses
                get_address_by_label
                get_balance
                get_address_balance
                get_address_received
                withdraw
                create_user
                get_users
                get_user_balance
                get_user_address
                get_user_received
                withdraw_from_user
                get_current_price);

=head1 NAME

Finance::BlockIO - Perl wrapper to JSON-based Block.io API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Finance::BlockIO;
    
    my $api_key = "gobbledegook";
    
    my $response = get_new_address($api_key, "foo");

=head1 DESCRIPTION

Finance::BlockIO provides a bare interface to the Block.io JSON-based API,
using WWW::Curl::Simple to make requests and returning a Perl data structure
created from any JSON response received.

You'll probably need an API key (and therefore an account) at Block.io in order
to actually use this.

This documentation is not a replacement for the actual API documentation, which
can be found at L<https://block.io/api/detailed/curl>.

=head1 SUBROUTINES

=cut

sub _fetch_response {
    my ($url) = @_;
    my $curl = WWW::Curl::Simple->new();
    my $json = $curl->get($url);
    return decode_json($json);
}

=head2 get_new_address

    my $response = get_new_address(
                                $api_key,       # REQUIRED
                                $label);        # Optional

Returns a brand new address.  Can optionally specify a label for this address.

=cut

sub get_new_address {
    my ($api_key, $label) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_new_address/?api_key=$api_key";
    $url = $url . "&label=$label" if $label;
    
    return _fetch_response($url);
}

=head2 get_my_addresses

    my $response = get_my_addresses(
                                $api_key);      # REQUIRED

Returns all addresses associated with $api_key.

=cut

sub get_my_addresses {
    my ($api_key) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_my_addresses/?api_key=$api_key";
    
    return _fetch_response($url);
}

=head2 get_address_by_label

    my $response = get_address_by_label(
                                $api_key,       # REQUIRED
                                $label);        # REQUIRED

Returns an address with a label $label associated with $api_key.

=cut

sub get_address_by_label {
    my ($api_key, $label) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($label) {
        carp "No label specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_address_by_label/?api_key=$api_key&label=$label";
    
    return _fetch_response($url);
}

=head2 get_balance

    my $response = get_balance( $api_key);      # REQUIRED

Returns the combined balance of all addresses associated with $api_key.

=cut

sub get_balance {
    my ($api_key) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_balance/?api_key=$api_key";
    
    return _fetch_response($url);
}

=head2 get_address_balance

    my $response = get_balance( $api_key,       # REQUIRED
                                $address,       # REQUIRED unless $label
                                $label);        # REQUIRED unless $address

Returns the balance of an address associated with $api_key, the address being
specified by either $address or $label.

=cut

sub get_address_balance {
    my ($api_key, $address, $label) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($address or $label) {
        carp "No address or label specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_address_balance/?api_key=$api_key";
    $url = $url . "&address=$address" if $address;
    $url = $url . "&label=$label" if $label;
    
    return _fetch_response($url);
}

=head2 get_address_received

    my $response = get_balance( $api_key,       # REQUIRED
                                $address,       # REQUIRED unless $label
                                $label);        # REQUIRED unless $address

Returns the amount received by an address associated with $api_key, the address
being specified by either $address or $label.

=cut

sub get_address_received {
    my ($api_key, $address, $label) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($address or $label) {
        carp "No address or label specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_address_received/?api_key=$api_key";
    $url = $url . "&address=$address" if $address;
    $url = $url . "&label=$label" if $label;
    
    return _fetch_response($url);
}

=head2 withdraw

    my $response = withdraw($api_key,           # REQUIRED
                            $amount,            # REQUIRED
                            $pin,               # REQUIRED
                            $payment_address,   # REQUIRED unless $to_user_ids
                            $to_user_id,        # REQUIRED unless $payment_address
                            $from_user_ids);    # Optional

Requests payment to be sent from the account associated with $api_key to either
an address specified by $payment_address or a Block.io user specified by
$to_user_id, in an amount specified by $amount and (optionally) from user IDs
associated with $api_key specified in a string $from_user_ids.  

=cut

sub withdraw {
    my ($api_key,
        $amount,
        $pin,
        $payment_address,
        $to_user_id,
        $from_user_ids) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($amount) {
        carp "No amount specified!";
        return;
    }
    
    unless ($pin) {
        carp "No PIN specified!";
        return;
    }
    
    unless ($payment_address or $to_user_id) {
        carp "No payment address or user ID specified";
        return;
    }
    
    my $url = "https://block.io/api/v1/withdraw/?api_key=$api_key&amount=$amount&pin=$pin";
    $url = $url . "&payment_address=$payment_address" if $payment_address;
    $url = $url . "&to_user_id=$to_user_id" if $to_user_id;
    $url = $url . "&from_user_ids=$from_user_ids" if $from_user_ids;
    
    return _fetch_response($url);
}

=head2 create_user

    my $response = create_user( $api_key,       # REQUIRED
                                $label);        # Optional

Creates a new user associated with $api_key, optionally with a label specified
by $label.

=cut

sub create_user {
    my ($api_key, $label) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/create_user/?api_key=$api_key";
    $url = $url . "&label=$label" if $label;
    
    return _fetch_response($url);
}

=head2 get_users

    my $response = get_users(   $api_key);      # REQUIRED

Returns a list of users associated with $api_key.

=cut

sub get_users {
    my ($api_key) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_users/?api_key=$api_key";
    
    return _fetch_response($url);
}

=head2 get_user_balance

    my $response = get_user_balance(
                                $api_key,       # REQUIRED
                                $user_id);      # REQUIRED

Get the balance of $user_id associated with $api_key.

=cut

sub get_user_balance {
    my ($api_key, $user_id) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($user_id) {
        carp "No user ID specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_user_balance/?api_key=$api_key&user_id=$user_id";
    
    return _fetch_response($url);
}

=head2 get_user_address

    my $response = get_user_address(
                                $api_key,       # REQUIRED
                                $user_id);      # REQUIRED

Get the address of $user_id associated with $api_key.

=cut

sub get_user_address {
    my ($api_key, $user_id) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($user_id) {
        carp "No user ID specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_user_address/?api_key=$api_key&user_id=$user_id";
    
    return _fetch_response($url);
}

=head2 get_user_received

    my $response = get_user_received(
                                $api_key,       # REQUIRED
                                $user_id);      # REQUIRED

Get the amount received by $user_id associated with $api_key.

=cut

sub get_user_received {
    my ($api_key, $user_id) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    unless ($user_id) {
        carp "No user ID specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_user_received/?api_key=$api_key&user_id=$user_id";
    
    return _fetch_response($url);
}

=head2 withdraw_from_user

See withdraw; as far as I can tell, this is just another name for it.

=cut

sub withdraw_from_user {
    return withdraw(@_);
}

=head2 get_current_price

=cut

sub get_current_price {
    my ($api_key, $price_base) = @_;
    
    unless ($api_key) {
        carp "No API key specified!";
        return;
    }
    
    my $url = "https://block.io/api/v1/get_current_price/?api_key=$api_key";
    $url = $url . "&price_base=$price_base" if $price_base;
    
    return _fetch_response($url);
}

=head1 AUTHOR

Ryan Northrup, C<< <northrup at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-blockio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-BlockIO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::BlockIO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-BlockIO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-BlockIO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-BlockIO>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-BlockIO/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Ryan Northrup.

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

1; # End of Finance::BlockIO
