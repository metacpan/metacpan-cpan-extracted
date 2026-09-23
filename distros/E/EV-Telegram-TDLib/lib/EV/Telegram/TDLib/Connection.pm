package EV::Telegram::TDLib::Connection;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Connection - connection methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Connection mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES = (
    updateConnectionState => \&update_connection_state,
    updateOption          => \&update_option,
);

# TDLib pushes its options as updates, my_id among them right after login,
# so the account's own id is known without a getMe round trip
sub update_option {
    my ($self, $obj) = @_;
    my $name = $obj->{name};
    return unless defined $name;
    my $v = $obj->{value} // {};
    my $type = $v->{'@type'} // '';
    $self->{cache}{options}{$name} =
          $type eq 'optionValueEmpty' ? undef
        : $type eq 'optionValueBoolean' ? ($v->{value} ? 1 : 0)
        : $v->{value};
}

sub option {
    my ($self, $name) = @_;
    # same as the other cache readers: undef in, undef out, and no warning
    # from inside the module for the lookup
    return undef unless defined $name;
    return $self->{cache}{options}{$name};
}

sub my_id { $_[0]{cache}{options}{my_id} }

sub update_connection_state {
    my ($self, $obj) = @_;
    my $state = $obj->{state} or return;
    my $type = $state->{'@type'} // '';
    return unless length $type;
    $self->{cache}{connection_state} = $type;
    if (my $cb = $self->{on_connection_state}) { $cb->($type) }
}

sub connection_state { $_[0]{cache}{connection_state} }

sub on_connection_state {
    my ($self, $cb) = @_;
    $self->{on_connection_state} = $cb if @_ > 1;
    return $self->{on_connection_state};
}

sub sessions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('sessions', 0, \@args);
    $self->send({ '@type' => 'getActiveSessions' }, $cb);
    return;
}

# session ids are TL int64 and must not cross as numbers
sub terminate_session {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('terminate_session', 1, \@args);
    my ($session_id) = @args;
    need('session_id', $session_id);
    $self->send({ '@type' => 'terminateSession',
                  session_id => plain_text('a session id', $session_id) }, $cb);
    return;
}

sub terminate_other_sessions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('terminate_other_sessions', 0, \@args);
    $self->send({ '@type' => 'terminateAllOtherSessions' }, $cb);
    return;
}

sub set_session_ttl {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_session_ttl', 1, \@args);
    my ($days) = @args;
    need('inactive_session_ttl_days', $days);
    $self->send({ '@type' => 'setInactiveSessionTtl',
                  inactive_session_ttl_days => 0 + $days }, $cb);
    return;
}


my %PROXY_TYPE = (
    socks5  => 'proxyTypeSocks5',
    http    => 'proxyTypeHttp',
    mtproto => 'proxyTypeMtproto',
);

sub proxy {
    my ($spec) = @_;
    _croak('a proxy needs a hashref') unless ref $spec eq 'HASH';
    my $kind = $spec->{type} // 'socks5';
    my $t = $PROXY_TYPE{$kind} or _croak("unknown proxy type '$kind'");
    my %type = ('@type' => $t);
    # stringified: a numeric password or an all-digit secret would otherwise
    # reach a string slot as a JSON Number, which TDLib refuses
    if ($kind eq 'mtproto') {
        $type{secret} = plain_text('a secret', $spec->{secret});
    }
    else {
        $type{username} = plain_text('a username', $spec->{username});
        $type{password} = plain_text('a password', $spec->{password});
        $type{http_only} = json_bool($spec->{http_only})
            if $kind eq 'http';
    }
    return { '@type' => 'proxy',
             server => plain_text('a server', $spec->{server}),
             port => num('port', $spec->{port} // 0), type => \%type };
}

sub add_proxy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($spec, @rest) = @args;
    my %opt = opts(@rest);
    need('proxy', $spec);
    $self->send({ '@type' => 'addProxy', proxy => proxy($spec),
                  enable => json_bool(exists $opt{enable} ? $opt{enable} : 1),
                  comment => plain_text('a comment', $opt{comment}) }, $cb);
    return;
}

sub proxies {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('proxies', 0, \@args);
    $self->send({ '@type' => 'getProxies' }, $cb);
    return;
}

sub enable_proxy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('enable_proxy', 1, \@args);
    my ($proxy_id) = @args;
    need('proxy_id', $proxy_id);
    $self->send({ '@type' => 'enableProxy', proxy_id => 0 + $proxy_id }, $cb);
    return;
}

