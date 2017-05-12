package Furl::HTTP::OAuth;
$Furl::HTTP::OAuth::VERSION = '0.002';
use warnings;
use strict;
use URI;
use URI::Escape;
use Furl::HTTP;
use Digest::HMAC_SHA1;
use Scalar::Util;

# well-formed oauth_signature_method values
use constant HMAC_METHOD => 'HMAC-SHA1';
use constant PTEXT_METHOD => 'PLAINTEXT';

=encoding utf8

=head1 NAME

Furl::HTTP::OAuth - Make OAuth 1.0 signed requests with Furl

=head1 SYNOPSIS

    my $client = Furl::HTTP::OAuth->new(
        consumer_key => '<your consumer key>',
        consumer_secret => '<your consumer secret>',
        token => '<your token>',
        token_secret => '<your token secret>',
        signature_method => 'HMAC-SHA1', # the default

        # accepts all Furl::HTTP->new options
        agent => 'MyAgent/1.0',
        timeout => 5
    );

    my ($version, $code, $msg, $headers, $body) = $client->get('http://test.com');
    ($version, $code, $msg, $headers, $body) = $client->put('http://test.com');
    ($version, $code, $msg, $headers, $body) = $client->post('http://test.com');
    
    # OR...

    ($version, $code, $msg, $headers, $body) = $client->request(
        # accepts all Furl::HTTP::request options        
        method => 'GET',
        url => 'http://test.com',
    );

=head1 DESCRIPTION

The goal of this module is to provide a simple interface for quickly signing and sending HTTP requests using OAuth 1.0 and Furl. You should be at least somewhat familiar with OAuth 1.0 and Furl before using this module.

=head1 METHODS

=head3 request

See L<Furl>'s request method

=head3 get

See L<Furl>'s get method

=head3 post

See L<Furl>'s post method

=head3 put

See L<Furl>'s put method

=head3 delete

See L<Furl>'s delete method

=head1 ATTRIBUTES

=head3 consumer_key (String)

Your OAuth consumer key

=head3 consumer_secret (String)

Your OAuth consumer secret

=head3 token (String)

Your OAuth token

=head3 token_secret (String)

Your OAuth token secret

=head3 signature_method (String)

Either 'HMAC-SHA1' (default) or 'PLAINTEXT'

=head3 nonce (Coderef)

The default is a coderef which returns an eight character string of random letters

=head3 timestamp (Coderef)

The default is a coderef which returns time()

=head3 furl (Furl::HTTP)

Underlying L<Furl::HTTP> object. Feel free to use your own.

=head1 SEE ALSO

L<Furl::HTTP>, L<OAuth RFC|http://tools.ietf.org/html/rfc5849>, L<https://hueniverse.com/oauth/guide/workflow/>

=head1 LICENSE

(c) 2016 ascra

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub new {
    my $class = shift;
    my %opts = ();

    if (@_) {
        if (@_ == 1 && ref $_[0] eq 'HASH') {
            %opts = %{$_[0]};
        } else {
            %opts = @_;
        }
    }

    my $consumer_key     = delete $opts{consumer_key};
    my $consumer_secret  = delete $opts{consumer_secret};
    my $signature_method = delete $opts{signature_method};
    my $token            = delete $opts{token};
    my $token_secret     = delete $opts{token_secret};

    # nonce generator
    my $nonce = delete $opts{nonce} || sub {
        my @chars = ("A".."Z", "a".."z");
        my $str = "";
        
        $str .= $chars[int(rand(scalar(@chars)))] 
            for (1..8);
        
        return $str;
    };

    # timestamp generator
    my $timestamp = delete $opts{timestamp} || sub {
        return time();
    };

    bless {
        consumer_key => $consumer_key,
        consumer_secret => $consumer_secret,
        signature_method => $signature_method,
        token => $token,
        token_secret => $token_secret,
        nonce => $nonce,
        timestamp => $timestamp,
        furl => Furl::HTTP->new(%opts)
    }, $class;
}
 
