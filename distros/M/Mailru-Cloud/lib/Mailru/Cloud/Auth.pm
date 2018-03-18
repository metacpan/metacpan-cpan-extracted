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
use Carp 'croak';
 
our $VERSION    = '0.02';

sub new {
    my ($class) = @_;
    my $self = {};
    my $ua = LWP::UserAgent->new (
                                    agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0',
                                    cookie_jar => {},
                                );
    $self->{ua} = $ua;
    return bless $self, $class;
}

sub login {
    my ($self, %opt)   = @_;
    $self->{login}     = $opt{-login}       || $self->{login}       || croak "You must specify -login opt for 'login' method";
    $self->{password}  = $opt{-password}    || $self->{password}    || croak "You must specify -password opt for 'login' method";
    my $ua = $self->{ua};

    my %param;
    $param{Domain} = 'mail.ru';
    $param{FailPage} = '';
    $param{Login} = $self->{login};
    $param{Password} = $self->{password};
    $param{new_auth_form} = 1;
    $param{page} ='https://cloud.mail.ru/?from=promo';
    $param{saveauth} = 1;

    my $res = $ua->post('https://auth.mail.ru/cgi-bin/auth?lang=ru_RU&from=authpopup', \%param);

    my $code = $res->code;
    if ($code eq '302' || $code eq '301' || $code eq '200') {
        $self->__getToken() or return;
        return $self->{authToken};
    }
    return;
}

sub __getToken {
    my $self = shift;

    my $ua = $self->{ua};
    my $res = $ua->get('https://cloud.mail.ru/?from=promo&from=authpopup');

    if ($res->is_success) {
        my $content = $res->decoded_content;
        if ($content =~ /"csrf":"(.+?)"/) {
            $self->{authToken} = $1;
            if ($content =~ /"email":"(.+?)"/) {
                $self->{email} = $1;
                
                #Get BUILD
                $self->{build} = 'hotfix_CLOUDWEB-7726_50-0-3.201710311503';
                if ($content =~ /"BUILD":"(.+?)"/) {
                    $self->{build} = $1;
                }
                
                #Get x-page-id
                $self->{'x-page-id'} = 'f9jfLFeHA5';
                if ($content =~ /"x-page-id":"(.+?)"/) {
                    $self->{'x-page-id'} = $1;
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
    if ($$content =~ /"space":[{].+?"used":(.+?),"total":(.+?)[}]/) {
        $info{used_space} = $1 * 1024 * 1024;   # To bytes from Mbytes
        $info{total_space} = $2 * 1024 * 1024;  # To bytes from Mbytes
    }
    if ($$content =~ /"file_size_limit":(.+?),/) {
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
    version 0.02

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
