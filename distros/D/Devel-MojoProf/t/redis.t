use Mojo::Base -strict;
use Devel::MojoProf -redis;
use Test::More;

$ENV{TEST_REDIS} = 'redis://localhost' if $ENV{TEST_ALL};
plan skip_all => 'TEST_REDIS=redis://localhost' unless $ENV{TEST_REDIS};

my @report;
Devel::MojoProf->singleton->reporter(sub {
  push @report, $_[1];
  shift->Devel::MojoProf::_default_reporter(@_) if $ENV{HARNESS_IS_VERBOSE};
});

my $redis = Mojo::Redis->new($ENV{TEST_REDIS});
my $db    = $redis->db;

$db->get('blocking:key');
is $report[-1]{class},   'Mojo::Redis::Connection', 'report class';
is $report[-1]{method},  'write_p',                 'report method';
is $report[-1]{message}, 'GET blocking:key',        'report blocking';

$db->dbsize(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $report[-1]{message}, 'DBSIZE', 'report non-blocking';

$db->hget_p('promise:key', 'field_a')->wait;
is $report[-1]{message}, 'HGET promise:key field_a', 'report promise';

done_testing;
