package Langertha::Holmgang::Sim::Linux::Pki;
# ABSTRACT: Certificates and keys as data: openssl, update-ca-certificates, verification in the client

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use JSON::MaybeXS ();
use MIME::Base64 ();
use Time::Local ();

our $VERSION = '0.002';


my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub _L { require Langertha::Holmgang::Sim::Linux; return 'Langertha::Holmgang::Sim::Linux' }
sub _text { my ( $dev, $p ) = @_; return Langertha::Holmgang::Sim::Linux::_file_text( $dev, $p ) }

sub _gap { _L(); no warnings 'once'; push @Langertha::Holmgang::Sim::Linux::GAPS, join ' ', @_; return ( '', 0 ) }

# --- PEM ------------------------------------------------------------------------

my %LABEL = ( cert => 'CERTIFICATE', key => 'PRIVATE KEY', enckey => 'ENCRYPTED PRIVATE KEY',
    csr => 'CERTIFICATE REQUEST', pub => 'PUBLIC KEY', p7 => 'PKCS7' );


sub pem {
    my ( $kind, $id ) = @_;
    my $tag = $kind eq 'enckey' ? 'key' : $kind;
    my $b = MIME::Base64::encode_base64( "cai-sim-$tag:$id", '' );
    $b =~ s/(.{64})/$1\n/g;
    $b =~ s/\n\z//;
    return "-----BEGIN $LABEL{$kind}-----\n$b\n-----END $LABEL{$kind}-----\n";
}


