package ETLp::Audit::Browser::Controller::User;
use Moose;
extends 'ETLp::Audit::Browser::Controller::Base';
use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
use Crypt::PasswdMD5 'unix_md5_crypt';
use Data::Dumper;

sub login {
    my $self = shift;
    my $errs = shift;
    my $next = $self->query->param('next');

    $self->logger->debug('Errs: ' . Dumper($errs));

    return $self->tt_process({next => $next, errs => $errs,});
}

sub validate_login {
    my $self = shift;
    my ($results, $err_page) = $self->check_rm('login', '_login_profile');
    return $err_page if ($err_page);

    my $q    = $results->valid;
    my $user = $self->model->get_user_by_username($q->{username});
    $self->session->param('user_id', $user->user_id);
    $self->session->param('admin',   $user->admin);

    my $redir =
      ($q->{next}) ? $q->{next} : $self->conf->param('root_url') . '/job';
    return $self->redirect($redir);
}

sub list {
    my $self = shift;
    unless ($self->session->param('admin')) {
        $self->session->param('error',
            'You do not have permission to call this function');
        return $self->redirect('error');
    }

    my $page = $self->query->param('page') || 1;
    my $users = $self->model->get_users(page => $page);
    return $self->tt_process({users => $users, page => $page});
}

sub edit {
    my $self = shift;
    my $errs = shift;
    unless ($self->session->param('admin')) {
        $self->session->param('error',
            'You do not have permission to call this function');
        return $self->redirect('error');
    }

    my $user_id = $self->query->param('user_id') || undef;
    my $user = $self->model->get_user($user_id);
    return $self->tt_process({user => $user, errs => $errs});
}

sub save {
    my $self = shift;
    my $url;

    unless ($self->session->param('admin')) {
        $self->session->param('error',
            'You do not have permission to call this function');
        return $self->redirect('error');
    }

    my ($results, $err_page) = $self->check_rm('edit', '_user_profile');
    return $err_page if ($err_page);

    my $q = $results->valid;

    my $user = $self->model->save($q);

    if ($q->{user_id}) {
        $self->session->param('message', 'User updated');
        $url = $self->conf->param('root_url') . '/user/edit/' . $user->user_id;
    } else {
        $self->session->param('message', 'User created');
        $url = $self->conf->param('root_url') . '/user/list/';
    }

    return $self->redirect($url);
}

sub edit_password {
    my $self = shift;
    my $errs = shift;
    return $self->tt_process({errs => $errs});
}

sub save_password {
    my $self = shift;
    my ($results, $err_page) =
      $self->check_rm('edit_password', '_password_profile');
    return $err_page if $err_page;

    my $q       = $results->valid;
    my $user_id = $self->session->param('user_id');
    
    $self->logger->debug("User ID: $user_id");
    $self->model->update_password($q->{password}, $user_id);

    $self->session->param('message', 'Password Updated');
    my $url = $self->conf->param('root_url') . '/user/edit_password/';
    $self->redirect($url);
}

sub logout {
    my $self = shift;
    $self->session->clear('user_id');
    $self->session->clear('admin');
    return $self->redirect($self->conf->param('root_url') . '/user/login');
}

sub module {
    return 'User';
}

sub _login_profile {
    my $self = shift;
    return {
        required    => [qw/username password/],
        optional    => [qw/next/],
        constraints => {
            username => {
                name       => 'invalid_login',
                constraint => sub {
                    my ($self, $username, $password) = @_;
                    my $user = $self->EtlpUser->single(
                        {username => $username, active => 1});

                    return 0 unless $user;
                    return $self->model->check_password($password,
                        $user->password);
                    my ($salt, $enc_passwd) =
                      (split(/\$/, $user->password))[2, 3];

                    return (unix_md5_crypt($password, $salt) eq $user->password)
                      ? 1
                      : 0;
                },
                params => [$self, qw/username password/]
            }
        },
        msgs => {
            any_errors  => 'some_errors',
            constraints => {invalid_login => 'Invalid username or password',}
        }
    };
}

sub _user_profile {
    my $self = shift;
    return {
        required => [qw/first_name last_name/],
        optional => [
            qw/username user_id password password2 email_address
              active admin/
        ],
        dependencies      => {username            => [qw/password password2/]},
        dependency_groups => {password_group      => [qw/password password2/],},
        require_some      => {username_or_user_id => [qw/username user_id/],},
        constraints       => {
            email_address => 'email',
            username      => [
                {
                    name       => 'changed_username',
                    constraint => sub {
                        my ($username, $user_id) = @_;
                        return ($username && $user_id) ? 0 : 1;
                    },
                    params => [qw/username user_id/]
                },
                {
                    name       => 'duplicate_username',
                    constraint => sub {
                        my ($self, $username, $user_id) = @_;
                        # exit if there is a user id. This will be picked up
                        # by another check - we're only after new users
                        return 1 if $user_id;

                        my $user =
                          $self->EtlpUser->single({username => $username});

                        return ($user) ? 0 : 1;
                    },
                    params => [$self, 'username', 'user_id'],
                }
            ],
            password => [
                {
                    name       => 'password_mismatch',
                    constraint => \&_password_mismatch,
                    params     => [qw/password password2/]
                },
                {
                    name       => 'password_length',
                    constraint => \&_password_length,
                }
            ],
        },
        msgs => {
            any_errors  => 'some_errors',
            constraints => {
                changed_username   => 'Username cannot be changed',
                duplicate_username => 'Username already in use',
                password_mismatch  => 'Passwords do not match',
                password_length => 'Passwords must be less than 10 characters',
            }
          }

    };
}

sub _password_profile {
    my $self = shift;
    return {
        required    => [qw/old_password password password2/],
        constraints => {
            old_password => {
                name       => 'password_incorrect',
                constraint => sub {
                    my ($self, $password) = @_;
                    my $user_id = $self->session->param('user_id');
                    my $user    = $self->EtlpUser->find($user_id);

                    return $self->model->check_password($password,
                        $user->password);

                },
                params => [$self, 'old_password'],
            },
            password => [
                {
                    name       => 'password_mismatch',
                    constraint => \&_password_mismatch,
                    params     => [qw/password password2/]
                },
                {
                    name       => 'password_length',
                    constraint => \&_password_length,
                }
            ],
            password2 => {
                name       => 'password_length',
                constraint => \&_password_length,
            }
        },
        msgs => {
            any_errors  => 'some_errors',
            constraints => {
                password_incorrect => 'This password is not correct',
                password_mismatch  => 'Passwords do not match',
                password_length => 'Passwords must be less than 10 characters',
            }
        }
    };
}

sub setup {
    my $self = shift;
    $self->start_mode('login');
    $self->run_modes(
        [
            qw/login validate_login list edit save edit_password
              save_password logout error/
        ]
    );
}

sub _password_mismatch {
    return $_[0] eq $_[1];
}

sub _password_length {
    length($_[0]) < 10;
}
1;
