#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Tester;
use JMAP::Validation::Checks::ContactGroup;
use JMAP::Validation::Checks::Error;
use JMAP::Validation::Generators;
use JSON::PP;
use JSON::Typist;
use Test2::Bundle::Extended;
use Test::Deep qw{eq_deeply};

my (
  %ACCOUNT,
  $STATE,
  @TESTS,
);

init();
do_tests();
done_testing();

sub _define_error_tests {
  my @accountIds = qw{
    ok
    true false
    negative_int negative_real
    zero
    int real
    array
    object
  };

  my @ids = qw{
    ok
    true false
    negative_int negative_real
    zero
    int real
    string
    object
    array_true array_false
    array_negative_int array_negative_real
    array_zero
    array_int array_real
    array_array array_object
  };

  foreach my $accountId (@accountIds) {
    foreach my $ids (@ids) {
      next if ($accountId eq 'ok') && ($ids eq 'ok');

      push @TESTS, {
        is_error  => 1,
        type      => 'invalidArguments',
        accountId => $accountId,
        ids       => $ids,
      };
    }
  }

  push @TESTS, {
    is_error  => 1,
    type      => 'accountNotFound',
  };

  # TODO: accountNoContacts
}

sub _define_good_tests {
  foreach my $accountId (qw{supplied omit null}) {
    foreach my $ids (qw{even odd some_not_found all_not_found omit empty null}) {
      push @TESTS, {
        accountId => $accountId,
        ids       => $ids,
      };
    }
  }
}

sub do_tests {
  _reset_state();

  foreach my $test (@TESTS) {
    my $request_args = $test->{is_error}
      ? _build_error_request($test)
      : _build_good_request($test);

    my $result = $ACCOUNT{jmap}->request([["getContactGroups", $request_args]])
      or die "Error getting contact groups\n";

    if ($test->{is_error}) {
      my $error = $result && $result->sentence(0) && $result->sentence(0)->as_struct();

      is($error, $JMAP::Validation::Checks::Error::is_error);
      is($error, _build_error_response($test));

      next;
    }

    my $contactGroups = $result && $result->sentence(0) && $result->sentence(0)->arguments();

    is($contactGroups, $JMAP::Validation::Checks::ContactGroup::is_contactGroups);
    is($contactGroups, _build_good_response($test));
  }
}

sub init {
  unless (scalar(@ARGV) == 1) {
    # TODO: add authentication via access token
    die "usage: $0 <accountId:jmap-account-uri>\n";
  }

  my ($accountId, $uri) = $ARGV[0] =~ /([^:]+):(.*)/;

  unless ($accountId and $uri) {
    die "Parameters are not in the following format <accountId:jmap-account-uri>\n";
  }

  %ACCOUNT = (
    accountId      => $accountId,
    jmap           => JMAP::Tester->new({ jmap_uri => $uri }),
    contact_groups => [
      map {
        {
          name       => JMAP::Validation::Generators::string(),
          contactIds => [], # TODO need to create real contact
        }
      } 1..6
    ],
  );

  _define_error_tests();
  _define_good_tests();
}

sub _build_error_request {
  my ($test) = @_;

  my %request_args;

  if ($test->{type} eq 'accountNotFound') {
    %request_args = (
      accountId => JMAP::Validation::Generators::string(),
      ids       => [JMAP::Validation::Generators::string()],
    );
  }

  # TODO: accountNoContacts

  if ($test->{type} eq 'invalidArguments') {
    %request_args = (
      accountId => {
        true          => JMAP::Validation::Generators::true(),
        false         => JMAP::Validation::Generators::false(),
        negative_int  => JMAP::Validation::Generators::negative_int(),
        negative_real => JMAP::Validation::Generators::negative_real(),
        zero          => JMAP::Validation::Generators::zero(),
        int           => JMAP::Validation::Generators::int(),
        real          => JMAP::Validation::Generators::real(),
        array         => [],
        object        => {},
        ok            => $ACCOUNT{accountId},
      }->{$test->{accountId} || 'ok'},
      ids => {
        true                => JMAP::Validation::Generators::true(),
        false               => JMAP::Validation::Generators::false(),
        negative_int        => JMAP::Validation::Generators::negative_int(),
        negative_real       => JMAP::Validation::Generators::negative_real(),
        zero                => JMAP::Validation::Generators::zero(),
        int                 => JMAP::Validation::Generators::int(),
        real                => JMAP::Validation::Generators::real(),
        string              => JMAP::Validation::Generators::string(),
        object              => {},
        array_true          => [JMAP::Validation::Generators::true()],
        array_false         => [JMAP::Validation::Generators::false()],
        array_negative_int  => [JMAP::Validation::Generators::negative_int()],
        array_negative_real => [JMAP::Validation::Generators::negative_real()],
        array_zero          => [JMAP::Validation::Generators::zero()],
        array_int           => [JMAP::Validation::Generators::int()],
        array_real          => [JMAP::Validation::Generators::real()],
        array_array         => [[]],
        array_object        => [{}],
        ok                  => [JMAP::Validation::Generators::string()],
      }->{$test->{ids} || 'ok'},
    );
  }

  return \%request_args;
}

