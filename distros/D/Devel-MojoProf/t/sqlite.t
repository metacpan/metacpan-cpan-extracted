use Mojo::Base -strict;
use Devel::MojoProf -sqlite;
use Test::More;

plan skip_all => 'Mojo::SQLite is not available' unless Devel::MojoProf->_ensure_loaded('Mojo::SQLite', 1);

my @report;
Devel::MojoProf->singleton->reporter(sub {
  push @report, $_[1];
  shift->Devel::MojoProf::_default_reporter(@_) if $ENV{HARNESS_IS_VERBOSE};
});

my $sqlite = Mojo::SQLite->new;
my $db     = $sqlite->db;

$db->query('SELECT "blocking"');
is $report[-1]{class},   'Mojo::SQLite::Database', 'report class';
is $report[-1]{method},  'query',                  'report method';
is $report[-1]{message}, 'SELECT "blocking"',      'report blocking';

$db->query('SELECT "non-blocking"', sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $report[-1]{message}, 'SELECT "non-blocking"', 'report non-blocking';

done_testing;
