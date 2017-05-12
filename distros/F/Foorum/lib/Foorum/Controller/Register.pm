package Foorum::Controller::Register;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Digest ();
use WWW::Contact;

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( $c->model('DBIC::BannedIp')->is_ip_banned( $c->req->address ) ) {
        $c->forward( '/print_error', ['IP banned'] );
        return 0;
    }

    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    unless ( $c->config->{function_on}->{register} ) {
        $c->detach( '/print_error', ['ERROR_REGISTER_CLOSED'] );
    }

    $c->stash->{template} = 'register/index.html';
    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->form(
        username => [qw/NOT_BLANK/],
        password => [ qw/NOT_BLANK/, [qw/LENGTH 6 20/] ],
        { passwords => [ 'password', 'confirm_password' ] } =>
            ['DUPLICATION'],
    );
    return if ( $c->form->has_error );

    # username
    my $username = $c->req->param('username');
    my $err      = $c->model('DBIC::User')->validate_username($username);
    if ($err) {
        return $c->set_invalid_form( username => $err );
    }

    # email
    my $email = $c->req->param('email');
    $err = $c->model('DBIC::User')->validate_email($email);
    if ($err) {
        return $c->set_invalid_form( email => $err );
    }

    # password
    my $password = $c->req->param('password');
    my $d = Digest->new( $c->config->{authentication}->{password_hash_type} );
    $d->add($password);
    my $computed = $d->digest;

    my $user = $c->model('DBIC')->resultset('User')->create(
        {   username      => $username,
            nickname      => $c->req->param('nickname') || $username,
            password      => $computed,
            email         => $email,
            register_time => time(),
            register_ip   => $c->req->address,
            lang          => $c->config->{default_lang},
            status        => 'unverified',
        }
    );

    # send activation code
    $c->model('DBIC::ScheduledEmail')
        ->send_activation( $user, 0, { lang => $c->stash->{lang} } );

    $c->authenticate( { username => $username, password => $password } );

    $c->res->redirect('/?st=103');
}

sub activation : Local {
    my ( $self, $c, $username, $activation_code ) = @_;

    # two situations:
    # 1, new account to activate
    # 2, new email to confirm

    $username = $c->req->param('username') unless ($username);
    $activation_code = $c->req->param('activation_code')
        unless ($activation_code);

    $c->stash(
        {   template => 'register/activation.html',
            username => $username,
        }
    );
    return unless ( $username and $activation_code );

    my $user = $c->model('DBIC::User')->get( { username => $username } );
    $c->detach( '/print_error', ['ERROR_USER_NON_EXIST'] ) unless ($user);

    my $activation_rs = $c->model('DBIC')->resultset('UserActivation')
        ->find( { user_id => $user->{user_id} } );
    unless ($activation_rs) {
        if ( $user->{status} eq 'unverified' ) {    # new account
            $c->model('DBIC::ScheduledEmail')
                ->send_activation( $user, 0, { lang => $c->stash->{lang} } );
            return $c->res->redirect(
                '/register/activation/' . $user->{username} );
        } else {
            return $c->res->redirect('/profile/edit');
        }
    }

    # validate it
    if ( $activation_rs->activation_code eq $activation_code ) {
        $c->model('DBIC::User')
            ->update_user( $user, { status => 'verified', } );
        $activation_rs->delete;

# login will be failed since the $user->password is SHA1 Hashed.
# $c->login( $username, $user->{password} );
# so instead, we use set_authenticated, check Catalyst::Plugin::Authentication
        bless $user, 'Catalyst::Authentication::User::Hash';    # XXX?
        $c->set_authenticated($user);

        # send a welcome email
        $c->model('DBIC::ScheduledEmail')->create_email(
            {   template => 'welcome_to_join',
                to       => $user->{email},
                lang     => $c->stash->{lang},
                stash    => { user => $user, }
            }
        );

        $c->res->redirect('/profile/edit');
    } else {
        $c->stash->{'ERROR_UNMATCHED'} = 1;
    }
}

sub import_contacts : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $email = $c->req->param('email') || $c->user->email;

    $c->stash(
        {   template => 'register/import_contacts.html',
            email    => $email,
        }
    );
    return unless ( $c->req->method eq 'POST' );

    my $wc = WWW::Contact->new();
    my @contacts = $wc->get_contacts( $email, $c->req->param('password') );

    my $errStr = $wc->errstr;
    if ($errStr) {
        $c->detach( '/print_error', [$errStr] );
    }

    use Data::Dumper;
    $c->res->body( Dumper( \@contacts ) );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
