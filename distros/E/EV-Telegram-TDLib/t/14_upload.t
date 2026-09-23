use strict;
use warnings;
use Test::More;

# _send is stubbed here, so a close can never complete and the END block
# would spend its whole default budget waiting for one
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1]; };
}

sub extra_of {
    my ($json) = @_;
    my ($extra) = $json =~ /"\@extra":"(\d+)"/;
    return $extra;
}

my $td = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-upload',
);

my (@progress, @updates);
$td->on_update(sub { push @updates, $_[0] });
$td->on_upload(55, sub { push @progress, $_[0] });

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":55,"size":2000,"local":{"@type":"localFile","path":"/tmp/big.bin","is_downloading_completed":true},"remote":{"@type":"remoteFile","is_uploading_active":true,"is_uploading_completed":false,"uploaded_size":500}}}));
is(scalar @progress, 1, 'upload progress fires for a registered id');
is($progress[0]{remote}{uploaded_size}, 500, 'the remote uploaded_size is delivered');

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":66,"size":2000,"remote":{"@type":"remoteFile","is_uploading_active":true,"is_uploading_completed":false,"uploaded_size":500}}}));
is(scalar @progress, 1, 'an unregistered id fires no upload watcher');
is($updates[-1]{'@type'}, 'updateFile', 'the update still reaches on_update');

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":55,"size":2000,"local":{"@type":"localFile","path":"/tmp/big.bin","is_downloading_completed":true},"remote":{"@type":"remoteFile","is_uploading_active":false,"is_uploading_completed":true,"uploaded_size":2000}}}));
is(scalar @progress, 2, 'the completing update is delivered');
ok($progress[1]{remote}{is_uploading_completed}, 'remote completion flag is delivered');

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":55,"size":2000,"remote":{"@type":"remoteFile","is_uploading_active":false,"is_uploading_completed":true,"uploaded_size":2000}}}));
is(scalar @progress, 2, 'the watcher is dropped after completion');

# --- explicit unwatch
my @gone;
$td->on_upload(56, sub { push @gone, $_[0] });
$td->on_upload(56, undef);
$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":56,"size":1,"remote":{"@type":"remoteFile","is_uploading_active":true,"is_uploading_completed":false,"uploaded_size":0}}}));
is(scalar @gone, 0, 'on_upload with an undef callback removes the watcher');

# --- download and upload registries coexist on the same client
my (@dl_progress, @dl_done);
$td->download(57, on_progress => sub { push @dl_progress, $_[0] }, sub { push @dl_done, [@_] });
my $extra_dl = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"file","id":57,"\@extra":"$extra_dl"}));
my @up57;
$td->on_upload(57, sub { push @up57, $_[0] });
$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":57,"size":10,"local":{"@type":"localFile","downloaded_size":5,"is_downloading_completed":false},"remote":{"@type":"remoteFile","is_uploading_active":true,"is_uploading_completed":false,"uploaded_size":3}}}));
is(scalar @dl_progress, 1, 'the download progress fired for the same id');
is(scalar @up57, 1, 'the upload watcher fired for the same id');

# --- close drops watchers silently
my @late;
$td->on_upload(58, sub { push @late, $_[0] });
$td->close;
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
ok(!exists $td->{cache}{uploads}, 'close drops upload watchers');
is(scalar @late, 0, 'no watcher fires during close');

# --- a dying progress callback must not skip the cleanup below it, which
# would leave the watcher installed for the life of the client
{
    my @errs;
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-updie',
        on_error => sub { push @errs, $_[0] });
    $c->on_upload(7, sub { die "boom\n" });
    $c->inject_raw(
        q({"@type":"updateFile","file":{"@type":"file","id":7,)
      . q("remote":{"@type":"remoteFile","is_uploading_completed":true}}}));
    is scalar(@errs), 1, 'the dying progress callback is reported';
    is scalar(keys %{ $c->{cache}{uploads} || {} }), 0,
        'and the completed upload watcher is still cleaned up';
}

