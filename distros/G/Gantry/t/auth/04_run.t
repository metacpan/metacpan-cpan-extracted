use Test::More;
use strict; no warnings;
use File::Copy;

BEGIN {
    my $message;

    eval {
        require HTML::Prototype;
    };
    if ( $@ ) {
        $message = 'Gantry Auth Application requires HTML::Prototype';
    }

    eval { 
        require DBD::SQLite;
    };
    if ( $@ ) {
        $message .= ' ' if ( $message );
	    $message .= 'Gantry Auth Application tests require DBD::SQLite';
    }

    if ( $message ) {
        plan skip_all => $message;
    }
    else {
        plan qw(no_plan);
    }
}

# test must contain valid template paths to the core gantry templates
# and the application templates
use lib qw( ../lib );
use Gantry qw{ -Engine=CGI -TemplateEngine=TT };
use Gantry::Server;
use Gantry::Engine::CGI;

copy( 'docs/auth.sqlite.db', 't/auth/copy_of_auth.db' ) 
    or fail( 'missing auth db' ); 

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        'app_rootp' => '/site',
        'auth_dbconn'   => 'dbi:SQLite:dbname=t/auth/copy_of_auth.db',
        'auth_dbuser'   => '',
        'auth_dbpass'   => '',
        'root'      => ( "../../root:root" )
    },
    locations => {
        '/site/users'       => 'Gantry::Control::C::Users',
        '/site/groups'      => 'Gantry::Control::C::Groups',
        '/site/pages'       => 'Gantry::Control::C::Pages',
    },
} );

my @tests = qw`
    /site/users
    /site/groups
    /site/pages
    POST:/site/users/add?user_id=1&active=t&user_name=sample1&first_name=sample1&last_name=sample1&email=samplesample.com&passwd=sample1&submit=Save
    POST:/site/groups/add?name=sample1&ident=sample1&description=mydescr&submit=Save
    POST:/site/pages/add?uri=sample1&title=sample1&owner_id=1&group_id=1&submit=Save
`;

my $server = Gantry::Server->new();
$server->set_engine_object( $cgi );

foreach my $location ( @tests ) {
    my( $status, $page ) = $server->handle_request_test( $location );
    
    if ( $location =~ /^POST/ ) {
        ok( $status =~ /^(302|200)/,
            "expected 200/302, received $status for $location" );

        if ( $status !~ /^(302|200)$/ ) {
            #diag( $page );   
        }
    }
    else {
        ok( $status eq '200',
            "expected 200, received $status for $location" );
    
        if ( $status ne '200' ) {
            my( $error_section ) =
            ( $page =~ /<div\s+class=(?:\"|\')error(?:\"|\')\s*>(.*?)<\/div>/is );
    
            if ( $error_section ) {
                diag( $location );
                diag( $error_section );
            }
            else {
                diag( $location );
                diag( $page );
            }
        }
    }
}

unlink( 't/auth/copy_of_auth.db' );


