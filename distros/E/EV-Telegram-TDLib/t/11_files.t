use strict;
use warnings;
use Test::More;

# This file stubs _send, so the END-block shutdown cannot deliver its close
# requests and would idle out the whole budget at exit. Nothing was ever sent
# to TDLib here, so there is nothing to wait for.
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
    database_directory => 't/tmp-files',
);

# --- download: progress, then completion exactly once
my (@progress, @done);
$td->download(77, on_progress => sub { push @progress, $_[0] }, sub { push @done, [@_] });
like($sent[-1], qr/"downloadFile"/, 'download sends downloadFile');
like($sent[-1], qr/"file_id":77/, 'the file id goes out as a number');
like($sent[-1], qr/"synchronous":false/, 'the download is asynchronous');
like($sent[-1], qr/"priority":1/, 'the default priority goes out');
my $extra_dl = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"file","id":77,"\@extra":"$extra_dl"}));

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":77,"size":1000,"local":{"@type":"localFile","is_downloading_active":true,"downloaded_size":500,"is_downloading_completed":false}}}));
is(scalar @done, 0, 'not finished at half way');
is($progress[0]{local}{downloaded_size}, 500, 'progress reported');

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":77,"size":1000,"local":{"@type":"localFile","path":"/tmp/x","downloaded_size":1000,"is_downloading_completed":true}}}));
is(scalar @done, 1, 'completion fires once');
is($done[0][0]{local}{path}, '/tmp/x', 'the local path is delivered');
is($done[0][1], undef, 'no error on a completed download');

$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":77,"size":1000,"local":{"@type":"localFile","path":"/tmp/x","downloaded_size":1000,"is_downloading_completed":true}}}));
is(scalar @done, 1, 'a repeat completion update does not fire the callback twice');
is(scalar @progress, 2, 'a repeat completion update does not fire progress either');

# --- updateFile for an unregistered id is ignored. Asserted against the
# registered id's callbacks: a lookup that fell back to any registration
# would fire them, and an unconditional pass could not tell.
$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":88,"size":10,"local":{"@type":"localFile","is_downloading_completed":true}}}));
is(scalar @done, 1, 'an unregistered updateFile fires no completion callback');
is(scalar @progress, 2, 'and no progress callback');

# --- priority option
$td->download(78, priority => 32, sub {});
like($sent[-1], qr/"priority":32/, 'an explicit priority goes out');
my $extra_p = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"file","id":78,"\@extra":"$extra_p"}));

# --- an immediate downloadFile rejection resolves the callback
my @dl_err;
$td->download(79, sub { push @dl_err, [@_] });
my $extra_err = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"error","code":400,"message":"FILE_ID_INVALID","\@extra":"$extra_err"}));
is($dl_err[0][0], undef, 'a rejected download delivers no file');
is($dl_err[0][1]{code}, 400, 'a rejected download delivers the error');
$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":79,"size":1,"local":{"@type":"localFile","is_downloading_completed":true}}}));
is(scalar @dl_err, 1, 'a rejected download stays deregistered');

# --- cancel_download
my @canceled;
$td->download(80, sub { push @canceled, [@_] });
$td->cancel_download(80);
like($sent[-1], qr/"cancelDownloadFile"/, 'cancel_download sends cancelDownloadFile');
like($sent[-1], qr/"file_id":80/, 'the canceled file id goes out');
is($canceled[0][0], undef, 'a canceled download delivers no file');
is($canceled[0][1]{'@type'}, 'error', 'a canceled download delivers an error');
$td->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":80,"size":1,"local":{"@type":"localFile","is_downloading_completed":true}}}));
is(scalar @canceled, 1, 'a completion after cancel does not fire again');

# --- cancel of an unknown id still sends the request, fires nothing
my $cbs_before = scalar @canceled;
$td->cancel_download(999);
like($sent[-1], qr/"cancelDownloadFile"/, 'cancel of an unknown id is still sent');
is(scalar @canceled, $cbs_before, 'cancel of an unknown id fires no callback');

# --- upload
my $input = $td->upload('/tmp/photo.jpg');
is($input->{'@type'}, 'inputFileLocal', 'upload returns inputFileLocal');
is($input->{path}, '/tmp/photo.jpg', 'upload carries the path verbatim');

# --- close flushes in-flight downloads
my @hung_dl;
$td->download(81, sub { push @hung_dl, [@_] });
$td->close;
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is($hung_dl[0][0], undef, 'close delivers no file to an in-flight download');
is($hung_dl[0][1]{message}, 'client closed', 'close fails an in-flight download');

# --- close flushes in-flight sends (Task 10 gap)
my $td2 = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-files',
);
my @hung_send;
$td2->send_message(-100123, 'never confirmed', sub { push @hung_send, [@_] });
my $extra_s = extra_of($sent[-1]);
$td2->inject_raw(qq({"\@type":"message","id":1048576,"chat_id":-100123,"\@extra":"$extra_s"}));
is(scalar @hung_send, 0, 'the send is still awaiting confirmation');
$td2->close;
$td2->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is($hung_send[0][0], undef, 'close delivers no message to an in-flight send');
is($hung_send[0][1]{message}, 'client closed', 'close fails an in-flight send');

