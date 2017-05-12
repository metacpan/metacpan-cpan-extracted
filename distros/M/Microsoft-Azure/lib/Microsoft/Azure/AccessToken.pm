package Microsoft::Azure::AccessToken;

use 5.006;
use strict;
use warnings FATAL => 'all';

use LWP::UserAgent;
use URL::Encode 'url_encode';
use Data::Dumper;
use JSON;

=head1 NAME

Microsoft::Azure::AccessToken - Microsoft Azure Access Token implementation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use constant TOKENAUTH_URL => 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13';


=head1 SYNOPSIS

Require AccessToken from Microsoft Azure Marketplace to use MS API. 
L<http://datamarket.azure.com>

    use Microsoft::Azure::AccessToken;

    my $maa = Microsoft::Azure::AccessToken->new("client_id", "client_secret", scope => "http://somemsscope.com");
    my $token = $foo->get_token();

=head1 SUBROUTINES/METHODS

=head2 token

=cut

sub new {
	my ($pkg, $client_id, $client_secret, %options) = @_;


	return bless {
		client_id => url_encode($client_id), 
		client_secret => url_encode($client_secret), 
		scope => $options{scope},
		token => undef, 
		expires => 0
	}, $pkg;
}

sub token {
	my $self = shift;

	if ( $self->{expires} > time and defined $self->{token} ) {
		return $self->{token};
	}

	my $ua = LWP::UserAgent->new; 

	my $content = join( '&', 
		'grant_type=client_credentials',
		'client_id=' . $self->{client_id},
		'client_secret=' . $self->{client_secret},
		'scope=' . $self->{scope} 
	);

	my $response = $ua->post(TOKENAUTH_URL, "Content-Type" => "application/x-www-form-urlencoded", Content => $content);

	if ( $response->is_success ) {
		my $resturn = undef;

		my $content = $response->decoded_content;
		my $js = eval { decode_json( $content ) };

		if ( $@ ) {
			print STDERR "Unable to parse response\n";
			return undef;
		} 

		my $expires = $js->{expires_in};
		my $token = $js->{access_token};

		$self->{expires} = time() + $expires; 
		$self->{token} = $token; 
		return $token;
	} else {
	      print STDERR $response->status_line;
	      return undef;
	}
}

=head1 AUTHOR

Dalibor Horinek, C<< <dal at horinek.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-microsoft-azure-accesstoken at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Microsoft-Azure-AccessToken>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Microsoft::Azure::AccessToken


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Microsoft-Azure-AccessToken>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Microsoft-Azure-AccessToken>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Microsoft-Azure-AccessToken>

=item * Search CPAN

L<http://search.cpan.org/dist/Microsoft-Azure-AccessToken/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dalibor Horinek.

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

1; # End of Microsoft::Azure::AccessToken
