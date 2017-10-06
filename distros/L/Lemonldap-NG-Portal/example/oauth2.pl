#!/usr/bin/perl -w

# Simple OpenID Connect client

use strict;
use JSON;
use LWP::UserAgent;
use MIME::Base64
  qw/encode_base64url encode_base64 decode_base64url decode_base64/;
use URI::Escape;
use CGI;
use Data::Dumper;
use utf8;
use Digest::SHA
  qw/hmac_sha256_base64 hmac_sha384_base64 hmac_sha512_base64 sha256 sha256_base64 sha384_base64 sha512_base64/;

#==============================================================================
# Configuration
#==============================================================================
my $client_id         = "lemonldap";
my $client_secret     = "secret";
my $portal_url        = "http://auth.example.com";
my $authorization_uri = "$portal_url/oauth2/authorize";
my $token_uri         = "$portal_url/oauth2/token";
my $userinfo_uri      = "$portal_url/oauth2/userinfo";
my $registration_uri  = "$portal_url/oauth2/register";
my $endsession_uri    = "$portal_url/oauth2/logout";
my $checksession_uri  = "$portal_url/oauth2/checksession";

#==============================================================================
# CSS
#==============================================================================
my $css = <<EOT;
html,body{
  height:100%;
  background:#ddd;
}
#content{
  padding:20px;
}
EOT

#==============================================================================
# Main
#==============================================================================
my $ua                      = new LWP::UserAgent;
my $cgi                     = new CGI;
my $redirect_uri            = $cgi->url . "?openidconnectcallback=1";
my $local_configuration_uri = $cgi->url . "?test=configuration";
my $local_registration_uri  = $cgi->url . "?test=registration";
my $local_request_uri       = $cgi->url . "?test=request";
my $local_checksession_uri  = $cgi->url . "?test=checksession";
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

# Request URI
if ( $cgi->param("test") eq "request" ) {
    my $request_paylod_hash = {
        response_type => "code",
        scope         => "openid profile",
        client_id     => $client_id,
        redirect_uri  => $redirect_uri,
        display       => "page",
        iss           => $client_id,
        aud           => [$portal_url]
    };
    my $request_payload = encode_base64( to_json($request_paylod_hash), "" );
    my $request_header_hash = { typ => "JWT", alg => "HS256" };
    my $request_header = encode_base64( to_json($request_header_hash), "" );

    my $request_digest =
      hmac_sha256_base64( $request_header . "." . $request_payload,
        $client_secret );
    $request_digest =~ s/\+/-/g;
    $request_digest =~ s/\//_/g;
    my $request =
      $request_header . "." . $request_payload . "." . $request_digest;

    print $cgi->header( -type => 'application/jwt;charset=utf-8' );
    print $request;
    exit;
}

# Check Session
if ( $cgi->param("test") eq "checksession" ) {
    my $session_state = $cgi->param("session_state");
    my $js;
    $js .= 'var stat = "unchanged";' . "\n";
    $js .=
        'var mes = "'
      . uri_escape($client_id)
      . '" + " " + "'
      . uri_escape($session_state) . '";' . "\n";
    $js .= 'function check_session()' . "\n";
    $js .= '{' . "\n";
    $js .= 'var targetOrigin = "http://auth.example.com";' . "\n";
    $js .=
'var win = window.parent.document.getElementById("opchecksession").contentWindow;'
      . "\n";
    $js .= 'win.postMessage( mes, targetOrigin);' . "\n";
    $js .= '}' . "\n";
    $js .= 'function setTimer()' . "\n";
    $js .= '{' . "\n";
    $js .= 'check_session();' . "\n";
    $js .= 'timerID = setInterval("check_session()",3*1000);' . "\n";
    $js .= '}' . "\n";
    $js .= 'window.addEventListener("message", receiveMessage, false);' . "\n";
    $js .= 'function receiveMessage(e)' . "\n";
    $js .= '{' . "\n";
    $js .= 'var targetOrigin = "http://auth.example.com";' . "\n";
    $js .= 'if (e.origin !== targetOrigin ) {return;}' . "\n";
    $js .= 'stat = e.data;' . "\n";
    $js .= 'document.getElementById("sessionstatus").textContent=stat;' . "\n";
    $js .= '}' . "\n";
    $js .= 'setTimer();' . "\n";

    print $cgi->header( -type => 'text/html' );
    print $cgi->start_html( -title => 'Check Session', -script => $js );
    print "<p>Session status: <span id=\"sessionstatus\"></span></p>\n";
    print $cgi->end_html();
    exit;
}