sub disable_proxy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('disable_proxy', 0, \@args);
    $self->send({ '@type' => 'disableProxy' }, $cb);
    return;
}

sub remove_proxy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_proxy', 1, \@args);
    my ($proxy_id) = @args;
    need('proxy_id', $proxy_id);
    $self->send({ '@type' => 'removeProxy', proxy_id => 0 + $proxy_id }, $cb);
    return;
}

sub ping_proxy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('ping_proxy', 1, \@args);
    my ($spec) = @args;
    need('proxy', $spec);
    $self->send({ '@type' => 'pingProxy', proxy => proxy($spec) }, $cb);
    return;
}

my %NETWORK = (
    none    => 'networkTypeNone',
    mobile  => 'networkTypeMobile',
    roaming => 'networkTypeMobileRoaming',
    wifi    => 'networkTypeWiFi',
    other   => 'networkTypeOther',
);

# telling TDLib the network changed lets it reconnect promptly instead of
# waiting for its own timers
sub set_network_type {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_network_type', 1, \@args);
    my ($type) = @args;
    my $t = $NETWORK{ $type // '' }
        or _croak("unknown network type '" . ($type // '') . "'");
    $self->send({ '@type' => 'setNetworkType', type => { '@type' => $t } }, $cb);
    return;
}

sub network_statistics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'getNetworkStatistics',
                  only_current => json_bool($opt{current}) }, $cb);
    return;
}

sub log_out {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('log_out', 0, \@args);
    $self->send({ '@type' => 'logOut' }, $cb);
    return;
}

sub password_state {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('password_state', 0, \@args);
    $self->send({ '@type' => 'getPasswordState' }, $cb);
    return;
}

sub set_password {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($old, $new, @rest) = @args;
    my %opt = opts(@rest);
    # an empty new password removes 2-step verification, so it must be asked
    # for, never inferred from a missing argument
    _croak('set_password needs a new password; pass the empty string to '
         . 'remove the password') unless defined $new;
    $self->send({
        '@type'        => 'setPassword',
        old_password   => plain_text('a password', $old),
        new_password   => plain_text('a password', $new),
        new_hint       => plain_text('a hint', $opt{hint}),
        set_recovery_email_address =>
            json_bool(defined $opt{recovery_email}),
        new_recovery_email_address =>
            plain_text('a recovery email', $opt{recovery_email}),
    }, $cb);
    return;
}

# the account is deleted after this many days with no activity
sub account_ttl {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('account_ttl', 1, \@args);
    my ($days) = @args;
    # both branches return nothing, like every other convenience method: the
    # getter used to hand back the internal @extra, which nothing accepts
    if (!defined $days) {
        $self->send({ '@type' => 'getAccountTtl' }, $cb);
        return;
    }
    $self->send({ '@type' => 'setAccountTtl',
                  ttl => { '@type' => 'accountTtl', days => num('days', $days) } }, $cb);
    return;
}

sub register_device {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($token, @rest) = @args;
    my %opt = opts(@rest);
    need('device_token', $token);
    _croak('register_device needs a deviceToken hashref')
        unless ref $token eq 'HASH';
    $self->send({ '@type' => 'registerDevice', device_token => $token,
                  other_user_ids =>
                      num_list('other_users', $opt{other_users} // []) }, $cb);
    return;
}

1;
