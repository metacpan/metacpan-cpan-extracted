package EV::Telegram::TDLib::WebApps;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::WebApps - Mini App methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"WebApps mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

my %MODE = (
    full_size   => 'webAppOpenModeFullSize',
    compact     => 'webAppOpenModeCompact',
    full_screen => 'webAppOpenModeFullScreen',
);

# Telegram takes this as the platform identifier and hands it to the app as
# tgWebAppPlatform. The class is spelled out because \w is Unicode-aware and
# would pass names the server rejects as PLATFORM_INVALID, which names
# nothing near the cause.
# _croak: this one is called straight from new(), so a backtrace here has
# the constructor's whole argument list under it -- and a hyphen or a dot in
# the name is enough to fire it
sub check_application_name {
    my ($name) = @_;
    _croak("application_name must be 0-64 letters, digits or underscores"
         . (defined $name ? " (got '$name')" : ''))
        unless defined $name && $name =~ /\A[A-Za-z0-9_]{0,64}\z/;
    return $name;
}

sub open_params {
    my ($self, $opt) = @_;
    my $mode = $opt->{mode} // 'full_size';
    croak "unknown web app mode '$mode'" unless $MODE{$mode};
    return {
        '@type'          => 'webAppOpenParameters',
        application_name => defined $opt->{application_name}
            ? check_application_name($opt->{application_name})
            : $self->{application_name},
        mode             => { '@type' => $MODE{$mode} },
        (defined $opt->{theme} ? (theme => $opt->{theme}) : ()),
    };
}

sub web_app {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('web_app', 2, \@args);
    my ($bot, $name) = @args;
    need('bot_user_id, short_name', $bot, $name);
    $self->send({ '@type' => 'searchWebApp',
                  bot_user_id => 0 + $bot,
                  web_app_short_name => plain_text('a name', $name) }, $cb);
    return;
}

sub web_app_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $bot, $name, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, bot_user_id, short_name', $chat, $bot, $name);
    $self->send({
        '@type'             => 'getWebAppLinkUrl',
        chat_id             => 0 + $chat,
        bot_user_id         => 0 + $bot,
        web_app_short_name  => plain_text('a name', $name),
        start_parameter     => plain_text('a start parameter',
                                          $opt{start_parameter}),
        allow_write_access  => json_bool($opt{allow_write_access}),
        parameters          => open_params($self, \%opt),
    }, $cb);
    return;
}

sub web_app_url {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getWebAppUrl', bot_user_id => 0 + $bot,
                  url => plain_text('a url', $opt{url}),
                  parameters => open_params($self, \%opt) }, $cb);
    return;
}

sub main_web_app {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $bot, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, bot_user_id', $chat, $bot);
    $self->send({
        '@type'          => 'getMainWebApp',
        chat_id          => 0 + $chat,
        bot_user_id      => 0 + $bot,
        start_parameter  => plain_text('a start parameter', $opt{start_parameter}),
        parameters       => open_params($self, \%opt),
    }, $cb);
    return;
}

sub web_app_placeholder {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('web_app_placeholder', 1, \@args);
    my ($bot) = @args;
    need('bot_user_id', $bot);
    $self->send({ '@type' => 'getWebAppPlaceholder', bot_user_id => 0 + $bot }, $cb);
    return;
}

# an empty url is only valid for an attachment menu bot; otherwise pass the
# url from a WebApp button or TDLib answers BOT_INVALID
sub open_web_app {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat, $bot, $url, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, bot_user_id', $chat, $bot);
    $self->send({
        '@type'      => 'openWebApp',
        chat_id      => 0 + $chat,
        bot_user_id  => 0 + $bot,
        url          => plain_text('a url', $url),
        parameters   => open_params($self, \%opt),
    }, $cb);
    return;
}

sub close_web_app {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('close_web_app', 1, \@args);
    my ($launch_id) = @args;
    need('web_app_launch_id', $launch_id);
    $self->send({ '@type' => 'closeWebApp',
                  web_app_launch_id =>
                      plain_text('a launch id', $launch_id) }, $cb);
    return;
}

sub send_web_app_data {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('send_web_app_data', 3, \@args);
    my ($bot, $button_text, $data) = @args;
    need('bot_user_id, button_text, data', $bot, $button_text, $data);
    $self->send({ '@type' => 'sendWebAppData', bot_user_id => 0 + $bot,
                  button_text => plain_text('a button text', $button_text),
                  data => plain_text('data', $data) }, $cb);
    return;
}

sub web_app_request {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('web_app_request', 3, \@args);
    my ($bot, $method, $params) = @args;
    need('bot_user_id, method, parameters', $bot, $method, $params);
    $self->send({ '@type' => 'sendWebAppCustomRequest', bot_user_id => 0 + $bot,
                  method => plain_text('a method', $method),
                  parameters => plain_text('parameters', $params) }, $cb);
    return;
}

sub answer_web_app_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('answer_web_app_query', 2, \@args);
    my ($query_id, $result) = @args;
    need('web_app_query_id, result', $query_id, $result);
    $self->send({ '@type' => 'answerWebAppQuery',
                  web_app_query_id => plain_text('a query id', $query_id),
                  result => $result }, $cb);
    return;
}

sub on_web_app_data {
    my ($self, $cb) = @_;
    $self->{on_web_app_data} = $cb if @_ > 1;
    return $self->{on_web_app_data};
}

1;
