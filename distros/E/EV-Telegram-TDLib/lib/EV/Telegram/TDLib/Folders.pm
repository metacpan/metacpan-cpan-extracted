package EV::Telegram::TDLib::Folders;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Folders - chat folder methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Folders mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

my @FOLDER_FLAGS = qw(
    exclude_muted exclude_read exclude_archived
    include_contacts include_non_contacts include_bots
    include_groups include_channels
);
my @FOLDER_LISTS = qw(pinned_chat_ids included_chat_ids excluded_chat_ids);
# TDLib replaces the whole folder, so a misspelt flag is not merely ignored:
# the flag it meant is sent as off
my %FOLDER_KEY = map { $_ => 1 }
    qw(name icon color_id shareable animate_emoji), @FOLDER_LISTS, @FOLDER_FLAGS;

# the name is a chatFolderName wrapping a formattedText, not a plain string;
# passing a string yields only "Chat folder name must be non-empty"
sub _folder {
    my ($spec) = @_;
    croak 'a folder needs a hashref' unless ref $spec eq 'HASH';
    if (my @bad = sort grep { !$FOLDER_KEY{$_} } keys %$spec) {
        croak "unknown folder field(s): @bad";
    }
    my $name = $spec->{name};
    my $text = ref $name eq 'HASH' && ($name->{'@type'} // '') eq 'formattedText'
        ? $name
        : { '@type' => 'formattedText', text => plain_text('a folder name', $name),
            entities => [] };
    croak 'a folder needs a name' unless length($text->{text} // '');
    return {
        '@type' => 'chatFolder',
        name    => {
            '@type'                => 'chatFolderName',
            text                   => $text,
            animate_custom_emoji   => json_bool($spec->{animate_emoji}),
        },
        (defined $spec->{icon}
            ? (icon => { '@type' => 'chatFolderIcon',
                         name => plain_text('an icon name', $spec->{icon}) }) : ()),
        color_id      => num('color_id', $spec->{color_id} // -1),
        is_shareable  => json_bool($spec->{shareable}),
        (map { $_ => num_list($_, $spec->{$_} // []) } @FOLDER_LISTS),
        (map { $_ => json_bool($spec->{$_}) } @FOLDER_FLAGS),
    };
}

sub folder {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('folder', 1, \@args);
    my ($id) = @args;
    need('chat_folder_id', $id);
    $self->send({ '@type' => 'getChatFolder', chat_folder_id => 0 + $id }, $cb);
    return;
}

sub create_folder {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('create_folder', 1, \@args);
    my ($spec) = @args;
    need('folder', $spec);
    $self->send({ '@type' => 'createChatFolder', folder => _folder($spec) }, $cb);
    return;
}

sub edit_folder {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('edit_folder', 2, \@args);
    my ($id, $spec) = @args;
    need('chat_folder_id, folder', $id, $spec);
    $self->send({ '@type' => 'editChatFolder', chat_folder_id => 0 + $id,
                  folder => _folder($spec) }, $cb);
    return;
}

sub delete_folder {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_folder_id', $id);
    $self->send({ '@type' => 'deleteChatFolder', chat_folder_id => 0 + $id,
                  leave_chat_ids =>
                      num_list('leave_chats', $opt{leave_chats} // []) }, $cb);
    return;
}

sub reorder_folders {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($ids, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_folder_ids', $ids);
    croak 'reorder_folders needs an arrayref of folder ids' unless ref $ids eq 'ARRAY';
    $self->send({
        '@type'                   => 'reorderChatFolders',
        chat_folder_ids           => num_list('chat_folder_ids', $ids),
        main_chat_list_position   => num('main_position', $opt{main_position} // 0),
    }, $cb);
    return;
}

sub recommended_folders {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('recommended_folders', 0, \@args);
    $self->send({ '@type' => 'getRecommendedChatFolders' }, $cb);
    return;
}

sub folder_chat_count {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('folder_chat_count', 1, \@args);
    my ($spec) = @args;
    need('folder', $spec);
    $self->send({ '@type' => 'getChatFolderChatCount', folder => _folder($spec) }, $cb);
    return;
}

sub folder_tags {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($on, @rest) = @args;
    no_opts('folder_tags', @rest);
    $self->send({ '@type' => 'toggleChatFolderTags',
                  are_tags_enabled => json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

sub folder_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_folder_id', $id);
    $self->send({
        '@type'          => 'createChatFolderInviteLink',
        chat_folder_id   => 0 + $id,
        name             => plain_text('an invite link name', $opt{name}),
        chat_ids         => num_list('chats', $opt{chats} // []),
    }, $cb);
    return;
}

sub folder_invite_links {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('folder_invite_links', 1, \@args);
    my ($id) = @args;
    need('chat_folder_id', $id);
    $self->send({ '@type' => 'getChatFolderInviteLinks',
                  chat_folder_id => 0 + $id }, $cb);
    return;
}

sub edit_folder_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $link, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_folder_id, invite_link', $id, $link);
    $self->send({
        '@type'          => 'editChatFolderInviteLink',
        chat_folder_id   => 0 + $id,
        invite_link      => plain_text('an invite link', $link),
        name             => plain_text('an invite link name', $opt{name}),
        chat_ids         => num_list('chats', $opt{chats} // []),
    }, $cb);
    return;
}

sub delete_folder_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_folder_invite_link', 2, \@args);
    my ($id, $link) = @args;
    need('chat_folder_id, invite_link', $id, $link);
    $self->send({ '@type' => 'deleteChatFolderInviteLink',
                  chat_folder_id => 0 + $id,
                  invite_link => plain_text('an invite link', $link) }, $cb);
    return;
}

sub check_folder_invite_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('check_folder_invite_link', 1, \@args);
    my ($link) = @args;
    need('invite_link', $link);
    $self->send({ '@type' => 'checkChatFolderInviteLink',
                  invite_link => plain_text('an invite link', $link) }, $cb);
    return;
}

sub add_folder_by_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($link, @rest) = @args;
    my %opt = opts(@rest);
    need('invite_link', $link);
    $self->send({
        '@type'      => 'addChatFolderByInviteLink',
        invite_link  => plain_text('an invite link', $link),
        chat_ids     => num_list('chats', $opt{chats} // []),
    }, $cb);
    return;
}

1;
