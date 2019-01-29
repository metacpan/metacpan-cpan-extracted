use Mojo::Base -strict;
use Devel::MojoProf -pg;
use Test::More;

$ENV{USER} ||= 'postgres';
$ENV{TEST_PG} = "postgresql://$ENV{USER}@/test" if $ENV{TEST_ALL};
plan skip_all => 'TEST_PG=postgresql://postgres@/test' unless $ENV{TEST_PG};

my @report;
Devel::MojoProf->singleton->reporter(sub {
  push @report, $_[1];
  shift->Devel::MojoProf::_default_reporter(@_) if $ENV{HARNESS_IS_VERBOSE};
});

my $pg = Mojo::Pg->new($ENV{TEST_PG});
my $db = $pg->db;

$db->query('SELECT 1 as blocking');
is $report[-1]{class},   'Mojo::Pg::Database',   'report class';
is $report[-1]{method},  'query',                'report method';
is $report[-1]{message}, 'SELECT 1 as blocking', 'report blocking';

$db->query('SELECT 1 as non_blocking', sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $report[-1]{message}, 'SELECT 1 as non_blocking', 'report non-blocking';

$db->query_p('SELECT 1 as promise')->wait;
is $report[-1]{message}, 'SELECT 1 as promise', 'report promise';

done_testing;
