package Loctools::Net::OAuth2::Session;

use strict;

use JSON qw(decode_json encode_json);
use Net::OAuth2::Profile::WebServer;

sub new {
    my ($class, %params) = @_;

    my $session_file = $params{session_file};
    die "session_file parameter not provided" if $session_file eq '';
    delete $params{session_file};

    my $auth = Net::OAuth2::Profile::WebServer->new(%params);

    my $self = {
        session_file => $session_file,
        auth         => $auth,
    };

    bless $self, $class;
    return $self;
}

sub start {
    my ($self) = @_;

    if (-f $self->{session_file}) {
        $self->load;

        if ($self->{token}->expired) {
            warn "OAuth2 token expired, renewing\n";
            $self->renew;
        }
    } else {
        warn "\nOAuth2 session file not found. You will need to authorize your application once.\n\n";
        $self->authorize;
    }
}

sub access_token {
    my ($self) = @_;
    return $self->{token}->access_token;
}

sub authorization_header {
    my ($self) = @_;
    return (Authorization => "Bearer ".$self->access_token);
}

sub load {
    my ($self) = @_;
    warn "Loading OAuth2 session from $self->{session_file}\n";
    my $session = _load_json($self->{session_file}) or die $!;
    $self->{token} = Net::OAuth2::AccessToken->session_thaw(
        $session, profile => $self->{auth}
    );
}

sub authorize {
    my ($self) = @_;

    my $response = $self->{auth}->authorize_response;
    my $url = $response->headers->{location};

    print "1) Open this URL in your browser:\n\n";
    print "$url\n\n";
    print "2) Authorize the application\n";
    print "3) Copy the authorization code and paste it here.\n\n";

    my $code;
    while (1) {
        print "Code: ";
        $code = <STDIN>; # wait for input
        chomp $code;
        last if $code ne '';
    }

    $self->{token} = $self->{auth}->get_access_token($code);
    $self->save;
}

sub renew {
    my ($self) = @_;
    $self->{auth}->update_access_token($self->{token});
    $self->save;
}

sub save {
    my ($self) = @_;
    warn "Saving OAuth2 session to $self->{session_file}\n";
    _save_json($self->{session_file}, $self->{token}->session_freeze());
}

sub _load_json {
    my ($filename) = @_;
    open IN, $filename || die "Can't read from file '$filename': $!";
    binmode IN;
    my $raw = join('', <IN>);
    close IN;
    return decode_json($raw);
}

sub _save_json {
    my ($filename, $data) = @_;
    my $raw = encode_json($data);
    open OUT, ">$filename" || die "Can't write to file '$filename': $!";
    binmode(OUT);
    print OUT $raw;
    close OUT;
}



1;
