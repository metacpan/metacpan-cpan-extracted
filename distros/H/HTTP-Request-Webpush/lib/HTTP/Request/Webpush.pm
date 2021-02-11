package HTTP::Request::Webpush;
#===========================================================================
#   Copyright 2021 Erich Strelow
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#============================================================================
use strict 'vars';
use warnings;

our $VERSION='0.14';

use parent 'HTTP::Request';

use JSON;
use Crypt::JWT qw(encode_jwt);
use MIME::Base64 qw( encode_base64url decode_base64url);
use Crypt::PRNG qw(random_bytes);
use Crypt::AuthEnc::GCM 'gcm_encrypt_authenticate';
use Crypt::PK::ECC 'ecc_shared_secret';
use Digest::SHA 'hmac_sha256';
use Carp;
use URI;

#================================================================
# hkdf()
#
# Calculates a key derivation using HMAC
# This is a simplified version based on Mat Scales jscript code
# see https://developers.google.com/web/updates/2016/03/web-push-encryption
#
# Notes: all args are expected to be binary strings, as the result
#================================================================
sub _hkdf($$$$$) {
   my $self=shift();
   my $salt=shift();
   my $ikm=shift();
   my $info=shift();
   my $len=shift();

   my $key=hmac_sha256($ikm,$salt);
   my $infoHmac= hmac_sha256($info,chr(1),$key);  

   return substr($infoHmac,0,$len);
}


sub subscription($$) {

   my $self=shift();
   my $subscription=shift();

   my $agent;

   if (ref $subscription eq 'HASH') {
      $agent=$subscription;
   } else {
      eval {$agent=from_json($subscription); };
   }

   croak "Can't process subscription object" unless ($agent);
   croak "Subscription must include endpoint" unless (exists $agent->{endpoint});

   $self->uri($agent->{endpoint});
   $self->{subscription}=$agent;
   return $agent;
}

sub auth($@) {

   my $self=shift();

   if (scalar @_ == 2) {
      $self->{'app-pub'}=shift();
      $self->{'app-key'}=shift();
   } elsif (scalar (@_) == 1 && ref $_ eq 'Crypt::PK::ECC') {
      $self->{'app-pub'}=$_->export_key_raw('public');
      $self->{'app-key'}=$_->export_key_raw('private');
   }

   return 1;
}

sub authbase64($$$) {

   my $self=shift();
   my $pub=decode_base64url(shift());
   my $key=decode_base64url(shift());
   return $self->auth($pub,$key);
}

sub reuseecc($$) {

   my $self=shift();
   return $self->{'ecc'}=shift();
}

sub subject($$) {
   my $self=shift();
   return $self->{'subject'}=shift();
}

