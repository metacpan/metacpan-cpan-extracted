package EV::Telegram::TDLib::Secret;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Secret - secret chat methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Secret mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

# A secret chat is a separate object from the chat that shows it: creating one
# yields a chat whose type is chatTypeSecret, and the id below is the secret
# chat's own id, not that chat_id. new_secret_chat returns the chat; the rest
# take the secret chat id, which lives in the chat's type.
sub new_secret_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('new_secret_chat', 1, \@args);
    my ($user_id) = @args;
    need('user_id', $user_id);
    $self->send({ '@type' => 'createNewSecretChat', user_id => 0 + $user_id }, $cb);
    return;
}

sub open_secret_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('open_secret_chat', 1, \@args);
    my ($secret_chat_id) = @args;
    need('secret_chat_id', $secret_chat_id);
    $self->send({ '@type' => 'createSecretChat',
                  secret_chat_id => 0 + $secret_chat_id }, $cb);
    return;
}

sub secret_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('secret_chat', 1, \@args);
    my ($secret_chat_id) = @args;
    need('secret_chat_id', $secret_chat_id);
    $self->send({ '@type' => 'getSecretChat',
                  secret_chat_id => 0 + $secret_chat_id }, $cb);
    return;
}

sub close_secret_chat {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('close_secret_chat', 1, \@args);
    my ($secret_chat_id) = @args;
    need('secret_chat_id', $secret_chat_id);
    $self->send({ '@type' => 'closeSecretChat',
                  secret_chat_id => 0 + $secret_chat_id }, $cb);
    return;
}

# secret messages are not on the server, so this searches the local database
sub search_secret_messages {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    my %req = ('@type' => 'searchSecretMessages',
               chat_id => num('chat_id', $opt{chat_id} // 0),
               query   => plain_text('a query', $query),
               offset  => plain_text('an offset', $opt{offset}),
               limit   => num('limit', $opt{limit} // 50));
    $req{filter} = tl_class('searchMessagesFilter', 'SearchMessagesFilter',
                             'message filter', $opt{filter})
        if defined $opt{filter};
    $self->send(\%req, $cb);
    return;
}

# Changing the key rewrites the local database. Losing it loses the secret
# chats with it, since nothing on the server can restore them.
sub set_database_encryption_key {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_database_encryption_key', 1, \@args);
    my ($key) = @args;
    need('new_encryption_key', $key);
    $self->send({ '@type' => 'setDatabaseEncryptionKey',
                  new_encryption_key =>
                      tl_bytes('new_encryption_key', $key) }, $cb);
    return;
}

sub session_accepts_secret_chats {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($session_id, $on, @rest) = @args;
    no_opts('session_accepts_secret_chats', @rest);
    need('session_id', $session_id);
    $self->send({ '@type' => 'toggleSessionCanAcceptSecretChats',
                  session_id => plain_text('a session id', $session_id),
                  can_accept_secret_chats =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

1;