sub blocks {
    my ($t) = @_;
    my @b;
    while ( ( $t // '' ) =~ /-----BEGIN ([A-Z0-9 ]+)-----\s*\n(.*?)\n?-----END \1-----/sg ) {
        my ( $label, $body ) = ( $1, $2 );
        my %rev = reverse %LABEL;
        my $kind = $rev{$label} // 'other';
        ( my $b64 = $body ) =~ s/\s+//g;
        my $raw = MIME::Base64::decode_base64($b64);
        my $block = "-----BEGIN $label-----\n$body\n-----END $label-----\n";
        if ( $raw =~ /\Acai-sim-(cert|key|csr|pub|p7):(.+)\z/s ) {
            my ( $tag, $id ) = ( $1, $2 );
            my $want = $kind eq 'enckey' ? 'key' : $kind;
            if ( $tag eq $want ) { push @b, { kind => $kind, id => $id, text => $block }; next }
        }
        push @b, { kind => 'bad', label => $label, text => $block };
    }
    return @b;
}

# --- Katalog --------------------------------------------------------------------


sub catalog {
    my ($state) = @_;
    my %c = ( certs => {}, keys => {}, now => undef );
    for my $h ( sort keys %{ $state || {} } ) {
        my $p = ref $state->{$h} eq 'HASH' ? $state->{$h}{pki} : undef;
        next unless ref $p eq 'HASH';
        %{ $c{certs} } = ( %{ $c{certs} }, %{ $p->{certs} || {} } );
        %{ $c{keys} }  = ( %{ $c{keys} },  %{ $p->{keys}  || {} } );
        $c{now} //= $p->{now};
    }
    $c{now} //= '2026-10-24T08:00:00Z';
    return \%c;
}

sub _epoch {
    my ($t) = @_;
    my ( $y, $m, $d, $H, $M, $S ) = ( $t // '' ) =~ /\A(\d{4})-(\d\d)-(\d\d)(?:[T ](\d\d):(\d\d)(?::(\d\d))?)?/ or return 0;
    return Time::Local::timegm( $S // 0, $M // 0, $H // 0, $d, $m - 1, $y );
}

my @MON = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

sub _odate {
    my ($t) = @_;
    my @g = gmtime( _epoch($t) );
    return sprintf( '%s %2d %02d:%02d:%02d %d GMT', $MON[ $g[4] ], $g[3], $g[2], $g[1], $g[0], $g[5] + 1900 );
}

sub _iso { my ($e) = @_; my @g = gmtime($e); return sprintf( '%04d-%02d-%02dT%02d:%02d:%02dZ', $g[5] + 1900, $g[4] + 1, @g[ 3, 2, 1, 0 ] ) }


sub dn {
    my ($s) = @_;
    return join ', ', map { my ( $k, $v ) = split /\s*=\s*/, $_, 2; "$k = " . ( $v // '' ) } grep {length} split /\s*,\s*(?=[A-Za-z]+\s*=)/, $s // '';
}

sub _cn { my ($s) = @_; return ( $s // '' ) =~ /(?:\A|,)\s*CN\s*=\s*([^,]+)/ ? $1 : undef }

sub _hex { my ( $id, $n, $sep ) = @_; my $h = uc Digest::SHA::sha512_hex("cai-sim:$id"); $h = substr( $h x 4, 0, $n ); return $sep ? join( ':', $h =~ /(..)/g ) : $h }


sub modulus { my ($key) = @_; return _hex( "mod:$key", 256 ) }

# --- Pruefung -------------------------------------------------------------------

our %ERR = (
    2  => 'unable to get issuer certificate', 9 => 'certificate is not yet valid', 10 => 'certificate has expired', 18 => 'self-signed certificate',
    19 => 'self-signed certificate in certificate chain', 20 => 'unable to get local issuer certificate',
    21 => 'unable to verify the first certificate', 24 => 'invalid CA certificate',
);


sub verify_chain {
    my ( $cat, $leaf, $inter, $trust ) = @_;
    my $now = _epoch( $cat->{now} );
    my %trust = map { $_ => 1 } @{ $trust || [] };
    my %inter = map { $_ => 1 } @{ $inter || [] };
    my ( $cur, $depth, $from_trust, %seen ) = ( $leaf, 0, 0 );
    while (1) {
        my $c = $cat->{certs}{$cur} or return { code => 20, depth => $depth, cert => $cur };
        return { code => 10, depth => $depth, cert => $cur } if _epoch( $c->{not_after} ) && $now > _epoch( $c->{not_after} );
        return { code => 9, depth => $depth, cert => $cur } if _epoch( $c->{not_before} ) && $now < _epoch( $c->{not_before} );
        my $iss = $c->{issuer} // $cur;
        if ( $iss eq $cur ) {    # selbst signiert: Anker nur, wenn vertraut
            return undef if $trust{$cur};
            return { code => $depth ? 19 : 18, depth => $depth, cert => $cur };
        }
        my $have = $trust{$iss} || $inter{$iss};
        return { code => $from_trust ? 2 : 20, depth => $depth, cert => $cur } unless $have && !$seen{$iss}++;
        my $ic = $cat->{certs}{$iss};
        return { code => 24, depth => $depth + 1, cert => $iss } if $ic && !$ic->{ca};
        ( $cur, $depth, $from_trust ) = ( $iss, $depth + 1, $trust{$iss} ? 1 : 0 );
    }
}


sub name_matches {
    my ( $c, $name ) = @_;
    $name = lc $name;
    my @n = @{ $c->{sans} || [] };
    @n = grep {defined} _cn( $c->{subject} ) unless @n;
    for my $s (@n) {
        ( my $x = lc $s ) =~ s/\A(?:DNS|IP(?: Address)?):\s*//i;
        return 1 if $x eq $name;
        if ( $x =~ /\A\*\.(.+)\z/ ) { my $d = $1; return 1 if $name =~ /\A[^.]+\.\Q$d\E\z/ }
    }
    return 0;
}


# Vertrauensspeicher eines Geraets (Client): trusted + installed, dazu von Hand
# an das Buendel /etc/ssl/certs/ca-certificates.crt Angehaengtes (wie echt,
# bis zum naechsten update-ca-certificates)
sub trust_of {
    my ($dev) = @_;
    my $p = ref $dev->{pki} eq 'HASH' ? $dev->{pki} : {};
    my $b = _text( $dev, '/etc/ssl/certs/ca-certificates.crt' );
    return [ @{ $p->{trusted} || [] }, @{ $p->{installed} || [] }, defined $b ? _cert_ids($b) : () ];
}

sub _cert_ids { my ($t) = @_; return map { $_->{id} } grep { $_->{kind} eq 'cert' } blocks($t) }


sub client_verify {
    my ( $state, $from, $tls, $req ) = @_;
    my $cat = catalog($state);
    my $dev = $state->{$from} || {};
    my @chain = @{ $tls->{chain} || [] };
    return [ 35, '(35) OpenSSL/3.0.15: error:0A000410:SSL routines::sslv3 alert handshake failure' ] unless @chain;
    my $trust = trust_of($dev);
    if ( defined $req->{cacert} ) {
        my $t = _text( $dev, $req->{cacert} );
        return [ 77, "(77) error setting certificate file: $req->{cacert}" ] unless defined $t;
        $trust = [ _cert_ids($t) ];
    }
    if ( my $e = verify_chain( $cat, $chain[0], [ @chain[ 1 .. $#chain ] ], $trust ) ) {
        return [ 60, "(60) SSL certificate problem: $ERR{ $e->{code} }" ];
    }
    my $host = $req->{host} // '';
    my $leaf = $cat->{certs}{ $chain[0] } || {};
    return [ 60, "(60) SSL: no alternative certificate subject name matches target host name '$host'" ]
        unless name_matches( $leaf, $host );
    return undef;
}


sub tls_lines {
    my ( $state, $tls ) = @_;
    my $cat = catalog($state);
    my $c = $cat->{certs}{ ( $tls->{chain} || [] )->[0] // '' } or return ();
    return ( "* SSL connection using $tls->{protocol} / " . ( $tls->{protocol} eq 'TLSv1.3' ? 'TLS_AES_256_GCM_SHA384' : 'ECDHE-RSA-AES256-GCM-SHA384' ),
        '* Server certificate:', '*  subject: ' . ( $c->{subject} // '' ) =~ s/,\s*/; /gr,
        '*  start date: ' . _odate( $c->{not_before} ), '*  expire date: ' . _odate( $c->{not_after} ),
        '*  subjectAltName: ' . join( ', ', @{ $c->{sans} || [] } ),
        '*  issuer: ' . ( $cat->{certs}{ $c->{issuer} // '' }{subject} // $c->{issuer} // '' ) =~ s/,\s*/; /gr );
}

# --- openssl --------------------------------------------------------------------

sub _opts {
    my ( $av, %spec ) = @_;    # spec: name => 1 (Wert folgt) | 0 (Schalter)
    my ( %o, @rest );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if ( $x =~ /\A--?([\w.:-]+)\z/ && exists $spec{$1} ) {
            my $k = $1;
            if ( $spec{$k} ) {
                return ( undef, "$k: Option requires an argument" ) unless @a;
                my $v = shift @a;
                if   ( $spec{$k} == 2 ) { push @{ $o{$k} }, $v }
                else                    { $o{$k} = $v }
            }
            else { $o{$k} = 1; push @{ $o{_order} }, $k }
            next;
        }
        if ( $x =~ /\A-/ ) { return ( undef, "Unknown option or message digest: " . substr( $x, 1 ) ) }
        push @rest, $x;
    }
    $o{_rest} = \@rest;
    return ( \%o );
}

sub _usage { my ( $cmd, $msg ) = @_; return ( "$cmd: $msg\n$cmd: Use -help for summary.", 0 ) }


sub openssl {
    my ( $dev, $av, $ctx, $stdin ) = @_;
    my @a = @$av;
    my $sub = shift(@a) // return _gap('openssl (interaktiv)');
    my $state = $ctx->{state} || { $ctx->{host} => $dev };
    my %f = (
        x509 => \&_x509, rsa => \&_pkey, pkey => \&_pkey, verify => \&_verify, s_client => \&_s_client,
        crl2pkcs7 => \&_crl2pkcs7, pkcs7 => \&_pkcs7, req => \&_req, dgst => \&_dgst, sha256 => \&_dgst,
        sha1 => \&_dgst, md5 => \&_dgst, version => sub { ( 'OpenSSL 3.0.15 3 Sep 2024 (Library: OpenSSL 3.0.15 3 Sep 2024)', 1 ) },
    );
    my $fn = $f{$sub} or return $sub =~ /\A(?:genrsa|genpkey|ecparam|pkcs12|ca|x509v3|storeutl|ocsp|rand|enc|base64|list|s_server|speed)\z/
        ? _gap( 'openssl', $sub, @a )
        : ( "Invalid command '$sub'; type \"help\" for a list.", 0 );
    return $fn->( $dev, \@a, $ctx, $stdin, $state, $sub );
}

sub _read_in {
    my ( $dev, $o, $stdin, $what ) = @_;
    if ( defined $o->{in} ) {
        my $t = _text( $dev, $o->{in} );
        return ( undef, "Could not open file or uri for loading $what from $o->{in}: No such file or directory" ) unless defined $t;
        return ($t);
    }
    return ( $stdin // '' );
}

sub _x509 {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, in => 1, inform => 1, outform => 1, out => 1, checkend => 1, ext => 1, noout => 0, subject => 0,
        issuer => 0, dates => 0, startdate => 0, enddate => 0, serial => 0, fingerprint => 0, sha256 => 0, sha1 => 0,
        md5 => 0, text => 0, modulus => 0, pubkey => 0, subject_hash => 0, issuer_hash => 0, nameopt => 1, purpose => 0,
        email => 0, hash => 0, ocsp_uri => 0 );
    return _usage( 'x509', $e ) unless $o;
    my ( $t, $err ) = _read_in( $dev, $o, $stdin, 'certificate' );
    return ( $err, 0 ) unless defined $t;
    my ($b) = grep { $_->{kind} eq 'cert' || $_->{kind} eq 'bad' } blocks($t);
    my $cat = catalog($state);
    my $c = $b && $b->{kind} eq 'cert' ? $cat->{certs}{ $b->{id} } : undef;
    return ( 'Could not read certificate from ' . ( $o->{in} // '<stdin>' ) . "\nUnable to load certificate", 0 ) unless $c;
    my $id = $b->{id};
    my @out;
    my $alg = $o->{sha256} ? 'sha256' : $o->{md5} ? 'md5' : 'sha1';
    for my $k ( @{ $o->{_order} || [] } ) {
        if    ( $k eq 'subject' ) { push @out, 'subject=' . dn( $c->{subject} ) }
        elsif ( $k eq 'issuer' )  { push @out, 'issuer=' . dn( ( $cat->{certs}{ $c->{issuer} // '' } || $c )->{subject} ) }
        elsif ( $k eq 'dates' )   { push @out, 'notBefore=' . _odate( $c->{not_before} ), 'notAfter=' . _odate( $c->{not_after} ) }
        elsif ( $k eq 'startdate' ) { push @out, 'notBefore=' . _odate( $c->{not_before} ) }
        elsif ( $k eq 'enddate' )   { push @out, 'notAfter=' . _odate( $c->{not_after} ) }
        elsif ( $k eq 'serial' )    { push @out, 'serial=' . ( $c->{serial} // _hex( "serial:$id", 32 ) ) }
        elsif ( $k eq 'fingerprint' ) {
            push @out, uc($alg) . ' Fingerprint=' . _hex( "fp-$alg:$id", $alg eq 'sha256' ? 64 : $alg eq 'md5' ? 32 : 40, 1 );
        }
        elsif ( $k eq 'modulus' ) { push @out, 'Modulus=' . modulus( $c->{key} // $id ) }
        elsif ( $k eq 'pubkey' )  { push @out, pem( pub => $c->{key} // $id ) =~ s/\n\z//r }
        elsif ( $k eq 'subject_hash' || $k eq 'hash' ) { push @out, lc _hex( "sh:" . ( $c->{subject} // '' ), 8 ) }
        elsif ( $k eq 'issuer_hash' ) { push @out, lc _hex( "sh:" . ( ( $cat->{certs}{ $c->{issuer} // '' } || $c )->{subject} // '' ), 8 ) }
        elsif ( $k eq 'text' )    { push @out, _x509_text( $cat, $id, $c ) }
        elsif ( $k eq 'purpose' ) { push @out, 'Certificate purposes:', 'SSL client : Yes', 'SSL server : ' . ( $c->{ca} ? 'No' : 'Yes' ) }
        elsif ( $k eq 'ocsp_uri' ) { push @out, 'http://ocsp.example.net' }
    }
    if ( defined $o->{ext} ) {
        for my $x ( split /,/, $o->{ext} ) {
            if ( $x eq 'subjectAltName' ) {
                push @out, 'X509v3 Subject Alternative Name: ', '    ' . join( ', ', map { /\A(?:DNS|IP)/ ? $_ : "DNS:$_" } @{ $c->{sans} || [] } )
                    if @{ $c->{sans} || [] };
            }
            elsif ( $x eq 'basicConstraints' ) { push @out, 'X509v3 Basic Constraints: critical', '    CA:' . ( $c->{ca} ? 'TRUE' : 'FALSE' ) }
            else { push @out, "No extensions matched with -ext $x" if 0 }
        }
    }
    my $ok = 1;
    if ( defined $o->{checkend} ) {
        my $exp = _epoch( $c->{not_after} ) <= _epoch( $cat->{now} ) + ( $o->{checkend} =~ /\A\d+\z/ ? $o->{checkend} : 0 );
        push @out, $exp ? 'Certificate will expire' : 'Certificate will not expire';
        $ok = $exp ? 0 : 1;
    }
    if ( !$o->{noout} ) {
        if ( defined $o->{out} ) {
            my ( $we, $wok ) = Langertha::Holmgang::Sim::Linux::_write_path( $dev, $o->{out}, pem( cert => $id ), 0, $ctx );
            return ( $we, 0 ) unless $wok;
        }
        else { push @out, pem( cert => $id ) =~ s/\n\z//r }
    }
    return ( join( "\n", @out ), $ok );
}

sub _x509_text {
    my ( $cat, $id, $c ) = @_;
    my $iss = ( $cat->{certs}{ $c->{issuer} // '' } || $c )->{subject};
    my $bits = ( $cat->{keys}{ $c->{key} // '' } || {} )->{bits} // 2048;
    my @l = ( 'Certificate:', '    Data:', '        Version: 3 (0x2)', '        Serial Number:',
        '            ' . lc join( ':', ( $c->{serial} // _hex( "serial:$id", 32 ) ) =~ /(..)/g ),
        '        Signature Algorithm: sha256WithRSAEncryption', '        Issuer: ' . dn($iss), '        Validity',
        '            Not Before: ' . _odate( $c->{not_before} ), '            Not After : ' . _odate( $c->{not_after} ),
        '        Subject: ' . dn( $c->{subject} ), '        Subject Public Key Info:',
        '            Public Key Algorithm: rsaEncryption', "                Public-Key: ($bits bit)",
        '        X509v3 extensions:', '            X509v3 Basic Constraints: critical',
        '                CA:' . ( $c->{ca} ? 'TRUE' : 'FALSE' ) );
    push @l, '            X509v3 Subject Alternative Name: ',
        '                ' . join( ', ', map { /\A(?:DNS|IP)/ ? $_ : "DNS:$_" } @{ $c->{sans} } ) if @{ $c->{sans} || [] };
    push @l, '    Signature Algorithm: sha256WithRSAEncryption';
    return @l;
}

# Passphrase aus -passin
sub _pass {
    my ( $dev, $spec ) = @_;
    return undef unless defined $spec;
    return $1 if $spec =~ /\Apass:(.*)\z/s;
    if ( $spec =~ /\Afile:(.+)\z/ ) { my $t = _text( $dev, $1 ); return defined $t ? ( split /\n/, $t )[0] // '' : undef }
    return undef;
}

# Schluessel aus Text: ( key-id, fehler )
sub _load_key {
    my ( $cat, $dev, $t, $passin, $path ) = @_;
    my ($b) = grep { $_->{kind} eq 'key' || $_->{kind} eq 'enckey' } blocks($t);
    return ( undef, "Could not read private key from $path" ) unless $b && $cat->{keys}{ $b->{id} };
    if ( $b->{kind} eq 'enckey' ) {
        my $want = $cat->{keys}{ $b->{id} }{passphrase} // '';
        my $p = _pass( $dev, $passin );
        return ( undef, "Enter pass phrase for $path:\nCould not read private key from $path" ) unless defined $p;
        return ( undef, "Could not read private key from $path" ) unless $p eq $want;
    }
    return ( $b->{id} );
}

sub _pkey {
    my ( $dev, $av, $ctx, $stdin, $state, $cmd ) = @_;
    my ( $o, $e ) = _opts( $av, in => 1, out => 1, passin => 1, passout => 1, inform => 1, outform => 1, noout => 0,
        modulus => 0, check => 0, text => 0, pubout => 0, pubin => 0, aes256 => 0, des3 => 0, traditional => 0 );
    return _usage( $cmd, $e ) unless $o;
    my ( $t, $err ) = _read_in( $dev, $o, $stdin, 'private key' );
    return ( $err, 0 ) unless defined $t;
    my $cat = catalog($state);
    my $path = $o->{in} // '<stdin>';
    if ( $o->{pubin} ) {
        my ($b) = grep { $_->{kind} eq 'pub' } blocks($t);
        return ( "Could not read public key from $path", 0 ) unless $b;
        return ( join( "\n", $o->{modulus} ? 'Modulus=' . modulus( $b->{id} ) : (), $o->{noout} ? () : pem( pub => $b->{id} ) =~ s/\n\z//r ), 1 );
    }
    my ( $id, $kerr ) = _load_key( $cat, $dev, $t, $o->{passin}, $path );
    return ( $kerr, 0 ) unless defined $id;
    my $k = $cat->{keys}{$id} || {};
    my @out;
    push @out, 'Modulus=' . modulus($id) if $o->{modulus};
    push @out, $cmd eq 'rsa' ? 'RSA key ok' : 'Key is valid' if $o->{check};
    push @out, 'Private-Key: (' . ( $k->{bits} // 2048 ) . ' bit, 2 primes)', 'modulus:', '    ' . lc( substr( modulus($id), 0, 48 ) =~ s/(..)(?=.)/$1:/gr ) . ':...' if $o->{text};
    if ( !$o->{noout} ) {
        my $text = $o->{pubout} ? pem( pub => $id ) : pem( ( $o->{aes256} || $o->{des3} ) ? 'enckey' : 'key', $id );
        if ( defined $o->{out} ) {
            my ( $we, $wok ) = _write_key( $dev, $o->{out}, $text, $ctx, !$o->{pubout} );
            return ( $we, 0 ) unless $wok;
            push @out, 'writing RSA key' if $cmd eq 'rsa';
        }
        else { push @out, 'writing RSA key' x !!( $cmd eq 'rsa' ), $text =~ s/\n\z//r }
    }
    return ( join( "\n", grep {length} @out ), 1 );
}

# Private Schluessel schreibt OpenSSL 3 neu mit 0600 (bio_open_owner)
sub _write_key {
    my ( $dev, $path, $text, $ctx, $private ) = @_;
    my $new = !Langertha::Holmgang::Sim::Linux::_file_entry( $dev, $path );
    my ( $e, $ok ) = Langertha::Holmgang::Sim::Linux::_write_path( $dev, $path, $text, 0, $ctx );
    return ( $e, $ok ) unless $ok && $private && $new;
    $dev->{files}{$path} = { content => $text, owner => 'root', group => 'root', mode => '0600' };
    return ( $e, $ok );
}

sub _verify {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, CAfile => 1, untrusted => 2, CApath => 1, purpose => 1, verbose => 0, show_chain => 0,
        no_check_time => 0, partial_chain => 0, verify_hostname => 1, x509_strict => 0, 'no-CAfile' => 0, 'no-CApath' => 0 );
    return _usage( 'verify', $e ) unless $o;
    my $cat = catalog($state);
    my $trust = trust_of($dev);
    if ( defined $o->{CAfile} ) {
        my $t = _text( $dev, $o->{CAfile} ) // return ( "Error loading file $o->{CAfile}", 0 );
        $trust = [ $o->{'no-CAfile'} ? () : (), _cert_ids($t) ];
    }
    my @inter = map { my $t = _text( $dev, $_ ); defined $t ? _cert_ids($t) : () } @{ $o->{untrusted} || [] };
    my @files = @{ $o->{_rest} };
    @files = ('stdin') unless @files;
    my @out;
    my $ok = 1;
    for my $f (@files) {
        my $t = $f eq 'stdin' ? $stdin // '' : _text( $dev, $f );
        if ( !defined $t ) { push @out, "Could not open file or uri for loading certificate from $f: No such file or directory"; $ok = 0; next }
        my ($id) = _cert_ids($t);
        if ( !defined $id || !$cat->{certs}{$id} ) { push @out, "Could not read certificate from $f", 'Unable to load certificate'; $ok = 0; next }
        if ( my $r = verify_chain( $cat, $id, \@inter, $trust ) ) {
            my $c = $cat->{certs}{ $r->{cert} } || {};
            push @out, dn( $c->{subject} // '' ), "error $r->{code} at $r->{depth} depth lookup: $ERR{ $r->{code} }", "error $f: verification failed";
            $ok = 0;
        }
        else { push @out, "$f: OK" }
    }
    return ( join( "\n", @out ), $ok );
}

sub _s_client {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, connect => 1, servername => 1, CAfile => 1, cert => 1, key => 1, showcerts => 0, brief => 0,
        tls1 => 0, tls1_1 => 0, tls1_2 => 0, tls1_3 => 0, quiet => 0, verify_return_error => 0, verify => 1, state => 0,
        debug => 0, status => 0, crlf => 0, ign_eof => 0, no_ign_eof => 0, alpn => 1, noservername => 0, verify_hostname => 1,
        starttls => 1, prexit => 0, msg => 0 );
    return _usage( 's_client', $e ) unless $o;
    my $c = $o->{connect} // $o->{_rest}[0] // 'localhost:443';
    my ( $host, $port ) = $c =~ /\A\[?([^\]]+?)\]?(?::(\d+))?\z/;
    $port //= 443;
    my ($ver) = map { { tls1 => 'TLSv1', tls1_1 => 'TLSv1.1', tls1_2 => 'TLSv1.2', tls1_3 => 'TLSv1.3' }->{$_} } grep { $o->{$_} } qw( tls1 tls1_1 tls1_2 tls1_3 );
    require Langertha::Holmgang::Sim::Linux::Http;
    my $sni = $o->{noservername} ? undef : $o->{servername} // ( $host =~ /\A[\d.]+\z/ ? undef : $host );
    my $res = Langertha::Holmgang::Sim::Linux::Http::request( $state, $ctx->{host}, {
        url => "https://$host:$port/", method => 'HEAD', insecure => 1, tls_version => $ver,
        headers => { host => $sni // $host }, ( defined $sni ? ( sni => $sni ) : () ),
        ( defined $o->{cert} ? ( cert => $o->{cert}, key => $o->{key} // $o->{cert} ) : () ),
    } );
    if ( defined $res->{error} ) {
        return ( "40F7B3E1B17F0000:error:8000006F:system library:BIO_connect:Connection refused:../crypto/bio/bio_sock2.c:114:calling connect()\nconnect:errno=111", 1 )
            if ( $res->{code} // 0 ) == 7;
        return ( "40F7B3E1B17F0000:error:10080002:BIO routines:BIO_lookup_ex:system lib:../crypto/bio/bio_sock.c:457:\nconnect:errno=0", 1 )
            if ( $res->{code} // 0 ) == 6;
        return ( "CONNECTED(00000003)\n40F7B3E1B17F0000:error:0A00010B:SSL routines:ssl3_get_record:wrong version number:../ssl/record/ssl3_record.c:354:\n---\nno peer certificate available\n---", 1 )
            if ( $res->{code} // 0 ) == 35 && $res->{error} =~ /wrong version/;
        return ( "CONNECTED(00000003)\n40F7B3E1B17F0000:error:0A00042E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version:../ssl/record/rec_layer_s3.c:1584:SSL alert number 70\n---\nno peer certificate available\n---\nNo client certificate CA names sent\n---", 1 )
            if ( $res->{code} // 0 ) == 35;
        return ( "CONNECTED(00000003)\n$res->{error}", 1 );
    }
    my $tls = $res->{tls} or return ( 'CONNECTED(00000003)', 1 );
    my $cat = catalog($state);
    my @chain = @{ $tls->{chain} || [] };
    my $trust = trust_of($dev);
    if ( defined $o->{CAfile} ) { my $t = _text( $dev, $o->{CAfile} ); $trust = [ defined $t ? _cert_ids($t) : () ] }
    my $r = @chain ? verify_chain( $cat, $chain[0], [ @chain[ 1 .. $#chain ] ], $trust ) : { code => 20, depth => 0 };
    my @l = ('CONNECTED(00000003)');
    my $subj = sub { dn( ( $cat->{certs}{ $_[0] } || {} )->{subject} ) };
    my $issu = sub { my $x = $cat->{certs}{ $_[0] } || {}; dn( ( $cat->{certs}{ $x->{issuer} // '' } || {} )->{subject} // $x->{issuer} ) };
    if ($r) {
        for ( my $d = $r->{depth}; $d >= 0; $d-- ) {
            my $id = $chain[$d] // $r->{cert};
            push @l, "depth=$d " . $subj->($id);
            push @l, "verify error:num=$r->{code}:$ERR{$r->{code}}" if $d == $r->{depth};
            push @l, 'verify error:num=21:unable to verify the first certificate' if $d == 0 && $r->{code} == 20 && $r->{depth} == 0;
            push @l, 'verify return:1';
        }
    }
    else {
        my $n = $#chain;
        for ( my $d = $n + 1; $d >= 0; $d-- ) {
            my $id = $d <= $n ? $chain[$d] : ( $cat->{certs}{ $chain[$n] } || {} )->{issuer};
            next unless defined $id && $cat->{certs}{$id};
            next if $d == $n + 1 && $id eq $chain[$n];
            push @l, "depth=$d " . $subj->($id), 'verify return:1';
        }
    }
    push @l, '---', 'Certificate chain';
    for my $i ( 0 .. $#chain ) {
        my $x = $cat->{certs}{ $chain[$i] } || {};
        push @l, " $i s:" . $subj->( $chain[$i] ), '   i:' . $issu->( $chain[$i] ),
            '   a:PKEY: rsaEncryption, ' . ( ( $cat->{keys}{ $x->{key} // '' } || {} )->{bits} // 2048 ) . ' (bit); sigalg: RSA-SHA256',
            '   v:NotBefore: ' . _odate( $x->{not_before} ) . '; NotAfter: ' . _odate( $x->{not_after} );
        push @l, pem( cert => $chain[$i] ) =~ s/\n\z//r if $o->{showcerts};
    }
    push @l, '---', 'Server certificate';
    push @l, pem( cert => $chain[0] ) =~ s/\n\z//r unless $o->{showcerts};
    push @l, 'subject=' . $subj->( $chain[0] ), 'issuer=' . $issu->( $chain[0] ), '---';
    push @l, $tls->{client_ca} ? ( 'Acceptable client certificate CA names', map { $subj->($_) } @{ $tls->{client_ca} } ) : 'No client certificate CA names sent';
    my $code = $r ? ( $r->{code} == 20 && $r->{depth} == 0 ? 21 : $r->{code} ) : 0;
    my $msg = $r ? $ERR{$code} : 'ok';
    push @l, '---', 'SSL handshake has read 4352 bytes and written 393 bytes',
        $r ? "Verification error: $msg" : 'Verification: OK', '---',
        "New, $tls->{protocol}, Cipher is " . ( $tls->{protocol} eq 'TLSv1.3' ? 'TLS_AES_256_GCM_SHA384' : 'ECDHE-RSA-AES256-GCM-SHA384' ),
        'Server public key is 2048 bit', 'Secure Renegotiation IS NOT supported', 'Compression: NONE', 'Expansion: NONE',
        'No ALPN negotiated', 'Early data was not sent', "Verify return code: $code ($msg)", '---', 'DONE';
    return ( join( "\n", @l ), 1 );
}

sub _crl2pkcs7 {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, nocrl => 0, certfile => 2, out => 1, outform => 1, in => 1 );
    return _usage( 'crl2pkcs7', $e ) unless $o;
    my @ids;
    for my $f ( @{ $o->{certfile} || [] } ) {
        my $t = _text( $dev, $f ) // return ( "Could not open file or uri for loading certificates from $f: No such file or directory", 0 );
        push @ids, _cert_ids($t);
    }
    my $p = pem( p7 => join( ',', @ids ) );
    return ( $p =~ s/\n\z//r, 1 );
}

sub _pkcs7 {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, in => 1, inform => 1, print_certs => 0, noout => 0, text => 0, print => 0 );
    return _usage( 'pkcs7', $e ) unless $o;
    my ( $t, $err ) = _read_in( $dev, $o, $stdin, 'PKCS7' );
    return ( $err, 0 ) unless defined $t;
    my ($b) = grep { $_->{kind} eq 'p7' } blocks($t);
    return ( 'Could not read PKCS7 from ' . ( $o->{in} // '<stdin>' ) . "\nUnable to load PKCS7 object", 0 ) unless $b;
    my $cat = catalog($state);
    my @l;
    for my $id ( split /,/, $b->{id} ) {
        my $c = $cat->{certs}{$id} or next;
        push @l, 'subject=' . dn( $c->{subject} ), 'issuer=' . dn( ( $cat->{certs}{ $c->{issuer} // '' } || $c )->{subject} );
        push @l, pem( cert => $id ) =~ s/\n\z//r unless $o->{noout};
        push @l, '';
    }
    pop @l if @l && $l[-1] eq '';
    return ( join( "\n", @l ), 1 );
}

sub _dgst {
    my ( $dev, $av, $ctx, $stdin, $state, $cmd ) = @_;
    my @a = @$av;
    my $alg = $cmd eq 'dgst' ? 'sha256' : $cmd;
    my @files;
    for (@a) { if (/\A-(sha256|sha1|md5|sha512)\z/) { $alg = $1 } elsif ( !/\A-/ ) { push @files, $_ } }
    my @out;
    for my $f ( @files ? @files : (undef) ) {
        my $t = defined $f ? _text( $dev, $f ) : $stdin // '';
        return ( "Can't open \"$f\" for reading, No such file or directory", 0 ) unless defined $t;
        my $h = $alg eq 'md5' ? do { require Digest::MD5; Digest::MD5::md5_hex($t) } : Digest::SHA->can("${alg}_hex")->( _enc_bytes($t) );
        push @out, uc( $alg eq 'sha256' ? 'SHA2-256' : $alg eq 'sha512' ? 'SHA2-512' : $alg ) . '(' . ( $f // 'stdin' ) . ")= $h";
    }
    return ( join( "\n", @out ), 1 );
}

sub _enc_bytes { my ($t) = @_; utf8::encode($t) if utf8::is_utf8($t); return $t }

# --- req (CSR, selbst signiert) -------------------------------------------------

sub _subj {
    my ($s) = @_;
    return undef unless defined $s;
    $s =~ s{\A/}{};
    my @p = grep {length} split m{(?<!\\)/}, $s;
    return join ',', map { my ( $k, $v ) = split /=/, $_, 2; "$k=" . ( $v // '' ) } @p;
}

sub _sans_from {
    my ($v) = @_;
    return () unless defined $v;
    $v =~ s/\A\s*subjectAltName\s*=\s*//;
    return map { s/\A\s+|\s+\z//gr } grep {/\S/} split /,/, $v;
}

# openssl.cnf: [req] distinguished_name, req_extensions, x509_extensions, prompt
sub _cnf {
    my ($t) = @_;
    my ( %s, $cur );
    $cur = '';
    for my $l ( split /\n/, $t // '' ) {
        $l =~ s/#.*//;
        next unless $l =~ /\S/;
        if ( $l =~ /^\s*\[\s*([^\]\s]+)\s*\]/ ) { $cur = $1; next }
        my ( $k, $v ) = $l =~ /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ or next;
        push @{ $s{$cur} }, [ $k, $v ];
    }
    return \%s;
}

sub _cnf_get { my ( $c, $sec, $k ) = @_; for ( @{ $c->{$sec} || [] } ) { return $_->[1] if $_->[0] eq $k } return undef }

sub _cnf_sans {
    my ( $c, $sec ) = @_;
    my $v = _cnf_get( $c, $sec, 'subjectAltName' ) // return ();
    if ( $v =~ /\A\@(\S+)\z/ ) { return map { my ( $t, undef ) = split /\./, $_->[0]; "$t:$_->[1]" } @{ $c->{$1} || [] } }
    return _sans_from($v);
}

sub _canon_csr {
    my (%c) = @_;
    my %seen;
    my @sans = sort grep { !$seen{$_}++ } map { /\A(?:DNS|IP|email|URI):/ ? $_ : "DNS:$_" } @{ $c{sans} || [] };
    my %dn = map { my ( $k, $v ) = split /=/, $_, 2; ( $k => $v ) } grep {length} split /,(?=[A-Za-z]+=)/, $c{subject} // '';
    return $JSON->encode( { subject => \%dn, sans => \@sans, key => $c{key} } );
}

sub _csr_pem { my ($json) = @_; my $b = MIME::Base64::encode_base64( "cai-sim-csr:$json", '' ); $b =~ s/(.{64})/$1\n/g; $b =~ s/\n\z//; return "-----BEGIN CERTIFICATE REQUEST-----\n$b\n-----END CERTIFICATE REQUEST-----\n" }


sub csr_pem_for { my (%c) = @_; return _csr_pem( _canon_csr(%c) ) }

sub _dn_from_hash { my ($h) = @_; my @o = qw( C ST L O OU CN emailAddress ); my %k = map { $_ => 1 } @o; return join ',', map {"$_=$h->{$_}"} ( grep { exists $h->{$_} } @o ), sort grep { !$k{$_} } keys %$h }

sub _req {
    my ( $dev, $av, $ctx, $stdin, $state ) = @_;
    my ( $o, $e ) = _opts( $av, new => 0, x509 => 0, key => 1, newkey => 1, nodes => 0, noenc => 0, keyout => 1, out => 1,
        in => 1, subj => 1, addext => 2, config => 1, reqexts => 1, extensions => 1, days => 1, sha256 => 0, sha384 => 0,
        noout => 0, text => 0, subject => 0, verify => 0, passin => 1, passout => 1, batch => 0, utf8 => 0, set_serial => 1 );
    return _usage( 'req', $e ) unless $o;
    my $cat = catalog($state);
    my $p = $dev->{pki} //= {};
    if ( !$o->{new} && !$o->{x509} ) {    # CSR lesen
        my ( $t, $err ) = _read_in( $dev, $o, $stdin, 'certificate request' );
        return ( $err, 0 ) unless defined $t;
        my ($b) = grep { $_->{kind} eq 'csr' } blocks($t);
        return ( 'Unable to load X509 request', 0 ) unless $b;
        my $c = eval { $JSON->decode( _enc_bytes( $b->{id} ) ) } or return ( 'Unable to load X509 request', 0 );
        my @l;
        push @l, 'Certificate request self-signature verify OK' if $o->{verify};
        push @l, 'subject=' . dn( _dn_from_hash( $c->{subject} ) ) if $o->{subject};
        push @l, 'Certificate Request:', '    Data:', '        Version: 1 (0x0)', '        Subject: ' . dn( _dn_from_hash( $c->{subject} ) ),
            '        Subject Public Key Info:', '            Public Key Algorithm: rsaEncryption',
            '                Public-Key: (' . ( ( $cat->{keys}{ $c->{key} // '' } || {} )->{bits} // 2048 ) . ' bit)',
            '        Attributes:', '            Requested Extensions:',
            ( @{ $c->{sans} } ? ( '                X509v3 Subject Alternative Name: ', '                    ' . join( ', ', @{ $c->{sans} } ) ) : () ),
            '    Signature Algorithm: sha256WithRSAEncryption' if $o->{text};
        push @l, $b->{text} =~ s/\n\z//r unless $o->{noout};
        return ( join( "\n", @l ), 1 );
    }
    # Schluessel
    my $key;
    if ( defined $o->{key} ) {
        my $t = _text( $dev, $o->{key} ) // return ( "Could not open file or uri for loading private key from $o->{key}: No such file or directory", 0 );
        ( $key, my $kerr ) = _load_key( $cat, $dev, $t, $o->{passin}, $o->{key} );
        return ( $kerr, 0 ) unless defined $key;
    }
    elsif ( defined $o->{newkey} ) {
        my ($bits) = $o->{newkey} =~ /\Arsa:(\d+)\z/ or return _gap( 'openssl req -newkey', $o->{newkey} );
        my $n = 1 + scalar grep {/\Agen-key-/} keys %{ $p->{keys} || {} };
        $key = "gen-key-$n";
        $p->{keys}{$key} = { bits => 0 + $bits };
        return _gap('openssl req -newkey ohne -nodes (Passphrase interaktiv)') unless $o->{nodes} || $o->{noenc} || defined $o->{passout};
        my $kout = $o->{keyout} // 'privkey.pem';
        $kout = "/root/$kout" unless $kout =~ m{\A/};
        my ( $we, $wok ) = _write_key( $dev, $kout, pem( key => $key ), $ctx, 1 );
        return ( $we, 0 ) unless $wok;
    }
    else { return _gap('openssl req ohne -key/-newkey') }
    # Subjekt und Namen
    my $cnf = defined $o->{config} ? _cnf( _text( $dev, $o->{config} ) // return ( "Can't open \"$o->{config}\" for reading, No such file or directory", 0 ) ) : {};
    my $subject = _subj( $o->{subj} );
    if ( !defined $subject && defined $o->{config} ) {
        my $dsec = _cnf_get( $cnf, 'req', 'distinguished_name' );
        if ( defined $dsec && ( _cnf_get( $cnf, 'req', 'prompt' ) // '' ) eq 'no' ) {
            $subject = join ',', map {"$_->[0]=$_->[1]"} @{ $cnf->{$dsec} || [] };
        }
    }
    return _gap('openssl req (interaktive Abfrage des Subjekts)') unless defined $subject;
    my @sans = map { _sans_from($_) } grep {/\A\s*subjectAltName\s*=/} @{ $o->{addext} || [] };
    if ( defined $o->{config} ) {
        my $xsec = $o->{x509} ? ( $o->{extensions} // _cnf_get( $cnf, 'req', 'x509_extensions' ) ) : ( $o->{reqexts} // _cnf_get( $cnf, 'req', 'req_extensions' ) );
        push @sans, _cnf_sans( $cnf, $xsec ) if defined $xsec;
    }
    my $out = $o->{out};
    if ( $o->{x509} ) {
        my $n = 1 + scalar grep {/\Agen-cert-/} keys %{ $p->{certs} || {} };
        my $id = "gen-cert-$n";
        my $now = _epoch( $cat->{now} );
        my %seen;
        $p->{certs}{$id} = { subject => $subject, sans => [ grep { !$seen{$_}++ } map { s/\ADNS://r } @sans ], issuer => $id, ca => 1, key => $key,
            not_before => _iso($now), not_after => _iso( $now + 86400 * ( $o->{days} && $o->{days} =~ /\A\d+\z/ ? $o->{days} : 30 ) ) };
        my $text = pem( cert => $id );
        return ( $text =~ s/\n\z//r, 1 ) unless defined $out;
        my ( $we, $wok ) = Langertha::Holmgang::Sim::Linux::_write_path( $dev, $out, $text, 0, $ctx );
        return ( $we, $wok );
    }
    my $text = _csr_pem( _canon_csr( subject => $subject, sans => \@sans, key => $key ) );
    return ( $text =~ s/\n\z//r, 1 ) unless defined $out;
    my ( $we, $wok ) = Langertha::Holmgang::Sim::Linux::_write_path( $dev, $out, $text, 0, $ctx );
    return ( $we, $wok );
}

# --- update-ca-certificates -----------------------------------------------------


sub update_ca_certificates {
    my ( $dev, $av, $ctx ) = @_;
    my $p = $dev->{pki} //= {};
    my @old = @{ $p->{installed} || [] };
    my @new;
    for my $f ( Langertha::Holmgang::Sim::Linux::_under( $dev, '/usr/local/share/ca-certificates' ) ) {
        next unless $f =~ /\.crt\z/;
        push @new, _cert_ids( _text( $dev, $f ) // '' );
    }
    my %o = map { $_ => 1 } @old;
    my %n = map { $_ => 1 } @new;
    my $add = grep { !$o{$_} } keys %n;
    my $rem = grep { !$n{$_} } keys %o;
    my @sorted = sort keys %n;
    if ( join( ',', @sorted ) ne join( ',', sort @old ) ) {
        if   (@sorted) { $p->{installed} = \@sorted }
        else           { delete $p->{installed} }
    }
    # das Buendel wird neu geschrieben: von Hand Angehaengtes faellt heraus
    my $bundle = '/etc/ssl/certs/ca-certificates.crt';
    if ( Langertha::Holmgang::Sim::Linux::_file_entry( $dev, $bundle ) ) {
        my $t = join '', map { pem( cert => $_ ) } @{ $p->{trusted} || [] }, @sorted;
        Langertha::Holmgang::Sim::Linux::_file_set( $dev, $bundle, $t ) if $t ne ( _text( $dev, $bundle ) // '' );
    }
    return ( "Updating certificates in /etc/ssl/certs...\n$add added, $rem removed; done.\nRunning hooks in /etc/ca-certificates/update.d...\ndone.", 1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Pki - Certificates and keys as data: openssl, update-ca-certificates, verification in the client

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Pki::openssl( $dev, \@argv, $ctx, $stdin );
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Pki::update_ca_certificates( $dev, \@argv, $ctx );

  # for case authors: PEM text of a certificate or key
  my $pem = Langertha::Holmgang::Sim::Linux::Pki::pem( cert => 'shop-2026' );

=head1 DESCRIPTION

Certificates are B<data in the state>; their PEM text in files only refers to
them (cai-platform F<docs/entwurf-evals.md> §3.3). The catalog lives under C<pki> of one
or more devices (merged):

  pki:
    now: "2026-10-24T08:00:00Z"             # time for validity
    certs:
      shop-2026: { subject: "CN=shop.example.com", sans: [shop.example.com, www.shop.example.com],
                   issuer: int-r3, not_before: "2026-09-01T00:00:00Z", not_after: "2026-11-30T00:00:00Z",
                   key: k-shop-2026, serial: "04A1…" }
      int-r3:    { subject: "C=US,O=Example Trust,CN=Example R3", issuer: root-x1, ca: true, key: k-int, … }
      root-x1:   { subject: "C=US,O=Example Trust,CN=Example Root X1", issuer: root-x1, ca: true, … }
    keys:   { k-shop-2026: { bits: 2048, passphrase: "…" } }   # passphrase: only for encrypted files
    trusted: [ root-x1 ]                      # trust store of this device (client)
    installed: [ … ]                          # by the simulator: installed via update-ca-certificates

A PEM block carries C<base64("cai-sim-cert:<id>")> as its body (or C<key>,
encrypted in an C<ENCRYPTED PRIVATE KEY> block); files stay text, C<cat
a b E<gt> chain> works as for real. CSRs carry their content (subject, names,
key) canonically in the block. Self-generated certificates and keys
(C<openssl req -x509 -newkey>) are added under the device's C<pki>.

B<openssl>: C<x509> (C<-in>/input, C<-noout>, C<-subject>, C<-issuer>,
C<-dates>, C<-startdate>, C<-enddate>, C<-serial>, C<-fingerprint
[-sha256|-sha1]>, C<-ext subjectAltName>, C<-text>, C<-checkend N>,
C<-modulus>, C<-pubkey>, C<-subject_hash>), C<rsa>/C<pkey> (C<-in>,
C<-noout>, C<-modulus>, C<-check>, C<-text>, C<-pubout>, C<-out>, C<-passin
pass:…|file:…|env:…>), C<verify [-CAfile] [-untrusted]>, C<s_client -connect
h:p [-servername] [-showcerts] [-tls1_2|-tls1_3|-tls1_1|-tls1] [-CAfile]>,
C<crl2pkcs7 -nocrl -certfile>, C<pkcs7 -print_certs>, C<req> (C<-new>,
C<-x509>, C<-key>, C<-newkey rsa:N>, C<-nodes>/C<-noenc>, C<-keyout>, C<-out>,
C<-subj>, C<-addext>, C<-config> with C<[alt_names]>, C<-days>, C<-in … -noout
-text|-subject|-verify>), C<dgst -sha256>/C<sha256>/C<md5> over the input,
C<version>. Anything else: gap in the simulation.

B<update-ca-certificates> installs the certificates of all F<*.crt> under
F</usr/local/share/ca-certificates> (not other extensions — as on Debian).

L</client_verify> checks what a server presents, like curl with OpenSSL:
chain up to a trusted certificate (C<trusted> + C<installed> of the
client, or only C<--cacert>), validity, name (SAN, otherwise CN).

=head2 pem

  my $text = pem( cert => 'shop-2026' );        # also key, enckey, pub

PEM text (with a trailing newline) for an entry of the catalog.

=head2 blocks

  my @b = blocks($text);   # ( { kind => cert|key|enckey|csr|pub|p7|bad|other, id, text }, … )

The PEM blocks of a text in order; a body that refers to nothing in the
catalog is C<bad>.

=head2 catalog

  my $cat = catalog($state);   # { certs, keys, now }

The catalog from C<pki> of all devices, merged.

=head2 dn

  dn('C=US,O=Example Trust,CN=Example R3');   # "C = US, O = Example Trust, CN = Example R3"

A subject written the way OpenSSL 3 prints it.

=head2 modulus

The (simulated) modulus of a key, the same for certificate and key.

=head2 verify_chain

  my $err = verify_chain( $catalog, $leaf, \@intermediates, \@trusted );
  # undef = valid, otherwise { code, depth, cert }

=head2 name_matches

  name_matches( $certificate, 'www.shop.example.com' );

Does the name match the SANs (with C<*.> wildcard for exactly one level), or,
without SANs, the CN?

=head2 trust_of

The certificates a device trusts as a client (list of IDs).

=head2 client_verify

  my $bad = client_verify( $state, $from, $tls, $req );   # undef or [ 60, "(60) …" ]

=head2 tls_lines

Lines of C<curl -v> about the presented certificate.

=head2 openssl

  my ( $out, $ok ) = openssl( $dev, \@argv, $ctx, $stdin );

The command C<openssl> (subcommands see above).

=head2 csr_pem_for

  my $text = csr_pem_for( subject => 'CN=shop.example.com', sans => [ 'shop.example.com' ], key => 'k-shop' );

PEM text of a CSR (canonical: subject fields and names sorted) — for
rules on a generated CSR file.

=head2 update_ca_certificates

The command C<update-ca-certificates>: installs the F<*.crt> under
F</usr/local/share/ca-certificates> into C<pki.installed> and rewrites the bundle
F</etc/ssl/certs/ca-certificates.crt> if it is in the state.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
