use strict;
use warnings;
use Test::More tests => 5;

use_ok('Dezi::App');
use_ok('Dezi::Test::Indexer');

diag("testing Dezi::App version $Dezi::App::VERSION");

ok( my $program = Dezi::App->new(
        invindex   => 't/testindex',
        aggregator => 'fs',
        indexer    => 'test',
        config     => 't/test.conf',
        filter     => sub { diag( "doc filter on " . $_[0]->url ) },
    )
);

# skip our local config test files
$program->config->FileRules( 'dirname contains config',              1 );
$program->config->FileRules( 'filename is swish.xml',                1 );
$program->config->FileRules( 'filename contains \.t',                1 );
$program->config->FileRules( 'dirname contains (testindex|\.index)', 1 );
$program->config->FileRules( 'filename contains \.conf',             1 );
$program->config->FileRules( 'dirname contains mailfs',              1 );

ok( $program->run('t/'), "run program" );

is( $program->count, 7, "indexed test docs" );

# clean up header so other test counts work
unlink('t/testindex/swish.xml') unless $ENV{DEZI_DEBUG};

