#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

pod_coverage_ok( $_, { trustme => [ qr/^BUILD(|ARGS)$/ ] } )
  foreach grep { ! /::(Format|Types|IPC::Run)$/ } all_modules( 'lib' );


pod_coverage_ok( 'IPC::PrettyPipe::Execute::IPC::Run',
		 { trustme => [ qr/^BUILD(|ARGS)$/, 'pipe' ] } );


done_testing;