# Start HTTP response
print $cgi->header( -type => 'text/html;charset=utf-8' );

print "<!DOCTYPE html>\n";
print
  "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
print "<head>\n";
print "<title>OpenID Connect sample client</title>\n";
print
  "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n";
print
  "<meta http-equiv=\"Content-Script-Type\" content=\"text/javascript\" />\n";
print "<meta http-equiv=\"cache-control\" content=\"no-cache\" />\n";
print
"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n";
print
"<link href=\"$portal_url/skins/bootstrap/css/bootstrap.css\" rel=\"stylesheet\">\n";
print
"<link href=\"$portal_url/skins/bootstrap/css/bootstrap-theme.css\" rel=\"stylesheet\">\n";
print "<style>\n";
print "$css\n";
print "</style>\n";
print
"<script type=\"text/javascript\" src=\"/skins/common/js/jquery-1.10.2.js\"></script>\n";
print
"<script type=\"text/javascript\" src=\"/skins/common/js/jquery-ui-1.10.3.custom.js\"></script>\n";
print "<script src=\"$portal_url/skins/bootstrap/js/bootstrap.js\"></script>\n";
print "</head>\n";
print "<body>\n";

print "<div id=\"content\" class=\"container\">\n";
print "<div class=\"panel panel-info panel-body\">\n";

print "<div class=\"page-header\">\n";
print "<h1 class=\"text-center\">OpenID Connect sample client</h1>\n";
print "</div>\n";

# OIDC Callback
my $callback = $cgi->param("openidconnectcallback");

