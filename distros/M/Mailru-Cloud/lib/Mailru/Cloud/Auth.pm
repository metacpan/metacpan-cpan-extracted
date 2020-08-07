package Mailru::Cloud::Auth;

use 5.008001;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use LWP::UserAgent;
use HTTP::Request;
use JSON::XS;
use URI::Escape;
use Carp qw/carp croak/;

our $VERSION    = '0.09';

sub new {
    my ($class, %opt) = @_;
    my $max_redirect = $opt{'-max_redirect'} // 30;
    my $self = {};
    $self->{debug} = $opt{-debug};
    my $ua = LWP::UserAgent->new (
                                    agent => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36',
                                    cookie_jar => {},
                                );
    $self->{ua} = $ua;
    $self->{ua}->max_redirect($max_redirect);
    return bless $self, $class;
}

sub login {
    my ($self, %opt)   = @_;
    $self->{login}     = $opt{-login}       || $self->{login}       || croak "You must specify -login opt for 'login' method";
    $self->{password}  = $opt{-password}    || $self->{password}    || croak "You must specify -password opt for 'login' method";
    my $ua = $self->{ua};
    my $res;

    #Get login token
    $res = $ua->get('https://mail.ru');
    if ($res->code ne '200') {
        croak "Can't get start mail.ru page. Code: " . $res->code;
    }
    my ($login_token) = $res->decoded_content =~ /CSRF\s*[:=]\s*"([0-9A-Za-z]+?)"/;
    if (not $login_token) {
        croak "Can't found login token";
    }

    #Login
    my %param = (
            'login'         => $self->{login},
            'password'      => $self->{password},
            'saveauth'      => 1,
            'project'       => 'e.mail.ru',
            'token'         => $login_token,
    );
    my %headers = (
        'Content-type'      => 'application/x-www-form-urlencoded',
        'Accept'            => '*/*',
        'Accept-Encoding'   => 'gzip, deflate, br',
        'Accept-Language'   => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
        'Referer'           => 'https://mail.ru/?from=logout',
        'Origin'            => 'https://mail.ru',
    );

    $res = $ua->post('https://auth.mail.ru/jsapi/auth', \%param, %headers);
    if ($res->code ne '200') {
        croak "Wrong response code from login form: " . $res->code;
    }

    my $json = decode_json($res->decoded_content);
    if ($json->{status} eq 'fail') {
        croak "Fail login: $json->{code}";
    }

    $self->__getToken() or return;
    return $self->{authToken};
}

sub __getToken {
    my $self = shift;

    my %headers = (
        'Accept'                    => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Encoding'           => 'gzip, deflate, br',
        'Accept-Language'           => 'ru,en-US;q=0.9,en;q=0.8',
        'Referer'                   => 'https://mail.ru/',
        'Sec-Fetch-Dest'            => 'document',
        'Sec-Fetch-Mode'            => 'navigate',
        'Sec-Fetch-Site'            => 'same-site',
        'Sec-Fetch-User'            => '?1',
        'Upgrade-Insecure-Requests' => '1',
    );
    my $res = $self->{ua}->get('https://auth.mail.ru/sdc?from=' . uri_escape('https://cloud.mail.ru/?from=promo&from=authpopup') , %headers);

    if ($res->is_success) {
        my $content = $res->decoded_content;
        $DB::single = 1;
        if ($content =~ /"csrf"\s*:\s*"([a-zA-Z0-9]+?)"/) {
            $self->{authToken} = $1;
            carp "Found authToken: $self->{authToken}" if $self->{debug};

            if ($content =~ /"email"\s*:\s*"(.+?)"/) {
                $self->{email} = $1;
                carp "Found email: $self->{email}" if $self->{debug};

                #Get BUILD
                $self->{build} = 'hotfix_CLOUDWEB-7726_50-0-3.201710311503';
                if ($content =~ /"BUILD"\s*:\s*"(.+?)"/) {
                    $self->{build} = $1;
                    carp "Found and use new build $self->{build}" if $self->{debug};
                }

                #Get x-page-id
                $self->{'x-page-id'} = 'f9jfLFeHA5';
                if ($content =~ /"x-page-id"\s*:\s*"(.+?)"/) {
                    $self->{'x-page-id'} = $1;
                    carp "Found and use new x-page_id $self->{build}" if $self->{debug};
                }

                #Parse free space info
                $self->{info} = __parseInfo(\$content);
                return 1;
            }

        }
    }
    return;
}

sub info {
    my $self = shift;
    if ($self->{info}) {
        my %info = map {$_, $self->{info}->{$_}} keys %{$self->{info}};
        return \%info;
    }
    return;
}

sub __parseInfo {
    my $content = shift;
    my %info = (
                'used_space'        => '',
                'total_space'       => '',
                'file_size_limit'   => '',
            );

    if (my ($size_block) = $$content =~ /"space":\s*{([^}]*)}/s) {
        while ($size_block =~ /"([^"]+)":\s*(\w+?)\b/gm) {
            if ($1 eq 'bytes_total') {
                $info{total_space} = $2;
            }
            elsif ($1 eq 'bytes_used') {
                $info{used_space} = $2;
            }
        }
    }

    if ($$content =~ /"file_size_limit":\s*(.+?)[,\s]/) {
        $info{file_size_limit} = $1;
    }
    return \%info;
}

sub __isLogin {
    my $self = shift;
    if ($self->{authToken}) {
        my $ua = $self->{ua};
        my $res = $ua->get('https://auth.mail.ru/cgi-bin/auth?mac=1&Login=' . uri_escape($self->{login}));
        my $code = $res->code;
        if ($code ne '200') {
            croak "Can't get status about login";
        }
        my $json_res = decode_json($res->content);
        $json_res->{status} eq 'ok' and return 1;
        $self->login() and return 1;
    }

    croak "Not logined";
}

1;


__END__
=pod

=encoding UTF-8

=head1 NAME

B<Mailru::Cloud::Auth> - authorize on site https://cloud.mail.ru and return csrf token

=head1 VERSION
    version 0.09

=head1 SYNOPSYS

    use Mailru::Cloud::Auth;
    my $cloud = Mailru::Cloud::Auth->new;

    my $token = $cloud->login(-login => 'test', -password => '12345') or die "Cant login on mail.ru";

=head1 METHODS

=head2 login(%opt)

Login on cloud.mail.ru server.Return csrf token if success. Return undef if false

    $cloud->login(-login => 'test', -password => '12345');
    Options:
        -login          => login form cloud.mail.ru
        -password       => password from cloud.mail.ru


=head1 DEPENDENCE

L<LWP::UserAgent>, L<Carp>, L<HTTP::Request>

=head1 AUTHORS

=over 4

=item *

Pavel Andryushin <vrag867@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Andryushin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
