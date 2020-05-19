# NAME

Digi-ID implementation in Perl5

# DESCRIPTION

Perl5 implementation of \[Digi-ID\](https://www.digi-id.io/).

## Digi-ID Open Authentication Protocol

Pure DigiByte sites and applications shouldn't have to rely on artificial identification methods such as usernames and passwords. Digi-ID is an open authentication protocol allowing simple and secure authentication using public-key cryptography.

Classical password authentication is an insecure process that could be solved with public key cryptography. The problem however is that it theoretically offloads a lot of complexity and responsibility on the user. Managing private keys securely is complex. However this complexity is already addressed in the DigiByte ecosystem. So doing public key authentication is practically a free lunch to DigiByte users.

## The protocol is based on the following BIP draft

https://github.com/bitid/bitid/blob/master/BIP\_draft.md

# USAGE IN WEB APPLICATION

    use Dancer2;
    use DigiByte::DigiID qw(get_qrcode extract_nonce verify_signature);

    get '/login' => sub {
        template 'login' => {
            qrcode => {get_qrcode(request->host)},
        };
    };

    get '/callback' => sub {
       my $credential = from_json do { 
           my $input = request->env->{'psgi.input'};
           local $/; <$input>;
       } or halt "credential not found";

       my $nonce = extract_nonce($credential->{uri})
           or do { 
               status 403; 
               return "Nonce is missing";
           };

       eval { verify_signature(@$credential{qw(address signature uri)}) }
           or do { 
               status(403);
               return "Invalid credential, $@";
           };

       my $db = DB->schema; ## using dbix-lite for example

       my $user = $db->table('digiid_users')
           ->find({digiid => $credential->{address}})
           or do {
               status(403);
               return "digiid is not found: $credential->{address}";
           };

       $db->transaction(sub {
           $db->table('digiid_sessions')->insert({
               nonce      => $nonce,
               digiid     => $user->id,
               created_at => \'NOW()',
           });
       });

       return 'OK';
    };

    get '/ajax' => sub {
       content_type 'application/json';

       my $nonce = params->{nonce}
           or return to_json {ok => 0, error => 'missing nonce'};

       my $db = DB->schema; ## using dbix-lite for example

       my $session = $db->table('digiid_sessions')
           ->find({nonce => $nonce})
               or return to_json {ok => 0};

       my $user = $session->get_digiid_users->get_user
           or return to_json {ok => 0, next => 'scan to login in digibyte wallet'};

       $session->delete;

           return to_json {ok => 1};
    };

    dance;

# Demo

https://digibyteforums.io/ (Has a custom interface on top)

# Notes

\* Pure Perl5 implementation, no need to run a DigiByte node

# Credit

Direct Translation from PHP to Perl5 - https://github.com/DigiByte-Core/digiid-php/blob/master/DigiID.php
