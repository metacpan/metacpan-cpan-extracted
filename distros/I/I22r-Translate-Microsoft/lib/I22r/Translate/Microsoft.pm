package I22r::Translate::Microsoft;
use Moose;
with 'I22r::Translate::Backend';
use I22r::Translate::Result;
use Time::HiRes;
use Carp;
use Data::Dumper;
use Encode;
use HTML::Entities;
use HTTP::Request;
use HTTP::Headers;
use JSON;
use LWP::UserAgent;
use URL::Encode 'url_encode';
use XML::XPath;

use constant TOKENAUTH_URL => 
    'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13';
use constant SERVICE_URL =>
    'http://api.microsofttranslator.com/V2/Http.svc';
use constant TEXT_TAG =>
    "<string xmlns=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">";

sub encode_content {
    # encode a string to be translated. Non-ASCII text must be UTF-8 encoded
    # and the characters < & > must be encoded as their XML/HTML entities.
    my $text = shift;
    $text = HTML::Entities::encode_entities( $text, q[<>&] );
    $text = Encode::encode("utf-8", $text);
    return $text;
}

sub decode_ents {
    my $text = shift;
    $text = HTML::Entities::decode_entities( $text, q[<>&] );
    return $text;
}



our $VERSION = '0.96';

# TODO: apply MooseX::ClassAttribute to these variables
our %remap = ( hm => 'nww', zh => 'zh-CHS' );
our %unremap = ( mww => 'hm', "zh-CHS" => "zh" );
our @bing_languages = qw(ar bg ca zh-CHS zh-CHT cs da nl en et fi fr 
    de el ht he hi mww hu id it ja ko lv lt no fa pl pt ro ru sk sl 
    es sv th tr uk vi );

my $token = { expired => 0 };
sub _token { $token }

sub BUILD {
    my $self = shift;
    $self->name('Bing') unless $self->name;
}

sub can_translate {
    my ($self, $lang1, $lang2) = @_;
    if ($lang1 eq $lang2) {
	return 1;
    }
    my $langs = join(" ", keys %remap, @bing_languages);
    return -1 unless " $langs " =~ / \Q$lang1 / && " $langs " =~ / \Q$lang2 /;
    if ($lang1 =~ /zh/ && $lang2 =~ /zh/) {
	return 0.9;
    }
    return 0.39 + 0.02 * rand;
}

sub network_available { 1 }

