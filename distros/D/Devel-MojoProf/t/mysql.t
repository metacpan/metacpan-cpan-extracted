use Mojo::Base -strict;
use Devel::MojoProf -mysql;
use Test::More;

$ENV{TEST_MYSQL} = 'mysql://root@/test' if $ENV{TEST_ALL};
plan skip_all => 'TEST_MYSQL=mysql://root@/test' unless $ENV{TEST_MYSQL};

my @report;
Devel::MojoProf->singleton->reporter(sub { push @report, $_[1] });

my $mysql = Mojo::mysql->new($ENV{TEST_MYSQL});
my $db    = $mysql->db;

$db->query('SELECT "blocking"');
is $report[-1]{class},   'Mojo::mysql::Database', 'report class';
is $report[-1]{method},  'query',                 'report method';
is $report[-1]{message}, 'SELECT "blocking"',     'report blocking';

$db->query('SELECT "non-blocking"', sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $report[-1]{message}, 'SELECT "non-blocking"', 'report non-blocking';

$db->query_p('SELECT "promise"')->wait;
is $report[-1]{message}, 'SELECT "promise"', 'report promise';

done_testing;