sub _build_good_request {
  my ($test) = @_;

  my %request_args;

  unless ($test->{accountId} eq 'omit') {
    $request_args{accountId} = {
      supplied => $ACCOUNT{accountId},
      null     => JSON::PP::null,
    }->{$test->{accountId}};
  }

  unless ($test->{ids} eq 'omit') {
    $request_args{ids} = {
      even           => [map { $_->{id} } @{$STATE->{contact_groups}}[1, 3, 5]],
      odd            => [map { $_->{id} } @{$STATE->{contact_groups}}[0, 2, 4]],
      some_not_found => [
        (map { $_->{id} } @{$STATE->{contact_groups}}[2, 5]),
        qw{some ids do not exist}
      ],
      all_not_found  => [qw{these ids do not exist}],
      empty          => [],
      null           => JSON::PP::null,
    }->{$test->{ids}};
  }

  return \%request_args;
}

sub _build_error_response {
  my ($test) = @_;

  my $response_check = array {
    item 1 => hash {
      field type => string($test->{type}),
    };
  };

  return $response_check;
}

sub _build_good_response {
  my ($test) = @_;

  my $response_check = hash {
    field accountId => string(JSON::Typist::String->new($ACCOUNT{accountId}));

    # TODO: state

    my $list = {
      even           => [@{$STATE->{contact_groups}}[1, 3, 5]],
      odd            => [@{$STATE->{contact_groups}}[0, 2, 4]],
      some_not_found => [@{$STATE->{contact_groups}}[2, 5]],
      all_not_found  => [],
      omit           => [@{$STATE->{contact_groups}}[0..5]],
      null           => [@{$STATE->{contact_groups}}[0..5]],
      empty          => [],
    }->{$test->{ids}};

    field list => validator(sub {
      my (%params) = @_;

      return eq_deeply(
        [sort { $a->{id} cmp $b->{id} } @{$list        || []}],
        [sort { $a->{id} cmp $b->{id} } @{$params{got} || []}]
      );
    });

    my $notFound = {
      even           => JSON::PP::null,
      odd            => JSON::PP::null,
      some_not_found => [map { JSON::Typist::String->new($_) } qw{some ids do not exist}],
      all_not_found  => [map { JSON::Typist::String->new($_) } qw{these ids do not exist}],
      omit           => JSON::PP::null,
      null           => JSON::PP::null,
      empty          => JSON::PP::null,
    }->{$test->{ids}};

    field notFound => validator(sub {
      my (%params) = @_;

      return eq_deeply(
        [sort @{$notFound    || []}],
        [sort @{$params{got} || []}]
      );
    });
  };

  return $response_check;
}

sub _reset_state {
  $STATE = {};

  my $creation_id = 0;

  my $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {}]])
    or die "Error getting contact groups\n";

  $ACCOUNT{jmap}->request([
    [
      "setContactGroups",
      {
        create  => {},
        update  => {},
        destroy => [ map { $_->{id} } @{$contactGroups->sentence(0)->arguments()->{list} || []}],
      },
    ],
  ]) or die "Error deleting contact groups\n";

  $ACCOUNT{jmap}->request([
    [
      "setContactGroups",
      {
        create  => { map { $creation_id++ => $_ } @{$ACCOUNT{contact_groups}} },
        update  => {},
        destroy => [],
      },
    ],
  ]) or die "Error creating contact groups\n";

  $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {} ]])
    or die "Error getting contact groups\n";

  my %keyed_contactGroups
    = map { $_->{name} => $_ }
        @{$contactGroups->sentence(0)->arguments()->{list} || []};

  foreach my $contact_group (@{$ACCOUNT{contact_groups}}) {
    die "Error getting contact group\n"
      unless exists $keyed_contactGroups{$contact_group->{name}};

    push @{$STATE->{contact_groups}}, $keyed_contactGroups{$contact_group->{name}};
  }
}