sub encode($$) {

   my $self=shift();
   my $enc= shift() || 'aes128gcm';

   
   #This method is inherited from HTTP::Message, but here only aes128gcm applies
   croak 'Only aes128gcm encoding available' unless ($enc eq 'aes128gcm');

   #Check prerequisites
   croak 'Endpoint must be present for message encoding' unless ($self->url());
   croak 'Authentication keys must be present for message encoding' unless ($self->{'app-key'});
   croak 'UA auth params must be present for message encoding' unless ($self->{subscription}->{'keys'}->{'p256dh'} && $self->{subscription}->{'keys'}->{'auth'});
   croak 'Message payload must be 3992 bytes or less' unless (length($self->content) <= 3992);

   #This is the JWT part
   my $origin=URI->new($self->{subscription}->{endpoint});
   $origin->path_query('');
   my $data={  
     'aud' => "$origin",
     'exp'=> time() + 86400  
   };
   $data->{'sub'}=$self->{'subject'} if ($self->{'subject'});
 
   my $appk = Crypt::PK::ECC->new();
   $appk->import_key_raw($self->{'app-key'},'secp256r1');
   my $token = encode_jwt(payload => $data, key => $appk  , alg=>'ES256');
   $self->header( 'Authorization' => "WebPush $token" );

   #Now the encription step
   my $salt=random_bytes(16);

   my $pk; #This will be the session key for encryption
   if ($self->{'ecc'}) {
      $pk=$self->{'ecc'};
   } else {
      $pk=Crypt::PK::ECC->new();
      $pk->generate_key('prime256v1');
   }

   my $pub_signkey=$pk->export_key_raw('public');
   my $sec_signkey=$pk->export_key_raw('private');

   my $sk=Crypt::PK::ECC->new(); #This will be the UA endpoint key, which we know from the subscription object

   #The p256dh key is given to us in X9.62 format. Crypt::PK::ECC should be able
   #to read it as a "raw" format. But it's important to apply the base64url variant
   my $ua_public=decode_base64url($self->{subscription}->{'keys'}->{'p256dh'});
   $sk->import_key_raw($ua_public, 'secp256r1');

   my $ecdh_secret=$pk->shared_secret($sk);
   my $auth_secret= decode_base64url($self->{subscription}->{'keys'}->{'auth'});

   #An earlier draft established this header string as Content-Encoding: auth
   my $key_info='WebPush: info'.chr(0).$ua_public.$pub_signkey;
   my $prk=$self->_hkdf($auth_secret, $ecdh_secret, $key_info,32);

   #Again, an earlier RFC8291 draft used a different cek_info and nonce_info
   my $cek_info='Content-Encoding: aes128gcm'.chr(0);
   my $nonce_info='Content-Encoding: nonce'.chr(0);

   my $cek=$self->_hkdf($salt,$prk,$cek_info,16);
   my $nonce= $self->_hkdf($salt, $prk,$nonce_info,12);

   #Now we have all the ingredients, it's time for encryption
   my ($body, $tag) = gcm_encrypt_authenticate('AES', $cek, $nonce, '', $self->content."\x02\x00");

   #Some final composition
   #0x00001000" is the coding unit of AES-GCM, and x41 is the key length
   $body = $salt."\x00\x00\x10\x00\x41".$pub_signkey.$body.$tag;

   $self->content($body);
   $self->remove_header('Content-Length', 'Content-MD5','Content-Encoding','Content-Type','Encryption','Crypto-Key');
   $self->header('Crypto-Key' => "p256ecdsa=". encode_base64url($self->{'app-pub'}) );
   $self->header('Content-Length' => length($body));
   $self->header('Content-Type' => 'application/octet-stream');
   $self->header('Content-Encoding' => 'aes128gcm');
   return 1;
}

sub decoded_content
{
    my($self, %opt) = @_;

    #This is included so will always fail. decoded_content is inherited from HTTP::Message
    croak 'No decoding available';

}

sub decode {
    my($self, %opt) = @_;
    
    #This is included so will always fail. decode is inherited from HTTP::Message
    croak 'No decoding available';
}

sub new($%) {

   my ($class, %opts)=@_;

   my $self= HTTP::Request->new();
   $self->method('POST');

   bless $self, $class;

   my @Options= ('auth','subscription','authbase64','reuseecc','subject','content');
   for (@Options) {
      &$_($self,$opts{$_}) if (exists $opts{$_});
   }

   return $self;
}


1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Request::Webpush - HTTP Request for web push notifications

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use HTTP::Request::Webpush;

 #This should be the application-wide VAPID key pair
 #The APP_PUB part must be the same used by the user UA when requesting the subscription
 use constant APP_PUB => 'BCAI...RA8';
 use constant APP_KEY => 'M6x...UQTow';
 
 #This should be previously collected from an already subscribed user UA
 my $subscription='{"endpoint":"https://foo/fooer","expirationTime":null,"keys":{"p256dh":"BCNS...","auth":"dZ..."}}';

 my $message=HTTP::Request::Webpush->new();
 $message->auth(APP_PUB, APP_KEY);
 $message->subscription($subscription);
 $message->subject('mailto:bobsbeverage@some.com');
 $message->content('Hello world');
 
 #Additional headers can be applied with inherited HTTP::Response methods
 $message->header('TTL' => '90');

 #To send a single push message
 $message->encode();
 my $ua = LWP::UserAgent->new;
 my $response = $ua->request($message);

 #To send a batch of messages using the same application's end encryption key
 my $ecc = Crypt::PK::ECC->new();
 $ecc->generate_key('prime256v1');
 
 for (@cleverly_stored_subscriptions) {
    my $message=HTTP::Request::Webpush->new(reuseecc => $ecc);
    $message->subscription($_);
    $message->subject('mailto:bobsbeverage@some.com');
    $message->content('Come taste our new pale ale brand');
    $message->encode();
    my $response = $ua->request($message);
 }
 
=head1 DESCRIPTION

C<HTTP::Request::Webpush> produces an HTTP::Request for Application-side Webpush
notifications as described on L<RFC8291|https://tools.ietf.org/html/rfc8291>.
Such requests can then be submitted to the push message channel so they will
pop-up in the corresponding end user host.
In this scheme, an Application is a 
server-side component that sends push notification to previously subscribed
browser worker(s). This class only covers the Application role. A lot must 
be done on the browser side to setup a full working push notification system.

