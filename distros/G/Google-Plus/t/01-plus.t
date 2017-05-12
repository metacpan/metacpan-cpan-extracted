#!/usr/bin/env perl
use Test::Most;
use Net::Ping;

BEGIN {
  plan skip_all => 'these tests are not for smoke testing'
    if $ENV{AUTOMATED_TESTING};
  plan skip_all => 'Needs Google+ API key in %ENV'
    unless $ENV{GOOGLE_PLUS_API_KEY};

  my $p = Net::Ping->new('syn', 2);
  $p->port_number(scalar getservbyname(https => 'tcp'));
  $p->service_check(1);
  plan skip_all => 'Needs access to remote Google API endpoint'
    unless $p->ping('www.googleapis.com');

  plan tests => 4;
}

use Google::Plus;

# Google+Zak
my $user_id = '112708775709583792684';

my $g;
subtest 'create object' => sub {
  plan tests => 5;

  can_ok 'Google::Plus' => 'new';
  throws_ok { Google::Plus->new } qr/key.+required/, 'needs API key';
  throws_ok { Google::Plus->new(blah => 'ther') } qr/key.+required/,
    'bad key';

  $g = new_ok 'Google::Plus', [key => $ENV{GOOGLE_PLUS_API_KEY}];
  ok ref $g => 'Made object';
};

my $person;
subtest 'get person profile' => sub {
  plan tests => 7;

  can_ok $g => 'person';

  throws_ok { $g->person } qr/ID.+required/, 'needs user ID';
  throws_ok { $g->person('foo') } qr/Invalid/, 'user ID must be numeric';
  throws_ok { $g->person('00000000000000000000') } qr/unable to map/,
    'bad person';

  $person = $g->person($user_id);
  isa_ok $person => 'HASH';

  subtest 'person properties' => sub {
    plan tests => 10;

    ok $person->{$_}, "$_ exists"
      for qw/ aboutMe displayName gender id image organizations placesLived
      tagline url urls /;
  };

  subtest 'person profile partial response' => sub {
    plan tests => 6;

    my @fields = qw(displayName gender aboutMe);

    my $partial = $g->person($user_id, join ',' => @fields);
    isa_ok $partial => 'HASH', 'got partial response for person';

    ok $partial->{$_}, "$_ exists in partial response" for @fields;

    ok !exists $partial->{birthday}, "birthday should not be in response";

    throws_ok { $g->person($user_id, 'invalid,fields') } qr/Invalid field/,
      "partial response using invalid field names";
  };
};

my $activities;
subtest 'get person activities' => sub {
  plan tests => 8;

  can_ok $g => 'activities';

  throws_ok { $g->activities } qr/ID.+required/, 'needs user ID';
  throws_ok { $g->activities('foo') } qr/Invalid/, 'user ID must be numeric';
  throws_ok { $g->activities('00000000000000000000') } qr/unable to map/,
    'bad person';

  subtest 'get person activities per collection' => sub {
    plan tests => 3;

    $activities = $g->activities($user_id);
    isa_ok $activities => 'HASH', 'get activities (default public)';

    $activities = $g->activities($user_id => 'public');
    isa_ok $activities => 'HASH', 'get activities (explicit public)';

  SKIP: {
      skip 'no custom collections for activities/list yet', 1;
      $activities = $g->activities($user_id => 'cats');
      isa_ok $activities => 'HASH', 'get activities (custom collection)';
    }
  };

  subtest 'activity list properties' => sub {
    plan tests => 7;

    ok $activities->{$_}, "$_ in activity list exists"
      for qw/ id items nextLink nextPageToken selfLink title updated /;
  };

  subtest 'next activity list' => sub {
    plan tests => 8;

    my $next =
      $g->activities($user_id => 'public', $activities->{nextPageToken});
    isnt $next->{nextPageToken}, $activities->{nextPageToken},
      'got new activity list (the next page)';
    ok $next->{$_}, "$_ in next activity list exists"
      for qw/ id items nextLink nextPageToken selfLink title updated /;
  };

  subtest 'activity list partial response' => sub {
    plan tests => 5;

    my @fields = qw(selfLink nextLink);

    my $partial = $g->activities($user_id, undef, undef, join ',' => @fields);
    isa_ok $partial => 'HASH', 'got partial response for activity list';

    ok $partial->{$_}, "$_ exists in partial response" for @fields;

    ok !exists $partial->{title}, "title should not be in response";

    throws_ok { $g->activities($user_id, undef, undef, 'invalid,fields') }
    qr/Invalid field/, "partial response using invalid field names";
  };
};

# Google+ is the _vehicle_, Google Hangouts is the _product_.
my $post = 'z13uxtsawqqwwbcjt04cdhsxcnfyir44xeg';

my $activity;
subtest 'get activity' => sub {
  plan tests => 7;

  can_ok $g => 'activity';

  throws_ok { $g->activity } qr/ID.+required/, 'needs activity ID';
  throws_ok { $g->activity('$!@$@#$') } qr/Invalid activity/, 'bad activity';
  throws_ok { $g->activity('foobarbaz') } qr/Unable to find activity/,
    'no activity named "foobarbaz"';

  $activity = $g->activity($post);
  isa_ok $activity => 'HASH';

  subtest 'activity properties' => sub {
    plan tests => 10;

    ok $activity->{$_}, "activity property $_ exists"
      for qw/ access actor annotation id object published title updated
      url verb /;
  };

  subtest 'activity detail partial response' => sub {
    plan tests => 7;

    my @fields = qw(id title object url);

    my $partial = $g->activity($post, join ',' => @fields);
    isa_ok $partial => 'HASH', 'got partial response for activity';

    ok $partial->{$_}, "$_ exists in partial response" for @fields;

    ok !exists $partial->{updated},
      'updated property should not be in response';

    # Google throws a 404 here unlike when requesting other partials
    throws_ok { $g->activities($post, 'invalid,fields') } qr/Not Found/,
      "partial response using invalid field names";
  };
};
