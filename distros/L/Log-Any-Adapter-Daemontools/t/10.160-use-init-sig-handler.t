#! /usr/bin/perl

use Test::More (($^O =~ /Win/)? ( skip_all => "User signals not supported on Windows" ) : () );
use Log::Any '$log';
use Log::Any::Adapter 'Daemontools', -init => { signals => [ 'USR1', 'USR2' ] };

my $cfg= Log::Any::Adapter::Daemontools->global_config;

is( $cfg->log_level, 'info', 'start at level info' );

kill USR1 => $$;

is( $cfg->log_level, 'debug', 'USR1 increased verbosity' );

kill USR2 => $$;
kill USR2 => $$;

is( $cfg->log_level, 'notice', 'USR2 decreased verbosity' );

done_testing;