sub request {
    my $self = shift;
    my %args = @_;

    my $url        = $args{url};
    my $scheme     = $args{scheme};
    my $host       = $args{host};
    my $port       = $args{port};
    my $path_query = $args{path_query};
    my $content    = $args{content};
    my $method     = $args{method};
    my $headers    = $args{headers};
    my $write_file = $args{write_file};
    my $write_code = $args{write_code};
    my $signature  = $args{signature};

    my $consumer_key     = $self->consumer_key;
    my $consumer_secret  = $self->consumer_secret;
    my $token            = $self->token;
    my $token_secret     = $self->token_secret;
    my $signature_method = $self->signature_method || '';
    my $timestamp        = &{$self->timestamp};
    my $nonce            = &{$self->nonce};
    my $uri              = undef;

    if ($url) {
        $uri = URI->new($url);
    } else {
        $uri = URI->new;
        $uri->scheme($scheme);
        $uri->host($host);
        $uri->port($port);
        $uri->path_query($path_query);
    }
    
    # build signature
    if (! $signature) {
        if (uc $signature_method eq PTEXT_METHOD) {
            $signature_method = PTEXT_METHOD;
            $signature = $self->gen_plain_sig(
                consumer_secret => $consumer_secret,
                token_secret => $token_secret
            );
        } else {
            $signature_method = HMAC_METHOD;
            $signature = $self->gen_sha1_sig(
                method => $method, 
                uri => $uri, 
                content => $content,
                consumer_key => $consumer_key,
                consumer_secret => $consumer_secret,
                token => $token,
                token_secret => $token_secret,
                timestamp => $timestamp,
                nonce => $nonce,
            );
        }
    }

    $uri->query_form([
        $uri->query_form,
        oauth_consumer_key => $consumer_key,
        oauth_nonce => $nonce,
        oauth_signature_method => $signature_method,
        oauth_timestamp => $timestamp,
        oauth_token => $token,
        oauth_signature => $signature
    ]);

    return $self->furl->request(
        method => $method,
        url => $uri->as_string,
        content => $content,
        headers => $headers,
        write_file => $write_file,
        write_code => $write_code
    );
}

sub get {
    my ($self, $url, $headers) = @_;

    return $self->request(
        method => 'GET',
        url => $url,
        headers => $headers
    );
}

sub head {
    my ($self, $url, $headers) = @_;

    return $self->request(
        method => 'HEAD',
        url => $url,
        headers => $headers
    );
}

sub post {
    my ($self, $url, $headers, $content) = @_;

    return $self->request(
        method => 'POST',
        url => $url,
        headers => $headers,
        content => $content
    );
}

sub put {
    my ($self, $url, $headers, $content) = @_;

    return $self->request(
        method => 'PUT',
        url => $url,
        headers => $headers,
        content => $content
    );
}

sub delete {
    my ($self, $url, $headers) = @_;

    return $self->request(
        method => 'DELETE',
        url => $url,
        headers => $headers
    );
}

