#!perl

use Test::More tests => 3;

my $do_mvr;
BEGIN {
        use_ok( 'File::Rsync::Mirror::Recent' );
        use_ok( 'File::Rsync::Mirror::Recentfile' );
        use_ok( 'File::Rsync::Mirror::Recentfile::Done' );
        $do_mvr = eval { require Module::Versions::Report; 1 };
}
if ($do_mvr) {
    diag(Module::Versions::Report->report);
} else {
    diag( "Testing File::Rsync::Mirror::Recentfile $File::Rsync::Mirror::Recentfile::VERSION, Perl $], $^X" );
}
