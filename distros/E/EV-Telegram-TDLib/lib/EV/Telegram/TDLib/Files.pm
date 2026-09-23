package EV::Telegram::TDLib::Files;

use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Files - file methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Files mixin">.

=cut

sub CLONE_SKIP { 1 }

our %UPDATES = (
    updateFile => \&update_file,
);

sub downloads { $_[0]{cache}{downloads} ||= {} }

sub uploads { $_[0]{cache}{uploads} ||= {} }


sub update_file {
    my ($self, $obj) = @_;
    my $file = $obj->{file} or return;
    # an id-less file would key both registries under the empty string and
    # collide with a later lookup
    return unless defined $file->{id};
    # TDLib re-sends updateFile for reasons unrelated to our download, so
    # only registered ids are followed and a completed one is dropped at once.
    # One update can reach both registries for the same id, so every callback
    # is guarded: a die in an earlier one would strand the other's watcher.
    if (my $dl = $self->downloads->{ $file->{id} }) {
        if (my $cb = $dl->{on_progress}) { $self->guarded($cb, $file) }
        my $local = $file->{local};
        if ($local && $local->{is_downloading_completed}) {
            delete $self->downloads->{ $file->{id} };
            $self->guarded($dl->{cb}, $file, undef);
        }
        elsif ($local && $local->{is_downloading_active}) {
            $dl->{started} = 1;
        }
        # started, then neither active nor completed: a permanent failure,
        # signalled only via updateFile; an inactive update before the
        # start is just the file's current state, not a failure
        elsif ($local && $dl->{started}) {
            delete $self->downloads->{ $file->{id} };
            $self->guarded($dl->{cb}, undef,
                            { '@type' => 'error', code => -1,
                              message => 'download failed' });
        }
    }
    if (my $up = $self->uploads->{ $file->{id} }) {
        my $remote = $file->{remote} || {};
        $up->{started} = 1 if $remote->{is_uploading_active};
        # completed, or stopped after it had started: either way the last
        # update this watcher will ever get. Only completion used to count, so
        # every failed or cancelled upload left its watcher behind for good.
        # An inactive update before the start is the file's current state, as
        # for downloads.
        my $last = $up->{last} = $remote->{is_uploading_completed}
                || ($up->{started} && !$remote->{is_uploading_active});
        $self->guarded($up->{cb}, $file);
        # read the registry directly: the callback may have closed the client,
        # which drops it, or registered this id again, which is not ours
        my $reg = $self->{cache}{uploads};
        delete $reg->{ $file->{id} }
            if $last && $reg && ($reg->{ $file->{id} } // 0) == $up;
    }
}

sub download {
    my ($self, @args) = @_;
    # a trailing on_progress => $p is the option, not the callback
    my $cb = ref $args[-1] eq 'CODE' && ($args[-2] // '') ne 'on_progress'
           ? pop @args : sub {};
    my ($file_id, @rest) = @args;
    need('file_id', $file_id);
    my %opt = opts(@rest);
    my $id = 0 + $file_id;
    # one registration per file id: overwriting would silently drop the
    # first caller's callback, so the second call fails instead --
    # synchronously, like a parse_mode error, since nothing is sent
    if ($self->downloads->{$id}) {
        $cb->(undef, { '@type' => 'error', code => -1,
                       message => "download of file $id already in progress" });
        return;
    }
    my $reg = { cb => $cb, on_progress => $opt{on_progress} };
    $self->downloads->{$id} = $reg;
    $self->send({
        '@type' => 'downloadFile',
        file_id => 0 + $file_id,
        priority => num('priority', $opt{priority} // 1),
        offset => 0,
        limit => 0,
        synchronous => json_bool(0),
    }, sub {
        my ($res, $err) = @_;
        # bind to our own registration: a cancel followed by a fresh
        # download reuses the id, and this reply must not be handed to the
        # replacement, which would fail it and swallow its own reply
        my $dl = $self->downloads->{ 0 + $file_id };
        return unless $dl && $dl == $reg;
        if ($err) {
            delete $self->downloads->{ 0 + $file_id };
            $dl->{cb}->(undef, $err);
            return;
        }
        # an asynchronous request resolves at download start, so from
        # here an inactive-and-not-completed update is a terminal failure
        $dl->{started} = 1;
        # an already-downloaded file resolves the request at once and no
        # updateFile follows: nothing about the file changed
        if ($res->{local} && $res->{local}{is_downloading_completed}) {
            delete $self->downloads->{ 0 + $file_id };
            $dl->{cb}->($res, undef);
        }
    });
    return;
}

sub cancel_download {
    my ($self, $file_id, @rest) = @_;
    # a callback passed here was never called: the download's own one is failed
    _croak('cancel_download takes only a file id; the download callback is'
         . ' the one told of the cancel') if @rest;
    need('file_id', $file_id);
    $self->send({
        '@type' => 'cancelDownloadFile',
        file_id => 0 + $file_id,
        only_if_pending => json_bool(0),
    });
    my $dl = delete $self->downloads->{ 0 + $file_id } or return;
    $dl->{cb}->(undef, { '@type' => 'error', code => -1,
                         message => 'download canceled' });
    return;
}

sub upload {
    my ($self, $path) = @_;
    need('path', $path);
    return { '@type' => 'inputFileLocal', path => plain_text('a path', $path) };
}

sub on_upload {
    my ($self, $file_id, $cb) = @_;
    need('file_id', $file_id);
    my $id = 0 + $file_id;
    if (@_ > 2 && !defined $cb) { delete $self->uploads->{$id}; return }
    _croak('on_upload needs a callback; pass undef to remove the watcher')
        unless ref $cb eq 'CODE';
    # a watcher replaced mid-upload keeps what the old one saw, or a stop
    # after the replace would pass for a file that never started; one
    # re-armed from the final update starts afresh, for a retry
    my $old = $self->uploads->{$id};
    $self->uploads->{$id} =
        { cb => $cb, started => $old && !$old->{last} ? $old->{started} : 0 };
    return;
}

sub file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('file', 1, \@args);
    my ($file_id) = @args;
    need('file_id', $file_id);
    $self->send({ '@type' => 'getFile', file_id => 0 + $file_id }, $cb);
    return;
}

# a remote file id is the persistent one that travels in a message; file_type
# must match what it actually is or TDLib refuses it
sub remote_file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($remote_id, @rest) = @args;
    my %opt = opts(@rest);
    need('remote_file_id', $remote_id);
    $self->send({ '@type' => 'getRemoteFile',
                  remote_file_id => plain_text('a remote file id', $remote_id),
                  file_type => tl_class('fileType', 'FileType', 'file type',
                                         $opt{file_type} // 'Unknown') }, $cb);
    return;
}

sub delete_file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_file', 1, \@args);
    my ($file_id) = @args;
    need('file_id', $file_id);
    $self->send({ '@type' => 'deleteFile', file_id => 0 + $file_id }, $cb);
    return;
}

sub add_to_downloads {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($file_id, $chat_id, $message_id, @rest) = @args;
    my %opt = opts(@rest);
    need('file_id, chat_id, message_id', $file_id, $chat_id, $message_id);
    $self->send({ '@type' => 'addFileToDownloads', file_id => 0 + $file_id,
                  chat_id => 0 + $chat_id, message_id => 0 + $message_id,
                  priority => num('priority', $opt{priority} // 1) }, $cb);
    return;
}

sub remove_from_downloads {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($file_id, @rest) = @args;
    my %opt = opts(@rest);
    need('file_id', $file_id);
    $self->send({ '@type' => 'removeFileFromDownloads', file_id => 0 + $file_id,
                  delete_from_cache => json_bool($opt{delete_cache}) }, $cb);
    return;
}

sub pause_download {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($file_id, $paused, @rest) = @args;
    no_opts('pause_download', @rest);
    need('file_id', $file_id);
    $self->send({ '@type' => 'toggleDownloadIsPaused', file_id => 0 + $file_id,
                  is_paused => json_bool(defined $paused ? $paused : 1) }, $cb);
    return;
}

sub storage_statistics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('storage_statistics', 0, \@args);
    $self->send({ '@type' => 'getStorageStatisticsFast' }, $cb);
    return;
}

# a long-lived client accumulates gigabytes; this is how it prunes them
sub optimize_storage {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my (@rest) = @args;
    my %opt = opts(@rest);
    $self->send({
        '@type'          => 'optimizeStorage',
        size             => num('size',  $opt{size}  // -1),
        ttl              => num('ttl',   $opt{ttl}   // -1),
        count            => num('count', $opt{count} // -1),
        immunity_delay   => num('immunity_delay', $opt{immunity_delay} // -1),
        file_types       => [],
        chat_ids         => num_list('chats', $opt{chats} // []),
        exclude_chat_ids => num_list('exclude_chats', $opt{exclude_chats} // []),
        return_deleted_file_statistics => json_bool($opt{statistics}),
        chat_limit       => num('chat_limit', $opt{chat_limit} // 0),
    }, $cb);
    return;
}

sub suggested_file_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($file_id, @rest) = @args;
    my %opt = opts(@rest);
    need('file_id', $file_id);
    $self->send({ '@type' => 'getSuggestedFileName', file_id => 0 + $file_id,
                  directory => plain_text('a directory', $opt{directory}) }, $cb);
    return;
}

1;