# --- a file already downloaded completes from the downloadFile reply alone:
# TDLib emits no updateFile when nothing changed (FileManager download_impl)
my $td3 = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-files',
);
my @cached;
$td3->download(90, sub { push @cached, [@_] });
my $extra_cached = extra_of($sent[-1]);
$td3->inject_raw(qq({"\@type":"file","id":90,"size":1000,"local":{"\@type":"localFile","path":"/tmp/cached","downloaded_size":1000,"is_downloading_completed":true},"\@extra":"$extra_cached"}));
is(scalar @cached, 1, 'an already-downloaded file completes from the reply');
is($cached[0][0]{local}{path}, '/tmp/cached', 'the reply file is delivered');
is($cached[0][1], undef, 'no error on an immediate completion');
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":90,"size":1000,"local":{"@type":"localFile","is_downloading_completed":true}}}));
is(scalar @cached, 1, 'the registration is gone: a later updateFile fires nothing');

# --- a permanent download failure is signalled via updateFile with
# is_downloading_active false and is_downloading_completed false
my @failed;
$td3->download(91, sub { push @failed, [@_] });
my $extra_f = extra_of($sent[-1]);
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":91,"size":10,"local":{"@type":"localFile","is_downloading_active":false,"is_downloading_completed":false}}}));
is(scalar @failed, 0, 'an inactive update before the start is not a failure');
$td3->inject_raw(qq({"\@type":"file","id":91,"\@extra":"$extra_f"}));
is(scalar @failed, 0, 'the started download still waits');
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":91,"size":10,"local":{"@type":"localFile","is_downloading_active":true,"is_downloading_completed":false}}}));
is(scalar @failed, 0, 'an active download is not a failure');
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":91,"size":10,"local":{"@type":"localFile","is_downloading_active":false,"is_downloading_completed":false}}}));
is(scalar @failed, 1, 'a permanent failure resolves the callback');
is($failed[0][0], undef, 'a failed download delivers no file');
is($failed[0][1]{'@type'}, 'error', 'a failed download delivers an error');
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":91,"size":10,"local":{"@type":"localFile","is_downloading_active":false,"is_downloading_completed":false}}}));
is(scalar @failed, 1, 'the failure fires only once');

# --- a duplicate download id fails the second registration at once
my (@dup1, @dup2);
$td3->download(92, sub { push @dup1, [@_] });
$td3->download(92, sub { push @dup2, [@_] });
is(scalar @dup2, 1, 'a duplicate download fails at once');
is($dup2[0][0], undef, 'a duplicate download delivers no file');
like($dup2[0][1]{message}, qr/already in progress/, 'the duplicate error is clear');
is(scalar(grep { /"downloadFile"/ && /"file_id":92/ } @sent), 1,
    'the duplicate sends nothing');
is(scalar @dup1, 0, 'the first download is untouched');
my $extra_dup = extra_of($sent[-1]);
$td3->inject_raw(qq({"\@type":"file","id":92,"\@extra":"$extra_dup"}));
$td3->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":92,"size":10,"local":{"@type":"localFile","path":"/tmp/dup","downloaded_size":10,"is_downloading_completed":true}}}));
is(scalar @dup1, 1, 'the first download completes normally');
is($dup1[0][0]{local}{path}, '/tmp/dup', 'the first download delivers the file');
is(scalar @dup2, 1, 'the failed duplicate does not fire again');

# a cancelled download frees the id for a new one; the first request's late
# reply must not be handed to the replacement, failing it and swallowing its
# own reply
{
    my @outs;
    my $td4 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-files-stale',
        on_error => sub { },
    );
    @sent = ();
    $td4->download(9, sub { push @outs, ['a', $_[1] ? $_[1]{message} : 'ok'] });
    my ($first) = $sent[-1] =~ /"\@extra":"(\d+)"/;
    $td4->cancel_download(9);
    $td4->download(9, sub { push @outs, ['b', $_[1] ? $_[1]{message} : 'ok'] });
    $td4->inject_raw(qq({"\@type":"error","code":400,"message":"stale","\@extra":"$first"}));
    my @b = grep { $_->[0] eq 'b' } @outs;
    is scalar @b, 0, 'a stale reply is not delivered to the replacement download';
}

# user progress code runs before the module's own bookkeeping, so a die there
# must not strand a finished download unresolved
{
    my $done = 0;
    my $td5 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-files-die',
        on_error => sub { },
    );
    $td5->download(11, on_progress => sub { die "boom\n" }, sub { $done++ });
    $td5->inject_raw('{"@type":"updateFile","file":{"id":11,"size":10,"local":{"is_downloading_completed":true,"path":"/tmp/x"}}}');
    is $done, 1, 'a dying on_progress still resolves the download';
    is scalar keys %{ $td5->{cache}{downloads} || {} }, 0,
        'the finished download is unregistered even when on_progress dies';
}

# --- a download can be seen to start by an updateFile rather than by the
# reply, and the failure that follows must still be recognised. Everywhere
# else in this file the downloadFile reply arrives first and marks the
# download started, so the update doing it was never exercised.
{
    my @out;
    my $td6 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-files-active');
    $td6->download(21, sub { push @out, [@_] });
    # active, with no reply yet
    $td6->inject_raw('{"@type":"updateFile","file":{"id":21,"size":10,"local":{"is_downloading_active":true,"is_downloading_completed":false}}}');
    is scalar @out, 0, 'an active update alone resolves nothing';
    # neither active nor completed, after a start: a permanent failure
    $td6->inject_raw('{"@type":"updateFile","file":{"id":21,"size":10,"local":{"is_downloading_active":false,"is_downloading_completed":false}}}');
    is scalar @out, 1, 'the failure that follows is delivered';
    is $out[0][1]{message}, 'download failed', 'as a download failure';
    is scalar keys %{ $td6->{cache}{downloads} || {} }, 0,
        'and the registration is dropped';
}

done_testing;
