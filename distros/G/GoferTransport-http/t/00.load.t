use Test::More tests => 2;

BEGIN {
use_ok( 'DBD::Gofer::Transport::http' );
use_ok( 'DBI::Gofer::Transport::mod_perl' );
}

diag( "Testing DBD::Gofer::Transport::http $DBD::Gofer::Transport::http::VERSION" );
diag( "Testing DBI::Gofer::Transport::mod_perl $DBI::Gofer::Transport::mod_perl::VERSION" );
