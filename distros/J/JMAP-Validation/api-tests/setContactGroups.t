#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Tester;
use JMAP::Validation::Checks::ContactGroup;
use JMAP::Validation::Checks::Error;
use JMAP::Validation::Generators;
use JMAP::Validation::Generators::ContactGroup;
use JMAP::Validation::Generators::String;
use JSON::PP;
use JSON::Typist;
use Test2::Bundle::Extended;
use Test::Deep qw{eq_deeply};

my (
  %ACCOUNT,
  %STATE,
  @TESTS,
);

init();
do_tests();
done_testing();

sub _define_error_tests {
  push @TESTS, {
    is_error  => 1,
    type      => 'accountNotFound',
  };

  # TODO: accountReadOnly
  # TODO: accountNoContacts

  my @accountIds = qw{
    ok
    true false
    negative_int negative_real
    zero
    int real
    array
    object
  };

  my @ifInStates = qw{
    ok
    true false
    negative_int negative_real
    zero
    int real
    array
    object
  };

  my @creates = qw{
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
    array_string array_array array_object
  };

  my @updates = qw{
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
    array_string array_array array_object
  };

  my @destroys = qw{
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
    foreach my $ifInState (@ifInStates) {
      foreach my $create (@creates) {
        foreach my $update (@updates) {
          foreach my $destroy (@destroys) {
            my @oks = grep { $_ eq 'ok' } $accountId, $ifInState, $create, $update, $destroy;
            next if (scalar(@oks) == 5);

            push @TESTS, {
              is_error  => 1,
              type      => 'invalidArguments',
              accountId => $accountId,
              ifInState => $ifInState,
              create    => $create,
              update    => $update,
              destroy   => $destroy,
            };
          }
        }
      }
    }
  }

  # TODO: - stateMismatch
  # TODO: - for create/update/create
  # TODO:   - notFound
  # TODO:   - invalidProperties
}

sub _define_good_tests {
  my @update;

  foreach my $update_name (qw{change same}) {
    foreach my $update_contactIds (qw{change same}) {
      # TODO: change
      next if $update_contactIds eq 'change';

      push @update, {
        name       => $update_name,
        contactIds => $update_contactIds,
      };
    }
  }

  foreach my $accountId (qw{supplied omit null}) {
    foreach my $state (qw{supplied omit null}) {
      foreach my $create (qw{create omit null empty}) {
        foreach my $update (@update, qw{omit null empty}) {
          foreach my $destroy (qw{destroy omit null empty}) {
            push @TESTS, {
              accountId => $accountId,
              state     => $state,
              create    => $create,
              update    => $update,
              destroy   => $destroy,
            };
          }
        }
      }
    }
  }
}

sub do_tests {
  foreach my $test (@TESTS) {
    _reset_state();

    my $request_args = $test->{is_error}
      ? _build_error_request($test)
      : _build_good_request($test);


    my $result = $ACCOUNT{jmap}->request([["setContactGroups", $request_args]])
      or die "Error setting contact groups\n";

    if ($test->{is_error}) {
      my $error = $result && $result->sentence(0) && $result->sentence(0)->as_struct();

      is($error, $JMAP::Validation::Checks::Error::is_error);
      is($error, _build_error_response($test));

      next;
    }

    my $contactGroupSet = $result && $result->sentence(0) && $result->sentence(0)->arguments();

    is($contactGroupSet, $JMAP::Validation::Checks::ContactGroup::is_contactGroupsSet);
    is($contactGroupSet, _build_good_response($test));
  }
}