# --- only a completed upload used to release its watcher, so every upload
# that failed or was cancelled left one behind for the life of the client
{
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-upfail');
    my $state = sub {
        my ($id, $active, $done) = @_;
        return qq({"\@type":"updateFile","file":{"\@type":"file","id":$id,)
             . qq("remote":{"\@type":"remoteFile","is_uploading_active":$active,)
             . qq("is_uploading_completed":$done}}});
    };
    my $n = 0;
    $c->on_upload(8, sub { $n++ });
    $c->inject_raw($state->(8, 'false', 'false'));
    ok exists $c->{cache}{uploads}{8},
        'an inactive update before the upload starts keeps the watcher';
    $c->inject_raw($state->(8, 'true', 'false'));
    ok exists $c->{cache}{uploads}{8}, 'and so does one while it runs';
    $c->inject_raw($state->(8, 'false', 'false'));
    is $n, 3, 'every update reached the callback, the last one included';
    ok !exists $c->{cache}{uploads}{8},
        'an upload that stopped without completing releases its watcher';

    # re-registering from the final update's own callback, as a retry would,
    # must survive the cleanup of the watcher being replaced
    my $again = 0;
    $c->on_upload(9, sub {
        my $f = shift;
        $c->on_upload(9, sub { $again++ }) unless $f->{remote}{is_uploading_active};
    });
    $c->inject_raw($state->(9, 'true', 'false'));
    $c->inject_raw($state->(9, 'false', 'false'));
    ok exists $c->{cache}{uploads}{9},
        'a watcher registered again from the final callback is not dropped';
    $c->inject_raw($state->(9, 'false', 'false'));
    ok exists $c->{cache}{uploads}{9},
        'and it waits for its own upload to start, as a fresh one does';
    is $again, 1, 'and the re-registered watcher receives subsequent updates';

    # replacing a watcher mid-upload used to forget that the upload had
    # started, so a stop after the replace kept the new one for good
    my @seen;
    $c->on_upload(10, sub { push @seen, 'first' });
    $c->inject_raw($state->(10, 'true', 'false'));
    $c->on_upload(10, sub { push @seen, 'second' });
    $c->inject_raw($state->(10, 'false', 'false'));
    is "@seen", 'first second', 'the replacement gets the stop';
    ok !exists $c->{cache}{uploads}{10},
        'and is released by it, like the watcher it replaced';

    # a keyed handler croaks without a callback, as on_command does
    my $err = sub { my $code = shift; local $@; eval { $code->() }; $@ };
    like $err->(sub { $c->on_upload(11) }), qr/needs a callback/,
        'on_upload with the callback left out croaks';
    like $err->(sub { $c->on_upload(11, 'not code') }), qr/needs a callback/,
        'and so does one given something other than code';
    ok !exists $c->{cache}{uploads}{11}, 'and nothing is registered';
}

# --- one updateFile can reach both registries for the same id, so a die in
# the download callback must not skip the upload block's cleanup below it
{
    my @errs;
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-bothdie',
        on_error => sub { push @errs, $_[0] });
    $c->download(99, sub { die "download boom\n" });
    $c->on_upload(99, sub {});
    my $escaped = '';
    eval {
        $c->inject_raw(
            q({"@type":"updateFile","file":{"@type":"file","id":99,"size":10,)
          . q("local":{"@type":"localFile","is_downloading_completed":true},)
          . q("remote":{"@type":"remoteFile","is_uploading_completed":true}}}));
        1;
    } or $escaped = $@;
    is $escaped, '', 'the dying download callback does not escape the handler';
    is scalar(@errs), 1, 'and is reported';
    is scalar(keys %{ $c->{cache}{uploads} || {} }), 0,
        'the upload watcher for the same id is still cleaned up';
}

# --- the same for the download failure branch, which is a separate call site
{
    my @errs;
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-faildie',
        on_error => sub { push @errs, $_[0] });
    $c->download(99, sub { die "failure boom\n" });
    $c->on_upload(99, sub {});
    # a download only fails after it has started
    $c->inject_raw(
        q({"@type":"updateFile","file":{"@type":"file","id":99,)
      . q("local":{"@type":"localFile","is_downloading_active":true}}}));
    my $escaped = '';
    eval {
        $c->inject_raw(
            q({"@type":"updateFile","file":{"@type":"file","id":99,)
          . q("local":{"@type":"localFile","is_downloading_active":false,)
          . q("is_downloading_completed":false},)
          . q("remote":{"@type":"remoteFile","is_uploading_completed":true}}}));
        1;
    } or $escaped = $@;
    is $escaped, '', 'a dying download-failure callback does not escape';
    is scalar(@errs), 1, 'and is reported';
    is scalar(keys %{ $c->{cache}{uploads} || {} }), 0,
        'and the upload watcher for the same id is still cleaned up';
}

done_testing;
