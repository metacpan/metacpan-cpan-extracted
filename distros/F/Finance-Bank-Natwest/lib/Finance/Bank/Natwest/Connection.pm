package Finance::Bank::Natwest::Connection;
use strict;
use vars qw( $VERSION );
use Carp;
use LWP::UserAgent;

$VERSION = '0.04';

require Finance::Bank::Natwest;

use constant POSS_PIN => { first => 0, second => 1, third => 2, fourth => 3 };
use constant POSS_PASS =>
    { first => 0, second => 1, third => 2, fourth => 3, fifth => 4,
      sixth => 5, seventh => 6, eighth => 7, ninth => 8, tenth => 9,
      eleventh => 10, twelfth => 11, thirteenth => 12, fourteenth => 13,
      fifteenth => 14, sixteenth => 15, seventeenth => 16,
      eighteenth => 17, nineteenth => 18, twentieth => 19
    };


sub new{
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    $self->{url_base} = $opts{url_base} || Finance::Bank::Natwest->url_base;

    $self->_set_credentials( %opts );
    $self->_new_ua( %opts );
    
    return $self;
}

sub _new_ua{
    my ($self, %opts) = @_;

    my %proxy;

    if (exists $opts{proxy}) {
        $proxy{env_proxy} = 0;
        $proxy{proxy} = $opts{proxy} if 
            $opts{proxy} ne 'no' and $opts{proxy} ne 'env';
        $proxy{env_proxy} = 1 if $opts{proxy} eq 'env';
    } else {
        $proxy{env_proxy} = 1;
    }

    $self->{ua} = LWP::UserAgent->new(
        env_proxy => $proxy{env_proxy},
        keep_alive => 1,
        timeout => 30,
        cookie_jar => {},
        requests_redirectable => [ 'GET', 'HEAD', 'POST' ],
        agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
    );

    $self->{ua}->proxy('https', $proxy{proxy}) if exists $proxy{proxy};
}

sub _set_credentials{
    my ($self, %opts) = @_;

    croak "Must provide either a premade credentials object or ".
          "a class name together with options, stopped" if
        !exists $opts{credentials};

    if (ref($opts{credentials})) {
        croak "Can't accept credential options if supplying a premade ".
              "credentials object, stopped" if
            exists $opts{credentials_options};

        croak "Not a valid credentials object, stopped" unless
            $self->_isa_credentials($opts{credentials});

        $self->{credentials} = $opts{credentials};
    } else {
        croak "Must provide credential options unless suppying a premade ".
              "credentials object, stopped" if
            !exists $opts{credentials_options};

        $self->{credentials} =
            $self->_new_credentials(
                $opts{credentials}, $opts{credentials_options}
            );
    };
}

sub _new_credentials{
    my ($self, $class, $options) = @_;

    croak "Invalid class name, stopped" if
        $class !~ /^(?:\w|::)+$/;
    
    my $full_class = "Finance::Bank::Natwest::CredentialsProvider::$class";
    
    eval "local \$SIG{'__DIE__'}; 
          local \$SIG{'__WARN__'}; 
          require $full_class;
         ";
    croak "Not a valid credentials class, stopped"
        if $@;

    croak "Not a valid credentials class, stopped"
        unless $self->_isa_credentials($full_class);

    {
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        return $full_class->new(%{$options});
    }
}

sub _isa_credentials{
    my ($self, $credentials) = @_;

    my @required_subs = qw( new get_start get_stop get_identity get_pinpass );
  
    foreach my $sub (@required_subs) {
        return unless defined eval {
            local $SIG{'__DIE__'};
            local $SIG{'__WARN__'};
            $credentials->can($sub);
        };
    }

    return 1;
}