In practical terms, this class is a glue for all the encryption steps involved
in setting up a RFC8291 message, along with the L<RFC8292|https://tools.ietf.org/html/rfc8291> VAPID scheme.

=over 4

=item C<$r=HTTP::Request::Webpush-E<gt>new()>

=item C<$r=HTTP::Request::Webpush-E<gt>new(auth =E<gt> $my_key, subscription =E<gt> $my_subs, content='New lager batch arrived')>

The following options can be supplied in the constructor: subscription, auth, reuseecc, subject, content.

=item C<$r-E<gt>subscription($hash_reference)>

=item C<$r-E<gt>subscription('{"endpoint":"https://foo/fooer","expirationTime":null,"keys":{"p256dh":"BCNS...","auth":"dZ..."}}');>

This sets the subscription object related to this notification service. This should be the same object
returned inside the browser environment using the browser's Push API C<PushManager.subscribe()> method. The argument can
be either a JSON string or a previously setup hash reference. The HTTP::Request uri is taken verbatim from the endpoint
of the subscription object.

=item C<$r-E<gt>auth($pk) #pk being a Crypt::PK::ECC ref>

=item C<$r-E<gt>auth($pub_bin, $priv_bin)>

=item C<$r-E<gt>authbase64('BCAI...jARA8','M6...Tow')>

This sets the authentication key for the VAPID authentication scheme related to this push service.
This can either be a (public, private) pair or an already setup L<Crypt::PK::ECC> object. The public part
must be the same used earlier in the browser environment in the C<PushManager.subscribe() applicationServerKey> option.
The key pair can be passed as URL safe base64 strings using the C<authbase64()> variant.

=item C<$r-E<gt>reuseecc($ecc) #ecc being a Crypt::PK::ECC ref>

By default, HTTP::Request::Webpush creates a new P-256 key pair for the encryption
step each time. In large push batches this can be time consuming. You can
reuse the same previously setup key pair in repeated messages using this method.

=item C<$r-E<gt>subject('mailto:jdoe@some.com')>

This establish the contact information related to the origin of the push service. This method
isn't enforced since RFC8292 mentions this as a SHOULD practice. But, if a valid contact information
is not included, the browser push service is likely to bounce the message. The URI passed is 
used as the 'sub' claim in the authentication JWT.

=item C<$r-E<gt>content('Try our new draft beer')>

This sets the unencripted message content, or the payload in terms of RFC8291.
This is actually inherited from L<HTTP::Message>,
as well as other methods that can be used to set the message content.

=item C<$r-E<gt>encode('aes128gcm')>

This does the encryption process, as well as setting the headers expected by the push service.
aes128gcm is the only acceptable argument. Before calling this, the subscription and auth must
be supplied. B<You must call this method before submitting the message>, otherwise the encryption
process won't happen.

Please note that B<encode()> and B<content()> are inherited from L<HTTP::Message>. 

=back

=head1 REMARKS

No backward decryption is provided by this class, so the decoded_content() and decode() methods will fail. 

After you encode(), the content can still be accessed through HTTP::Message standard methods and it
will be the binary body of the encrypted message.

This class sets the following headers: I<Authorization>, I<Crypto-Key>, I<Content-Length>, I<Content-Type>, I<Content-Encoding>.
Additional headers might be added using the C<HTTP::Message::header()> method. Please note that the browser push
service will likely bounce the message if I<TTL> is missing. The standard also states that an I<Urgency> header might apply.


=head1 REFERENCES

This class relies on L<Digest::SHA> for the HKDF derivation, 
L<Crypt::AuthEnc::GCM> for the encryption itself, L<Crypt::PK::ECC> for key management and
L<Crypt::PRNG> for the salt.

RFC8291 establish the encription steps: L<https://tools.ietf.org/html/rfc8291>

RFC8292 establish the VAPID scheme: L<https://tools.ietf.org/html/rfc8292>

RFC8030 covers the whole HTTP push life cycle L<https://tools.ietf.org/html/rfc8030>

The following code samples and tutorials were very useful:

L<https://developers.google.com/web/updates/2016/03/web-push-encryption>

L<https://developers.google.com/web/fundamentals/push-notifications/web-push-protocol>

L<https://adiary.adiary.jp/0391>

=head1 AUTHOR

Erich Strelow <estrelow@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Erich Strelow

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

__END__