sub get_translations {
    my ($self, $req) = @_;

    return unless $req->config('ENABLED');
    return unless $self->network_available();
    return unless $self->_check_token($req);

    # XXX - handle source encoding

    my (%result, %untext);
    my %text = %{ $req->text };
    while (my ($id,$text) = each %text) {
	push @{ $untext{$text} }, $id;
    }
    
    my $src = $remap{ $req->src } // $req->src;
    my $dest = $remap{ $req->dest } // $req->dest;
    my $content0 = _template($src, $dest);
    my @text = keys %untext;
    my @translated;

    while (@text) {
	last if $req->timed_out;
	last if !$self->_check_token($req);

	my $uri = URI->new( SERVICE_URL . "/GetTranslationsArray");
	my $headers = HTTP::Headers->new;
	$headers->header( Authorization => $token->{authorization} );
	$headers->header( "Content-Type" => "text/xml" );
	my $content = $content0;

	my @itext;
	my $otext = shift @text;
	my $xtext = TEXT_TAG . encode_content($otext) . "</string>\n";
	while (length($content) + length($xtext) < 10000) {
	    $content =~ s{<TXT/>\n*}{$xtext . "<TXT/>"}e;
	    push @itext, $otext;
	    last unless defined( $otext = shift @text );
	    $xtext =
		"<string xmlns=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">"
		. encode_content($otext) . "</string>\n";
	}
	if (defined $otext) {
	    unshift @text, $otext;
	}
	$content =~ s{<TXT/>}{};
	$content =~ s{<COUNT/>}{scalar @itext}e;

#	$content = Encode::encode("utf-8", $content);

	my $remaining;
	my $translation_start = Time::HiRes::time();

	eval {
	    $SIG{ALRM} = sub { die "bing translator timeout\n" };
	    alarm( $req->config("timeout") // 15 );

	    my $request = HTTP::Request->new(
		POST => $uri, $headers, $content );
	    my $response = $token->{ua}->request($request);

	    $remaining = alarm(0);

	    if ($response->code == 414) {
		die "Request was too long (content length was "
		    . length($content) . ")";
	    }
	    if ($response->code != 200) {
		my $rq = delete $response->{_request};
		print STDERR "$_ => " . Dumper($rq->{$_}) . "\n" for keys %$rq;
		die "Error response from the Bing translator: ", Dumper($response);
	    }
	    my $dc = $response->decoded_content;

	    my $xp = XML::XPath->new( xml => $dc );
	    my @resultnodes = $xp->findnodes("//TranslatedText");
	    for my $i (0 .. $#resultnodes) {
		my $input = $itext[$i];

		my $output = $xp->getNodeText($resultnodes[$i]);
		$output = decode_ents($output);

		# XXX - handle destination encoding

		my $ids = $untext{$input};
		foreach my $id (@$ids) {
		    $req->results->{$id} = I22r::Translate::Result->new(
			id => $id,
			otext => $input,
			olang => $unremap{$req->src} // $req->src,
			lang => $unremap{$req->dest} // $req->dest,
			text => $output,
			source => $self->name,
			length => length($output),
			time => time
			);
		    push @translated, $id;			
		}
		$self->config->{_NETWORK_ERR} = 0;
	    }
	};
	if ($@) {
	    if ($@ =~ /bing translator timeout/) {
		carp __PACKAGE__, ": translation timed out";
	    } 
            # XXX - what does network error look like?
	    elsif ($@ =~ /asdfasdfasdf/) { 
		carp __PACKAGE__, ": network error - $@";
		$self->config->{_NETWORK_ERR}++;
	    } else {
		carp __PACKAGE__, ": error in translation: $@";
	    }
	}
	my $translation_elapsed = Time::HiRes::time() - $translation_start;
    }
    return @translated;
}

sub _template {
    my ($src, $dest) = @_;
    my $content0 = qq[
<GetTranslationsArrayRequest>
  <AppId />
  <From>$src</From>
  <Options>
    <Category xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2">general</Category>
    <ContentType xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2">text/plain</ContentType>
    <ReservedFlags xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2"/>
    <State xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2" />
    <Uri xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2"></Uri>
    <User xmlns="http://schemas.datacontract.org/2004/07/Microsoft.MT.Web.Service.V2">TestUserId</User>
  </Options>
  <Texts>
<TXT/>
  </Texts>
  <To>$dest</To>
  <MaxTranslations><COUNT/></MaxTranslations>
</GetTranslationsArrayRequest>];

    return $content0;
}







sub _check_token {
    my ($pkg, $req) = @_;

    if (time < ($token->{expires} // 0)) {
	I22r::Translate->log( $req->{logger}, "Microsoft backend: ",
			      "auth token still valid" );
	return 1;
    }

    my ($client_id, $secret);
    if ($req) {
	$client_id = $req->config('CLIENT_ID');
	$secret = $req->config('SECRET');
    } else {
	$client_id = $pkg->config('CLIENT_ID');
	$secret = $pkg->config('SECRET');
    }
    unless ($client_id && $secret) {
	I22r::Translate->log( $req->{logger},
			      "Microsoft backend: ",
			      "client_id or secret missing, ",
			      "cannot obtain auth token!" );
	return;
    }

    if (!$token->{secret} || $token->{secret} ne $secret) {
	$token->{secret} = $secret;
	$token->{secretx} = url_encode( $secret );
    }
    $token->{client_idx} = url_encode( $client_id );

    my $content = join( '&', 
			'grant_type=client_credentials',
			'client_id=' . $token->{client_idx},
			'client_secret=' . $token->{secretx},
			'scope=http://api.microsofttranslator.com/' );

    my $headers = HTTP::Headers->new(
	'Content-Type', 'application/x-www-form-urlencoded');
    $token->{ua} //= LWP::UserAgent->new;
    my $request = HTTP::Request->new(
	POST => TOKENAUTH_URL,
	$headers, $content );
    my $req_start = time;
    my $res = $token->{ua}->request( $request );
    if (!$res->is_success) {

	eval {
	    my $js = decode_json( $res->decoded_content );
	    if ($js->{error} && $js->{error_description}) {
		carp __PACKAGE__, 
			": Failed to refresh authorization token ",
			"for client [$client_id\n$secret]:\n",
		    "Error: ", $js->{error}, "\n",
		    "Error description: ", $js->{error_description}, "\n",
		    "Result code: ", $res->{_rc}, "\n",
		    "FULL ERROR: ", join(";",%$js), "\n",
		    "REQUEST: ", join(" ",%$request), "\n",
		    "REQ_HEADERS: ", join(" ", %{$request->{_headers}}), "\n";
		I22r::Translate->log( $req->{logger},
				      "request for auth token failed: ",
				      $js->{error}, "/",
				      $js->{error_description} );
		1;
	    }
	} or carp __PACKAGE__, ": Failed to refresh authorization token for",
			       " client [$client_id]. $!\n";
	return;
    }
    my $dc = $res->decoded_content;
    my $js = eval { decode_json( $dc ) };
    if ($@) {
	carp "decode_json error. input was $dc";
	return;
    }

    my $expires = $js->{expires_in};
    if ($expires > 120) {
	$expires -= 60;
    } else {
	$expires /= 2;
    }
    $token->{expires} = $req_start + $expires;
    $token->{token} = $js->{access_token};
    $token->{authorization} = "Bearer " . $token->{token};
    I22r::Translate->log($req->{logger}, "Microsoft backend: ",
			 "obtained auth token");
    return 1;
}

1;
# End of I22r::Translate::Microsoft

=head1 NAME

I22r::Translate::Microsoft - Microsoft Translator backend for I22r::Translate
framework

=head1 VERSION

Version 0.96

=head1 SYNOPSIS

    I22r::Translate->config(
        'I22r::Translate::Microsoft' => {
            ENABLED => 1,
            CLIENT_ID => 'your_Microsoft/Azure_client_id',
            SECRET => 'your_Microsoft/Azure_secret'
        }
    );

    $translation = I22r::Translate->translate_string(
        src => 'en', dest => 'es', text => 'hello world',
        quality => { 'I22r::Translate::Microsoft' => 2.0 } );

=head1 DESCRIPTION

Invokes Microsoft's translation webservice to translate content
from one language to another.

=head1 CONFIG

You instruct the L<I22r::Translate> package to use the
Microsoft backend by passing a key-value  pair to the
L<I22r::Translate::config|I22r::Translate/"config"> method
where the key is the string "C<I22r::Translate::Microsoft>"
and the value is a hash reference with at least the following
key-value pairs:

=over 4

=item ENABLED => 0 | 1

Must be set to a true value for the Microsoft backend to function.

=item CLIENT_ID => userid

Required Windows Azure Marketplace client ID for accessing the
Microsoft Translator API. See L<"CREDENTIALS">, below.

=item SECRET => 44-character string

Required Windows Azure Marketplace "client secret" for accessing the
Microsoft Translator API. See L<"CREDENTIALS">, below.

=item timeout => integer

Stops a translation job after a certain number of seconds have
passed. Optional. Any translations that were completed before
the timeout will still be returned.

=item callback => code reference or function name

A function to be invoked when the Microsoft backend obtains
a translation result. 
The function will be called with two arguments: the
L<request|I22r::Translate::Request> object that is handling the
translation, and a hash reference containing the fields and values
for the new translation result.

You can have separate callbacks in the global configuration, for each
backend, and for the current request.

=item filter => array reference

List of filters to use (see L<I22r::Translate::Filter>) when
sending text to the Microsoft Translate webservice.

=back

=head1 CREDENTIALS

This package interacts with the Microsoft Translator API,
which requires some you/us to provide a "client id" and
"client secret" to access Microsoft's data services.
As of October 2012, here are the steps you need to take
to get those credentials. (If these steps don't work anymore,
and you do figure out what steps you need to do, L<let me 
know|mailto:mob@cpan.org> or L<file a bug report|"SUPPORT">
and I'll update this document.

=over 4

=item 1. 

If you don't have a  Windows Live ID , sign up
for one at L<https://signup.live.com/signup.aspx?lic=1>    

=item 2. 

Visit L<https://datamarket.azure.com/dataset/bing/microsofttranslator>.
Register for a "Windows Azure Marketplace" account.

=item 3. 

Choose a Microsoft Translator data plan. One of the
available plans is a free option for 2,000,000 characters/month.

=item 4. 

Now you have to "register an application". Visit
L<https://datamarket.azure.com/developer/applications> and hit the
big green B<REGISTER> button.

=item 5. 

Choose any "Client ID" and "Name" for your application. The "URI"
is also a required field, but the translator API doesn't use it, so you
can put whatever you like in that field, too.

Make a note of the "Client ID"  value that you entered and the
"Client secret" value that Microsoft provided. You will have to provide
these values to the C<I22r::Translate::Microsoft> backend configuration
with the C<CLIENT_ID> and C<SECRET> keys.

Example: If your application registration screen looks like:

    * Client ID         angus
    * Name              The Beefinator
    * Client secret     ykiDjfQ9lztW/oFUC4t2ciPWH2nJS88FqXcQbs/Z9Y=7
    * Redirect URI      https://ilikebeef.com/
      Description       The multilingual Beefinator site

Then you would configure the Microsoft backend with

    I22r::Translate->config(
        'I22r::Translate::Microsoft' => {
            ENABLED => 1,
            CLIENT_ID => "angus",
            SECRET => "ykiDjfQ9lztW/oFUC4t2ciPWH2nJS88FqXcQbs/Z9Y=7"
        } );

(these are not real credentials).

=back

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-i22r-translate-microsoft at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=I22r-Translate-Microsoft>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc I22r::Translate::Microsoft

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=I22r-Translate-Microsoft>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/I22r-Translate-Microsoft>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/I22r-Translate-Microsoft>

=item * Search CPAN

L<http://search.cpan.org/dist/I22r-Translate-Microsoft/>

=back

=head1 SUBROUTINES/METHODS

There should be no need to use the methods of this package directly.
See L<I22r::Translate::Backend> and L<I22r::Translate>.

=head1 SEE ALSO

L<I22r::Translate>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