sub _gen_sha1_sig {
    my $self = shift;
    my %args = @_;

    my $method          = $args{method};
    my $uri             = $args{uri};
    my $content         = $args{content};
    my $timestamp       = $args{timestamp};
    my $nonce           = $args{nonce};
    my $consumer_key    = $args{consumer_key};
    my $consumer_secret = $args{consumer_secret};
    my $token           = $args{token};
    my $token_secret    = $args{token_secret};
    
    # method part
    my $base_string = uc($method) . '&';
    
    # url part
    # exclude ports 80 and 443
    my $port = $uri->port;
    $port = $port && ($port == 443 || $port == 80) ? '' : (':' . $port);
    $base_string .= _encode(
        lc($uri->scheme . '://' . $uri->authority . $port . $uri->path)
    ) . '&';
    
    my @query_form = $uri->query_form;
    my @sorted_params = ();
    my %params = ();

    # handle parameters in $content (hashref or arrayref supported)
    my $c_reftype = ref $content;
    if ($content && $c_reftype && ! _is_real_fh($content) && 
        (($c_reftype eq 'HASH') || $c_reftype eq 'ARRAY')) {
        @query_form = $c_reftype eq 'HASH' ? (@query_form, %$content) :
            (@query_form, @$content);
    }
    
    # for the sake of sorting, construct a param mapping
    for (my $i = 0; $i <= (@query_form - 1); $i += 2) {
        my $k = _encode($query_form[$i]);
        my $v = _encode($query_form[$i + 1]);
        
        if (exists $params{$k}) {
            push @{$params{$k}}, $v;
        } else {
            $params{$k} = [ $v ];
        }
    }
    
    # add oauth parameters
    $params{oauth_consumer_key}     = [ _encode($consumer_key) ];
    $params{oauth_token}            = [ _encode($token) ];
    $params{oauth_signature_method} = [ _encode(HMAC_METHOD) ];
    $params{oauth_timestamp}        = [ _encode($timestamp) ];
    $params{oauth_nonce}            = [ _encode($nonce) ];
    
    # sort params and join each key/value with a '='
    foreach my $key (sort keys %params) {
        my @vals = @{$params{$key}};

        # if there's more than one value for the param, sort (see RFC)
        @vals = sort @vals if (@vals > 1);

        push @sorted_params, $key . '=' . $_
            for (@vals);
    }
    
    # add sorted encoded params
    $base_string .= _encode(join('&', @sorted_params));
    
    # compute digest
    my $key = _encode($consumer_secret) . '&' . _encode($token_secret);
    my $hmac = Digest::HMAC_SHA1->new($key);
    $hmac->add($base_string);
    my $signature = $hmac->b64digest;
    
    # pad signature
    $signature .= '=' x (4 - (length($signature) % 4));

    return $signature;
}

sub _gen_plain_sig {
    my $self = shift;
    my %args = @_;

    my $consumer_secret = $args{consumer_secret} || '';
    my $token_secret    = $args{token_secret} || '';

    return _encode($consumer_secret) . '&' . _encode($token_secret)
}

sub _encode {
    return URI::Escape::uri_escape($_[0], '^\w.~-');
}

# stolen from Plack::Util::is_real_fh
sub _is_real_fh {
    my $fh = shift;

    my $reftype = Scalar::Util::reftype($fh) or return;
    if( $reftype eq 'IO'
        or $reftype eq 'GLOB' && *{$fh}{IO} ){
        my $m_fileno = $fh->fileno;
        return unless defined $m_fileno;
        return unless $m_fileno >= 0;
        my $f_fileno = fileno($fh);
        return unless defined $f_fileno;
        return unless $f_fileno >= 0;
        return 1;
    }
    else {
        return;
    }
}

sub consumer_key {
    return $_[0]->{consumer_key} = 
        (@_ == 2 ? $_[1] : $_[0]->{consumer_key});
}

sub consumer_secret {
    return $_->[0]->{consumer_secret} = 
        (@_ == 2 ? $_[1] : $_[0]->{consumer_secret});
}

sub signature_method {
    return $_->[0]->{signature_method} = 
        (@_ == 2 ? $_[1] : $_[0]->{signature_method});
}

sub token {
    return $_->[0]->{token} = 
        (@_ == 2 ? $_[1] : $_[0]->{token});
}

sub token_secret {
    return $_->[0]->{token_secret} = 
        (@_ == 2 ? $_[1] : $_[0]->{token_secret});
}

sub nonce {
    return $_->[0]->{nonce} = 
        (@_ == 2 ? $_[1] : $_[0]->{nonce});
}

sub timestamp {
    return $_->[0]->{timestamp} = 
        (@_ == 2 ? $_[1] : $_[0]->{timestamp});
}

sub furl {
    return $_->[0]->{furl} = 
        (@_ == 2 ? $_[1] : $_[0]->{furl});
}

1;
