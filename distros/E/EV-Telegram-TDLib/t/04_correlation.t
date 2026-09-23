use strict;
use warnings;
use Test::More;
use EV;
use EV::Telegram::TDLib;

my $td = EV::Telegram::TDLib->new(
    api_id    => 1,
    api_hash  => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-corr',
);

my (@updates, @replies);
$td->on_update(sub { push @updates, $_[0] });

$td->send({ '@type' => 'getMe' }, sub { push @replies, [@_] });

my ($extra) = keys %{ $td->{pending} };
ok defined $extra, 'the request was recorded as pending with an @extra';

$td->inject_raw(qq({"\@type":"user","id":42,"\@extra":"$extra"}));
is scalar @replies, 1, 'the reply reached the callback';
is $replies[0][0]{id}, 42, 'result is decoded';
is $replies[0][1], undef, 'no error on success';
ok !%{ $td->{pending} }, 'pending entry was cleared';

$td->send({ '@type' => 'getMe' }, sub { push @replies, [@_] });
my ($extra2) = keys %{ $td->{pending} };
$td->inject_raw(
    qq({"\@type":"error","code":400,"message":"nope","\@extra":"$extra2"}));
is $replies[1][0], undef, 'error delivers undef as the result';
is $replies[1][1]{code}, 400, 'error object is the second argument';

$td->inject_raw(q({"@type":"updateNewChat","chat":{"id":7}}));
is scalar @updates, 1, 'an object with no @extra is an update';
is $updates[0]{chat}{id}, 7, 'update payload decoded';

my $big = '7331982750000123457';
$td->send({ '@type' => 'getChat' }, sub { push @replies, [@_] });
my ($extra3) = keys %{ $td->{pending} };
$td->inject_raw(qq({"\@type":"chat","id":$big,"\@extra":"$extra3"}));
is "$replies[2][0]{id}", $big, 'int64 ids survive the round trip exactly';

# --- an unmatched @extra is a reply, not an update: warn and drop
my @warn4;
{
    local $SIG{__WARN__} = sub { push @warn4, $_[0] };
    $td->inject_raw(qq({"\@type":"user","id":43,"\@extra":"999999"}));
}
is scalar @updates, 1, 'an unmatched @extra reply is not dispatched as an update';
is scalar @replies, 3, 'no pending callback fired';
like $warn4[0], qr/unknown request 999999/, 'the unmatched reply warned';

done_testing;
