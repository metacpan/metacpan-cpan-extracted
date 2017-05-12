package TestCGI;

use Module::Util qw(find_installed);
use HTTP::Date qw(time2str);
use base ('HTTP::Daemon::Threaded::CGIHandler');

use strict;
use warnings;

our $mtime = time2str((stat(find_installed(__PACKAGE__)))[9]);

sub new { my $class = shift; return $class->SUPER::new(@_); }

sub handleCGI {
	my ($self, $cgi, $session) = @_;

	if (1 == 0) {
	print STDERR "\n*************** Got request:\n",
		join("\n", 
			map $_ . ': ' . ($ENV{$_} || 'none'), qw(
				SERVER_URL 
				REQUEST_METHOD
				REQUEST_URI
				REMOTE_ADDR
				QUERY_STRING
				PATH_INFO
				CONTENT_TYPE
				CONTENT_LENGTH)), "\n";
	}	
	my $uri = $ENV{REQUEST_URI};
	
	$uri = substr($uri, 1) if (substr($uri, 0, 1) eq '/');
#	print STDERR "*** URI is $uri\n";
	print $cgi->header(-status => "404 NOT FOUND", -nph => 1), "\n\n" and
	return 1
		unless ($uri=~/^(?:posted|postxml|getform)/);

	my $params = $cgi->Vars;
	my $ct = 'text/html';
	my $html = '';
	if ($uri=~/^posted/) {
		$html .= "$_ is $params->{$_}<br>\r\n"
			foreach (sort keys %$params);
	}
	elsif ($uri=~/^postxml/) {
		$html = $cgi->param('POSTDATA');
		$ct = 'text/xml';
	}

	if ($cgi->request_method eq 'HEAD') {
#	print STDERR "*** return HEAD for $ct\n";
		print $cgi->header( 
			-Content_type => $ct,
			-charset => 'UTF-8',
			-Last_Modified => $mtime,
			), "\n\n";
		return 1;
	}
	elsif ($cgi->request_method eq 'GET') {
		if ($uri=~/^posted/) {
			print $cgi->header( 
				-Content_type => $ct,
				-charset => 'UTF-8',
				-Last_Modified => $mtime,
				),
				$cgi->start_html(),
				$html,
				$cgi->end_html;
		}
		elsif ($uri=~/^getform/) {
			print $cgi->header( 
				-Content_type => $ct,
				-charset => 'UTF-8',
				-Last_Modified => $mtime,
				),
				$cgi->start_html( 
					-title    => 'Hello World',
					-encoding => 'UTF-8'
				),
				$cgi->h1('Hello World'),
				$cgi->start_form,
				$cgi->table(
					$cgi->Tr( [
						$cgi->td( [ 'Name',  $cgi->textfield( -name => 'name'  ) ] ),
						$cgi->td( [ 'Email', $cgi->textfield( -name => 'email' ) ] ),
						$cgi->td( [ 'Phone', $cgi->textfield( -name => 'phone' ) ] ),
						$cgi->td( [ 'File',  $cgi->filefield( -name => 'file'  ) ] )
					] )
				),
				$cgi->submit,
				$cgi->end_form,
				$cgi->h2('Parameters'),
				$cgi->Dump,
				$cgi->end_html;
		}
	}
	else {
		if ($uri=~/^posted/) {
			print $cgi->header( 
				-Content_type => $ct,
				-charset => 'UTF-8',
				-Last_Modified => $mtime,
				),
				$cgi->start_html(),
				$html,
				$cgi->end_html;
		}
		else {
			print $cgi->header( 
				-Content_type => $ct,
				-charset => 'UTF-8',
				-Last_Modified => $mtime,
				),
				$html;
		}
	}
	return 1;
}

1;

