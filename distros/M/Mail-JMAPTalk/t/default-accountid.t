use strict;
use warnings;
use Test::More;
use JSON;

use Mail::JMAPTalk;

# A user agent that records what was posted and answers an empty JMAP response.
package FakeUA {
  sub new { bless { posts => [] }, shift }
  sub post {
    my ($self, $uri, $opts) = @_;
    push @{ $self->{posts} }, { uri => $uri, %$opts };
    return { success => 1, status => 200, reason => 'OK',
             content => '{"methodResponses":[],"sessionState":"s"}' };
  }
  sub last_calls {
    my ($self) = @_;
    return JSON->new->decode($self->{posts}[-1]{content})->{methodCalls};
  }
}

my $ua = FakeUA->new;

subtest "no default configured: calls go out untouched" => sub {
  my $jt = Mail::JMAPTalk->new(ua => $ua, user => 'u', password => 'p');
  $jt->CallMethods([['Mailbox/get', {}, 'R1']]);
  is_deeply($ua->last_calls, [['Mailbox/get', {}, 'R1']], 'no accountId invented');
};

subtest "default accountId is added to every call that lacks one" => sub {
  my $jt = Mail::JMAPTalk->new(ua => $ua, user => 'u', password => 'p',
                               accountId => 'acct');
  is($jt->accountId, 'acct', 'accessor reads the default');

  my $args = { ids => ['x'] };
  $jt->CallMethods([
    ['Mailbox/get',  $args,                              'R1'],
    ['Mailbox/get',  { accountId => 'other' },           'R2'],
    ['Mailbox/get',  { '#accountId' => { resultOf => 'R1', name => 'Mailbox/get', path => '/accountId' } }, 'R3'],
    ['Core/echo',    { hello => 'world' },               'R4'],
  ]);
  my $calls = $ua->last_calls;
  is_deeply($calls->[0][1], { ids => ['x'], accountId => 'acct' }, 'missing accountId filled in');
  is_deeply($calls->[1][1], { accountId => 'other' },              'explicit accountId kept');
  ok(!exists $calls->[2][1]{accountId}, 'a #accountId reference is left to the server');
  is_deeply($calls->[3][1], { hello => 'world' },                  'Core/echo gets none');
  is_deeply($args, { ids => ['x'] }, "the caller's arguments are not modified");
};

subtest "copy methods get both sides" => sub {
  my $jt = Mail::JMAPTalk->new(ua => $ua, accountId => 'acct');
  $jt->CallMethods([
    ['Email/copy', { create => {} },                       'R1'],
    ['Email/copy', { accountId => 'dest', create => {} },  'R2'],
    ['Blob/copy',  { fromAccountId => 'src', blobIds => [] }, 'R3'],
  ]);
  my $calls = $ua->last_calls;
  is_deeply($calls->[0][1], { fromAccountId => 'acct', accountId => 'acct', create => {} },
    'both sides defaulted');
  is_deeply($calls->[1][1], { fromAccountId => 'acct', accountId => 'dest', create => {} },
    'source defaulted, explicit destination kept');
  is_deeply($calls->[2][1], { fromAccountId => 'src', accountId => 'acct', blobIds => [] },
    'explicit source kept, destination defaulted');
};

subtest "the default can be changed and cleared" => sub {
  my $jt = Mail::JMAPTalk->new(ua => $ua, accountId => 'acct');
  $jt->accountId('second');
  $jt->CallMethods([['Mailbox/get', {}, 'R1']]);
  is($ua->last_calls->[0][1]{accountId}, 'second', 'changed default is used');
  $jt->accountId(undef);
  $jt->CallMethods([['Mailbox/get', {}, 'R1']]);
  ok(!exists $ua->last_calls->[0][1]{accountId}, 'cleared default adds nothing');
};

subtest "Upload uses the default accountId in its URL" => sub {
  my $jt = Mail::JMAPTalk->new(ua => $ua, user => 'u', password => 'p',
                               accountId => 'acct');
  my ($res, $data) = $jt->Upload('bytes', 'text/plain');
  like($ua->{posts}[-1]{uri}, qr{/jmap/upload/acct/}, 'default accountId in upload URI');
  $jt->Upload('bytes', 'text/plain', 'explicit');
  like($ua->{posts}[-1]{uri}, qr{/jmap/upload/explicit/}, 'an explicit accountId wins');
};

done_testing;
