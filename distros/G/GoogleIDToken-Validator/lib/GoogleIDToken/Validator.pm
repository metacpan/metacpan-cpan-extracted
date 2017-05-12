package GoogleIDToken::Validator;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

use MIME::Base64::URLSafe;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::RSA;
use Date::Parse;
use LWP::Simple;
use JSON;

=head1 NAME

GoogleIDToken::Validator - allows you to verify on server side Google Access Token received by mobile application

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Perl implamentation of Google Access Token verification.
Details can be found on android developers blog: 
L<http://android-developers.blogspot.com/2013/01/verifying-back-end-calls-from-android.html>

This module ONLY:
=item * Verifies that this token signed by google certificates.
=item * Verifies that this token was received by mobile application with given Client IDs and for given web application Client ID.

Nothing more. Nothing connected with authorization on any of Google APIs etc etc

    use GoogleIDToken::Validator;

    my $validator = GoogleIDToken::Validator->new(
	#do_not_cache_certs => 1, 					# will download google certificates from web every call of verify
        #google_certs_url	=> 'https://some.domain.com/certs',	# in case they change URL in the future... default is: https://www.googleapis.com/oauth2/v1/certs
	certs_cache_file 	=> '/tmp/google.crt',			# will cache certs in this file for faster verify if you are using CGI
	web_client_id 	=> '111222333444.apps.googleusercontent.com',	# Your Client ID for web applications received in Google APIs console
        app_client_ids 	=> [								# Array of your Client ID for installed applications received in Google APIs console
	    '777777777777-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',	# for exm. your production keystore ID
	    '888888888888-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com'	# and your eclipse debug keystore ID
	]
    );

    # web_client_id and at least one of app_client_ids are required

    # get the token from your mobile app somehow...
    my $token =  'eyJhbG..............very.long.base64.encoded.access.token............';

    my $payload = $validator->verify($token);
    if($payload) {
	# token is OK, lets see what we have got
        use Data::Dumper;
	print "payload: ".Dumper($payload);
    }

=cut

sub new {
    my($class, %args) = @_;
    my $self = bless({}, $class);
    
    $self->{google_certs_url} = exists $args{google_certs_url} ? $args{google_certs_url} : 'https://www.googleapis.com/oauth2/v1/certs';
    $self->{certs_cache_file} = exists $args{certs_cache_file} ? $args{certs_cache_file} : undef;
    $self->{do_not_cache_certs} = exists $args{do_not_cache_certs} ? $args{do_not_cache_certs} : 0;

    if($args{web_client_id}) {
	$self->{web_client_id} = $args{web_client_id};
    } else {
	croak "No Web Client ID was specified to check against.";
    }

    if($args{app_client_ids}) {
	$self->{app_client_ids} = $args{app_client_ids};
    } else {
	croak "No Application Client IDs were specified to check against.";
    }

    $self->{certs} = undef;

    return $self;
}

sub verify {
    my($self, $token) = @_;
    
    if($self->certs_expired()) {
	$self->get_certs();
    }
    
    my($env, $payload, $signature) = split /\./, $token;
    my $signed = $env . '.' . $payload;
    
    $signature = urlsafe_b64decode($signature);
    $env = decode_json(urlsafe_b64decode($env));
    $payload = decode_json(urlsafe_b64decode($payload));
    
    
    if(!exists $self->{certs}->{$env->{kid}}) {
	carp "There are no such certificate that used to sign this token (kid: $env->{kid}).";
	return undef;
    }
    my $rsa = Crypt::OpenSSL::RSA->new_public_key($self->{certs}->{$env->{kid}}->pubkey());
    $rsa->use_sha256_hash();
    
    if(!$rsa->verify($signed, $signature)) {
	carp "Signature is wrong.";
        return undef;
    }
    
    if($payload->{aud} ne $self->{web_client_id}) {
	carp "Web Client ID missmatch. ($payload->{aud}).";
	return undef;
    }
    
    foreach my $cid (@{$self->{app_client_ids}}) {
	return $payload if($cid eq $payload->{azp});
    }
    carp "App Client ID missmatch. ($payload->{azp})."
    
}

sub certs_expired {
    my $self = shift;
    return 1 if(!$self->{certs});
    foreach my $kid (keys %{$self->{certs}}) {
	return 1 if(str2time($self->{certs}->{$kid}->notAfter()) < time);
    }
    return 0;
}

sub get_certs {
    my $self = shift;
    if($self->{do_not_cache_certs}) {
	$self->get_certs_from_web();
    } else {
	if($self->{certs_cache_file} && -e $self->{certs_cache_file}) {
	    $self->get_certs_from_file();
	}
        if($self->certs_expired()) {
    	    $self->get_certs_from_web();
	}
    }
}

sub get_certs_from_file {
    my $self = shift;
    open my $fh, $self->{certs_cache_file} or croak "Can't read certs from cache file($self->{certs_cache_file}): $!";
    my $json_certs = '';
    while(<$fh>) { $json_certs .= $_ }
    if($json_certs) {
	$self->parse_certs($json_certs);
    } else {
	$self->{certs} = undef;
    }
    close $fh;
}

sub get_certs_from_web {
    my($self) = @_;
    my $json_certs = get($self->{google_certs_url});
    if($json_certs) {
	$self->parse_certs($json_certs);
	if(!$self->{do_not_cache_certs} && $self->{certs_cache_file}) {
	    open my $fh, ">".$self->{certs_cache_file} or croak "Can't write certs to cache file($self->{certs_cache_file}): $!";
	    print $fh $json_certs;
	    close $fh;
	}
	
    } else {
	croak "ERROR getting certs from $self->{certs_cache_file}";
	
    }
}

sub parse_certs {
    my($self, $json_certs) = @_;
    my $certs = decode_json($json_certs);
    foreach my $kid (keys %{$certs}) {
        $self->{certs}->{$kid} = Crypt::OpenSSL::X509->new_from_string($certs->{$kid});
    }
}

=head1 AUTHOR

Dmitry Mukhin, C<< <admin at dimanoid.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-googleidtoken-validator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GoogleIDToken-Validator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GoogleIDToken::Validator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GoogleIDToken-Validator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GoogleIDToken-Validator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GoogleIDToken-Validator>

=item * Search CPAN

L<http://search.cpan.org/dist/GoogleIDToken-Validator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dmitry Mukhin.

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

42; # End of GoogleIDToken::Validator
