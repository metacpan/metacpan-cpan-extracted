use strict;
use warnings;
use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 3 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;
use Data::Dump qw( dump );

SKIP: {
    skip 'leak tests skipped till we sort out hang', 3;

    #use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end leakguard );

    use_ok('Dezi::App');
    use_ok('Dezi::Test::Indexer');

SKIP: {

        # is executable present?
        my $indexer
            = Dezi::Test::Indexer->new( 'invindex' => 't/mail.index' );

        unless ( $ENV{TEST_LEAKS} ) {
            skip "set TEST_LEAKS to test memory leaks", 1;
        }

        leaks_cmp_ok {
            my $program = Dezi::App->new(
                invindex   => 't/testindex',
                aggregator => 'fs',
                indexer    => 'test',
                config     => 't/test.conf',
                filter     => sub { diag( "doc filter on " . $_[0]->url ) },
            );

            my $config = $program->config;

            # skip our local config test files
            $config->FileRules( 'dirname contains config',              1 );
            $config->FileRules( 'filename is swish.xml',                1 );
            $config->FileRules( 'filename contains \.t',                1 );
            $config->FileRules( 'dirname contains (testindex|\.index)', 1 );
            $config->FileRules( 'filename contains \.conf',             1 );
            $config->FileRules( 'dirname contains mailfs',              1 );

            $program->run('t/');

            # clean up header so other test counts work
            unlink('t/testindex/swish.xml') unless $ENV{DEZI_DEBUG};

        }
        '<=', 2;    # 2 outside our control

    }

}