sub init {
  unless (scalar(@ARGV) == 1) {
    # TODO: add authentication via access token
    die "usage: $0 <accountId:jmap-account-uri>\n";
  }

  my ($accountId, $uri) = $ARGV[0] =~ /([^:]+):(.*)/;

  unless ($accountId and $uri) {
    die "Parameter not in the format <accountId:jmap-account-uri>\n";
  }

  %ACCOUNT = (
    accountId      => $accountId,
    jmap           => JMAP::Tester->new({ jmap_uri => $uri }),
    contact_groups => [
      map {
        {
          name       => JMAP::Validation::Generators::String->generate(),
          contactIds => [], # TODO: need to create real contact
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
    );
  }

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
      }->{$test->{accountId}},
      ifInState => {
        true          => JMAP::Validation::Generators::true(),
        false         => JMAP::Validation::Generators::false(),
        negative_int  => JMAP::Validation::Generators::negative_int(),
        negative_real => JMAP::Validation::Generators::negative_real(),
        zero          => JMAP::Validation::Generators::zero(),
        int           => JMAP::Validation::Generators::int(),
        real          => JMAP::Validation::Generators::real(),
        array         => [],
        object        => {},
        ok            => JSON::PP::null,
      }->{$test->{ifInState}},
      create => {
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
        array_string        => [JMAP::Validation::Generators::string()],
        array_object        => [{}],
        ok                  => []
      }->{$test->{create}},
      update => {
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
        array_string        => [JMAP::Validation::Generators::string()],
        array_object        => [{}],
        ok                  => []
      }->{$test->{update}},
      destroy => {
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
        ok                  => [],
      }->{$test->{destroy}},
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

  my $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {}]])
    or die "Error getting contact groups\n";

  unless ($test->{state} eq 'omit') {
    my $state = $contactGroups->sentence(0)->arguments()->{state}
      or die "Error getting contact group\n";

    $request_args{ifInState} = {
      supplied => $state,
      null     => JSON::PP::null,
    }->{$test->{state}};
  }

  unless ($test->{create} eq 'omit') {
    my @createdContactGroups = JMAP::Validation::Generators::ContactGroup::generate(no_id => 1);

    $request_args{create} = {
      create => { map { $STATE{i}++ => $_ } @createdContactGroups },
      empty  => {},
      null   => JSON::PP::null,
    }->{$test->{create}};

    $STATE{created} = $request_args{create};
  }

  unless ($test->{update} eq 'omit') {
    my $update = ref ($test->{update})
      ? _update_request_args($test->{update})
      : '';

    $request_args{update} = {
      update => $update,
      empty  => {},
      null   => JSON::PP::null,
    }->{ref($test->{update}) ? 'update' : $test->{update}};
  }

  unless ($test->{destroy} eq 'omit') {
    $request_args{destroy} = {
      destroy => [ map { $_->{id} } @{$contactGroups->sentence(0)->arguments()->{list} || []}],
      null    => JSON::PP::null,
      empty   => [],
    }->{$test->{destroy}};

    $STATE{destroyed} = $request_args{destroy};
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

    # TODO: oldState
    # TODO: newState

    field created => validator(sub {
      my (%params) = @_;

      my $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {}]])
        or die "Error getting contact groups\n";

      my %contactGroupsByName
        = map { $_->{name} => $_->{id} }
            @{$contactGroups->sentence(0)->arguments()->{list} || []};

      my %created;

      foreach my $createdId (keys %{$STATE{created} || {}}) {
        $created{$createdId}{id} = $contactGroupsByName{$STATE{created}{$createdId}{name}};
      }

      return eq_deeply(
        \%created,
        $params{got},
      );
    });

    field updated => validator(sub {
      my (%params) = @_;

      return eq_deeply(
         [sort { $a cmp $b } @{$STATE{updated} || []}],
         [sort { $a cmp $b } @{$params{got}    || []}],
      );
    });

    field destroyed => validator(sub {
      my (%params) = @_;

      return eq_deeply(
        [sort { $a cmp $b } @{$STATE{destroyed} || []}],
        [sort { $a cmp $b } @{$params{got}      || []}],
      );
    });

    field notCreated   => hash { end() };
    field notUpdated   => hash { end() };
    field notDestroyed => hash { end() };
  };

  return $response_check;
}

sub _reset_state {
  %STATE = (
    i => 1,
  );

  # TODO: prevent race in proxy
  sleep 1;

  my $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {}]])
    or die "Error getting contact groups\n";

  # TODO: prevent race in proxy
  sleep 1;

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

  # TODO: prevent race in proxy
  sleep 1;

  $ACCOUNT{jmap}->request([
    [
      "setContactGroups",
      {
        create  => { map { $STATE{i}++ => $_ } @{$ACCOUNT{contact_groups}} },
        update  => {},
        destroy => [],
      },
    ],
  ]) or die "Error creating contact groups\n";

  # TODO: prevent race in proxy
  sleep 1;

  $contactGroups = $ACCOUNT{jmap}->request([["getContactGroups", {}]])
    or die "Error getting contact groups\n";

  my %keyed_contactGroups
    = map { $_->{name} => $_ }
        @{$contactGroups->sentence(0)->arguments()->{list} || []};

  foreach my $contact_group (@{$ACCOUNT{contact_groups}}) {
    die "Error getting contact group\n"
      unless exists $keyed_contactGroups{$contact_group->{name}};

    push @{$STATE{contact_groups}}, $keyed_contactGroups{$contact_group->{name}};
  }
}

sub _update_request_args {
  my ($test) = @_;

  my %update_args;

  foreach my $contactGroup (@{$STATE{contact_groups}}) {
    unless ($test->{name} eq 'omit') {
      $update_args{$contactGroup->{id}}{name} = {
        change => JMAP::Validation::Generators::String->generate(),
        same   => $contactGroup->{name},
      }->{$test->{name}};
    }

    unless ($test->{contactIds} eq 'omit') {
      $update_args{$contactGroup->{id}}{contactIds} = {
        # TODO: change
        same   => $contactGroup->{contactIds},
      }->{$test->{name}};
    }

    if (grep { $test->{$_} =~ /change|same/ } qw{name contactIds}) {
      push @{$STATE{updated}}, $contactGroup->{id};
    }
  }

  return \%update_args;
}
