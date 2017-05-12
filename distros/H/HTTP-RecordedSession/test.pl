use strict;

use vars qw( $loaded $storable );
BEGIN { $| = 1; print "1..12\n"; }

use HTTP::RecordedSession;
$loaded = 1;
print "ok 1\n";
END {print "not ok 1\n" unless $loaded;}

use Storable;
$storable = 1;
print "ok 2\n";
END {print "not ok 2\n" unless $storable;}

my ( $config_id ) = 'Es3eOOda';

my ( $session );
eval {
    $session = new HTTP::RecordedSession(
	config_id => $config_id,
	path      => "./", 
	test_mod  => "Monkeywrench",
    );
};

if ( $@ ) { print "not ok 3\n" }
else { print "ok 3\n" }

if ( $session->get_id eq $config_id ) { print "ok 4\n" }
else { print "not ok 4\n" }

my ( $clicks ) = $session->get_clicks;
#check to see that there are 5 clicks in the sample file
if ( scalar( @$clicks ) == 5 ) { print "ok 5\n" }
else { print "not ok 5\n" }

my $accept_cookie = 1;
my $send_cookie = 1;
my $method = 1;
foreach my $element ( @$clicks ) {
    foreach my $key ( keys %{ $element } ) {
        if ( $key =~ /cookie/ ) {
	    if ( $key =~ /^accept/ ) { $accept_cookie = 0 unless ( $key eq 'acceptcookie' ) }
	    elsif ( $key =~ /^send/ ) { $send_cookie = 0 unless ( $key eq 'sendcookie' ) } 
	}
	if ( $key eq 'method' ) { 
	    $method = 0 unless ( ( $element->{ $key } eq 'GET' ) || 
	                         ( $element->{ $key } eq 'POST' ) ); 
	}
    }
}

#check format of $clicks hash
if ( $accept_cookie == 1 ) { print "ok 6\n" }
else { print "not ok 6\n" }

if ( $send_cookie == 1 ) { print "ok 7\n" }
else { print "not ok 7\n" }

if ( $method == 1 ) { print "ok 8\n" } 
else { print "not ok 8\n" }

my ( $session_wt );
eval {
    $session_wt = new HTTP::RecordedSession(
	config_id => $config_id,
	path      => "./", 
	test_mod  => "WebTest",
    );
};

my ( $clicks_wt ) = $session_wt->get_clicks;

if ( $@ ) { print "not ok 9\n" }
else { print "ok 9\n" }

my $accept_cookie_wt = 1;
my $send_cookie_wt = 1;
my $method_wt = 1;
foreach my $element ( @$clicks_wt ) {
    foreach my $key ( keys %{ $element } ) {
        if ( $key =~ /cookie/ ) {
	    if ( $key =~ /^accept/ ) { $accept_cookie = 0 unless ( $key eq 'accept_cookies' ) }
	    elsif ( $key =~ /^send/ ) { $send_cookie = 0 unless ( $key eq 'send_cookies' ) } 
	}
	if ( $key eq 'method' ) { 
	    $method = 0 unless ( ( $element->{ $key } eq 'get' ) || 
	                         ( $element->{ $key } eq 'post' ) ); 
	}
    }
}

#check format of $clicks hash
if ( $accept_cookie == 1 ) { print "ok 10\n" }
else { print "not ok 10\n" }

if ( $send_cookie == 1 ) { print "ok 11\n" }
else { print "not ok 11\n" }

if ( $method == 1 ) { print "ok 12\n" } 
else { print "not ok 12\n" }
