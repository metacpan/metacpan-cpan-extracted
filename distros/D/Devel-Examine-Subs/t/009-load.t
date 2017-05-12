#!perl
use warnings;
use strict;

use Test::More tests => 27;

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Sub' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Preprocessor' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Postprocessor' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
    use_ok( 'PPI' ) || print "PPI can't be loaded, bailing out!\n";

}

diag( "Testing Devel::Examine::Subs $Devel::Examine::Subs::VERSION, Perl $], $^X" );

my $subs_namespace = "Devel::Examine::Subs";

can_ok( $subs_namespace, 'new' );
can_ok( $subs_namespace, 'has' );
can_ok( $subs_namespace, 'missing' );
can_ok( $subs_namespace, 'all' );

can_ok( $subs_namespace, '_file' );
can_ok( $subs_namespace, '_core' );
can_ok( $subs_namespace, '_engine' );
can_ok( $subs_namespace, '_pod' );
is (Devel::Examine::Subs::_pod(), 1, "subs placeholder check");

my $sub_namespace = "Devel::Examine::Subs::Sub";

can_ok( $sub_namespace, 'new' );
can_ok( $sub_namespace, 'name' );
can_ok( $sub_namespace, 'start' );
can_ok( $sub_namespace, 'end' );
can_ok( $sub_namespace, 'line_count' );

my $engine_namespace = "Devel::Examine::Subs::Engine";

can_ok( $engine_namespace, '_test' );
can_ok( $engine_namespace, '_vim_placeholder' );
is (Devel::Examine::Subs::Engine::_vim_placeholder(), 1, "engine placeholder check");

my $preproc_namespace = "Devel::Examine::Subs::Preprocessor";

can_ok( $preproc_namespace, '_vim_placeholder' );
is (Devel::Examine::Subs::Preprocessor::_vim_placeholder(), 1, "pre placeholder check");

my $postproc_namespace = "Devel::Examine::Subs::Preprocessor";

can_ok( $postproc_namespace, '_vim_placeholder' );
is (Devel::Examine::Subs::Postprocessor::_vim_placeholder(), 1, "post placeholder check");