if ($callback) {

    print "<h2 class=\"text-center\">Callback received</h2>";

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print
"<h2 class=\"panel-title text-center\">OpenID Connect callback received</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre><code>"
      . $cgi->url( -path_info => 1, -query => 1 )
      . "</code></pre>\n";
    print "</div>\n";
    print "</div>\n";

    # Check Flow
    my $code              = $cgi->param("code");
    my $implicitcallback  = $cgi->param("implicitcallback");
    my $error             = $cgi->param("error");
    my $error_description = $cgi->param("error_description");

    if ($error) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Error: $error</p>";
        print "<p>Description: $error_description</p>" if $error_description;
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    unless ( $code or $implicitcallback ) {

        print '
	<script type="text/javascript">
	// First, parse the query string
	var params = {}, postBody = location.hash.substring(1),
	regex = /([^&=]+)=([^&]*)/g, m;
	var redirect_location = "http://" + window.location.host + "/oauth2.pl?openidconnectcallback=1&implicitcallback=1";
	while (m = regex.exec(postBody)) {
	params[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
	redirect_location = redirect_location +  "&" + decodeURIComponent(m[1]) +"="+ decodeURIComponent(m[2]);
	}
	
	window.location = redirect_location;

	</script>
    ';

    }

    # AuthN Response
    my $state = $cgi->param("state");

    # Check state
    unless ( $state eq "ABCDEFGHIJKLMNOPQRSTUVWXXZ" ) {
        print "<div class=\"alert alert-danger\">";
        print "<p>OpenIDConnect callback state $state is invalid</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    my $access_token;
    my $id_token;

    if ($code) {

        my $grant_type = "authorization_code";

        my %form;
        $form{"code"}         = $code;
        $form{"redirect_uri"} = $redirect_uri;
        $form{"grant_type"}   = $grant_type;

        # Method client_secret_post
        #$form{"client_id"}     = $client_id;
        #$form{"client_secret"} = $client_secret;
        #my $response = $ua->post( $token_uri, \%form,
        #    "Content-Type" => 'application/x-www-form-urlencoded' );

        # Method client_secret_basic
        my $response = $ua->post(
            $token_uri, \%form,
            "Authorization" => "Basic "
              . encode_base64("$client_id:$client_secret"),
            "Content-Type" => 'application/x-www-form-urlencoded',
        );

        if ( $response->is_error ) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Bad authorization response: "
              . $response->message . "</p>";
            print "<p>$response->content</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        # Get access_token and id_token
        my $content = $response->decoded_content;

        my $json;
        eval { $json = from_json( $content, { allow_nonref => 1 } ); };

        if ($@) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Wrong JSON content</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        if ( $json->{error} ) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Error in token response:" . $json->{error} . "</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        $access_token = $json->{access_token};
        $id_token     = $json->{id_token};

    }
    else {
        $access_token = $cgi->param("access_token");
        $id_token     = $cgi->param("id_token");
    }

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">Tokens</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>Access token: <code>$access_token</code></pre>";
    print "<pre>ID token: <code>$id_token</code></pre>";
    print "</div>\n";
    print "</div>\n";

    # Get ID token content
    my ( $id_token_header, $id_token_payload, $id_token_signature ) =
      split( /\./, $id_token );

    # TODO check signature

    my $id_token_payload_hash =
      from_json( decode_base64($id_token_payload), { allow_nonref => 1 } );

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">ID Token content</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>" . Dumper($id_token_payload_hash) . "</pre>";
    print "</div>\n";
    print "</div>\n";

    # Request UserInfo

    my $ui_response =
      $ua->get( $userinfo_uri, "Authorization" => "Bearer $access_token" );
    my $ui_content = $ui_response->decoded_content;

    my $ui_json;

    my $content_type = $ui_response->header('Content-Type');
    if ( $content_type =~ /json/ ) {
        eval { $ui_json = from_json( $ui_content, { allow_nonref => 1 } ); };
    }
    elsif ( $content_type =~ /jwt/ ) {
        my ( $ui_header, $ui_payload, $ui_signature ) =
          split( /\./, $ui_content );
        eval {
            $ui_json =
              from_json( decode_base64($ui_payload), { allow_nonref => 1 } );
        };
    }

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">User Info</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>" . Dumper($ui_json) . "</pre>";
    print "</div>\n";
    print "</div>\n";

    # Session Management RP iFrame
    print "<iframe src=\""
      . $local_checksession_uri
      . "&session_state="
      . $cgi->param('session_state')
      . "\" id=\"rpchecksession\" width=\"100%\"></iframe>\n";
    print
"<iframe src=\"$checksession_uri\" id=\"opchecksession\" width=\"0\" height=\"0\"></iframe>\n";

    my $logout_redirect_uri =
        $endsession_uri
      . "?post_logout_redirect_uri="
      . $cgi->url
      . "&state="
      . $state;

    print "<div class=\"text-center\">\n";
    print
"<a class=\"btn btn-danger\" role=\"button\" href=\"$endsession_uri\">Logout</a>\n";
    print
"<a class=\"btn btn-danger\" role=\"button\" href=\"$logout_redirect_uri\">Logout with redirect</a>\n";
    print "</div>\n";
    print "<hr />\n";
    print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
      . $cgi->url
      . "\">Home</a></div>\n";

}

# Configuration read
elsif ( $cgi->param("test") eq "configuration" ) {

    my $openid_configuration_url =
      $portal_url . "/.well-known/openid-configuration";

    print
"<h3 class=\"text-center\">Get configuration from <a href=\"$openid_configuration_url\">$openid_configuration_url</a></h3>\n";

    my $config_response = $ua->get($openid_configuration_url);

    if ( $config_response->is_error ) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Bad configuration response: "
          . $config_response->message . "</p>";
        print "<p>$config_response->content</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    my $content = $config_response->decoded_content;

    my $json;
    eval { $json = from_json( $content, { allow_nonref => 1 } ); };

    if ($@) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Wrong JSON content</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    if ( $json->{error} ) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Error in configuration response:" . $json->{error} . "</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">Configuration content</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>" . Dumper($json) . "</pre>";
    print "</div>\n";
    print "</div>\n";

    if ( $json->{jwks_uri} ) {
        my $jwks_response = $ua->get( $json->{jwks_uri} );

        if ( $jwks_response->is_error ) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Bad JWKS response: " . $jwks_response->message . "</p>";
            print "<p>$jwks_response->content</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        my $jwks_content = $jwks_response->decoded_content;

        my $jwks_json;
        eval { $jwks_json = from_json( $jwks_content, { allow_nonref => 1 } ); };

        if ($@) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Wrong JSON content</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        if ( $json->{error} ) {
            print "<div class=\"alert alert-danger\">";
            print "<p>Error in jwks response:" . $json->{error} . "</p>";
            print "</div>";
            print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
              . $cgi->url
              . "\">Home</a></div>\n";
            print "</div>";
            print "</div>";
            print $cgi->end_html();
            exit 0;
        }

        print "<div class=\"panel panel-info\">\n";
        print "<div class=\"panel-heading\">\n";
        print "<h2 class=\"panel-title text-center\">JWKS content</h2>\n";
        print "</div>\n";
        print "<div class=\"panel-body\">\n";
        print "<pre>" . Dumper($jwks_json) . "</pre>";
        print "</div>\n";
        print "</div>\n";
    }

    print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
      . $cgi->url
      . "\">Home</a></div>\n";

}

# Registration
elsif ( $cgi->param("test") eq "registration" ) {

    print
"<h3 class=\"text-center\">Register fake client on <a href=\"$registration_uri\">$registration_uri</a></h3>\n";

    my $fake_metadata = {
        "application_type" => "web",
        "redirect_uris"    => [
            "https://client.example.org/callback",
            "https://client.example.org/callback2"
        ],
        "client_name"            => "My Example",
        "client_name#ja-Jpan-JP" => "クライアント名",
        "logo_uri"               => "https://client.example.org/logo.png",
        "subject_type"           => "pairwise",
        "sector_identifier_uri" =>
          "https://other.example.net/file_of_redirect_uris.json",
        "token_endpoint_auth_method" => "client_secret_basic",
        "jwks_uri" => "https://client.example.org/my_public_keys.jwks",
        "userinfo_encrypted_response_alg" => "RSA1_5",
        "userinfo_encrypted_response_enc" => "A128CBC-HS256",
        "contacts"     => [ 've7jtb@example.org', 'mary@example.org' ],
        "request_uris" => [
'https://client.example.org/rf.txt#qpXaRLh_n93TTR9F252ValdatUQvQiJi5BDub2BeznA'
        ],
    };

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">Client metadata sent</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>" . Dumper($fake_metadata) . "</pre>";
    print "</div>\n";
    print "</div>\n";

    # POST client metadata
    my $fake_metadata_json = to_json($fake_metadata);
    my $register_response  = $ua->post(
        $registration_uri,
        "Content-Type" => 'application/json',
        "Content"      => $fake_metadata_json
    );

    my $register_content = $register_response->decoded_content;

    my $register_json;
    eval {
        $register_json = from_json( $register_content, { allow_nonref => 1 } );
    };

    if ($@) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Wrong JSON content</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    if ( $register_json->{error} ) {
        print "<div class=\"alert alert-danger\">";
        print "<p>Error in register response:"
          . $register_json->{error} . "</p>";
        print "</div>";
        print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
          . $cgi->url
          . "\">Home</a></div>\n";
        print "</div>";
        print "</div>";
        print $cgi->end_html();
        exit 0;
    }

    print "<div class=\"panel panel-info\">\n";
    print "<div class=\"panel-heading\">\n";
    print "<h2 class=\"panel-title text-center\">Register content</h2>\n";
    print "</div>\n";
    print "<div class=\"panel-body\">\n";
    print "<pre>" . Dumper($register_json) . "</pre>";
    print "</div>\n";
    print "</div>\n";

    print
"<div class=\"text-center\"><a class=\"btn btn-info\" role=\"button\" href=\""
      . $cgi->url
      . "\">Home</a></div>\n";

}

# First access
else {

    # AuthN Request
    my $response_type = uri_escape("code");
    my $scope         = uri_escape("openid profile address email phone");
    my $state         = uri_escape("ABCDEFGHIJKLMNOPQRSTUVWXXZ");
    my $nonce         = uri_escape("1234567890");
    my $display       = uri_escape("popup");
    my $prompt        = uri_escape("consent");
    my $ui_locales    = uri_escape("fr-CA en-GB en fr-FR fr");
    my $login_hint    = uri_escape("coudot");
    my $max_age       = 3600;
    my $id_token_hint =
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhenAiOiJsZW1vbmxkYXAiLCJzdWIiOiJjb3Vkb3RAbGluYWdvcmEuY29tIiwiaWF0IjoxNDI3Mjk5MjMyLCJhdXRoX3RpbWUiOjE0MjcyOTYwNTQsImV4cCI6IjM2MDAiLCJub25jZSI6IjEyMzQ1Njc4OTAiLCJhdWQiOlsibGVtb25sZGFwIl0sImF0X2hhc2giOiJwZEdBcG9lVE8tNTM0el9XQ2wxcUtRIiwiYWNyIjoibG9hLTIiLCJpc3MiOiJodHRwOi8vYXV0aC5leGFtcGxlLmNvbS8ifQ==.R7nddv9bom+J2hyrTe/7a4mRupJAoDioBYaop+Q94Fg";

    my $request_paylod_hash = {
        response_type => "code",
        scope         => "openid profile",
        client_id     => $client_id,
        redirect_uri  => $redirect_uri,
        display       => "page",
        iss           => $client_id,
        aud           => [$portal_url]
    };
    my $request_payload = encode_base64( to_json($request_paylod_hash), "" );
    my $request_header_hash = { typ => "JWT", alg => "HS256" };
    my $request_header = encode_base64( to_json($request_header_hash), "" );

    my $request_digest =
      hmac_sha256_base64( $request_header . "." . $request_payload,
        $client_secret );
    $request_digest =~ s/\+/-/g;
    $request_digest =~ s/\//_/g;
    my $request = uri_escape(
        $request_header . "." . $request_payload . "." . $request_digest );
    my $request_uri = uri_escape($local_request_uri);

    $client_id    = uri_escape($client_id);
    $redirect_uri = uri_escape($redirect_uri);

    my $redirect_url = $authorization_uri
      . "?response_type=$response_type&client_id=$client_id&scope=$scope&redirect_uri=$redirect_uri&state=$state&nonce=$nonce&display=$display&prompt=$prompt&ui_locales=$ui_locales&login_hint=$login_hint&max_age=$max_age&id_token_hint=$id_token_hint";

    my $implicit_response_type = uri_escape("id_token token");
    my $implicit_redirect_url  = $authorization_uri
      . "?response_type=$implicit_response_type&client_id=$client_id&scope=$scope&redirect_uri=$redirect_uri&state=$state&nonce=$nonce&display=$display&prompt=$prompt&ui_locales=$ui_locales&login_hint=$login_hint&max_age=$max_age&id_token_hint=$id_token_hint";

    my $hybrid_response_type = uri_escape("code id_token token");
    my $hybrid_redirect_url  = $authorization_uri
      . "?response_type=$hybrid_response_type&client_id=$client_id&scope=$scope&redirect_uri=$redirect_uri&state=$state&nonce=$nonce&display=$display&prompt=$prompt&ui_locales=$ui_locales&login_hint=$login_hint&max_age=$max_age&id_token_hint=$id_token_hint";

    my $request_redirect_url = $authorization_uri
      . "?response_type=code&client_id=$client_id&request=$request&state=$state&scope=openid";
    my $request_uri_redirect_url = $authorization_uri
      . "?response_type=code&client_id=$client_id&request_uri=$request_uri&state=$state&scope=openid";

    print "<h2 class=\"text-center\">Authentication</h2>\n";
    print "<div class=\"text-center\">\n";
    print
"<a href=\"$redirect_url\" class=\"btn btn-info\" role=\"button\">Authorization Code Flow</a>\n";
    print
"<a href=\"$implicit_redirect_url\" class=\"btn btn-info\" role=\"button\">Implicit Flow</a>\n";
    print
"<a href=\"$hybrid_redirect_url\" class=\"btn btn-info\" role=\"button\">Hybrid Flow</a>\n";
    print
"<a href=\"$request_redirect_url\" class=\"btn btn-info\" role=\"button\">Authorization Code Flow with request</a>\n";
    print
"<a href=\"$request_uri_redirect_url\" class=\"btn btn-info\" role=\"button\">Authorization Code Flow with request_uri</a>\n";
    print "</div>\n";
    print "<h2 class=\"text-center\">Configuration</h2>\n";
    print "<div class=\"text-center\">\n";
    print
"<a href=\"$local_configuration_uri\" class=\"btn btn-success\" role=\"button\">Configuration discovery</a>\n";
    print "</div>\n";
    print "<h2 class=\"text-center\">Registration</h2>\n";
    print "<div class=\"text-center\">\n";
    print
"<a href=\"$local_registration_uri\" class=\"btn btn-success\" role=\"button\">Register a fake client</a>\n";
    print "</div>\n";

}

print "</div>\n";
print "</div>\n";

print $cgi->end_html();
exit 0;