sub login{
    my ($self) = @_;

    my $page;

    $self->{login_ok} = 0;
    $self->{in_login} = 1;
    delete $self->{rb_id};

    $self->{credentials}->get_start();

    my $identity = $self->{credentials}->get_identity();

    ($self->{rb_id}, $page) = $self->post( 'logon.asp',
        {   DBIDa => $identity->{dob}, DBIDb => $identity->{uid},
            radType => '', scriptingon => 'yup' } );

    croak "Error during login process. " . 
          "The website is temporarily unavailable, stopped" if
        $page =~ m|Service Temporarily Unvailable|i;

    croak "Error during login process, stopped" if
        $page =~ m|<div class=ErrorMsg>.*?</div>|i;

    croak "Error during login process. " .
          "Current page cannot be recognised, stopped" unless
        $page =~ m#
                    Please \s enter \s the \s
                    ([a-z]{5,6}), \s ([a-z]{5,6}) \s and \s ([a-z]{5,6}) \s
                    digits \s from \s your \s (?:Security \s Number|PIN):
                  #ix;

    croak "Error during login process. " .
          "Unrecognised pin request ($1, $2, $3), stopped" unless
        exists POSS_PIN->{$1} && 
        exists POSS_PIN->{$2} && 
        exists POSS_PIN->{$3};

    my $pin_digits = [ POSS_PIN->{$1}, POSS_PIN->{$2}, POSS_PIN->{$3} ];

    croak "Error during login process. " .
          "Current page cannot be recognised, stopped" unless
        $page =~ m|
                    Please \s enter \s the \s
                    ([a-z]{5,11}), \s ([a-z]{5,11}) \s and \s ([a-z]{5,11}) \s
                    characters \s from \s your \s Password:
                  |ix;
    
    croak "Error during login process. " .
          "Unrecognised password request ($1, $2, $3), stopped" unless
        exists POSS_PASS->{$1} && 
        exists POSS_PASS->{$2} && 
        exists POSS_PASS->{$3};
    
    my $pass_chars = [ POSS_PASS->{$1}, POSS_PASS->{$2}, POSS_PASS->{$3} ];

    my $pinpass = $self->{credentials}->get_pinpass( $pin_digits, $pass_chars );
    $self->{credentials}->get_stop();

    $page = $self->post('Logon-PinPass.asp', 
        {   pin1 => $pinpass->{pin}[0], 
            pin2 => $pinpass->{pin}[1],
            pin3 => $pinpass->{pin}[2],
            pass1 => $pinpass->{password}[0],
            pass2 => $pinpass->{password}[1],
            pass3 => $pinpass->{password}[2],
            buttonComplete => 'Submitted',
            buttonFinish => 'Finish' } );

    $page = $self->post('LogonMessage.asp', { buttonOK => 'Next' }) if
        $page =~ m|LogonMessage\.asp|i;

    croak "Error during login process, stopped" if
        $page =~ m|<div class=ErrorMsg>.*?</div>|i;

    $self->{login_ok} = 1;
    delete $self->{in_login};
}

sub post{
    my $self = shift;

    $self->login(@_)
        if !$self->{login_ok} and !exists $self->{in_login};

    my $resp = $self->_post(@_);

    if ($self->_check_expired($resp)) {
        $self->_login(@_);
    
        $resp = $self->_post(@_);
        croak "Error talking to nwolb. " .
              "Session has timed out even though only just logged in, stopped"
            if $self->_check_expired($resp);
    }

    return unless defined wantarray;

    if (wantarray) {
        return (($resp->base->path_segments)[2], $resp->content);
    } else {
        return $resp->content;
    }
}

sub _check_expired{
    my ($self, $resp) = @_;

    return lc(($resp->base->path_segments)[-1]) eq 'exit.asp';
}

sub _post{
    my $self = shift;
    my $url = shift;
    my $full_url;

    if (exists $self->{rb_id}) {
        $full_url = $self->{url_base} . $self->{rb_id} . '/' . $url;
    } else {
        $full_url = $self->{url_base} . $url;
    }

    my $resp = $self->{ua}->post($full_url, @_);

    croak "Error talking to nwolb: " . $resp->message . ", stopped"
        if !$resp->is_success;

    croak "Unknown error talking to nwolb, stopped"
        if !exists $self->{in_login} and 
            lc($resp->base->as_string) ne lc($full_url);

    return $resp;
}

1;
