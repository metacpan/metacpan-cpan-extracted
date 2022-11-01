use Test2::V0 -no_srand => 1;
use Test2::Tools::Subtest qw( subtest_streamed );
use experimental qw( signatures );
use Time::HiRes qw( time );
use Memcached::RateLimit;
use YAML ();

subtest_streamed 'basic create without use' => sub {

  my $rl = Memcached::RateLimit->new("memcache://127.0.0.1:12345?timeout=10&tcp_nodelay=true");
  isa_ok $rl, 'Memcached::RateLimit';

  note YAML::Dump($rl);

  # this should destroy
  undef $rl;

};

sub time_it :prototype(&) {
  my $code = shift;
  my $start = time;
  $code->();
  note "clocking in at: @{[ time - $start ]}s";
}

sub slow_down {
  note "sleeping for 2s";
  sleep 2;
}

my %name = (
  simple => 'MEMCACHED_RATELIMIT_TEST',
  tls    => 'MEMCACHED_RATELIMIT_TLS_TEST',
  slow   => 'MEMCACHED_RATELIMIT_TEST,MEMCACHED_RATELIMIT_TEST_SLOW',
);

my %scheme = (
  simple => 'memcache+tcp',
  tls    => 'memcache+tls',
  slow   => 'memcache+tcp',
);

subtest_streamed 'live tests' => sub {

  my $i = 1;

  foreach my $name (sort keys %name) {

    subtest_streamed $name => sub {

      foreach my $env (split /,/, $name{$name})
      {
        skip_all "Set $name{$name} to run tests"
          unless defined $ENV{$env};
      }

      my($host, $port) = split /:/, $ENV{[split /,/, $name{$name}]->[0]};
      $host ||= '127.0.0.1';
      $port ||= 11211;

      # note: connect_timeout not yet recognized, but hopefully will be soon
      my $url = "$scheme{$name}://$host:$port?timeout=5.5&connect_timeout=5.5";
      $url .= "&verify_mode=none" if $name eq 'tls';
      note "using $url";

      my $rl = Memcached::RateLimit->new($url);
      isa_ok $rl, 'Memcached::RateLimit';

      note YAML::Dump($rl);

      my @error;

      $rl->error_handler(sub ($rl,$message) {
        push @error, $message;
        note "error:$message";
      });

      my $key = "frooble-$$-@{[ $i++ ]}";
      note "using key: $key";

      time_it {
        is(
          $rl->rate_limit($key, 1, 20, 60),
          0,
          '$rl->rate_limit($key, 1, 20, 60) = 0');
      };

      slow_down if $name eq 'slow';

      time_it {
        is(
          $rl->rate_limit($key, 19, 20, 60),
          0,
          '$rl->rate_limit($key, 19, 20, 60) = 0');
      };

      slow_down if $name eq 'slow';

      time_it {
        is(
          $rl->rate_limit($key, 1, 20, 60),
          1,
          '$rl->rate_limit($key, 1, 20, 60) = 1');
      };

      is \@error, [], 'no errors';

      # this should destroy
      undef $rl;

    };
  }
};

subtest_streamed 'hash config' => sub {

  is
    [Memcached::RateLimit::_hash_to_url()],
    ["memcache://127.0.0.1:11211", undef, undef, undef],
    'default';

  is
    [Memcached::RateLimit::_hash_to_url(
       scheme          => 'memcache+tls',
       read_timeout    => 0.4,
       write_timeout   => 0.5,
       host            => '1.2.3.4',
       port            => 12345,
       connect_timeout => 0.2,
       protocol        =>'ascii',
       timeout         => 0.3,
       retry           => 10,
       verify_mode     => 'none' )],
    ['memcache+tls://1.2.3.4:12345?connect_timeout=0.2&protocol=ascii&timeout=0.3&verify_mode=none',0.4,0.5,10],
    'the works';

  is
    [Memcached::RateLimit::_hash_to_url( host => '::1')],
    ['memcache://%3A%3A1:11211', undef, undef, undef],
    'IPv6';

  is
    dies { Memcached::RateLimit::_hash_to_url( x => 'y', z => 1, ) },
    match qr/Unknown options: x z/,
    'error on invalid arg';
};

subtest_streamed 'retry' => sub {

  my @ret;
  my @error;

  my $mock = mock 'Memcached::RateLimit' => (
      override => [
        _rate_limit => sub {
          shift @ret;
        },
        _error => sub {
          shift @error;
        },
      ],
  );

  my $rl = Memcached::RateLimit->new({
    retry => 3,
  });

  my @cb_error;
  my @cb_final_error;

  $rl->error_handler(sub ($, $message) {
    push @cb_error, $message;
  });

  $rl->final_error_handler(sub ($, $message) {
    push @cb_final_error, $message;
  });

  subtest 'default for instance (3)' => sub {
      @ret   = (-1,-1,-1);
      @error = ('err1','err2','err3');
      @cb_error       = ();
      @cb_final_error = ();

      is(
        $rl->rate_limit("key", 1, 20, 60),
        0,
        'fail open');

      is
        \@cb_error,
        [ 'err1','err2','err3'],
        'error callback';

      is
        \@cb_final_error,
        ['err3'],
        'final error callback';

  };

  subtest 'override instance default when calling (2)' => sub {
      @ret            = (-1,-1,-1);
      @error          = ('err1','err2','err3');
      @cb_error       = ();
      @cb_final_error = ();

      is(
        $rl->rate_limit("key", 1, 20, 60, 2),
        0,
        'fail open');

      is
        \@cb_error,
        [ 'err1','err2'],
        'error callback';

      is
        \@cb_final_error,
        ['err2'],
        'final error callback';

  };

  # don't perminently delete, because we want to check that the our
  # variables have been cleaned up later.
  local $Memcached::RateLimit::retry{$$rl} = $Memcached::RateLimit::retry{$$rl};
  delete $Memcached::RateLimit::retry{$$rl};

  subtest 'regular default' => sub {
      @ret            = (-1,-1,-1);
      @error          = ('err1','err2','err3');
      @cb_error       = ();
      @cb_final_error = ();

      is(
        $rl->rate_limit("key", 1, 20, 60),
        0,
        'fail open');

      is
        \@cb_error,
        [ 'err1'],
        'error callback';

      is
        \@cb_final_error,
        ['err1'],
        'final error callback';

  };

};

subtest_streamed 'counterfit object!' => sub {

  my $rl = bless \do { my $x = 42}, 'Memcached::RateLimit';
  isa_ok $rl, 'Memcached::RateLimit';

  note YAML::Dump($rl);

  my @error;

  $rl->error_handler(sub ($rl,$message) {
    push @error, $message;
    note "error:$message";
  });

  is(
    $rl->rate_limit("frooble-$$", 1, 20, 60),
    0,
    '$rl->rate_limit("frooble-$$", 1, 20, 60) = 0');

  is
    \@error,
    ["Invalid object index"],
    "expected error";

  undef $rl;
};

subtest_streamed 'cleanup' => sub {

  is
    \%Memcached::RateLimit::retry,
    {},
    'retry';

  is
    \%Memcached::RateLimit::error_handler,
    {},
    'error_handler';

  is
    \%Memcached::RateLimit::final_error_handler,
    {},
    'final_error_handler';

};

done_testing;
