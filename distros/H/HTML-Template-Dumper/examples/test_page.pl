#!/usr/local/bin/perl
# 
# A simple example of writing a test for a CGI.
#
# Requirements: 
# 
# - Sends a MIME-type of text/html
# - When sending a parameter $foo, then there will 
# 	be a parameter $bar, where $bar == $foo + 1
# 

=head1 COPYRIGHT

Copyright 2003, American Society of Agronomy. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software 
Foundation; either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with Perl.

=cut


use strict;
use warnings;
use LWP::UserAgent;
use HTML::Template::Dumper;

use Test::More tests => 20;

use constant URI => 'http://www.example.com/cgi-bin/test.cgi';


sub run_test 
{
	my $foo_value = shift || 0;
	my $ua = LWP::UserAgent->new;
	my $response = $ua->post( URI, foo => $foo_value );

	if($response->is_success) {
		ok( $response->header('Content-Type') eq 'text/html', 
			"Checking MIME type" );

		my $data = HTML::Template::Dumper->parse( 
			$response->content 
		);
		ok( $data->{bar} == $foo_value + 1, 
			"Checking value of 'bar'" );
	}
	else {
		warn $response->status_line, "\n";
		# Failed both tests
		ok(0, "Checking MIME type" );
		ok(0, "Checking value of 'bar'" );
	}
}


run_test($_) for (0 .. 9);

