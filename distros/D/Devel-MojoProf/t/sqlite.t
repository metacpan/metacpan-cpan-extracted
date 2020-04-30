use Mojo::Base -strict;
use Devel::MojoProf -sqlite;
use Test::More;

plan skip_all => 'Mojo::SQLite is not available' unless Devel::MojoProf->_ensure_loaded('Mojo::SQLite', 1);

my @report;
Devel::MojoProf->singleton->reporter(sub { push @report, $_[1] });

my $sqlite = Mojo::SQLite->new;
my $db     = $sqlite->db;

$db->query('create table t_devel_mojoprof (whatever integer)');
is $report[-1]{class},   'Mojo::SQLite::Database',                           'report class';
is $report[-1]{method},  'query',                                            'report method';
is $report[-1]{message}, 'create table t_devel_mojoprof (whatever integer)', 'report blocking';

$db->query('insert into t_devel_mojoprof (42)', sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $report[-1]{message}, 'insert into t_devel_mojoprof (42)', 'report non-blocking';

done_testing;
